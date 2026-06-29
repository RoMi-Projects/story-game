"""Generate every pixel-art asset for the game from scratch.

Run with:  python3 tools/generate_assets.py

All art is drawn procedurally so it is original, version-controlled, and
regenerable. Editing the palette or drawing helpers and re-running this script
is the way to tweak the art -- no binary editor or third-party files involved.

Outputs (written to ../assets relative to this file):
  - floor_tile.png          16x16 tiling wooden floor
  - wall_tile.png           16x16 tiling stone wall
  - player_spritesheet.png  64x96 sheet: 4 rows (down, up, left, right)
                            x 4 columns (walk frames), each cell 16x24
  - icon.png                256x256 application/window icon
"""

from pathlib import Path

from PIL import Image

TILE_SIZE = 16

FRAME_WIDTH = 16
FRAME_HEIGHT = 24
WALK_FRAME_COUNT = 4

TRANSPARENT = (0, 0, 0, 0)

PALETTE = {
    "outline": (54, 42, 38, 255),
    "skin": (242, 198, 156, 255),
    "skin_shadow": (214, 165, 122, 255),
    "hat": (158, 104, 60, 255),
    "hat_shadow": (116, 74, 42, 255),
    "hair": (96, 64, 38, 255),
    "shirt": (74, 138, 184, 255),
    "shirt_shadow": (52, 104, 142, 255),
    "pants": (70, 78, 116, 255),
    "pants_shadow": (48, 54, 86, 255),
    "shoe": (52, 40, 30, 255),
    "floor": (184, 142, 102, 255),
    "floor_seam": (150, 112, 78, 255),
    "floor_grain": (198, 158, 118, 255),
    "wall": (124, 120, 130, 255),
    "wall_grout": (86, 82, 92, 255),
    "wall_highlight": (146, 142, 152, 255),
    "grass": (96, 152, 88, 255),
    "grass_dark": (78, 132, 72, 255),
    "desi_hair": (150, 78, 48, 255),
    "desi_hair_shadow": (118, 60, 38, 255),
    "desi_dress": (176, 64, 84, 255),
    "desi_dress_shadow": (140, 48, 66, 255),
    "portrait_back": (44, 40, 52, 255),
    "eye_white": (248, 246, 240, 255),
    "angry_red": (214, 66, 54, 255),
    "blush": (232, 122, 112, 255),
    "mouth": (122, 52, 52, 255),
}


# --- low-level drawing helpers -------------------------------------------------

def fill_rect(pixels, left, top, right, bottom, color):
    """Fill an inclusive rectangle of pixels with a color."""
    for y in range(top, bottom + 1):
        for x in range(left, right + 1):
            pixels[x, y] = color


def new_image(width, height):
    return Image.new("RGBA", (width, height), TRANSPARENT)


# --- floor and wall tiles ------------------------------------------------------

def draw_floor_tile():
    image = new_image(TILE_SIZE, TILE_SIZE)
    pixels = image.load()
    fill_rect(pixels, 0, 0, TILE_SIZE - 1, TILE_SIZE - 1, PALETTE["floor"])
    _draw_horizontal_seam(pixels, 0)
    _draw_horizontal_seam(pixels, 8)
    _draw_vertical_seam(pixels, 0, 0, 7)
    _draw_vertical_seam(pixels, 8, 8, 15)
    _scatter_grain(pixels)
    return image


def _draw_horizontal_seam(pixels, row):
    fill_rect(pixels, 0, row, TILE_SIZE - 1, row, PALETTE["floor_seam"])


def _draw_vertical_seam(pixels, column, top, bottom):
    fill_rect(pixels, column, top, column, bottom, PALETTE["floor_seam"])


def _scatter_grain(pixels):
    grain_pixels = [(3, 3), (11, 2), (6, 5), (13, 6), (2, 11), (9, 12), (14, 13)]
    for x, y in grain_pixels:
        pixels[x, y] = PALETTE["floor_grain"]


def draw_wall_tile():
    image = new_image(TILE_SIZE, TILE_SIZE)
    pixels = image.load()
    fill_rect(pixels, 0, 0, TILE_SIZE - 1, TILE_SIZE - 1, PALETTE["wall"])
    _draw_brick_grout(pixels)
    _draw_brick_highlights(pixels)
    return image


def _draw_brick_grout(pixels):
    for row in (0, 8):
        fill_rect(pixels, 0, row, TILE_SIZE - 1, row, PALETTE["wall_grout"])
    fill_rect(pixels, 8, 1, 8, 7, PALETTE["wall_grout"])
    fill_rect(pixels, 0, 9, 0, 15, PALETTE["wall_grout"])


def _draw_brick_highlights(pixels):
    fill_rect(pixels, 1, 1, 7, 1, PALETTE["wall_highlight"])
    fill_rect(pixels, 9, 9, 15, 9, PALETTE["wall_highlight"])


# --- character sprite sheet ----------------------------------------------------

def draw_player_spritesheet():
    rows = ["down", "up", "left", "right"]
    sheet = new_image(FRAME_WIDTH * WALK_FRAME_COUNT, FRAME_HEIGHT * len(rows))
    for row_index, facing in enumerate(rows):
        for frame in range(WALK_FRAME_COUNT):
            cell = _draw_character(facing, frame)
            sheet.paste(cell, (frame * FRAME_WIDTH, row_index * FRAME_HEIGHT))
    return sheet


def _draw_character(facing, frame):
    image = new_image(FRAME_WIDTH, FRAME_HEIGHT)
    pixels = image.load()
    _draw_hat(pixels)
    _draw_head(pixels, facing)
    _draw_torso(pixels)
    _draw_arms(pixels)
    _draw_legs(pixels, facing, frame)
    return image


def _draw_hat(pixels):
    fill_rect(pixels, 6, 2, 9, 3, PALETTE["hat"])
    fill_rect(pixels, 5, 4, 10, 4, PALETTE["hat"])
    fill_rect(pixels, 3, 5, 12, 5, PALETTE["hat_shadow"])


def _draw_head(pixels, facing):
    if facing == "up":
        fill_rect(pixels, 5, 6, 10, 9, PALETTE["hair"])
        return
    fill_rect(pixels, 5, 6, 10, 9, PALETTE["skin"])
    fill_rect(pixels, 5, 9, 10, 9, PALETTE["skin_shadow"])
    _draw_eyes(pixels, facing)


def _draw_eyes(pixels, facing):
    if facing == "down":
        pixels[6, 8] = PALETTE["outline"]
        pixels[9, 8] = PALETTE["outline"]
    elif facing == "left":
        pixels[6, 8] = PALETTE["outline"]
    elif facing == "right":
        pixels[9, 8] = PALETTE["outline"]


def _draw_torso(pixels):
    fill_rect(pixels, 5, 10, 10, 16, PALETTE["shirt"])
    fill_rect(pixels, 5, 10, 5, 16, PALETTE["shirt_shadow"])
    fill_rect(pixels, 10, 10, 10, 16, PALETTE["shirt_shadow"])


def _draw_arms(pixels):
    fill_rect(pixels, 3, 10, 4, 14, PALETTE["shirt"])
    fill_rect(pixels, 11, 10, 12, 14, PALETTE["shirt"])
    fill_rect(pixels, 3, 15, 4, 16, PALETTE["skin"])
    fill_rect(pixels, 11, 15, 12, 16, PALETTE["skin"])


def _draw_legs(pixels, facing, frame):
    step = _leg_step_offset(frame)
    if facing in ("left", "right"):
        _draw_profile_legs(pixels, facing, step)
    else:
        _draw_front_legs(pixels, step)


def _leg_step_offset(frame):
    """Return the foot swing for a frame: 0 neutral, +1 / -1 alternating."""
    return (0, 1, 0, -1)[frame]


def _draw_front_legs(pixels, step):
    left_bottom = 21 + step
    right_bottom = 21 - step
    _draw_leg(pixels, 5, 7, 17, left_bottom)
    _draw_leg(pixels, 8, 10, 17, right_bottom)


def _draw_profile_legs(pixels, facing, step):
    forward = 1 if facing == "right" else -1
    front_left = 7 + forward * step
    back_left = 7 - forward * step
    _draw_leg(pixels, back_left, back_left + 2, 17, 21)
    _draw_leg(pixels, front_left, front_left + 2, 17, 21)


def _draw_leg(pixels, left, right, top, bottom):
    fill_rect(pixels, left, top, right, bottom - 1, PALETTE["pants"])
    fill_rect(pixels, left, bottom, right, bottom, PALETTE["shoe"])


# --- Desi (NPC) ----------------------------------------------------------------

def draw_desi_sprite():
    image = new_image(FRAME_WIDTH, FRAME_HEIGHT)
    pixels = image.load()
    _draw_desi_hair(pixels)
    _draw_desi_face(pixels)
    _draw_desi_dress(pixels)
    _draw_desi_legs(pixels)
    return image


def _draw_desi_hair(pixels):
    fill_rect(pixels, 4, 2, 11, 6, PALETTE["desi_hair"])
    fill_rect(pixels, 3, 6, 4, 13, PALETTE["desi_hair_shadow"])
    fill_rect(pixels, 11, 6, 12, 13, PALETTE["desi_hair_shadow"])


def _draw_desi_face(pixels):
    fill_rect(pixels, 5, 5, 10, 9, PALETTE["skin"])
    fill_rect(pixels, 5, 5, 10, 5, PALETTE["desi_hair"])
    fill_rect(pixels, 5, 9, 10, 9, PALETTE["skin_shadow"])
    pixels[6, 8] = PALETTE["outline"]
    pixels[9, 8] = PALETTE["outline"]


def _draw_desi_dress(pixels):
    fill_rect(pixels, 5, 10, 10, 15, PALETTE["desi_dress"])
    fill_rect(pixels, 5, 10, 5, 15, PALETTE["desi_dress_shadow"])
    fill_rect(pixels, 10, 10, 10, 15, PALETTE["desi_dress_shadow"])
    fill_rect(pixels, 3, 10, 4, 14, PALETTE["desi_dress"])
    fill_rect(pixels, 11, 10, 12, 14, PALETTE["desi_dress"])
    fill_rect(pixels, 3, 15, 4, 16, PALETTE["skin"])
    fill_rect(pixels, 11, 15, 12, 16, PALETTE["skin"])
    fill_rect(pixels, 4, 16, 11, 19, PALETTE["desi_dress"])
    fill_rect(pixels, 3, 20, 12, 20, PALETTE["desi_dress_shadow"])


def _draw_desi_legs(pixels):
    fill_rect(pixels, 5, 21, 7, 22, PALETTE["skin"])
    fill_rect(pixels, 8, 21, 10, 22, PALETTE["skin"])
    fill_rect(pixels, 5, 23, 7, 23, PALETTE["shoe"])
    fill_rect(pixels, 8, 23, 10, 23, PALETTE["shoe"])


def draw_desi_portrait():
    image = new_image(32, 32)
    pixels = image.load()
    fill_rect(pixels, 0, 0, 31, 31, PALETTE["portrait_back"])
    _draw_portrait_hair(pixels)
    _draw_portrait_face(pixels)
    _draw_angry_brows(pixels)
    _draw_glaring_eyes(pixels)
    _draw_angry_mouth(pixels)
    _draw_anger_mark(pixels)
    return image


def _draw_portrait_hair(pixels):
    fill_rect(pixels, 5, 3, 26, 28, PALETTE["desi_hair"])
    fill_rect(pixels, 4, 8, 5, 26, PALETTE["desi_hair_shadow"])
    fill_rect(pixels, 26, 8, 27, 26, PALETTE["desi_hair_shadow"])


def _draw_portrait_face(pixels):
    fill_rect(pixels, 9, 9, 22, 27, PALETTE["skin"])
    fill_rect(pixels, 9, 9, 22, 10, PALETTE["desi_hair"])
    fill_rect(pixels, 9, 26, 22, 27, PALETTE["skin_shadow"])
    fill_rect(pixels, 7, 19, 8, 21, PALETTE["blush"])
    fill_rect(pixels, 23, 19, 24, 21, PALETTE["blush"])


def _draw_angry_brows(pixels):
    left_brow = [(10, 13), (11, 13), (12, 14), (13, 14), (14, 15)]
    right_brow = [(21, 13), (20, 13), (19, 14), (18, 14), (17, 15)]
    for x, y in left_brow + right_brow:
        pixels[x, y] = PALETTE["outline"]


def _draw_glaring_eyes(pixels):
    fill_rect(pixels, 10, 16, 13, 18, PALETTE["eye_white"])
    fill_rect(pixels, 18, 16, 21, 18, PALETTE["eye_white"])
    fill_rect(pixels, 11, 16, 12, 17, PALETTE["outline"])
    fill_rect(pixels, 19, 16, 20, 17, PALETTE["outline"])


def _draw_angry_mouth(pixels):
    fill_rect(pixels, 13, 23, 18, 23, PALETTE["mouth"])
    pixels[12, 24] = PALETTE["mouth"]
    pixels[19, 24] = PALETTE["mouth"]


def _draw_anger_mark(pixels):
    marks = [(26, 4), (24, 6), (28, 6), (26, 7), (25, 5), (27, 5)]
    for x, y in marks:
        pixels[x, y] = PALETTE["angry_red"]


# --- application icon ----------------------------------------------------------

def draw_icon():
    scale = 8
    icon = new_image(256, 256)
    pixels = icon.load()
    fill_rect(pixels, 0, 0, 255, 255, PALETTE["grass"])
    _checker_grass(pixels)
    character = _draw_character("down", 0).resize(
        (FRAME_WIDTH * scale, FRAME_HEIGHT * scale), Image.NEAREST
    )
    icon.alpha_composite(character, (64, 32))
    return icon


def _checker_grass(pixels):
    block = 16
    for y in range(0, 256, block):
        for x in range(0, 256, block):
            if (x // block + y // block) % 2 == 0:
                fill_rect(pixels, x, y, x + block - 1, y + block - 1,
                          PALETTE["grass_dark"])


# --- entry point ---------------------------------------------------------------

def assets_directory():
    return Path(__file__).resolve().parent.parent / "assets"


def save(image, name, directory):
    path = directory / name
    image.save(path)
    print(f"wrote {path.relative_to(directory.parent)} ({image.width}x{image.height})")


def main():
    directory = assets_directory()
    directory.mkdir(parents=True, exist_ok=True)
    save(draw_floor_tile(), "floor_tile.png", directory)
    save(draw_wall_tile(), "wall_tile.png", directory)
    save(draw_player_spritesheet(), "player_spritesheet.png", directory)
    save(draw_desi_sprite(), "desi.png", directory)
    save(draw_desi_portrait(), "desi_portrait.png", directory)
    save(draw_icon(), "icon.png", directory)


if __name__ == "__main__":
    main()
