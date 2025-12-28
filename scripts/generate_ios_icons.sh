#!/bin/bash

# Script to generate all iOS app icon sizes from a source image
# Usage: ./generate_ios_icons.sh <source_image_path>

SOURCE_IMAGE="$1"
ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [ -z "$SOURCE_IMAGE" ]; then
    echo "Usage: ./generate_ios_icons.sh <source_image_path>"
    echo "Example: ./generate_ios_icons.sh assets/icons/app_icon.png"
    exit 1
fi

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image not found: $SOURCE_IMAGE"
    exit 1
fi

echo "Generating iOS app icons from: $SOURCE_IMAGE"
echo "Output directory: $ICON_DIR"

# Create output directory if it doesn't exist
mkdir -p "$ICON_DIR"

# Function to generate icon
generate_icon() {
    local size=$1
    local filename=$2
    local output_path="$ICON_DIR/$filename"
    
    echo "Generating $filename (${size}x${size})..."
    sips -z $size $size "$SOURCE_IMAGE" --out "$output_path" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✓ Created $filename"
    else
        echo "✗ Failed to create $filename"
    fi
}

# iPhone icons
generate_icon 40 "Icon-App-20x20@2x.png"      # 20pt @2x = 40x40
generate_icon 60 "Icon-App-20x20@3x.png"      # 20pt @3x = 60x60
generate_icon 29 "Icon-App-29x29@1x.png"      # 29pt @1x = 29x29
generate_icon 58 "Icon-App-29x29@2x.png"      # 29pt @2x = 58x58
generate_icon 87 "Icon-App-29x29@3x.png"      # 29pt @3x = 87x87
generate_icon 80 "Icon-App-40x40@2x.png"      # 40pt @2x = 80x80
generate_icon 120 "Icon-App-40x40@3x.png"     # 40pt @3x = 120x120
generate_icon 120 "Icon-App-60x60@2x.png"     # 60pt @2x = 120x120
generate_icon 180 "Icon-App-60x60@3x.png"     # 60pt @3x = 180x180

# iPad icons
generate_icon 20 "Icon-App-20x20@1x.png"      # 20pt @1x = 20x20
generate_icon 40 "Icon-App-20x20@2x.png"     # 20pt @2x = 40x40 (reuse)
generate_icon 29 "Icon-App-29x29@1x.png"     # 29pt @1x = 29x29 (reuse)
generate_icon 58 "Icon-App-29x29@2x.png"     # 29pt @2x = 58x58 (reuse)
generate_icon 40 "Icon-App-40x40@1x.png"      # 40pt @1x = 40x40
generate_icon 80 "Icon-App-40x40@2x.png"      # 40pt @2x = 80x80 (reuse)
generate_icon 76 "Icon-App-76x76@1x.png"      # 76pt @1x = 76x76
generate_icon 152 "Icon-App-76x76@2x.png"     # 76pt @2x = 152x152
generate_icon 167 "Icon-App-83.5x83.5@2x.png" # 83.5pt @2x = 167x167

# App Store icon (required)
generate_icon 1024 "Icon-App-1024x1024@1x.png" # 1024x1024

echo ""
echo "✓ All icons generated successfully!"
echo "Icons are located in: $ICON_DIR"
echo ""
echo "Note: Make sure the Contents.json file references these icons correctly."

