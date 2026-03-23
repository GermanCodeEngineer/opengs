import os
from PIL import Image
import numpy as np

# Output directories
LUT_OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '../map/map_data/lut_scaled')
BT_OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '../map/map_data/bt_scaled')

# List of scale factors (full, half, quarter)
SCALE_FACTORS = [1.0, 0.5, 0.25]

def scale_image(input_path, output_dir, scale_factors):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    img = Image.open(input_path).convert('RGBA')
    base_name = os.path.splitext(os.path.basename(input_path))[0]
    scale_names = {1.0: 'full', 0.5: 'half', 0.25: 'quarter'}
    out_paths = []
    for factor in scale_factors:
        scale_name = scale_names.get(factor, str(factor))
        if factor == 1.0:
            scaled_img = img
        else:
            new_width = round(img.width * factor)
            new_height = round(img.height * factor)
            scaled_img = img.resize((new_width, new_height), resample=Image.NEAREST)
        output_path = os.path.join(output_dir, f'{scale_name}.png')
        scaled_img.save(output_path)
        print(f'Saved: {output_path}')
        out_paths.append(output_path)
    return out_paths

def create_boundary_image_fast(province_path, output_path):
    output_dir = os.path.dirname(output_path)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    img = Image.open(province_path).convert('RGBA')
    arr = np.array(img)
    h, w, _ = arr.shape
    # Create a mask of where the color changes in the 8-neighborhood
    boundary = np.zeros((h, w), dtype=np.uint8) + 255
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            if dx == 0 and dy == 0:
                continue
            shifted = np.roll(arr, shift=(dy, dx), axis=(0, 1))
            diff = np.any(shifted != arr, axis=2)
            boundary[diff] = 0
    # Convert to 1-bit image (mode '1')
    boundary_img = Image.fromarray(boundary, mode='L').convert('1')
    boundary_img.save(output_path)
    print(f'Saved 1-bit boundary image: {output_path}')

if __name__ == '__main__':
    # Scale lut_preview.png and create boundaries for each scale
    lut_input = os.path.join(os.path.dirname(__file__), '../map/map_data/lut_preview.png')
    lut_scaled_paths = scale_image(lut_input, LUT_OUTPUT_DIR, SCALE_FACTORS)
    # For each scaled lut, create a boundary in bt_scaled
    for lut_path in lut_scaled_paths:
        # Save as full.png, half.png, quarter.png in bt_scaled
        scale_name = os.path.splitext(os.path.basename(lut_path))[0]
        # Remove any prefix before _ (e.g. lut_full -> full)
        if '_' in scale_name:
            scale_name = scale_name.split('_')[-1]
        bt_path = os.path.join(BT_OUTPUT_DIR, f'{scale_name}.png')
        create_boundary_image_fast(lut_path, bt_path)