--@name svg test
--@client
--@include ../lib/format/svg.lua

local svg = require("../lib/format/svg.lua")

hook.add("render", "", function()
	render.setRGBA(100, 100, 100, 255)
	render.drawRect(256, 0, 256, 256)
	render.drawRect(0, 256, 256, 256)
	
	svg.drawSVGRaw(0, 0, 256, 256, [[<?xml version="1.0" encoding="UTF-8" ?>
	<svg width="391" height="391" viewBox="0 0 250 250" xmlns="http://www.w3.org/2000/svg">
		<rect x="25" y="25" width="200" height="200" fill="lime" stroke-width="4" stroke="pink" />
		<circle cx="125" cy="125" r="75" fill="orange" />
		<polyline points="50,150 50,200 200,200 200,100" stroke="red" stroke-width="4" fill="none" />
		<line x1="50" y1="50" x2="200" y2="200" stroke="blue" stroke-width="4" />
	</svg>]])
	
	render.setColor(Color((timer.curtime() * 50) % 360, 1, 1):hsvToRGB())
	svg.drawSVGRaw(256, 0, 256, 256, [[<svg aria-hidden="true" focusable="false" data-prefix="fas" data-icon="edit" class="svg-inline--fa fa-edit fa-w-18" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 576 512"><path fill="currentcolor" d="
	M402.6 83.2l90.2 90.2c3.8 3.8 3.8 10 0 13.8L274.4 405.6l-92.8 10.3c-12.4 1.4-22.9-9.1-21.5-21.5l10.3-92.8L388.8 83.2c3.8-3.8 10-3.8 13.8 0z
	m162-22.9l-48.8-48.8c-15.2-15.2-39.9-15.2-55.2 0l-35.4 35.4c-3.8 3.8-3.8 10 0 13.8l90.2 90.2c3.8 3.8 10 3.8 13.8 0l35.4-35.4c15.2-15.3 15.2-40 0-55.2z
	M384 346.2V448H64V128h229.8c3.2 0 6.2-1.3 8.5-3.5l40-40c7.6-7.6 2.2-20.5-8.5-20.5H48C21.5 64 0 85.5 0 112v352c0 26.5 21.5 48 48 48h352c26.5 0 48-21.5 48-48V306.2c0-10.7-12.9-16-20.5-8.5l-40 40c-2.2 2.3-3.5 5.3-3.5 8.5z
	"></path></svg>]])
	
	svg.drawSVGRaw(0, 256, 256, 256, [[<svg aria-hidden="true" focusable="false" data-prefix="fab" data-icon="centos" class="svg-inline--fa fa-centos fa-w-14" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><path fill="currentColor" d="
	M289.6 97.5l31.6 31.7-76.3 76.5V97.5z
	m-162.4 31.7l76.3 76.5V97.5h-44.7z
	m41.5-41.6h44.7v127.9l10.8 10.8 10.8-10.8V87.6h44.7L224.2 32z
	m26.2 168.1l-10.8-10.8H55.5v-44.8L0 255.7l55.5 55.6v-44.8h128.6l10.8-10.8z
	m79.3-20.7h107.9v-44.8l-31.6-31.7z
	m173.3 20.7L392 200.1v44.8H264.3l-10.8 10.8 10.8 10.8H392v44.8l55.5-55.6z
	M65.4 176.2l32.5-31.7 90.3 90.5h15.3v-15.3l-90.3-90.5 31.6-31.7H65.4z
	m316.7-78.7h-78.5l31.6 31.7-90.3 90.5V235h15.3l90.3-90.5 31.6 31.7z
	M203.5 413.9V305.8l-76.3 76.5 31.6 31.7h44.7z
	M65.4 235h108.8l-76.3-76.5-32.5 31.7z
	m316.7 100.2l-31.6 31.7-90.3-90.5h-15.3v15.3l90.3 90.5-31.6 31.7h78.5z
	m0-58.8H274.2l76.3 76.5 31.6-31.7z
	m-60.9 105.8l-76.3-76.5v108.1h44.7z
	M97.9 352.9l76.3-76.5H65.4v44.8z
	m181.8 70.9H235V295.9l-10.8-10.8-10.8 10.8v127.9h-44.7l55.5 55.6z
	m-166.5-41.6l90.3-90.5v-15.3h-15.3l-90.3 90.5-32.5-31.7v78.7h79.4z
	"></path></svg>]])
	
	svg.drawSVGRaw(256, 256, 256, 256, [[<svg aria-hidden="true" focusable="false" data-prefix="fas" data-icon="folder-open" class="svg-inline--fa fa-folder-open fa-w-18" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 576 512"><path fill="currentColor" d="
	M572.694 292.093L500.27 416.248A63.997 63.997 0 0 1 444.989 448H45.025c-18.523 0-30.064-20.093-20.731-36.093l72.424-124.155A64 64 0 0 1 152 256h399.964c18.523 0 30.064 20.093 20.73 36.093z
	M152 224h328v-48c0-26.51-21.49-48-48-48H272l-64-64H48C21.49 64 0 85.49 0 112v278.046l69.077-118.418C86.214 242.25 117.989 224 152 224z
	"></path></svg>]])
	
end)