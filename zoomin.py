#!/home/jack/Desktop/FlaskAppArchitect_Flask_App_Creator/env/bin/python3
from flask import request, render_template, redirect, url_for, flash,Blueprint
import os
import subprocess
import uuid
import shutil
import glob
import logging
from logging.handlers import RotatingFileHandler
zoomin_bp = Blueprint('zoomin', __name__)

# Create a logger object
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

# Create a formatter for the log messages
formatter = logging.Formatter(
    '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]')

# Create a file handler to write log messages to a file
file_handler = RotatingFileHandler(
    'Logs/zoom.log', maxBytes=10000, backupCount=1)
file_handler.setLevel(logging.DEBUG)
file_handler.setFormatter(formatter)

# Add the file handler to the logger
logger.addHandler(file_handler)

# Define a directory to store uploaded images
UPLOAD_FOLDER = 'static/temp_uploads'


# Allowed image extensions
ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'gif'}

# Function to check if a filename has an allowed extension
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Function to get a list of image directories
def get_image_directories():
    image_dir = glob.glob("static/images/*")
    image_dir = sorted(image_dir)
    return image_dir

# Route to display the upload form and select an image directory
@zoomin_bp.route('/upload_form', methods=['GET',])
def upload_form():
    # List available image directories
    image_directories = get_image_directories()
    image_directories = sorted(image_directories)
    logger.debug('Image directories: %s', image_directories)
    video2 = "static/output/generated_video.mp4"
    return render_template('dir_to_video.html', image_directories=image_directories, video2=video2) 
# Route to display the upload form and select an image directory
@zoomin_bp.route('/upload_zoom', methods=['GET',])
def upload_zoom():
    # List available image directories
    image_directories = get_image_directories()
    image_directories = sorted(image_directories)
    logger.debug('Image directories: %s', image_directories)
    video2 = "static/output/generated_video.mp4"
    return render_template('dir_to_zoom.html', image_directories=image_directories, video2=video2) 

# Route to handle image directory selection and video generation
@zoomin_bp.route('/image_dir_to_zoom', methods=['POST','GET'])
def image_dir_to_zoom():
    try:
        selected_directory = request.form.get('selected_directory')
        logger.debug('image_dir_to_zoom: %s', selected_directory)

        # List image files in the selected directory
        image_files = glob.glob(os.path.join(selected_directory, '*.jpg'))  # Modify the extension as needed
        logger.debug('Image files: %s', image_files)

        if not image_files:
            flash('No image files found in the selected directory.')
            return redirect(request.url)

        # Specify the output video file path
        output_video = os.path.join('static', 'output', 'generated_video.mp4')

        # Frame rate for the output video (adjust as needed)
        frame_rate = 4

        # Initialize the FFmpeg command
        
        #ffmpeg -framerate 4 -i static/images/yoda/%05d.jpg -vf "zoompan=z='min(zoom+0.005,1.5)':x='iw/2':y='ih/#2-400':d=35:s=512x768, crop=512:768:0:256" -c:v libx264 -pix_fmt yuv420p -y zoomout_yoda.mp4

        
        ffmpeg_cmd = [
            'ffmpeg',
            '-framerate', str(frame_rate),
            '-pattern_type', 'glob',
            '-i', os.path.join(selected_directory, '*.jpg'),
        ]
        logger.debug('ffmpeg_cmd: %s', ffmpeg_cmd)
        # Output video settings
        ffmpeg_cmd += [
            '-vf', 'zoompan=z=\'min(zoom+0.005,1.5)\':x=\'iw/2\':y=\'ih/2-400\':d=35:s=512x768,crop=512:768:0:256',
            '-c:v', 'libx264',
            '-pix_fmt', 'yuv420p',
            '-r', '20',
            '-y',  # Overwrite output file if it exists
            output_video,
        ]
        logger.debug('FINAL: ffmpeg_cmd: %s', ffmpeg_cmd)
        # Run the FFmpeg command to generate the video
        subprocess.run(ffmpeg_cmd)

        logger.debug('Video created: %s', output_video)
        shutil.copy(output_video, 'static/assets')
        # mp4 video name generated with uuid
        video_name = str(uuid.uuid4()) + 'framed.mp4'
        shutil.move('static/assets/generated_video.mp4', 'static/assets/' + video_name)
        return redirect(url_for('zoomin.download_video', filename='generated_video.mp4'))
    except Exception as e:
        logger.exception('Error occurred during image directory to video conversion: %s', str(e))
        return "An error occurred during image directory to video conversion."
    
    
# Route to handle image directory selection and video generation
@zoomin_bp.route('/image_dir_to_video', methods=['POST'])
def image_dir_to_video():
    try:
        selected_directory = request.form.get('selected_directory')
        logger.debug('Selected image directory: %s', selected_directory)

        # List image files in the selected directory
        image_files = glob.glob(os.path.join(selected_directory, '*.jpg'))  # Modify the extension as needed
        logger.debug('Image files: %s', image_files)

        if not image_files:
            flash('No image files found in the selected directory.')
            return redirect(request.url)

        # Specify the output video file path
        output_video = os.path.join('static', 'output', 'generated_video.mp4')

        # Frame rate for the output video (adjust as needed)
        frame_rate = 1

        # Initialize the FFmpeg command
        ffmpeg_cmd = [
            'ffmpeg',
            '-pattern_type', 'glob',
            '-framerate', str(frame_rate),
            '-i', os.path.join(selected_directory, '*.jpg'),
        ]

        # Output video settings
        ffmpeg_cmd += [
            '-c:v', 'libx264',
            '-pix_fmt', 'yuv420p',
            '-r', '20',
            '-y',  # Overwrite output file if it exists
            output_video,
        ]

        # Run the FFmpeg command to generate the video
        subprocess.run(ffmpeg_cmd)

        logger.debug('Video created: %s', output_video)
        shutil.copy(output_video, 'static/assets')
        # mp4 video name generated with uuid
        video_name = str(uuid.uuid4()) + 'framed.mp4'
        shutil.move('static/assets/generated_video.mp4', 'static/assets/' + video_name)
        return redirect(url_for('zoomin.download_video', filename='generated_video.mp4'))
    except Exception as e:
        logger.exception('Error occurred during image directory to video conversion: %s', str(e))
        return "An error occurred during image directory to video conversion."


# Route to download the generated video
@zoomin_bp.route('/download_video/<filename>')
def download_video(filename):
    return redirect(url_for('static', filename=f'output/{filename}'))

