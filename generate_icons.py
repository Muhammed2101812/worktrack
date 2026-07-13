import os
from PIL import Image, ImageDraw

# Create output folder
output_dir = "assets/icon_candidates"
os.makedirs(output_dir, exist_ok=True)

# Color Palette
EMERALD = (16, 185, 129)      # #10B981
LIGHT_GREEN = (52, 211, 153)  # #34D399
DARK_GREY = (17, 24, 39)      # #111827
WHITE = (255, 255, 255)
LIGHT_GREY = (229, 231, 235)  # #E5E7EB
GREY = (156, 163, 175)        # #9CA3AF

# High resolution canvas size for antialiasing
CANVAS_SIZE = 4096
TARGET_SIZE = 1024

def draw_rounded_rect(draw, xy, radius, fill):
    x0, y0, x1, y1 = xy
    # Draw corners
    draw.ellipse([x0, y0, x0 + 2*radius, y0 + 2*radius], fill=fill)
    draw.ellipse([x1 - 2*radius, y0, x1, y0 + 2*radius], fill=fill)
    draw.ellipse([x0, y1 - 2*radius, x0 + 2*radius, y1], fill=fill)
    draw.ellipse([x1 - 2*radius, y1 - 2*radius, x1, y1], fill=fill)
    # Draw body rectangles
    draw.rectangle([x0 + radius, y0, x1 - radius, y1], fill=fill)
    draw.rectangle([x0, y0 + radius, x1, y1 - radius], fill=fill)

def draw_thick_line(draw, points, width, color):
    # Draw circles at vertices for rounded joints/caps
    for pt in points:
        r = width // 2
        draw.ellipse([pt[0] - r, pt[1] - r, pt[0] + r, pt[1] + r], fill=color)
    # Draw segment lines
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=color, width=width)

# Helper to save with high quality scaling
def save_image(img, path):
    try:
        resample_filter = Image.Resampling.LANCZOS
    except AttributeError:
        resample_filter = Image.ANTIALIAS
    
    resized = img.resize((TARGET_SIZE, TARGET_SIZE), resample_filter)
    resized.save(path, "PNG")
    print(f"Saved {path}")

# ==========================================
# Icon 1: Clock + checkmark
# ==========================================
def make_icon1():
    img = Image.new("RGB", (CANVAS_SIZE, CANVAS_SIZE), DARK_GREY)
    draw = ImageDraw.Draw(img)
    
    # Background Squircle (Emerald Green)
    draw_rounded_rect(draw, [200, 200, 3896, 3896], 800, EMERALD)
    
    # Clock Outer Ring (White)
    cx, cy = 2048, 2048
    draw.ellipse([cx - 1100, cy - 1100, cx + 1100, cy + 1100], fill=WHITE)
    # Clock Inner (Emerald Green)
    draw.ellipse([cx - 940, cy - 940, cx + 940, cy + 940], fill=EMERALD)
    
    # Clock Ticks
    ticks = [
        ([2018, 1020, 2078, 1140], WHITE),  # 12
        ([2956, 2018, 3076, 2078], WHITE),  # 3
        ([2018, 2956, 2078, 3076], WHITE),  # 6
        ([1020, 2018, 1140, 2078], WHITE),  # 9
    ]
    for bbox, color in ticks:
        draw.rectangle(bbox, fill=color)
        
    # Checkmark serving as clock hands
    # Start: left, Vertex: bottom turn, End: top right (extends out of clock face)
    checkmark_pts = [(1448, 1948), (1948, 2448), (3148, 1048)]
    
    # White outline for checkmark (so it pops over the emerald center/white ring)
    draw_thick_line(draw, checkmark_pts, 320, WHITE)
    # Dark Grey fill for checkmark
    draw_thick_line(draw, checkmark_pts, 220, DARK_GREY)
    
    save_image(img, os.path.join(output_dir, "icon1_clock_check.png"))

# ==========================================
# Icon 2: Notebook + clock
# ==========================================
def make_icon2():
    img = Image.new("RGB", (CANVAS_SIZE, CANVAS_SIZE), DARK_GREY)
    draw = ImageDraw.Draw(img)
    
    # Background Squircle (Emerald Green)
    draw_rounded_rect(draw, [200, 200, 3896, 3896], 800, EMERALD)
    
    # Notebook Backing (Dark Grey)
    draw_rounded_rect(draw, [800, 950, 3296, 3146], 150, DARK_GREY)
    
    # Left Page (White)
    draw_rounded_rect(draw, [950, 1100, 1980, 2996], 80, WHITE)
    # Right Page (White)
    draw_rounded_rect(draw, [2116, 1100, 3146, 2996], 80, WHITE)
    
    # Rings (Light Green)
    ring_ys = [1350, 1700, 2050, 2400, 2750]
    for ry in ring_ys:
        draw_rounded_rect(draw, [1900, ry - 40, 2196, ry + 40], 40, LIGHT_GREEN)
        
    # Left Page Lines (representing tasks)
    lines = [
        [(1150, 1450), (1750, 1450)],
        [(1150, 1800), (1600, 1800)],
        [(1150, 2150), (1700, 2150)],
        [(1150, 2500), (1450, 2500)]
    ]
    for line_pts in lines:
        draw_thick_line(draw, line_pts, 60, GREY)
        
    # Right Page Clock
    rcx, rcy = 2631, 2048
    # Clock Outer (Emerald)
    draw.ellipse([rcx - 320, rcy - 320, rcx + 320, rcy + 320], fill=EMERALD)
    # Clock Inner (White)
    draw.ellipse([rcx - 260, rcy - 260, rcx + 260, rcy + 260], fill=WHITE)
    
    # Clock Hands
    draw_thick_line(draw, [(rcx, rcy), (rcx, rcy - 180)], 45, DARK_GREY)
    draw_thick_line(draw, [(rcx, rcy), (rcx + 140, rcy + 100)], 45, DARK_GREY)
    # Center pin
    draw.ellipse([rcx - 40, rcy - 40, rcx + 40, rcy + 40], fill=DARK_GREY)
    
    save_image(img, os.path.join(output_dir, "icon2_notebook_clock.png"))

# ==========================================
# Icon 3: Minimal bar chart
# ==========================================
def make_icon3():
    img = Image.new("RGB", (CANVAS_SIZE, CANVAS_SIZE), DARK_GREY)
    draw = ImageDraw.Draw(img)
    
    # Background Squircle (Emerald Green)
    draw_rounded_rect(draw, [200, 200, 3896, 3896], 800, EMERALD)
    
    # Bars (White, Light Green, Dark Grey)
    # Bar 1 (White)
    draw_rounded_rect(draw, [850, 2400, 1250, 3200], 200, WHITE)
    # Bar 2 (Light Green)
    draw_rounded_rect(draw, [1450, 1700, 1850, 3200], 200, LIGHT_GREEN)
    # Bar 3 (Dark Grey)
    draw_rounded_rect(draw, [2050, 1000, 2450, 3200], 200, DARK_GREY)
    
    # Clock Floating Top Right
    ccx, ccy = 2950, 1350
    # Outer White
    draw.ellipse([ccx - 380, ccy - 380, ccx + 380, ccy + 380], fill=WHITE)
    # Inner Dark Grey
    draw.ellipse([ccx - 310, ccy - 310, ccx + 310, ccy + 310], fill=DARK_GREY)
    
    # Clock Hands (White)
    draw_thick_line(draw, [(ccx, ccy), (ccx - 140, ccy - 140)], 50, WHITE)
    draw_thick_line(draw, [(ccx, ccy), (ccx + 200, ccy)], 50, WHITE)
    
    # Clock Center Pin (White)
    draw.ellipse([ccx - 45, ccy - 45, ccx + 45, ccy + 45], fill=WHITE)
    
    save_image(img, os.path.join(output_dir, "icon3_barchart.png"))

# ==========================================
# Icon 4: Timer/stopwatch
# ==========================================
def make_icon4():
    img = Image.new("RGB", (CANVAS_SIZE, CANVAS_SIZE), DARK_GREY)
    draw = ImageDraw.Draw(img)
    
    # Background Squircle (Emerald Green)
    draw_rounded_rect(draw, [200, 200, 3896, 3896], 800, EMERALD)
    
    # Stopwatch Center and Body
    scx, scy = 2048, 2200
    
    # Top crown/button
    draw_rounded_rect(draw, [1928, 800, 2168, 1050], 40, WHITE)  # Stem
    draw_rounded_rect(draw, [1748, 650, 2348, 800], 50, WHITE)  # Top pusher
    
    # Side button at 45 degrees
    # Center of button: 2048 + 1050 * cos(-45), 2200 - 1050 * sin(-45)
    draw_thick_line(draw, [(2720, 1528), (2861, 1387)], 180, WHITE)
    
    # Main Body Circle (White)
    draw.ellipse([scx - 1050, scy - 1050, scx + 1050, scy + 1050], fill=WHITE)
    # Inner Face (Dark Grey)
    draw.ellipse([scx - 890, scy - 890, scx + 890, scy + 890], fill=DARK_GREY)
    
    # Major Ticks (White)
    draw.rectangle([scx - 30, scy - 840, scx + 30, scy - 720], fill=WHITE)  # 12
    draw.rectangle([scx + 720, scy - 30, scx + 840, scy + 30], fill=WHITE)  # 3
    draw.rectangle([scx - 30, scy + 720, scx + 30, scy + 840], fill=WHITE)  # 6
    draw.rectangle([scx - 840, scy - 30, scx - 720, scy + 30], fill=WHITE)  # 9
    
    # Minor Ticks (Light Green)
    minors = [
        [(scx + 520, scy - 520), (scx + 590, scy - 590)],
        [(scx + 520, scy + 520), (scx + 590, scy + 590)],
        [(scx - 520, scy + 520), (scx - 590, scy + 590)],
        [(scx - 520, scy - 520), (scx - 590, scy - 590)]
    ]
    for m_pts in minors:
        draw_thick_line(draw, m_pts, 30, LIGHT_GREEN)
        
    # Stopwatch Hand (Light Green & White)
    hand_end = (scx + 606, scy - 350)
    hand_start = (scx - 130, scy + 75)
    
    draw_thick_line(draw, [hand_start, hand_end], 40, LIGHT_GREEN)
    
    # Center Pin
    draw.ellipse([scx - 65, scy - 65, scx + 65, scy + 65], fill=WHITE)
    
    save_image(img, os.path.join(output_dir, "icon4_stopwatch.png"))

# ==========================================
# Icon 5: Checkmark + document
# ==========================================
def make_icon5():
    img = Image.new("RGB", (CANVAS_SIZE, CANVAS_SIZE), DARK_GREY)
    draw = ImageDraw.Draw(img)
    
    # Background Squircle (Emerald Green)
    draw_rounded_rect(draw, [200, 200, 3896, 3896], 800, EMERALD)
    
    # Paper Rounded Rectangle (White)
    draw_rounded_rect(draw, [950, 750, 3146, 3346], 120, WHITE)
    
    # Cut top right corner with Background color (Emerald Green)
    draw.polygon([(2596, 730), (3160, 730), (3160, 1300)], fill=EMERALD)
    
    # Draw Dog-ear Fold (Light Green)
    draw.polygon([(2596, 750), (2596, 1300), (3146, 1300)], fill=LIGHT_GREEN)
    
    # Lines on Document (Dark Grey)
    lines = [
        [(1300, 1600), (2800, 1600)],
        [(1300, 1950), (2800, 1950)],
        [(1300, 2300), (2200, 2300)],
        [(1300, 2650), (2500, 2650)]
    ]
    for line_pts in lines:
        draw_thick_line(draw, line_pts, 60, DARK_GREY)
        
    # Checkmark Overlay at bottom-right
    checkmark_pts = [(1900, 2750), (2350, 3200), (3250, 1900)]
    
    # Draw white outline (width 320)
    draw_thick_line(draw, checkmark_pts, 320, WHITE)
    # Draw inner fill (Dark Grey, width 220)
    draw_thick_line(draw, checkmark_pts, 220, DARK_GREY)
    
    save_image(img, os.path.join(output_dir, "icon5_checkmark_doc.png"))

if __name__ == "__main__":
    make_icon1()
    make_icon2()
    make_icon3()
    make_icon4()
    make_icon5()
    print("All icons successfully generated!")
