"""Regenerate Frontline's indexed terrain and static detail layers from stock art."""
from pathlib import Path
import math
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = Path(__file__).resolve().parent / 'map_sources'

MAPS = (
    {
        'bitmap': 'Battlefield.png', 'detail_bitmap': 'BattlefieldDetails.png',
        'source': 'Battlefield.base.png', 'outposts': 3, 'base_y': 600,
        'veins': 8, 'gold_depth': 120, 'ridge_height': 75, 'ridge_foot': 45,
        'ridge_rise': 100, 'ridges': ((760, 1, 110), (1620, 1, 130), (2920, 1, 130)),
        'rocks': ((900, 84, 24, 20), (2100, 96, 30, 24), (3300, 108, 34, 27), (4400, 84, 26, 20)),
        'grass_count': 7, 'plant_count': 5, 'vegetation': 'plants',
    },
    {
        'bitmap': 'FrontlineExpanse.png', 'detail_bitmap': 'FrontlineExpanseDetails.png',
        'source': 'FrontlineExpanse.base.png', 'outposts': 5, 'base_y': 600,
        'veins': 16, 'gold_depth': 120, 'ridge_height': 75, 'ridge_foot': 45,
        'ridge_rise': 100,
        'ridges': ((850, 1, 100), (2350, 1, 140), (4050, 1, 150), (5800, 1, 150), (7500, 1, 140)),
        'rocks': ((1000, 90, 26, 20), (2800, 100, 30, 24), (4600, 110, 34, 28),
                  (6250, 110, 32, 25), (7900, 116, 36, 29), (9600, 96, 30, 23)),
        'grass_count': 14, 'plant_count': 10, 'vegetation': 'cacti',
    },
    {
        'bitmap': 'Highlands.png', 'detail_bitmap': 'HighlandsDetails.png',
        'source': 'Highlands.base.png', 'outposts': 9, 'base_y': 1100,
        'veins': 24, 'gold_depth': 270, 'ridge_height': 120, 'ridge_foot': 80,
        'ridge_rise': 100,
        'ridges': ((2100, 1, 150), (5200, 1, 180), (8300, 1, 180), (11400, 1, 180)),
        'rocks': ((900, 96, 28, 22), (3900, 104, 32, 26), (5700, 110, 34, 28),
                  (8500, 116, 38, 31), (10100, 110, 34, 28), (13200, 104, 32, 26)),
        'grass_count': 22, 'plant_count': 16, 'vegetation': 'plants',
        'bunker': {
            'surface_y': 1150, 'shaft_centers': (6912, 7200),
            'shaft_segments': 3, 'pad_halfwidth': 48, 'pad_blend': 120,
            'capture_outposts': (
                {'x': 4200, 'shaft_segments': 2},
                {'x': 11400, 'shaft_segments': 2},
            ),
        },
    },
)

AIR = 0
GOLD = 2
EARTH = 11
STONE = 12
GRASS = 128
GOLD_PER_VEIN = 679
GOLD_VEIN_LENGTH = 120
GOLD_VEIN_HALF_WIDTH = GOLD_VEIN_LENGTH // 2
BASE_CLEARANCE = 650
OUTPOST_CLEARANCE = 200
BUNKER_MATERIALS = {
    'End B': 'BunkerEndB.material.png',
    'End D': 'BunkerEndD.material.png',
    'Tunnel A': 'BunkerTunnelA.material.png',
    'T-Junction B': 'BunkerTJunctionB.material.png',
    'Shaft A': 'BunkerShaftA.material.png',
}
VEGETATION_ASSETS = {
    'plants': ('Plant000.png', 'Plant010.png', 'Plant030.png', 'Plant040.png', 'Plant050.png'),
    'cacti': ('Cactus001.png', 'Cactus005.png', 'Cactus010.png'),
}
VEGETATION_SCALE = 2


def surface_profile(image):
    pixels = image.load()
    result = []
    for x in range(image.width):
        for y in range(image.height):
            if pixels[x, y] != AIR:
                result.append(y)
                break
        else:
            raise ValueError(f'No terrain in column {x}')
    return result


def protected_outposts(width, count):
    return [int(width * index / (count + 1)) for index in range(1, count + 1)]


def ridge_bounds(spec, ridge):
    center, direction, plateau = ridge
    rise = spec['ridge_rise']
    ends = (center - direction * rise, center + direction * (plateau + rise))
    return min(ends), max(ends) + 1


def ridge_surface(spec, base_profile):
    result = list(base_profile)
    rise = spec['ridge_rise']
    for ridge in spec['ridges']:
        center, direction, plateau = ridge
        left, right = ridge_bounds(spec, ridge)
        for x in range(left, right):
            along = (x - center) * direction
            if along < -rise:
                delta = 0
            elif along < 0:
                delta = -spec['ridge_foot'] * (along + rise) / rise
            elif along < rise:
                delta = -spec['ridge_foot'] - (spec['ridge_height'] - spec['ridge_foot']) * along / rise
            elif along <= plateau:
                delta = -spec['ridge_height']
            elif along <= plateau + rise:
                delta = -spec['ridge_height'] * (plateau + rise - along) / rise
            else:
                delta = 0
            result[x] = base_profile[x] + round(delta)
    return result


def rock_rise(rock_index, center, patch_width, rock_height, x):
    taper = max(0.0, 1.0 - abs(x - center) / (patch_width / 2))
    wave = 0.84 + 0.16 * math.sin((x + rock_index * 19) * 0.17)
    return round(rock_height * math.sqrt(taper) * wave)


def bunker_layouts(spec):
    bunker = spec.get('bunker')
    if not bunker:
        return ()
    layouts = [bunker]
    for outpost in bunker.get('capture_outposts', ()):
        layouts.append({
            'surface_y': bunker['surface_y'],
            'shaft_centers': (outpost['x'],),
            'shaft_segments': outpost['shaft_segments'],
            'pad_halfwidth': bunker['pad_halfwidth'],
            'pad_blend': bunker['pad_blend'],
        })
    return tuple(layouts)


def bunker_objects_for_layout(bunker):
    shafts = bunker['shaft_centers']
    surface_y = bunker['surface_y']
    segments = bunker['shaft_segments']
    hall_y = surface_y + 48 + segments * 96
    objects = [('End B', shafts[0] - 192, hall_y, False)]
    shaft_centers = set(shafts)
    for center_x in range(shafts[0] - 96, shafts[-1] + 97, 96):
        name = 'T-Junction B' if center_x in shaft_centers else 'Tunnel A'
        objects.append((name, center_x, hall_y, False))
    objects.append(('End D', shafts[-1] + 192, hall_y, False))
    for center_x in shafts:
        for segment in range(segments):
            center_y = surface_y + 48 + segment * 96
            objects.append(('Shaft A', center_x, center_y, False))
    return tuple(objects)


def bunker_objects(spec):
    return tuple(
        obj
        for bunker in bunker_layouts(spec)
        for obj in bunker_objects_for_layout(bunker)
    )


def bunker_bounds(spec):
    bounds = []
    for bunker in bunker_layouts(spec):
        centers = [x for _, x, _, _ in bunker_objects_for_layout(bunker)]
        bounds.append((min(centers) - 48, max(centers) + 48))
    return tuple(bounds)


def bunker_shaft_centers(spec):
    return tuple(
        center
        for bunker in bunker_layouts(spec)
        for center in bunker['shaft_centers']
    )


def level_bunker_profile(profile, bunker):
    result = list(profile)
    original = list(profile)
    halfwidth, blend = bunker['pad_halfwidth'], bunker['pad_blend']
    for center_x in bunker['shaft_centers']:
        for x in range(center_x - blend, center_x + blend + 1):
            if not 0 <= x < len(result):
                continue
            distance = abs(x - center_x)
            if distance <= halfwidth:
                result[x] = bunker['surface_y']
            elif distance < blend:
                weight = (blend - distance) / (blend - halfwidth)
                result[x] = round(original[x] + (bunker['surface_y'] - original[x]) * weight)
    return result


def expected_surface_profile(spec, base_profile):
    result = ridge_surface(spec, base_profile)
    for rock_index, (center, patch_width, rock_height, _) in enumerate(spec['rocks']):
        for x in range(center - patch_width // 2, center + patch_width // 2):
            if 0 <= x < len(result):
                result[x] -= rock_rise(rock_index, center, patch_width, rock_height, x)
    for bunker in bunker_layouts(spec):
        result = level_bunker_profile(result, bunker)
    return result


def validate_layout(spec, width, height):
    posts = protected_outposts(width, spec['outposts'])
    for ridge in spec['ridges']:
        left, right = ridge_bounds(spec, ridge)
        if left < BASE_CLEARANCE or right >= width - BASE_CLEARANCE:
            raise ValueError(f'{spec["bitmap"]} ridge intrudes into a base approach: {ridge}')
        if any(left <= post + OUTPOST_CLEARANCE and right >= post - OUTPOST_CLEARANCE for post in posts):
            raise ValueError(f'{spec["bitmap"]} ridge intrudes into an outpost pad: {ridge}')

    bunker_ranges = bunker_bounds(spec)
    for center, patch_width, _, _ in spec['rocks']:
        left, right = center - patch_width // 2, center + patch_width // 2
        if left < BASE_CLEARANCE or right >= width - BASE_CLEARANCE:
            raise ValueError(f'{spec["bitmap"]} surface rock intrudes into a base approach: {center}')
        if any(left <= post + OUTPOST_CLEARANCE and right >= post - OUTPOST_CLEARANCE for post in posts):
            raise ValueError(f'{spec["bitmap"]} surface rock intrudes into an outpost pad: {center}')
        if any(left <= bunker_right and right >= bunker_left
               for bunker_left, bunker_right in bunker_ranges):
            raise ValueError(f'{spec["bitmap"]} surface rock overlaps its bunker: {center}')

    bunker = spec.get('bunker')
    for bunker_layout, (left, right) in zip(bunker_layouts(spec), bunker_ranges):
        if left < BASE_CLEARANCE or right >= width - BASE_CLEARANCE:
            raise ValueError(f'{spec["bitmap"]} bunker intrudes into a base approach')
        if any(left <= post + OUTPOST_CLEARANCE and right >= post - OUTPOST_CLEARANCE for post in posts):
            raise ValueError(f'{spec["bitmap"]} bunker intrudes into an outpost pad')
        hall_y = bunker_layout['surface_y'] + 48 + bunker_layout['shaft_segments'] * 96
        if hall_y + 48 >= height:
            raise ValueError(f'{spec["bitmap"]} bunker does not fit beneath the surface')
        if bunker_layout['surface_y'] <= 0 or bunker_layout['pad_halfwidth'] < 24:
            raise ValueError(f'{spec["bitmap"]} bunker shaft mouths are not safely grounded')

    if bunker:
        capture_outposts = bunker.get('capture_outposts', ())
        capture_x = [outpost['x'] for outpost in capture_outposts]
        if len(capture_x) != 2 or capture_x[0] + capture_x[1] != width:
            raise ValueError(f'{spec["bitmap"]} underground capture outposts must be mirrored')
        for outpost in capture_outposts:
            if outpost['shaft_segments'] < 2:
                raise ValueError(f'{spec["bitmap"]} capture outpost needs a connected vertical access shaft')
        for first_index, first in enumerate(bunker_ranges):
            for second in bunker_ranges[first_index + 1:]:
                if first[0] <= second[1] and second[0] <= first[1]:
                    raise ValueError(f'{spec["bitmap"]} bunker layouts overlap')


def vein_bounds(center_x):
    left = center_x - GOLD_VEIN_HALF_WIDTH
    return left, left + GOLD_VEIN_LENGTH


def vein_centers(spec, width):
    posts = protected_outposts(width, spec['outposts'])
    rocks = [(center, patch_width // 2) for center, patch_width, _, _ in spec['rocks']]
    bunker_ranges = tuple(
        (left - GOLD_VEIN_HALF_WIDTH, right + GOLD_VEIN_HALF_WIDTH)
        for left, right in bunker_bounds(spec)
    )
    low, high = BASE_CLEARANCE + 80, width - BASE_CLEARANCE - 80
    result = []
    for index in range(spec['veins']):
        target = low + (index + 0.5) * (high - low) / spec['veins']
        candidates = sorted(range(low, high + 1, 4), key=lambda x: (abs(x - target), x))
        for center in candidates:
            if any(abs(center - post) < 280 for post in posts):
                continue
            vein_left, vein_right = vein_bounds(center)
            if any(vein_left < right and left < vein_right for left, right in bunker_ranges):
                continue
            if any(abs(center - rock) < half_width + 80 for rock, half_width in rocks):
                continue
            if any(abs(center - prior) < 180 for prior in result):
                continue
            result.append(center)
            break
        else:
            raise ValueError(f'Could not place balanced gold vein {index + 1} on {spec["bitmap"]}')
    return result


def bunker_cavity_pixels(spec, width, height):
    pixels = set()
    materials = {}
    for name, center_x, center_y, h_flipped in bunker_objects(spec):
        if name not in materials:
            material = Image.open(SOURCE_DIR / BUNKER_MATERIALS[name])
            if material.mode != 'P' or material.size != (96, 96):
                raise ValueError(f'{BUNKER_MATERIALS[name]} must be a 96x96 indexed material mask')
            if tuple(material.getpalette()[3:6]) != (128, 0, 128):
                raise ValueError(f'{BUNKER_MATERIALS[name]} lost the engine air-mask color')
            materials[name] = material
        material = materials[name]
        for local_y in range(material.height):
            world_y = center_y - 48 + local_y
            for local_x in range(material.width):
                source_x = material.width - 1 - local_x if h_flipped else local_x
                if material.getpixel((source_x, local_y)) != 1:
                    continue
                world_x = center_x - 48 + local_x
                if not (0 <= world_x < width and 0 <= world_y < height):
                    raise ValueError(f'{spec["bitmap"]} bunker cavity exceeds map bounds at {(world_x, world_y)}')
                pixels.add((world_x, world_y))
    return pixels


def add_bunker_cavities(data, width, height, spec):
    pixels = bunker_cavity_pixels(spec, width, height)
    for x, y in pixels:
        data[y * width + x] = AIR
    return pixels


def add_ridges(data, width, height, spec, base_profile):
    profile = ridge_surface(spec, base_profile)
    for x, (base_y, surface_y) in enumerate(zip(base_profile, profile)):
        if surface_y < base_y:
            for y in range(surface_y, base_y):
                data[y * width + x] = EARTH
        elif surface_y > base_y:
            for y in range(base_y, min(height, surface_y)):
                data[y * width + x] = AIR
    return profile


def add_surface_rocks(data, profile, width, height, spec):
    result = list(profile)
    for rock_index, (center, patch_width, rock_height, buried_depth) in enumerate(spec['rocks']):
        for x in range(center - patch_width // 2, center + patch_width // 2):
            if not 0 <= x < width:
                continue
            top = profile[x] - rock_rise(rock_index, center, patch_width, rock_height, x)
            result[x] = top
            for y in range(max(0, top), min(height, profile[x] + buried_depth)):
                data[y * width + x] = STONE
    return result


def add_bunker_pads(data, profile, width, height, spec):
    result = list(profile)
    for bunker in bunker_layouts(spec):
        target = level_bunker_profile(result, bunker)
        for x, (old_y, new_y) in enumerate(zip(result, target)):
            if new_y < old_y:
                for y in range(new_y, old_y):
                    data[y * width + x] = EARTH
            elif new_y > old_y:
                for y in range(old_y, min(height, new_y)):
                    data[y * width + x] = AIR
        result = target
    return result


def grass_centers(spec, width):
    posts = protected_outposts(width, spec['outposts'])
    rocks = [(center, patch_width // 2) for center, patch_width, _, _ in spec['rocks']]
    bunker_ranges = bunker_bounds(spec)
    low, high = BASE_CLEARANCE + 48, width - BASE_CLEARANCE - 48
    result = []
    count = spec['grass_count']
    for index in range(count):
        target = low + (index + 0.5) * (high - low) / count
        candidates = sorted(range(low, high + 1, 4), key=lambda x: (abs(x - target), x))
        for center in candidates:
            if any(abs(center - post) < OUTPOST_CLEARANCE + 40 for post in posts):
                continue
            if any(abs(center - rock) < half_width + 40 for rock, half_width in rocks):
                continue
            if any(left - 48 <= center <= right + 48 for left, right in bunker_ranges):
                continue
            if any(abs(center - prior) < 70 for prior in result):
                continue
            result.append(center)
            break
        else:
            raise ValueError(f'Could not place surface grass patch {index + 1} on {spec["bitmap"]}')
    return result


def add_surface_grass(data, profile, width, height, spec):
    for index, center in enumerate(grass_centers(spec, width)):
        patch_width = (28, 36, 42, 32)[index % 4]
        patch_depth = (8, 12, 14, 10)[index % 4]
        for x in range(center - patch_width // 2, center + patch_width // 2):
            taper = max(0.0, 1.0 - abs(x - center) / (patch_width / 2))
            depth = max(1, round(patch_depth * math.sqrt(taper)))
            for y in range(profile[x], min(height, profile[x] + depth)):
                data[y * width + x] = GRASS


def plant_centers(spec, width, profile):
    posts = protected_outposts(width, spec['outposts'])
    rocks = [(center, patch_width // 2) for center, patch_width, _, _ in spec['rocks']]
    bunker_ranges = bunker_bounds(spec)
    low, high = BASE_CLEARANCE + 100, width - BASE_CLEARANCE - 100
    sprite_names = VEGETATION_ASSETS[spec['vegetation']]
    root_offsets_by_name = {}
    for sprite_name in sprite_names:
        sprite = Image.open(SOURCE_DIR / sprite_name).convert('RGB')
        sprite = sprite.resize(
            (sprite.width * VEGETATION_SCALE, sprite.height * VEGETATION_SCALE),
            Image.Resampling.NEAREST,
        )
        sprite_pixels = sprite.load()
        sprite_bottom = max(
            y for y in range(sprite.height)
            if any(sprite_pixels[x, y] != (255, 0, 255) for x in range(sprite.width))
        )
        root_offsets_by_name[sprite_name] = [
            x - sprite.width // 2 for x in range(sprite.width)
            if sprite_pixels[x, sprite_bottom] != (255, 0, 255)
        ]

    result = []
    count = spec['plant_count']
    for index in range(count):
        target = low + (index + 0.5) * (high - low) / count
        candidates = sorted(range(low, high + 1, 8), key=lambda x: (abs(x - target), x))
        root_offsets = root_offsets_by_name[sprite_names[index % len(sprite_names)]]
        for center in candidates:
            if any(abs(center - post) < OUTPOST_CLEARANCE + 80 for post in posts):
                continue
            if any(abs(center - rock) < half_width + 80 for rock, half_width in rocks):
                continue
            if any(left - 100 <= center <= right + 100 for left, right in bunker_ranges):
                continue
            if any(abs(center - prior) < 220 for prior in result):
                continue
            local = profile[max(0, center - 8):min(width, center + 9)]
            if max(local) - min(local) > 6:
                continue
            if not any(
                0 <= center + offset < width and profile[center + offset] >= profile[center]
                for offset in root_offsets
            ):
                continue
            result.append(center)
            break
        else:
            raise ValueError(f'Could not place grounded surface vegetation {index + 1} on {spec["bitmap"]}')
    return result


def centerline(length, seed):
    result = []
    previous = 0
    phase = seed * 0.731
    for step in range(length):
        raw = round(3.0 * math.sin(step * 0.113 + phase)
                    + 2.0 * math.sin(step * 0.287 + phase * 0.61))
        if result:
            raw = max(previous - 1, min(previous + 1, raw))
        result.append(raw)
        previous = raw
    return result


def make_vein(center_x, ground_profile, depth, seed):
    length = GOLD_VEIN_LENGTH
    first_x = center_x - length // 2
    offsets = centerline(length, seed)
    pixels = set()
    for step, offset in enumerate(offsets):
        x = first_x + step
        center_y = ground_profile[x] + depth + offset
        for y in range(center_y - 2, center_y + 3):
            pixels.add((x, y))

    branch_specs = ((12, 20), (40, 20), (68, 19), (96, 20))
    for branch_index, (step, branch_length) in enumerate(branch_specs):
        x = first_x + step
        side = 1 if (seed + branch_index) % 2 else -1
        current_x = x
        current_y = ground_profile[x] + depth + offsets[step] + side * 2
        horizontal_direction = 1 if (seed + branch_index) % 3 else -1
        added = 0
        while added < branch_length:
            if added < 5 or added % 4 != 3:
                candidate = (current_x, current_y + side)
            else:
                candidate = (current_x + horizontal_direction, current_y)
            if candidate in pixels:
                candidate = (candidate[0], candidate[1] + side)
            current_x, current_y = candidate
            pixels.add(candidate)
            added += 1

    if len(pixels) != GOLD_PER_VEIN:
        raise ValueError(f'Vein generator produced {len(pixels)} pixels, expected {GOLD_PER_VEIN}')
    return pixels


def build_map(spec):
    source = Image.open(SOURCE_DIR / spec['source'])
    if source.mode != 'P':
        raise ValueError(f'{spec["source"]} must remain indexed color')
    palette = source.getpalette()
    expected_colors = {
        AIR: (255, 0, 255), GOLD: (255, 209, 41), EARTH: (140, 110, 70),
        STONE: (90, 85, 80), GRASS: (105, 170, 90),
    }
    for material_id, color in expected_colors.items():
        if tuple(palette[material_id * 3:material_id * 3 + 3]) != color:
            raise ValueError(f'{spec["source"]} palette index {material_id} does not match its engine material')

    width, height = source.size
    base_profile = surface_profile(source)
    if any(base_profile[x] != spec['base_y'] for x in (180, 335, 495, width - 180, width - 335, width - 495)):
        raise ValueError(f'{spec["source"]} base approaches no longer match configured ground')
    validate_layout(spec, width, height)
    source_data = source.tobytes()
    old_gold_count = source_data.count(GOLD)
    if old_gold_count != spec['veins'] * GOLD_PER_VEIN:
        raise ValueError(f'{spec["source"]} gold baseline changed: {old_gold_count} pixels')

    remap = list(range(256))
    remap[GOLD] = EARTH
    data = bytearray(source.point(remap).tobytes())
    profile = add_ridges(data, width, height, spec, base_profile)
    profile = add_surface_rocks(data, profile, width, height, spec)
    profile = add_bunker_pads(data, profile, width, height, spec)
    bunker_pixels = add_bunker_cavities(data, width, height, spec)
    add_surface_grass(data, profile, width, height, spec)

    centers = vein_centers(spec, width)
    for index, center_x in enumerate(centers):
        lode = make_vein(center_x, base_profile, spec['gold_depth'], index + 1)
        vein_left, vein_right = vein_bounds(center_x)
        if any(not vein_left <= x < vein_right for x, _ in lode):
            raise ValueError(f'{spec["bitmap"]} Gold branch exceeds its reserved lode footprint')
        for x, y in lode:
            if not (0 <= x < width and 0 <= y < height):
                raise ValueError(f'{spec["bitmap"]} gold vein extends outside the map')
            offset = y * width + x
            if data[offset] not in (EARTH, STONE):
                raise ValueError(f'{spec["bitmap"]} Gold lode intersects an open bunker at {(x, y)}')
            data[offset] = GOLD

    result = Image.frombytes('P', source.size, bytes(data))
    result.putpalette(palette)
    return result


def build_detail_background(spec):
    source = Image.open(SOURCE_DIR / spec['source'])
    base_profile = surface_profile(source)
    profile = expected_surface_profile(spec, base_profile)
    width, height = source.size
    plants = []
    sprite_names = VEGETATION_ASSETS[spec['vegetation']]
    for index, center_x in enumerate(plant_centers(spec, width, profile)):
        sprite = Image.open(SOURCE_DIR / sprite_names[index % len(sprite_names)]).convert('RGB')
        sprite = sprite.resize(
            (sprite.width * VEGETATION_SCALE, sprite.height * VEGETATION_SCALE),
            Image.Resampling.NEAREST,
        )
        sprite_pixels = sprite.load()
        sprite_bottom = max(
            y for y in range(sprite.height)
            if any(sprite_pixels[x, y] != (255, 0, 255) for x in range(sprite.width))
        )
        plants.append((center_x, profile[center_x], sprite, sprite_bottom))

    cave_pixels = bunker_cavity_pixels(spec, width, height)
    top = min([y for _, y in cave_pixels]
              + [ground_y - sprite_bottom - 1 for _, ground_y, _, sprite_bottom in plants])
    bottom = max([y + 1 for _, y in cave_pixels]
                 + [ground_y for _, ground_y, _, _ in plants])
    background = Image.open(SOURCE_DIR / 'DirtRoughBG.png').convert('RGB')
    dirt_colors = [color for _, color in background.getcolors(maxcolors=65536) if color != (255, 0, 255)]
    if not dirt_colors:
        raise ValueError('DirtRoughBG.png has no opaque soil pixels')
    dirt_fallback = dirt_colors[0]

    canvas = Image.new('RGB', (width, bottom - top), (255, 0, 255))
    opaque = Image.new('L', canvas.size, 0)
    canvas_pixels, opaque_pixels = canvas.load(), opaque.load()
    for x, y in cave_pixels:
        color = background.getpixel((x % background.width, y % background.height))
        if color == (255, 0, 255):
            color = dirt_fallback
        canvas_pixels[x, y - top] = color
        opaque_pixels[x, y - top] = 255

    for center_x, ground_y, sprite, sprite_bottom in plants:
        left = center_x - sprite.width // 2
        sprite_pixels = sprite.load()
        for local_y in range(sprite.height):
            world_y = ground_y - sprite_bottom - 1 + local_y
            for local_x in range(sprite.width):
                color = sprite_pixels[local_x, local_y]
                if color == (255, 0, 255):
                    continue
                world_x = left + local_x
                if not 0 <= world_x < width or world_y >= profile[world_x]:
                    continue
                canvas_pixels[world_x, world_y - top] = color
                opaque_pixels[world_x, world_y - top] = 255

    quantized = canvas.quantize(colors=255, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    palette = [255, 0, 255] + quantized.getpalette()[:765]
    opaque_data = opaque.tobytes()
    quantized_data = quantized.tobytes()
    indexed_data = bytes(value + 1 if opaque_data[index] else 0 for index, value in enumerate(quantized_data))
    result = Image.frombytes('P', canvas.size, indexed_data)
    result.putpalette(palette)
    return result, top


def outputs_for_map(spec):
    detail, detail_origin_y = build_detail_background(spec)
    return (
        (ROOT / 'Frontline.rte' / spec['bitmap'], build_map(spec), None),
        (ROOT / 'Frontline.rte' / spec['detail_bitmap'], detail, detail_origin_y),
    )




def process_output(output_path, generated, origin_y, check):
    if check:
        checked_in = Image.open(output_path)
        if (checked_in.mode != 'P' or checked_in.size != generated.size
                or checked_in.tobytes() != generated.tobytes()
                or checked_in.getpalette() != generated.getpalette()):
            raise SystemExit(f'{output_path.name} differs from deterministic generation')
        print(f'{output_path.name}: deterministic indexed data matches'
              + (f' (world Y {origin_y})' if origin_y is not None else ''))
    else:
        generated.save(output_path, format='PNG', optimize=True)
        print(f'Wrote {output_path.relative_to(ROOT)} ({generated.width}x{generated.height})'
              + (f', world Y {origin_y}' if origin_y is not None else ''))


def main():
    check = len(sys.argv) == 2 and sys.argv[1] == '--check'
    if len(sys.argv) > 2 or (len(sys.argv) == 2 and not check):
        raise SystemExit('Usage: python3 tools/generate_frontline_maps.py [--check]')
    for spec in MAPS:
        for output_path, generated, origin_y in outputs_for_map(spec):
            process_output(output_path, generated, origin_y, check)


if __name__ == '__main__':
    main()
