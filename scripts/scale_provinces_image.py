import os
from PIL import Image

# Path to the original image
INPUT_IMAGE = os.path.join(os.path.dirname(__file__), '../map/map_data/provinces.png')
# Output directory for scaled images
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '../map/map_data/scaled_provinces')

# List of scale factors (e.g., 0.5 for half size, 0.25 for quarter size)
SCALE_FACTORS = [0.5, 0.25, 0.125, 0.0625]

# Output directory for upscaled images
UPSCALED_DIR = os.path.join(os.path.dirname(__file__), '../map/map_data/upscaled_provinces')


def scale_image(input_path, output_dir, scale_factors):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    img = Image.open(input_path)
    img = img.convert('RGBA')  # Ensure consistent mode

    # Prepare upscaled output directory
    if not os.path.exists(UPSCALED_DIR):
        os.makedirs(UPSCALED_DIR)

    for factor in scale_factors:
        new_width = round(img.width * factor)
        new_height = round(img.height * factor)
        new_img = Image.new('RGBA', (new_width, new_height))
        for y in range(new_height):
            for x in range(new_width):
                src_x = round(x / factor)
                src_y = round(y / factor)
                new_img.putpixel((x, y), img.getpixel((src_x, src_y)))
        output_path = os.path.join(
            output_dir, f'provinces_{new_width}x{new_height}.png')
        new_img.save(output_path)
        print(f'Saved: {output_path}')

        # Now upscale this image back to original resolution (no smoothing)
        upscaled_img = new_img.resize((img.width, img.height), resample=Image.NEAREST)
        upscaled_path = os.path.join(
            UPSCALED_DIR, f'provinces_{new_width}x{new_height}_upscaled_{img.width}x{img.height}.png')
        upscaled_img.save(upscaled_path)
        print(f'Saved upscaled: {upscaled_path}')


if __name__ == '__main__':
    scale_image(INPUT_IMAGE, OUTPUT_DIR, SCALE_FACTORS)
