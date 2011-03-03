display.setStatusBar( display.HiddenStatusBar )

system.activate( "multitouch" )

require("physics")

local ui = require("ui")
local NamedObjects = require("NamedObjects")
local NamedEventHandlers = require("NamedEventHandlers")
--local json = require("cadkjson")
require("Json")

require("CollectibleItemsHandlers")  -- application/map specific

physics.start()

-- Load Lime
local lime = require("lime")

-- Load your map
local map = lime.loadMap("tutorial12-fs.tmx")

-------------------------------------------------------------------------------
-- Application specific 

-- Create a background colour just to make the map look a little nicer
local back = display.newRect(0, 0, display.contentWidth, display.contentHeight)
back:setFillColor(165, 210, 255)

local onPlayerProperty = function(property, type, object)
	local STATE_IDLE = "Idle"
	local STATE_WALKING = "Walking"
	local STATE_JUMPING = "Jumping"
	local DIRECTION_LEFT = -1
	local DIRECTION_RIGHT = 1
	local player = object.sprite
	player.state = STATE_IDLE
	player:prepare("anim" .. player.state)
	player:play()
end
map:addPropertyListener("IsPlayer", onPlayerProperty)

-------------------------------------------------------------------------------
-- Generic reusable code 

--- A Lime "registerNameObject" property listener that will register a name-object entry for the object.sprite and the name given in the property value within the context of the map.
local onRegisterNameObjectProperty = function(property, aType, object)
	local aDisplayObject = object.sprite
	if(type(property.value)=="string")then
		NamedObjects.registerNameObject(property.value, aDisplayObject, object.map)
	end
end
map:addPropertyListener("registerNameObject", onRegisterNameObjectProperty)

--- A onTransitionEnd handler that simply removes the underlying display object.
local onTransitionEndRemoveSelf = function(event)
	if(NamedObjects.isDisplayObject(event))then event:removeSelf() end
end
NamedObjects.registerNameObject("onTransitionEndRemoveSelf",onTransitionEndRemoveSelf, "PermanentContext")

--- A Lime "localEventHandler" property listener that will decode the property value to register the specified local event handlers with the target object.sprite.
-- Property.value should be a table or a list of table with keys "event" and "handler". The handler-name will be resolved to a function thru NamedObjects.getObject(handler), which will be registered for the "event-value" with object.sprite.
local onLocalEventHandler = function(property, aType, object)
	local aDisplayObject = object.sprite
	if(property.value==nil)then return end
	local eventPropsA = property.value
	if(type(property.value)=="string")then
		eventPropsA = Json.Decode(property.value)
	end
	if(type(eventPropsA) ~= "table")then 
		print("WARNING - onLocalEventHandler: property.value is not a (json-encoded) table")
		return 
	end
	if(#eventPropsA == 0)then eventPropsA = {eventPropsA} end
	for i,eventProps in ipairs(eventPropsA)do
		if(type(eventProps)=="table" and eventProps.event and eventProps.handler)then
			aDisplayObject:addEventListener(eventProps.event, NamedObjects.getObject(eventProps.handler))
		else
			print("WARNING - onLocalEventHandler: property.value has undecypherable elements")
		end
	end
end
map:addPropertyListener("localEventHandler", onLocalEventHandler)

--- A Lime "globalEventHandler" property listener that will decode the property value to register the specified global event handlers with the specified target.
-- Property.value should be a table or a list of table with keys "target", "event" and "handler". The target-name will be resolved to a target-object and the handler-name will be resolved to a function thru NamedObjects.getObject(handler), which will be registered for the "event-value" with the target-object.
local onGlobalEventHandler = function(property, aType, object)
	local aDisplayObject = object.sprite
	if(property.value==nil)then return end
	local eventPropsA = property.value
	if(type(property.value)=="string")then
		eventPropsA = Json.Decode(property.value)
	end
	if(type(eventPropsA) ~= "table")then 
		print("WARNING - onGlobalEventHandler: property.value is not a (json-encoded) table")
		return 
	end
	if(#eventPropsA == 0)then eventPropsA = {eventPropsA} end
	for i,eventProps in ipairs(eventPropsA)do
		if(type(eventProps)=="table" and eventProps.target and eventProps.event and eventProps.handler)then
			NamedObjects.getObject(eventProps.target):addEventListener(eventProps.event, NamedObjects.getObject(eventProps.handler))
		else
			print("WARNING - onGlobalEventHandler: property.value has undecypherable elements")
		end
	end
end
map:addPropertyListener("globalEventHandler", onGlobalEventHandler)

--- A Lime "tableEventHandler" property listener that will decode the property value to register the specified table event handler with the target object.sprite.
-- Property.value should be a single table with keys "target", "event" and "handler". The target-name will be resolved to a target-object and the handler-name will be resolved to a function thru NamedObjects.getObject(handler). The handler will be installed at the object.sprite[event-value] slot, and the object.sprite will be registered for the "event-value" with the target-object.
local onTableEventHandler = function(property, aType, object)
	local aDisplayObject = object.sprite
	local eventProps = Json.Decode(property.value)
	if(type(eventProps)=="table" and eventProps.target and eventProps.event and eventProps.handler and NamedObjects.isDisplayObject(object.sprite))then
		aDisplayObject[eventProps.event] = NamedObjects.getObject(eventProps.handler)
		NamedObjects.getObject(eventProps.target):addEventListener(eventProps.event, aDisplayObject)
	else
		print("WARNING - onTableEventHandler: property.value has undecypherable elements")
	end
end
map:addPropertyListener("tableEventHandler", onTableEventHandler)

--- Generic button-type object-listener handler that transforms a tile-object into a ui.Button.
-- Registered with map:addObjectListener("UIButton", onUIButtonType), it will transform any tile-object of a "UIButton" type into a ui:newButton. The handler will look for the (optional) property "overButton" to find the tile to use for press-animation. Also, button handlers can be registered by name thru the "buttonHandlers" property, which value should be a json encoded table with the names of the onEvent, onPress and onRelease handler functions.
local onUIButtonType = function(object)
	local map = object.map
	local gid = tonumber(object.gid)
	local oversprite
	-- find the over-button tile to use for the press animation
	local tileNameIDS = object:getObjectTilePropertyValue("overButton")
	if(tileNameIDS)then  -- create sprite for over-button
		local tileNameIDT = (type(tileNameIDS)=="string" and Json.Decode(tileNameIDS)) or {}
		local overgid, ltid = map:getGIDForTileNameID(tileNameIDT.tileSet,tileNameIDT.localTID)
		if(not overgid)then -- assume overtile is local to default tile
			local tileS,tileID = map:getTileSetFromGID( gid )
			overgid = tileS.firstgid + ltid
		end
		oversprite = map:createSprite(overgid)
	end
	-- find the button event handlers to register
	local buttonHandlersS = object:getObjectTilePropertyValue("buttonHandlers")
	local buttonHandlersT = (type(buttonHandlersS)=="string" and Json.Decode(buttonHandlersS)) or {}
	object.sprite = ui.newButton{
		default = object.sprite,
		over = oversprite,
		x = object.x,
		y = object.y,
		onEvent = buttonHandlersT.onEvent,
		onPress = buttonHandlersT.onPress,
		onRelease = buttonHandlersT.onRelease
	}
	-- copy some other properties (look at lime-interface...)?
end
map:addObjectListener("UIButton", onUIButtonType)

-------------------------------------------------------------------------------
-- Lime-Application boilerplate 

-- Create the visual
local visual = lime.createVisual(map)

-- Build the physical
local physical = lime.buildPhysical(map)

