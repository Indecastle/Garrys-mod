#!/usr/bin/python3.8

"""
	
	Dependencies:
		python-pillow
		python-xlib (Linux only)
	
	
	TODO:
		Add Windows support
		Make grabbing window by class actually not shit
	
"""

# ------------------------------ #

import os, sys, time, math, requests, json
from threading import Timer
from PIL import Image
from io import BytesIO
from Xlib.display import Display
from Xlib import X

# ------------------------------ #

if len(sys.argv) < 5:
	quit("Usage: ./streamer window_class/id fps width height name=\"A Stream\" streamer_name=\"Anonymous\"")

win_class = sys.argv[1]
fps = int(sys.argv[2])
width = int(sys.argv[3])
height = int(sys.argv[4])
name = len(sys.argv) >= 6 and sys.argv[5] or "A Stream"
streamer_name = len(sys.argv) >= 7 and sys.argv[6] or "Anonymous"

url = "https://sevii.dev/api/streamer" # "http://localhost/api/streamer"
dis = Display()
root = dis.screen().root
win = None

# ------------------------------ #

if win_class[0] == "0":
	win = dis.create_resource_object("window", int(win_class, 16))
else:
	for w in root.query_tree().children:
		wclass = w.get_wm_class()
		
		if wclass != None and wclass[1].lower() == win_class:
			try:
				dis.create_resource_object("window", w.id + 2).get_image(0, 0, 1, 1, X.ZPixmap, 0xffffffff)
			except:
				pass
			else:
				win = dis.create_resource_object("window", w.id + 2)
				
				break

if not win:
	quit("No window found with class of " + sys.argv[1])

sheet_count = math.floor(1024 / width) * math.floor(1024 / height)
if sheet_count < fps:
	print("Warning: with current settings the sheetrate is %f sheets per second, this is not recommended" % (fps / sheet_count))

# ------------------------------ #

def capture_window():
	gem = win.get_geometry()
	raw = win.get_image(0, 0, gem.width, gem.height, X.ZPixmap, 0xffffffff)
	return Image.frombytes("RGB", (gem.width, gem.height), raw.data, "raw", "BGRX"), gem.width, gem.height

# ------------------------------ #

stream_key = None
def post(file):
	print(requests.post(url, {"stream_key": stream_key}, files = {"sheet": file.getvalue()}).content)

def capture_loop():
	next_cap = time.time()
	i = 0
	sheet = None
	
	while True:
		curtime = time.time()
		
		while curtime >= next_cap:
			next_cap += 1 / fps
			print("cap")
			if i == 0:
				if sheet != None:
					file = BytesIO()
					sheet.save(file, "PNG")
					
					Timer(0, post, [file]).start()
				
				sheet = Image.new("RGB", (1024, 1024), (0, 0, 0))
			
			cap, cap_w, cap_h = capture_window()
			ratio = min(width / cap_w, height / cap_h)
			cap = cap.resize((int(cap_w * ratio), int(cap_h * ratio)))
			sheet.paste(cap, ((i % int(1024 / width)) * width, int(math.floor(i / (1024 / width))) * height))
			
			i += 1
			if i >= sheet_count:
				i = 0

# ------------------------------ #

resp = requests.post(url).content
print(resp)
resp_json = json.loads(resp)

if not resp_json or "error" in resp_json:
	quit()

resp = requests.post(url, {
	"confirm_key": resp_json["confirm_key"],
	"fps": fps,
	"width": width,
	"height": height,
	"name": name,
	"streamer_name": streamer_name
}).content
print(resp)
resp_json = json.loads(resp)

if not resp_json or "error" in resp_json:
	quit()

stream_key = resp_json["stream_key"]

capture_loop()