# create_comic.py

from flask import Blueprint, render_template, request, redirect, url_for
import os
from PIL import Image, ImageDraw

create_comic_bp = Blueprint('create_comic', __name__)

@create_comic_bp.route('/create_comic_index', methods=['GET', 'POST'])
def create_comic_index():
    if request.method == 'POST':
        # Handle form submission and generate the border image here
        border_name = request.form.get('border_name')
        border_size = int(request.form.get('border_size'))
        border_shape = request.form.get('border_shape')
        border_thickness = int(request.form.get('border_thickness'))
        border_color = request.form.get('border_color')

        # Generate the border image using Pillow (PIL)
        border_image = generate_border(
            border_shape, border_size, border_thickness, border_color)

        # Save the generated image to the 'static/borders' directory
        save_path = os.path.join('static', 'borders', f'{border_name}.png')
        border_image.save(save_path)

        # Redirect to the '/show_generated_image' route to display the image
        return redirect(url_for('create_comic.show_generated_image'))

    return render_template('create_comic_index.html')
S

def generate_border(shape, size, thickness, color):
    # Create a transparent image
    border_image = Image.new('RGBA', (size, size), (0, 0, 0, 0))

    draw = ImageDraw.Draw(border_image)

    # Define the border shape based on user input
    if shape == 'square':
        draw.rectangle((0, 0, size - 1, size - 1), outline=color, width=thickness)
    elif shape == 'rectangle':
        draw.rectangle((0, 0, size - 1, size // 2), outline=color, width=thickness)
    elif shape == 'triangle':
        points = [(size // 2, 0), (0, size - 1), (size - 1, size - 1)]
        draw.polygon(points, outline=color, width=thickness)

    return border_image

@create_comic_bp.route('/show_generated_image')
def show_generated_image():
    # Implement logic to display the generated image here
    # You can create an HTML page to display the image

    return render_template('show_generated_image.html')
