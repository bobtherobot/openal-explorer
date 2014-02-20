-- 
-- Abstract: ObjectAL Exposer - 


--[[ 
OpenAL doesn't define units (section 3.3), so you must decide how "units" in your sound environment
correspond to "units" in your graphical environment (similar to what you'd have to do when mixing Box2D and
cocos2d, for example). Basically, choose a conversion ratio that makes "1.0" in your sound environment equal to a
sane value in pixels (such as, say, 100 pixels = 1 "unit" in the sound system). I'm not doing that in my demos,
though I probably should! Position your sound sources according to whatever formula you come up with for this. You
can also position the listener somewhere other than the center, but usually that's not needed.

If you're not using graphics, just assume that "1.0" is one meter, and make sure you're not moving your sources
too far away, otherwise it'll seem like a sharp dropoff as you move 1km away in a split-second ;-) 
--]]

display.setStatusBar( display.HiddenStatusBar )

local bkgdColor = {100, 100, 100}
local bkgd = display.newRect(0,0, display.contentWidth, display.contentHeight)
bkgd:setFillColor(bkgdColor[1], bkgdColor[2], bkgdColor[3])

local slider = require("Slider")
local popup = require("PopUp")
local tools = require("Tools")
local button = require("Button")
local toggle = require("Toggle")

--local stage = require("stage")


local controls = display.newGroup()


--------------------------------------------------------------------------------
-- Audio recording setup
--------------------------------------------------------------------------------
--local testSoundFile = "Templar.mp3"
local testSoundFile = "Templar.caf"




local playbackSoundHandle
local playState 	= 0
local playButton

local ch, src                 				-- openAL audio channel and source
local pitch			= 1			  			-- the pitch shift
local sourcePos 	= {x = 0, y = 0, z = 0} -- source coordinates
local sourceDir 	= {x = 0, y = 0, z = 0} -- source direction	(z = looking down at the listener)
local sourceVel 	= {x = 0, y = 0, z = 0} -- source velocity
local listenerPos 	= {x = 0, y = 0, z = 0} -- listener coordinates
local listenerOri	= {x = 0, y = 0, z = 0} -- listener orientation (z = looking up at the source)	
local listenerVel 	= {x = 0, y = 0, z = 0} -- listener velocity

--[[--------------------------------------------------
--   NOTES
----------------------------------------------------

-----------------------
LISTENER_ORIENTATION
-----------------------
z = 1 since we're looking down the Z axis (at the listener.

Technically, the LISTENER_ORIENTATION array should hav 6 values, 
the first three are for the "at" vector, and the last three for 
the "up" vector. We're not dealing with the "up" since we're in 2 dimensions.
And we've hard coded the last three values into the updateAL() function.

-----------------------
SOURCE_DIRECTION
-----------------------
z = -1 since we're facing the person (opposite of the listener orientation z "at")

--]]


local uiFont 		= "HelveticaNeue-Bold"
local uiFontSize 	= 30
local uiFontColor 	= {180, 180, 180, 255} --{100, 100, 100, 255}

local ui_slider_label_textSize 	= 12
local ui_slider_label_textColor	= uiFontColor
local ui_slider_label_offsetX 	= 10
local ui_slider_label_offsetY 	= 18
local ui_slider_spacing 		= 42

local ui_start_pos_x 			= display.contentWidth - 240
local ui_start_pos_y 			= 20
local ui_section_spacing 		= 20

local ui_dmLabelOffset = ui_start_pos_x + 20

local pitchSlider = {}
local panSlider = {}
local volSlider = {}
--local oriSlider = {}
--local dirSlider = {}
local coneInSlider = {}
local coneOutSlider = {}
local dfSlider = {}		-- Doppler Factor
local sosSlider = {}	-- Speed of Sound


local rofSlider = {}	-- Rolloff Slider
local refDistSlider = {}-- Reference Distance Slider
local maxDistSlider = {}-- Max Distance Slider

local rrmSliderCallback -- Rolloff, Ref, Max display function 
local distance_range_lo = 1
local distance_range_hi = 10

local volume_level = 0.9
local volume_level_multiplier = 7

local pan_value = 0



local cone_outer_val = 360
local cone_inner_val = 360

-- Forward Reference Functions
local coneOutSliderCallback
local coneInSliderCallback
local updateControls
local visualToAudio
local resetVelocity
local relaunchTrack
local dmButtonCallback
local clampedButtonCallback
local pause
local play
local pitchSliderCallback
local volSliderCallback
local panSliderCallback
local doDistanceModel

local nullObj = {}

----------------------------------------------- A to B Button
local abTimer = {}
local abSpeed = 5000

local prevPos = {x=0, y=0}
local prevSP_x = 0
local prevSP_y = 0

local currentTime = 0
local prevTime = 0




local ui_dm_textSize = 10
local ui_dm_height = 16
local ui_dm_spacerY = 10

local dm_radioGroup = {}
local clamped = {}

local amClamped = 1

local myDistanceModelBase = "INVERSE_DISTANCE"
local myDistanceModelReal = myDistanceModelBase .. "_CLAMPED"

-- RRM = Rolloff, Reference, Max
local rrm_roff = 1
local rrm_dist_ref = 1
local rrm_dist_max = distance_range_hi * 0.4


-- Default = INVERSE_DISTANCE_CLAMPED
local dmValues = {
	"NONE",
	
	"LINEAR_DISTANCE",
	--"LINEAR_DISTANCE_CLAMPED",
	
	"INVERSE_DISTANCE",
	--"INVERSE_DISTANCE_CLAMPED",
	
	"EXPONENT_DISTANCE",
	--"EXPONENT_DISTANCE_CLAMPED",

}




local model_top = require("model_top")
local model = {}


local controlsBkgdColor = {50, 50, 50}
local controlsBkgd = display.newRect(ui_start_pos_x,0, 250, display.contentHeight)
controlsBkgd:setFillColor(controlsBkgdColor[1], controlsBkgdColor[2], controlsBkgdColor[3])
ui_start_pos_x = ui_start_pos_x + 20






local dataTextBoxTextColor	= {0, 0, 0, 255}
local dataTextBoxWidth 	= 200
local dataTextBoxHeight = 800
local dataTextBoxX 		= 10
local dataTextBoxY 		= 10

--display.newText( [parentGroup,] string, left, top,[width, height,] font, size )
local dataTextBox = display.newText("Hello", 
									dataTextBoxX, 
									dataTextBoxY, 
									dataTextBoxWidth, 
									dataTextBoxHeight,
									"Helvetica", 18 
									)
dataTextBox:setReferencePoint(display.TopLeftReferencePoint)
dataTextBox.align = "left"
dataTextBox:setReferencePoint(display.CenterReferencePoint)
dataTextBox:setTextColor( dataTextBoxTextColor[1], dataTextBoxTextColor[2], dataTextBoxTextColor[3] )

local function showData()
	local dbText = ""
	
--	dbText = dbText .. "--------------" .. "\n"
	dbText = dbText .. "al.Source" .. "\n"
--	dbText = dbText .. "--------------" .. "\n"
	dbText = dbText .. "POSITION" .. "\n"
	dbText = dbText .. "x: " .. tools:round(sourcePos.x, 2) .. "\n"
	dbText = dbText .. "y: " .. tools:round(sourcePos.y, 2) .. "\n"
	dbText = dbText .. "z: " .. tools:round(sourcePos.z, 2) .. "\n"
	dbText = dbText .. "DIRECTION" .. "\n"
	dbText = dbText .. "x: " .. tools:round(sourceDir.x, 2) .. "\n"
	dbText = dbText .. "y: " .. tools:round(sourceDir.y, 2) .. "\n"
	dbText = dbText .. "z: " .. tools:round(sourceDir.z, 2) .. "\n"
	dbText = dbText .. "VELOCITY" .. "\n"
	dbText = dbText .. "x: " .. tools:round(sourceVel.x, 2) .. "\n"
	dbText = dbText .. "y: " .. tools:round(sourceVel.y, 2) .. "\n"
	dbText = dbText .. "z: " .. tools:round(sourceVel.z, 2) .. "\n"

	dbText = dbText .. "--------------" .. "\n"
	dbText = dbText .. "al.Listener" .. "\n"
--	dbText = dbText .. "--------------" .. "\n"
	dbText = dbText .. "POSITION" .. "\n"
	dbText = dbText .. "x: " .. tools:round(listenerPos.x, 2) .. "\n"
	dbText = dbText .. "y: " .. tools:round(listenerPos.y, 2) .. "\n"
	dbText = dbText .. "z: " .. tools:round(listenerPos.z, 2) .. "\n"
	dbText = dbText .. "ORI at" .. "\n"
	dbText = dbText .. "x: " .. tools:round(listenerOri.x, 2) .. "\n"
	dbText = dbText .. "y: " .. tools:round(listenerOri.y, 2) .. "\n"
	dbText = dbText .. "z: " .. tools:round(listenerOri.z, 2) .. "\n"
	dbText = dbText .. "ORI up" .. "\n"
	dbText = dbText .. "x: 0" .. "\n"
	dbText = dbText .. "y: 0" .. "\n"
	dbText = dbText .. "z: 1" .. "\n"
	dbText = dbText .. "VELOCITY" .. "\n"
	dbText = dbText .. "x: " .. tools:round(listenerVel.x, 2) .. "\n"
	dbText = dbText .. "y: " .. tools:round(listenerVel.y, 2) .. "\n"
	dbText = dbText .. "z: " .. tools:round(listenerVel.z, 2) .. "\n"
	
	dataTextBox.text = dbText
	
end


local function updateAL()
	if src ~= nil then
		--[[
		al.DopplerFactor(DOPPLER_FACTOR, 100.0)
		al.SpeedOfSound(SPEED_OF_SOUND, 100.0)
		--]]
		
		
		
		---------------------------------------
		--           Positions
		---------------------------------------
        al.Source( 		src, 
						al.POSITION, 
						sourcePos.x,
						sourcePos.y,
						sourcePos.z
						)

        al.Listener( 					-- No src
						al.POSITION, 
						listenerPos.x,
						listenerPos.y,
						listenerPos.z
						)
		
		---[[
		---------------------------------------
		--           Velocity
		---------------------------------------
        al.Source( 		src, 
						al.VELOCITY, 
						sourceVel.x,
						sourceVel.y,
						sourceVel.z
						)

        al.Listener( 					-- No src
						al.VELOCITY, 
						listenerVel.x,
						listenerVel.y,
						listenerVel.z
						)
		--]]

		---------------------------------------
		--      Source Direction
		---------------------------------------
		
		if cone_inner_val < 2 or cone_inner_val > 358 then
			cone_inner_val = 360
		end
		
		if cone_outer_val < cone_inner_val then
			cone_outer_val = cone_inner_val
			coneOutSlider:setValue(cone_outer_val)
			model:drawCones(cone_inner_val, cone_outer_val)
		end
		

	
		al.Source(src, al.CONE_INNER_ANGLE, cone_inner_val)
		al.Source(src, al.CONE_OUTER_ANGLE, cone_outer_val)

		al.Source( src,
					al.DIRECTION, 
					sourceDir.x,
					sourceDir.y,
					sourceDir.z 	-- z facing the person (opposite of orientation "at")
				)			
						
		---------------------------------------
		--      Listener Orientation
		---------------------------------------

		al.Listener(
					al.ORIENTATION, 

					-- "at"
					listenerOri.x,
					listenerOri.y,
					listenerOri.z, 	-- z  -1 (looking down the Z axis)

					-- "up"
					0, 				-- x 
					0, 				-- y
					1				-- z
				)

		
		
    end

	showData()
	
end

--al.DopplerFactor(10.0)
--al.SpeedOfSound(10.0)
--al.DopplerVelocity(100.0)

--[[
print("DOPPLER_FACTOR: " .. al.Get(al.DOPPLER_FACTOR))
print("SPEED_OF_SOUND: " .. al.Get(al.SPEED_OF_SOUND))
print("DOPPLER_VELOCITY: " .. al.Get(al.DOPPLER_VELOCITY))
--]]


visualToAudio = function (amPanOrVol)
	
	local rad, mag
	
	-- Positions
	sourcePos.x = model.speaker.x/100
	sourcePos.y = model.speaker.y/100
	
	listenerPos.x = model.person.x/100
	listenerPos.y = model.person.y/100
	
	-- Source Direction
	-- Minus y value because of brute force trila and error tells me so.
	rad = (model.speaker.rotation) * tools.MATH_PI_180
	sourceDir.x = math.sin(rad)
	sourceDir.y = -math.cos(rad)
	
	-- Listener Orientation
	-- Minus x value because of brute force trila and error tells me so.
	rad = (model.person.rotation) * tools.MATH_PI_180
	listenerOri.x = -math.sin(rad)
	listenerOri.y = math.cos(rad)
	
	updateAL()
	
	if amPanOrVol ~= true then
		updateControls()
	end
	
end


--[[
---------- To 360 -------------------------------------
var angle = -2 * Math.atan((y2-y1)/(x2-x1)) * (180/Math.PI) + 180
or
local degrees = math.abs( -2 * tools:getAngleInRadians(model.speaker, model.person) * (180/math.pi) )
-------------------------------------------------------
--]]
updateControls = function ()
	
	------------------------------
	--          Pan
	------------------------------
	
	--[[
	local degrees = radToDeg( tools:getAngleInRadians(model.speaker, model.person) )
	if degrees < 0 then
		degrees = degrees + 360
	end
	--]]
	
	
	local degrees = 270 - (tools:getAngleInRadians(model.speaker, model.person) / tools.MATH_PI_180)
	--local degrees = math.abs( -2 * tools:getAngleInRadians(model.speaker, model.person) * (180/math.pi) )
	if degrees > 360 then
		degrees = degrees - 360
	end
	--[[
	if degrees < 0 then
		degrees = degrees * (-1)
	end
	--]]
	-- Invert final (otherwise left is right)
	--degrees = 180 - degrees 
	
	panSlider:setValue(degrees, true)
	
	------------------------------
	--          Volume
	------------------------------
	volume_level = ( volume_level_multiplier - (math.abs( tools:distance(model.person, model.speaker) )/100) ) / volume_level_multiplier
	volSlider:setValue(volume_level, true)
	
end

--[[
local function moveSpeaker()
	-- Divide by two, since were dealing with radius and not diameter. 
	model.speaker.x = ((listenerPos.x + sourcePos.x ) / 2) * 100
	model.speaker.y = ((listenerPos.y + sourcePos.y ) / 2) * 100
end
--]]

local function speakerCallback(xPos, yPos)
	visualToAudio()
end

local function personCallback(xPos, yPos)
	visualToAudio()
end

local function setModel(theKind)
	if theKind == "top" then
		model = model_top:newModel{
					--[[
					x				= (display.contentWidth/2) + 130, 
					y				= (display.contentHeight/2),
					--]]
					x				= (display.contentWidth/2) - 130, 
					y				= (display.contentHeight/2),
					speakerCallback = speakerCallback,
					personCallback 	= personCallback,
					speakerPos 		= sourcePos,
					personPos 		= listenerPos,
					popup 			= popup,
					visualToAudio 	= visualToAudio,
					bkgdColor = bkgdColor,
					}
	end
end



----------------------------------------------- Reset

local function resetButtonPress()
	
	--  Pitch, Pan, Distance, Cones
	pitchSlider:setValue(1)
	panSlider:setValue(90)
	volSlider:setValue(0.5)
	coneInSlider:setValue(360)
	coneOutSlider:setValue(360)
	
	pitchSliderCallback( nullObj, 1, 0 )
	volSliderCallback(nullObj, 0.5, 0)
	coneOutSliderCallback(nullObj, 360, 0)
	coneInSliderCallback(nullObj, 360, 0)
	
	-- Move back into original positions
	-- NOTE: vloumecallback changes the position
	-- so this section needs to be below the volcallback call.
	
	model.speaker.x = 0
	model.speaker.y = -200
	model.speaker.rotation = 180
	
	model.person.x = 0
	model.person.y = 0
	model.person.rotation = 0
	

	-- Rest DM sliders
	rrm_roff = 1
	rrm_dist_ref = 1
	rrm_dist_max = distance_range_hi * 0.4
	
	rofSlider:setValue(rrm_roff)
	refDistSlider:setValue(rrm_dist_ref)
	maxDistSlider:setValue(rrm_dist_max)


	myDistanceModelBase = "INVERSE_DISTANCE"
	myDistanceModelReal = myDistanceModelBase .. "_CLAMPED"
	-- 3 is the index in dmValues for "INVERSE_DISTANCE"
	dmButtonCallback( nullObj, 3, 1 )
	
	-- Clamped Button
	clampedButtonCallback( nullObj, nullObj, 1 )
	-- doDistanceModel() -- Already being called twice!
	
	
	-- A B stuff
	abSpeed = 5000

	prevPos = {x=0, y=0}
	prevSP_x = 0
	prevSP_y = 0

	currentTime = 0
	prevTime = 0
	
	model.ptA.x = (model.axis.width/8)
	model.ptA.y = (-model.axis.height/2) + 60

	model.ptB.x = (model.axis.width/8)
	model.ptB.y = (model.axis.height/2) - 60
	
	dirSlider:setValue(abSpeed)
	dfSlider:setValue(10)
	sosSlider:setValue(343.3)
	

	
	
	pause()
	
	popup:off()

	rrmSliderCallback()
	visualToAudio()

end

local linkButton = button:newButton {
	id			= "reset",
	callback	= resetButtonPress,
	label		= "RESET",
	textSize	= 12,
	width 		= 80,
	height 		= 16,
	x 			= ui_start_pos_x + 116,
	y 			= display.contentHeight - 30,
}


----------------------------------------------- More Info Button

local function linkButtonPress()
	timer.performWithDelay(1000, function() system.openURL( "http://www.drumbot.com" ) end)
end

local linkButton = button:newButton {
	id			= "link",
	callback	= linkButtonPress,
	label		= "Learn More",
	textSize	= 12,
	width 		= 80,
	height 		= 16,
	x 			= ui_start_pos_x + 6,
	y 			= display.contentHeight - 30,
}

----------------------------------------------- Play / Pause Button


play = function()
	resetVelocity()
	if src == nil then
		playbackSoundHandle = audio.loadSound(testSoundFile)
	end
	
	ch, src = audio.play(playbackSoundHandle, { loops=-1 })
	--print ("audio.play")
	al.Source( src, al.PITCH, pitch )
	al.Source( src, al.POSITION, sourcePos.x, sourcePos.y, sourcePos.z ) 
	al.Listener( al.POSITION, listenerPos.x, listenerPos.y, listenerPos.z )
	playState = 1
	playButton:setText( "STOP")
	visualToAudio()
	rrmSliderCallback()
end

pause = function()
	audio.stop(ch)
	playState = 0
	playButton:setText( "PLAY")
	resetVelocity()
end

local function playButtonPress ( event )
	if playState == 0 then
		play()
	else
		pause()
	end
end

relaunchTrack = function()
	--[[
	pause()
	audio.dispose(src)
	playbackSoundHandle = audio.loadSound(testSoundFile)
	play()
	--]]
end

playButton = button:newButton {
	id			= "playpause",
	callback	= playButtonPress,
	label		= "PLAY",
	textSize	= 20,
	width 		= 180,
	height 		= 40,
	x 			= ui_start_pos_x + 10,
	y 			= ui_start_pos_y
}
ui_start_pos_y = ui_start_pos_y + playButton.height + 20




----------------------------------------------- Pitch


pitchSliderCallback = function( id, value, percent )
	pitch = value
    if playState == 1 then
        al.Source( src, al.PITCH, pitch )
    end
end

-- Sends: (lo, hi, theVal, percent, backwardation)
f_pitchValue = function(lo, hi, theVal, percent, backwardation)
	if backwardation == true then
		return tools:getLogVal(1, lo, hi, theVal)
	else
		return tools:getLogVal(2, lo, hi, theVal)
	end
end

pitchSlider = slider:newSlider {
	id 			= "pitch",
	label 		= "Pitch",
	labelSize 	= ui_slider_label_textSize,
	labelColor 	= ui_slider_label_textColor,
	label_x		= ui_slider_label_offsetX,
	label_y		= ui_slider_label_offsetY,
	callback	= pitchSliderCallback,
	--f_value		= f_pitchValue,
	value_min 	= 0.5,
	value_max 	= 2.0,
	value		= 1,
	--height		= 200,
	width		= 200,
	x 			= ui_start_pos_x,
	y 			= ui_start_pos_y,
	popup 		= popup,
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing


----------------------------------------------- Pan


panSliderCallback = function( id, value, percent )
	
	pan_value = value
	local radius = -tools:distance(model.person, model.speaker)
	
	local radi = pan_value * tools.MATH_PI_180
	model.speaker.x = model.person.x + (math.sin(radi) * (radius))
	model.speaker.y = (model.person.y) + ( math.cos(radi) * (radius) )
	
	visualToAudio(true)
	
end


panSlider = slider:newSlider {
	id 			= "pan",
	label 		= "Pan",
	labelSize 	= ui_slider_label_textSize,
	labelColor 	= ui_slider_label_textColor,
	label_x		= ui_slider_label_offsetX,
	label_y		= ui_slider_label_offsetY,
	callback	= panSliderCallback,
	--f_value		= f_dirValue,
	value_min 	= 0,
	value_max 	= 360,
	value		= 90,
	--height		= 200,
	width		= 200,
	x 			= ui_start_pos_x,
	y 			= ui_start_pos_y,
	popup 		= popup,
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing


----------------------------------------------- Volume

volSliderCallback = function( id, value, percent )

	-- Not setting "acual" volume because the audio level is 
	-- controlled by the distance bewtween the speaker and person
	--audio.setVolume( value , { channel = ch  } )

	volume_level = (1-value)

	local rad = tools:getAngleInRadians(model.speaker, model.person)

	local radius =  (volume_level * volume_level_multiplier) * 100
	model.speaker.x = model.person.x + ( radius * math.cos(rad) )
	model.speaker.y = model.person.y + ( radius * math.sin(rad) )

	visualToAudio(true)
	
end


volSlider = slider:newSlider {
	id 			= "vol",
	label 		= "Volume",
	labelSize 	= ui_slider_label_textSize,
	labelColor 	= ui_slider_label_textColor,
	label_x		= ui_slider_label_offsetX,
	label_y		= ui_slider_label_offsetY,
	callback	= volSliderCallback,
	--f_value		= f_dirValue,
	value_min 	= 0,
	value_max 	= 1,
	value		= 0.5,
	--height		= 200,
	width		= 200,
	x 			= ui_start_pos_x,
	y 			= ui_start_pos_y,
	popup 		= popup,
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing





----------------------------------------------- Cones

coneOutSliderCallback = function( id, value, percent )
	cone_outer_val = value
	
	if cone_outer_val < cone_inner_val then
		cone_inner_val = cone_outer_val
		coneInSlider:setValue(cone_inner_val)
	end
	
	model:drawCones(cone_inner_val, cone_outer_val)
	updateAL()
end


coneInSliderCallback = function( id, value, percent )
    cone_inner_val = value

	if cone_inner_val > cone_outer_val then
		cone_outer_val = cone_inner_val
		coneOutSlider:setValue(cone_outer_val)
	end
	

	model:drawCones(cone_inner_val, cone_outer_val)
	updateAL()
end


---------- INNER CONE SLIDER
coneInSlider = slider:newSlider {
	id 			= "dir",
	label 		= "Inner Cone",
	labelSize 	= ui_slider_label_textSize,
	labelColor 	= ui_slider_label_textColor,
	label_x		= ui_slider_label_offsetX,
	label_y		= ui_slider_label_offsetY,
	callback	= coneInSliderCallback,
	--f_value		= f_dirValue,
	value_min 	= 1,
	value_max 	= 360,
	value		= 360,
	--height		= 200,
	width		= 200,
	x 			= ui_start_pos_x,
	y 			= ui_start_pos_y,
	popup 		= popup,
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing

---------- OUTER CONE SLIDER
coneOutSlider = slider:newSlider {
	id 			= "dir",
	label 		= "Outer Cone",
	labelSize 	= ui_slider_label_textSize,
	labelColor 	= ui_slider_label_textColor,
	label_x		= ui_slider_label_offsetX,
	label_y		= ui_slider_label_offsetY,
	callback	= coneOutSliderCallback,
	--f_value		= f_dirValue,
	value_min 	= 1,
	value_max 	= 360,
	value		= 360,
	--height		= 200,
	width		= 200,
	x 			= ui_start_pos_x,
	y 			= ui_start_pos_y,
	popup 		= popup,
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing


----------------------------------------------- A to B Button


resetVelocity = function()
	sourceVel.x = 0
	sourceVel.y = 0
	if src ~= nil then
		al.DopplerFactor(1.0)
		al.SpeedOfSound(343.3)
	end
end

local function doAB( event )
	-- broken
	


	--[[
	-- Should work, but retarded
	
	local currentTime = system.getTimer()
	local deltaT = currentTime - prevTime
	
	local rad = tools:getAngleInRadians(prevPos, model.speaker)
	
	sourceVel.x = math.sin(rad) * deltaT
	sourceVel.z = math.cos(rad) * deltaT
	
	prevPos.x = model.speaker.x
	prevPos.y = model.speaker.y
	
	prevTime = currentTime
	--]]

	--[[
	-- kinda works, but slow
	
	local currentTime = system.getTimer()
	local deltaT = currentTime - prevTime
	sourceVel.x = (sourcePos.x - prevSP_x) * deltaT
	sourceVel.z = (sourcePos.z - prevSP_z) * deltaT
	prevTime = currentTime
	--]]
	
	-- This is the only thing that sorta-kinda works.
	-- Have to ramp up the Doppler Factor to actually hear anything.
	sourceVel.x = (sourcePos.x - prevSP_x)
	sourceVel.y = (sourcePos.y - prevSP_y)
	
	
	prevSP_x = sourcePos.x
	prevSP_y = sourcePos.y
	
	
	
    visualToAudio()
end

local function killAB()
	sourceVel.x = 0
	sourceVel.y = 0
	
	--[[
	al.SpeedOfSound(343.3)
	sosSlider:setValue(343.3)
	--]]
	
	visualToAudio()
	timer.cancel(abTimer)
	timer.cancel(abTimer)
end


local function abPress()
	
	model.speaker.x = model.ptA.x
	model.speaker.y = model.ptA.y
	
	transition.to(model.speaker, {time=abSpeed, x = model.ptB.x, y=model.ptB.y, onComplete=killAB})
	abTimer = timer.performWithDelay(1, doAB, 0)
	
end

-- Bump down a bit
ui_start_pos_y = ui_start_pos_y + ui_section_spacing
AtoBbutton = button:newButton {
	id			= "ab",
	callback	= abPress,
	label		= "A -> B",
	textSize	= 20,
	width 		= 180,
	height 		= 40,
	x 			= ui_start_pos_x + 10,
	y 			= ui_start_pos_y
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing + 10


----------------------------------------------- A B speed Factor


local abSpeedSliderCallback = function( id, value, percent )

	abSpeed = value
	
end

dirSlider = slider:newSlider {
	id 			= "df",
	label 		= "A -> B Speed (ms)",
	labelSize 	= ui_slider_label_textSize,
	labelColor 	= ui_slider_label_textColor,
	label_x		= ui_slider_label_offsetX,
	label_y		= ui_slider_label_offsetY,
	callback	= abSpeedSliderCallback,
	--f_value		= f_dirValue,
	value_min 	= 250,
	value_max 	= 10000,
	value		= abSpeed,
	--height		= 200,
	width		= 200,
	x 			= ui_start_pos_x,
	y 			= ui_start_pos_y,
	popup 		= popup,
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing


----------------------------------------------- Doppler Factor



local dfSliderCallback = function( id, value, percent )

	if src ~= nil then
		al.DopplerFactor(value)
	end
	
end

dfSlider = slider:newSlider {
	id 			= "df",
	label 		= "Doppler Factor",
	labelSize 	= ui_slider_label_textSize,
	labelColor 	= ui_slider_label_textColor,
	label_x		= ui_slider_label_offsetX,
	label_y		= ui_slider_label_offsetY,
	callback	= dfSliderCallback,
	--f_value		= f_dirValue,
	value_min 	= 1,
	value_max 	= 1000,
	value		= 10,
	--height		= 200,
	width		= 200,
	x 			= ui_start_pos_x,
	y 			= ui_start_pos_y,
	popup 		= popup,
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing


----------------------------------------------- Speed of Sound



local sosSliderCallback = function( id, value, percent )
	if src ~= nil then
		al.SpeedOfSound(value)
	end
end

sosSlider = slider:newSlider {
	id 			= "df",
	label 		= "Speed of Sound",
	labelSize 	= ui_slider_label_textSize,
	labelColor 	= ui_slider_label_textColor,
	label_x		= ui_slider_label_offsetX,
	label_y		= ui_slider_label_offsetY,
	callback	= sosSliderCallback,
	--f_value		= f_dirValue,
	value_min 	= 1,
	value_max 	= 1000,
	value		= 343.3,
	--height		= 200,
	width		= 200,
	x 			= ui_start_pos_x,
	y 			= ui_start_pos_y,
	popup 		= popup,
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing 


--[[
-- No Documentation on this "available" hook
----------------------------------------------- Doppler Velocity


local dvSliderCallback = function( id, value, percent )
	al.DopplerVelocity(value)
end

dvSlider = slider:newSlider {
	id 			= "dv",
	label 		= "Doppler Velocity",
	labelSize 	= ui_slider_label_textSize,
	labelColor 	= ui_slider_label_textColor,
	label_x		= ui_slider_label_offsetX,
	label_y		= ui_slider_label_offsetY,
	callback	= dvSliderCallback,
	--f_value		= f_dirValue,
	value_min 	= 1,
	value_max 	= 1000,
	value		= 500,
	--height		= 200,
	width		= 200,
	x 			= ui_start_pos_x,
	y 			= ui_start_pos_y,
	popup 		= popup,
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing
--]]

----------------------------------------------- DistanceModel



doDistanceModel = function()
	
	local tempPlayState = playState
	
	if playState == 1 then
		pause()
	end
	
	-- Default = INVERSE_DISTANCE_CLAMPED
	local tackClamp = ""
	if amClamped == 1 then
		tackClamp = "_CLAMPED"
	end
	
	myDistanceModelReal = myDistanceModelBase .. tackClamp
	
	if src ~= nil then
		--print("Distance Model (real): " .. myDistanceModelReal)
		al.DistanceModel(al[myDistanceModelReal])
	end
	
	
	if tempPlayState == 1 then
		play()
	end
	
	--relaunchTrack()
	-- Ensure the new model gets the proper calculations applied.
	rrmSliderCallback()
	visualToAudio()
end

clampedButtonCallback = function( theSelf, id, theState )
	amClamped = theState
	doDistanceModel()
end



dmButtonCallback = function( theSelf, id, theState )
	
	for i=1, #dmValues do
		dm_radioGroup[i]:setState(0, true)
	end
	
	dm_radioGroup[id]:setState(1, true)
	
	myDistanceModelBase = dmValues[id]
	
	dmLabel.text = dmValues[id]
	dmLabel:setReferencePoint(display.TopLeftReferencePoint)
	dmLabel.x = ui_dmLabelOffset

	doDistanceModel()
end






-- Bump down a bit
ui_start_pos_y = ui_start_pos_y + ui_section_spacing

for i=1, #dmValues do
	--_G[ "dmButton" .. i ] = button:newButton {
	
	local isSelected = 0
	
	if dmValues[i] == "INVERSE_DISTANCE" then
		isSelected = 1
	end
	dm_radioGroup[i] = toggle:newToggle {
		id			= i,
		callback	= dmButtonCallback,
		bkgdOff		= "images/i-dm-" .. dmValues[i] .. ".png",
		bkgdOn		= "images/i-dm-" .. dmValues[i] .. "-on.png",
		starupState = isSelected,
		--label		= dmValues[i],
		--textSize	= ui_dm_textSize,
		--width 		= 180,
		--height 		= ui_dm_height,
		x 			= ui_start_pos_x + (52 * (i-1)),
		y 			= ui_start_pos_y
	}
	
end

ui_start_pos_y = ui_start_pos_y + ui_slider_spacing + 10


clamped = toggle:newToggle {
	id			= "clamped",
	callback	= clampedButtonCallback,
	label		= "CLAMPED",
	bkgdColorUp = {140, 140, 140, 255},
	textSize	= 10,
	starupState = 1,
	width 		= 64,
	height 		= 20,
	x 			= ui_start_pos_x + 140,
	y 			= ui_start_pos_y
}

dmLabel = display.newText("INVERSE_DISTANCE", 
						ui_dmLabelOffset,
						ui_start_pos_y, 
						uiFont, 12 )
dmLabel:setTextColor( uiFontColor[1], uiFontColor[2], uiFontColor[3], uiFontColor[4] )
dmLabel:setReferencePoint(display.TopLeftReferencePoint)

-- bump down a bit
ui_start_pos_y = ui_start_pos_y + 25


----------------------------------------------- Roll Off Factor, Max Distance, Reference Distance



--[[

referenceDistance:  

rolloffFactor:



------------------------------
Rolloff, reference distance and max distnace are applied to individual source instances, not set globally.

------------------------------
ROLLOFF_FACTOR  (default = 1)
------------------------------
Scales the volume attenuation between the range established by maxDistance and referenceDistance. Each
Distance Model handles rolloff differently. Setting rollof to zero prevents any attenuation from
occuring. Additionally, when set to zero, attenuation calculations are bypassed during runtime (e.g. faster calculations).

Think of "attenuation range" is a slope between the outer edge/range (maxDistance) 
and the center of the source. The shape of the slope is affected by the Distance Model.

Note that referenceDistance also plays a roll in overall shape of the "attenuation range" slope.
 
When rolloffFactor is at a higher value:
- The volume level starts to fall-off closer to the center of the source.

At lower values: 
- The volume level starts to fall-off closer to the referenceDistance.

When a Distance Model is CLAMPED, the volume level at the outer edges of rolloff are fixed at the MIN_GAIN level. 
When not clamped, rolloff factor can exceed the maxDistance and/or shorten the referenceDistance.

Think of rolloff factor as a filter sites above referenceDistance and maxDistance. 

------------------------------
REFERENCE_DISTANCE 
------------------------------

The reference distance lets you change the scale, e.g. you go from 0 to 10, or 0 to 128, or 0 1,000,000,
etc. Then based on the distance, you can specify the decay curve which can be linear, exponential, or
inverse. This just means how fast does the sound volume drop as it moves away.

The distance where the listener percieves the volume at 1/2 the normal volume.
Note that rolloffFactor and maxDistance also influence the percieved volume level.
// The distance at which the listener will experience gain. Outside referenceDistance, will be silence.
Depending on the distance model it will also act as a distance threshold below which gain is clamped.


FROM:
http://www.gamedev.net/topic/484693-openal-distance-fade/

The reference distance is typically the distance where the source will be loudest. So if you, say, set
the reference distance to 2 and the max gain to 0.8 for the source, if the listener is 2 units or closer
to the source, the playback volume for the source will be at 0.8.

The problem with setting the reference distance to 0 is because of the inverse distance math. The math
for getting the attenuation is:

flAttenuation = MinDist / (MinDist + (Rolloff * (Distance - MinDist)));

(where Rolloff is the rolloff factor, which can be used to strengthen or weaken the distance
attentuation, and MinDist is the reference distance)

If the reference distance was 0, that would cause the math to be 0/x, which would always be 0 (or worse,
if the distance was also 0, you'd get 0/0). A reference distance of 0 makes mathmatically no sense
because, as in real-life, you can't be listening directly at the point where a sound eminates from.
Setting the reference distance to something >0 and clamping solves this issue.

-------------------------------
MAX_DISTANCE
------------------------------
Outside of tis distance, athere will no longer be any attenuation of the source.

If CLAMPED, distances greater than maxDistance will be clamped to the calculated 
volume level at maxDistance.

The volume level at (or outside of) the point defined by maxDistance may be calculated
to be higher than MIN_GAIN due to how rolloff and referenceDistance are set up.

The calculated volume level at maxDistance over-rides MIN_GAIN. (MIN_GAIN has no affect under this circumstance.)

maxDistance
used with the Inverse Clamped Distance Model to set the distance where there will no longer be any
attenuation of the source

-------------------------------
culling
------------------------------
Culling is a term generally used in the 3d world that means (in regular Joe language): 
If it's too small, or hidden behind something (we can't see it anyway), 
then stop performing calculations on it. In essence, don't necessarily throw it away, 
but just zero it out and don't waste any cycles on it. Or, set it's visiblility to false.

ObjectAL doesn't do culling.

A source will always be playing, regardless of how low the volume level is, it's samples will 
always be added (literally) to the final sound output.

So it's up to the programmer to remove sources which are in audible.


Apply to source:
ROLLOFF_FACTOR
REFERENCE_DISTANCE
MAX_DISTANCE

--]]



rrmSliderCallback = function( id, value, percent )
	
	-- We are calling this when chaning Distance Model, so we need to check all.
	-- (i.e. "id" mat not be present)
	if id == "roff" then
		rrm_roff = value
		--local vis = tools:getLogVal(1.5, 0, 100, value)
	elseif id == "ref" then
		rrm_dist_ref = value
	elseif id == "max" then
		rrm_dist_max = value
	end
	
	model:renderAttenuation(myDistanceModelBase, rrm_roff, rrm_dist_ref, rrm_dist_max, amClamped)

	if src ~= nil then
		-- Applying all of these values at the same time, 
		-- since updating one seems to not 'take' when 
		-- handled indiviually.
		al.Source( src, al.ROLLOFF_FACTOR, rrm_roff )
		al.Source( src, al.REFERENCE_DISTANCE, rrm_dist_ref )
		al.Source( src, al.MAX_DISTANCE, rrm_dist_max )
	end
	
end




rofSlider = slider:newSlider {
	id 			= "roff",
	label 		= "Roll Off Factor",
	labelSize 	= ui_slider_label_textSize,
	labelColor 	= ui_slider_label_textColor,
	label_x		= ui_slider_label_offsetX,
	label_y		= ui_slider_label_offsetY,
	callback	= rrmSliderCallback,
	--f_value		= f_dirValue,
	value_min 	= 0.1,
	value_max 	= 10.0,
	value		= 1.0,
	--height		= 200,
	width		= 200,
	x 			= ui_start_pos_x,
	y 			= ui_start_pos_y,
	popup 		= popup,
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing


------------------------------------------------------- Reference Distance Slider
refDistSlider = slider:newSlider {
	id 			= "ref",
	label 		= "Reference Distance",
	labelSize 	= ui_slider_label_textSize,
	labelColor 	= ui_slider_label_textColor,
	label_x		= ui_slider_label_offsetX,
	label_y		= ui_slider_label_offsetY,
	callback	= rrmSliderCallback,
	--f_value		= f_dirValue,
	value_min 	= 0.1,
	value_max 	= 5.0,
	value		= 1.0,
	--height		= 200,
	width		= 200,
	x 			= ui_start_pos_x,
	y 			= ui_start_pos_y,
	popup 		= popup,
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing


------------------------------------------------------- Max Distance Slider
maxDistSlider = slider:newSlider {
	id 			= "max",
	label 		= "Max Distance",
	labelSize 	= ui_slider_label_textSize,
	labelColor 	= ui_slider_label_textColor,
	label_x		= ui_slider_label_offsetX,
	label_y		= ui_slider_label_offsetY,
	callback	= rrmSliderCallback,
	--f_value		= f_dirValue,
	value_min 	= distance_range_lo,
	value_max 	= distance_range_hi,
	value		= rrm_dist_max,
	--height		= 200,
	width		= 200,
	x 			= ui_start_pos_x,
	y 			= ui_start_pos_y,
	popup 		= popup,
}
ui_start_pos_y = ui_start_pos_y + ui_slider_spacing

---------------------------------------------- INITIALIZE


setModel("top")
--[[
--]]
model.speaker.y = model.speaker.y -200
model.speaker.rotation = 180

popup:off()


rrmSliderCallback()
visualToAudio()




model:toBack()
bkgd:toBack()

