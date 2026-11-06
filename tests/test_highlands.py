"""Validate indexed terrain materials, bunker connectivity and surface detail for every Frontline map."""
from collections import deque
from pathlib import Path
import re
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'Frontline.rte'
SOURCE_DIR = ROOT.parent / 'tools' / 'map_sources'
SCENARIO = (ROOT / 'Scenario.ini').read_text()
sys.path.insert(0, str(ROOT.parent / 'tools'))
import generate_frontline_maps as terrain

MAPS = (
    {
        'scene': 'Frontline Battlefield', 'terrain': 'Frontline Terrain',
        'bitmap': 'Battlefield.png', 'detail_bitmap': 'BattlefieldDetails.png',
        'size': (5200, 800), 'base_y': 600, 'outposts': 3,
        'gold_pixels': 5432, 'veins': 8, 'profile_span': (70, 190),
        'backgrounds': ['Default Front', 'Mountains Middle', 'Clouds Layer A', 'Mountains Backdrop Layer'],
    },
    {
        'scene': 'Frontline Expanse Battlefield', 'terrain': 'Frontline Expanse Terrain',
        'bitmap': 'FrontlineExpanse.png', 'detail_bitmap': 'FrontlineExpanseDetails.png',
        'size': (10400, 800), 'base_y': 600, 'outposts': 5,
        'gold_pixels': 10864, 'veins': 16, 'profile_span': (70, 210),
        'backgrounds': ['Desert Front', 'Desert Middle', 'Clouds Layer B Middle', 'Default Sky Layer'],
    },
    {
        'scene': 'Frontline Highlands Battlefield', 'terrain': 'Frontline Highlands Terrain',
        'bitmap': 'Highlands.png', 'detail_bitmap': 'HighlandsDetails.png',
        'size': (15600, 1600), 'base_y': 1100, 'outposts': 9, 'capture_outposts': 2,
        'gold_pixels': 16296, 'veins': 24, 'profile_span': (200, 520),
        'backgrounds': ['Mountains Front', 'Mountains Back', 'Clouds Layer B Middle', 'Mountains Backdrop Layer'],
    },
)
SPEC_BY_BITMAP = {spec['bitmap']: spec for spec in terrain.MAPS}


def scene_block(name):
    start = SCENARIO.index(f'PresetName = {name}')
    end = SCENARIO.index('Name = Frontline Battlefield Only', start)
    return SCENARIO[start:end]


def terrain_block(name):
    start = SCENARIO.index(f'PresetName = {name}')
    end = SCENARIO.index('\n\n', start)
    return SCENARIO[start:end]


def flood_connected(image, start, target, bounds):
    left, top, right, bottom = bounds
    pixels = image.load()
    queue = deque([start])
    visited = {start}
    while queue:
        x, y = queue.popleft()
        if (x, y) == target:
            return True
        for next_x, next_y in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            point = (next_x, next_y)
            if (left <= next_x < right and top <= next_y < bottom
                    and point not in visited and pixels[next_x, next_y] == terrain.AIR):
                visited.add(point)
                queue.append(point)
    return False


def gold_components(image):
    width = image.width
    gold_pixels = {
        (offset % width, offset // width)
        for offset, material in enumerate(image.tobytes())
        if material == terrain.GOLD
    }
    components = []
    while gold_pixels:
        start = gold_pixels.pop()
        component = {start}
        queue = [start]
        while queue:
            x, y = queue.pop()
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor in gold_pixels:
                    gold_pixels.remove(neighbor)
                    component.add(neighbor)
                    queue.append(neighbor)
        components.append(component)
    return components


def detail_layer_origin(scene, bitmap_name):
    pattern = (
        r'AddBackgroundLayer = SLBackground\s+AddToGroup = Near Backdrops\s+'
        r'DrawTransparent = 1\s+IgnoreAutoScaling = 1\s+WrapX = 0\s+WrapY = 0\s+'
        r'ScrollRatio = Vector\s+X = 1\s+Y = 1\s+'
        r'OriginPointOffset = Vector\s+X = 0\s+Y = (\d+)\s+'
        r'BitmapFile = ContentFile\s+FilePath = Frontline\.rte/'
        + re.escape(bitmap_name)
    )
    match = re.search(pattern, scene)
    assert match, f'{bitmap_name} must be a world-aligned transparent foreground detail layer'
    return int(match.group(1))


def assert_safe_surface_features(image, source, spec):
    width, height = image.size
    base_profile = terrain.surface_profile(source)
    expected_profile = terrain.expected_surface_profile(spec, base_profile)
    data = image.tobytes()
    source_data = source.tobytes()

    # Preserve exact base approach silhouettes and every outpost's ground pad.
    for y in range(height):
        row = y * width
        for x in range(650):
            assert (data[row + x] == terrain.AIR) == (source_data[row + x] == terrain.AIR)
            edge_x = width - 650 + x
            assert (data[row + edge_x] == terrain.AIR) == (source_data[row + edge_x] == terrain.AIR)
    for post in terrain.protected_outposts(width, spec['outposts']):
        for x in range(post - 60, post + 61):
            assert expected_profile[x] == base_profile[x], f'{spec["bitmap"]} altered outpost pad at {x}'
            assert data[expected_profile[x] * width + x] != terrain.AIR

    # Every non-shaft column has the expected surface, reachable ground height,
    # and a continuous solid route beneath that surface.
    bunker_cells = terrain.bunker_cavity_pixels(spec, width, height)
    bunker = spec.get('bunker')
    shaft_columns = {
        x for center in terrain.bunker_shaft_centers(spec) for x in range(center - 24, center + 24)
    }
    samples = [expected_profile[x] for x in range(600, width - 600, 20)]
    minimum, maximum = spec['profile_span']
    assert minimum <= max(samples) - min(samples) <= maximum, f'{spec["bitmap"]} terrain profile changed'
    assert all(abs(a - b) <= 150 for a, b in zip(samples, samples[1:])), (
        f'{spec["bitmap"]} contains a traversal-breaking surface slope'
    )
    for x, surface_y in enumerate(expected_profile):
        if x not in shaft_columns:
            assert data[surface_y * width + x] != terrain.AIR, (
                f'{spec["bitmap"]} lost ground at accessible column {x}'
            )
        for y in range(surface_y, height):
            if data[y * width + x] == terrain.AIR:
                assert (x, y) in bunker_cells, (
                    f'{spec["bitmap"]} has an unplanned underground cavity at {(x, y)}'
                )

    # Deliberate surface outcrops are raised Stone masses, not merely buried
    # stripes; none intersects a base, outpost pad or Highlands bunker.
    ridge_profile = terrain.ridge_surface(spec, base_profile)
    for rock_index, (center, patch_width, rock_height, buried_depth) in enumerate(spec['rocks']):
        left, right = center - patch_width // 2, center + patch_width // 2
        assert expected_profile[center] <= ridge_profile[center] - rock_height * 0.6
        assert image.getpixel((center, expected_profile[center])) == terrain.STONE
        assert sum(
            data[y * width + x] == terrain.STONE
            for x in range(left, right)
            for y in range(max(0, expected_profile[x]), min(height, ridge_profile[x] + buried_depth))
        ) >= patch_width * rock_height // 2
        assert all(abs(center - post) >= terrain.OUTPOST_CLEARANCE + patch_width // 2
                   for post in terrain.protected_outposts(width, spec['outposts']))

    # Sparse, indexed Grass marks the actual surface without blocking a lane.
    for center in terrain.grass_centers(spec, width):
        assert image.getpixel((center, expected_profile[center])) == terrain.GRASS

    # Original Gold remains the exact mineable material and balanced total,
    # arranged as connected lodes with the branch-expanded footprint protected.
    components = gold_components(image)
    assert len(components) == spec['veins']
    assert sum(map(len, components)) == spec['gold_pixels']
    centers = []
    bunker_ranges = terrain.bunker_bounds(spec)
    for component in components:
        assert len(component) == terrain.GOLD_PER_VEIN
        xs = [x for x, _ in component]
        ys = [y for _, y in component]
        bounds_width = max(xs) - min(xs) + 1
        bounds_height = max(ys) - min(ys) + 1
        assert bounds_width >= 110 and bounds_width >= bounds_height * 1.9
        center_x = (min(xs) + max(xs)) // 2
        centers.append(center_x)
        assert all(
            max(xs) < left - terrain.GOLD_VEIN_HALF_WIDTH
            or min(xs) > right + terrain.GOLD_VEIN_HALF_WIDTH
            for left, right in bunker_ranges
        ), f'{spec["bitmap"]} Gold lode branch overlaps a Highlands bunker'
        assert min(y - expected_profile[x] for x, y in component) >= 8
        for x, y in component:
            assert all(data[ny * width + nx] != terrain.AIR for nx, ny in (
                (x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)
            ) if 0 <= nx < width and 0 <= ny < height)
    centers.sort()
    assert all(b - a >= 180 for a, b in zip(centers, centers[1:]))

    if not bunker:
        assert not bunker_cells, f'{spec["bitmap"]} must remain surface-only'
        return expected_profile

    assert len(bunker_cells) > 12000, 'Highlands must stamp the base bunker and both capture halls'
    bunker_ranges = terrain.bunker_bounds(spec)
    layouts = terrain.bunker_layouts(spec)
    assert len(layouts) == 3 and len(bunker_ranges) == 3
    for layout_index, bunker_layout in enumerate(layouts):
        surface_y = bunker_layout['surface_y']
        hall_center_y = surface_y + 48 + bunker_layout['shaft_segments'] * 96
        corridor_left, corridor_right = bunker_ranges[layout_index]
        shafts = bunker_layout['shaft_centers']
        for center in shafts:
            assert all(data[(surface_y + 1) * width + x] == terrain.AIR
                       for x in range(center - 24, center + 24))
            assert data[(surface_y + 1) * width + center - 25] != terrain.AIR
            assert data[(surface_y + 1) * width + center + 24] != terrain.AIR
        # Stock bunker masks provide a 48px-high air corridor above the
        # material floor. Check its full cross-section, not a single sample.
        assert all(data[(hall_center_y + dy) * width + x] == terrain.AIR
                   for x in range(corridor_left + 24, corridor_right - 24)
                   for dy in range(-24, 24))
        assert all(data[(hall_center_y + 24) * width + x] != terrain.AIR
                   for x in range(corridor_left + 24, corridor_right - 24))
        target_x = shafts[-1] if len(shafts) > 1 else shafts[0] + 96
        assert flood_connected(
            image,
            (shafts[0], surface_y + 12),
            (target_x, hall_center_y),
            (corridor_left + 24, surface_y, corridor_right - 24, hall_center_y + 1),
        ), 'Highlands surface entrances must connect through character-width roofed bunker halls'

    capture_outposts = bunker['capture_outposts']
    assert len(capture_outposts) == len(layouts) - 1
    assert [(post['x'], post['shaft_segments']) for post in capture_outposts] == [(4200, 2), (11400, 2)]
    assert capture_outposts[0]['x'] + capture_outposts[1]['x'] == width
    for outpost, layout in zip(capture_outposts, layouts[1:]):
        assert layout['shaft_centers'] == (outpost['x'],)
        assert layout['shaft_segments'] == outpost['shaft_segments']
    for outpost in capture_outposts:
        for x in range(outpost['x'] - bunker['pad_halfwidth'],
                       outpost['x'] + bunker['pad_halfwidth'] + 1):
            assert expected_profile[x] == bunker['surface_y']
            if x < outpost['x'] - 24 or x >= outpost['x'] + 24:
                assert data[bunker['surface_y'] * width + x] != terrain.AIR
        assert all(data[bunker['surface_y'] * width + x] == terrain.AIR
                   for x in range(outpost['x'] - 24, outpost['x'] + 24))
    return expected_profile


def assert_grounded_vegetation(detail, spec, profile, detail_origin):
    sprite_names = terrain.VEGETATION_ASSETS[spec['vegetation']]
    width = detail.width
    for index, center_x in enumerate(terrain.plant_centers(spec, width, profile)):
        sprite = Image.open(
            SOURCE_DIR / sprite_names[index % len(sprite_names)]
        ).convert('RGB')
        sprite = sprite.resize(
            (sprite.width * terrain.VEGETATION_SCALE, sprite.height * terrain.VEGETATION_SCALE),
            Image.Resampling.NEAREST,
        )
        sprite_pixels = sprite.load()
        sprite_bottom = max(
            y for y in range(sprite.height)
            if any(sprite_pixels[x, y] != (255, 0, 255) for x in range(sprite.width))
        )
        surface_y = profile[center_x]
        sprite_top = surface_y - sprite_bottom - 1
        left = center_x - sprite.width // 2
        rooted_pixels = 0
        for local_y in range(sprite.height):
            world_y = sprite_top + local_y
            for local_x in range(sprite.width):
                if sprite_pixels[local_x, local_y] == (255, 0, 255):
                    continue
                world_x = left + local_x
                detail_pixel = detail.getpixel((world_x, world_y - detail_origin))
                if world_y < profile[world_x]:
                    assert detail_pixel != 0, (
                        f'{spec["bitmap"]} vegetation at {(world_x, world_y)} is missing above ground'
                    )
                    rooted_pixels += local_y == sprite_bottom
                else:
                    assert detail_pixel == 0, (
                        f'{spec["bitmap"]} vegetation at {(world_x, world_y)} is buried below ground'
                    )
        assert rooted_pixels, f'{spec["bitmap"]} vegetation at {center_x} does not touch the surface'




for map_data in MAPS:
    scene = scene_block(map_data['scene'])
    terrain_text = terrain_block(map_data['terrain'])
    width = int(re.search(r'Width = (\d+)', scene).group(1))
    height = int(re.search(r'Height = (\d+)', scene).group(1))
    assert (width, height) == map_data['size']
    assert re.search(rf'Terrain = SLTerrain\s+CopyOf = {re.escape(map_data["terrain"])}', scene)
    layers = re.findall(r'AddBackgroundLayer = SLBackground\s+CopyOf = ([^\n]+)', scene)
    assert layers == map_data['backgrounds']
    detail_origin = detail_layer_origin(scene, map_data['detail_bitmap'])
    detail_layer = re.search(
        r'AddBackgroundLayer = SLBackground(?:(?!AddBackgroundLayer = SLBackground).)*'
        + rf'FilePath = Frontline\.rte/{re.escape(map_data["detail_bitmap"])}',
        scene, re.S,
    )
    assert (
        detail_layer
        and detail_layer.start() == scene.index('AddBackgroundLayer = SLBackground')
        and re.search(r'IgnoreAutoScaling = 1', detail_layer.group(0))
    ), f'{map_data["detail_bitmap"]} must be world-scaled and drawn over the other backdrops'

    bitmap_name = re.search(r'FilePath = Frontline\.rte/([^\s]+\.png)', terrain_text).group(1)
    assert bitmap_name == map_data['bitmap']
    image = Image.open(ROOT / bitmap_name)
    source = Image.open(SOURCE_DIR / SPEC_BY_BITMAP[bitmap_name]['source'])
    detail = Image.open(ROOT / map_data['detail_bitmap'])
    spec = {**SPEC_BY_BITMAP[bitmap_name], 'profile_span': map_data['profile_span'], 'gold_pixels': map_data['gold_pixels']}
    assert image.mode == source.mode == detail.mode == 'P'
    assert image.size == source.size == map_data['size']
    assert detail.width == width and detail_origin + detail.height <= height
    assert width < 32768 // 2, 'map exceeds the measured texture-chunk limit'

    palette = image.getpalette()
    assert tuple(palette[0:3]) == (255, 0, 255), 'index 0 must remain magenta air'
    assert tuple(palette[6:9]) == (255, 209, 41), 'index 2 must remain Gold'
    assert tuple(palette[33:36]) == (140, 110, 70), 'index 11 must remain Dense Earth'
    assert tuple(palette[36:39]) == (90, 85, 80), 'index 12 must remain Stone'
    assert tuple(palette[384:387]) == (105, 170, 90), 'index 128 must remain Grass'
    assert palette == source.getpalette(), 'terrain material palette must remain the indexed template palette'
    histogram = image.histogram()
    assert [index for index, count in enumerate(histogram) if count] == [0, 2, 11, 12, 128]
    assert histogram[2] == map_data['gold_pixels']
    assert histogram[12] > 0 and histogram[128] > spec['grass_count'] * 2
    assert tuple(detail.getpalette()[0:3]) == (255, 0, 255), 'detail-layer index 0 must remain transparent magenta'
    assert any(detail.tobytes()), 'stock vegetation must appear in the detail layer'

    profile = assert_safe_surface_features(image, source, spec)
    detail_expected, expected_origin = terrain.build_detail_background(spec)
    assert expected_origin == detail_origin, f'{map_data["detail_bitmap"]} has a stale world-space Y offset'
    assert detail.tobytes() == detail_expected.tobytes() and detail.getpalette() == detail_expected.getpalette(), (
        f'{map_data["detail_bitmap"]} differs from deterministic stock detail generation'
    )
    assert_grounded_vegetation(detail, spec, profile, detail_origin)

    bunker_cells = terrain.bunker_cavity_pixels(spec, width, height)
    texture = Image.open(SOURCE_DIR / 'DirtRoughBG.png').convert('RGB')
    for x, y in bunker_cells:
        detail_index = detail.getpixel((x, y - detail_origin))
        assert detail_index != 0, f'{map_data["detail_bitmap"]} leaves bunker cavity at {(x, y)} unbacked'
        detail_color = tuple(detail.getpalette()[detail_index * 3:detail_index * 3 + 3])
        texture_color = texture.getpixel((x % texture.width, y % texture.height))
        if texture_color == (255, 0, 255):
            continue
        assert max(abs(a - b) for a, b in zip(detail_color, texture_color)) <= 60, (
            f'{map_data["detail_bitmap"]} must use the stock non-solid DirtRough background texture'
        )

    assert image.tobytes() == terrain.build_map(spec).tobytes(), (
        f'{map_data["bitmap"]} differs from deterministic indexed map generation'
    )

end_b = Image.open(terrain.SOURCE_DIR / terrain.BUNKER_MATERIALS['End B'])
end_d = Image.open(terrain.SOURCE_DIR / terrain.BUNKER_MATERIALS['End D'])
assert end_b.mode == end_d.mode == 'P' and end_b.size == end_d.size == (96, 96)
assert end_d.tobytes() == end_b.transpose(Image.Transpose.FLIP_LEFT_RIGHT).tobytes()
assert end_d.getpalette() == end_b.getpalette()
highlands = next(spec for spec in terrain.MAPS if spec['bitmap'] == 'Highlands.png')
right_end_caps = [obj for obj in terrain.bunker_objects(highlands) if obj[0] == 'End D']
assert len(right_end_caps) == 3
assert {obj[1] for obj in right_end_caps} == {4392, 7392, 11592}
highlands_scene = scene_block('Frontline Highlands Battlefield')
placed_right_caps = [
    (int(x), int(y))
    for x, y in re.findall(
        r'PlaceMovableObject = TerrainObject\s+CopyOf = Base\.rte/End D\s+Position = Vector\s+X = (\d+)\s+Y = (\d+)',
        highlands_scene,
    )
]
assert placed_right_caps == [(7392, 1486), (4392, 1390), (11592, 1390)]

print('All Frontline maps preserve indexed materials, balanced Gold, safe surface routes, grounded detail, surface-only variants, and connected mirrored Highlands capture halls')
