from pathlib import Path

import numpy as np
from PIL import Image


SPECS = {
    "player": (
        "assets/characters/animated/player/yan_wugui_actions.png",
        8,
        6,
        ["idle", "run", "attack", "dodge", "hurt", "dead"],
    ),
    "blade": (
        "assets/characters/animated/enemies/blade_actions.png",
        8,
        4,
        ["idle", "run", "attack", "dead"],
    ),
    "guard": (
        "assets/characters/animated/enemies/guard_actions.png",
        8,
        4,
        ["idle", "run", "attack", "dead"],
    ),
    "dart": (
        "assets/characters/animated/enemies/dart_actions.png",
        8,
        4,
        ["idle", "run", "attack", "dead"],
    ),
    "elite": (
        "assets/characters/animated/enemies/elite_actions.png",
        7,
        5,
        ["idle", "run", "attack", "hurt", "dead"],
    ),
    "boss": (
        "assets/characters/animated/enemies/boss_actions.png",
        8,
        6,
        ["idle", "run", "attack", "phase", "hurt", "dead"],
    ),
}


def largest_component(mask: np.ndarray) -> np.ndarray:
    height, width = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    best: list[tuple[int, int]] = []
    for start_y, start_x in zip(*np.where(mask & ~visited)):
        stack = [(int(start_y), int(start_x))]
        visited[start_y, start_x] = True
        component: list[tuple[int, int]] = []
        while stack:
            y, x = stack.pop()
            component.append((y, x))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = y + dy, x + dx
                    if (
                        0 <= ny < height
                        and 0 <= nx < width
                        and mask[ny, nx]
                        and not visited[ny, nx]
                    ):
                        visited[ny, nx] = True
                        stack.append((ny, nx))
        if len(component) > len(best):
            best = component
    result = np.zeros_like(mask, dtype=bool)
    for y, x in best:
        result[y, x] = True
    return result


def frame_anchor(alpha: np.ndarray) -> tuple[float, float]:
    body = largest_component(alpha > 160)
    ys, xs = np.where(body)
    if len(xs) == 0:
        return 0.5, 0.84

    lower_band = ys >= np.quantile(ys, 0.88)
    center_x = float(np.median(xs[lower_band])) / alpha.shape[1]
    foot_y = float(np.quantile(ys, 0.97)) / alpha.shape[0]
    return max(0.35, min(0.65, center_x)), max(0.72, min(0.94, foot_y))


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    for kind, (relative_path, columns, rows, actions) in SPECS.items():
        image = np.array(Image.open(root / relative_path).convert("RGBA"))
        height, width = image.shape[:2]
        print(kind)
        for row, action in enumerate(actions):
            anchors = []
            for column in range(columns):
                x0 = round(column * width / columns)
                x1 = round((column + 1) * width / columns)
                y0 = round(row * height / rows)
                y1 = round((row + 1) * height / rows)
                anchor = frame_anchor(image[y0:y1, x0:x1, 3])
                anchors.append(tuple(round(value, 3) for value in anchor))
            print(f"  {action}: {anchors}")


if __name__ == "__main__":
    main()
