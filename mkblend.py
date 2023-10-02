import os
import glob
import shutil
import tempfile
import subprocess
import datetime
from PIL import Image
from flask import Flask, request, render_template, redirect, url_for
import logging
from time import sleep
from random import randint
import random

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)


@app.route("/")
def index_a():
    return render_template('index.html')

@app.route("/mkblend_video", methods=['GET', 'POST'])
def mkblend_video():
    if request.method == 'POST':
        selected_directory = request.form.get('directory')  # Corrected name to 'directory'
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
                    shutil.copy(source_path, target_path)  # Use shutil.copy instead of os.rename
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
            # Rest of your code for image processing and video creation goes here...

            # Return a response or redirect to a success page
            return redirect(url_for('success_page'))  # Change 'success_page' to the name of your success page route

    return render_template('choose_directory.html')

@app.route('/add_effects')
def add_effects():
    return '''
        <form method="post" action="/video" enctype="multipart/form-data">
            <label for="input_video">Select input video file:</label><br>
            <input type="file" id="input_video" name="input_video"><br><br>
            <input type="submit" value="Submit">
        </form>
    '''
@app.route('/videos', methods=['POST', 'GET'])
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
  
    music = random.choice(glob.glob('static/MUSIC/*.mp3'))
    command3 = f"ffmpeg -i {DIR}alice/final5.mp4 -ss {init} -i {music} -af 'afade=in:st=0:d=4,afade=out:st=55:d=3' -map 0:0 -map 1:0 -shortest -y {DIR}alice/Final_End.mp4"
    subprocess.run(command3, shell=True)

    # Save the output video to a file
    now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    shutil.copy(f"{DIR}alice/output2.mp4", f"{DIR}alice/{now}_output.mp4")
    shutil.copy(f"{DIR}alice/Final_End.mp4", f"{DIR}alice/{now}_Final.mp4")
    shutil.copy(f"{DIR}alice/Final_End.mp4", f"{DIR}alice/Final_End_mix.mp4")
    return render_template('final.html', video_file="alice/Final_End.mp4")





if __name__ == '__main__':
    print("Starting Python Flask Server For Ffmpeg \n Code Snippets on port 5300")
    app.run(debug=True, host='0.0.0.0', port=5300)