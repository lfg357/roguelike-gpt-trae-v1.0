from pathlib import Path

import numpy as np
from PIL import Image


ATLASES = {
    "player": ("assets/characters/animated/player/yan_wugui_actions.png", 8, 6),
    "blade": ("assets/characters/animated/enemies/blade_actions.png", 8, 4),
    "guard": ("assets/characters/animated/enemies/guard_actions.png", 8, 4),
    "dart": ("assets/characters/animated/enemies/dart_actions.png", 8, 4),
    "elite": ("assets/characters/animated/enemies/elite_actions.png", 7, 5),
    "boss": ("assets/characters/animated/enemies/boss_actions.png", 8, 6),
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


def max_edge_pixels(alpha: np.ndarray, columns: int, rows: int, inset: int) -> int:
    height, width = alpha.shape
    maximum = 0
    for row in range(rows):
        for column in range(columns):
            x0 = round(column * width / columns) + inset
            x1 = round((column + 1) * width / columns) - inset
            y0 = round(row * height / rows) + inset
            y1 = round((row + 1) * height / rows) - inset
            if x1 <= x0 or y1 <= y0:
                continue
            maximum = max(
                maximum,
                int(np.count_nonzero(alpha[y0:y1, x0] > 128)),
                int(np.count_nonzero(alpha[y0:y1, x1 - 1] > 128)),
            )
    return maximum


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    for name, (relative_path, columns, rows) in ATLASES.items():
        alpha = np.array(Image.open(root / relative_path).convert("RGBA"))[:, :, 3]
        readings = [f"{inset}px={max_edge_pixels(alpha, columns, rows, inset)}" for inset in (2, 4, 6, 8, 12, 16, 20)]
        print(f"{name:12} " + " ".join(readings))


if __name__ == "__main__":
    main()
