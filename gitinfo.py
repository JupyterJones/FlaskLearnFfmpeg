from PIL import Image
from PIL.ExifTags import TAGS
from sys import argv
image = Image.open(argv[1]) 
exif_data = image._getexif()

for tag, value in exif_data.items():
    tag_name = TAGS.get(tag, tag)
    # Check if the value is bytes and decode it to UTF-8 if so
    if isinstance(value, bytes):
        value = value.decode('utf-8', errors='replace')
    print(f"{tag_name}: {value}")
