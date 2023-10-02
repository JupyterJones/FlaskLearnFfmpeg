from moviepy.editor import *
import os

# Path to the directory containing images
image_dir = 'static/images/gothic_lolita'

# Get a list of image files in the directory
image_files = [f for f in os.listdir(image_dir) if f.endswith('.jpg')]

# Sort image files based on their filenames
image_files.sort()

# Initialize the video
video = VideoFileClip('static/output/video.mp4')

# Set the duration for each image in seconds (adjust as needed)
image_duration = 5

# Initialize the final video with the first image
final_video = ImageClip(os.path.join(image_dir, image_files[0]), duration=image_duration)

# Iterate through the remaining images
for i in range(1, len(image_files)):
    # Load the current image
    current_image = ImageClip(os.path.join(image_dir, image_files[i]), duration=image_duration)

    # Zoom and pan transition between the current and previous images
    zoom_factor = 1.1  # Adjust the zoom factor as needed
    zoomed_image = current_image.zoom(zoom_factor)
    pan_duration = 1  # Adjust the pan duration as needed
    zoomed_and_panned = zoomed_image.pan(rel_x=0.5, rel_y=0.5, duration=pan_duration)

    # Concatenate the transitioned image to the final video
    final_video = concatenate_videoclips([final_video, zoomed_and_panned])

# Write the final video to an output file
final_video.write_videofile('static/output/video.mp4', codec='libx264', fps=24)
