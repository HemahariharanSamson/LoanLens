"""
Simple icon generator for LoanLens
Creates a minimalist icon with magnifying glass, currency symbol, and trend line
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    HAS_PIL = True
except ImportError:
    HAS_PIL = False
    print("PIL/Pillow not found. Install with: pip install Pillow")

def create_icon():
    if not HAS_PIL:
        print("\nPlease install Pillow first:")
        print("  pip install Pillow")
        return
    
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors - Soft pastels
    blue = (107, 155, 210, 255)  # #6B9BD2
    teal = (77, 182, 172, 255)   # #4DB6AC
    white = (255, 255, 255, 230)
    
    # Create gradient background
    for y in range(size):
        ratio = y / size
        r = int(blue[0] * (1 - ratio) + teal[0] * ratio)
        g = int(blue[1] * (1 - ratio) + teal[1] * ratio)
        b = int(blue[2] * (1 - ratio) + teal[2] * ratio)
        draw.rectangle([(0, y), (size, y + 1)], fill=(r, g, b, 255))
    
    # Round corners - create mask
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    # Draw rounded rectangle manually if rounded_rectangle not available
    try:
        mask_draw.rounded_rectangle([(0, 0), (size, size)], radius=200, fill=255)
    except:
        # Fallback: draw rounded rectangle manually
        radius = 200
        # Draw main rectangle
        mask_draw.rectangle([radius, 0, size-radius, size], fill=255)
        mask_draw.rectangle([0, radius, size, size-radius], fill=255)
        # Draw corner circles
        for corner in [(radius, radius), (size-radius, radius), (radius, size-radius), (size-radius, size-radius)]:
            mask_draw.ellipse([corner[0]-radius, corner[1]-radius, corner[0]+radius, corner[1]+radius], fill=255)
    img.putalpha(mask)
    
    # Magnifying glass circle
    cx, cy = size // 2, int(size * 0.44)
    radius = 180
    for w in range(45):
        draw.ellipse(
            [cx - radius - w, cy - radius - w, cx + radius + w, cy + radius + w],
            outline=white, width=2
        )
    
    # Handle
    draw.line([(640, 580), (750, 690)], fill=white, width=50)
    
    # Currency symbol - try to use system font
    try:
        # Windows
        font_paths = [
            "C:/Windows/Fonts/arial.ttf",
            "C:/Windows/Fonts/calibri.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
        ]
        font = None
        for path in font_paths:
            try:
                font = ImageFont.truetype(path, 280)
                break
            except:
                continue
        if font is None:
            font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()
    
    # Draw ₹ symbol
    text = "₹"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    draw.text(
        (cx - text_width // 2, cy - text_height // 2),
        text, fill=white, font=font
    )
    
    # Trend line
    points = [(200, 850), (350, 750), (500, 800), (800, 750)]
    for i in range(len(points) - 1):
        draw.line(points[i:i+2], fill=white, width=35)
    
    # Arrow
    arrow = [(750, 750), (800, 700), (850, 750)]
    draw.polygon(arrow, outline=white, width=35)
    
    # Save
    img.save("app_icon.png", "PNG")
    
    # Foreground (same but ensure transparency)
    fg = img.copy()
    fg.save("app_icon_foreground.png", "PNG")
    
    print("Icons created successfully!")
    print("  - app_icon.png")
    print("  - app_icon_foreground.png")

if __name__ == "__main__":
    create_icon()

