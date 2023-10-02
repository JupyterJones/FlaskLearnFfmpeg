def convert_text_file(input_file, output_file):
    with open(input_file, 'r') as f_in, open(output_file, 'w') as f_out:
        for line in f_in:
            words = line.split()
            current_line = words[0]
            for word in words[1:]:
                if len(current_line) + len(word) + 1 <= 50:
                    current_line += ' ' + word
                else:
                    f_out.write(current_line + '\n')
                    current_line = word
            f_out.write(current_line + '\n')

# Example usage
#input_file = '/mnt/HDD500/MyTube_AI_Flask_App/Project_TheOrigin/RAW_Story_resources/That-sounds-like-an-intriguing-concept.text'
input_file = '/home/jack/Desktop/HDD500/FLASK/static/text/unformated_text.txt'
output_file = '/home/jack/Desktop/HDD500/FLASK/static/text/formated.txt'
convert_text_file(input_file, output_file)
