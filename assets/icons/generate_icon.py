"""
Script to generate LoanLens app icon
Requires: Pillow (pip install Pillow)
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon():
    # Create 1024x1024 image with transparent background
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    blue = (107, 155, 210)  # #6B9BD2
    teal = (77, 182, 172)   # #4DB6AC
    white = (255, 255, 255, 230)  # White with transparency
    
    # Draw rounded rectangle background with gradient
    # Simple gradient approximation
    for y in range(size):
        ratio = y / size
        r = int(blue[0] * (1 - ratio) + teal[0] * ratio)
        g = int(blue[1] * (1 - ratio) + teal[1] * ratio)
        b = int(blue[2] * (1 - ratio) + teal[2] * ratio)
        draw.rectangle([(0, y), (size, y + 1)], fill=(r, g, b, 255))
    
    # Round the corners (simplified - draw white rounded rect then composite)
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([(0, 0), (size, size)], radius=200, fill=255)
    img.putalpha(mask)
    
    # Draw magnifying glass circle
    center_x, center_y = size // 2, int(size * 0.44)
    radius = 180
    # Outer circle (white stroke)
    for i in range(45):
        draw.ellipse(
            [(center_x - radius - i, center_y - radius - i),
             (center_x + radius + i, center_y + radius + i)],
            outline=white, width=2
        )
    
    # Draw handle
    start_x, start_y = int(size * 0.625), int(size * 0.567)
    end_x, end_y = int(size * 0.732), int(size * 0.674)
    for i in range(50):
        draw.line(
            [(start_x + i, start_y + i), (end_x + i, end_y + i)],
            fill=white, width=3
        )
    
    # Draw currency symbol (₹) - simplified
    try:
        # Try to use a font if available
        font_size = 280
        font = ImageFont.truetype("arial.ttf", font_size) if os.path.exists("C:/Windows/Fonts/arial.ttf") else ImageFont.load_default()
    except:
        font = ImageFont.load_default()
    
    # Draw ₹ symbol (simplified representation)
    symbol_x, symbol_y = size // 2, int(size * 0.49)
    # Draw a simple representation
    draw.text((symbol_x, symbol_y), "₹", fill=white, font=font, anchor="mm")
    
    # Draw trend line
    points = [
        (int(size * 0.195), int(size * 0.83)),
        (int(size * 0.342), int(size * 0.73)),
        (int(size * 0.488), int(size * 0.78)),
        (int(size * 0.781), int(size * 0.73))
    ]
    for i in range(len(points) - 1):
        draw.line([points[i], points[i + 1]], fill=white, width=35)
    
    # Draw arrow
    arrow_x, arrow_y = int(size * 0.732), int(size * 0.73)
    arrow_points = [
        (arrow_x, arrow_y),
        (int(size * 0.781), int(size * 0.683)),
        (int(size * 0.83), int(size * 0.73))
    ]
    draw.polygon(arrow_points, outline=white, width=35)
    
    return img

if __name__ == "__main__":
    print("Generating LoanLens app icon...")
    icon = create_app_icon()
    
    # Save main icon
    icon.save("app_icon.png", "PNG")
    print("✓ Created app_icon.png")
    
    # Create foreground for adaptive icon (same as main icon but on transparent)
    foreground = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    fg_draw = ImageDraw.Draw(foreground)
    
    # Copy the icon elements but on transparent background
    # For simplicity, we'll use the same icon
    foreground.paste(icon, (0, 0), icon)
    foreground.save("app_icon_foreground.png", "PNG")
    print("✓ Created app_icon_foreground.png")
    
    print("\nIcon generation complete!")
    print("Files created:")
    print("  - app_icon.png (1024x1024)")
    print("  - app_icon_foreground.png (1024x1024)")

