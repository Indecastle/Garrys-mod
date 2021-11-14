#!/usr/bin/python3.8

"""
	
	Dependencies:
		pydub
	
	TODO:
		make command line help
	
"""

from pydub import AudioSegment
import os

audio = AudioSegment.empty()
data = "{"

if not os.path.exists("./audio"):
	quit("audio folder not found")

for name in os.listdir("./audio"):
	print("adding " + name)
	segment = AudioSegment.from_file("./audio/" + name)
	data += "\n\t[\"" + os.path.splitext(name)[0] + "\"] = {\n\t\tstart = " + str(len(audio)) + ",\n\t\tlength = " + str(len(segment)) + "\n\t},"
	audio += segment + AudioSegment.silent(duration = 100)

file_handle = audio.export("audio.mp3", format = "mp3")

with open("./audio.lua", "w") as file:
	file.write(data + "\n}")