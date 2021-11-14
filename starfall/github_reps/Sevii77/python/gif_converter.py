from PIL import Image
import math

sheet = Image.new("RGBA", (1024, 1024))
gif = Image.open("./gif.gif")



frames = gif.n_frames
w, h = 1024 * min(gif.width / gif.height, 1), 1024 * min(gif.height / gif.width, 1)
width, height = 0, 0
wc, hc = 0, 0

for i in range(1, 9999):
	width = math.floor(w / i)
	height = math.floor(h / i)
	
	wc = math.floor(1024 / width)
	hc = math.floor(1024 / height)
	
	if wc * hc >= frames:
		break

data = "{\n\txcount = %i,\n\tycount = %i,\n\twidth = %i,\n\theight = %i,\n\ttiming = {" % (wc, hc, width, height)



for index in range(frames):
	x = (index % wc) * width
	y = math.floor(index / wc) * height
	
	gif.seek(index)
	sheet.paste(gif.resize((width, height)), (x, y, x + width, y + height))
	
	data += str(gif.info["duration"] / 1000) + (index == frames - 1 and "}" or ", ")



sheet.save("./sheet.png", "PNG")

with open("./data.lua", "w") as file:
	file.write(data + "\n}")