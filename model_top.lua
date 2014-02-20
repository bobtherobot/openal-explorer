
local retObj = {}

function retObj:makeArc(x,y,w,h,s,e, doPie)
	local xc,yc,xt,yt,cos,sin = x,y,0,0,math.cos,math.sin
	s,e = s or 0, e or 360
	s,e = math.rad(s),math.rad(e)
	w,h = w/2,h/2
	local l = display.newLine(0,0,0,0)
	if doPie == true then
		l:append(0, yc - sin(2))
	end
	--0.02
	for t=s,e,0.02 do l:append(xc + w*cos(t), yc - h*sin(t)) end
	if doPie == true then
		l:append(yc - sin(2), 0)
	end
	
	return l
end

function retObj:drawSlice(angle, color)
	--makeArc(x,y,w,h,s,e)
	local slice = retObj:makeArc(0,0,300,300,1,angle, true)

	--[[
	-- Converts to radians an angle given in degrees.
	-- print (math.rad(180))  ---->  3.1415926535898
	-- print (math.rad(1))    ---->  0.017453292519943
	local len = 100
	local halfAng = (angle-360)/2
	local rad = math.rad(halfAng)
	local rad1x = len*math.sin(rad)
	local rad1y = len*math.cos(rad)
	
	local rad2x = len*math.sin(-rad)
	local rad2y = len*math.cos(-rad)
	
	print("angle: " .. angle)
	print("halfAng: " .. halfAng)
	print("-")
	print("rad1x: " .. rad1x)
	print("rad1y: " .. rad1y)
	print("-----")
	
	-- display.newLine( [parent,] x1,y1, x2,y2 )
	local slice = display.newLine(rad1x,rad1y,0,0)
	slice:append(rad2x, rad2y)
	--]]
	
	slice.rotation = 270 + (angle / 2)
	
	if color == 1 then
		slice:setColor( 255, 0, 0, 70 )
		slice.width = 10
	else
		slice:setColor( 255, 255, 0, 70 )
		slice.width = 10
	end

	return slice
end

local dragger = require("dragger")
local rotater = require("rotater")
local rolloffGradient = require("RolloffGradient")
local tools = require("Tools")




local model = display.newGroup()
local axis = display.newImage("images/grid-800x50.png", 0, 0)

local speaker = display.newGroup()
local speakerImg = display.newImage("images/speaker.png", 0, 0)

local personGrp = display.newGroup()
local personImg = display.newImage("images/person-top-down.png", 0, 0)

local ptTextFont = "Helvetica-Bold"
local ptTextSize = 18
local ptTextColor = {255, 255, 255, 255}

local ptAcolor = {255, 7, 17, 255}
local ptBcolor = {0, 178, 255, 255}

local function ptCallback()
	-- don't do anything
end

---------------------------------------------- Point A
local ptAgrp = display.newGroup()

local ptAdot = display.newCircle(0,0,15)
ptAdot:setFillColor(ptAcolor[1], ptAcolor[2], ptAcolor[3], ptAcolor[4])

local ptAlabel = display.newText("A",0,0, ptTextFont, ptTextSize)
ptAlabel:setTextColor( ptTextColor[1], ptTextColor[2], ptTextColor[3], ptTextColor[4] )

ptAgrp:insert(ptAdot)
ptAgrp:setReferencePoint(display.CenterReferencePoint)
ptAgrp:insert(ptAlabel)
ptAlabel.x = 1.5
ptAlabel.y = 0

---------------------------------------------- Point B
local ptBgrp = display.newGroup()

local ptBdot = display.newCircle(0,0,15)
ptBdot:setFillColor(ptBcolor[1], ptBcolor[2], ptBcolor[3], ptBcolor[4])

local ptBlabel = display.newText("B",0,0, ptTextFont, ptTextSize)
ptBlabel:setTextColor( ptTextColor[1], ptTextColor[2], ptTextColor[3], ptTextColor[4] )

ptBgrp:insert(ptBdot)
ptBgrp:setReferencePoint(display.CenterReferencePoint)
ptBgrp:insert(ptBlabel)
ptBlabel.x = 1.5
ptBlabel.y = 0


---------------------------------------------- Max Dist
local distModel = display.newGroup()
local rolloffColorInner = {220, 220, 220, 255} -- light grey 2
local rolloffColorOuter = {100, 100, 100, 255} -- dark grey 2 (same as main.kau > bkgdColor)
local distRefColor = {220, 220, 220, 255} -- light grey 1
local distMaxColor = {255, 249, 114, 50} -- light yellow

--[[
local myDistRef = retObj:makeArc(0,0,100,100,0,360) -- 200 = radius (total width and height of 100 
myDistRef.width = 1
local myDistMax = retObj:makeArc(0,0,100,100,0,360)
myDistMax.width = 4

myDistRef:setColor(distRefColor[1], distRefColor[2], distRefColor[3], distRefColor[4])
myDistMax:setColor(distMaxColor[1], distMaxColor[2], distMaxColor[3], distMaxColor[4])
--]]


local myDistRef = display.newCircle(0,0,50) -- 200 = radius (total width and height of 100 
myDistRef.strokeWidth = 1
local myDistMax = display.newCircle(0,0,50)
myDistMax.strokeWidth = 4

myDistRef:setFillColor(0, 0, 0, 0)
myDistMax:setFillColor(0, 0, 0, 0)

myDistRef:setStrokeColor(distRefColor[1], distRefColor[2], distRefColor[3], distRefColor[4])
myDistMax:setStrokeColor(distMaxColor[1], distMaxColor[2], distMaxColor[3], distMaxColor[4])

distModel:insert(myDistMax)
distModel:insert(myDistRef)




function retObj:newModel(params)
	
	
	
	local bkgdColor = params.bkgdColor

	local speakerGrabber = dragger:newDragger{	img			= speakerImg, 
										callback	= params.speakerCallback, 
										popup		= params.popup,
										dragTarget	= speaker
										} 
	

	speaker:insert(speakerGrabber)
	speaker:setReferencePoint(display.CenterReferencePoint)
	speakerGrabber.x = 0
	speakerGrabber.y = 0
	speaker:setReferencePoint(display.CenterReferencePoint)


	personGrp:insert(personImg)
	personGrp:setReferencePoint(display.CenterReferencePoint)
	personImg.x = 0
	personImg.y = 0
	personGrp:setReferencePoint(display.CenterReferencePoint)
	
	local person = dragger:newDragger{	img			= personGrp, 
										callback	= params.personCallback, 
										popup		= params.popup
										}
	

	
	---------------------------------------------- Point A

	local ptA = dragger:newDragger{	img			= ptAgrp, 
									callback	= ptCallback, 
									popup		= params.popup
									}

	---------------------------------------------- Point B


	local ptB = dragger:newDragger{	img			= ptBgrp, 
									callback	= ptCallback, 
									popup		= params.popup
									}
	

	
	person.x = axis.width/2
	person.y = axis.height/2
	
	speaker.x = axis.width/2
	speaker.y = axis.height/2	

	
	function model:drawCones(cone_inner_val, cone_outer_val)
		
		if speaker.cone_inner ~= nil then
			speaker.cone_inner:removeSelf()
			speaker.cone_inner = nil
			speaker.cone_outer:removeSelf()
			speaker.cone_outer = nil
		end
		
		if cone_inner_val < 358 and cone_inner_val > 2 then
			speaker.cone_outer = retObj:drawSlice(cone_outer_val, 2)
			speaker.cone_inner = retObj:drawSlice(cone_inner_val, 1)
		
			speaker:insert(speaker.cone_outer)
			speaker:insert(speaker.cone_inner)
			
			speakerGrabber:toFront()
		end
	end
	
	
	model:insert(axis)
	model:insert(person)
	model:insert(speaker)
	
	model:setReferencePoint(display.CenterReferencePoint)
	
	axis.x = 0
	axis.y = 0
	
	person.x = 0
	person.y = 0
	
	speaker.x = 0
	speaker.y = 0
	
	model:setReferencePoint(display.CenterReferencePoint)
	

	model.axis = axis
	model.person = person
	model.speaker = speaker
	
	
	---------------------------------------------- Rotater Person
	local visualToAudio = params.visualToAudio
	local function doRotate()
		visualToAudio()
	end
	local myRotaterPerson = rotater:newRotater{
		popup = params.popup,
		rotateTarget = person,
		callback = doRotate,
		x = 0,
		y = 85
	}
	person:insert(myRotaterPerson)
	
	---------------------------------------------- Rotater Speaker

	local myRotaterSpeaker = rotater:newRotater{
		popup = params.popup,
		rotateTarget = speaker,
		callback = doRotate,
		x = 0,
		y = 85
	}
	
	speaker:insert(myRotaterSpeaker)
	
	
	---------------------------------------------- Max Distance

	

	
	speaker:insert(distModel)
	
	model.distref = myDistRef
	model.distmax = myDistMax
	
	model.distModel = distModel
	
	distModel:toBack()
	speaker:toBack()
	

	
	function model:renderAttenuation(distModel, rolloff, ref, max, clamped)
		
		-- To see rolloff terminal output better
		--print("================================")
		
		------------------------------
		-- NOTE
		------------------------------
		-- After 3 solid days of banging my head against the wall trying to get the "actual" formulas
		-- found in the OpenAL documentation to work (graphically) I just decided to fudge things and 
		-- create formulas that provide a "close" approximation between the audio and the visual.
		
		-- So any brainiacs out there, if you can get the actual formulas to work, that's be great.
		
		-------------------------------
		-- Max Distance
		-------------------------------
		local maxScale = max*2
		myDistMax.xScale = maxScale
		myDistMax.yScale = maxScale

		-------------------------------
		-- Reference Distance
		-------------------------------
		-- The distnace refers to the radius, (from the center of the 
		-- source tot he listener's ear), and our display object needs 
		-- to have this value doubled... Don't know exactly why, but it works!
		-- I think it may have to do with the "arc" object (which is NOT a display.circle(), 
		-- but a shape generated with lines), and so it's actual size may be freakish.
		local refScale = ref*2
		myDistRef.xScale = refScale
		myDistRef.yScale = refScale
		
		-------------------------------
		-- Rolloff Gradient Display
		-------------------------------
		if model.rolloff ~= nil then
			model.rolloff:destroy()
			model.rolloff:removeSelf()
			model.rolloff = nil
		end

		----------------rolloffGradient:new(outerColor, 	innerColor, 	smoothness, [and so on])
		model.rolloff = rolloffGradient:new(rolloffColorOuter, 	rolloffColorInner, 	20, rolloff, ref, max, distModel, clamped)
		model.distModel:insert(model.rolloff)
		model.rolloff:toBack()

	end
	
	
	
	
	---------------------------------------------
	-- A -> B points
	---------------------------------------------
	
	ptA.x = (axis.width/8)
	ptA.y = (-axis.height/2) + 60
	

	ptB.x = (axis.width/8)
	ptB.y = (axis.height/2) - 60


	
	model:insert(ptA)
	model:insert(ptB)
	model:setReferencePoint(display.CenterReferencePoint)
	
	model.ptA = ptA
	model.ptB = ptB
	
	---------------------------------------------
	-- Move into position
	---------------------------------------------
	
	model:setReferencePoint(display.CenterReferencePoint)
	model.x = params.x
	model.y = params.y

	
	return model
	
end



return retObj









