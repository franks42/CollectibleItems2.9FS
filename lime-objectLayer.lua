-- Project: Lime
--
-- Date: 09-Feb-2011
--
-- Version: 2.9
--
-- File name: lime-objectLayer.lua
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

local utils = require("lime-utils")

----------------------------------------------------------------------------------------------------
----									CLASS METATABLE											----
----------------------------------------------------------------------------------------------------

ObjectLayer = {}
ObjectLayer_mt = { __index = ObjectLayer }

----------------------------------------------------------------------------------------------------
----									CLASS VARIABLES											----
----------------------------------------------------------------------------------------------------

ObjectLayer.version = 2.9

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

local utils = lime.utils
local moveObject = utils.moveObject
local dragObject = utils.dragObject
local readInConfigFile = utils.readInConfigFile
local hexToRGB = utils.hexToRGB

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

--- Create a new instance of an ObjectLayer object.
-- @param data The XML data.
-- @param map The current Map object.
-- @return The newly created object layer.
function ObjectLayer:new(data, map)

    local self = {} -- the new instance
    
    setmetatable( self, ObjectLayer_mt ) -- all instances share the same metatable
    
	self.properties = {}
	self.objects = {}
	self.map = map
    
	-- Extract header info, name, width, height	
	for key, value in pairs(data["Attributes"]) do
		self:setProperty(key, value)
	end
	
	local node = nil
	local attributes = nil
	
	-- Loop through all the child nodes
	for i=1, #data["ChildNodes"], 1 do
	
		node = data["ChildNodes"][i]

		if node.Name == "object" then
			self.objects[#self.objects + 1] = Object:new(node, self.map, self)
		elseif node.Name == "properties" then
		
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

--- Sets the value of a Property of the ObjectLayer. 
-- Will create a new Property if none found.
-- @param name The name of the Property.
-- @param value The new value.
function ObjectLayer:setProperty(name, value)
		
	local property = self:getProperty(name)
	
	if property then
		return property:setValue(value)
	else
		self:addProperty(Property:new(name, value))
	end
	
	self[name] = value
end

--- Gets a Property of the ObjectLayer.
-- @param name The name of the Property.
-- @return The Property. nil if no Property found.
function ObjectLayer:getProperty(name)
	return self.properties[name]
end

--- Gets the value of a Property of the ObjectLayer.
-- @param name The name of the Property.
-- @return The Property value. nil if no Property found.
function ObjectLayer:getPropertyValue(name)
	
	local property = self:getProperty(name)
	
	if property then
		return property:getValue()
	end
	
end

--- Gets a list of all Properties of the ObjectLayer.
-- @return The list of Properties.
function ObjectLayer:getProperties()
	return self.properties
end

--- Gets a count of how many properties the Object Layer has.
-- @return The Property count.
function ObjectLayer:getPropertyCount()

	local count = 0
	
	for _k, _v in pairs(self.properties) do
		count = count + 1
	end

	return count
end

--- Checks whether the ObjectLayer has a certain Property.
-- @param name The name of the property to check for.
-- @return True if the ObjectLayer has the Property, false if not.
function ObjectLayer:hasProperty(name)
	return self:getProperty(name) ~= nil
end

--- Adds a Property to the ObjectLayer. 
-- @param property The Property to add.
-- @return The added Property.
function ObjectLayer:addProperty(property)
	self.properties[property:getName()] = property
	
	self[property:getName()] = property:getValue()
	
	return property
end

--- Removes a Property from the ObjectLayer. 
-- @param name The name of the Property to remove.
function ObjectLayer:removeProperty(name)
	self.properties[name] = nil
end

--- Get an object by its name. 
-- @param name The name of the Object to get.
-- @param type The type of the Object to get. Optional.
-- @return The found Object. nil if none found.
function ObjectLayer:getObject(name, type)

	for i=1, #self.objects, 1 do
		
		if(name) then
			
			local object = nil
			
			if(self.objects[i].name == name) then
				
				object = self.objects[i]
				
				if(type) then -- Type specified to check that it is equal
					if(object.type == type) then
						return object
					end
				
				else -- No type specified so just return the object
					return object
				end
				
			end
			
		end
	end
	
	return nil
end
	
--- Get a list of objectd by there name. 
-- @param name The name of the Objects to get.
-- @param type The type of the Objects to get. Optional.
-- @return A list of the found Objects. Empty if none found.
function ObjectLayer:getObjects(name, type)
	
	local objects = {}
		
	for i=1, #self.objects, 1 do
		
		if(name) then
			
			local object = nil
			
			if(self.objects[i].name == name) then
				
				object = self.objects[i]
				
				if(type) then -- Type specified to check that it is equal
					if(object.type == type) then
						objects[#objects + 1] = self.objects[i]
					end
				
				else -- No type specified so just return the object
					objects[#objects + 1] = self.objects[i]
				end
				
			end
			
		end
	end
	
	return objects
end

--- Gets a list of Objects on this ObjectLayer that have a specified property. 
-- @param name The name of the Property to look for.
-- @return A list of found Objects. Empty if none found.
function ObjectLayer:getObjectsWithProperty(name)

	local objects = {}
	
	for i = 1, #self.objects, 1 do
		if self.objects[i]:hasProperty(name) then
			objects[#objects + 1] = self.objects[i]
		end
	end

	return objects
end

--- Gets a list of Objects on this ObjectLayer that have a certain name. 
-- @param name The name of the Object to look for.
-- @return A list of found Objects. Empty if none found.
function ObjectLayer:getObjectsWithName(name)

	local objects = {}
	
	for i = 1, #self.objects, 1 do
		if self.objects[i].name == name then
			objects[#objects + 1] = self.objects[i]
		end
	end

	return objects
end

--- Gets a list of Objects on this ObjectLayer that have a certain type. 
-- @param type - The type of the Object to look for.
-- @return A list of found Objects. Empty if none found.
function ObjectLayer:getObjectsOfType(type)

	local objects = {}
	
	for i = 1, #self.objects, 1 do
		if self.objects[i].type == type then
			objects[#objects + 1] = self.objects[i]
		end
	end

	return objects
end

--- Moves the ObjectLayer.
-- @param x The amount to move the ObjectLayer along the X axis.
-- @param y The amount to move the ObjectLayer along the Y axis.
function ObjectLayer:move(x, y)
	moveObject(self, x, y)
	
	for i=1, #self.objects, 1 do
		self.objects[i]:move(x, y)
	end
end


--- Drags the ObjectLayer.
-- @param event The Touch event.
function ObjectLayer:drag(event)
	dragObject(self, event)
	
	for i=1, #self.objects, 1 do
		self.objects[i]:drag(x, y)
	end	
end

--- Shows all debug images on the ObjectLayer.
function ObjectLayer:showDebugImages()
	
	for i=1, #self.objects, 1 do 
		self.objects[i]:showDebugImage()
	end
end

--- Hides all debug images on the ObjectLayer.
function ObjectLayer:hideDebugImages()

	for i=1, #self.objects, 1 do 
		self.objects[i]:hideDebugImage()
	end
end

--- Toggles the visibility of all debug images on the ObjectLayer.
function ObjectLayer:toggleDebugImagesVisibility()
	
	for i=1, #self.objects, 1 do 
		self.objects[i]:toggleDebugImageVisibility()
	end
	
end	

--- Creates the visual debug representation of the ObjectLayer.
function ObjectLayer:create()
	
	-- Display group used for debug visuals
	self.group = display.newGroup()
		
	local object = nil
	local listeners = nil
		
	local hexValue = nil
	
	if self.color then
		local strippedHex = utils.splitString(self.color, "#")

		if strippedHex[2] then
			hexValue = strippedHex[2]
		end					
	end
	
	self.color = hexToRGB(hexValue or "A0A0A4")
	
	for j=1, #self.objects, 1 do
		self.objects[j]:create(self)				
	end
	
	self.map.world:insert(self.group)
	
	if self.visible then
		if self.visible == "0" then
			self.group.isVisible = false
		end
	end
	
	for key, value in pairs(self.properties) do
		self.map:firePropertyListener(self.properties[key], "objectLayer", self)
	end	
	
end

--- Builds the physical representation of the ObjectLayer.
function ObjectLayer:build()

	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Building Object Layer - " .. self.name)
	end	
	
	for i=1, #self.objects, 1 do
		
		if( self.objects[i].type == "Body" or self.objects[i]:hasProperty("HasBody") ) then
			self.objects[i]:build()
		end
		
	end
	
end

--- Completely removes all visual and physical objects associated with the TileLayer.
function ObjectLayer:destroy()

	if self.group and self.objects then
	
		for i=1, #self.objects, 1 do	
			self.objects[i]:destroy()
		end
		
		self.objects = nil
		
		self.group:removeSelf()
		self.group = nil
	end

end
