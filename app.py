#!/home/jack/Desktop/FlaskAppArchitect_Flask_App_Creator/env/bin/python
from moviepy.editor import *
from flask import Flask, render_template, request, redirect, url_for, send_from_directory, Response, flash, request, session, jsonify
from flask import send_file, g
import os
import pygame
from gtts import gTTS
import numpy as np
from random import randint
import subprocess
from pathlib import Path as change_ext
import re
from io import BytesIO
import io
import sqlite3
import tempfile
import random
import glob
import signal
import base64
from datetime import datetime
import imageio
import time
from werkzeug.utils import secure_filename
import shutil
#from search import search
from time import sleep
import uuid
import json
from PIL import Image, ImageDraw, ImageFont
import logging
from logging.handlers import RotatingFileHandler
#from view_gallery import view_gallery_bp
#from create_comic import create_comic_bp
#from view_archive_videos import view_archive_videos_bp
#from api_search.api_search import api_search_bp
#from mp3_sound.mp3_sound import mp3_sound_bp
from zoomin import zoomin_bp
import sys
from selenium import webdriver 
# Initialize Flask app
app = Flask(__name__)
# Set the template folder for the main app
app.template_folder = 'templates'
# Register your Blueprint and specify its template folder
api_search_template_folder = 'api_search/templates'
#app.register_blueprint(api_search_bp, url_prefix='/api_search', template_folder=api_search_template_folder)
# Register the Blueprint from view_gallery.py with the main app
#app.register_blueprint(view_gallery_bp)
#app.register_blueprint(create_comic_bp)
app.register_blueprint(zoomin_bp)
#app.register_blueprint(view_archive_videos_bp)
#app.register_blueprint(mp3_sound_bp)
app.static_folder = 'static'
# allow CORS

app.secret_key = os.urandom(24)
# Create a logger object
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
# Create a formatter for the log messages
formatter = logging.Formatter(
    '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]')

directory_paths = ["static/current_project", "static/images/uploads", "static/images/thumbnails", "static/videos/results", "static/css", "static/videos/thumbnails","static/formatted_text", "static/transparent_borders"]
for directory_path in directory_paths:
    if not os.path.exists(directory_path):
         os.makedirs(directory_path)
if not os.path.exists("Logs"):
         os.makedirs("Logs")         
# Create a file handler to write log messages to a file
file_handler = RotatingFileHandler(
    'Logs/app.log', maxBytes=10000, backupCount=1)
file_handler.setLevel(logging.DEBUG)
file_handler.setFormatter(formatter)

# Add the file handler to the logger
logger.addHandler(file_handler)

#SDIR = "static/"
# Define the file path to store the script content
#script_file = os.path.join(os.getcwd(), SDIR, 'scripts', 'scripts.js')

# Route to the main app's template

def findvideos():
    videoroot_directory = "static"
    MP4 = []
    for dirpath, dirnames, filenames in os.walk(videoroot_directory):
        for filename in filenames:
            if filename.endswith(".mp4") and "Final" in filename:
                MP4.append(os.path.join(dirpath, filename))
    if MP4:
        last_video = session.get("last_video")
        new_video = random.choice([video for video in MP4 if video != last_video])
        session["last_video"] = new_video
        return new_video
    else:
        return None
@app.route('/')
def index():
    video = findvideos()
    return render_template('index.html', video=video)

@app.route('/hello_world')
def hello_world():
    TExt = "TEXT TEST 6789"
    logger.debug('This is a debug message: %s', TExt)

    TEXT = "TEXT TEST abcd"
    logger.debug('This is a debug message: %s', TEXT)

    return "Hello, World!"


app.config['UPLOAD_FOLDER'] = 'static/images/uploads'
app.config['RESULTS_FOLDER'] = 'static/videos/results'
app.config['THUMBNAILS_FOLDER'] = 'static/images/thumbnails'
app.config['DATABASE'] = 'code.db'  # SQLite database file

app.secret_key = "your_secret_key"  # Add a secret key for session management


@app.route('/favicons.ico')
def favicons():
    return send_from_directory(os.path.join(app.root_path, 'static'), 'favicon.ico', mimetype='image/vnd.microsoft.icon')


@app.route('/favicon.ico')
def favicon():
    # Set the size of the favicon
    size = (16, 16)

    # Create a new image with a transparent background
    favicon = Image.new('RGBA', size, (0, 0, 0, 0))

    # Create a drawing object
    draw = ImageDraw.Draw(favicon)

    # Draw a yellow square
    square_color = (255, 0, 255)
    draw.rectangle([(0, 0), size], fill=square_color)

    # Draw a red circle
    circle_center = (size[0] // 2, size[1] // 2)
    circle_radius = size[0] // 3
    logger.info(f'circle_center, circle_radius:,{circle_center} {circle_radius}')
    circle_color = (255, 255, 0)
    draw.ellipse(
        [(circle_center[0] - circle_radius, circle_center[1] - circle_radius),
         (circle_center[0] + circle_radius, circle_center[1] + circle_radius)],
        fill=circle_color
    )

    # Save the image to a memory buffer
    image_buffer = io.BytesIO()
    favicon.save(image_buffer, format='ICO')
    image_buffer.seek(0)

    return Response(image_buffer.getvalue(), content_type='image/x-icon')
# Configure logging
logging.basicConfig(filename='Logs/code_count.log', level=logging.INFO, format='%(asctime)s - %(message)s')

def count_lines_of_code(directory):
    total_lines = 0

    for root, dirs, files in os.walk(directory):
        # Exclude the 'env/' directory from the search
        if 'env' in dirs:
            dirs.remove('env')

        for file in files:
            if file.endswith('.py'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        for line in f:
                            total_lines += 1
                except Exception as e:
                    logging.error(f"Error reading file '{filepath}': {e}")
    
    return total_lines


directory_path = os.getcwd()
lines_of_code = count_lines_of_code(directory_path)
    
# Logging the result
logging.info(f'Total lines of code in {directory_path}: {lines_of_code}')
print(f'Total lines of code in {directory_path}: {lines_of_code}')
@app.route('/products', methods=['GET', 'POST'])
def products():
    if request.method == 'POST':
        name = request.form['name']
        description = request.form['description']
        price = request.form['price']

        db = get_db()
        cursor = db.cursor()
        cursor.execute("INSERT INTO products (name, description, price) VALUES (?, ?, ?)",
                       (name, description, price))
        db.commit()

    db = get_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM products")
    products = cursor.fetchall()

    return render_template('products.html', products=products)


@app.route('/edit/<int:product_id>', methods=['GET', 'POST'])
def edit_product(product_id):
    if request.method == 'POST':
        name = request.form['name']
        description = request.form['description']
        price = request.form['price']

        db = get_db()
        cursor = db.cursor()
        cursor.execute("UPDATE products SET name=?, description=?, price=? WHERE id=?",
                       (name, description, price, product_id))
        db.commit()

        return redirect('/products')

    db = get_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM products WHERE id=?", (product_id,))
    product = cursor.fetchone()

    return render_template('edit_product.html', product=product)


@app.route('/delete/<int:product_id>', methods=['POST'])
def delete_product(product_id):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("DELETE FROM products WHERE id=?", (product_id,))
    db.commit()

    return redirect('/products')
# Function to create the database and table

    
@app.route('/access_database')
def access_database():
    db_path = os.path.join(os.path.dirname(__file__), 'code.db')
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM snippets')
    code = cursor.fetchall()
    conn.close()
    return render_template('database.html', code=code)
# Function to create the database and table


def create_database():
    conn = sqlite3.connect('code.db')
    cursor = conn.cursor()
    # cursor.execute("CREATE TABLE snippets (description TEXT, code TEXT, keywords TEXT)")
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS snippets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT NOT NULL,
            code TEXT,
            keywords TEXT
        )
    ''')
    conn.commit()
    conn.close()
# Route to display all code


@app.route('/code', methods=['GET'])
def display_code():
    conn = sqlite3.connect('code.db')
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM snippets')
    code = cursor.fetchall()
    conn.close()

    # Define the HTML code for the form
    form_code = """
    <h1>Add New code</h1>
    <form action="/code" method="post">
        <label for="description">Description:</label>
        <textarea type="description" name="description" rows="8" cols="90%"></textarea><br />
        <label for="code">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Code:</label>
        <textarea type="text" name="code" rows="8" cols="90%"></textarea><br>
        <label for="keywords">Keywords:</label>
        <input style="width:53%;height: 25px;" type="keywords" name="keywords"><br>
        <input type="submit" value="Add code">
    </form>
    """

    return render_template('code.html', code=code, form_code=form_code)
# Route to add a new code

def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(app.config['DATABASE'])
    return db


@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

@app.route('/code', methods=['POST'])
def add_code():
    description = request.form['description']
    code = request.form['code']
    keywords = request.form['keywords']

    conn = sqlite3.connect('code.db')
    cursor = conn.cursor()
    cursor.execute('INSERT INTO snippets (description, code, keywords) VALUES (?, ?, ?)',
                   (description, code, keywords))
    conn.commit()
    conn.close()
    return redirect(url_for('display_code'))
# Route to edit a code


@app.route('/edit_code/<int:code_id>', methods=['GET', 'POST'])
def edit_code(code_id):
    conn = sqlite3.connect('code.db')
    cursor = conn.cursor()

    if request.method == 'POST':
        description = request.form['description']
        code = request.form['code']
        keywords = request.form['keywords']

        cursor.execute('UPDATE snippets SET description=?, code=?, keywords=? WHERE id=?',
                       (description, code, keywords, code_id))
        conn.commit()
        conn.close()
        return redirect(url_for('display_code'))

    cursor.execute('SELECT * FROM snippets WHERE id = ?', (code_id,))
    code = cursor.fetchone()
    conn.close()
    return render_template('edit_code.html', code=code)
# Route to delete a code


@app.route('/delete_code/<int:code_id>', methods=['POST'])
def delete_code(code_id):
    conn = sqlite3.connect('code.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM snippets WHERE id = ?', (code_id,))
    conn.commit()
    conn.close()
    return redirect(url_for('display_code'))
template_dir = 'templates'
original_template_dir = os.path.join(template_dir, 'original')
os.makedirs(original_template_dir, exist_ok=True)


def load_original_template_file(filename):
    original_file_path = os.path.join(template_dir, filename)
    with open(original_file_path, 'r') as file:
        return file.read()


def save_original_template_file(filename, content):
    now = datetime.now().strftime("%Y%m%d_%H%M%S")
    new_filename = f"{filename}_{now}.txt"
    new_file_path = os.path.join(original_template_dir, new_filename)
    with open(new_file_path, 'w') as file:
        file.write(content)


def edit_and_save_template_file(filename, content):
    save_original_template_file(filename, content)
    edited_file_path = os.path.join(template_dir, filename)
    with open(edited_file_path, 'w') as file:
        file.write(content)


@app.route('/edit_template')
def edit_template():
    filenames = [f for f in os.listdir(template_dir) if f.endswith('.html')]
    filenames = sorted(filenames)
    fvideo ="static/assets/voice-for_avatar_Edit_Files.mp4"
    return render_template('edit_template.html', filenames=filenames, video=fvideo)


@app.route('/edit_template_page')
def edit_template_page():
    selected_filename = request.args.get('filename')
    original_content = load_original_template_file(selected_filename)
    return render_template('edit_template_page.html', selected_filename=selected_filename, original_content=original_content)


@app.route('/edit_template_save', methods=['POST'])
def edit_template_save():
    edited_content = request.form['edited_content']
    selected_filename = request.form['filename']
    edit_and_save_template_file(selected_filename, edited_content)
    return redirect(url_for('edit_template'))

css_dir = 'static/css'
original_css_dir = os.path.join(css_dir, 'original')
os.makedirs(original_css_dir, exist_ok=True)


def load_original_css_file(filename):
    original_file_path = os.path.join(css_dir, filename)
    with open(original_file_path, 'r') as file:
        return file.read()


def save_original_css_file(filename, content):
    now = datetime.now().strftime("%Y%m%d_%H%M%S")
    new_filename = f"{filename}_{now}.css"
    new_file_path = os.path.join(original_css_dir, new_filename)
    with open(new_file_path, 'w') as file:
        file.write(content)


def edit_and_save_css_file(filename, content):
    save_original_css_file(filename, content)
    edited_file_path = os.path.join(css_dir, filename)
    with open(edited_file_path, 'w') as file:
        file.write(content)


@app.route('/edit_css')
def edit_css():
    filenames = [f for f in os.listdir(css_dir) if f.endswith('.css')]
    filenames = sorted(filenames)
    # render template
    return render_template ('edit_css.html', filenames=filenames)


@app.route('/edit_css_page')
def edit_css_page():
    selected_filename = request.args.get('filename')
    original_content = load_original_css_file(selected_filename)
    return render_template('edit_css_page.html', selected_filename=selected_filename, original_content=original_content)

directories = glob.glob('static/images/*')
@app.route('/edit_css_save', methods=['POST'])
def edit_css_save():
    edited_content = request.form['edited_content']
    selected_filename = request.form['filename']
    edit_and_save_css_file(selected_filename, edited_content)
    return redirect(url_for('edit_css'))
@app.route('/mk_text', methods=['GET', 'POST'])
def mk_text():
    DIR = "static/text/"
    if request.method == 'POST':
        text = request.form.get('text')
        tex = text.replace(" ", "_")
        filename = tex[:25]
        with open(f'{DIR}{filename}.txt', 'w') as file:
            file.write(text)
        return render_template('mk_text.html', text=text, filename=f'{filename}.txt')
    else:
        return render_template('mk_text.html')
@app.route('/choose_dir', methods=['GET', 'POST'])
def choose_dir():
    if request.method == 'POST':
        selected_directory = request.form.get('directory', directories)
        TExt = "TEXT TEST"
        logger.error('No file was selected: %s', TExt)
        logger.debug('Debug was selected: %s', TExt)
        if selected_directory is None:
            # Handle the case where no directory is selected
            logger.error('No directory selected')
            return 'No directory selected!'
        # Rest of the code...
        # Use the selected_directory variable in your logic to generate the video
        # Make sure to update the paths according to the selected directory
        logger.debug('Selected directory: %s', selected_directory)
        # Get the list of image files in the selected directory
        samp = len(glob.glob(selected_directory + '/*.jpg'))
        logger.debug('Number of image files: %d',samp)                                                             
        image_filenames = random.sample(
            glob.glob(selected_directory + '/*.jpg'), 21)
        logger.debug('Selected image filenames: %s', image_filenames)

        image_clips = []
        for filename in image_filenames:
            # Open the image file and resize it to 512x768
            logger.debug('Processing image: %s', filename)
            image = Image.open(filename)
            # image = image.resize((512, 768), Image.ANTIALIAS)
            # Convert the PIL Image object to a NumPy array
            image_array = np.array(image)
            # Create an ImageClip object from the resized image and set its duration to 1 second
            image_clip = ImageClip(image_array).set_duration(1)
            # Append the image clip to the list
            image_clips.append(image_clip)

        logger.debug('Number of image clips: %d', len(image_clips))

        # Concatenate all the image clips into a single video clip
        video_clip = concatenate_videoclips(image_clips, method='compose')
        timestr = time.strftime("%Y%m%d-%H%M%S")
        # Set the fps value for the video clip
        video_clip.fps = 24
        # Write the video clip to a file
        video_file = f'static/videos/random_images_{timestr}_video.mp4'
        output_p = 'static/videos/random_images_video.mp4'
        logger.debug('Output video file path: %s', video_file)
        logger.debug('Final video file path: %s', output_p)

        video_clip.write_videofile(video_file, fps=24)

        try:
            shutil.copy(video_file, output_p)
        except Exception as e:
            logger.error('Error occurred while copying file: %s', str(e))
            return f"Error occurred while copying file: {str(e)}"

        # Return the rendered template with the list of directories and output path
        return render_template('choose_dir.html', directories=directories, output_path=output_p)

    # If the request method is GET, render the form template with the list of directories
    output_p = 'static/videos/random_images_video.mp4'
    return render_template('choose_dir.html', directories=directories, output_path=output_p)


@app.route('/convert', methods=['GET', 'POST'])
def convert():
    if request.method == 'POST':
        try:
            audio_file = request.files['audio_file']
            # Path for audio file
            audio_file_path = f'static/audio_mp3/{audio_file.filename}'
            # Save the audio file to the specified location
            audio_file.save(audio_file_path)

            formatted_text_file = request.files['formatted_text_file']
            # Path for formatted text file
            formatted_text_file_path = f'static/formatted_text/{formatted_text_file.filename}'
            # Save the formatted text file to the specified location
            formatted_text_file.save(formatted_text_file_path)

            output_filename = datetime.now().strftime('%Y-%m-%d') + '.mp4'
            output_path = 'static/videos/' + output_filename
            # Define the ffmpeg command
            # Create the blank video
            # ffmpeg -f lavfi -i color='#470000'@0x0:s=1280x720:rate=60,format=rgba -t 280 -y blank.mp4
            command = [
                'ffmpeg',
                '-i', audio_file_path,
                '-f', 'lavfi',
                '-i', f"color='#470000'@0.0:s=1280x720:rate=60,format=rgba",
                '-vf', f"drawtext=textfile='{os.path.abspath(formatted_text_file_path)}':y=(h-220)-12*t:x=580:fontcolor=orange:fontfile=/home/jack/Arimo-Regular.ttf:fontsize=26",
                '-t', '280',
                '-y', output_path
            ]

            logger.debug(f"Command: {' '.join(command)}")

            subprocess.run([str(arg) for arg in command], check=True)
            video = f'{output_filename}'
            return render_template('convert.html', video=output_path)
        except Exception as _:
            logger.exception("An error occurred during video conversion:")
            return render_template('error.html', message="An error occurred during video conversion.")
    else:
        return render_template('convert_form.html')


@app.route('/convert512', methods=['GET', 'POST'])
def convert512():
    if request.method == 'POST':
        try:
            audio_file = request.files['audio_file']
            # Path for audio file
            audio_file_path = f'static/audio_mp3/{audio_file.filename}'
            # Save the audio file to the specified location
            audio_file.save(audio_file_path)
            # Get the duration of the audio using ffprobe
            command = f"ffprobe -v error -show_entries format=duration -of default=noprint_wrloggers=1:nokey=1 {audio_file_path}"
            duration = subprocess.check_output(command.split())
            duration = float(duration.strip().decode())
            length = int(duration + 5)
            logger.info(f'Duration-512: {length}')
            formatted_text_file = request.files['formatted_text_file']
            # Path for formatted text file
            formatted_text_file_path = f'static/formatted_text/{formatted_text_file.filename}'
            # Save the formatted text file to the specified location
            formatted_text_file.save(formatted_text_file_path)

            output_filename = datetime.now().strftime('%Y-%m-%d') + '.mp4'
            output_path = 'static/videos/' + output_filename
            # Define the ffmpeg command
            # Create the blank video
            # ffmpeg -f lavfi -i color='#470000'@0x0:s=1280x720:rate=60,format=rgba -t 280 -y blank.mp4
            # y=(h-120)-12*t:x=24:
            command = [
                'ffmpeg',
                '-i', audio_file_path,
                '-f', 'lavfi',
                '-i', f"color='#470000'@0.0:s=512x1024:rate=60,format=rgba",
                '-vf', f"drawtext=textfile='{os.path.abspath(formatted_text_file_path)}':y=(h-120)-10*t:x=24:fontcolor=orange:fontfile=/home/jack/Arimo-Regular.ttf:fontsize=20",
                '-t', f'{length}', '-y', output_path
            ]

            logger.debug(f"Command: {' '.join(command)}")

            subprocess.run([str(arg) for arg in command], check=True)
            video = f'{output_filename}'
            return render_template('convert512.html', video=output_path)
        except Exception as e:
            logger.exception("An error occurred during video conversion:")
            return render_template('error.html', message="An error occurred during video conversion.")
    else:
        return render_template('convert_form512.html')



@app.route('/list_files')
def list_files():
    static_text_dir = 'static/text/'
    files = os.listdir(static_text_dir)
    files = [file for file in files if os.path.isfile(
        os.path.join(static_text_dir, file))]
    return str(files)


@app.route('/format_file', methods=['POST', 'GET'])
def format_file():
    static_text_dir = 'static/text/'
    static_format_dir = 'static/formatted_text/'
    if request.method == 'POST':
        filename = request.form.get('filename')
        file_path = os.path.join(static_text_dir, filename)
        if not os.path.isfile(file_path):
            return render_template('error.html', message=f'File "{filename}" does not exist')
        with open(file_path, 'r') as file:
            content = file.read()
        words = content.split()
        formatted_content = '\n'.join(
            [' '.join(words[i:i + 5]) for i in range(0, len(words), 5)])
        modified_filename = filename.replace('.txt', '') + 'FORMATTED.txt'
        modified_file_path = os.path.join(static_format_dir, modified_filename)
        with open(modified_file_path, 'w') as modified_file:
            modified_file.write(formatted_content)
            logger.debug('This is Formated Content: %s', formatted_content)
            logger.debug('This is Formated file: %s', modified_file_path)
        return render_template('success.html', original_file=filename, modified_file=modified_filename)

    file_options = []
    for file_name in os.listdir(static_text_dir):
        if file_name.endswith('.txt'):
            file_options.append(file_name)

    return render_template('form.html', file_options=file_options)


@app.route('/view_text')
def view_text():
    text_files_dir = 'static/text/'
    text_files = []
    for filename in os.listdir(text_files_dir):
        if filename.endswith('.txt'):
            text_files.append(filename)
    return render_template('select_file.html', text_files=text_files)


@app.route('/view_text/<filename>')
def display_text(filename):
    text_file_path = f'static/text/{filename}'
    try:
        with open(text_file_path, 'r') as file:
            file_contents = file.read()
        return render_template('view_text.html', file_contents=file_contents, filename=filename)
    except FileNotFoundError:
        return f'Text file {filename} not found.'


@app.route('/edit_file', methods=['GET', 'POST'])
def edit_file():
    if request.method == 'POST':
        filename = request.form.get('filename')
        text = request.form.get('text')
        with open(f'static/text/{filename}', 'w') as file:
            file.write(text)
    text_files_dir = 'static/text/'
    text_files = []
    for filename in os.listdir(text_files_dir):
        if filename.endswith('.txt'):
            text_files.append(filename)
    fvideo = findvideos()        
    return render_template('edit_file.html', text_files=text_files, video=fvideo)


@app.route('/edit_formatted', methods=['GET', 'POST'])
def edit_formatted():
    if request.method == 'POST':
        filename = request.form.get('filename')
        text = request.form.get('text')
        with open(f'static/formatted_text/{filename}', 'w') as file:
            file.write(text)
    text_files_dir = 'static/formatted_text/'
    text_files = []
    for filename in os.listdir(text_files_dir):
        if filename.endswith('.txt'):
            text_files.append(filename)
    return render_template('edit_formatted.html', text_files=text_files)


@app.route('/get_formatted_content/<filename>')
def get_formatted_content(filename):
    file_path = os.path.join('static/formatted_text', filename)
    with open(file_path, 'r') as file:
        content = file.read()
    return content


@app.route('/get_file_content/<filename>')
def get_file_content(filename):
    file_path = os.path.join('static/text', filename)
    with open(file_path, 'r') as file:
        content = file.read()
    return content
@app.route('/ffmpeg_commands')
def ffmpeg_commands():
    fvideo = findvideos()        
    return render_template('ffmpeg_commands.html', video=fvideo)
    
#FFMPEG -framerate 5 -i %05d.jpg -c:v libx265 -r 20 -pix_fmt yuv420p -y archived-images.mp4
@app.route('/list_jpgs')
def list_jpgs():
    static_text_dir = 'static/images/*'
    files = os.listdir(static_text_dir)
    files = [file for file in files if os.path.isfile(
        os.path.join(static_text_dir, file))]
    print(files)
    return str(files)  
 
@app.route("/mkblend_video", methods=['GET', 'POST'])
def mkblend_video():
    if request.method == 'POST':
        selected_directory = request.form.get('selected_directory')
        logger.debug('Selected Directory: %s', selected_directory)             
        if selected_directory:
            # Create a temporary directory to save the images
            temp_dir = tempfile.mkdtemp()

            # Loop through the files in the selected directory and move them to the temporary directory
            chosen_directory = os.path.join('static/images', selected_directory)
            for filename in os.listdir(chosen_directory):
                if filename.endswith('.jpg') or filename.endswith('.png'):
                    logger.debug('Moving file: %s', filename)
                    source_path = os.path.join(chosen_directory, filename)
                    target_path = os.path.join(temp_dir, filename)
                    os.rename(source_path, target_path)
                    logger.debug('Moved file: %s', filename)
        temp_dir = tempfile.mkdtemp()
        image_list = glob.glob(temp_dir + "*.jpg")
        logger.debug('IMAGE_LIST: %s', image_list)
        # Shuffle and select a subset of images
        # random.shuffle(image_list)
        image_list = sorted(image_list)
        logger.debug('Selected image filenames: %s', image_list)
        # Print the number of selected images
        print(len(image_list))
        logger.debug('Number of files: %s', len(image_list))

        def changeImageSize(maxWidth, maxHeight, image):
            widthRatio = maxWidth / image.size[0]
            heightRatio = maxHeight / image.size[1]
            newWidth = int(widthRatio * image.size[0])
            newHeight = int(heightRatio * image.size[1])
            newImage = image.resize((newWidth, newHeight))
            return newImage

        # Get the size of the first image
        if image_list:
            imagesize = Image.open(image_list[0]).size

            for i in range(len(image_list) - 1):
                imag1 = image_list[i]
                imag2 = image_list[i + 1]
                image1 = Image.open(imag1)
                image2 = Image.open(imag2)

                image3 = changeImageSize(imagesize[0], imagesize[1], image1)
                image4 = changeImageSize(imagesize[0], imagesize[1], image2)

                image5 = image3.convert("RGBA")
                image6 = image4.convert("RGBA")

                text = "static/animate/"
                for ic in range(0, 100):
                    inc = ic * 0.01
                    # inc = ic * 0.08
                    sleep(0.1)
                    # Gradually increase opacity
                    alphaBlended = Image.blend(image5, image6, alpha=inc)
                    alphaBlended = alphaBlended.convert("RGB")
                    current_time = datetime.datetime.now()
                    filename = current_time.strftime(
                        '%Y%m%d_%H%M%S%f')[:-3] + '.jpg'
                    alphaBlended.save(f'{text}{filename}')
                    # shutil.copy(f'{text}{filename}', {temp_dir}+'TEMP.jpg')
                    shutil.copy(f'{text}{filename}', os.path.join(temp_dir, 'TEMP.jpg'))

                    if ic % 25 == 0:
                        print(i, ":", ic, end=" . ")
                    if ic % 100 == 0:
                        logger.debug('Image Number: %.2f %d', inc, ic)

            from moviepy.video.io.ImageSequenceClip import ImageSequenceClip
            # Get the list of files sorted by creation time
            imagelist = sorted(glob.glob('static/animate/*.jpg'),
                               key=os.path.getmtime)

            # Create a clip from the images
            clip = ImageSequenceClip(imagelist, fps=30)

            # Write the clip to a video file using ffmpeg
            current_time = datetime.datetime.now()
            filename = "static/animate/TEMP3a.mp4"
            clip.write_videofile(
                filename, fps=24, codec='libx265', preset='medium')
            store = "static/videos/" + \
                current_time.strftime('%Y%m%d_%H%M%S%f')[:-3] + 'jul27.mp4'
            # Replace with the desired path for the converted video file
            output_file = "static/animate/TEMP5.mp4"
            # Replace with the desired path for the converted video file
            webm_file = "static/animate/TEMP5.webm"
            ffmpeg_cmd = [
                'ffmpeg', '-i', filename, '-c:v', 'libx264', '-crf', '23', '-preset', 'medium', '-c:a', 'aac',
                '-b:a', '128k', '-movflags', '+faststart', '-y', output_file
            ]
            subprocess.run(ffmpeg_cmd)
            ffmpeg_cmd2 = [
                'ffmpeg', '-i', filename, '-c:v', 'libx264', '-crf', '23', '-preset', 'medium', '-c:a', 'aac',
                '-b:a', '128k', '-movflags', '+faststart', '-y', webm_file
            ]
            subprocess.run(ffmpeg_cmd2)
            shutil.copy(filename, store)
            return render_template('mkblend_video.html', video=filename)

    return render_template('choose_directory.html')


 
  
if __name__ == '__main__':
    create_database()  # Create the database and table before starting the app
    print("Starting Python Flask Server For Ffmpeg \n Code Snippets on port 5200")
    app.run(debug=True, host='0.0.0.0', port=5200)

