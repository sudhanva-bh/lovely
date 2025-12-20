from rembg import remove
from PIL import Image
import os

input_dir = r"S:\Coding\Flutter\lovely\assets\setup"
output_dir = r"S:\Coding\Flutter\lovely\assets\setup_edited"

os.makedirs(output_dir, exist_ok=True)

for file in os.listdir(input_dir):
    if file.lower().endswith(".png"):
        input_path = os.path.join(input_dir, file)
        output_path = os.path.join(output_dir, file)

        with Image.open(input_path) as img:
            output = remove(img)
            output.save(output_path)

print("Background removal complete!")
