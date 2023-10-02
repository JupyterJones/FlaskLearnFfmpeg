import os
import glob
import shutil
import tempfile
import subprocess
import datetime
from PIL import Image
from flask import Flask, request, render_template, redirect, url_for
from moviepy.editor import VideoFileClip, ImageClip, CompositeVideoClip
from moviepy.editor import concatenate_videoclips, AudioFileClip
from moviepy.video.io.ImageSequenceClip import ImageSequenceClip
import logging
from time import sleep
from random import randint
import random
import time
import uuid
import numpy as np
from logging.handlers import RotatingFileHandler
from zoomin import zoomin_bp
app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.DEBUG)
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

app.register_blueprint(zoomin_bp)


@app.route("/")
def index():
    return render_template("index.html")

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
            imagelist = sorted(glob.glob('animate/*.jpg'),
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

    return render_template('choosedirectory.html')

@app.route('/add_effects')
def add_effects():
    return '''
        <form method="post" action="/video" enctype="multipart/form-data">
            <label for="input_video">Select input video file:</label><br>
            <input type="file" id="input_video" name="input_video"><br><br>
            <input type="submit" value="Submit">
        </form>
    '''
@app.route('/video', methods=['POST', 'GET'])
def process_video():
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
  
    music = random.choice(glob.glob('static/MUSIC/*.mp3'))
    command3 = f"ffmpeg -i {DIR}alice/final5.mp4 -ss {init} -i {music} -af 'afade=in:st=0:d=4,afade=out:st=55:d=3' -map 0:0 -map 1:0 -shortest -y {DIR}alice/Final_End.mp4"
    subprocess.run(command3, shell=True)

    # Save the output video to a file
    now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    shutil.copy(f"{DIR}alice/output2.mp4", f"{DIR}alice/{now}_output.mp4")
    shutil.copy(f"{DIR}alice/Final_End.mp4", f"{DIR}alice/{now}_Final.mp4")
    shutil.copy(f"{DIR}alice/Final_End.mp4", f"{DIR}alice/Final_End_mix.mp4")
    return render_template('final.html', video_file="alice/Final_End.mp4")
@app.route('/videos', methods=['GET', 'POST'])
def process_videos():
    DIR = "static/"
    input_video = request.files['input_video']

    # Save the uploaded video to a file
    input_video.save(f"{DIR}input_video.mp4")

    # Run FFmpeg commands
    command1 = f"ffmpeg -nostdin -i {DIR}input_video.mp4 -filter:v \"minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=10'\" -c:v libx264 -r 20 -pix_fmt yuv420p -c:a copy -y {DIR}output.mp4"
    logger.info(f'my_video: f"{DIR}output.mp4"')
    logger.info('Command1:',command1)
    subprocess.run(command1, shell=True, stderr=subprocess.PIPE,
                   universal_newlines=True)

    command2 = f"ffmpeg -nostdin -i {DIR}output.mp4 -vf mpdecimate,setpts=N/FRAME_RATE/TB -c:v libx264 -r 30 -pix_fmt yuv420p -c:a copy -y {DIR}mpdecimate.mp4"
    logger.info(f'my_video: f"{DIR}mpdecimate.mp4"')
    logger.info('Command2:',command2)
    print(command2)
    subprocess.run(command2, shell=True, stderr=subprocess.PIPE,
                   universal_newlines=True)

    # DIR = "/home/jack/Desktop/ffmpeg_flask/"
    command3 = f"ffmpeg -i static/mpdecimate.mp4 -filter_complex \"[0:v]trim=duration=14,loop=500:1:0[v];[1:a]afade=t=in:st=0:d=1,afade=t=out:st=0.9:d=2[a1];[v][0:a][a1]concat=n=1:v=1:a=1\" -c:v libx264 -r 30 -pix_fmt yuv420p -c:a aac -b:a 192k -shortest -y static/output.mp4"
    subprocess.run(command3, shell=True, stderr=subprocess.PIPE,
                   universal_newlines=True)
    logger.info('Command3:',command3)
    print("command3: ",command3)
    now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    shutil.copy(f"{DIR}output.mp4", f"{DIR}{now}_output.mp4")
    logger.info(f'my_video: f"{DIR}mpdecimate.mp4"')
    video_file = "static/outputALL.mp4"
    command4 = f'ffmpeg -i "{DIR}mpdecimate.mp4" -i "{DIR}mpdecimate.mp4" -i "{DIR}mpdecimate.mp4" -i "{DIR}mpdecimate.mp4" -i "{DIR}mpdecimate.mp4" -filter_complex "[0:v]trim=duration=15[v0];[1:v]trim=duration=15[v1];[2:v]trim=duration=15[v2];[3:v]trim=duration=15[v3];[4:v]trim=duration=15[v4];[v0][v1][v2][v3][v4]concat=n=5:v=1:a=0" -c:v libx264 -pix_fmt yuv420p -shortest -y {video_file}'
    subprocess.run(command4, shell=True, stderr=subprocess.PIPE,
                   universal_newlines=True)
    now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    diR = f"{DIR}videos/"
    logger.info(f'diR: f"{diR}mpdecimate.mp4"')
    shutil.copy(f"{video_file}", f"{diR}{now}_outputALL.mp4")
    logger.info(f'diR: {diR}mpdecimate.mp4')
    return render_template('final.html', video_file=video_file)


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
@app.route('/upload_form')
def upload_form():
    return render_template('upload_form.html')
def create_mp4_from_images(images_list, output_file, fps):
    # Convert PIL Image objects to NumPy arrays
    image_arrays = [np.array(image) for image in images_list]

    # Create the video clip from the NumPy arrays
    clip = ImageSequenceClip(image_arrays, fps=fps)

    # Write the video to the output file
    clip.write_videofile(output_file, codec="libx264", fps=fps)



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
    logger.info(f'bg_file_path: {bg_file_path}')
    logger.info(f'fg_file_path: {fg_file_path}') 
    images_list = zoom_effect(bg_file_path, fg_file_path)

    output_mp4_file = 'static/overlay_zooms/imagez_video.mp4'
    frames_per_second = 30
    logger.info('create_mp4_from_images: ',images_list, output_mp4_file, frames_per_second)
    create_mp4_from_images(images_list, output_mp4_file, frames_per_second)

    # Clean up temporary files
    # os.remove(bg_filename)
    # os.remove(fg_filename)
    file_bytime = time.strftime("%Y%m%d-%H%M%S") + ".mp4"

    shutil.copy('static/overlay_zooms/imagez_video.mp4',
                'static/overlay_zooms/' + file_bytime)
    video_url = url_for('static', filename=output_mp4_file)
    return render_template('upload.html', video_url=video_url)


if __name__ == '__main__':
    print("Starting Python Flask Server For Ffmpeg \n Code Snippets on port 5200")
    app.run(debug=True, host='0.0.0.0', port=5100)