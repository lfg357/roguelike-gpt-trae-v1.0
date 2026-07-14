from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]

CHARACTER_SPECS = {
    "player": ("assets/characters/animated/player/yan_wugui_actions.png", 8, 6),
    "blade": ("assets/characters/animated/enemies/blade_actions.png", 8, 4),
    "guard": ("assets/characters/animated/enemies/guard_actions.png", 8, 4),
    "dart": ("assets/characters/animated/enemies/dart_actions.png", 8, 4),
    "elite": ("assets/characters/animated/enemies/elite_actions.png", 7, 5),
    "boss": ("assets/characters/animated/enemies/boss_actions.png", 8, 6),
}

VFX_SPECS = {
    "weapon": ("assets/vfx/sequences/weapon_actions.png", 8, 4),
    "impact": ("assets/vfx/sequences/impact_actions.png", 8, 4),
    "element": ("assets/vfx/sequences/element_actions.png", 8, 6),
    "duanshui": ("assets/vfx/sequences/duanshui_subskills.png", 8, 3),
    "shuangren": ("assets/vfx/sequences/shuangren_subskills.png", 8, 3),
    "mohong": ("assets/vfx/sequences/mohong_subskills.png", 8, 3),
    "lieshan": ("assets/vfx/sequences/lieshan_subskills.png", 8, 3),
    "yinxue": ("assets/vfx/sequences/yinxue_subskills.png", 8, 3),
    "progression": ("assets/vfx/sequences/progression_actions.png", 8, 5),
}


def frame_bounds(width: int, height: int, columns: int, rows: int, col: int, row: int) -> tuple[int, int, int, int]:
    return (
        round(col * width / columns),
        round(row * height / rows),
        round((col + 1) * width / columns),
        round((row + 1) * height / rows),
    )


def alpha_metrics(frame: np.ndarray) -> dict[str, float]:
    alpha = frame[:, :, 3]
    ys, xs = np.where(alpha > 24)
    if len(xs) == 0:
        return {"empty": 1.0, "cx": 0.5, "cy": 0.5, "edge": 0.0, "area": 0.0}
    edge_pixels = np.concatenate([alpha[0, :], alpha[-1, :], alpha[:, 0], alpha[:, -1]])
    return {
        "empty": 0.0,
        "cx": float(xs.mean()) / max(1, alpha.shape[1]),
        "cy": float(ys.mean()) / max(1, alpha.shape[0]),
        "edge": float(np.count_nonzero(edge_pixels > 24)),
        "area": float(len(xs)) / float(alpha.size),
    }


def frame_difference(a: np.ndarray, b: np.ndarray) -> float:
    common_h = min(a.shape[0], b.shape[0])
    common_w = min(a.shape[1], b.shape[1])
    aa = a[:common_h, :common_w, 3].astype(np.float32) / 255.0
    bb = b[:common_h, :common_w, 3].astype(np.float32) / 255.0
    return float(np.mean(np.abs(aa - bb)))


def validate_group(name: str, relative_path: str, columns: int, rows: int, strict_motion: bool) -> list[str]:
    image = np.array(Image.open(ROOT / relative_path).convert("RGBA"))
    height, width = image.shape[:2]
    issues: list[str] = []
    for row in range(rows):
        frames = []
        metrics = []
        for col in range(columns):
            x0, y0, x1, y1 = frame_bounds(width, height, columns, rows, col, row)
            frame = image[y0:y1, x0:x1]
            frames.append(frame)
            metrics.append(alpha_metrics(frame))
        for col, metric in enumerate(metrics):
            if metric["empty"]:
                issues.append(f"{name} row {row} frame {col}: empty frame")
            if metric["edge"] > 0:
                issues.append(f"{name} row {row} frame {col}: alpha touches cell edge ({metric['edge']:.0f}px)")
        for col in range(columns - 1):
            diff = frame_difference(frames[col], frames[col + 1])
            if diff < 0.002:
                issues.append(f"{name} row {row} frames {col}->{col + 1}: near-duplicate alpha")
            jump = abs(metrics[col]["cx"] - metrics[col + 1]["cx"]) + abs(metrics[col]["cy"] - metrics[col + 1]["cy"])
            if strict_motion and jump > 0.34:
                issues.append(f"{name} row {row} frames {col}->{col + 1}: large alpha centroid jump {jump:.3f}")
    return issues


def main() -> None:
    issues: list[str] = []
    for name, spec in CHARACTER_SPECS.items():
        issues.extend(validate_group(name, *spec, strict_motion=True))
    for name, spec in VFX_SPECS.items():
        issues.extend(validate_group(name, *spec, strict_motion=False))

    if issues:
        print("ANIMATION_AUDIT_WARN")
        for issue in issues:
            print(issue)
    else:
        print("ANIMATION_AUDIT_OK")


if __name__ == "__main__":
    main()
