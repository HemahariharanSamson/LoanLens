# LoanLens Icon Design

## Design Concept

The icon combines three key elements representing the app's functionality:

1. **Magnifying Glass (Lens)** - Represents "tracking" and "analysis" - the core "Lens" concept
2. **Currency Symbol (₹)** - Represents loans and financial tracking
3. **Trend Line with Arrow** - Represents progress, analytics, and repayment trends

## Design Specifications

- **Style**: Minimalist, flat design with subtle gradient
- **Colors**: 
  - Primary: Soft blue (#6B9BD2) to teal (#4DB6AC) gradient
  - Accent: White elements for contrast
- **Shape**: Rounded square (200px corner radius)
- **Size**: 1024x1024px (will be resized for different platforms)

## Color Palette

- Background Gradient Start: #6B9BD2 (Soft Blue)
- Background Gradient End: #4DB6AC (Soft Teal)
- Foreground Elements: White (#FFFFFF) with 90% opacity
- Lens Gradient: #64B5F6 to #81C784

## Icon Elements

1. **Magnifying Glass**
   - Outer circle: 180px radius
   - Handle: Diagonal line from bottom-right
   - Represents "focus" and "analysis"

2. **Currency Symbol**
   - ₹ symbol centered in the magnifying glass
   - Represents financial tracking

3. **Trend Line**
   - Subtle upward trending line at bottom
   - Small arrow indicating progress
   - Represents analytics and growth

## Conversion Instructions

To convert the SVG to PNG for use with flutter_launcher_icons:

1. Use an online SVG to PNG converter (e.g., https://svgtopng.com/)
2. Or use ImageMagick: `magick app_icon.svg -resize 1024x1024 app_icon.png`
3. Or use Inkscape: `inkscape app_icon.svg --export-filename=app_icon.png --export-width=1024 --export-height=1024`

The PNG should be:
- 1024x1024 pixels
- Square format
- Transparent or white background (will be handled by adaptive icon)

## Adaptive Icon (Android)

For Android adaptive icons, we'll use:
- **Foreground**: The main icon design (magnifying glass + currency + trend)
- **Background**: Light gray (#FAFAFA) matching the app theme

