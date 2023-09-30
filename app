#!/home/jack/Desktop/FlaskAppArchitect_Flask_App_Creator/env/bin/python
from flask import Flask, render_template, request, redirect, url_for, send_from_directory, Response, flash, request, session, jsonify
from flask import send_file, g
import os
import pygame
from gtts import gTTS
import cv2
import dlib
import numpy as np
from random import randint
import subprocess
from pathlib import Path as change_ext
import re
from io import BytesIO
import io
import sqlite3
import random
import glob
from datetime import datetime
import imageio
import time
from werkzeug.utils import secure_filename
import shutil
import uuid
import logging
from logging.handlers import RotatingFileHandler
from zoomin import zoomin_bp
import sys

app = Flask(__name__)
# Set the template folder for the main app
app.template_folder = 'templates'
app.static_folder = 'static'
# Register your Blueprint and specify its template folder
api_search_template_folder = 'api_search/templates'
app.register_blueprint(api_search_bp, url_prefix='/api_search', template_folder=api_search_template_folder)
# Register the Blueprint from view_gallery.py with the main app
app.register_blueprint(view_gallery_bp)
app.register_blueprint(create_comic_bp)
app.register_blueprint(zoomin_bp)
app.register_blueprint(view_archive_videos_bp)
app.register_blueprint(mp3_sound_bp)

# Create a logger object
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

# Create a formatter for the log messages
formatter = logging.Formatter(
    '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]')

# Create a file handler to write log messages to a file
file_handler = RotatingFileHandler(
    'Logs/app.log', maxBytes=10000, backupCount=1)
file_handler.setLevel(logging.DEBUG)
file_handler.setFormatter(formatter)

# Add the file handler to the logger
logger.addHandler(file_handler)

SDIR = "static/"
# Define the file path to store the script content
script_file = os.path.join(os.getcwd(), SDIR, 'scripts', 'scripts.js')

# Route to the main app's template
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


directory_path = "static/current_project"
if not os.path.exists(directory_path):
    os.makedirs(directory_path)
app.config['UPLOAD_FOLDER'] = 'static/images/uploads'
app.config['RESULTS_FOLDER'] = 'static/videos/results'
app.config['THUMBNAILS_FOLDER'] = 'static/images/thumbnails'
app.config['CHECKPOINT_PATH'] = 'checkpoints/wav2lip_gan.pth'
app.config['AUDIO_PATH'] = 'sample_data/input_audio.wav'
app.config['video_PATH'] = 'sample_data/input_videio.mp4'
app.config['DATABASE'] = 'code.db'  # SQLite database file

app.secret_key = os.urandom(24)

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

# use the search function as a route
app.add_url_rule('/search', 'search', search)


def zip_lists(list1, list2):
    return zip(list1, list2)


app.jinja_env.filters['zip'] = zip_lists

directory_path = 'temp'  # Replace with the desired directory path
# Create the directory if it doesn't exist
os.makedirs(directory_path, exist_ok=True)

# Walk through all directories and subdirectories

def ClipList():
    cliplist = glob.glob("clip*.mp3")
    print(cliplist)
    return cliplist
for clip in ClipList():
    os.remove(clip)   
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




@app.route("/index2")
def index2():
    image_dir = 'static/images/MISC_MIX'
    image_files = [f for f in os.listdir(image_dir) if f.endswith('.jpg')]
    random_image_file = random.choice(image_files)
    return render_template('index2.html', random_image_file="images/MISC_MIX/" + random_image_file)


def generate_output():
    # Specify the path to your Bash script
    bash_script_path = '/home/jack/Desktop/StoryMaker/MakeVideo'

    # Execute the Bash script
    subprocess.run(['bash', bash_script_path])
    # Backup the result_videoxx.mp4 file
    current_datetime = str(int(time.time()))
    backup_filename = f"static/{current_datetime}.mp4"
    original_filename = "results/result_voice.mp4"
    shutil.copyfile(original_filename, backup_filename)
    return redirect('/final_lipsync')


@app.route('/run_command', methods=['GET'])
def run_command():
    # Specify the path to your Bash script
    bash_script_path = 'MakeVideo'

    # Execute the Bash script
    subprocess.run(['bash', bash_script_path])
    # Backup the result_videoxx.mp4 file
    current_datetime = str(int(time.time()))
    backup_filename = f"static/{current_datetime}.mp4"
    shutil.copyfile("results/result_voice.mp4", backup_filename)
    redirect('/final_lipsync')


@app.route('/result/<filename>')
def result(filename):
    return render_template('result.html', filename=filename)

@app.route('/text_mp3', methods=['GET', 'POST'])
def text_mp3():
    if request.method == 'POST':
        # Get the text from the textarea
        text = request.form['text']
        text0 = text
        # Remove whitespace from the text
        text = text.replace(" ", "")
        # Create a filename based on the first 25 characters of the text
        filename = "static/audio_mp3/" + text[:25] + ".mp3"
        textname = text[:25] + ".txt"
        # Save the text to a text file
        textname = textname.strip()
        with open("static/text/" + textname, 'w') as f:
            f.write(text0)
        filename = filename.strip()  # remove the newline character
        # Create a gTTS object and save the audio file
        tts = gTTS(text)
        filename = filename.strip()
        tts.save(filename)
        shutil.copy(filename, 'static/TEMP.mp3')
        # Play the mp3 file
        pygame.mixer.init()
        pygame.mixer.music.load(filename)
        pygame.mixer.music.play()
        # Wait for the audio to finish playing
        while pygame.mixer.music.get_busy():
            pygame.time.Clock().tick(10)
        # Stop pygame and exit the program
        pygame.mixer.quit()
        pygame.quit()
        # Return the text and filename to the template
        return render_template('text_mp3.html', text=text, filename=filename)
    else:
        # Render the home page template
        return render_template('text_mp3.html')


@app.route('/mp3_upload', methods=['POST', 'GET'])
def mp3_upload():
    if 'file' not in request.files:
        return 'No file uploaded', 400

    file = request.files['file']
    if file.filename == '':
        return 'No file selected', 400

    if file:
        audio_file = 'static/TEMP.mp3'
        file.save(audio_file)
        return render_template('player.html', audio_file=audio_file)

def extract_eyes(image_path, eyes_filename, shape_predictor_path):
    # Load the image and shape predictor model
    image = cv2.imread(image_path)
    detector = dlib.get_frontal_face_detector()
    predictor = dlib.shape_predictor(shape_predictor_path)

    # Convert the image to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Detect faces in the image
    faces = detector(gray)

    # Iterate over the detected faces and extract the eye regions
    for face in faces:
        landmarks = predictor(gray, face)

        # Extract the coordinates of the left eye
        left_eye_pts = [(landmarks.part(i).x, landmarks.part(i).y)
                        for i in range(36, 42)]

        # Extract the coordinates of the right eye
        right_eye_pts = [(landmarks.part(i).x, landmarks.part(i).y)
                         for i in range(42, 48)]

        # Create a transparent image with an alpha channel
        transparent_image = np.zeros(
            (image.shape[0], image.shape[1], 4), dtype=np.uint8)

        # Define the skin color (e.g., light brown or tan) in BGR format
        # skin_color_bgr = (210, 180, 140)
        skin_color_bgr = (80, 80, 40)

        # Convert BGR to RGB
        skin_color_rgb = (skin_color_bgr[2],
                          skin_color_bgr[1], skin_color_bgr[0])

        # Draw the eye regions on the transparent image with the skin color and alpha channel
        cv2.fillPoly(transparent_image, [np.array(
            left_eye_pts)], skin_color_rgb + (200,))
        cv2.fillPoly(transparent_image, [np.array(
            right_eye_pts)], skin_color_rgb + (200,))
        blurred_image = cv2.GaussianBlur(transparent_image, (5, 5), 0)
        # Save the transparent image with only the eyes as a PNG file
        cv2.imwrite(eyes_filename, blurred_image)
# Function to create a looping clip with blinking eyes


@app.route("/apply_text_to_video", methods=["POST", "GET"])
def apply_text_to_video():
    if request.method == "POST":
        file = request.files["mp4_file"]
        if file.filename == '':
            return redirect(request.url)
        file.save('static/TTMP.mp4')

        mp4_path = 'static/TTMP.mp4'
        text = request.form["text"]
        x = request.form["x"]
        y = request.form["y"]
        new_mp4_path = apply_text(mp4_path, text, x, y)
        return render_template("apply_text_to_video.html", new_mp4_path=new_mp4_path)
    else:
        return render_template("apply_text_to_video.html")


# Get a list of existing subdirectories in the video resources directory
existing_subdirectories = [subdir for subdir in os.listdir(
    "static/current_project") if os.path.isdir(os.path.join("static/current_project", subdir))]


@app.route('/uploads', methods=['GET', 'POST'])
def upload_files():
    video_resources_dir = "static/current_project"
    if request.method == 'POST':
        # Get the selected subdirectory from the form
        selected_subdirectory = request.form.get('subdirectory')

        # Check if the selected subdirectory exists
        if selected_subdirectory in existing_subdirectories:
            # Handle the uploaded file
            file = request.files['file']
            if file:
                # Save the file to the selected subdirectory
                file.save(os.path.join(video_resources_dir,
                          selected_subdirectory, file.filename))
                # Get the URL for the uploaded image
                image_path = url_for('static', filename=os.path.join(
                    'current_project', selected_subdirectory, file.filename))
                return render_template('upload_files.html', image_path=image_path)
            else:
                return 'No file selected.'
        else:
            return 'Invalid subdirectory selected.'
    # Render the upload form with the list of existing subdirectories
    return render_template('upload_files.html', subdirectories=existing_subdirectories)


@app.route('/get_files', methods=['POST'])
def get_files():
    subdirectory = request.form.get('subdirectory')
    file_options = []
    if subdirectory and subdirectory in existing_subdirectories:
        subdirectory_path = os.path.join(
            "static/current_project", subdirectory)
        files = os.listdir(subdirectory_path)
        file_options = [
            f'<option value="{file}">{file}</option>'
            for file in files
            if os.path.isfile(os.path.join(subdirectory_path, file))
        ]
    return ''.join(file_options)


@app.route('/image_list')
def image_list():
    image_directory = 'static/current_project/Narrators'
    image_list = [
        filename
        for filename in os.listdir(image_directory)
        if filename.endswith('.jpg')
    ]
    return render_template('image_list.html', image_list=image_list)


@app.route('/upload', methods=['POST', 'GET'])
def upload():
    filename = request.form['filename']
    if filename:
        src_path = 'static/current_project/Narrators/' + filename
        dest_path = 'static/TEMP.jpg'
        shutil.copyfile(src_path, dest_path)
        return redirect('/')
    else:
        return 'No file selected.'


# List of image directories (you can add more as needed)
image_directories = glob.glob('static/images/*')


@app.route("/mkblend_video", methods=['GET', 'POST'])
def mkblend_video():
    if request.method == 'POST':
        selected_directory = request.form.get('selected_directory')

        if selected_directory:
            # Create a temporary directory to save the images
            temp_dir = tempfile.mkdtemp()

            # Loop through the files in the selected directory and move them to the temporary directory
            chosen_directory = os.path.join('static/images', selected_directory)
            for filename in os.listdir(chosen_directory):
                if filename.endswith('.jpg') or filename.endswith('.png'):
                    source_path = os.path.join(chosen_directory, filename)
                    target_path = os.path.join(temp_dir, filename)
                    os.rename(source_path, target_path)
                    logger.debug('Moved file: %s', filename)
    
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

                text = "animate/"
                for ic in range(0, 100):
                    inc = ic * 0.01
                    # inc = ic * 0.08
                    sleep(0.1)
                    # Gradually increase opacity
                    alphaBlended = Image.blend(image5, image6, alpha=inc)
                    alphaBlended = alphaBlended.convert("RGB")
                    current_time = datetime.now()
                    filename = current_time.strftime(
                        '%Y%m%d_%H%M%S%f')[:-3] + '.jpg'
                    alphaBlended.save(f'{text}{filename}')
                    # shutil.copy(f'{text}{filename}', {temp_dir}+'TEMP.jpg')
                    shutil.copy(f'{text}{filename}', os.path.join(temp_dir, 'TEMP.jpg'))

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


def changeImageSize(maxWidth, maxHeight, image):
    widthRatio = maxWidth / image.size[0]
    heightRatio = maxHeight / image.size[1]
    newWidth = int(widthRatio * image.size[0])
    newHeight = int(heightRatio * image.size[1])
    newImage = image.resize((newWidth, newHeight))
    return newImage


directories = glob.glob("static/images/*")


@app.route("/mkblend_videos", methods=['POST', 'GET'])
def mkblend_videos():
    # Get the selected directory from the form data
    selected_directory = request.form.get('selected_directory')
    logger.debug('Selected Directory: %s', selected_directory)
    # Check if the selected directory is valid
    if selected_directory and selected_directory in directories:
        # Use glob to get the list of files within the selected directory
        filelist = glob.glob(os.path.join(selected_directory, '*.jpg'))
        logger.debug('Selected directory: %s', selected_directory)
        image_list = filelist
        # Shuffle and select a subset of images
        image_list = filelist
        random.shuffle(image_list)
        image_list = random.sample(image_list, 29)
        # Get the size of the first image
        imagesize = Image.open(image_list[0]).size

        # Print the number of selected images
        print("IMAGE_LIST_length:", len(image_list))

        for i in range(len(image_list) - 1):
            imag1 = image_list[i]
            imag2 = image_list[i + 1]
            image1 = Image.open(imag1)
            image2 = Image.open(imag2)

            image3 = changeImageSize(imagesize[0], imagesize[1], image1)
            image4 = changeImageSize(imagesize[0], imagesize[1], image2)

            image5 = image3.convert("RGBA")
            image6 = image4.convert("RGBA")

            text = "animate/"
            # for ic in range(0,125):
            for ic in range(0, 100):
                inc = ic * .01
                sleep(.1)
                # gradually increase opacity
                alphaBlended = Image.blend(image5, image6, alpha=inc)
                alphaBlended = alphaBlended.convert("RGB")
                current_datetime = str(int(time.time()))
                filename = current_datetime[:-3] + '.jpg'
                alphaBlended.save(f'{text}{filename}')
                if ic % 25 == 0:
                    print(ic, ":", inc, end=" . ")
    ffmpeg_cmd = ['ffmpeg', '-i', filename, '-c:v', 'libx264', '-crf', '23', '-preset',
                  'medium', '-c:a', 'aac', '-b:a',  '128k', '-movflags', '+faststart', '-y', output_file]
    subprocess.run(ffmpeg_cmd)
    # ffmpeg_cmd2 = ['ffmpeg', '-i', filename, '-c:v', 'libx264', '-crf', '23', '-preset', 'medium', '-c:a', 'aac', #'-b:a', '128k', '-movflags', '+faststart', '-y', webm_file]
    # subprocess.run(ffmpeg_cmd2)
    shutil.copy(filename, store)
    return render_template('mkblend_videos.html', video=filename)


@app.route('/generate_vid', methods=['GET', 'POST'])
def generate_vid():
    current_datetime = str(int(time.time()))
    str_current_datetime = str(current_datetime)
    logger.debug('Generating video', str_current_datetime)
    if request.method == 'POST':
        # Load the audio file
        audio_file = request.files['audio']
        # , 'input_audio.mp3')
        filename = os.path.join(app.config['AUDIO_PATH'])
        logger.info(f'Audio path: {filename}')
        audio_file.save(filename)
        print("FILENAME:", filename)

        # Get the duration of the audio using ffprobe
        command = f"ffprobe -v error -show_entries format=duration -of default=noprint_wrloggers=1:nokey=1 {filename}"
        duration = subprocess.check_output(command.split())
        duration = float(duration.strip().decode())
        logger.info(f'Duration: {duration}')
        # Load the image file
        image_file = request.files['image']
        image_path = os.path.join(
            app.config['UPLOAD_FOLDER'], secure_filename(image_file.filename))
        logger.info(f'Image path: {image_path}')
        image_file.save(image_path)

        # Create the video
        # video_path = os.path.join(app.config['VIDEO_PATH'])#, 'sample_data/input_video.mp4')
        video_path = 'sample_data/input_video.mp4'
        logger.info(f'Video path: {video_path}')
        ffmpeg_command = f"ffmpeg -loop 1 -i {image_path} -c:v libx264 -t {duration+ 0.5} -pix_fmt yuv420p -y {video_path}"
        subprocess.run(ffmpeg_command, shell=True)

        return f'Video created: {video_path}'

    return render_template('generate_vid.html')
# Define route to display upload form


@app.route('/upload_file', methods=['POST', 'GET'])
def upload_file():
    if request.method == 'POST':
        # Check if file was uploaded
        if 'file' not in request.files:
            logger.error('No file was uploaded')
            flash('Error: No file was uploaded')
            return redirect(request.url)

        logger.error('request.files[\'file\']')
        file = request.files['file']

        # Check if file was selected
        if file.filename == '':
            logger.error('No file was selected')
            flash('Error: No file was selected')
            return redirect(request.url)

        # Define allowed file extensions
        ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

        # Define function to check file extension
        def allowed_file(filename):
            return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

        # Check if file is allowed
        if not allowed_file(file.filename):
            # logger.error(f"File '{file.filename}' is not allowed")
            logger.error("File '" + file.filename + "' is not allowed")
            flash("Error: File '" + file.filename + "'close is not allowed")
            return redirect(request.url)

        # Save the file
        try:
            filename = secure_filename(file.filename)
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
            logger.info(f'File {filename} saved')
            logger.info('FILENAME:', os.path.join(
                app.config['UPLOAD_FOLDER'], filename))
        except Exception as e:
            logger.error(f'Error saving file: {e}')
            flash('Error: Unable to save file')
            return redirect(request.url)

        # Redirect to the result page
        logger.info(f'File-Result {filename} SAVED')
        return redirect(url_for('result', filename=filename))

    # Return the upload form for GET requests
    return render_template('upload_file.html')


@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)


@app.route('/make_text', methods=['GET', 'POST'])
def make_text():
    DIR = 'static/text/'
    if request.method == 'POST':
        # Get the text entered in the textarea
        text = request.form.get('text')

        # Generate a filename using the first 25 letters of the text
        text = text.replace(' ', '_')
        filename = text[:25]

        # Save the text to a file
        with open(f'{DIR}{filename}.txt', 'w') as file:
            file.write(text)

        return 'Text saved successfully!'
    else:
        return render_template('make_text.html')

directories = glob.glob('static/images/*')

# Route for the home page
@app.route("/hello")
def hello():  
    video=findvideos()
    return render_template('about.html', video=video)

@app.route("/home", methods=['GET'])
def home(): 
    return render_template('HTML5_Canvas_Cheat_Sheet.html')

@app.route("/about", methods=['GET'])
def about():     
    video=findvideos()
    return render_template('about.html', video=video)
@app.route("/html_base", methods=['GET'])
def html_base(): 
    with open('static/code.txt', 'r') as file:
        code_content = file.read()

    return render_template('your_template.html', code_content=code_content)


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
        image_filenames = random.sample(
            glob.glob(selected_directory + '/*.jpg'), 30)
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

            output_filename = datetime.datetime.now().strftime('%Y-%m-%d') + '.mp4'
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

            output_filename = datetime.datetime.now().strftime('%Y-%m-%d') + '.mp4'
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


@app.route('/resize_and_overlay_videos')
def resize_and_overlay_videos():
    # Path to the videos
    static_video_path = 'static/videos/2023-07-07.mp4'
    input_video_path = 'static/animate/topvideo.mp4'
    output_video_path = 'static/output/resulta.mp4'

    # Resize the input video using FFmpeg
    resize_command = f'ffmpeg -i {input_video_path} -vf "scale=410:820" -y resized.mp4'
    subprocess.call(resize_command, shell=True)

    # Overlay the resized video on the background video using FFmpeg
    overlay_command = f'ffmpeg -i {static_video_path} -i resized.mp4 -filter_complex "overlay=25:25" -y {output_video_path}'
    subprocess.call(overlay_command, shell=True)

    # Remove the temporary resized video
    subprocess.call('rm resized.mp4', shell=True)

    # Return the final video as a response
    return send_file(output_video_path, mimetype='video/mp4')


@app.route('/resize_and_overlay_videos_page')
def resize_and_overlay_videos_page():
    output_video_path = 'static/output/resulta.mp4'
    return render_template('resize_and_overlay_videos.html', video=output_video_path)



@app.route('/clean_images', methods=['POST'])
def clean_images_route():
    clean_images()
    logger.error('line 210 clean_images_route')
    return redirect(url_for('index'))


@app.route('/get_gallery')
def get_gallery():
    image_dir = '/mnt/HDD500/flask/FLASK/static/images/uploads'
    image_names = os.listdir(image_dir)
    return render_template('get_gallery.html', image_names=image_names)


@app.route('/uploads/<filename>')
def send_image(filename):
    return send_from_directory('static/images/uploads', filename)


@app.route('/uploads/thumbnails/<filename>')
def send_image_thumb(filename):
    return send_from_directory('static/images/uploads/thumbnails', filename)


@app.route('/flask_info')
def flask_info():
    return render_template('flask_info.html')


@app.route('/add_effects')
def add_effects():
    return '''
        <form method="post" action="/video" enctype="multipart/form-data">
            <label for="input_video">Select input video file:</label><br>
            <input type="file" id="input_video" name="input_video"><br><br>
            <input type="submit" value="Submit">
        </form>
    '''

@app.route('/video', methods=['GET', 'POST'])
def process_video():
    DIR = "static/"
    input_video = request.files['input_video']

    # Save the uploaded video to a file
    input_video.save(f"{DIR}input_video.mp4")

    # Run FFmpeg commands
    command1 = f"ffmpeg -nostdin -i {DIR}input_video.mp4 -filter:v \"minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=10'\" -c:v libx264 -r 20 -pix_fmt yuv420p -c:a copy -y {DIR}output.mp4"

    subprocess.run(command1, shell=True, stderr=subprocess.PIPE,
                   universal_newlines=True)

    command2 = f"ffmpeg -nostdin -i {DIR}output.mp4 -vf mpdecimate,setpts=N/FRAME_RATE/TB -c:v libx264 -r 30 -pix_fmt yuv420p -c:a copy -y {DIR}mpdecimate.mp4"

    subprocess.run(command2, shell=True, stderr=subprocess.PIPE,
                   universal_newlines=True)

    # DIR = "/home/jack/Desktop/ffmpeg_flask/"
    command3 = f"ffmpeg -i static/mpdecimate.mp4 -filter_complex \"[0:v]trim=duration=14,loop=500:1:0[v];[1:a]afade=t=in:st=0:d=1,afade=t=out:st=0.9:d=2[a1];[v][0:a][a1]concat=n=1:v=1:a=1\" -c:v libx264 -r 30 -pix_fmt yuv420p -c:a aac -b:a 192k -shortest -y static/output.mp4"
    subprocess.run(command3, shell=True, stderr=subprocess.PIPE,
                   universal_newlines=True)

    now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    shutil.copy(f"{DIR}output.mp4", f"{DIR}{now}_output.mp4")
    logger.info(f'my_video: f"{DIR}mpdecimate.mp4"')
    video_file = "static/outputALL.mp4"
    command4 = f'ffmpeg -i "{DIR}mpdecimate.mp4" -i "{DIR}mpdecimate.mp4" -i "{DIR}mpdecimate.mp4" -i "{DIR}mpdecimate.mp4" -i "{DIR}mpdecimate.mp4" -filter_complex "[0:v]trim=duration=15[v0];[1:v]trim=duration=15[v1];[2:v]trim=duration=15[v2];[3:v]trim=duration=15[v3];[4:v]trim=duration=15[v4];[v0][v1][v2][v3][v4]concat=n=5:v=1:a=0" -c:v libx264 -pix_fmt yuv420p -shortest -y {video_file}'
    subprocess.run(command4, shell=True, stderr=subprocess.PIPE,
                   universal_newlines=True)
    now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    diR = f"{DIR}/square_videos/"
    logger.info(f'diR: f"{diR}mpdecimate.mp4"')
    shutil.copy(f"{video_file}", f"{diR}{now}_outputALL.mp4")
    logger.info(f'diR: {diR}mpdecimate.mp4')
    return render_template('final.html', video_file=video_file)


def get_all_mp4_videos():
    mp4_videos = []
    for root, dirs, files in os.walk('static'):
        for file in files:
            if file.endswith('.mp4'):
                mp4_videos.append(os.path.join(root, file))
    return mp4_videos


@app.route('/play/<path:video_path>')
def play(video_path):
    return send_file(video_path)


@app.route('/select_order', methods=['GET', 'POST'])
def select_order():
    # Set a default value for output_path
    output_path = 'static/videos/concatenated_video.mp4'
    if request.method == 'POST':
        # Get the order of the videos from the form data
        order = request.form.getlist('order')
        # Join the videos in the specified order
        join_videos(order, output_path)
        # Set the timestamped output path
        timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
        new_output_path = f'static/videos/concatenated_{timestamp}XX.mp4'
        shutil.copy(output_path, new_output_path)
        # Redirect to the download page
        return redirect(url_for('download'))
    else:
        # Get the paths to the video files in the directory
        video_dir = 'static/videos'
        video_files = [os.path.join(video_dir, filename) for filename in os.listdir(
            video_dir) if filename.endswith('.mp4')]
        # Render the template with the list of video files and the output path
        return render_template('select_order.html', video_files=video_files, output_path=output_path)


def join_videos(video_paths, output_path):
    # Generate a list of input arguments for FFmpeg
    input_args = []
    for path in video_paths:
        input_args.extend(['-i', path])
    # Join the videos using FFmpeg
    subprocess.run(['ffmpeg', *input_args, '-filter_complex', 'concat=n={}:v=1:a=0'.format(
        len(video_paths)), '-c:v', 'libx264', '-crf', '23', '-preset', 'veryfast', '-y', output_path])
    # output_path = 'static/videos/concatenated_video.mp4'
    timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    new_output_path = f'static/videos/concatenated_{timestamp}XX.mp4'
    shutil.copy(output_path, new_output_path)


@app.route('/videos', methods=['POST'])
def process_videos():
    DIR = "static/"
    input_video = request.files['input_video']
    ""
    # Save the uploaded video to a file
    input_video.save(f"{DIR}input_video2.mp4")

    command1 = f"ffmpeg -nostdin -i {DIR}input_video2.mp4 -filter:v \"minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=10'\" -c:v libx264 -r 20 -pix_fmt yuv420p -c:a copy -y {DIR}alice/output2.mp4"
    subprocess.run(command1, shell=True, stderr=subprocess.PIPE,
                   universal_newlines=True)

    command2 = f"ffmpeg -hide_banner -i {DIR}alice/output2.mp4 -filter:v \"setpts=5*PTS,minterpolate='fps=25:scd=none:me_mode=bidir:vsbmc=1:search_param=200'\" -t 58 -y {DIR}alice/final2.mp4"
    subprocess.run(command2, shell=True, stderr=subprocess.PIPE,
                   universal_newlines=True)

    command3 = f"ffmpeg -hide_banner -i {DIR}alice/final2.mp4 -filter:v \"setpts=5*PTS,minterpolate='fps=25:scd=none:me_mode=bidir:vsbmc=1:search_param=200'\" -t 58 -y {DIR}alice/final5.mp4"
    subprocess.run(command3, shell=True, stderr=subprocess.PIPE,
                   universal_newlines=True)

    # Add music to the video
    init = randint(10, 50)
    MUSIC = ["static/music/Born_a_Rockstar-Instrumental-NEFFEX.mp3", "static/music/Cattle-Telecasted.mp3", "static/music/Bite_Me-Clean-NEFFEX.mp3", "static/music/El_Secreto-Yung_Logos.mp3", "static/music/Blue_Mood-Robert_Munzinger.mp3", "static/music/Escapism-Yung_Logos.mp3", "static/music/Enough-NEFFEX.mp3", "static/music/As_You_Fade_Away-NEFFEX.mp3", "static/music/Culture-Anno_Domini_Beats.mp3", "static/music/Contrast-Anno_Domini_Beats.mp3", "static/music/Diving_in_Backwards-Nathan_Moore.mp3",
             "static/music/Aztec_Empire-Jimena_Contreras.mp3", "static/music/Devil_s_Organ-Jimena_Contreras.mp3", "static/music/Alpha_Mission-Jimena_Contreras.mp3", "static/music/Changing-NEFFEX.mp3", "static/music/Anxiety-NEFFEX.mp3", "static/music/6-Shots-NEFFEX.mp3", "static/music/DimishedReturns.mp3", "static/music/Drum_Meditation.mp3", "static/music/ChrisHaugen.mp3", "static/music/DoveLove-Moreira.mp3", "static/music/DesertPlanet.mp3", "static/music/David_Fesliyan.mp3"]

    music = random.choice(glob.glob('static/MUSIC/*.mp3'))
    command3 = f"ffmpeg -i {DIR}alice/final5.mp4 -ss {init} -i {music} -af 'afade=in:st=0:d=4,afade=out:st=55:d=3' -map 0:0 -map 1:0 -shortest -y {DIR}alice/Final_End.mp4"
    subprocess.run(command3, shell=True)

    # Save the output video to a file
    now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    shutil.copy(f"{DIR}alice/output2.mp4", f"{DIR}alice/{now}_output.mp4")
    shutil.copy(f"{DIR}alice/Final_End.mp4", f"{DIR}alice/{now}_Final.mp4")
    shutil.copy(f"{DIR}alice/Final_End.mp4", f"{DIR}alice/Final_End_mix.mp4")
    return render_template('final.html', video_file="alice/Final_End.mp4")


@app.route('/large_video')
def large_video():
    return render_template('large_video.html')


@app.route('/add_border')
def add_border():
    images = [f for f in os.listdir(
        'static/images/uploads/') if os.path.isfile(os.path.join('static/images/uploads/', f))]
    thumbnails = []
    for image in images:
        with Image.open('static/images/uploads/' + image) as img:
            img.thumbnail((200, 200))
            thumbnail_name = 'thumbnail_' + image
            img.save('static/thumbnails/' + thumbnail_name)
            thumbnails.append(thumbnail_name)
    return render_template('add_border.html', images=images, thumbnails=thumbnails)


@app.route('/select_border')
def select_border():
    borders = os.listdir('static/transparent_borders/')
    return render_template('select_border.html', borders=borders)


@app.route('/apply_border', methods=['POST', 'GET'])
def apply_border():
    selected_image = request.form['image']
    selected_border = request.form['border']
    try:
        with Image.open('static/images/uploads/' + selected_image) as img:
            with Image.open('static/transparent_borders/' + selected_border) as border:
                img = img.resize(border.size)
                img.paste(border, (0, 0), border)
                final_image_name = 'final_' + selected_image
                img.save('static/final_images/' + final_image_name)
        return render_template('final_image.html', final_image=final_image_name, message='Border applied successfully.')
    except Exception as e:
        error_message = f'An error occurred: {str(e)}. Please try again.'
        return render_template('apply_border.html', image=selected_image, border=selected_border, error_message=error_message)


@app.route('/select_border_image', methods=['GET'])
def select_border_image():
    try:
        image = request.args.get('image')
        if not image:
            raise ValueError('No image selected.')
        return render_template('select_border.html', image=image, borders=os.listdir('static/transparent_borders/'))
    except Exception as e:
        error_message = f'An error occurred: {str(e)}. Please try again.'
        return render_template('add_border.html', error_message=error_message)


@app.route('/overlay_text', methods=['GET'])
def overlay_text():
    # Load the blank image
    blank_image_path = 'static/new_video/Border-plain.png'
    blank_image = Image.open(blank_image_path)

    # Load the text file and format its contents
    text_file_path = 'static/new_video/text_file.txt'
    with open(text_file_path, 'r') as file:
        text_contents = file.read()

    formatted_text = f"{text_contents}"  # Format the contents as desired

    # Set the font properties
    font_size = 21
    font_color = (255, 255, 255)  # White color
    font_path = '/home/jack/fonts/source-sans-pro-semibold.ttf'

    font = ImageFont.truetype(font_path, font_size)

    # Create a new image with the same size as the blank image and transparent background
    text_overlay = Image.new('RGBA', blank_image.size, (0, 0, 0, 0))

    # Draw the formatted text onto the overlay image
    draw = ImageDraw.Draw(text_overlay)
    text_position = (50, 600)  # Adjust the position as needed
    draw.text(text_position, formatted_text, font=font, fill=font_color)

    # Merge the overlay image with the blank image
    final_image = Image.alpha_composite(
        blank_image.convert('RGBA'), text_overlay)

    # Save the final image
    output_image_path = 'static/new_video/output_image.png'
    final_image.save(output_image_path)

    return render_template('overlay_text.html', output_image_path=output_image_path)


@app.route('/create_text_file', methods=['GET', 'POST'])
def create_text_file():
    if request.method == 'POST':
        # Get the text content from the textarea
        text_content = request.form.get('textarea_content')

        # Create the file path
        text_file_path = os.path.join('static/new_video', 'text_file.txt')

        # Write the text content to the file
        with open(text_file_path, 'w') as file:
            file.write(text_content)

        return render_template('text_file_created.html', text_file_path=text_file_path)

    return render_template('create_text_file.html')


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() == 'jpg'


@app.route('/generate_video3', methods=['GET', 'POST'])
def generate_video3():
    if request.method == 'POST':
        # Check if any files were uploaded
        if 'file' not in request.files:
            error_message = "No files uploaded."
            logger.error(error_message)
            return render_template('generate_video3.html', error_message=error_message)

        files = request.files.getlist('file')

        # Check if files were selected
        if len(files) == 0:
            error_message = "No files selected."
            logger.error(error_message)
            return render_template('generate_video3.html', error_message=error_message)

        # Check if the files have supported extensions
        for file in files:
            if not allowed_file(file.filename):
                error_message = f"Invalid file extension for {file.filename}. Only JPG files are allowed."
                logger.error(error_message)
                return render_template('generate_video3.html', error_message=error_message)

        # Create a temporary directory to save the uploaded files
        temp_dir = os.path.join('static', 'temp')
        os.makedirs(temp_dir, exist_ok=True)

        # Save the uploaded files to the temporary directory
        saved_files = []
        for file in files:
            filename = secure_filename(file.filename)
            file_path = os.path.join(temp_dir, filename)
            file.save(file_path)
            saved_files.append(file_path)

        # Randomly select 30 image files
        selected_images = random.sample(saved_files, min(30, len(saved_files)))

        # Create a list of image clips from the selected images
        image_clips = []
        for image_file in selected_images:
            image_clip = mp.ImageClip(image_file, duration=1)
            image_clips.append(image_clip)

        # Concatenate the image clips into a video clip
        video_clip = mp.concatenate_videoclips(image_clips)

        # Set the output video path
        output_path = os.path.join('static', 'videos', 'generated_video.mp4')

        # Write the video clip to the output file
        video_clip.write_videofile(output_path, fps=24)

        # Delete the uploaded files after processing
        for file_path in saved_files:
            os.remove(file_path)

        # Return the generated video URL to the client
        video_url = url_for('static', filename='videos/generated_video.mp4')
        return render_template('generate_video3.html', video_url=video_url)

    # Render the initial form
    return render_template('generate_video3.html')


@app.route('/generate_video2')
def generate_video2():
    # Get the pythonlist of image files in the static/final_images/ directory
    # image_filenames = random.sample(glob.glob('static/final_images/*.jpg'),25)
    # image_filenames = random.sample(glob.glob('static/images/uploads/*.jpg'),30)
    # image_filenames = random.sample(glob.glob('static/alien_files/*.jpg'),30)
    image_filenames = random.sample(
        glob.glob('/mnt/HDD500/collections/absrtact/*.jpg'), 30)
    print(image_filenames, end="-")

    image_clips = []
    for filename in image_filenames:
        # Open the image file and resize it to 512x768
        image = Image.open(filename)
        image = image.resize((512, 768), Image.ANTIALIAS)
        print(image)
        # Convert the PIL Image object to a NumPy array
        image_array = np.array(image)
        # Create an ImageClip object from the resized image and set its duration to 1 second
        image_clip = ImageClip(image_array).set_duration(1)

        # Append the image clip to the list
        image_clips.append(image_clip)

    # Concatenate all the image clips into a single video clip
    video_clip = concatenate_videoclips(image_clips, method='compose')
    timestr = time.strftime("%Y%m%d-%H%M%S")
    # Set the fps value for the video clip
    video_clip.fps = 24
    # Write the video clip to a file
    video_path = 'static/videos/random_images' + timestr + 'video.mp4'
    video_clip.write_videofile(video_path, fps=24)
    video_clip.write_videofile('static/videos/TEMPvideo.mp4', fps=24)

    # Return a message to the client
    return render_template('generate_video2.html', video_url='static/videos/TEMPvideo.mp4')
    # return render_template('generate_video2.html' ,video_url='/static/videos/TEMPvideo.mp4', video_path=video_path)


@app.route('/ffmpeg_ctl', methods=['GET', 'POST'])
def ffmpeg_ctl():
    if request.method == 'POST':
        # Access the numeric input value from the form data
        number = request.form.get('number')
        # Process the value as needed
        # ...

    return render_template('ffmpeg_ctl.html')


@app.route('/mkmoz', methods=['GET', 'POST'])
def mkmoz():
    im = Image.new("RGB", (2048, 2048), (250, 250, 250))
    for i in range(0, 2500):
        if i < 500:
            DIR = "/home/jack/.cache/thumbnails/large/*.png"
        if i > 500:
            DIR = "/home/jack/.cache/thumbnails/normal/*.png"
        # if i> 2495:DIR = "/home/jack/.cache/thumbnails/large/*.png"
        thumb = random.choice(glob.glob(DIR))
        print("THUMB:", thumb)
        Thum = Image.open(thumb)
        im.paste(Thum, ((randint(0, im.size[0])), randint(0, im.size[1]) - 50))
        filename = "static/images/ThumbNails.png"
        im.save(filename)
        Filename = "images/ThumbNails.png"
    return render_template("mkmoz.html", filename=Filename)


@app.route('/mk_background', methods=['GET', 'POST'])
def mk_background():
    im = Image.new("RGB", (8000, 512), (127, 255, 127))
    for i in range(0, 1000):
        if i < 250:
            DIR = "/home/jack/.cache/thumbnails/large/*.png"
        else:
            DIR = "/home/jack/.cache/thumbnails/normal/*.png"
        thumb = random.choice(glob.glob(DIR))
        print("THUMB:", thumb)
        Thum = Image.open(thumb)
        im.paste(Thum, ((randint(0, im.size[0])), randint(0, im.size[1]) - 50))
        filename = "static/images/ThumbNails_Background.png"
        im.save(filename)
    return redirect('/mkvid')


@app.route('/mkvid')
def mkvid():
    Filename = "static/images/ThumbNails_Background.png"
    Video_file = "static/images/ThumbNails_Background_FFmpeg.mp4"
    command = [
        'FFmpeg', '-hide_banner',
        '-loop', '1', '-i', 'static/images/ThumbNails_Background.png',
        '-vf', 'scale=8000:512,scroll=horizontal=0.0001,crop=768:512:0:0,format=yuv420p',
        '-t', '240', '-y', 'static/images/ThumbNails_Background_FFmpeg.mp4'
    ]
    subprocess.run(command)
    return redirect('/mkvid2')


@app.route('/mkvid2')
def mkvid2():
    command2 = [
        'ffmpeg', '-hide_banner',
        '-i', 'static/images/ThumbNails_Background_FFmpeg.mp4',
        '-vf', 'scale=512:768,setsar=1/1',
        '-c:a', 'copy', '-y', 'static/images/long_512-768.mp4'
    ]
    subprocess.run(command2)
    Filenamez = "images/ThumbNails_Background.png"
    Video_filez = "images/long_512-768.mp4"
    return render_template("mkvid2.html", filename=Filenamez, video=Video_filez)


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


@app.route('/view_thumbs')
def view_thumbs():
    # Define the directory where the images are located
    image_directory = 'static/images/uploads'
    # Get a list of all the image files in the directory
    image_files = [f for f in os.listdir(
        image_directory) if f.endswith('.jpg') or f.endswith('.png')]
    # Create a list of dictionaries containing the image file name and URL
    image_list = [{'name': f, 'url': f'/images/uploads/{f}'}
                  for f in image_files]
    # Render the template with the list of images
    return render_template('view_thumbs.html', image_list=image_list)


@app.route('/add_text', methods=['GET', 'POST'])
def add_text():
    if request.method == 'POST':
        text = request.form['text']
        now = datetime.datetime.now()
        timestamp = now.strftime("%Y-%m-%d %H:%M:%S")
        text = f'Text Entry: {timestamp} {text}'
        with open('chat.txt', 'a') as file:
            file.write(f'\n{text}')
        return render_template('add_text.html', message='Text added successfully')
    else:
        return render_template('add_text.html')


@app.route('/search_txt', methods=['GET', 'POST'])
def search_txt():
    if request.method == 'POST' and 'phrase' in request.form:
        phrase = request.form['phrase']
        with open('chat.txt', 'r') as file:
            lines = file.readlines()
        results = []
        for i, line in enumerate(lines):
            if phrase in line:
                start = max(0, i - 5)
                end = min(len(lines), i + 6)
                context = lines[start:end]
                for j, context_line in enumerate(context):
                    if phrase in context_line:
                        phrase = phrase.strip()
                        results.append(f'Line {start+j}: {context_line}')
                    else:
                        phrase = phrase.strip()
                        results.append(f'Line {start+j}: {context_line}')
        return render_template('results.html', results=results)
    return render_template('search_txt.html')

@app.route('/search_text', methods=['GET', 'POST'])
def search_text():
    if request.method == 'POST' and 'phrase' in request.form:
        phrase = request.form['phrase']
        with open('chat.txt', 'r') as file:
            file_contents = file.read()
        
        # Split the file contents at the ##====== declarations
        route_declarations = file_contents.split('##======')
        results = set()  # Use a set to store unique results
        for declaration in route_declarations:
            if phrase in declaration:
                # Check if the declaration starts with '@app.route'
                if declaration.strip().startswith('@app.route'):
                    # Split the declaration into lines
                    lines = declaration.split('\n')
                    formatted_lines = []
                    for line in lines:
                        if line.strip().startswith('@app.route'):
                            # Remove leading spaces from lines starting with '@app.route'
                            formatted_lines.append(line.lstrip())
                        else:
                            formatted_lines.append(line)
                    declaration = '\n'.join(formatted_lines)
                results.add(declaration)

        return render_template('results.html', results=list(results))
    return render_template('search_text.html')




@app.route('/blend_pil', methods=['POST', 'GET'])
def blend_pil():
    if request.method == 'POST':
        # Get the uploaded images
        img1 = request.files['img1']
        img2 = request.files['img2']
        img3 = request.files['img3']

        # Open the images using PIL
        img1_pil = Image.open(img1)
        img2_pil = Image.open(img2)
        img3_pil = Image.open(img3)

        # Blend the images
        blended_pil = Image.blend(img1_pil, img2_pil, 1 / 3)
        blended_pil = Image.blend(blended_pil, img3_pil, 1 / 3)

        # Return the blended image as a response
        # Since we are not saving it to the server, we can use a BytesIO object to avoid creating a temporary file
        img_io = BytesIO()
        blended_pil.save(img_io, 'JPEG', quality=70)
        current_datetime = datetime.now()
        str_current_datetime = str(current_datetime)
        file_name = "static/images/uploads/blended_pil" + \
            str_current_datetime + "XXXX.jpg"
        blended_pil.save(file_name, format='JPEG')
        img_io.seek(0)

        # Generate the HTML for displaying the blended image in the template
        blended_image_data = base64.b64encode(
            img_io.getvalue()).decode('utf-8')
        blended_image_url = f"data:image/jpeg;base64,{blended_image_data}"
        # blended_image_url = blended_image_url.resize(( blended_image_url.size[0]//2, blended_image_url.size[1]//2), Image.ANTIALIAS)
        # Pass the URL of the blended image to the template
        return render_template('show_blend_pil.html', blended_image_url=blended_image_url)
    return render_template('blend_pil.html')


@app.route('/process_images', methods=['POST', 'GET'])
def process_images():
    if request.method == 'POST':
        # read the images from the request
        img1 = Image.open(request.files['image1'].stream).convert('RGB')
        img2 = Image.open(request.files['image2'].stream).convert('L')
        img3 = Image.open(request.files['image3'].stream).convert('RGB')

        # resize the images to have the same shape
        img1 = img1.resize((img2.width, img2.height))
        img3 = img3.resize((img2.width, img2.height))

        # convert the mask to binary
        threshold = 127
        mask = Image.eval(img2, lambda px: 255 if px > threshold else 0)

        # apply the mask
        img = Image.composite(img1, img3, mask)

        # save the image to a file
        output = BytesIO()
        current_datetime = datetime.now()
        str_current_datetime = str(current_datetime)
        file_name = "static/images/" + str_current_datetime + "XXXX.jpg"
        img.save(file_name, format='JPEG')
        img.save(output, format='JPEG')
        output.seek(0)

        # encode the image to bytes
        img_bytes = output.getvalue()

        # return the image as a response
        return Response(img_bytes, mimetype='image/jpeg')
    return render_template('process_images.html')


@app.route('/image_directories', methods=['GET', 'POST'])
def image_directories():
    image_directories = ['static/Prodia_640x640', 'static/LineArt',
                         'static/Quantized', 'static/squares', 'static/BrightColors']
    if request.method == 'POST':
        # Rest of the code

        directory = request.form['directory']
        # Check that the directory parameter is not empty
        if directory:
            logger.info(
                'Redirecting endpoint with directory: %s', directory)
            # Check that the directory is a valid directory path
            if os.path.isdir(directory):
                # Pass the directory value to the square_video endpoint
                logger.info(
                    'Redirecting to square_video endpoint with directory: %s', directory)
                return redirect(url_for('square_video', directory=directory))
            else:
                # Render an error template if the directory parameter is not a valid directory path
                logger.error('Invalid directory parameter: %s', directory)
                return render_template('error.html', message='Please enter a valid directory path.')
        else:
            # Render an error template if the directory parameter is empty
            logger.error('Directory parameter is empty')
            return render_template('error.html', message='Please enter a directory path.')
    else:
        # Pass the list of image directories to the template
        return render_template('image_directories.html', image_directories=image_directories)

# USE_AUDIO_MP3 = False  # Set this to True if you want to use 'static/audio_mp3/'
# MDIR = 'static/music/' if not USE_AUDIO_MP3 else 'static/audio_mp3/'

# ...


@app.route('/select_playmp3', methods=['GET', 'POST'])
def select_playmp3():
    selected_directory = request.args.get('selected_directory')  # Use args instead of form for GET method
    selected_mp3 = request.form.get('mp3_file')  # Check the name attribute of your form input
    
    logging.info(f"Selected Directory: {selected_directory}")
    logging.info(f"Selected MP3: {selected_mp3}")
    
    directories = ['static/audio_mp3/', 'static/music/']
    mp3_files = []

    if selected_directory:
        mp3_files = [f for f in os.listdir(selected_directory) if f.endswith('.mp3')]
    
        # Sort the list of MP3 files by size in descending order (largest first)
        mp3_files.sort(key=lambda x: os.path.getsize(os.path.join(selected_directory, x)), reverse=True)
    
    if request.method == 'POST' and selected_mp3 and selected_directory:
        mp3_path = os.path.join(selected_directory, selected_mp3)
        
        logging.info(f"MP3 Path: {mp3_path}")
        
        pygame.mixer.init()
        pygame.mixer.music.load(mp3_path)
        pygame.mixer.music.play()
        
        while pygame.mixer.music.get_busy():
            pygame.time.Clock().tick(10)
        
        pygame.mixer.quit()
        pygame.quit()
    
    fvideo = findvideos()
    return render_template('select_playmp3.html', directories=directories, selected_directory=selected_directory, mp3_files=mp3_files, video=fvideo)


@app.route("/make_animation")
def make_animation():
    # Get a list of all files in the final_images directory
    # image_files = os.listdir("static/final_images/")
    # DIR = "/home/jack/Desktop/HDD500/collections/gypsy_files/"
    # DIR = "/home/jack/Desktop/HDD500/collections/hippy_files/"
    # DIR = "/mnt/HDD500/collections/jungle/exotic_lithograph_prints-Playground_AI_files/512x768/"
    DIR = "static/images/clip_drop/"
    selected_files = random.sample(glob.glob(DIR + '*.jpg'), 30)
    print(selected_files)
    # image_files = os.listdir(DIR)
    # image_files = os.listdir("/mnt/HDD500/collections/640x640-alien/")
    # Select 20 random files from the list
    # selected_files = random.sample(image_files, 30)

    # Load each selected file, resize it to 400x600, and save it to a temporary directory
    resized_images = []
    for filename in selected_files:
        print(filename)
        with Image.open(filename) as img:

            img = img.resize((400, 600))
            temp_filename = "static/tmp/" + filename
            img.save(temp_filename)
            resized_images.append(temp_filename)

    # Create an animated GIF from the resized images

    gif_filename = "static/animated_gifs/animated.gif"
    with imageio.get_writer(gif_filename, mode='I', duration=1) as writer:
        for filename in resized_images:
            image = imageio.imread(filename)
            writer.append_data(image)
    import shutil

    timestr = time.strftime("%Y%m%d-%H%M%S")

    src = 'static/animated_gifs/animated.gif'
    dst = 'static/animated_gifs/animated' + timestr + '.gif'
    # 2nd option
    shutil.copy(src, dst)
    # Return a template that displays the GIF
    return render_template("make_animation.html", gif_filename=gif_filename)


@app.route('/title_page', methods=['GET', 'POST'])
def title_page():
    if request.method == 'POST':
        # Get the text input and image file from the form data
        text = request.form['text']
        image = request.files['image']

        # Save the image to a temporary location
        image_path = os.path.join(
            app.config['UPLOAD_FOLDER'], secure_filename(image.filename))
        image.save(image_path)

        # Open the image file
        image = Image.open(image_path)

        # Create a drawing context on the image
        draw = ImageDraw.Draw(image)

        # Define the font and font size for the text
        font = ImageFont.truetype('static/fonts/OpenSansBold.ttf', 50)
        # Split the text by newline characters
        lines = text.split("  ")

        # Calculate the size of each line and get the maximum width
        line_sizes = [draw.textsize(line, font) for line in lines]
        max_line_width = max([size[0] for size in line_sizes])

        # Calculate the total size of the text
        text_width = max_line_width
        text_height = sum([size[1] for size in line_sizes])

        # Calculate the position of the text in the center of the image
        x = (640 - text_width) / 2
        y = (640 - text_height) / 2

        # Calculate the size of the text
        text_width, text_height = draw.textsize(text, font)

        # Calculate the position of the text in the center of the image
        x = (640 - text_width) / 2
        y = (640 - text_height) / 2

        # Add the text to the image
        draw.text((x, y), text, font=font, fill=(0, 0, 0, 255))

        # Save the image to the static folder with a unique filename
        inc = text.replace(" ", "")
        filenamex = os.path.join(
            app.static_folder, 'title_pages', f'{inc}_{hash(text)}.png')
        image.save(filenamex)
        filename = 'static/title_pages/title_page.png'
        shutil.copy(filenamex, filename)
        logger.error('filename: %s', filename)

        # print(inc[:5])
        # Remove the temporary image file
        # os.remove(image_path)
        filenamev = 'title_pages/title_page.png'
        # Return the rendered template with the image filename
        return render_template('title_page.html', filename=filenamev)
    filenamev = 'title_pages/title_page.png'
    return render_template('title_page.html', filename=filenamev)


@app.route('/add_title', methods=['GET', 'POST'])
def add_title():
    # Create the final_videos directory if it does not exist
    final_videos_dir = os.path.join(app.static_folder, 'final_videos')
    if not os.path.exists(final_videos_dir):
        os.makedirs(final_videos_dir)

    if request.method == 'POST':
        logger.debug('Entering POST request handler for /add_title')
        # Get the paths of the selected video and title page
        video_path = os.path.join(
            app.static_folder, 'videos', request.form['video'])
        title_page_path = os.path.join(
            app.static_folder, 'title_pages', request.form['title_page'])
        logger.debug(f'video_path: {video_path}')
        logger.debug(f'title_page_path: {title_page_path}')

        # Load the video and title page as clips
        video_clip = VideoFileClip(video_path)
        title_page_clip = ImageClip(title_page_path).set_duration(2)

        # Add the title page to the video for the first 2 seconds
        final_clip = concatenate_videoclips(
            [title_page_clip, video_clip.subclip(2)])

        # Save the final video to the final_videos directory
        final_filename = f"{os.path.splitext(request.form['video'])[0]}_{os.path.splitext(request.form['title_page'])[0]}.mp4"
        final_path = os.path.join(final_videos_dir, final_filename)
        logger.debug(f'final_path: {final_path}')
        final_clip.write_videofile(final_path)

        # Return a response to the user indicating that the video with title page was created
        message = f"The video with title page was created and saved to {final_path}"
        return render_template('add_title.html', message=message)

    # If the request method is GET, render the add_title.html template
    logger.debug('Entering GET request handler for /add_title')
    videos = os.listdir(os.path.join(app.static_folder, 'square_vids'))
    title_pages = os.listdir(os.path.join(app.static_folder, 'title_pages'))
    logger.debug(f'videos: {videos}')
    logger.debug(f'title_pages: {title_pages}')
    return render_template('add_title.html', videos=videos, title_pages=title_pages)


def get_rowid():
    # Connect to the database
    db = sqlite3.connect('code.db')
    cursor = db.cursor()
    row_id = request.form['row_id']
    # Execute a query to retrieve the rowid
    cursor.execute("SELECT rowid FROM snippets WHERE rowid = ?", (rowid,))

    # Fetch the result
    result = cursor.fetchone()

    # Close the database connection
    db.close()

    # Check if a rowid was found
    if result:
        rowid = result[0]
    else:
        # Handle the case when no rowid is found
        rowid = None

    return rowid


@app.route('/indexA')
def indexA():
    image_dir = 'static/images'
    image_files = [f for f in os.listdir(image_dir) if f.endswith('.jpg')]
    random_image_file = random.choice(image_files)
    logger.info(f"Random image file selected: {random_image_file}")
    return render_template('indexA.html', random_image_file=random_image_file)


@app.route('/index_FLASK')
def index_FLASK():
    image_dir = 'static/images'
    image_files = [f for f in os.listdir(image_dir) if f.endswith('.jpg')]
    random_image_file = random.choice(image_files)
    logger.info(f"Random image file selected: {random_image_file}")

    return render_template('index_FLASK.html')


# Configuration
app.config['DATABASE'] = 'code.db'


def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect("code.db")
    return db


@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()


@app.before_first_request
def create_table():
    db = get_db()
    cursor = db.cursor()

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            price REAL
        )
    ''')

    db.commit()


@app.teardown_appcontext
def close_connection(exception):
    db = getattr(app, '_database', None)
    if db is not None:
        db.close()


@app.route('/indexD')
def indexD():
    return render_template('/indexD.html')


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


def create_databaseD():
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


@app.route('/indexE')
def indexE():
    # Get a list of directories within static/images
    image_directories = os.listdir(os.path.join(app.static_folder, 'images'))

    # Create a dropdown menu with the list of directories
    dropdown_menu = ""
    for directory in image_directories:
        dropdown_menu += f'<option value="{directory}">{directory}</option>'

    return f"""
    <!DOCTYPE html>
    <html>
    <body>
        <h2>Upload a file</h2>
        <form action="/uploadN" method="post" enctype="multipart/form-data">
            <select name="directory">
                {dropdown_menu}
            </select>
            <input type="file" name="file">
            <input type="submit" value="Upload">
        </form>
    </body>
    </html>
    """


@app.route('/uploadN', methods=['POST'])
def upload_fileN():
    # Check if a file was submitted in the request
    if 'file' not in request.files:
        return redirect(url_for('indexD'))

    file = request.files['file']

    # Check if the file is not empty
    if file.filename == '':
        return redirect(url_for('indexE'))

    # Save the file to the desired directory
    save_path = os.path.join('static', 'temp_images', file.filename)
    file.save(save_path)

    return f'The file {file.filename} has been uploaded successfully!'


def FilenameByTime(directory):
    timestr = time.strftime("%Y%m%d-%H%M%S")
    filename = directory + "/" + timestr + "_.png"
    return filename


def change_extension(orig_file, new_extension):
    p = change_ext(orig_file)
    new_name = p.rename(p.with_suffix(new_extension))
    return new_name


def auto_canny(image, sigma=0.33):
    # compute the median of the single channel pixel intensities
    v = np.median(image)
    # apply automatic Canny edge detection using the computed median
    lower = int(max(0, (1.0 - sigma) * v))
    upper = int(min(255, (1.0 + sigma) * v))
    edged = cv2.Canny(image, lower, upper)
    # return the edged image
    return edged
# image = cv2.imread('mahotastest/orig-color.png')


def change_extension(orig_file, new_extension):
    p = change_ext(orig_file)
    new_name = p.rename(p.with_suffix(new_extension))
    return new_name


def outlineJ(filename1, outfile_jpg, sigma=0.33):
    """
    USE:
    filename1 = '/home/jack/Desktop/Imagedata/0-original-images/07082orig.jpg' 
    outfile_jpg = '/home/jack/Desktop/dockercommands/images/useresult.png'
    outlineJ(filename1,outfile_jpg)
    """
    image = cv2.imread(filename1)
    edged = auto_canny(image, sigma=0.33)
    inverted = cv2.bitwise_not(edged)
    cv2.imwrite("static/outlines/temp2.png", inverted)
    cv2.imwrite(FilenameByTime("static/outlines/"), inverted)
    # Open Front Image
    # frontimage = Image.open('mahotastest/inverted-bitwise-note3_6.png').convert("1")
    frontimage = Image.open('static/outlines/temp2.png').convert("1")
    frontImage = frontimage.convert("RGBA")
    datas = frontImage.getdata()
    newData = []
    for item in datas:
        if item[0] == 255 and item[1] == 255 and item[2] == 255:
            newData.append((255, 255, 255, 0))
        else:
            newData.append(item)

    frontImage.putdata(newData)
    # Open Background Image
    background = Image.open(filename1)
    # Calculate width to be at the center
    width = (frontimage.width - frontimage.width) // 2
    # Calculate height to be at the center
    height = (frontimage.height - frontimage.height) // 2
    # Paste the frontImage at (width, height)
    background.paste(frontImage, (width, height), frontImage)
    # Save this image
    background.save(outfile_jpg)
    savefile = FilenameByTime("static/outlines/")
    background.save(savefile)
    # background = background.convert("RGB")
    return background


def outlineP(filename1, outfile_png):
    """
    USE:
    filename1 = '/home/jack/Desktop/Imagedata/0-original-images/07082orig.jpg'
    outfile_jpg = '/home/jack/Desktop/dockercommands/images/useresult.png'
    outlineP(filename1,outfile_png)
    """
    image = cv2.imread(filename1)
    edged = auto_canny(image, sigma=0.33)
    inverted = cv2.bitwise_not(edged)
    cv2.imwrite("static/outlines/temp2.png", inverted)
    cv2.imwrite(FilenameByTime("static/outlines/"), inverted)
    # Open Front Image
    # frontimage = Image.open('mahotastest/inverted-bitwise-note3_6.png').convert("1")
    frontimage = Image.open('static/outlines/temp2.png').convert("1")
    frontImage = frontimage.convert("RGBA")
    datas = frontImage.getdata()
    newData = []
    for item in datas:
        if item[0] == 255 and item[1] == 255 and item[2] == 255:
            newData.append((255, 255, 255, 0))
        else:
            newData.append(item)

    frontImage.putdata(newData)
    # Open Background Image
    background = Image.open(filename1)
    # Calculate width to be at the center
    width = (frontimage.width - frontimage.width) // 2
    # Calculate height to be at the center
    height = (frontimage.height - frontimage.height) // 2
    # Paste the frontImage at (width, height)
    background.paste(frontImage, (width, height), frontImage)
    # Save this image
    background.save(outfile_png, format="png")
    savefile = FilenameByTime("static/outlines/")
    background.save(savefile, format="png")
    # background = background.convert("RGB")
    return background


@app.route('/outline_j', methods=['POST'])
def outline_j():
    if request.method == 'POST':
        # Get the uploaded image file from the form data
        file = request.files['file']

        # Save the uploaded file to a temporary location

        temp_path = 'static/outlines/temp_image.jpg'
        file.save(temp_path)

        # Process the image using outlineJ function
        output_path = 'static/outlines/outlined_image_j.jpg'
        outlineJ(temp_path, output_path)
        output_path2 = "static/outlines/temp2.png"
        # Return the path to the processed image to display it on a page
        return render_template('outlined_image.html', image_orig=temp_path, image_path=output_path, image_path2=output_path2)


@app.route('/outline_p', methods=['POST'])
def outline_p():
    if request.method == 'POST':
        # Get the uploaded image file from the form data
        file = request.files['file']

        # Save the uploaded file to a temporary location
        temp_path = 'static/temp_image.jpg'
        image_orig = temp_path
        file.save(temp_path)

        # Process the image using outlineP function
        output_path = 'static/outlines/outlined_image_p.png'
        outlineP(temp_path, output_path)
        output_path2 = "static/outlines/temp2.png"
        # Return the path to the processed image to display it on a page
        return render_template('outlined_image.html', image_orig=temp_path, image_path=output_path, image_path2=output_path2)


def zoom_effect(bg_file, fg_file):
    bg = Image.open(bg_file).convert('RGBA')
    SIZE = bg.size
    bg = bg.resize((SIZE), Image.BICUBIC)
    fg = Image.open(fg_file).convert('RGBA')
    fg = fg.resize((SIZE), Image.BICUBIC)
    fg_copy = fg.copy()
    fg_copy = fg_copy.resize((int(fg_copy.width), int(fg_copy.height)))
    result_images = []
    for i in range(200):
        size = (int(fg_copy.width * (i + 1) / 200),
                int(fg_copy.height * (i + 1) / 200))
        fg_copy_resized = fg_copy.resize(size)
        fg_copy_resized.putalpha(int((i + 1) * 255 / 200))
        fg_copy_resized = fg_copy_resized.convert('RGBA')
        fg_copy_resized.putalpha(int((i + 1) * 255 / 200))
        result = bg.copy()
        x = int((bg.width - fg_copy_resized.width) / 2)
        y = int((bg.height - fg_copy_resized.height) / 2)
        result.alpha_composite(fg_copy_resized, (x, y))
        # result.save("gifs/_"+str(i)+".png")
        result_images.append(result)

    return result_images  # Move the return statement outside the for loop


def create_mp4_from_images(images_list, output_file, fps):
    # Convert PIL Image objects to NumPy arrays
    image_arrays = [np.array(image) for image in images_list]

    # Create the video clip from the NumPy arrays
    clip = ImageSequenceClip(image_arrays, fps=fps)

    # Write the video to the output file
    clip.write_videofile(output_file, codec="libx264", fps=fps)


@app.route('/upload_form')
def upload_form():
    return render_template('upload_form.html')


@app.route('/process_imagez', methods=['POST', 'GET'])
def process_imagez():
    if 'bg_image' not in request.files or 'fg_image' not in request.files:
        return redirect(url_for('upload_form'))

    bg_image = request.files['bg_image']
    fg_image = request.files['fg_image']

    if bg_image.filename == '' or fg_image.filename == '':
        return redirect(url_for('upload_form'))

    bg_filename = 'background.png'
    fg_filename = 'foreground.png'

    bg_image.save(bg_filename)
    fg_image.save(fg_filename)

    bg_file_path = os.path.abspath(bg_filename)
    fg_file_path = os.path.abspath(fg_filename)

    images_list = zoom_effect(bg_file_path, fg_file_path)

    output_mp4_file = 'static/overlay_zooms/imagez_video.mp4'
    frames_per_second = 30
    create_mp4_from_images(images_list, output_mp4_file, frames_per_second)

    # Clean up temporary files
    # os.remove(bg_filename)
    # os.remove(fg_filename)
    file_bytime = time.strftime("%Y%m%d-%H%M%S") + ".mp4"

    shutil.copy('static/overlay_zooms/imagez_video.mp4',
                'static/overlay_zooms/' + file_bytime)
    video_url = url_for('static', filename=output_mp4_file)
    return render_template('upload.html', video_url=video_url)


app.config['DATABASE'] = 'code.db'

# Set up logger
# logger.basicConfig(level=logger.DEBUG)
# logger = logger.getLogger(__name__)


def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(app.config['DATABASE'])
    return db


@app.route('/indexdb')
def indexdb():
    logger.debug("Accessing indexdb route")
    video = findvideos()
    return render_template('indexdb.html', video=video)


@app.route('/select_by_id_form', methods=['POST', 'GET'])
def select_by_id_form():
    logger.debug("Accessing select_by_id_form route")
    return render_template('select_by_id_form.html')


@app.route('/search_by_rowid', methods=['GET', 'POST'])
def search_by_rowid():
    logger.debug("Accessing search_by_rowid route")
    return render_template('search_by_rowid.html')

# ...
# ...
# ...
# Function to get a list of image files from the selected directory


def get_image_list(selected_directory):
    image_extensions = ['.jpg', '.jpeg', '.png', '.gif']
    image_list = [f for f in os.listdir(selected_directory) if os.path.isfile(
        os.path.join(selected_directory, f)) and f.lower().endswith(tuple(image_extensions))]
    print(image_list)
    return image_list


@app.route('/Index', methods=['GET', 'POST'])
def Index():
    if request.method == 'POST':
        selected_directory = request.form['selected_directory']
        image_list = get_image_list(selected_directory)
        images = [os.path.join(selected_directory, image)
                  for image in image_list]

        clips = [ImageClip(m).set_duration(0.5) for m in images]
        concat_clip = concatenate_videoclips(clips, method="compose")
        uid = str(uuid.uuid4())  # Generate a unique ID using uuid
        mp4_file = os.path.join("static", "videos", f"{uid}.mp4")
        concat_clip.write_videofile(mp4_file, fps=24)
        return render_template('Index.html', video=mp4_file)
    else:
        directory_list = glob.glob("static/images/*/", recursive=True)
        return render_template('Index.html', directory_list=directory_list)
# ...
# ...

# ...


@app.route('/edit_data_page', methods=['GET', 'POST'])
@app.route('/edit_data_page/<int:rowid>', methods=['GET', 'POST'])
def edit_data_page(rowid=None):
    db = get_db()
    cursor = db.cursor()

    if request.method == 'POST':
        description = request.form['description']
        code = request.form['code']
        keywords = request.form['keywords']

        if rowid is not None:
            # Update the data in the database for the given rowid
            cursor.execute("UPDATE snippets SET description = ?, code = ?, keywords = ? WHERE rowid = ?",
                           (description, code, keywords, rowid))
        else:
            # Insert the data into the database as a new row
            cursor.execute("INSERT INTO snippets (description, code, keywords) VALUES (?, ?, ?)",
                           (description, code, keywords))

        db.commit()

        # Close the database connection
        cursor.close()
        db.close()

        return redirect(url_for('indexdb'))

    if rowid is not None:
        # If a rowid is provided, retrieve the data from the database
        # based on the provided rowid and render the edit_data.html template
        cursor.execute("SELECT * FROM snippets WHERE rowid = ?", (rowid,))
        data = cursor.fetchone()

        if data is None:
            # If no data is found for the given rowid, return an error message
            return "Error: Data not found for the provided Row ID."

        # Convert the fetched data to a dictionary for easier access in the template
        data = {
            'rowid': data[0],
            'description': data[1],
            'code': data[2],
            'keywords': data[3]
        }

    else:
        # If no rowid is provided, create an empty data dictionary
        data = {}

    # Close the database connection
    cursor.close()
    db.close()

    return render_template('edit_data.html', data=data)
# ...


@app.route('/get_rowid_form', methods=['GET', 'POST'])
def get_rowid_form():
    if request.method == 'POST':
        rowid = request.form['rowid']
        return redirect(url_for('edit_data_page', rowid=rowid))
    return render_template('get_rowid_form.html')

# ...


@app.route('/search_database', methods=['POST', 'GET'])
def search_database():
    logger.debug("Accessing search_database route")
    if request.method == 'POST':
        search_term = request.form['search_term']
        search_area = request.form['search_area']
    else:
        # For GET requests, get the search_term and search_area from the query string
        search_term = request.args.get('search_term')
        search_area = request.args.get('search_area')

    if not search_term or not search_area:
        logger.debug(
            "Redirecting to indexdb due to missing search_term or search_area")
        # Redirect to the main index page if search_term or search_area is missing
        return redirect('/indexdb')

    db = get_db()
    cursor = db.cursor()

    if search_area == 'rowid':
        cursor.execute(
            "SELECT rowid, * FROM snippets WHERE rowid = ?", (search_term,))
    elif search_area == 'description':
        cursor.execute(
            "SELECT rowid, * FROM snippets WHERE description LIKE ?", ('%' + search_term + '%',))
    elif search_area == 'code':
        cursor.execute(
            "SELECT rowid, * FROM snippets WHERE code LIKE ?", ('%' + search_term + '%',))
    elif search_area == 'keywords':
        cursor.execute(
            "SELECT rowid, * FROM snippets WHERE keywords LIKE ?", ('%' + search_term + '%',))
    else:
        logger.debug("Redirecting to indexdb due to invalid search area")
        # Redirect to the main index page if an invalid search area is provided
        return redirect('/indexdb')

    results = cursor.fetchall()
    logger.debug("Rendering db_results.html template with search results")
    return render_template('db_results.html', results=results)


@app.route('/insert_data', methods=['POST', 'GET'])
def insert_data():
    logger.debug("Accessing insert_data route")
    if request.method == 'POST':
        description = request.form['description']
        code = request.form['code']
        keywords = request.form['keywords']

        # Assuming you have the database connection and cursor defined
        db = get_db()
        cursor = db.cursor()

        cursor.execute("INSERT INTO snippets (description, code, keywords) VALUES (?, ?, ?)",
                       (description, code, keywords))
        db.commit()

        # Close the database connection
        cursor.close()
        db.close()

        logger.debug("Redirecting to indexdb after inserting data")
        return redirect(url_for('indexdb'))

    # If the request method is not POST (e.g., GET), render the insert_data.html template
    logger.debug("Rendering insert_data.html template")
    return render_template('insert_data.html')


@app.route('/select_by_id', methods=['POST', 'GET'])
def handle_select_by_id():
    logger.debug("Accessing select_by_id route")
    if request.method == 'POST':
        row_id = request.form['search_term']
    else:
        row_id = request.args.get('search_term')

    db = get_db()
    cursor = db.cursor()

    cursor.execute("SELECT * FROM snippets WHERE rowid = ?", (row_id,))
    data = cursor.fetchone()

    cursor.close()
    db.close()

    if data is not None:
        id_value = data[0]
        description = data[1]
        code = data[2]
        keywords = data[3]

        logger.debug("Rendering display_data.html template with selected data")
        return render_template('display_data.html', id_value=id_value, description=description, code=code, keywords=keywords)
    else:
        logger.debug("Rendering display_data.html template with no data found")
        return render_template('display_data.html', id_value=row_id, description="", code="", keywords="")


def extract_code_blocks(file_path):
    with open(file_path) as file:
        content = file.read()
    return content.split("--Code Start:")[1:]


def format_datetime(datetime_str):
    return datetime_str.replace("_", " ")


@app.route('/enter_code', methods=['GET', 'POST'])
def enter_code():
    formatted_datetime = ""  # Initialize the variable
    if request.method == 'POST':
        code_block = request.form['code_block']
        formatted_datetime = datetime.datetime.now().strftime("%a_%d_%b_%Y %H:%M:%S")
        with open('codeshints.txt', 'a') as file:
            file.write(f"--Code Start:\n{formatted_datetime}\n{code_block}\n--Code End:\n\n")
        # Log code entry
        logger.debug('New code entered: %s', code_block)
    return render_template('enter_data.html', formatted_datetime=formatted_datetime)


@app.route('/search_code', methods=['GET', 'POST'])
def search_code():
    if request.method == 'POST':
        keyword = request.form['keyword']
        code_blocks = extract_code_blocks('codeshints.txt')
        filtered_blocks = [block for block in code_blocks if keyword in block]
        formatted_datetime_blocks = []
        
        for block in filtered_blocks:
            match = re.search(r"\w+_\d+_\w+_\d+_\d+:\d+:\d+", block)
            if match:
                formatted_datetime = format_datetime(match.group(0))
            else:
                formatted_datetime = "Unknown datetime format"
            
            formatted_datetime_blocks.append(
                {"datetime": formatted_datetime, "code_block": block}
            )
            
        # Log search activity
        logger.debug('Keyword searched: %s', keyword)
        return render_template('search_results.html', keyword=keyword, code_blocks=formatted_datetime_blocks)
    
    return render_template('search_data.html')


@app.route('/tube_index')
def tube_index():
    return render_template('tube_index.html')


@app.route('/data_page')
def data_page():
    return render_template('data_page.html')

@ app.route('/capture_overlay_verify')
def capture_overlay_verify():
    logger.info('Capture process started')
    logger.info('POST request received')

    datename = subprocess.run(
        ["date", "+%Y-%m-%d_%H-%M-%S"], capture_output=True, text=True).stdout.strip()
    capture_filename = f"{datename}.mp4"
    # Create the file path using os.path.join()
    base_folder = "static"
    subfolder = "assets"
    original_filename = os.path.join(
        app.root_path, base_folder, subfolder, f"overlaid_{capture_filename}")
    overlayed_filename = os.path.join(
        app.root_path, base_folder, subfolder, f"overlaid_{capture_filename}")
    verification_filename = os.path.join(
        app.root_path, base_folder, subfolder, f"verification_{capture_filename}")
    logger.info(f'File path original_filename created: {original_filename}')
    logger.info(f'File path overlayed_filename created: {overlayed_filename}')
    logger.info(f' verification_filename created: {verification_filename}')
    sleep(5)
    # Capture screen
    capture_command = [
        "ffmpeg", "-ss", "2", "-f", "x11grab", "-framerate", "24",
        "-video_size", "690x445", "-i", ":0.0+130,250", "-f", "alsa",
        "-i", "plughw:0,0", "-f", "pulse", "-i", "default",
        "-filter_complex", "[1:a]volume=0.1,apad[headset_audio];[2:a]volume=2.0,apad[system_audio];[headset_audio][system_audio]amix=inputs=2[a]",
        "-map", "0:v", "-map", "[a]", "-c:v", "libx264", "-r", "24",
                "-g", "48", "-c:a", "aac", "-b:a", "128k", "-t", "58", "-y", original_filename
    ]
    subprocess.run(capture_command)
    logger.info('Screen captured', capture_command)
    # Overlay videos
    overlay_command = [
        "ffmpeg", "-i", "background.mp4", "-i", original_filename, "-filter_complex",
        f"[1:v]scale=460:300[ovrl];[0:v][ovrl]overlay=W-w-25:H-h-400[out]",
        "-map", "[out]", "-map", "1:a", "-c:v", "libx264", "-crf", "18", "-c:a", "aac",
                "-strict", "-2", "-y", "-t", "58", overlayed_filename
    ]
    subprocess.run(overlay_command)
    logger.info('Videos overlaid', overlay_command)

    # Verify sound
    verification_command = [
        "ffmpeg", "-i", "background.mp4", "-i", overlayed_filename, "-filter_complex",
        f"[1:v]scale=460:300[ovrl];[0:v][ovrl]overlay=W-w-25:H-h-400[out]",
        "-map", "[out]", "-map", "1:a", "-c:v", "libx264", "-crf", "18", "-c:a", "aac",
                "-strict", "-2", "-y", "-t", "58", verification_filename
    ]
    subprocess.run(verification_command)
    logger.info('Sound verified', verification_command)

    logger.info('Capture process completed', verification_filename)
    return render_template('view_capture.html', video_filename=verification_filename)

# ...


@app.route('/create_text', methods=['GET', 'POST'])
def create_text():
    if request.method == 'POST':
        text = request.form['text']
        image = Image.new('RGB', (512, 512), color='beige')
        draw = ImageDraw.Draw(image)

        # Load the custom font and set the size
        font_path = '/home/jack/fonts/OpenSans-Bold.ttf'
        font_size = 50
        font = ImageFont.truetype(font_path, font_size)

        lines = text.split('\n')[:5]

        y = 10
        for line in lines:
            line = line.rstrip()  # Strip the newline character
            # Calculate the width and height of the text
            text_width, text_height = draw.textsize(line, font=font)

            # Draw the text
            draw.text(((512 - text_width) // 2, y),
                      line, fill='black', font=font)
            y += text_height + 5  # Move down for the next line

        output_path = os.path.join(
            app.root_path, 'static', 'assets', '512x512_text.jpg')
        image.save(output_path)
        # return send_from_directory('static/assets', '512x512_text.jpg', as_attachment=True)
        return render_template('view_textimage.html', image_filename='assets/512x512_text.jpg')
    return render_template('create_text.html')


@app.route('/view_log')
def view_log():
    with open('Logs/app.log', 'r') as log_file:
        log_content = log_file.read()
    return render_template('log_viewer.html', log_content=log_content)


@app.route('/self_check')
def self_check():
    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    new_filename = f'Logs/{timestamp}.info'
    result = subprocess.run(['flake8', '-v', 'FlaskAppArchitect'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    logger.info("xxxxxxxx")
    logger.info("Self-check completed", result.stdout)
    with open('Logs/flake8.info', 'w') as flake_file:
        flake_file.write(result.stdout)
        shutil.copy('Logs/flake8.info', new_filename)
    return redirect(url_for('view_flake8'))


@app.route('/view_flake8')
def view_flake8():
    with open('Logs/flake8.info', 'r') as flake_file:
        flake_content = flake_file.read()
    return render_template('flake8_viewer.html', flake_content=flake_content)


def get_image_directories():
    dirs = os.listdir(os.path.join('static', 'images'))
    DIR = sorted(dirs)
    return DIR


def feather_image(input_path):
    try:
        logger.info("Feathering image: %s", input_path)
        
        # Load the image
        giger = cv2.imread(input_path)
        l_row, l_col, nb_channel = giger.shape
        rows, cols = np.mgrid[:l_row,:l_col]
        radius = np.sqrt((rows - l_row / 2) ** 2 + (cols - l_col / 2) ** 2)
        alpha_channel = np.zeros((l_row, l_col))
        
        # Calculate alpha channel values
        r_min, r_max = 1. / 3 * radius.max(), 0.6 * radius.max()
        alpha_channel[radius < r_min] = 1
        alpha_channel[radius > r_max] = 0
        gradient_zone = np.logical_and(radius >= r_min, radius <= r_max)
        alpha_channel[gradient_zone] = (r_max - radius[gradient_zone]) / (r_max - r_min)
        alpha_channel *= 255
        
        # Create feathered image
        feathered = np.empty((l_row, l_col, nb_channel + 1), dtype=np.uint8)
        feathered[...,:3] = giger[:]
        feathered[..., -1] = alpha_channel[:]
        
        # Save the feathered image
        timestamp = datetime.datetime.now().strftime('%Y%m%d%H%M%S')
        output_path = os.path.join('static', 'images', 'feathers', f'{timestamp}.png')
        plt.imsave(output_path, feathered, format="png")
        logger.info("Feathered image saved at: %s", output_path)

        return output_path
    except Exception as e:
        logger.error("An error occurred during feathering: %s", str(e))
        return None


@app.route('/feather_files', methods=['GET', 'POST'])
def feather_files():
    if request.method == 'POST':
        selected_directories = request.form.getlist('directories')  # Use 'directories' instead of 'directory'
        selected_directories = sorted(selected_directories)
        if selected_directories:
            images = os.listdir(os.path.join('static', 'images', selected_directories[0]))
            return render_template('feather_files.html', directories=get_image_directories(), selected_directory=selected_directories[0], images=images)
        
        selected_image = request.form.get('image')
        if selected_image:
            selected_directory = request.form.get('selected_directory')  # Add this line to retrieve selected_directory
            image_path = os.path.join('static', 'images', selected_directory, selected_image)
            feathered_image_path = feather_image(image_path)
            return render_template('feather_files.html', directories=get_image_directories(), selected_directory=selected_directory, images=os.listdir(os.path.join('static', 'images', selected_directory)), feathered_image_path=feathered_image_path)
    
    return render_template('feather_files.html', directories=get_image_directories())


@app.route('/word_cloud')
def word_cloud():
    code_blocks = extract_code_blocks('codeshints.txt')
    extracted_lines = []

    for block in code_blocks:
        lines = block.split("\n")[:3]  # Extract the first three lines
        extracted_lines.append("\n".join(lines))

    return render_template('word_cloud.html', extracted_lines=extracted_lines)


# ------------
static_dir = 'static'
text_dir = os.path.join(static_dir, 'text')
original_text_dir = os.path.join(text_dir, 'original')
os.makedirs(original_text_dir, exist_ok=True)


def load_original_text_file(filename):
    original_file_path = os.path.join(text_dir, filename)
    with open(original_file_path, 'r') as file:
        return file.read()


def save_original_text_file(filename, content):
    now = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    new_filename = f"{filename}_{now}.txt"
    new_file_path = os.path.join(original_text_dir, new_filename)
    with open(new_file_path, 'w') as file:
        file.write(content)


def edit_and_save_text_file(filename, content):
    save_original_text_file(filename, content)
    edited_file_path = os.path.join(text_dir, filename)
    with open(edited_file_path, 'w') as file:
        file.write(content)


@app.route('/edit_text')
def edit_text():
    filenames = [f for f in os.listdir(text_dir) if f.endswith('.txt')]
    return render_template('edit_text.html', filenames=filenames)


@app.route('/edit_text_page')
def edit_text_page():
    selected_filename = request.args.get('filename')
    original_content = load_original_text_file(selected_filename)
    return render_template('edit_text_page.html', selected_filename=selected_filename, original_content=original_content)


@app.route('/edit_text_save', methods=['POST'])
def edit_text_save():
    edited_content = request.form['edited_content']
    selected_filename = request.form['filename']
    edit_and_save_text_file(selected_filename, edited_content)
    return redirect(url_for('edit_text'))


@app.route('/the_description')
def the_description():
    return render_template('the_description.html')


@app.route('/run')
def run():
    return render_template('execute.html')


def save_script_to_file(script):
    # Retrieve textarea content
    script_content = script.strip('\r')
    for line in script_content.splitlines():
        if line.startswith('#'):
            script_head = script_content.replace(line, f"echo {line}")
            print("SCRIPT HEAD: ", script_head)

    # Generate unique filename
    current_datetime = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    filename = "static/scripts/" + current_datetime + "_script.sh"

    # Save content to file
    with open(filename, "w") as file:
        file.write(script_content)

    return filename


def list_functions():
    # Retrieve all function names from the script
    script_filenames = glob.glob("static/scripts/*.sh")
    
    for script_filename in script_filenames:
        with open(script_filename, "r") as file:
            script_content = file.read()
            print(script_content)

    # Find all function names
    function_names = re.findall(r"function\s+(\w+)\s*\(\)", script_content)
    return function_names


@app.route('/execute', methods=['POST', 'GET'])
def execute():
    # Extract the bash script from the textarea
    script = request.form['script']
    save_script_to_file(script)
    # Execute the bash script using subprocess
    result = subprocess.run(script, shell=True, capture_output=True, text=True)

    # Return the result to the client
    list_functions()

    # Return the result to the client
    list_functions()

    # Retrieve all function names from the script
    script_filenames = glob.glob("static/scripts/*.sh")
    CONTENT = []
    filename = []
    for script_filename in script_filenames:
        filename.append(script_filename)
        with open(script_filename, "r") as file:
            script_content = file.read()
            CONTENT.append(script_content)

    return render_template("view_execute.html", content=CONTENT, result=filename)


@app.route('/list_functions')
def list_functions():
    route_lines = get_route_lines()
    return render_template('list_functions.html', functions=route_lines)


def get_route_lines():
    with open('app_bp', 'r') as file:
        route_lines = [
            re.split(r'[,/]', line.strip())[1].replace("'", "").replace(")", "").replace('"', '').replace(" ", "")
            for line in file
            if line.strip() != '' and line.strip() != '@app.route("/")' and line.startswith('@app.route')
        ]
    return route_lines


# Call the function to get the route lines
route_lines = get_route_lines()
# Print the result
for line in route_lines:
    print(line)
    
    
@app.route('/all_routes')
def all_routes(): 
    return render_template('all_routes.html')

 
@app.route('/edit_description', methods=['GET', 'POST'])
def edit_description():
    # Open the 'the_description.html' file and read its contents
    with open('templates/the_description.html', 'r') as file:
        description = file.read()

    return render_template('edit_the_description.html', description=description)

    
@app.route('/save_description', methods=['POST'])
def save_description():
    # Retrieve the updated description from the form submission
    updated_description = request.form['description']

    # Open the 'the_description.html' file in write mode and save the updated description
    with open('templates/the_description.html', 'w') as file:
        file.write(updated_description)

    return redirect('/edit_description')


@app.route('/app_utilities')
def app_utilities():
    video = findvideos()
    return render_template('app_utilities.html', video=video)


@app.route("/image_processing")
def image_processing():
    video = findvideos()
    return render_template('image_processing.html', video=video)


template_dir = 'templates'
original_template_dir = os.path.join(template_dir, 'original')
os.makedirs(original_template_dir, exist_ok=True)


def load_original_template_file(filename):
    original_file_path = os.path.join(template_dir, filename)
    with open(original_file_path, 'r') as file:
        return file.read()


def save_original_template_file(filename, content):
    now = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
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


@app.route('/edit_javascript')
def edit_javascript():
    filenames = [f for f in os.listdir(template_dir) if f.endswith('script.html')]
    filenames = sorted(filenames)
    fvideo = findvideos()
    return render_template('edit_javascript.html', filenames=filenames, video=fvideo)


@app.route('/images/<path>')
def show_images(path):
    # get the full path of the directory
    basepath = os.path.join('static', 'images', path)
    # get the file names in the directory
    file_list = os.listdir(basepath)
    # filter out non-image files
    image_list = [f for f in file_list if f.endswith('.jpg') or f.endswith('.png')]
    # pass the image names to the template
    return render_template('thumbnailz.html', images=image_list, path=path)


@app.route('/code_editor')
def code_editor():
    
    return render_template('code_editor.html')


@app.route('/save', methods=['POST'])
def save():
    content = request.form.get('content')  # Get the content from the AJAX request
    file_path = 'static/text/Experimental.txt'  # Specify the file path where you want to save

    # Write the content to the file
    with open(file_path, 'w') as file:
        file.write(content)

    return jsonify({'message': 'File saved successfully'})


video_process = None


@app.route('/run_capture', methods=['POST'])
def run_capture():
    global video_process
    
    # Specify the path to your Bash script
    bash_script_path = 'STREAM-save-local'
    
    # Execute the Bash script and save the process ID
    video_process = subprocess.Popen(['bash', bash_script_path])
    
    return jsonify({'message': 'Video capture started'})


@app.route('/stop_capture', methods=['POST'])
def stop_capture():
    global video_process
    
    if video_process:
        # Send a termination signal to stop the process gracefully
        os.killpg(os.getpgid(video_process.pid), signal.SIGTERM)
        video_process = None
        return jsonify({'message': 'Video capture stopped'})
    else:
        return jsonify({'message': 'Video capture process not found'})


@app.route('/capture_html')
def capture_html():
    return render_template('capture.html')


@app.route('/youtube_videos')
def youtube_videos():
    return render_template('youtube_videos.html')


@app.route('/aigeneration_links')
def aigeneration_links():
    return render_template('aigeneration_links.html')


@app.route('/index_bash')
def index_bash():
    return render_template('run_bash.html')


@app.route('/run_bash', methods=['POST'])
def run_bash():
    bash_command = request.form.get('bash_command')
    
    try:
        result = subprocess.check_output(bash_command, shell=True, text=True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        result = e.output
    video = findvideos()
    return render_template('run_bash.html', result=result, video=video)


css_dir = 'static/css'
original_css_dir = os.path.join(css_dir, 'original')
os.makedirs(original_css_dir, exist_ok=True)


def load_original_css_file(filename):
    original_file_path = os.path.join(css_dir, filename)
    with open(original_file_path, 'r') as file:
        return file.read()


def save_original_css_file(filename, content):
    now = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
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


@app.route('/edit_css_save', methods=['POST'])
def edit_css_save():
    edited_content = request.form['edited_content']
    selected_filename = request.form['filename']
    edit_and_save_css_file(selected_filename, edited_content)
    return redirect(url_for('edit_css'))


@app.route('/terminal_index')
def terminal_index():
    return render_template('terminal_index.html')


@app.route('/execute_command', methods=['POST'])
def execute_command():
    command = request.form.get('command')
    try:
        output = subprocess.check_output(command, shell=True, text=True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        output = e.output
    return jsonify({'output': output})


@app.route('/comic_book')
def comic_book():
    return render_template('comic_book.html')

@app.route('/video_index')
def video_index():
    return render_template('video_index.html')


@app.route('/image_stuff')
def image_stuff():
    return render_template('image_stuff.html')


UPLOAD_FOLDER = 'static/uploads'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


@app.route('/crop', methods=['GET', 'POST'])
def crop():
    image_path = None
    if request.method == 'POST' and 'image' in request.files:
        image = request.files['image']
        if image.filename != '':
            filename = secure_filename(image.filename)
            image_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            image.save(image_path)
    fvideo = findvideos()        
    return render_template('crop.html', image_path=image_path, video=fvideo)


@app.route('/crop_and_save', methods=['POST'])
def crop_and_save():
    image_path = request.form.get('image_path')
    x = int(request.form.get('x'))
    y = int(request.form.get('y'))
    width = int(request.form.get('width'))
    height = int(request.form.get('height'))

    try:
        image = Image.open(image_path)
        cropped_image = image.crop((x, y, x + width, y + height))
        cropped_image.save('static/cropped_image.jpg')
        return render_template('crop.html', image_path='static/cropped_image.jpg')
    except Exception as e:
        return f"Error: {str(e)}"


def move_cropped_image():
    source_path = 'static/cropped_image.jpg'

    if not os.path.exists(source_path):
        return "Source file does not exist", 404

    destination_folder = 'static/images/Leonardo'
    image_ = f'cropped_{str(uuid.uuid4())}.jpg'

    try:
        os.makedirs(destination_folder, exist_ok=True)
    except OSError as e:
        return f"Failed to create destination folder: {e}", 500

    destination_path = os.path.join(destination_folder, image_)

    try:
        shutil.move(source_path, destination_path)
    except FileNotFoundError:
        return "Source file does not exist", 404
    except shutil.Error as e:
        return f"Error occurred while moving the file: {e}", 500
    return destination_path


@app.route('/move_cropped', methods=['GET', 'POST'])
def move_cropped():
    if request.method == 'POST':
        destination_path = move_cropped_image()
        source_path = 'static/cropped_image.jpg'
        fvideo = findvideos()
        return render_template('move_cropped.html', mv_img=destination_path, video=fvideo)
    else:
        return "Method not allowed", 405


@app.route('/edit_images_video')
def edit_images_video():
    fvideo = findvideos()
    return render_template('edit_images_video.html', video=fvideo)


@app.route('/mp3_player')
def mp3_player():
    mp3_files = [file for file in os.listdir('static/music') if file.endswith('.mp3')]
    return render_template('mp3_player.html', mp3_files=mp3_files)


@app.route('/NOTES')
def plain_html():
    return render_template('NOTES.html')


@app.route('/edit_script', methods=['GET', 'POST'])
def edit_script():
    logger.info('Edit script page accessed')
    script_dir = "static/scripts/"
    script_files = []
    for filename in os.listdir(script_dir):
        if filename.endswith('.js'):
            script_files.append(filename)

    if request.method == 'POST':
        selected_file = request.form['script_file']
        if selected_file.endswith('.js'):
            selected_file_path = os.path.join(script_dir, selected_file)
            shutil.copy(selected_file_path, script_file)
            with open(selected_file_path, 'r') as file:
                script_content = file.read()
            logger.info(f'Selected script file: {selected_file}')
            return render_template('edit_script.html', script_files=script_files, script_content=script_content)

    logger.info('No script file selected')
    return render_template('edit_script.html', script_files=script_files)


@app.route('/save_script', methods=['POST'])
def save_script():
    logger.info('Save script request received')
    # Retrieve the updated script content from the form data
    updated_script = request.form.get('script_content')
    # Write the updated script content to the file
    with open(script_file, 'w') as file:
        file.write(updated_script)
        # Log the updated script content
        logger.info(f'Updated script:\n{updated_script}')
        logger.info(f'Updated script_file:\n{script_file}')
    return render_template('index.html')


@app.route('/edit_canvas_script', methods=['GET', 'POST'])
def edit_canvas_script():
    logger.info('Edit canvas script page accessed')
    script_dir = "static/scripts/"
    script_files = []

    # Retrieve the list of script files regardless of the request method
    for filename in os.listdir(script_dir):
        if filename.endswith('canvas.js'):
            script_files.append(filename)
        logger.info("XXXXXXXXXXX:", script_files)
    if request.method == 'POST':
        selected_file = request.form['script_file']
        if selected_file.endswith('canvas.js'):
            selected_file_path = os.path.join(script_dir, selected_file)

            # Debugging: Print selected_file and selected_file_path
            logger.info(f"selected_file: {selected_file}")
            logger.info(f"selected_file_path: {selected_file_path}")

            shutil.copy(selected_file_path, script_file)
            with open(selected_file_path, 'r') as file:
                script_content = file.read()
            logger.info(f'=====Selected script file: {selected_file}')
            logger.info(f'=====Selected script content: {script_content}')
            return render_template('edit_canvas_script.html', script_files=script_files, script_content=script_content)       

        logger.info('XXXXXXX-No script file selected')

    return render_template('edit_canvas_script.html', script_files=script_files)


@app.route('/save_canvas_script', methods=['POST', 'GET'])
def save_canvas_script():
    logger.info('Save script request received')
    # Retrieve the updated script content from the form data
    updated_script = request.form.get('script_content')

    # Retrieve the script file name from the form data
    script_file = request.form.get('script_file')

    if script_file is not None:
        script_path = os.path.join("static/scripts/", script_file)

        # Write the updated script content to the file
        with open(script_path, 'w') as file:
            file.write(updated_script)
            # Log the updated script content
            logger.info(f'Updated script:\n{updated_script}')

    return render_template('save_canvas_script.html', script_file=script_file)


@app.route('/preview', methods=['GET', 'POST'])
def preview():
    logger.info('Preview page accessed')
    script_file = 'static/scripts/script.js'  # Path to the script file

    # Check if the script file exists
    if os.path.isfile(script_file):
        logger.info(f'Script file found: {script_file}')
        # Read the content of the script file
        with open(script_file, 'r') as file:
            script_content = file.read()
            logger.info(f'Script content:\n{script_content}')
    else:
        logger.warning('No script file found')
        script_content = 'No script file found'

    # HTML content to be displayed
    html_content = "<p>This is a dynamic HTML content. It can include various elements, <br />such as paragraphs, headings, lists, etc.</p>"
    
    
@app.route('/preview_two_canvass', methods=['GET', 'POST'])
def preview_two_canvass():
    logger.info('Preview page accessed')
    script_file = 'static/scripts/two_canvas.js'  # Path to the script file

    # Check if the script file exists
    if os.path.isfile(script_file):
        logger.info(f'Script file found: {script_file}')
        # Read the content of the script file
        with open(script_file, 'r') as file:
            script_content = file.read()
            logger.info(f'Script content:\n{script_content}')
    else:
        logger.warning('No script file found')
        script_content = 'No script file found'

    # HTML content to be displayed
    html_content = "<p>This is a dynamic HTML content. It can include various elements, <br />such as paragraphs, headings, lists, etc.</p>"

    return render_template('two_canvas.html', html_content=html_content, script_content=script_content)


@app.route('/capture_video')
def capture_video():
    now = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    video_filename = f'static/captured_video_{now}.mp4'
    
    command = f"sleep 5 && ffmpeg -f x11grab -framerate 24 -video_size 1366x760 -i :0.0 -f alsa -i plughw:0,0 -f pulse -i default -filter_complex '[1:a]volume=0.1[headset_audio];[2:a]volume=1[system_audio];[headset_audio][system_audio]amix=inputs=2[a]' -map 0:v -map '[a]' -c:v libx264 -r 24 -g 48 -c:a aac -b:a 128k -t 58 {video_filename}"
    
    # command = f'ffmpeg -f x11grab -framerate 24 -video_size 1366x760 -i :0.0 -f alsa -i plughw:0,0 -f pulse -i default -filter_complex "[1:a]volume=0.1[headset_audio];[2:a]volume=1[system_audio];[headset_audio][system_audio]amix=inputs=2[a],[0:v]scale=512x666[aout]" -map "[aout]" -map "[a]" -c:v libx264 -r 24 -g 48 -c:a aac -b:a 128k -t 58 -y {video_filename}'
     
    logger.info(f'Command: {command}')  # Additional informational log  
    try:
        subprocess.run(command, shell=True, check=True, capture_output=True)
        shutil.copy(video_filename, 'static/LIVE2.mp4')
        return "Video captured successfully"
    except subprocess.CalledProcessError as e:
        return f"Error capturing video: {str(e)}"

    
@app.route('/capture_square')
def capture_square():
    now = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    videos_filename = f'static/captured_square_{now}.mp4'
    
    command2 = (f'sleep 5 && ffmpeg -f x11grab -framerate 24 -video_size 580x580 -i :0+374,170 -f alsa -i plughw:0,0 -f pulse -i default -filter_complex "[1:a]volume=0.1[headset_audio];[2:a]volume=1[system_audio];[headset_audio][system_audio]amix=inputs=2[a],[0:v]scale=512x666[aout]" -map "[aout]" -map "[a]" -c:v libx264 -r 24 -g 48 -c:a aac -b:a 128k -t 58 -y {videos_filename}'
)
    
    logger.info(f'Command: {command2}')  # Additional informational log  
    try:
        subprocess.run(command2, shell=True, check=True, capture_output=True)
        shutil.copy(videos_filename, 'static/square2.mp4')
        return "Video captured successfully"
    except subprocess.CalledProcessError as e:
        return f"Error capturing video: {str(e)}"   

    
@app.route('/misc_links')
def misc_links():
        return render_template('misc_links.html')  


@app.route('/search_chat')
def search_chat():
    # Load the conversations JSON file
    with open('static/chat/conversations.json', 'r') as f:
        conversations = json.load(f)
    
    # Get the search query from the request parameters
    query = request.args.get('q')

    # Search the conversations for the query and collect results
    results = []
    for conversation in conversations:
        if 'messages' in conversation:
            for message in conversation['messages']:
                if 'content' in message and query.lower() in message['content'].lower():
                    results.append(message)

    # Render the search results in the template
    return render_template('search_chat.html', output=results)  # Pass 'results' instead of 'output'


@app.route('/canvas')
def canvas():
        return render_template('canvas.html') 

      
@app.route('/index_canvas')
def index_canvas():
        fvideo = findvideos()
        return render_template('index_canvas.html', video=fvideo)   


@app.route('/one_canvas')
def one_canvas():
        return render_template('one_canvas.html')  

    
@app.route('/two_canvas')
def two_canvas():
        return render_template('two_canvas.html') 

      
@app.route('/processing_text')
def processing_text():
    fvideo = findvideos()
    return render_template('processing_text.html', video=fvideo)


@app.route('/image_video')
def image_video():
        fvideo = findvideos()
        return render_template('image_video.html', video=fvideo)   


@app.route('/kaleidoscope')
def kaleidoscope():
        fvideo = findvideos()
        return render_template('kaleidoscope.html', video=fvideo)  


sys.path.append('/home/jack/hidden')
#from YouTube_key import YouTube_key
#key = YouTube_key()


# Your YouTube Live Streaming key
@app.route('/start_stream')
def start_stream():
    print("slaeeping 10 seconds")
    sleep(10)
    key = ""
    try:
        # Construct the FFmpeg command
        ffmpeg_command = [
            "ffmpeg",
            "-f", "pulse",
            "-ac", "2",
            "-i", "default",
            "-f", "x11grab",
            "-framerate", "24",
            "-video_size", "1366x760",
            "-i", ":0.0",
            "-c:v", "libx264",
            "-preset", "ultrafast",
            "-pix_fmt", "yuv420p",
            "-c:a", "aac",
            "-f", "flv",
            f"rtmp://a.rtmp.youtube.com/live2/{key}"
        ]

        # Execute the FFmpeg command in the background
        subprocess.Popen(ffmpeg_command, stderr=subprocess.PIPE, stdout=subprocess.PIPE)

        return "Streaming started. Check your YouTube Live Dashboard."
    except Exception as e:
        return f"Error: {str(e)}"


canvas_dir = 'static/canvas'
original_canvas_dir = os.path.join(canvas_dir, 'original')
os.makedirs(original_canvas_dir, exist_ok=True)


def load_original_canvas_file(filename):
    original_file_path = os.path.join(canvas_dir, filename)
    with open(original_file_path, 'r') as file:
        logger.debug("original_file_path:", original_file_path)
        return file.read()


# Function to save the original canvas file with a timestamp
def save_original_canvas_file(filename, content):
    now = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    new_filename = f"{filename}_{now}canvas.js"
    new_file_path = os.path.join(original_canvas_dir, new_filename)
    with open(new_file_path, 'w') as file:
        file.write(content)


# Function to edit and save the canvas file
def edit_and_save_canvas_file(filename, content):
    save_original_canvas_file(filename, content)
    logger.debug("filename:", filename)
    logger.debug("content:", content)
    edited_file_path = os.path.join(canvas_dir, filename)
    with open(edited_file_path, 'w') as file:
        file.write(content)


@app.route('/edit_canvas')
def edit_canvas():
    filenames = [f for f in os.listdir(canvas_dir) if f.endswith('canvas.js')]
    filenames = sorted(filenames)
    logger.debug("FILENAMES:", filenames)
    fvideo = findvideos()  # Assuming findvideos() is defined elsewhere
    fvideo = "static/assets/How_to_Edit_an_HTML_Page_With_FlaskAppArchitect_Editing_Error.mp4"
    logger.debug("FVIDEO:", fvideo)
    return render_template('edit_canvas.html', filenames=filenames, video=fvideo)


@app.route('/edit_canvas_page')
def edit_canvas_page():
    selected_filename = request.args.get('filename')
    logger.debug("selected_filename:", selected_filename)
    original_content = load_original_canvas_file(selected_filename)
    logger.debug("original_content:", original_content)
    return render_template('edit_canvas_page.html', selected_filename=selected_filename, original_content=original_content)


@app.route('/edit_canvas_save', methods=['POST'])
def edit_canvas_save():
    edited_content = request.form['edited_content']
    selected_filename = request.form['filename']
    edit_and_save_canvas_file(selected_filename, edited_content)
    return redirect(url_for('edit_canvas'))


def get_an_image():
    # image_dir =random.choice(glob.glob("/home/jack/Desktop/FlaskAppArchitect_Flask_App_Creator/static/images/*"))
    image_dir = glob.glob("static/images/*")
    # images = glob.glob(image_dir)
    image_dir = sorted(image_dir)
    return image_dir


def list_image_directories():
    image_directories = get_an_image()
    return image_directories


@app.route('/fade_index')
def fade_index():
    # List available image directories
    image_directories = list_image_directories()
    logger.debug("LINE 56: ", image_directories)
    video = 'assets/framed_final_output.mp4'
    video2 = 'assets/final_output.mp4'
    return render_template('fade_index.html', image_directories=image_directories, video=video, video2=video2)


def get_an_mp3():
    mp3s = random.choice(glob.glob("static/MUSIC/*.mp3"))
    return mp3s


@app.route('/generate_videoz', methods=['POST', 'GET'])
def generate_videoz():
    try:
        selected_directory = request.form['selected_directory']

        if not selected_directory:
            return redirect(url_for('fade_index'))

        # List all image files in the selected directory
        image_files = []
        logger.debug("selected_directory: ", selected_directory)
        for root, dirs, files in os.walk(selected_directory):
            for file in files:
                if file.lower().endswith(('.png', '.jpg', '.jpeg', '.gif')):
                    image_files.append(os.path.join(root, file))

        if not image_files:
            outV = 'assets/output.mp4'
            return render_template('fade_index.html', video=outV)

        # Shuffle the image files to mix them randomly
        random.shuffle(image_files)

        # Create a temporary directory to store the resized images
        temp_dir = 'temp/'
        os.makedirs(temp_dir, exist_ok=True)

        # Load and resize the images
        resized_images = []
        for image_file in image_files:
            im = Image.open(image_file)
            SIZE = im.size

            img = cv2.imread(image_file)
            img = cv2.resize(img, SIZE)  # Resize to the same size as the original image
            resized_images.append(img)

        # Create a video writer
        out_path = 'static/assets/output.mp4'
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')  # You may need to change the codec depending on your system
        out = cv2.VideoWriter(out_path, fourcc, 30, SIZE)

        # Keep track of video duration
        video_duration = 0

        # Create the video with fading transitions
        for i in range(len(resized_images)):
            if video_duration >= 58:  # Limit video to 58 seconds
                break

            img1 = resized_images[i]
            img2 = resized_images[(i + 1) % len(resized_images)]  # Wrap around to the first image
            # changing the alpha step size will change the duration of the fade effect
            step_size = 5
            for alpha in range(0, 150):  # Gradually change alpha from 0 to 100 for fade effect
                alpha /= 150.0
                blended = cv2.addWeighted(img1, 1 - alpha, img2, alpha, 0)
                out.write(blended)
                video_duration += 1 / 30  # Assuming 30 FPS

        out.release()

        # Prepare an audio clip of the same duration (58 seconds)
        audio_clip = AudioFileClip(get_an_mp3())  # Replace with your audio file path
        audio_clip = audio_clip.subclip(0, 58)  # Limit audio to 58 seconds
        # Load the video clip
        video_clip = VideoFileClip(out_path)

        # Set the audio of the video clip
        video_clip = video_clip.set_audio(audio_clip)

        # Save the final video with music
        final_output_path = 'static/assets/final_output.mp4'
        uid = str(uuid.uuid4())  # Generate a unique ID using uuid
        mp4_file = os.path.join("static", "assets", f"{uid}.mp4")
        
        video_clip.write_videofile(final_output_path, codec='libx264')
        shutil.copyfile(final_output_path, mp4_file) 
        # return render_template('fade_index.html', video='assets/final_output.mp4',video2='assets/framed_final_output.mp4')
        return redirect(url_for('frame_final_output'))

    except Exception as e:
        # Handle any exceptions
        return "An error occurred. Please check the logs for details."

    
@app.route('/frame_final_output')
def frame_final_output():
    logger.debug("WE MADE IT HERE !")
    try:
        # Load the final output video
        final_output_path = 'static/assets/final_output.mp4'
        final_video_clip = VideoFileClip(final_output_path)
        logger.debug(final_video_clip.size)

        # Load the PNG overlay frame
        overlay_frame_path = 'static/overlay/frame.png'  # Replace with the actual path to your overlay frame
        overlay_frame = ImageClip(overlay_frame_path)  # Load the overlay frame as an image

        # Resize the overlay frame to match the video's dimensions
        overlay_frame = overlay_frame.resize(final_video_clip.size)
        logger.debug("FRAME SIZE: ", overlay_frame.size)

        # Create a list of overlay frames with the desired duration
        overlay_frames = [overlay_frame.set_duration(58)]

        # Concatenate the overlay frames to match the final video's duration
        overlay = concatenate_videoclips(overlay_frames, method="compose")

        # Composite the overlay onto the final video
        final_video_with_overlay = CompositeVideoClip([final_video_clip.set_duration(58), overlay])
        uid = str(uuid.uuid4())  # Generate a unique ID using uuid
        frame_file = os.path.join("static", "assets", f"{uid}framed.mp4")
        # Write the video with the overlay to a new file
        framed_final_output_path = 'static/assets/framed_final_output.mp4'
        final_video_with_overlay.write_videofile(framed_final_output_path, codec='libx264')
        shutil.copyfile(framed_final_output_path, frame_file) 
        return render_template('fade_index.html', video='assets/final_output.mp4', video2='assets/framed_final_output.mp4')

    except Exception as e:
        # Handle any exceptions
        logger.debug("Exception: ", e)
        return "An error occurred. Please check the logs for details."


@app.route('/large_script')
def large_script():
    return render_template('large_script.html')


@app.route('/java_script')
def java_script():
    return render_template('java_script.html')
@app.route('/upload_file_rename', methods=['POST', 'GET'])
def upload_file_rename():
    try:
        # Get the uploaded file
        uploaded_file = request.files['file']

        # Check if a file was selected
        if uploaded_file.filename == '':
            return jsonify({"error": "No file selected."})

        # Get the new filename (you can customize this logic)
        new_filename = request.form.get('new_filename')
        if not new_filename:
            return jsonify({"error": "New filename not provided."})

        # Get the selected directory
        selected_directory = 'static/images/Leonardo'
        #selected_directory = request.form.get('selected_directory')
        if not selected_directory:
            return jsonify({"error": "Selected directory not provided."})

        # Ensure the selected directory exists
        if not os.path.exists(selected_directory):
            return jsonify({"error": "Selected directory does not exist."})

        # Save the file to the selected directory with the new filename
        file_path = os.path.join(selected_directory, new_filename)
        uploaded_file.save(file_path)

        # Log the operation
        logging.info(f"File '{uploaded_file.filename}' was renamed to '{new_filename}' and moved to '{selected_directory}'")

        return jsonify({"message": "File uploaded, renamed, and moved successfully."})

    except Exception as e:
        # Log any errors
        logging.error(str(e))
        return jsonify({"error": "An error occurred."})
    
@app.route('/uploadrename_fileform', methods=['GET'])
def uploadrename_fileform():
    return render_template('uploadrename_fileform.html')

@app.route('/upload_file_renamed', methods=['POST'])
def upload_file_renamed():
    # Handle the file upload and renaming here
    # You can access the form data using request.form and request.files

    return "File uploaded, renamed, and moved successfully."
@app.route('/archive_video', methods=['POST'])
def archive_video():
    #directory_path = "/home/jack/Desktop/FlaskAppArchitect_Flask_App_Creator/static/uploads/"
    directory_path = "static/uploads/"
    try:
        # Get the directory path from the request
        directory_path = request.form.get('directory_path')

        if not directory_path:
            logging.error('Directory path is missing in the request.')
            return jsonify({'error': 'Directory path is required'}), 400

        if not os.path.isdir(directory_path):
            logging.error('Invalid directory path provided.')
            return jsonify({'error': 'Invalid directory path'}), 400

        # Get a list of image files in the directory
        image_files = [file for file in os.listdir(directory_path) if file.lower().endswith(('.jpg', '.jpeg', '.png', '.gif'))]

        if not image_files:
            logging.error('No image files found in the directory.')
            return jsonify({'error': 'No image files found'}), 400

        # Sort the image files alphabetically
        image_files.sort()

        # Create a list of file paths for the images
        image_paths = [os.path.join(directory_path, file) for file in image_files]

        # Create a video from the images
        video = ImageSequenceClip(image_paths, fps=1)

        # Define the output video file path
        output_path = os.path.join(directory_path, 'ARCHIVE_output_video.mp4')

        # Write the video to the output file
        video.write_videofile(output_path, codec='libx264', fps=1, threads=4)

        logging.info('Video successfully generated.')
        return jsonify({'message': 'Video successfully generated', 'video_path': output_path}), 200

    except Exception as e:
        logging.error(f'Error occurred: {str(e)}')
        return jsonify({'error': 'An error occurred'}), 500

@app.route('/capture_and_overlay', methods=['POST','GET'])
def capture_and_overlay():
    try:
        # Get the current date and time
        datename = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

        # Specify the filename extension (change to your desired extension)
        extension = ".mp4"

        # Specify the directory where you want to save the captured videos
        capture_directory = 'static/captured_videos'

        # Create the directory if it doesn't exist
        os.makedirs(capture_directory, exist_ok=True)

        # Combine the datename and extension to form the full filename
        filename = os.path.join(capture_directory, f"{datename}{extension}")

        # Capture screen
        capture_command = (
            f"ffmpeg -f x11grab -framerate 24 -video_size 480x600 -i :0.0+7,80 "
            f"-f alsa -i pulse -c:v libx264 -c:a aac -b:a 128k -t 58 -y {filename}"
        )
        os.system(capture_command)

        # Overlay videos
        overlay_command = (
            f"ffmpeg -i static/assets/background.mp4 -i {filename} "
            f"-filter_complex '[1:v]scale=380:500[ovrl];[0:v][ovrl]overlay=W-w-65:H-h-200[out]' "
            f"-map '[out]' -map 1:a -c:v libx264 -crf 18 -c:a aac -strict -2 -t 58 -y shortoverlayed_filename.mp4"
        )
        os.system(overlay_command)

        # Verify sound
        verification_command = (
            f"ffmpeg -i shortoverlayed_filename.mp4 -c:v copy -c:a aac -strict -2 -y shortverification_{filename}"
        )
        os.system(verification_command)

        return jsonify({'message': 'Video processing complete', 'filename': filename})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/fish_kiss')
def fish_kiss():
    return render_template('fish_kiss.html')

@app.route('/links')
def links():
    return render_template('links.html')

@app.route("/capture_html_page", methods=["GET", "POST"])
def capture_html_page():
    if request.method == "POST":
        # Get the URL from the form input field
        url = request.form.get("url")

        # Initialize a headless Chrome browser
        options = webdriver.ChromeOptions()
        options.add_argument("--headless")  # Run Chrome in headless mode (no GUI)
        driver = webdriver.Chrome(options=options)

        # Navigate to the specified webpage
        driver.get(url)

        # Capture a screenshot of the webpage
        screenshot = driver.get_screenshot_as_png()

        # Close the browser
        driver.quit()

        # Return the screenshot as a response with the appropriate content type
        return Response(screenshot, content_type="image/png")

    # If the request method is GET, render the HTML template with the form
    return render_template("show_capture.html", image_url="")

@app.route('/run_falkon', methods=['GET'])
def run_falkon():
    # Specify the path to your Bash script
    bash_script_path = 'FalkonShort'

    # Execute the Bash script
    subprocess.run(['bash', bash_script_path])
    return "Bash script executed successfully."
@app.route('/add_files', methods=['GET', 'POST'])
def add_files():
    if request.method == 'POST':
        mp4_file = request.files['mp4_file']

        if mp4_file and mp4_file.filename.endswith('.mp4'):
            # Define the directory where you want to save the images
            image_dir = 'static/images/mp4_images'

            # Create the image directory if it doesn't exist
            os.makedirs(image_dir, exist_ok=True)

            # Path to the uploaded MP4 file
            mp4_path = os.path.join(image_dir, mp4_file.filename)

            # Save the MP4 file
            mp4_file.save(mp4_path)

            # Initialize OpenCV VideoCapture
            cap = cv2.VideoCapture(mp4_path)
            frame_count = 0

            while True:
                # Read a frame from the video
                ret, frame = cap.read()
                if not ret:
                    break

                # Define the path to save the image
                image_path = os.path.join(image_dir, f'frame_{frame_count:04d}.jpg')

                # Save the frame as an image
                cv2.imwrite(image_path, frame)

                frame_count += 1

            # Release the VideoCapture and clean up
            cap.release()
            cv2.destroyAllWindows()

    return render_template('add_files.html')


@app.route('/delete_files', methods=['GET', 'POST'])
def delete_files():
    if request.method == 'POST':
        # Delete all files in the image directory
        image_dir = 'static/images/mp4_images'
        for file_name in os.listdir(image_dir):
            file_path = os.path.join(image_dir, file_name)
            try:
                if os.path.isfile(file_path):
                    os.remove(file_path)
            except Exception as e:
                pass

    return render_template('delete_files.html')


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


if __name__ == '__main__':
    create_databaseD()  # Create the database and table before starting the app
    app.run(debug=True, host='0.0.0.0', port=5200)
