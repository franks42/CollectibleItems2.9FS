-- Project: Lime
--
-- Date: 09-Feb-2011
--
-- Version: 2.9
--
-- File name: lime-object.lua
--
-- Author: Graham Ranson 
--
-- Support: www.justaddli.me
--
-- Copyright (C) 2011 MonkeyDead Studios Limited. All Rights Reserved.

----------------------------------------------------------------------------------------------------
----									POLITE NOTICE / PSA										----
----------------------------------------------------------------------------------------------------
----																							----
----	I have put a lot of work into this library and plan to support it for a very, very		---- 
----	long time so please don't give the code to anyone else. I doubt that anyone would as	----
----	we are all developers in the same boat but I just thougt I would put this here in 		----
----	case any one wondered if it was ok to share.											----
----																							----
----	If you did get this code through less than legitimate means then please consider		----
----	buying it legally, it is (I think) affordably priced and you will get free updates		----
----	and support	for life.																	----
----																							----
----	I hope you enjoy using it as much as I have enjoyed writing it and I also hope that		----
----    you will support me and the development of Lime by telling your friends about it etc	----
----	although naturally I don't require any link backs of any kind, it is completely up		----
----	to you.																					----
----																							----
----	If you have any additions or fixes that you would like included in the main releases	----
----	please contact me via the forums or email - graham@grahamranson.co.uk					----
----																							----
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
----									REQUIRED MODULES										----
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
----									CLASS METATABLE											----
----------------------------------------------------------------------------------------------------

Object = {}
Object_mt = { __index = Object }

----------------------------------------------------------------------------------------------------
----									CLASS VARIABLES											----
----------------------------------------------------------------------------------------------------

Object.version = 2.9

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

local utils = lime.utils
local calculateViewpoint = utils.calculateViewpoint
local round = utils.round
local clampPosition = utils.clampPosition
local moveObject = utils.moveObject
local dragObject = utils.dragObject
local readInConfigFile = utils.readInConfigFile
local addObjectToGroup = utils.addObjectToGroup
local copyPropertiesToObject = utils.copyPropertiesToObject
local stringToBool = utils.stringToBool
local addPropertiesToBody = utils.addPropertiesToBody
local addCollisionFilterToBody = utils.addCollisionFilterToBody
local applyPhysicalParametersToBody = utils.applyPhysicalParametersToBody
local splitString = utils.splitString

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

--- Create a new instance of an Object object.
-- @param data The XML data.
-- @param map The current Map object.
-- @param objectLayer The ObjectLayer the the Object resides on.
-- @return The newly created object instance.
function Object:new(data, map, objectLayer)

    local self = {}    -- the new instance
    
    setmetatable( self, Object_mt ) -- all instances share the same metatable
    
    self.properties = {}
    self.map = map
    self.objectLayer = objectLayer
    
    -- Extract header info, name, x, y, width, height	
	for key, value in pairs(data['Attributes']) do
		self:setProperty(key, value)
	end
	
	local node = nil
	local attributes = nil
	
	-- Loop through all the child nodes
	for i=1, #data["ChildNodes"], 1 do
		
		node = data["ChildNodes"][i]
		
		if node.Name == "properties" then
		
			-- Loop through all the child nodes
			for j=1, #node["ChildNodes"], 1 do
				
				-- Each child node is a property, the attributes are the name and value
				attributes = node["ChildNodes"][j]["Attributes"]
				
				if attributes then	
					if attributes.name == "configFile" then
						readInConfigFile(attributes.value, self)	
					else
						property = self:setProperty(attributes.name, attributes.value)
					end
				end
				
			end
			
		end
		
	end

    return self
    
end

--- Sets the position of the Object.
-- @param x The new X position of the Object.
-- @param y The new Y position of the Object.
function Object:setPosition(x, y)
	self.x = x
	self.y = y
end

--- Gets the position of the Object.
-- @return The X position of the Object.
-- @return The Y position of the Object.
function Object:getPosition()
	return self.x, self.y
end

--- Sets the value of a Property of the Object. Will create a new Property if none found.
-- @param name The name of the Property.
-- @param value The new value.
-- @return
function Object:setProperty(name, value)
		
	local property = self:getProperty(name)

	if property then
		return property:setValue(value)
	else
		self:addProperty(Property:new(name, value))
	end
	
	self[name] = value
end

--- Gets a Property of the Object.
-- @param name The name of the Property.
-- @return The Property. nil if no Property found.
function Object:getProperty(name)
	return self.properties[name]
end

--- Gets the value of a Property of the Object.
-- @param name The name of the Property.
-- @return The Property value. nil if no Property found.
function Object:getPropertyValue(name)
	
	local property = self:getProperty(name)
	
	if property then
		return property:getValue()
	end
	
end

--- Gets a list of all Properties of the Object.
-- @return The list of Properties.
function Object:getProperties()
	return self.properties
end

--- Gets the value of a property on a tile object.
--	Originally created by FrankS - http://developer.anscamobile.com/forum/2011/02/19/additional-convenience-functions-navigate-lime-world-tree
-- @param name The name of the property to look for.
-- @return The value of the property. Nil if none found.
function Object:getObjectTilePropertyValue(name)

	if name then
	
		if self[name] then -- local object property
		
			return self[name]
			
		else  -- return the associated tile property value (if it exists)
		
			return self.map:getTilePropertyValueForGID(self.gid, name)
			
		end
	end
	
end

--- Gets a count of how many properties the Object has.
-- @return The Property count.
function Object:getPropertyCount()

	local count = 0
	
	for _k, _v in pairs(self.properties) do
		count = count + 1
	end

	return count
end

--- Checks whether the Object has a certain Property.
-- @param name The name of the property to check for.
-- @return True if the Object has the Property, false if not.
function Object:hasProperty(name)
	return self:getProperty(name) ~= nil
end

--- Adds a Property to the Object. 
-- @param property The Property to add.
-- @return The added Property.
function Object:addProperty(property)
	self.properties[property:getName()] = property
	
	self[property:getName()] = property:getValue()
	
	return property
end

--- Removes a Property from the Object. 
-- @param name The name of the Property to remove.
function Object:removeProperty(name)
	self.properties[name] = nil
end

--- Moves the Object.
-- @param x The amount to move the Object along the X axis.
-- @param y The amount to move the Object along the Y axis.
function Object:move(x, y)
	moveObject(self, x, y)
end

--- Drags the Object.
-- @param The Touch event.
function Object:drag(event)
	dragObject(self, event)
end

--- Shows the debug image of this Object.
function Object:showDebugImage()
	
	if self.debugImage then
		self.debugImage.isVisible = true
	end
	
end

--- Hides the debug image of this Object.
function Object:hideDebugImage()

	if self.debugImage then
		self.debugImage.isVisible = false
	end
	
end

--- Checks if the debug image of this Object is visible or not.
-- @return True if it is, false if not.
function Object:isDebugImageVisible()

	if self.debugImage then
		return self.debugImage.isVisible
	end
	
end

--- Toggles the visibility of the debug image of this Object.
function Object:toggleDebugImageVisibility()
	
	if self.debugImage then
		
		if self:isDebugImageVisible() then
			self:hideDebugImage()
		else
			self:showDebugImage()
		end
		
	end
	
end	

--- Creates the visual debug representation of the Object.
function Object:create()

	-- If an object has a GID then it is one of the new TileObjects brought into Tiled version 0.6.0
	if self:hasProperty("gid") then
		
		-- Get the correct tileset using the GID
		self.tileSet = self.map:getTileSetFromGID( self:getPropertyValue("gid") )
		
		if self.tileSet then
		
			-- Create the actual Corona sprite object
			self.sprite = sprite.newSprite(self.tileSet.spriteSet)
			
			-- Set the sprites frame to the current tile in the tileset
			self.sprite.currentFrame = self.gid - (self.tileSet.firstgid) + 1
			
			if(self.map.orientation == "orthogonal" ) then

				-- Place this tile in the right X position
				self.sprite.x = self.x
				
				-- Place this tile in the right Y position
				self.sprite.y = self.y
				
			elseif(self.map.orientation == "isometric") then

			end
	
			-- Copy over the properties to the sprite
			copyPropertiesToObject(self, self.sprite)
			 
			-- Add the sprite to the group
			self.objectLayer.group:insert(self.sprite)
			
		end
					
	else
		if self.width and self.height then -- Create a rounded rectangle for the debug image
			self.debugImage = display.newRoundedRect(self.objectLayer.group, self.x, self.y, self.width, self.height, 5)
		else -- Create a circle
			self.debugImage = display.newCircle( self.objectLayer.group, self.x, self.y, 10 )
		end
		
		self.debugImage.strokeWidth = 2
		self.debugImage:setFillColor( self.objectLayer.color.r, self.objectLayer.color.g, self.objectLayer.color.b, 50 )
		self.debugImage:setStrokeColor( self.objectLayer.color.r, self.objectLayer.color.g, self.objectLayer.color.b )
		self.debugImage.isVisible = false
		
		if self.map["Objects:DisplayDebug"] then
			if stringToBool(self.map["Objects:DisplayDebug"]) == true then
				self.debugImage.isVisible = true
			end
		end
	end
	
	self.map:fireObjectListener(self)
		
	for key, value in pairs(self.properties) do
		self.map:firePropertyListener(self.properties[key], "object", self)
	end
	
end

--- Builds the physical representation of the Object.
function Object:build()
	
	local body = nil
	
	if not self.map.world then
		self.map.world = display.newGroup()
	end
	
	if (self.sprite) then
		
		body = self.sprite

	elseif(self.radius) then
	
		body = display.newCircle( self.map.world, self.x, self.y, self.radius )
	
	elseif(self.points) then			
		
		local pointObjectNames = nil
		
		if type(self.points) == "string" then
			pointObjectNames = splitString(self.points, ",")
		elseif type(self.points) == "table" then
			pointObjectNames = self.points
		end
		
		if pointObjectNames then
	
			local objects = {}
			self.shape = {}
			
			for i=1, #pointObjectNames, 1 do
				local pointObject = self.objectLayer:getObject(pointObjectNames[i])
				
				if pointObject then
					objects[#objects + 1] = pointObject
				end
			end
			
			-- Make sure there are enough points (2 entries for each point)
			if(#objects > 1) then
	
				body = display.newLine( self.map.world, objects[1].x, objects[1].y, objects[2].x, objects[2].y )
	
				if(body) then
					for i=3, #objects, 1 do
						body:append( objects[i].x, objects[i].y )	
					end
				end
			end
			
			-- Rejoin the shape
			if objects[1] ~= objects[#objects] then
				body:append( objects[1].x, objects[1].y )
			end
					
			body.width = 3 
			body:setColor( 0, 2.6, 0 )
			
			
			for i=1, #objects, 1 do
				local pointObject = objects[i]
				
				-- Add the shape points and make sure to offset it so that it is created in the right place
				if pointObject then
					self.shape[#self.shape + 1] = pointObject.x - body.x
					self.shape[#self.shape + 1] = pointObject.y	- body.y
				end
				
			end
			
			self.shapeObjects = objects
		end
	
	elseif(self.shape) then	

		if type(self.shape) == "string" then
		
            local splitShape = splitString(self.shape, ",")
            
            if #splitShape > 1 then
   
                local shape = {}
                
                for i = 1, #splitShape, 1 do
                	shape[#shape + 1] = tonumber(splitShape[i])
                end
               
               	body = display.newRect( self.map.world, self.x, self.y, self.width or 1, self.height or 1 ) 
              	
              	self.shape = shape
              	
              	--[[
               	if #shape >= 6 then
               		
               		body = display.newLine(self.map.world, shape[1], shape[2], shape[3], shape[4] )
               		body.strokeWidth = 1
               		
               		for i = 5, #shape, 2 do
               			body:append(shape[i], shape[i+1])
               		end
               		
               		body:append(shape[1], shape[2])
               		
               	end
            	--]]
            	
            end
        end		
        
	else	
		body = display.newRect( self.map.world, self.x, self.y, self.width or 1, self.height or 1 ) 
	end

	if(body) then

		addPropertiesToBody(body, self)
		
		body.isVisible = false
		
		if self.gid or self.sprite then
			body.isVisible = true
		end
		
		self.isSensor = stringToBool(self.isSensor)
					
		addCollisionFilterToBody( self )		
				
		physics.addBody( body, self )

		applyPhysicalParametersToBody(body, self)
		
		self.rotation = self.rotation or 0
		
		body.type = self.type
		body.name = self.name
		
		if not self.shape then
			body.x = body.x + body.width * 0.5
			body.y = body.y + body.height * 0.5
		end
		
		self.body = body

		self.map.world:insert(self.body)
	end
		
end

--- Completely removes all visual and physical objects associated with the Object.
function Object:destroy()

	if self.debugImage then
		self.debugImage:removeSelf()
		self.debugImage = nil
	end
	
	if self.body then
		self.body:removeSelf()
		self.body = nil
	end

end
