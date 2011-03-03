-- Project: Lime
--
-- Date: 09-Feb-2011
--
-- Version: 2.9
--
-- File name: lime-tile.lua
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

require("sprite")

----------------------------------------------------------------------------------------------------
----									CLASS METATABLE											----
----------------------------------------------------------------------------------------------------

Tile = {}
Tile_mt = { __index = Tile }

----------------------------------------------------------------------------------------------------
----									CLASS VARIABLES											----
----------------------------------------------------------------------------------------------------

Tile.version = 2.9

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

local utils = lime.utils
local moveObject = utils.moveObject
local dragObject = utils.dragObject
local readInConfigFile = utils.readInConfigFile

local contentWidth = display.contentWidth
local contentHeight = display.contentHeight

local newSpriteSet = sprite.newSpriteSet
local newSprite = sprite.newSprite

local stringToBool = utils.stringToBool
local splitString = utils.splitString

local copyPropertiesToObject = utils.copyPropertiesToObject
local addPropertiesToBody = utils.addPropertiesToBody
local addCollisionFilterToBody = utils.addCollisionFilterToBody
local applyPhysicalParametersToBody = utils.applyPhysicalParametersToBody

----------------------------------------------------------------------------------------------------
----									PRIVATE METHODS											----
----------------------------------------------------------------------------------------------------

local newSpriteSequence = function(spriteSet, sequenceName, startFrame, frameCount, time, loopCount)
	sprite.add( spriteSet, sequenceName, startFrame, frameCount, time, loopCount)
end

local newSpriteSequenceFromString = function(tile, sequenceName, string)
	if(string) then
		local sequence = {}
		string = splitString(string, ",")
		
		for i=1, #string, 1 do
			local param = splitString(string[i], "=")
			
			sequence[param[1]] = param[2]
		end
	
		newSpriteSequence(tile.spriteSet, sequenceName, (sequence.startFrame or 1), sequence.frameCount, sequence.time, sequence.loopCount)
	end
end

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

--- Create a new instance of a Tile object.
-- @param data The XML data.
-- @param map The current Map object.
-- @param layer The TileLayer the the Tile resides on.
-- @return The newly created tile.
function Tile:new(data, map, layer)

    local self = {}    -- the new instance

    setmetatable( self, Tile_mt ) -- all instances share the same metatable
    
    self.properties = {}
    self.map = map
    self.layer = layer
    
   	-- Pull out all the details off this tile, currently it just seems to be the GID however Tiled may add more later.
	for key, value in pairs(data['Attributes']) do 
		if key == "gid" then
			self[key] = value
		else
			self:setProperty(key, value)
		end
	end
	
    return self
    
end

--- Sets the image of the Tile from a Tileset.
-- @param gid The gid of the tile image.
-- @usage Originally created by Mattguest - http://developer.anscamobile.com/forum/2011/02/02/settile-function
function Tile:setImage(gid)	

	-- Make sure there is a sprite
	if self.sprite then
		
		-- Calculate the tile index
		--local index = self.map.width * ( tile.row - 1 ) + tile.column
		local index = self.index
		
		local map = self.map
		local tileLayer = self.layer
		
		-- Destroy the tile
		self:destroy()
		
		-- Fake the XML data
		local data = {}
		data["Attributes"] = {}
		data["Attributes"].gid = gid
	
		data["Attributes"].gid = tonumber(data["Attributes"].gid)
		
		-- Create the tile object
		self = Tile:new(data, map, tileLayer)
		
		-- Add the tile to the tile list
		tileLayer.tiles[index] = tile
	
		-- Create the tile visual
		self:create(index)
		
		-- Build the tile physical
		self:build()
		
	end

end

--- Sets the value of a Property of the Tile. 
-- Will create a new Property if none found.
-- @param name The name of the Property.
-- @param value The new value.
function Tile:setProperty(name, value)
		
	local property = self:getProperty(name)
	
	if property then
		property:setValue(value)
	else
		self:addProperty(Property:new(name, value))
	end
	
	self[name] = value
end

--- Gets a Property of the Tile.
-- @param name The name of the Property.
-- @return The Property. nil if no Property found.
function Tile:getProperty(name)

	if not self.properties then
		self.properties = {}
	end
	
	return self.properties[name]
end

--- Gets the value of a Property of the Tile.
-- @param name The name of the Property.
-- @return The Property value. nil if no Property found.
function Tile:getPropertyValue(name)
	
	local property = self:getProperty(name)
	
	if property then
		return property:getValue()
	end
	
end

--- Gets a list of all Properties of the Tile.
-- @return The list of Properties.
function Tile:getProperties()
	return self.properties
end

--- Gets a count of how many properties the Tile has.
-- @return The Property count.
function Tile:getPropertyCount()

	if not self.properties then
		self.properties = {}
	end
	
	local count = 0
	
	for _k, _v in pairs(self.properties) do
		count = count + 1
	end

	return count
end

--- Checks whether the Tile has a certain Property.
-- @param name The name of the property to check for.
-- @return True if the Tile has the Property, false if not.
function Tile:hasProperty(name)
	return self:getProperty(name) ~= nil
end

--- Adds a Property to the Tile. 
-- @param property The Property to add.
-- @return The added Property.
function Tile:addProperty(property)

	if not self.properties then
		self.properties = {}
	end
	
	self.properties[property:getName()] = property
	
	self[property:getName()] = property:getValue()
	
	return property
end

--- Removes a Property from the Tile. 
-- @param name The name of the Property to remove.
function Tile:removeProperty(name)

	if not self.properties then
		self.properties = {}
	end
	
	self.properties[name] = nil
end

--- Moves the Tile.
-- @param x The amount to move the Tile along the X axis.
-- @param y The amount to move the Tile along the Y axis.
function Tile:move(x, y)
	moveObject(self, x, y)
end

--- Drags the Tile.
-- @param The Touch event.
function Tile:drag(event)
	dragObject(self, event)
end

--- Gets the world position of the Tile. 
-- @return The X position of the Tile or nil if there is no sprite
-- @return The Y position of the Tile or nil if there is no sprite
function Tile:getWorldPosition()

	-- Extra checks suggested by Pavel Nakaznenko
	if(self.sprite and self.sprite.parent and self.sprite.isVisible) then
					
		local x = self.sprite.x + self.map.world.x
		local y = self.sprite.y + self.map.world.y
	
		return x, y
		
	end
	
	return nil
end
	
--- Checks whether the Tile is currently on screen.
-- @return True if the Tile is on screen, false if not.
function Tile:isOnScreen()

	if self.sprite then
	
		local worldX, worldY = self:getWorldPosition()
		
		if(worldX and worldY) then
			if((worldX + self.sprite.width) < 0 or (worldX - self.sprite.width) > contentWidth) then
				return false
			elseif((worldY + self.sprite.height) < 0 or (worldY - self.sprite.height) > contentHeight) then
				return false
			end	
		
			return true
		end
		
	end
	
	return nil
end

--- Creates the visual representation of the Tile.
-- @param index The Tile number. Not the gid.
function Tile:create(index)
	
	self.index = index
	
	if(self.gid) then
	
		self.gid = tonumber(self.gid)
	
		if(self.gid ~= 0) then -- If it is 0 then there is no tile in this spot
			local tileSetIndex = 1
			local tileSet = self.map:getTileSet(tileSetIndex)
			
			if(tileSet) then
				-- If the GID is higher then the amount of tiles in this tileset then it must be in the next tileset (and so on)	
				while(self.gid + 1 > tileSet.tileCount + tileSet.firstgid) do
					tileSetIndex = tileSetIndex + 1
					tileSet = self.map.tileSets[tileSetIndex]
				end
			end
		
			if(tileSet) then
				
				self.tileSet = tileSet
				
				-- Get all the properties this tile should have from the tilese
				local properties = tileSet:getPropertiesForTile(self.gid)
				
				for i=1, #properties, 1 do
				
					-- Read in the Config file data if it has one, otherwise it is a normal property
					if properties[i].name == "configFile" then
						readInConfigFile(properties[i].value, self)
					else	
						self:addProperty(properties[i])	
					end	
									
				end

				-- Is this tile animated?
				if(self.IsAnimated) then
					self.startFrame = self.startFrame or (self.gid - (tileSet.firstgid) + 1)
			
					self.spriteSet = newSpriteSet(tileSet.spriteSheet, self.startFrame, (self.frameCount or (tileSet.tileCount - self.startFrame)), self.loopCount)
					self.sprite = newSprite( self.spriteSet )
						
					-- Does this tile have a set of sequences?				
					if(self.sequences) then
											
						if type(self.sequences) == "string" then
							self.sequences = utils.splitString(self.sequences, ",")
						elseif type(self.sequences) == "table" then
							
						end		
												
						-- Create all the sprite sequences	
						for i=1, #self.sequences, 1 do
							if(self[self.sequences[i]]) then
								newSpriteSequenceFromString(self, self.sequences[i], self[self.sequences[i]])
							end
						end

					else
		
		
						-- If the tile has a "frameTime" then create a single sequence allowing it to be time based, otherwise it will just be frame based.
						if self.frameTime then
							sprite.add( self.spriteSet, "DEFAULT", 1, self.frameCount, self.frameTime or 1000, self.loopCount)
							self.sprite:prepare("DEFAULT")
						end
						
						self.sprite:play()
					end
					
				
				else
				
					-- Create the actual Corona sprite object
					self.sprite = newSprite(tileSet.spriteSet)

					-- Set the sprites frame to the current tile in the tileset
					self.sprite.currentFrame = self.gid - (tileSet.firstgid) + 1
				end
								
				-- Calculate and set the row position of this tile in the map
				self.row = math.floor((index + self.layer.width - 1) / self.layer.width)
				
				-- Calculate and set the column position of this tile in the map
				self.column = index - (self.row - 1) * self.layer.width
				
				self.sprite.xReference = self.xReference or self.sprite.xReference
				self.sprite.yReference = self.yReference or self.sprite.yReference
				
				if(self.map.orientation == "orthogonal" ) then
	
					-- Place this tile in the right X position
					--self.sprite.x = ( ( self.column - 1) * self.map.tilewidth ) + self.sprite.width  * 0.5
					--self.sprite.x = ( ( self.column - (1 / display.contentScaleX) ) * self.map.tilewidth ) + self.sprite.width  * 0.5                    

if self.tileSet.usingHDSource then
        self.sprite.x = ( ( self.column - (1 / display.contentScaleX)) * self.map.tilewidth ) + self.sprite.width  * 0.5
else
        self.sprite.x = ( ( self.column - 1 ) * self.map.tilewidth ) + self.sprite.width  * 0.5
end 

					-- Place this tile in the right Y position
					self.sprite.y = ( self.row * self.map.tileheight ) - self.sprite.height * 0.5
					
				elseif(self.map.orientation == "isometric") then

					-- Place this tile in the right X position
					self.sprite.x = (self.column - self.row) * (self.map.tilewidth * 0.5)

					-- Place this tile in the right Y position
					self.sprite.y = (self.column + self.row) * (self.map.tileheight * 0.5)
				end
				
				-- Apply sprite properties
				self.sprite.alpha = self.alpha or 1
				self.sprite.isHitTestable = stringToBool(self.isHitTestable) or true
				
				self.sprite.xOrigin = self.xOrigin or self.sprite.xOrigin
				self.sprite.yOrigin = self.yOrigin or self.sprite.yOrigin
			
				self.sprite.rotation = self.rotation or 0
				self.sprite.x = (self.x or self.sprite.x) + (self.xOffset or 0) 
				self.sprite.y = (self.y or self.sprite.y) + (self.yOffset or 0)
				
				-- Adjust the scale and position for Retina display
				if display.contentScaleX == 0.5 and self.tileSet.usingHDSource == true then
			
					-- Scale the sprite back down to 0.5			
					self.sprite.xScale = self.xScale or 0.5
					self.sprite.yScale = self.yScale or 0.5
				
					-- Readjust the position
					self.sprite.x = self.sprite.x + self.sprite.width / 4
					self.sprite.y = self.sprite.y + self.sprite.height / 4
					
				else
					self.sprite.xScale = self.xScale or 1
					self.sprite.yScale = self.yScale or 1	
				end
				
				if _G.limeScreenCullingEnabled then
					self.sprite.isVisible = false
				else
					self.sprite.isVisible = stringToBool(self.isVisible) or true
				end
				
				if self.xTileOffset then
					self.sprite.x = self.sprite.x + (self.xTileOffset * self.sprite.width) 
				end
				
				if self.yTileOffset then
					self.sprite.y = self.sprite.y + (self.yTileOffset * self.sprite.height)
				end
				
				-- Correctly add the tile to the tileGrid of the layer
				if(self.gid ~= 0) then
				
					if(not self.layer.tileGrid) then
						self.layer.tileGrid = {}
					end
					
					if self.column and self.row then
					
						if(not self.layer.tileGrid[self.column]) then
							self.layer.tileGrid[self.column] = {}
						end	
					
						if(not self.layer.tileGrid[self.column][self.row]) then
							self.layer.tileGrid[self.column][self.row] = {}
						end
	
						self.layer.tileGrid[self.column][self.row] = self
					end
					
				end
				
				-- Add the sprite to the layer group
				if self.layer.group then
					self.layer.group:insert(self.sprite)
				end
				
				-- Make sure these are fired after the tile is created so that there is a sprite object
				for key, value in pairs(self.properties) do
					self.map:firePropertyListener(self.properties[key], "tile", self)	
				end
				
				-- Convert HasBody to a boolean value allowing explicit true/false setting. Blank is considered true as to not break old code.
				if self.HasBody then
	
					if self.HasBody == "" then
						self.HasBody = "true"
					end
					
					self.HasBody = stringToBool( self.HasBody )
				end
				
			end
		end
	end
	
end

--- Builds the physical representation of the Tile.
function Tile:build()

	if(self.HasBody and self.sprite) then
		
		local body = self.sprite
		
		if(self.shape) then	
	
			if type(self.shape) == "string" then
			
				local splitShape = splitString(self.shape, ",")
				
				if #splitShape > 1 then
	   
					local shape = {}
					
					for i = 1, #splitShape, 1 do
						shape[#shape + 1] = tonumber(splitShape[i])
					end
				   
					self.shape = shape
					
				end
			end		
		end
		
		-- Now that tiles can be set at runtime it is important to make sure physics is loaded as it may not have been at load time
		if not physics then
			require("physics")
			physics.start()
		end
		
		self.isSensor = stringToBool(self.isSensor)
		
		-- If using Retina, half the tile size so the physics body is correct
		if self.tileSet.tileXScale ~= 1 or self.tileSet.tileXScale ~= 1 then
			
			self.sprite.width = self.sprite.width / self.tileSet.tileXScale
			self.sprite.height = self.sprite.height / self.tileSet.tileYScale

		end

		addCollisionFilterToBody( self )
		
		physics.addBody( body, self ) 
		
		applyPhysicalParametersToBody(body, self)
		
		addPropertiesToBody(body, self)
		
		-- If using Retina, set the size back to original
		if  self.tileSet.tileXScale ~= 1 or self.tileSet.tileXScale ~= 1 then	
		
			self.sprite.width = self.sprite.width * self.tileSet.tileXScale
			self.sprite.height = self.sprite.height * self.tileSet.tileYScale

		end
	end
end

--- Completely removes all visual and physical objects associated with the Tile.
function Tile:destroy()

	-- Destroy the properties
 	if self.properties then
 		self.properties = nil
    end
 
 	-- Destroy the sprite object
	if self.sprite then
		self.sprite:removeSelf()
		self.sprite = nil
	end
	
end
