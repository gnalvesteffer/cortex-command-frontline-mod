"""Validate the Highlands terrain against its scene definition and layout."""
from pathlib import Path
import re
from PIL import Image

root = Path(__file__).resolve().parents[1] / 'Frontline.rte'
scene = (root / 'Scenario.ini').read_text().split('PresetName = Frontline Highlands Battlefield', 1)[1].split('AddActivity =', 1)[0]
width = int(re.search(r'Width = (\d+)', scene).group(1))
height = int(re.search(r'Height = (\d+)', scene).group(1))
im = Image.open(root / 'Highlands.png')
assert im.mode == 'P' and im.size == (width, height) == (15600, 1600)
assert width < 32768 // 2, 'exceeds this machine’s measured texture-chunk size'
assert im.histogram()[2] > 0, 'terrain must contain mineable gold'

def surface(x):
    return next(y for y in range(height) if im.getpixel((x, y)) != 0)

assert surface(180) == surface(335) == surface(495)
assert surface(width-180) == surface(width-335) == surface(width-495)
heights = [surface(x) for x in range(600, width-600, 100)]
assert max(heights) - min(heights) >= 250, 'expected varied elevation'
assert all(abs(a-b) <= 150 for a, b in zip(heights, heights[1:])), 'terrain contains an abrupt cliff'
print('Highlands dimensions, gold, flat base lanes and varied traversable slopes passed')
