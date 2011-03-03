-- Project: Lime
--
-- Date: 09-Feb-2011
--
-- Version: 2.9
--
-- File name: lime-tileLayer.lua
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

TileLayer = {}
TileLayer_mt = { __index = TileLayer }

----------------------------------------------------------------------------------------------------
----									CLASS VARIABLES											----
----------------------------------------------------------------------------------------------------

TileLayer.version = 2.9

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

local utils = lime.utils
local moveObject = utils.moveObject
local dragObject = utils.dragObject
local calculateViewpoint = utils.calculateViewpoint
local round = utils.round
local clampPosition = utils.clampPosition
local worldToGridPosition = utils.worldToGridPosition
local addObjectToGroup = utils.addObjectToGroup
local readInConfigFile = utils.readInConfigFile
local splitString = utils.splitString

----------------------------------------------------------------------------------------------------
----									PRIVATE METHODS											----
----------------------------------------------------------------------------------------------------

--- Parse layer data (GIDs) from a CSV string.
-- @params data The CSV string.
-- @returns A list of parsed GIDs.
local getTileIDsFromCSV = function(data)
	local IDs = {}
	
	if(data) then
		return splitString(data, ",")
	end
end

--- Parse layer data (GIDs) from a compressed string string.
-- @params layer The TileLayer object.
-- @params data The compressed string.
local getTileIDsFromBase64 = function(layer, data)

	if(layer.compression == "uncompressed") then
		print("Lime-Lychee: Base64 (Uncompressed) - Currently Unsupported!")
	elseif(layer.compression == "gzip") then
		print("Lime-Lychee: Base64 (GZip Compressed) - Currently Unsupported!")
	elseif(layer.compression == "zlib") then
		print("Lime-Lychee: Base64 (ZLib Compressed) - Currently Unsupported!")
	end
end

--- Gets a tile that is at a  grid position on this layer.
-- @params tileList The list of tiles. 2D array of grid positions.
-- @params position The grid position to look for.
-- @return The found tile or nil if none found.
local getTileAt = function(tileList, position)
	if(tileList) then
		if(tileList[position.column]) then
			if(tileList[position.column][position.row]) then
				return tileList[position.column][position.row]
			end
		end
	end
end

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

--- Create a new instance of a TileLayer object.
-- @param data The XML data.
-- @param map The current Map object.
-- @return The newly created tileLayer.
function TileLayer:new(data, map)
			
    local self = {}    -- the new instance
    
    setmetatable( self, TileLayer_mt ) -- all instances share the same metatable

    self.properties = {}
    self.tiles = {}
    self.map = map
    
    -- Extract the header info, name, height and width
	for key, value in pairs(data['Attributes']) do 
		self:setProperty(key, value)
	end	
	
	local node = nil
	local attributes = nil
	local childNode = nil	
	
	-- Loop through all the child nodes
	for i=1, #data["ChildNodes"], 1 do
		
		node = data["ChildNodes"][i]
		
		if node.Name == "data" then
			
			if node['Attributes'] then
				local encoding = node['Attributes'].encoding or "xml"
				self:setProperty("encoding", encoding)
				
				local compression = node['Attributes'].compression or "uncompressed"
				self:setProperty("compression", compression)
			end
			
			local tileIDs = {}
			
			if(self.encoding == "xml") then
			
				-- Loop through all the child nodes
				for j=1, #node["ChildNodes"], 1 do
					
					childNode = node["ChildNodes"][j]
					
					self.tiles[#self.tiles + 1] = Tile:new(childNode, self.map, self)
							
					tileIDs = nil
				end
				
			else
			
				if(self.encoding == "csv") then
					tileIDs = getTileIDsFromCSV(node.Value)
				elseif(self.encoding == "base64") then
					tileIDs = getTileIDsFromBase64(self, node.Value)
				end
				
				if(tileIDs) then -- Now create the tiles
					for i=1, #tileIDs, 1 do

						local data = {}
						data["Attributes"] = {}
						data["Attributes"].gid = tileIDs[i]
					
						if(data["Attributes"].gid) then
							data["Attributes"].gid = tonumber(data["Attributes"].gid)
							self.tiles[#self.tiles + 1] = Tile:new(data, self.map, self)
						end
					end
				end	
				
			end
			
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

--- Sets the value of a Property of the TileLayer. 
-- Will create a new Property if none found.
-- @param name The name of the Property.
-- @param value The new value.
-- @return The new value.
function TileLayer:setProperty(name, value)
		
	local property = self:getProperty(name)
	
	if property then
		return property:setValue(value)
	else
		self:addProperty(Property:new(name, value))
	end
	
	self[name] = value
end

--- Gets a Property of the TileLayer.
-- @param name The name of the Property.
-- @return The Property. nil if no Property found.
function TileLayer:getProperty(name)
	return self.properties[name]
end

--- Gets the value of a Property of the TileLayer.
-- @param name The name of the Property.
-- @return The Property value. Nil if no Property found.
function TileLayer:getPropertyValue(name)
	
	local property = self:getProperty(name)
	
	if property then
		return property:getValue()
	end
	
end

--- Gets a list of all Properties of the TileLayer.
-- @return The list of Properties.
function TileLayer:getProperties()
	return self.properties
end

--- Gets a count of how many properties the Tile Layer has.
-- @return The Property count.
function TileLayer:getPropertyCount()

	local count = 0
	
	for _k, _v in pairs(self.properties) do
		count = count + 1
	end

	return count
end

---Checks whether the TileLayer has a certain Property.
-- @param name The name of the property to check for.
-- @return True if the TileLayer has the Property, false if not.
function TileLayer:hasProperty(name)
	return self:getProperty(name) ~= nil
end

--- Adds a Property to the TileLayer. 
-- @param property The Property to add.
-- @return The added Property.
function TileLayer:addProperty(property)
	self.properties[property:getName()] = property
	
	self[property:getName()] = property:getValue()
	
	return property
end

--- Removes a Property from the TileLayer. 
-- @param: name The name of the Property to remove.
function TileLayer:removeProperty(name)
	self.properties[name] = nil
end

--- Shows the TileLayer.
function TileLayer:show()
	for i=1, #self.tiles, 1 do	
		if self.tiles[i].sprite then
			self.tiles[i].sprite.isVisible = true
		end		
	end	
end

--- Hides the TileLayer.
function TileLayer:hide()
	for i=1, #self.tiles, 1 do
		if self.tiles[i].sprite then
			self.tiles[i].sprite.isVisible = false
		end		
	end
end

--- Gets a Tile on this TileLayer at a specified position.
-- @param position The position of the Tile. A table containing either x & y or row & column.
-- @return The found Tile. nil if none found.
function TileLayer:getTileAt(position)
	
	if(position.row and position.column) then
		
		return getTileAt(self.tileGrid, position)
	
	elseif(position.x and position.y) then
		
		local gridPos = worldToGridPosition(self.map, position)
		
		return self:getTileAt(gridPos)
	end
end

--- Gets a list of Tiles on this TileLayer that have a specified property. 
-- @param name The name of the Property to look for.
-- @return A list of found Tiles. Empty if none found.
function TileLayer:getTilesWithProperty(name)

	local tiles = {}
	
	for i = 1, #self.tiles, 1 do
		if self.tiles[i]:hasProperty(name) then
			tiles[#tiles + 1] = self.tiles[i]
		end
	end

	return tiles
end

--- Swaps two tiles around.
-- @param tile1 The first tile.
-- @param tile2 The second tile.
-- @usage Originally created by Michał Kołodziejski - http://developer.anscamobile.com/forum/2011/02/12/how-swap-two-tiles-layer
function TileLayer:swapTiles(tile1, tile2)

	-- Make sure we actually have tiles
	if tile1 and tile2 then
	
		-- Make sure the tiles have sprites attached
		if tile1.sprite and tile2.sprite then
		
			-- Swap the tile world positions
			tile1.sprite.x, tile2.sprite.x = tile2.sprite.x, tile1.sprite.x
			tile1.sprite.y, tile2.sprite.y = tile2.sprite.y, tile1.sprite.y
			
			-- Swap the tiles in the tileGrid
			self.tileGrid[tile1.column][tile1.row], self.tileGrid[tile2.column][tile2.row] = self.tileGrid[tile2.column][tile2.row], self.tileGrid[tile1.column][tile1.row]
			
			-- Swap the tile grid positions
			tile1.column, tile2.column = tile2.column, tile1.column
			tile1.row, tile2.row = tile2.row, tile1.row			 
			
		end
	end
	
end

--- Swaps two tiles around based on their positions.
-- @param position1 The position of the first tile.
-- @param position2 The position of the second tile.
-- @usage Originally created by Michał Kołodziejski - http://developer.anscamobile.com/forum/2011/02/12/how-swap-two-tiles-layer
function TileLayer:swapTilesAtPositions(position1, position2)

	-- Get both tiles
	local tile1 = self:getTileAt(position1)
	local tile2 = self:getTileAt(position2)

	-- Swap the tiles
	self:swapTiles(tile1, tile2)
	
end

--- Destroys a tile at a certain position.
-- @param position The position of the tile, world or grid.
function TileLayer:removeTileAt(position)

	local tile = self:getTileAt(position)

	if tile then
		tile:destroy()
	end

end

--- Set a tile at a position.
-- @param gid The gid of the tile.
-- @param position The position of the tile, World or Grid.
-- @usage Originally created by Mattguest - http://developer.anscamobile.com/forum/2011/02/02/settile-function
function TileLayer:setTileAt(gid, position)
	
	local tile = self:getTileAt(position)
	
	-- First make sure there is a tile
	if tile then
		tile:setImage(gid)	
	end

end

--- Adds a displayObject to the layer. 
-- @param displayObject The displayObject to add.
-- @return The added displayObject.
function TileLayer:addObject(displayObject)
	return addObjectToGroup(displayObject, self.group)
end

--- Sets the position of the TileLayer.
-- @param x The new X position of the TileLayer.
-- @param y The new Y position of the TileLayer.
function TileLayer:setPosition(x, y)

	if self.group then
		local viewPoint = calculateViewpoint(self.group, x, y)

		self.group.x = round(viewPoint.x)
		self.group.y = round(viewPoint.y)

		if self.map.orientation ~= "isometric" then
			self.group.x, self.group.y = clampPosition(self.group.x, self.group.y, self.map.bounds)
		end
		
	end
	
end

--- Moves the TileLayer.
-- @param x The amount to move the TileLayer along the X axis.
-- @param y The amount to move the TileLayer along the Y axis.
function TileLayer:move(x, y)
	moveObject(self.group, x, y)
end

--- Drags the TileLayer.
-- @param event The Touch event.
function TileLayer:drag(event)
	dragObject(self.group, event)
end

--- Creates the visual representation of the layer.
-- @return The group containing the newly created layer.
function TileLayer:create()
	
	if not self.map.world then
		self.map.world = display.newGroup()
	end
	
	self.group = display.newGroup()

	if(lime.isDebugModeEnabled()) then
		print("Lime-Coconut: Creating layer - " .. self.name)
	end
		
	local tile = nil
	
	for i=1, #self.tiles, 1 do

		tile = self.tiles[i]
		
		tile:create(i)
	
		if(tile.sprite) then
			
		else
			-- If no sprite was created then chances are this was a blank section, delete the tile to save some memory (maybe). If problems start appearing simply comment out the next lines.
			--tile:destroy()
			--tile = nil
		end				
		
	end
	
	for key, value in pairs(self.properties) do
		self.map:firePropertyListener(self.properties[key], "layer", self)
	end		
	
	-- Override tile properties if this layer has been marked as static - NOTE: THIS IS A TEMPORARY FEATURE UNTIL A MORE FLEXIBLE / SECURE FEATURE SET HAS BEEN DECIDED ON!
	if self:getPropertyValue("IsStatic") then
		
		local tile = nil
		
		for i=1, #self.tiles, 1 do
			
			tile = self.tiles[i]
			
			if tile.gid ~= 0 then
				tile.HasBody = "true"
				tile.bodyType = "static"
			end
		
		end
		
	end
		
	if self.opacity then
		self.group.alpha = self.opacity 
	end
	
	return self.group
end

--- Builds the physical representation of the TileLayer.
function TileLayer:build()
		
	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Building Tile Layer - " .. self.name)
	end	
	
	for i=1, #self.tiles, 1 do
		self.tiles[i]:build()
	end
	
end

--- Completely removes all visual and physical objects associated with the TileLayer.
function TileLayer:destroy()

	if self.group and self.tiles then
	
		for i=1, #self.tiles, 1 do	
			self.tiles[i]:destroy()
		end
		
		self.tiles = nil
		
		self.group:removeSelf()
		self.group = nil
	end
	
end
