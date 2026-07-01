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

from pixel_font import build_fonts

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
    "wood": (150, 104, 62, 255),
    "wood_dark": (114, 78, 46, 255),
    "wood_light": (180, 134, 86, 255),
    "counter_top": (208, 208, 216, 255),
    "counter_top_dark": (168, 168, 180, 255),
    "metal": (176, 182, 192, 255),
    "stove": (62, 64, 72, 255),
    "stove_dark": (44, 46, 54, 255),
    "sofa": (148, 98, 66, 255),
    "sofa_dark": (116, 74, 48, 255),
    "sofa_light": (176, 124, 86, 255),
    "rug": (170, 70, 70, 255),
    "rug_border": (226, 208, 170, 255),
    "rug_accent": (120, 44, 44, 255),
    "glass": (152, 198, 224, 255),
    "glass_light": (192, 224, 242, 255),
    "frame": (158, 112, 66, 255),
    "frame_dark": (118, 82, 48, 255),
    "gold": (212, 178, 98, 255),
    "gold_dark": (168, 138, 70, 255),
    "wall_mat": (226, 220, 208, 255),
    "trash": (112, 122, 118, 255),
    "trash_dark": (84, 92, 90, 255),
    "trash_lid": (94, 102, 100, 255),
    "marker_bg": (250, 238, 168, 255),
    "marker_outline": (66, 52, 42, 255),
    "marker_red": (212, 72, 58, 255),
    "check": (86, 178, 94, 255),
    "check_dark": (62, 140, 72, 255),
    "heart": (226, 84, 98, 255),
    "heart_light": (244, 142, 152, 255),
    "lips": (204, 92, 96, 255),
    "path": (172, 134, 90, 255),
    "path_dark": (146, 110, 72, 255),
    "fence": (162, 122, 76, 255),
    "fence_dark": (120, 86, 52, 255),
    "dumpster": (78, 134, 94, 255),
    "dumpster_dark": (58, 106, 72, 255),
    "dumpster_lid": (98, 152, 112, 255),
    "wheel": (48, 50, 56, 255),
    "trash_bag": (66, 70, 78, 255),
    "trash_bag_dark": (46, 50, 58, 255),
    "trash_bag_light": (94, 98, 108, 255),
    "sparkle": (250, 250, 240, 255),
    "star": (242, 200, 72, 255),
    "star_light": (252, 230, 132, 255),
    "banana": (230, 202, 78, 255),
    "banana_dark": (190, 158, 54, 255),
    "banana_tip": (120, 96, 40, 255),
    "can_label": (200, 72, 62, 255),
    "paper": (226, 222, 210, 255),
    "paper_dark": (186, 182, 170, 255),
    "bone": (236, 232, 218, 255),
    "apple": (204, 154, 100, 255),
    "apple_dark": (152, 110, 68, 255),
    "apple_seed": (60, 44, 34, 255),
    "mouse_body": (150, 150, 158, 255),
    "mouse_dark": (112, 112, 122, 255),
    "mouse_belly": (200, 198, 202, 255),
    "mouse_ear": (214, 150, 158, 255),
    "mouse_nose": (224, 126, 138, 255),
    "mouse_eye": (38, 34, 40, 255),
    "cat_body": (226, 158, 92, 255),
    "cat_dark": (184, 120, 62, 255),
    "cat_belly": (244, 216, 172, 255),
    "cat_ear": (232, 176, 150, 255),
    "cat_nose": (214, 120, 120, 255),
    "cat_eye": (86, 150, 96, 255),
    "sky": (180, 214, 232, 255),
    "sky_low": (206, 230, 240, 255),
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


def draw_wall_window_tile():
    # The window baked into a wall tile (rule 2: it becomes part of the wall).
    image = draw_wall_tile()
    pixels = image.load()
    fill_rect(pixels, 2, 3, 13, 12, PALETTE["frame"])
    fill_rect(pixels, 3, 4, 12, 11, PALETTE["glass"])
    fill_rect(pixels, 3, 4, 12, 7, PALETTE["glass_light"])
    fill_rect(pixels, 7, 4, 8, 11, PALETTE["frame"])
    fill_rect(pixels, 3, 7, 12, 8, PALETTE["frame"])
    fill_rect(pixels, 2, 12, 13, 13, PALETTE["frame_dark"])
    return image


def draw_wall_portrait_tile():
    # The framed portrait baked into a wall tile.
    image = draw_wall_tile()
    pixels = image.load()
    fill_rect(pixels, 3, 2, 12, 13, PALETTE["gold"])
    fill_rect(pixels, 4, 3, 11, 12, PALETTE["gold_dark"])
    fill_rect(pixels, 5, 4, 10, 11, PALETTE["wall_mat"])
    fill_rect(pixels, 6, 5, 9, 7, PALETTE["skin"])
    fill_rect(pixels, 6, 8, 9, 10, PALETTE["shirt"])
    return image


def draw_tileset_atlas():
    # One 16px-tiled atlas the world TileSet sources from. Tile order (atlas x):
    # 0 wall, 1 wall_window, 2 wall_portrait, 3 fence, 4 floor, 5 grass, 6 path.
    tiles = [
        draw_wall_tile(),
        draw_wall_window_tile(),
        draw_wall_portrait_tile(),
        draw_fence(),
        draw_floor_tile(),
        draw_garden_grass(),
        draw_garden_path(),
    ]
    atlas = new_image(TILE_SIZE * len(tiles), TILE_SIZE)
    for index, tile in enumerate(tiles):
        atlas.paste(tile, (index * TILE_SIZE, 0))
    return atlas


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


def draw_desi_spritesheet():
    rows = ["down", "up", "left", "right"]
    sheet = new_image(FRAME_WIDTH * WALK_FRAME_COUNT, FRAME_HEIGHT * len(rows))
    for row_index, facing in enumerate(rows):
        for frame in range(WALK_FRAME_COUNT):
            cell = _draw_desi_character(facing, frame)
            sheet.paste(cell, (frame * FRAME_WIDTH, row_index * FRAME_HEIGHT))
    return sheet


def _draw_desi_character(facing, frame):
    image = new_image(FRAME_WIDTH, FRAME_HEIGHT)
    pixels = image.load()
    _draw_desi_hair_facing(pixels, facing)
    _draw_desi_head_facing(pixels, facing)
    _draw_desi_dress(pixels)
    _draw_desi_walk_legs(pixels, frame)
    return image


def _draw_desi_hair_facing(pixels, facing):
    fill_rect(pixels, 4, 2, 11, 6, PALETTE["desi_hair"])
    fill_rect(pixels, 3, 6, 4, 13, PALETTE["desi_hair_shadow"])
    fill_rect(pixels, 11, 6, 12, 13, PALETTE["desi_hair_shadow"])
    if facing == "up":
        fill_rect(pixels, 5, 6, 10, 9, PALETTE["desi_hair"])


def _draw_desi_head_facing(pixels, facing):
    if facing == "up":
        return
    fill_rect(pixels, 5, 5, 10, 9, PALETTE["skin"])
    fill_rect(pixels, 5, 5, 10, 5, PALETTE["desi_hair"])
    fill_rect(pixels, 5, 9, 10, 9, PALETTE["skin_shadow"])
    if facing in ("down", "left"):
        pixels[6, 8] = PALETTE["outline"]
    if facing in ("down", "right"):
        pixels[9, 8] = PALETTE["outline"]


def _draw_desi_walk_legs(pixels, frame):
    _draw_desi_foot(pixels, 5, frame == 1)
    _draw_desi_foot(pixels, 8, frame == 3)


def _draw_desi_foot(pixels, left, raised):
    skin_top = 20 if raised else 21
    fill_rect(pixels, left, skin_top, left + 2, skin_top + 1, PALETTE["skin"])
    fill_rect(pixels, left, skin_top + 2, left + 2, skin_top + 2, PALETTE["shoe"])


def _new_portrait():
    image = new_image(32, 32)
    pixels = image.load()
    fill_rect(pixels, 0, 0, 31, 31, PALETTE["portrait_back"])
    _draw_portrait_hair(pixels)
    _draw_portrait_face(pixels)
    return image, pixels


def draw_desi_portrait():
    image, pixels = _new_portrait()
    _draw_angry_brows(pixels)
    _draw_glaring_eyes(pixels)
    _draw_angry_mouth(pixels)
    _draw_anger_mark(pixels)
    return image


def draw_desi_kiss():
    image, pixels = _new_portrait()
    _draw_happy_eyes(pixels)
    _draw_kiss_mouth(pixels)
    _draw_strong_blush(pixels)
    _draw_floating_heart(pixels, 24, 4)
    return image


def draw_desi_wink():
    image, pixels = _new_portrait()
    _draw_wink_eyes(pixels)
    _draw_smile_mouth(pixels)
    pixels[22, 14] = PALETTE["sparkle"]
    pixels[23, 13] = PALETTE["sparkle"]
    return image


def _draw_happy_eyes(pixels):
    left = [(10, 16), (11, 15), (12, 15), (13, 16)]
    right = [(18, 16), (19, 15), (20, 15), (21, 16)]
    for x, y in left + right:
        pixels[x, y] = PALETTE["outline"]


def _draw_kiss_mouth(pixels):
    fill_rect(pixels, 14, 22, 17, 24, PALETTE["lips"])
    pixels[15, 23] = PALETTE["mouth"]
    pixels[16, 23] = PALETTE["mouth"]


def _draw_strong_blush(pixels):
    fill_rect(pixels, 6, 18, 8, 21, PALETTE["blush"])
    fill_rect(pixels, 23, 18, 25, 21, PALETTE["blush"])


def _draw_wink_eyes(pixels):
    fill_rect(pixels, 10, 16, 13, 18, PALETTE["eye_white"])
    fill_rect(pixels, 11, 16, 12, 17, PALETTE["outline"])
    for x, y in [(18, 17), (19, 16), (20, 16), (21, 17)]:
        pixels[x, y] = PALETTE["outline"]


def _draw_smile_mouth(pixels):
    for x, y in [(13, 23), (14, 24), (15, 24), (16, 24), (17, 24), (18, 23)]:
        pixels[x, y] = PALETTE["mouth"]


def _draw_floating_heart(pixels, left, top):
    fill_rect(pixels, left, top + 1, left + 1, top + 2, PALETTE["heart"])
    fill_rect(pixels, left + 3, top + 1, left + 4, top + 2, PALETTE["heart"])
    fill_rect(pixels, left, top + 2, left + 4, top + 3, PALETTE["heart"])
    fill_rect(pixels, left + 1, top + 4, left + 3, top + 4, PALETTE["heart"])
    pixels[left + 2, top + 5] = PALETTE["heart"]
    pixels[left + 1, top + 1] = PALETTE["heart_light"]


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


# --- furniture (each is one placeable unit) ------------------------------------

def draw_kitchen_counter():
    image = new_image(48, 28)
    pixels = image.load()
    fill_rect(pixels, 0, 4, 47, 27, PALETTE["wood"])
    fill_rect(pixels, 0, 0, 47, 2, PALETTE["counter_top"])
    fill_rect(pixels, 0, 3, 47, 3, PALETTE["counter_top_dark"])
    fill_rect(pixels, 0, 4, 47, 6, PALETTE["stove"])
    for x in (6, 12, 35, 41):
        pixels[x, 5] = PALETTE["metal"]
    _draw_oven(pixels)
    _draw_cabinet_door(pixels, 2, 9, 13, 25)
    _draw_cabinet_door(pixels, 34, 9, 45, 25)
    return image


def _draw_oven(pixels):
    fill_rect(pixels, 16, 8, 31, 26, PALETTE["stove_dark"])
    fill_rect(pixels, 18, 11, 29, 20, PALETTE["stove"])
    fill_rect(pixels, 19, 12, 28, 15, PALETTE["glass"])
    fill_rect(pixels, 18, 9, 29, 9, PALETTE["metal"])
    fill_rect(pixels, 18, 23, 29, 24, PALETTE["metal"])


def _draw_cabinet_door(pixels, left, top, right, bottom):
    fill_rect(pixels, left, top, right, bottom, PALETTE["wood_dark"])
    fill_rect(pixels, left + 1, top + 1, right - 1, bottom - 1, PALETTE["wood_light"])
    fill_rect(pixels, right - 2, (top + bottom) // 2, right - 1,
              (top + bottom) // 2, PALETTE["wood_dark"])


def draw_dining_table():
    image = new_image(32, 22)
    pixels = image.load()
    fill_rect(pixels, 3, 8, 4, 21, PALETTE["wood_dark"])
    fill_rect(pixels, 27, 8, 28, 21, PALETTE["wood_dark"])
    fill_rect(pixels, 2, 8, 29, 10, PALETTE["wood_dark"])
    fill_rect(pixels, 0, 2, 31, 7, PALETTE["wood_light"])
    fill_rect(pixels, 0, 2, 31, 2, PALETTE["wood"])
    fill_rect(pixels, 0, 7, 31, 7, PALETTE["wood_dark"])
    return image


def draw_trash_can():
    image = new_image(14, 20)
    pixels = image.load()
    fill_rect(pixels, 1, 4, 12, 19, PALETTE["trash"])
    for x in (4, 7, 10):
        fill_rect(pixels, x, 5, x, 18, PALETTE["trash_dark"])
    fill_rect(pixels, 0, 2, 13, 4, PALETTE["trash_lid"])
    fill_rect(pixels, 5, 0, 8, 1, PALETTE["trash_dark"])
    fill_rect(pixels, 1, 19, 12, 19, PALETTE["trash_dark"])
    return image


def draw_sofa():
    image = new_image(44, 24)
    pixels = image.load()
    fill_rect(pixels, 4, 2, 39, 12, PALETTE["sofa"])
    fill_rect(pixels, 4, 2, 39, 3, PALETTE["sofa_light"])
    fill_rect(pixels, 0, 6, 6, 22, PALETTE["sofa_dark"])
    fill_rect(pixels, 37, 6, 43, 22, PALETTE["sofa_dark"])
    fill_rect(pixels, 7, 12, 21, 20, PALETTE["sofa_light"])
    fill_rect(pixels, 22, 12, 36, 20, PALETTE["sofa_light"])
    fill_rect(pixels, 21, 12, 22, 20, PALETTE["sofa_dark"])
    fill_rect(pixels, 6, 22, 10, 23, PALETTE["wood_dark"])
    fill_rect(pixels, 33, 22, 37, 23, PALETTE["wood_dark"])
    return image


def draw_rug():
    image = new_image(48, 32)
    pixels = image.load()
    fill_rect(pixels, 0, 0, 47, 31, PALETTE["rug_border"])
    fill_rect(pixels, 3, 3, 44, 28, PALETTE["rug"])
    fill_rect(pixels, 6, 6, 41, 25, PALETTE["rug"])
    _draw_rectangle_outline(pixels, 6, 6, 41, 25, PALETTE["rug_accent"])
    _draw_rug_diamond(pixels)
    return image


def _draw_rectangle_outline(pixels, left, top, right, bottom, color):
    fill_rect(pixels, left, top, right, top, color)
    fill_rect(pixels, left, bottom, right, bottom, color)
    fill_rect(pixels, left, top, left, bottom, color)
    fill_rect(pixels, right, top, right, bottom, color)


def _draw_rug_diamond(pixels):
    center_x, center_y = 23, 15
    for offset in range(5):
        fill_rect(pixels, center_x - offset, center_y - 4 + offset,
                  center_x + offset, center_y - 4 + offset, PALETTE["rug_border"])
    for offset in range(5):
        fill_rect(pixels, center_x - 4 + offset, center_y + offset,
                  center_x + 4 - offset, center_y + offset, PALETTE["rug_border"])


def draw_coffee_table():
    image = new_image(24, 14)
    pixels = image.load()
    fill_rect(pixels, 2, 6, 4, 13, PALETTE["wood_dark"])
    fill_rect(pixels, 19, 6, 21, 13, PALETTE["wood_dark"])
    fill_rect(pixels, 0, 2, 23, 5, PALETTE["wood_light"])
    fill_rect(pixels, 0, 2, 23, 2, PALETTE["wood"])
    fill_rect(pixels, 0, 5, 23, 5, PALETTE["wood_dark"])
    fill_rect(pixels, 9, 0, 11, 1, PALETTE["rug"])
    return image


def draw_window():
    image = new_image(24, 20)
    pixels = image.load()
    fill_rect(pixels, 0, 0, 23, 19, PALETTE["frame"])
    fill_rect(pixels, 2, 2, 21, 16, PALETTE["glass"])
    fill_rect(pixels, 2, 2, 21, 8, PALETTE["glass_light"])
    fill_rect(pixels, 11, 2, 12, 16, PALETTE["frame"])
    fill_rect(pixels, 2, 8, 21, 9, PALETTE["frame"])
    fill_rect(pixels, 0, 17, 23, 19, PALETTE["frame_dark"])
    return image


def draw_wall_portrait():
    image = new_image(20, 26)
    pixels = image.load()
    fill_rect(pixels, 0, 0, 19, 25, PALETTE["gold"])
    fill_rect(pixels, 1, 1, 18, 24, PALETTE["gold_dark"])
    fill_rect(pixels, 3, 3, 16, 22, PALETTE["wall_mat"])
    _draw_portrait_bust(pixels)
    return image


def _draw_portrait_bust(pixels):
    fill_rect(pixels, 6, 6, 13, 7, PALETTE["hat_shadow"])
    fill_rect(pixels, 7, 4, 12, 6, PALETTE["hat"])
    fill_rect(pixels, 7, 8, 12, 12, PALETTE["skin"])
    pixels[8, 10] = PALETTE["outline"]
    pixels[11, 10] = PALETTE["outline"]
    fill_rect(pixels, 6, 13, 13, 21, PALETTE["shirt"])
    fill_rect(pixels, 6, 13, 6, 21, PALETTE["shirt_shadow"])


# --- player carrying a trash bag -----------------------------------------------

def draw_player_carry_spritesheet():
    rows = ["down", "up", "left", "right"]
    sheet = new_image(FRAME_WIDTH * WALK_FRAME_COUNT, FRAME_HEIGHT * len(rows))
    for row_index, facing in enumerate(rows):
        for frame in range(WALK_FRAME_COUNT):
            cell = _draw_character(facing, frame)
            _draw_held_bag(cell.load())
            sheet.paste(cell, (frame * FRAME_WIDTH, row_index * FRAME_HEIGHT))
    return sheet


def _draw_held_bag(pixels):
    fill_rect(pixels, 4, 16, 11, 21, PALETTE["trash_bag"])
    fill_rect(pixels, 5, 14, 10, 16, PALETTE["trash_bag"])
    fill_rect(pixels, 6, 12, 9, 13, PALETTE["trash_bag_dark"])
    fill_rect(pixels, 5, 16, 6, 19, PALETTE["trash_bag_light"])
    fill_rect(pixels, 4, 15, 5, 16, PALETTE["skin"])
    fill_rect(pixels, 10, 15, 11, 16, PALETTE["skin"])


# --- quest markers and heart ---------------------------------------------------

def draw_marker_exclaim():
    image = new_image(14, 18)
    pixels = image.load()
    fill_rect(pixels, 1, 1, 12, 11, PALETTE["marker_bg"])
    _draw_rectangle_outline(pixels, 1, 1, 12, 11, PALETTE["marker_outline"])
    fill_rect(pixels, 5, 12, 8, 12, PALETTE["marker_bg"])
    fill_rect(pixels, 6, 13, 7, 14, PALETTE["marker_bg"])
    pixels[5, 12] = PALETTE["marker_outline"]
    pixels[8, 12] = PALETTE["marker_outline"]
    pixels[6, 14] = PALETTE["marker_outline"]
    pixels[7, 14] = PALETTE["marker_outline"]
    fill_rect(pixels, 6, 3, 7, 7, PALETTE["marker_red"])
    fill_rect(pixels, 6, 9, 7, 10, PALETTE["marker_red"])
    return image


def draw_marker_check():
    image = new_image(16, 16)
    pixels = image.load()
    fill_rect(pixels, 3, 4, 12, 11, PALETTE["check"])
    fill_rect(pixels, 4, 2, 11, 13, PALETTE["check"])
    _draw_rectangle_outline(pixels, 4, 2, 11, 13, PALETTE["check_dark"])
    _draw_rectangle_outline(pixels, 3, 4, 12, 11, PALETTE["check_dark"])
    for x, y in [(5, 8), (6, 9), (7, 10), (8, 9), (9, 7), (10, 5)]:
        pixels[x, y] = PALETTE["sparkle"]
    return image


def draw_heart():
    image = new_image(12, 12)
    pixels = image.load()
    rows = {
        2: [(2, 3), (8, 9)],
        3: [(1, 4), (7, 10)],
        4: [(1, 10)],
        5: [(1, 10)],
        6: [(2, 9)],
        7: [(3, 8)],
        8: [(4, 7)],
        9: [(5, 6)],
    }
    for y, spans in rows.items():
        for left, right in spans:
            fill_rect(pixels, left, y, right, y, PALETTE["heart"])
    pixels[3, 3] = PALETTE["heart_light"]
    pixels[4, 4] = PALETTE["heart_light"]
    return image


# --- inventory item icons ------------------------------------------------------

def draw_trash_bag():
    image = new_image(12, 14)
    pixels = image.load()
    fill_rect(pixels, 2, 4, 9, 12, PALETTE["trash_bag"])
    fill_rect(pixels, 1, 6, 10, 12, PALETTE["trash_bag"])
    fill_rect(pixels, 3, 2, 8, 4, PALETTE["trash_bag_dark"])
    fill_rect(pixels, 4, 1, 7, 2, PALETTE["trash_bag"])
    fill_rect(pixels, 3, 6, 4, 10, PALETTE["trash_bag_light"])
    fill_rect(pixels, 1, 12, 10, 12, PALETTE["trash_bag_dark"])
    return image


def draw_empty_bag():
    image = new_image(12, 14)
    pixels = image.load()
    fill_rect(pixels, 2, 7, 9, 12, PALETTE["trash_bag_light"])
    fill_rect(pixels, 1, 9, 10, 12, PALETTE["trash_bag_light"])
    fill_rect(pixels, 2, 4, 9, 6, PALETTE["trash_bag_dark"])
    fill_rect(pixels, 2, 4, 9, 4, PALETTE["trash_bag"])
    fill_rect(pixels, 2, 6, 2, 11, PALETTE["trash_bag"])
    fill_rect(pixels, 9, 6, 9, 11, PALETTE["trash_bag"])
    fill_rect(pixels, 1, 12, 10, 12, PALETTE["trash_bag_dark"])
    return image


def draw_trash_banana():
    image = new_image(12, 9)
    pixels = image.load()
    fill_rect(pixels, 5, 6, 6, 8, PALETTE["banana_dark"])
    fill_rect(pixels, 2, 3, 3, 7, PALETTE["banana"])
    fill_rect(pixels, 5, 2, 6, 7, PALETTE["banana"])
    fill_rect(pixels, 8, 3, 9, 7, PALETTE["banana"])
    fill_rect(pixels, 2, 3, 2, 3, PALETTE["banana_tip"])
    fill_rect(pixels, 9, 3, 9, 3, PALETTE["banana_tip"])
    fill_rect(pixels, 5, 2, 5, 2, PALETTE["banana_tip"])
    return image


def draw_trash_can_litter():
    image = new_image(10, 13)
    pixels = image.load()
    fill_rect(pixels, 2, 1, 7, 11, PALETTE["metal"])
    fill_rect(pixels, 2, 1, 7, 1, PALETTE["counter_top"])
    fill_rect(pixels, 2, 11, 7, 11, PALETTE["trash_dark"])
    fill_rect(pixels, 2, 4, 7, 7, PALETTE["can_label"])
    fill_rect(pixels, 2, 2, 2, 10, PALETTE["counter_top_dark"])
    return image


def draw_trash_paper():
    image = new_image(11, 10)
    pixels = image.load()
    fill_rect(pixels, 3, 2, 7, 7, PALETTE["paper"])
    fill_rect(pixels, 2, 3, 8, 6, PALETTE["paper"])
    for x, y in [(4, 3), (6, 5), (5, 6), (3, 5), (7, 4)]:
        pixels[x, y] = PALETTE["paper_dark"]
    return image


def draw_trash_fishbone():
    image = new_image(14, 8)
    pixels = image.load()
    fill_rect(pixels, 2, 3, 10, 4, PALETTE["bone"])
    for x in range(3, 10, 2):
        pixels[x, 1] = PALETTE["bone"]
        pixels[x, 2] = PALETTE["bone"]
        pixels[x, 5] = PALETTE["bone"]
        pixels[x, 6] = PALETTE["bone"]
    fill_rect(pixels, 10, 2, 12, 5, PALETTE["bone"])
    pixels[12, 3] = PALETTE["trash_dark"]
    fill_rect(pixels, 0, 3, 1, 4, PALETTE["bone"])
    return image


def draw_trash_apple():
    image = new_image(9, 12)
    pixels = image.load()
    fill_rect(pixels, 4, 0, 4, 1, PALETTE["wood_dark"])
    fill_rect(pixels, 2, 2, 6, 3, PALETTE["apple_dark"])
    fill_rect(pixels, 3, 3, 5, 8, PALETTE["apple"])
    fill_rect(pixels, 2, 8, 6, 10, PALETTE["apple_dark"])
    pixels[3, 5] = PALETTE["apple_seed"]
    pixels[5, 7] = PALETTE["apple_seed"]
    return image


def draw_star():
    image = new_image(11, 11)
    pixels = image.load()
    rows = {
        0: [(5, 5)],
        1: [(4, 6)],
        2: [(4, 6)],
        3: [(0, 10)],
        4: [(2, 8)],
        5: [(3, 7)],
        6: [(3, 7)],
        7: [(2, 3), (7, 8)],
        8: [(1, 2), (8, 9)],
    }
    for y, spans in rows.items():
        for left, right in spans:
            fill_rect(pixels, left, y, right, y, PALETTE["star"])
    pixels[5, 2] = PALETTE["star_light"]
    pixels[5, 4] = PALETTE["star_light"]
    return image


# --- garden --------------------------------------------------------------------

def draw_garden_grass():
    image = new_image(TILE_SIZE, TILE_SIZE)
    pixels = image.load()
    fill_rect(pixels, 0, 0, TILE_SIZE - 1, TILE_SIZE - 1, PALETTE["grass"])
    for x, y in [(2, 4), (3, 3), (7, 6), (8, 5), (12, 9), (13, 8), (5, 12), (10, 13)]:
        fill_rect(pixels, x, y - 1, x, y, PALETTE["grass_dark"])
    return image


def draw_garden_path():
    image = new_image(TILE_SIZE, TILE_SIZE)
    pixels = image.load()
    fill_rect(pixels, 0, 0, TILE_SIZE - 1, TILE_SIZE - 1, PALETTE["path"])
    for x, y in [(2, 2), (6, 4), (11, 3), (14, 7), (4, 9), (9, 11), (13, 13), (3, 13)]:
        pixels[x, y] = PALETTE["path_dark"]
    return image


def draw_fence():
    image = new_image(TILE_SIZE, TILE_SIZE)
    pixels = image.load()
    for post in (2, 11):
        fill_rect(pixels, post, 0, post + 1, 15, PALETTE["fence"])
        fill_rect(pixels, post, 14, post + 1, 15, PALETTE["fence_dark"])
    fill_rect(pixels, 0, 3, 15, 5, PALETTE["fence"])
    fill_rect(pixels, 0, 10, 15, 12, PALETTE["fence"])
    fill_rect(pixels, 0, 5, 15, 5, PALETTE["fence_dark"])
    fill_rect(pixels, 0, 12, 15, 12, PALETTE["fence_dark"])
    return image


def draw_trash_container():
    image = new_image(32, 34)
    pixels = image.load()
    fill_rect(pixels, 13, 1, 18, 3, PALETTE["dumpster_dark"])
    fill_rect(pixels, 1, 3, 30, 9, PALETTE["dumpster_lid"])
    fill_rect(pixels, 1, 3, 30, 3, PALETTE["dumpster_dark"])
    fill_rect(pixels, 2, 9, 29, 30, PALETTE["dumpster"])
    fill_rect(pixels, 2, 9, 3, 30, PALETTE["dumpster_dark"])
    fill_rect(pixels, 28, 9, 29, 30, PALETTE["dumpster_dark"])
    fill_rect(pixels, 2, 19, 29, 20, PALETTE["dumpster_dark"])
    fill_rect(pixels, 12, 12, 19, 17, PALETTE["dumpster_lid"])
    fill_rect(pixels, 5, 31, 9, 33, PALETTE["wheel"])
    fill_rect(pixels, 22, 31, 26, 33, PALETTE["wheel"])
    return image


def draw_door():
    image = new_image(24, 28)
    pixels = image.load()
    fill_rect(pixels, 0, 0, 23, 27, PALETTE["wood_dark"])
    fill_rect(pixels, 2, 2, 21, 27, PALETTE["wood"])
    fill_rect(pixels, 2, 2, 21, 2, PALETTE["wood_light"])
    _draw_rectangle_outline(pixels, 4, 4, 19, 12, PALETTE["wood_dark"])
    _draw_rectangle_outline(pixels, 4, 15, 19, 24, PALETTE["wood_dark"])
    fill_rect(pixels, 17, 14, 18, 16, PALETTE["gold"])
    return image


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


# --- the mouse and its combat scene --------------------------------------------

def draw_mouse_spritesheet():
    rows = ["down", "up", "left", "right"]
    sheet = new_image(FRAME_WIDTH * WALK_FRAME_COUNT, FRAME_HEIGHT * len(rows))
    for row_index, facing in enumerate(rows):
        for frame in range(WALK_FRAME_COUNT):
            cell = _draw_mouse_cell(facing, frame)
            sheet.paste(cell, (frame * FRAME_WIDTH, row_index * FRAME_HEIGHT))
    return sheet


def _draw_mouse_cell(facing, frame):
    image = new_image(FRAME_WIDTH, FRAME_HEIGHT)
    pixels = image.load()
    _draw_mouse_tail(pixels, facing)
    _draw_mouse_body(pixels)
    _draw_mouse_face(pixels, facing)
    _draw_mouse_feet(pixels, frame)
    return image


def _draw_mouse_body(pixels):
    fill_rect(pixels, 5, 13, 10, 21, PALETTE["mouse_body"])
    fill_rect(pixels, 6, 12, 9, 12, PALETTE["mouse_body"])
    fill_rect(pixels, 5, 21, 10, 21, PALETTE["mouse_dark"])


def _draw_mouse_tail(pixels, facing):
    if facing == "up":
        fill_rect(pixels, 7, 20, 8, 23, PALETTE["mouse_ear"])
    elif facing == "left":
        fill_rect(pixels, 11, 17, 13, 18, PALETTE["mouse_ear"])
    elif facing == "right":
        fill_rect(pixels, 2, 17, 4, 18, PALETTE["mouse_ear"])


def _draw_mouse_face(pixels, facing):
    if facing == "up":
        fill_rect(pixels, 4, 11, 5, 13, PALETTE["mouse_ear"])
        fill_rect(pixels, 10, 11, 11, 13, PALETTE["mouse_ear"])
        return
    if facing == "down":
        fill_rect(pixels, 4, 11, 5, 13, PALETTE["mouse_ear"])
        fill_rect(pixels, 10, 11, 11, 13, PALETTE["mouse_ear"])
        fill_rect(pixels, 6, 15, 9, 18, PALETTE["mouse_belly"])
        pixels[6, 15] = PALETTE["mouse_eye"]
        pixels[9, 15] = PALETTE["mouse_eye"]
        pixels[7, 17] = PALETTE["mouse_nose"]
        pixels[8, 17] = PALETTE["mouse_nose"]
        return
    # profile: one ear up top, snout and eye on the facing side
    fill_rect(pixels, 7, 10, 8, 12, PALETTE["mouse_ear"])
    if facing == "left":
        fill_rect(pixels, 3, 16, 4, 18, PALETTE["mouse_body"])
        pixels[3, 17] = PALETTE["mouse_nose"]
        pixels[6, 15] = PALETTE["mouse_eye"]
    else:
        fill_rect(pixels, 11, 16, 12, 18, PALETTE["mouse_body"])
        pixels[12, 17] = PALETTE["mouse_nose"]
        pixels[9, 15] = PALETTE["mouse_eye"]


def _draw_mouse_feet(pixels, frame):
    left_raised = frame == 1
    right_raised = frame == 3
    fill_rect(pixels, 5, 21 if left_raised else 22, 6, 22 if left_raised else 23,
              PALETTE["mouse_ear"])
    fill_rect(pixels, 9, 21 if right_raised else 22, 10, 22 if right_raised else 23,
              PALETTE["mouse_ear"])


def draw_mouse_battle():
    image = new_image(48, 40)
    pixels = image.load()
    # tail, curling out behind to the right
    fill_rect(pixels, 33, 22, 40, 23, PALETTE["mouse_ear"])
    fill_rect(pixels, 39, 18, 40, 23, PALETTE["mouse_ear"])
    # body
    fill_rect(pixels, 12, 14, 34, 33, PALETTE["mouse_body"])
    fill_rect(pixels, 14, 12, 32, 13, PALETTE["mouse_body"])
    fill_rect(pixels, 12, 33, 34, 34, PALETTE["mouse_dark"])
    fill_rect(pixels, 16, 22, 28, 32, PALETTE["mouse_belly"])
    # ears
    fill_rect(pixels, 9, 6, 16, 13, PALETTE["mouse_body"])
    fill_rect(pixels, 28, 6, 35, 13, PALETTE["mouse_body"])
    fill_rect(pixels, 11, 8, 14, 11, PALETTE["mouse_ear"])
    fill_rect(pixels, 30, 8, 33, 11, PALETTE["mouse_ear"])
    # face, looking down toward the player
    fill_rect(pixels, 17, 18, 18, 20, PALETTE["mouse_eye"])
    fill_rect(pixels, 26, 18, 27, 20, PALETTE["mouse_eye"])
    fill_rect(pixels, 21, 23, 23, 25, PALETTE["mouse_nose"])
    # whiskers
    fill_rect(pixels, 13, 24, 18, 24, PALETTE["mouse_dark"])
    fill_rect(pixels, 26, 24, 31, 24, PALETTE["mouse_dark"])
    # feet
    fill_rect(pixels, 14, 34, 18, 36, PALETTE["mouse_ear"])
    fill_rect(pixels, 28, 34, 32, 36, PALETTE["mouse_ear"])
    return image


def draw_player_battle():
    # The player seen from behind, the way Pokemon frames the trainer.
    image = new_image(32, 40)
    pixels = image.load()
    fill_rect(pixels, 8, 2, 23, 7, PALETTE["hat"])
    fill_rect(pixels, 6, 7, 25, 8, PALETTE["hat_shadow"])
    fill_rect(pixels, 9, 9, 22, 11, PALETTE["hair"])
    fill_rect(pixels, 8, 12, 23, 27, PALETTE["shirt"])
    fill_rect(pixels, 6, 13, 8, 24, PALETTE["shirt_shadow"])
    fill_rect(pixels, 23, 13, 25, 24, PALETTE["shirt_shadow"])
    fill_rect(pixels, 9, 28, 22, 35, PALETTE["pants"])
    fill_rect(pixels, 15, 28, 16, 35, PALETTE["pants_shadow"])
    fill_rect(pixels, 9, 36, 14, 39, PALETTE["shoe"])
    fill_rect(pixels, 17, 36, 22, 39, PALETTE["shoe"])
    return image


def draw_combat_bg():
    image = new_image(320, 180)
    pixels = image.load()
    fill_rect(pixels, 0, 0, 319, 89, PALETTE["sky"])
    fill_rect(pixels, 0, 70, 319, 89, PALETTE["sky_low"])
    fill_rect(pixels, 0, 90, 319, 179, PALETTE["grass"])
    for y in range(96, 180, 8):
        fill_rect(pixels, 0, y, 319, y, PALETTE["grass_dark"])
    _draw_combat_platform(pixels, 60, 150, 52, 12)
    _draw_combat_platform(pixels, 234, 74, 46, 10)
    return image


def _draw_combat_platform(pixels, cx, cy, half_w, half_h):
    for y in range(cy - half_h, cy + half_h + 1):
        span = int(half_w * (1.0 - (abs(y - cy) / float(half_h)) ** 2))
        fill_rect(pixels, cx - span, y, cx + span, y, PALETTE["grass_dark"])


def draw_desi_smile():
    image, pixels = _new_portrait()
    _draw_happy_eyes(pixels)
    _draw_smile_mouth(pixels)
    return image


# --- Baby the cat and her combat scene -----------------------------------------

def draw_cat_spritesheet():
    rows = ["down", "up", "left", "right"]
    sheet = new_image(FRAME_WIDTH * WALK_FRAME_COUNT, FRAME_HEIGHT * len(rows))
    for row_index, facing in enumerate(rows):
        for frame in range(WALK_FRAME_COUNT):
            cell = _draw_cat_cell(facing, frame)
            sheet.paste(cell, (frame * FRAME_WIDTH, row_index * FRAME_HEIGHT))
    return sheet


def _draw_cat_cell(facing, frame):
    image = new_image(FRAME_WIDTH, FRAME_HEIGHT)
    pixels = image.load()
    _draw_cat_tail(pixels, facing)
    _draw_cat_body(pixels)
    _draw_cat_ears(pixels, facing)
    _draw_cat_face(pixels, facing)
    _draw_cat_feet(pixels, frame)
    return image


def _draw_cat_body(pixels):
    fill_rect(pixels, 5, 12, 10, 21, PALETTE["cat_body"])
    fill_rect(pixels, 6, 11, 9, 11, PALETTE["cat_body"])
    fill_rect(pixels, 5, 21, 10, 21, PALETTE["cat_dark"])
    fill_rect(pixels, 6, 13, 9, 13, PALETTE["cat_dark"])


def _draw_cat_tail(pixels, facing):
    if facing == "up":
        fill_rect(pixels, 10, 12, 11, 17, PALETTE["cat_body"])
        pixels[11, 12] = PALETTE["cat_dark"]
    elif facing == "down":
        fill_rect(pixels, 10, 18, 12, 22, PALETTE["cat_body"])
    elif facing == "left":
        fill_rect(pixels, 11, 14, 13, 15, PALETTE["cat_body"])
        pixels[13, 13] = PALETTE["cat_body"]
    else:
        fill_rect(pixels, 2, 14, 4, 15, PALETTE["cat_body"])
        pixels[2, 13] = PALETTE["cat_body"]


def _draw_cat_ears(pixels, facing):
    if facing in ("up", "down"):
        pixels[4, 9] = PALETTE["cat_body"]
        fill_rect(pixels, 4, 10, 5, 11, PALETTE["cat_body"])
        pixels[11, 9] = PALETTE["cat_body"]
        fill_rect(pixels, 10, 10, 11, 11, PALETTE["cat_body"])
        if facing == "down":
            pixels[5, 11] = PALETTE["cat_ear"]
            pixels[10, 11] = PALETTE["cat_ear"]
    else:
        pixels[7, 9] = PALETTE["cat_body"]
        fill_rect(pixels, 7, 10, 8, 11, PALETTE["cat_body"])


def _draw_cat_face(pixels, facing):
    if facing == "up":
        return
    if facing == "down":
        fill_rect(pixels, 6, 15, 9, 19, PALETTE["cat_belly"])
        pixels[6, 15] = PALETTE["cat_eye"]
        pixels[9, 15] = PALETTE["cat_eye"]
        pixels[7, 17] = PALETTE["cat_nose"]
        pixels[8, 17] = PALETTE["cat_nose"]
        pixels[4, 17] = PALETTE["cat_dark"]
        pixels[11, 17] = PALETTE["cat_dark"]
        return
    if facing == "left":
        fill_rect(pixels, 3, 15, 4, 17, PALETTE["cat_body"])
        pixels[3, 16] = PALETTE["cat_nose"]
        pixels[6, 14] = PALETTE["cat_eye"]
        pixels[2, 16] = PALETTE["cat_dark"]
    else:
        fill_rect(pixels, 11, 15, 12, 17, PALETTE["cat_body"])
        pixels[12, 16] = PALETTE["cat_nose"]
        pixels[9, 14] = PALETTE["cat_eye"]
        pixels[13, 16] = PALETTE["cat_dark"]


def _draw_cat_feet(pixels, frame):
    left_raised = frame == 1
    right_raised = frame == 3
    fill_rect(pixels, 5, 21 if left_raised else 22, 6, 22 if left_raised else 23,
              PALETTE["cat_dark"])
    fill_rect(pixels, 9, 21 if right_raised else 22, 10, 22 if right_raised else 23,
              PALETTE["cat_dark"])


def draw_cat_battle():
    return _draw_cat_battle(happy=False)


def draw_cat_battle_happy():
    return _draw_cat_battle(happy=True)


def _draw_cat_battle(happy):
    image = new_image(48, 40)
    pixels = image.load()
    # tail, curling up behind to the right
    fill_rect(pixels, 34, 20, 41, 23, PALETTE["cat_body"])
    fill_rect(pixels, 39, 12, 41, 21, PALETTE["cat_body"])
    pixels[40, 12] = PALETTE["cat_dark"]
    # body
    fill_rect(pixels, 12, 14, 34, 33, PALETTE["cat_body"])
    fill_rect(pixels, 14, 12, 32, 13, PALETTE["cat_body"])
    fill_rect(pixels, 12, 33, 34, 34, PALETTE["cat_dark"])
    fill_rect(pixels, 17, 22, 29, 33, PALETTE["cat_belly"])
    # tabby stripes
    fill_rect(pixels, 14, 16, 32, 16, PALETTE["cat_dark"])
    fill_rect(pixels, 14, 19, 15, 32, PALETTE["cat_dark"])
    fill_rect(pixels, 31, 19, 32, 32, PALETTE["cat_dark"])
    # pointy ears
    fill_rect(pixels, 10, 5, 15, 12, PALETTE["cat_body"])
    fill_rect(pixels, 29, 5, 34, 12, PALETTE["cat_body"])
    pixels[10, 4] = PALETTE["cat_body"]
    pixels[34, 4] = PALETTE["cat_body"]
    fill_rect(pixels, 11, 8, 13, 11, PALETTE["cat_ear"])
    fill_rect(pixels, 31, 8, 33, 11, PALETTE["cat_ear"])
    # eyes
    if happy:
        for x, y in [(16, 19), (17, 18), (18, 18), (19, 19)]:
            pixels[x, y] = PALETTE["cat_eye"]
        for x, y in [(25, 19), (26, 18), (27, 18), (28, 19)]:
            pixels[x, y] = PALETTE["cat_eye"]
    else:
        fill_rect(pixels, 16, 18, 18, 20, PALETTE["cat_eye"])
        fill_rect(pixels, 26, 18, 28, 20, PALETTE["cat_eye"])
    # nose and mouth
    fill_rect(pixels, 21, 23, 23, 24, PALETTE["cat_nose"])
    if happy:
        for x, y in [(19, 26), (20, 27), (21, 27), (23, 27), (24, 27), (25, 26)]:
            pixels[x, y] = PALETTE["cat_dark"]
    # whiskers
    fill_rect(pixels, 10, 25, 17, 25, PALETTE["cat_dark"])
    fill_rect(pixels, 27, 25, 34, 25, PALETTE["cat_dark"])
    # feet
    fill_rect(pixels, 14, 34, 18, 36, PALETTE["cat_dark"])
    fill_rect(pixels, 28, 34, 32, 36, PALETTE["cat_dark"])
    return image


def _draw_cat_ear(pixels, cx, base_y, height, color):
    for i in range(height + 1):
        span = height - i
        fill_rect(pixels, cx - span, base_y - i, cx + span, base_y - i, color)


def draw_cat_angry():
    image = new_image(32, 32)
    pixels = image.load()
    fill_rect(pixels, 0, 0, 31, 31, PALETTE["portrait_back"])
    _draw_cat_ear(pixels, 11, 11, 5, PALETTE["cat_body"])
    _draw_cat_ear(pixels, 20, 11, 5, PALETTE["cat_body"])
    _draw_cat_ear(pixels, 11, 10, 2, PALETTE["cat_ear"])
    _draw_cat_ear(pixels, 20, 10, 2, PALETTE["cat_ear"])
    # head
    fill_rect(pixels, 7, 11, 24, 27, PALETTE["cat_body"])
    fill_rect(pixels, 7, 27, 24, 28, PALETTE["cat_dark"])
    fill_rect(pixels, 11, 20, 20, 27, PALETTE["cat_belly"])
    # tabby forehead stripes
    fill_rect(pixels, 14, 12, 14, 15, PALETTE["cat_dark"])
    fill_rect(pixels, 17, 12, 17, 15, PALETTE["cat_dark"])
    # angry, slanted green eyes
    for x, y in [(10, 16), (11, 17), (12, 17), (13, 18)]:
        pixels[x, y] = PALETTE["cat_eye"]
    for x, y in [(21, 16), (20, 17), (19, 17), (18, 18)]:
        pixels[x, y] = PALETTE["cat_eye"]
    pixels[12, 17] = PALETTE["outline"]
    pixels[19, 17] = PALETTE["outline"]
    # nose and a frowning mouth
    fill_rect(pixels, 15, 21, 16, 22, PALETTE["cat_nose"])
    for x, y in [(13, 24), (14, 23), (15, 23), (16, 23), (17, 23), (18, 24)]:
        pixels[x, y] = PALETTE["mouth"]
    # whiskers
    fill_rect(pixels, 4, 22, 10, 22, PALETTE["cat_dark"])
    fill_rect(pixels, 21, 22, 27, 22, PALETTE["cat_dark"])
    _draw_anger_mark(pixels)
    return image


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
    save(draw_tileset_atlas(), "tileset_atlas.png", directory)
    save(draw_player_spritesheet(), "player_spritesheet.png", directory)
    save(draw_desi_sprite(), "desi.png", directory)
    save(draw_desi_spritesheet(), "desi_spritesheet.png", directory)
    save(draw_desi_portrait(), "desi_portrait.png", directory)
    save(draw_desi_kiss(), "desi_kiss.png", directory)
    save(draw_desi_wink(), "desi_wink.png", directory)
    save(draw_desi_smile(), "desi_smile.png", directory)
    save(draw_mouse_spritesheet(), "mouse_spritesheet.png", directory)
    save(draw_mouse_battle(), "mouse_battle.png", directory)
    save(draw_cat_spritesheet(), "cat_spritesheet.png", directory)
    save(draw_cat_battle(), "cat_battle.png", directory)
    save(draw_cat_battle_happy(), "cat_battle_happy.png", directory)
    save(draw_cat_angry(), "cat_angry.png", directory)
    save(draw_player_battle(), "player_battle.png", directory)
    save(draw_combat_bg(), "combat_bg.png", directory)
    save(draw_player_carry_spritesheet(), "player_carry_spritesheet.png", directory)
    save(draw_marker_exclaim(), "marker_exclaim.png", directory)
    save(draw_marker_check(), "marker_check.png", directory)
    save(draw_heart(), "heart.png", directory)
    save(draw_trash_bag(), "trash_bag.png", directory)
    save(draw_empty_bag(), "empty_bag.png", directory)
    save(draw_trash_banana(), "trash_banana.png", directory)
    save(draw_trash_can_litter(), "trash_can_litter.png", directory)
    save(draw_trash_paper(), "trash_paper.png", directory)
    save(draw_trash_fishbone(), "trash_fishbone.png", directory)
    save(draw_trash_apple(), "trash_apple.png", directory)
    save(draw_star(), "star.png", directory)
    save(draw_garden_grass(), "garden_grass.png", directory)
    save(draw_garden_path(), "garden_path.png", directory)
    save(draw_fence(), "fence.png", directory)
    save(draw_trash_container(), "trash_container.png", directory)
    save(draw_door(), "door.png", directory)
    save(draw_kitchen_counter(), "kitchen_counter.png", directory)
    save(draw_dining_table(), "dining_table.png", directory)
    save(draw_trash_can(), "trash_can.png", directory)
    save(draw_sofa(), "sofa.png", directory)
    save(draw_rug(), "rug.png", directory)
    save(draw_coffee_table(), "coffee_table.png", directory)
    save(draw_window(), "window.png", directory)
    save(draw_wall_portrait(), "wall_portrait.png", directory)
    save(draw_icon(), "icon.png", directory)
    build_fonts(directory)


if __name__ == "__main__":
    main()
