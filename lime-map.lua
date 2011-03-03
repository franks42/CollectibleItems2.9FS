-- Project: Lime
--
-- Date: 09-Feb-2011
--
-- Version: 2.9
--
-- File name: lime-map.lua
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

Map = {}
Map_mt = { __index = Map }

----------------------------------------------------------------------------------------------------
----									CLASS VARIABLES											----
----------------------------------------------------------------------------------------------------

Map.version = 2.9

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
local stringToBool = utils.stringToBool
local showScreenSpaceTiles = utils.showScreenSpaceTiles
local splitString = utils.splitString

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

--- Create a new instance of a Map object.
-- @param filename
-- @param baseDirectory
-- @param customMapParams
-- @return The newly created Map instance.
function Map:new(filename, baseDirectory, customMapParams)

    local self = {}    -- the new instance
    
    setmetatable( self, Map_mt ) -- all instances share the same metatable
    
    self.properties = {}
    self.header = {}
    self.tileSets = {}
    self.tileLayers = {}
    self.objectLayers = {}
    
    self.objectListeners = {}
    self.propertyListeners = {}
    self.filename = filename
    self.baseDirectory = baseDirectory
    
	-- Get the absolute path
	local path = system.pathForFile(filename, baseDirectory or system.Resourcesirectory)
	
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Lychee: Loading Map - " .. filename)
	end
	
	-- Map file exists
	if path then
		
		self.rootDir = utils.stripFilenameFromPath(path)
		
		if customMapParams then
			
			if(customMapParams.type == "dweezil") then
				
				if not customMapParams.tileset then
					return nil
				end
				
				if not customMapParams.tilewidth then
					return nil
				end
				
				if not customMapParams.tileheight then
					return nil
				end

				local tilesetImage = customMapParams.tileset
	
				local levelData = utils.readLines(path)
				
				--if tilesetImage and levelData then
				if levelData then
				
					local header = levelData[1]
					
					self.xml = {}
					
					if(header) then
					
						-- CREATE MAP DATA
						self.xml["Attributes"] = {}
						self.xml["Attributes"].version = "1.0"
						self.xml["Attributes"].width = header:sub(1, 3) --+ 1
						self.xml["Attributes"].height = header:sub(4, 6) --+ 1
						self.xml["Attributes"].tilewidth = customMapParams.tilewidth						
						self.xml["Attributes"].tileheight = customMapParams.tileheight
						self.xml["Attributes"].orientation = "orthogonal"
						
						-- CREATE THE CHILD NODES
						self.xml["ChildNodes"] = {}
						
						-- CREATE THE TILESET
						self.xml["ChildNodes"][1] = {}
						self.xml["ChildNodes"][1].Name = "tileset"
						self.xml["ChildNodes"][1]["Attributes"] = {}
						self.xml["ChildNodes"][1]["Attributes"].name = customMapParams.tilesetName or "tileset"
						self.xml["ChildNodes"][1]["Attributes"].tilewidth = customMapParams.tilewidth
						self.xml["ChildNodes"][1]["Attributes"].tileheight = customMapParams.tileheight
						self.xml["ChildNodes"][1]["Attributes"].firstgid = "1"
						
						self.xml["ChildNodes"][1]["ChildNodes"] = {}
						self.xml["ChildNodes"][1]["ChildNodes"][1] = {}
						self.xml["ChildNodes"][1]["ChildNodes"][1].Name = "image"
						self.xml["ChildNodes"][1]["ChildNodes"][1]["Attributes"] = {}
						self.xml["ChildNodes"][1]["ChildNodes"][1]["Attributes"].source = customMapParams.tileset
						
						-- CREATE THE LAYER
						self.xml["ChildNodes"][2] = {}
						self.xml["ChildNodes"][2].Name = "layer"
						
						self.xml["ChildNodes"][2]["Attributes"] = {}
						self.xml["ChildNodes"][2]["Attributes"].name = customMapParams.layerName or "layer"
						self.xml["ChildNodes"][2]["Attributes"].width = self.xml["Attributes"].width
						self.xml["ChildNodes"][2]["Attributes"].height = self.xml["Attributes"].height
						self.xml["ChildNodes"][2]["Attributes"].encoding = "csv"	
						
						
						-- CREATE THE TILES
						self.xml["ChildNodes"][2]["ChildNodes"] = {}
						self.xml["ChildNodes"][2]["ChildNodes"][1] = {}
						self.xml["ChildNodes"][2]["ChildNodes"][1].Name = "data"
						
						local tileIDString = ""
						
						for i=2, #levelData - 1, 1 do
							
							for j = 1, #levelData[i] - 1 do
								local tileID = levelData[i]:sub(j, j)
								
								if(tileID == " ") then
									tileID = "0"
								end

								tileIDString = tileIDString .. tileID .. ","
			
							end
						end
				
						self.xml["ChildNodes"][2]["ChildNodes"][1].Value = tileIDString
					
						
					end
				
				end
				
			end
			
			
		else -- A regular TMX map		
			-- Read in all the data
			self.xml = XmlParser:ParseXmlFile(path)
		end	
			
	end

	-------------------------------
	---- Load In Header Values ----
	-------------------------------
	
	-- Loop through the header BEFORE loading anything else
	for key, value in pairs(self.xml["Attributes"]) do 
		self:setProperty(key, value)
		self.header[key] = value
	end
	
	local tileLayer = nil
	local tileSet = nil
	local objectLayer = nil
	local property = nil
	
	local node = nil
	local nodeName = nil
	local attributes = nil
	
	-------------------------------
	----   Load In Map Items   ----
	-------------------------------
	for i=1, #self.xml["ChildNodes"], 1 do
		
		node = self.xml["ChildNodes"][i]
		nodeName = node.Name
		
		if(nodeName == "tileset") then
			
			tileSet = TileSet:new(node, self)
					
			self.tileSets[#self.tileSets + 1] = tileSet
					
			if(lime.isDebugModeEnabled() and tileSet) then
				print("Lime-Lychee: Loaded TileSet - " .. tileSet.name)
			end
					
		elseif(nodeName == "layer") then
		
			tileLayer = TileLayer:new(node, self)
				
			self.tileLayers[#self.tileLayers + 1] = tileLayer
				
			if(lime.isDebugModeEnabled() and tileLayer) then
				print("Lime-Lychee: Loaded Tile Layer - " .. tileLayer.name)
			end
			
		elseif(nodeName == "objectgroup") then
		
			objectLayer = ObjectLayer:new(node, self)
				
			self.objectLayers[#self.objectLayers + 1] = objectLayer
				
			if(lime.isDebugModeEnabled() and objectLayer) then
				print("Lime-Lychee: Loaded Object Layer - " .. objectLayer.name)
			end
					
		elseif(nodeName == "properties") then
			
			-- Loop through all the child nodes
			for j=1, #node["ChildNodes"], 1 do
			
				-- Each child node is a property, the attributes are the name and value
				attributes = node["ChildNodes"][j]["Attributes"]
				
				if attributes then
					
					if attributes.name == "configFile" then

						readInConfigFile(attributes.value, self)
						
					else
						
						property = self:setProperty(attributes.name, attributes.value)
						
						if(lime.isDebugModeEnabled() and property) then
							print("Lime-Lychee: Loaded Map Property - " .. property.name)
						end
					end
				end
			end
		end
	end
				
    return self
    
end

--- Sets the value of a Property of the Map. Will create a new Property if none found.
-- @param name The name of the Property.
-- @param value The new value.
-- @return The property being set.
function Map:setProperty(name, value)
		
	local property = self:getProperty(name)
	
	if property then
		property:setValue(value)
	else
		property = self:addProperty(Property:new(name, value))
	end
	
	self[name] = value
	
	return property
end

--- Gets a Property of the Map.
-- @param name The name of the Property.
-- @return The Property. nil if no Property found.
function Map:getProperty(name)
	return self.properties[name]
end

--- Gets the value of a Property of the Map.
-- @param name The name of the Property.
-- @return value The Property value. nil if no Property found.
function Map:getPropertyValue(name)
	
	local property = self:getProperty(name)
	
	if property then
		return property:getValue()
	end
	
end

--- Gets a list of all Properties of the Map.
-- @return The list of Properties.
function Map:getProperties()
	return self.properties
end

--- Gets a count of how many properties the Map has.
-- @return The Property count.
function Map:getPropertyCount()

	local count = 0
	
	for _k, _v in pairs(self.properties) do
		count = count + 1
	end

	return count
end

--- Checks whether the Map has a certain Property.
-- @param name The name of the property to check for.
-- @return True if the Map has the Property, false if not.
function Map:hasProperty(name)
	return self:getProperty(name) ~= nil
end

--- Adds a Property to the Map. 
-- @param property The Property to add.
-- @return The added Property.
function Map:addProperty(property)
	self.properties[property:getName()] = property
	
	self[property:getName()] = property:getValue()

	return property
end

--- Removes a Property from the Map. 
-- @param name The name of the Property to remove.
function Map:removeProperty(name)
	self.properties[name] = nil
	self[name] = nil
end

--- Gets the value of a header Property of the Map.
-- @param name The name of the header Property.
-- @return value The Property value. nil if no Property found.
function Map:getHeaderValue(name)
	
	return self.header[name]
	
end

--- Gets a TileLayer.
-- @param indexOrName The index or name of the TileLayer to get.
-- @return The tile layer at indexOrName.
function Map:getTileLayer(indexOrName)
	
	if type(indexOrName) == "number" then
		
		return self.tileLayers[indexOrName]
		 
	elseif type(indexOrName) == "string" then
		
		for i=1, #self.tileLayers, 1 do 
			
			if self.tileLayers[i].name == indexOrName then
				return self.tileLayers[i]
			end
			
		end
		
	end
	
end

--- Gets an ObjectLayer.
-- @param indexOrName The index or name of the ObjectLayer to get.
-- @return The object layer at indexOrName.
function Map:getObjectLayer(indexOrName)
	
	if type(indexOrName) == "number" then
		
		return self.objectLayers[indexOrName]
		 
	elseif type(indexOrName) == "string" then
		
		for i=1, #self.objectLayers, 1 do 
			
			if self.objectLayers[i].name == indexOrName then
				return self.objectLayers[i]
			end
			
		end
		
	end
	
end

--- Gets a TileSet.
-- @param indexOrName The index or name of the TileSet to get.
-- @return The tileset at indexOrName.
function Map:getTileSet(indexOrName)

	if type(indexOrName) == "number" then
		
		return self.tileSets[indexOrName]
		 
	elseif type(indexOrName) == "string" then
		
		for i=1, #self.tileSets, 1 do 
			
			if self.tileSets[i].name == indexOrName then
				return self.tileSets[i]
			end
			
		end
		
	end
	
end


--- Gets a Tile image from a GID.
-- Fixed fantastically by FrankS - http://developer.anscamobile.com/forum/2011/02/18/bug-mapgettilesetfromgidgid
-- @param gid The gid to use.
-- @return The tileset at the gid location.
function Map:getTileSetFromGID(gid)
	gid = tonumber(gid)
	if gid then
	
		local tileSets = self.tileSets
		if #tileSets > 0 and gid >= tonumber(tileSets[1].firstgid) then
            
            for i = 2, #tileSets, 1 do 
            	if tonumber(tileSets[i].firstgid) > gid then 
                	return tileSets[i-1] 
                end
            end
                
            return tileSets[#self.tileSets]  -- leap of faith that it's in the last tileset
            
        else
        
            return nil 
            
        end
        
	end
	
		--[[
		
		local tileSet = nil
		
		local nextTileSet = nil
	
		for i=1, #self.tileSets, 1 do 
			
			if self.tileSets[i].firstgid < gid then
							
				nextTileSet = self.tileSets[i + 1]
			
				if nextTileSet then
				
					if nextTileSet.firstgid then
						
						if tonumber(nextTileSet.firstgid) > tonumber(gid) then
							tileSet = self.tileSets[i]
						end
					end
					
				else
					
					return self.tileSets[i]
					
				end
				
			end
			
		end
	end
	
	return tileSet
	
	--]]
end

--- Shows the Map.
function Map:show()
	for i=1, #self.tiles, 1 do	
		self.tileLayers[i]:show()	
	end	
end

--- Hides the Map.
function Map:hide()
	for i=1, #self.tileLayers, 1 do
		self.tileLayers[i]:hide()		
	end
end

--- Moves the Map.
-- @param x The amount to move the Map along the X axis.
-- @param y The amount to move the Map along the Y axis.
function Map:move(x, y)
	moveObject(self.world, x, y)
	
	if self.orientation ~= "isometric" then
		self.world.x, self.world.y = clampPosition(self.world.x, self.world.y, self.bounds)
	end
	
end

--- Drags the Map.
-- @param event The Touch event.
function Map:drag(event)

	if self.world then
		dragObject(self.world, event)
		
		if self.orientation ~= "isometric" then
			self.world.x, self.world.y = clampPosition(self.world.x, self.world.y, self.bounds)
		
			if self.ParallaxEnabled then
				self:setParallaxPosition{ x = self.world.x, y = self.world.y }
			end
		
		end
	end		
end
	
--- Sets the position of the Map.
-- @param x The new X position of the Map.
-- @param y The new Y position of the Map.
function Map:setPosition(x, y)

	if self.world then
		local viewPoint = calculateViewpoint(self.world, x, y)

		self.world.x = round(viewPoint.x)
		self.world.y = round(viewPoint.y)

		if self.orientation ~= "isometric" then
			self.world.x, self.world.y = clampPosition(self.world.x, self.world.y, self.bounds)
			
			if self.ParallaxEnabled then
				self:setParallaxPosition{ x = self.world.x, y = self.world.y }
			end
		
		end
		
	end	
end

--- Gets the position of the Map.
-- @return The X position of the Map.
-- @return The Y position of the Map.
function Map:getPosition()

	if self.world then
		return self.world.x, self.world.y
	end

end

--- Fades the Map to a new position.
-- @param x The new X position of the Map.
-- @param y The new Y position of the Map.
-- @param fadeTime The time it will take to fade the Map out or in. Optional, default is 1000.
-- @param moveDelay The time inbetween both fades. Optional, default is 0.
-- @param onCompleteHandler Event handler to be called on movement completion. Optional.
function Map:fadeToPosition(x, y, fadeTime, moveDelay, onCompleteHandler)
	
	local beginFadeIn = function(event)
	
		if self.moveDelayTimer then
			timer.cancel(self.moveDelayTimer)
		end
		
		transition.to(self.world, {alpha = 1, time=fadeTime or 1000, onComplete=onCompleteHandler})
	end
	
	local onFadeOut = function(event)
		self:setPosition(x, y)
		
		if moveDelay then
			self.moveDelayTimer = timer.performWithDelay(moveDelay, beginFadeIn, 1)
		else
			beginFadeIn()
		end
	end

	if(self.fadeTransition) then
		transition.cancel(self.fadeTransition)
	end
	
	self.fadeTransition = transition.to(self.world, {alpha = 0, time=fadeTime or 1000, onComplete=onFadeOut})
end

--- Slides the Map to a new position.
-- @param x The new X position of the Map.
-- @param y The new Y position of the Map.
-- @param slideTime The time it will take to slide the Map to the new position.
-- @param onCompleteHandler Event handler to be called on movement completion. Optional.
function Map:slideToPosition(x, y, slideTime, onCompleteHandler)
	
	local onTransitionUpdate = function(event)
		if self.ParallaxEnabled then
			self:setParallaxPosition{x = self.world.x, y = self.world.y }
		end
	end
	
	local onSlideComplete = function(event)
	
		if onCompleteHandler then
			onCompleteHandler(event)
		end
		
		Runtime:removeEventListener("enterFrame", onTransitionUpdate)
	end
	
	local viewPoint = calculateViewpoint(self.world, x, y)
		
	if(self.slideTransition) then
		transition.cancel(self.slideTransition)
		Runtime:removeEventListener("enterFrame", onTransitionUpdate)
	end
	
	local clampedX, clampedY = x, y
	
	if self.orientation ~= "isometric" then
		-- Clamp the position first to ensure that it is not outside the bounds
		clampedX, clampedY = clampPosition(round(viewPoint.x, 0.5), round(viewPoint.y, 0.5), self.bounds)
	end
	
	
	Runtime:addEventListener("enterFrame", onTransitionUpdate)
	
	self.slideTransition = transition.to( self.world, {time=slideTime or 1000, x=clampedX, y=clampedY, onComplete=onSlideComplete})
end

--- Shows all debug images on the Map.
function Map:showDebugImages()
	
	for i=1, #self.objectLayers, 1 do 
		self.objectLayers[i]:showDebugImages()
	end
end

--- Hides all debug images on the Map.
function Map:hideDebugImages()

	for i=1, #self.objectLayers, 1 do 
		self.objectLayers[i]:hideDebugImages()
	end
end

--- Toggles the visibility of all debug images on the Map.
function Map:toggleDebugImagesVisibility()
	
	for i=1, #self.objectLayers, 1 do 
		self.objectLayers[i]:toggleDebugImagesVisibility()
	end
	
end	

--- Gets all Tiles across all TileLayers at a specified position.
-- @param position The position of the Tiles. A table containing either x & y or row & column.
-- @param count The number of Tiles to get. Optional.
-- @return A table of found Tiles. Empty if none found.
function Map:getTilesAt(position, count)
	
	local tiles = {}
	local tile = nil
	
	for i=1, #self.tileLayers, 1 do
		
		tile = self.tileLayers[i]:getTileAt(position)
		
		if(tile) then
			tiles[#tiles + 1] = tile
		end
		
		if(count) then
			if(count == #tiles) then -- If they want more, wait till we have the correct amount
				return tiles
			end
		end
		
	end

	return tiles
end
	
--- Gets the first found tile at a specified position.
-- @param position The position of the Tile. A table containing either x & y or row & column.
-- @return tile The found Tile. nil if none found.	
function Map:getTileAt(position)
	local tiles = self:getTilesAt(position, 1)
	return tiles[1]
end
	
--- Gets a list of Tiles across all TileLayers that have a specified property. 
-- @param name The name of the Property to look for.
-- @return A list of found Tiles. Empty if none found.
function Map:getTilesWithProperty(name)

	local tiles = {}
	
	local tileLayers = {}
	
	for i = 1, #self.tileLayers, 1 do
		
		tileLayers = self.tileLayers[i]:getTilesWithProperty(name)
		
		for j = 1, #tileLayers, 1 do
			tiles[#tiles + 1] = tileLayers[j]
		end

	end

	return tiles
end

--- Gets a list of Objects across all ObjectLayers that have a specified property. 
-- @param name The name of the Property to look for.
-- @return A list of found Objects. Empty if none found.
function Map:getObjectsWithProperty(name)

	local objects = {}
	
	local objectLayers = {}
	
	for i = 1, #self.objectLayers, 1 do
		
		objectLayers = self.objectLayers[i]:getObjectsWithProperty(name)
		
		for j = 1, #objectLayers, 1 do
			objects[#objects + 1] = objectLayers[j]
		end

	end

	return objects
end

--- Gets a list of Objects across all ObjectLayers that have a specified name. 
-- @param name The name of the Objects to look for.
-- @return A list of found Objects. Empty if none found.
function Map:getObjectsWithName(name)

	local objects = {}
	
	local objectLayers = {}
	
	for i = 1, #self.objectLayers, 1 do
		
		objectLayers = self.objectLayers[i]:getObjectsWithName(name)
		
		for j = 1, #objectLayers, 1 do
			objects[#objects + 1] = objectLayers[j]
		end

	end

	return objects
end

--- Gets a list of Objects across all ObjectLayers that have a specified type. 
-- @param type The type of the Objects to look for.
-- @return A list of found Objects. Empty if none found.
function Map:getObjectsWithType(type)

	local objects = {}
	
	local objectLayers = {}
	
	for i = 1, #self.objectLayers, 1 do
		
		objectLayers = self.objectLayers[i]:getObjectsWithType(type)
		
		for j = 1, #objectLayers, 1 do
			objects[#objects + 1] = objectLayers[j]
		end

	end

	return objects
end

--- Gets a list of all tile properties across the map that have the same name.
--	Originally created by FrankS - http://developer.anscamobile.com/forum/2011/02/19/additional-convenience-functions-navigate-lime-world-tree
-- @param name The type of the Property to look for.
-- @return A list of found Objects. Empty if none found.
function Map:findValuesByTilePropertyName(name)

	local tiles = selfgetTilesWithProperty(name)
	local values = {}
	
	for i = 1, #tiles, 1 do
		values[#values + 1] = tiles[i]:getPropertyValue(name)
	end

	return values
	
end

--- Creates a sprite from a passed in GID
--	Originally created by FrankS - http://developer.anscamobile.com/forum/2011/02/19/additional-convenience-functions-navigate-lime-world-tree
-- @param gid The gid of the tile to create.
-- @return A corona display object. Nil if gid was invalid.
function Map:createSprite(gid)

	local tileSet = self:getTileSetFromGID( gid )
	
	if tileSet then
		return tileSet:createSprite(gid)
	end

end

--- Gets a property value from a tileset.
--	Originally created by FrankS - http://developer.anscamobile.com/forum/2011/02/19/additional-convenience-functions-navigate-lime-world-tree
-- @param gid The gid of the tile to check.
-- @param name The name of the property to look for.
-- @return The value of the property. Nil if none found.
function Map:getTilePropertyValueForGID(gid, name)
	gid = tonumber(gid)
	local tileSet = self:getTileSetFromGID(gid)
	
	if tileSet then
	
		local properties = tileSet:getPropertiesForTile(gid)
	
		for i = 1, #properties, 1 do
			if properties[i]:getName() == name then
				return properties[i]:getValue()
			end
		end
		
	end

end

--- Gets the GID and local id for a tile from a named tileset with a specified local id.
--	Originally created by FrankS - http://developer.anscamobile.com/forum/2011/02/19/additional-convenience-functions-navigate-lime-world-tree
-- @param tileSetName The name of the tileset to look for. Can also be specified in a single string - "tileSetName:localTileID".
-- @param localTileID The local id of the tile. Can also be specified in a single string - "tileSetName:localTileID".
-- @return The gid of the tile. Nil if none found.
-- @return The local id of the tile. Nil if none found.
function Map:getGIDForTileNameID(tileSetName, localTileID)

	if (tileSetName == nil) then 
		return nil, tonumber(localTileID)   
	end
	
	-- see if only localTileID specified in first arg
	if type( tileSetName ) == "number" or tonumber(tileSetName) then 
		return nil, tonumber(tileSetName)   
	end
	
	-- (maybe) only localTileID specified in first arg string
	local name, localID = unpack( splitString( tileSetName, ":" ) )
		
	if type(name) ~= "string" then 
		return nil, tonumber(name)  
	end
	
	 -- see if we can truly return gid, localTileID
	localID = tonumber(localID) or tonumber(localTileID) or 0
	
	local tileSet = self:getTileSet(name)
	
	if tileSet then 
		return (tonumber(tileSet.firstgid) + localID), localID 
	end
	
	-- fall-through...give up
	return nil  
end

--- Gets the name of the tileset and the local id of a specified gid
--	Originally created by FrankS - http://developer.anscamobile.com/forum/2011/02/19/additional-convenience-functions-navigate-lime-world-tree
-- @param gid The gid of the tile to check.
-- @return The name of the tileset. Nil if none found.
-- @return The local id of the tile. Nil if none found.
function Map:getTileNameIDForGID(gid)

	local tileSet = self:getTileSetFromGID(gid)
	
	if tileSet then
		return tileSet.name, (gid - tileSet.firstgid)
	end
	
end

--- Adds a displayObject to the world. 
-- @param displayObject The displayObject to add.
-- @return The added displayObject.
function Map:addObject(displayObject)
	return addObjectToGroup(displayObject, self.world)
end

--- Adds an Object listener to the Map.
-- @param objectType The type of Object to listen for.
-- @param listener The listener function.
function Map:addObjectListener(objectType, listener)
	
	if(objectType and listener) then
		if(not self.objectListeners[objectType]) then
			self.objectListeners[objectType] = {} 
		end
		self.objectListeners[objectType][#self.objectListeners[objectType] + 1] = listener
	end
	
end

--- Gets a table containing all the object listeners that have been added to the Map.
-- @return The object listeners.
function Map:getObjectListeners()
	return self.objectListeners
end

--- Adds a Property listener to the Map.
-- @param propertyName The name of the Property to listen for.
-- @param listener The listener function.
function Map:addPropertyListener(propertyName, listener)
	if(propertyName and listener) then
		if(not self.propertyListeners[propertyName]) then
			self.propertyListeners[propertyName] = {} 
		end
		
		self.propertyListeners[propertyName][#self.propertyListeners[propertyName] + 1] = listener
	end		
end

--- Gets a table containing all the property listeners that have been added to the Map.
-- @return The property listeners.
function Map:getPropertyListeners()
	return self.propertyListeners
end

--- Fires an already added property listener.
-- @param property The property object that was hit.
-- @param type The type of the property object. "map", "tileLayer", "objectLayer", "tile", "obeject".
-- @param object The object that has the property.
function Map:firePropertyListener(property, type, object)

	if self.propertyListeners[property.name] then
	
		local listeners = self.propertyListeners[property.name] or {}
		
		for i=1, #listeners, 1 do
			listeners[i](property, type, object)
		end
	end	
end

--- Fires an already added object listener
-- @param object The object that the listener was waiting for.
function Map:fireObjectListener(object)

	local listeners = self.objectListeners[object.type] or {}
			
	for i=1, #listeners, 1 do
		listeners[i](object)
	end

end			

--- Sets the focus for the Map.
-- @params object The object to track. nil if you wish to stop tracking.
-- @params xOffset The amount the tracking point should be offset from the object along the X axis. Optional, default is 0.
-- @params yOffset The amount the tracking point should be offset from the object along the Y axis. Optional, default is 0.
function Map:setFocus(object, xOffset, yOffset)
	self.focus = { object = object, xOffset = xOffset, yOffset = yOffset }
end

--- Sets the position of the Map for Parallax effects.
-- @params position The position for the Map.
function Map:setParallaxPosition(position)

	for i = 1, #self.tileLayers, 1 do
		
		position.x = -position.x * (self.tileLayers[i].parallaxFactorX or 1) + display.contentWidth
		position.y = -position.y * (self.tileLayers[i].parallaxFactorY or 1)
		
	--	position.x, position.y = clampPosition(position.x, position.y, self.bounds)
		
		self.tileLayers[i]:setPosition(position.x, position.y)
	end
	
end

--- Updates the Map.
-- @params event The enterFrame event object.
function Map:update(event)
	
	if self.focus then
		if self.focus.object then
			if self.ParallaxEnabled then
				self:setParallaxPosition(self.focus.object)
			else
				self:setPosition(self.focus.object.x + (self.focus.xOffset or 0), self.focus.object.y + (self.focus.yOffset or 0))
			end
		end
		
	end
	
	if _G.limeScreenCullingEnabled then
		showScreenSpaceTiles(self)
	end
end

--- Creates the visual representation of the map.
-- @return The newly created world a visual representation of the map.
function Map:create()
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Coconut: Creating map - " .. self.filename)
	end
	
	self.world = display.newGroup()
	
	for i=1, #self.tileLayers, 1 do

		self.tileLayers[i]:create()
			
		if self.tileLayers[i].group then
			self.world:insert(self.tileLayers[i].group)
		end
	end
	
	for i=1, #self.objectLayers, 1 do

		self.objectLayers[i]:create()
			
		if self.objectLayers[i].group then
			self.world:insert(self.objectLayers[i].group)
		end
	end	
	
	for key, value in pairs(self.properties) do
		self:firePropertyListener(self.properties[key], "map", self)
	end
	
	self.pixelwidth = self.width * self.tilewidth
	self.pixelheight = self.height * self.tileheight
	
	self.bounds = {}
	self.bounds.x = 0
	self.bounds.y = 0
	self.bounds.width = self.pixelwidth
	self.bounds.height = self.pixelheight	

	self.visualCreated = true
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Coconut: Map Created - " .. self.filename)
	end
	
	showScreenSpaceTiles(self)
	
	return self.world
end

--- Builds the physical representation of the Map.
function Map:build()

	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Building map - " .. self.filename)
	end

	if not physics then
		require("physics")
		physics.start()
	end
	
	local gravityX, gravityY = physics.getGravity()
	
	physics.setGravity( self:getPropertyValue("Physics:GravityX") or gravityX, self:getPropertyValue("Physics:GravityY") or gravityY )
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Setting gravity (x|y) to " .. (self:getPropertyValue("Physics:GravityX") or gravityX) .. "|" .. (self:getPropertyValue("Physics:GravityY") or gravityY))
	end
	
	physics.setScale( self:getPropertyValue("Physics:Scale") or 30 ) 
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Setting scale to " .. (self:getPropertyValue("Physics:Scale") or 30))
	end
	
	physics.setDrawMode( self:getPropertyValue("Physics:DrawMode") or "normal" ) 

	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Setting draw mode to " .. (self:getPropertyValue("Physics:DrawMode") or "normal"))
	end
	
	physics.setPositionIterations( self:getPropertyValue("Physics:PositionIterations") or 8 ) 
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Setting position iterations to " .. (self:getPropertyValue("Physics:PositionIterations") or 8))
	end
	
	physics.setVelocityIterations( self:getPropertyValue("Physics:VelocityIterations") or 3 ) 
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Setting velocity iterations to " .. (self:getPropertyValue("Physics:VelocityIterations") or 3))
	end	
			
	for i=1, #self.objectLayers, 1 do
		self.objectLayers[i]:build()	
	end
	
	for i=1, #self.tileLayers, 1 do
		self.tileLayers[i]:build()
	end	
	
	self.physicalCreated = true
	
	if self.ParallaxEnabled then
	
		if self.ParallaxEnabled == "" then
			self.ParallaxEnabled = "true"
		end
		
		self.ParallaxEnabled = stringToBool( self.ParallaxEnabled )
	end
	
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Map Built - " .. self.filename)
	end
	
end

--- Completely removes all visual and physical objects associated with the Map.
function Map:destroy()

	if self.world then
			
		for i=1, #self.tileLayers, 1 do
			self.tileLayers[i]:destroy()
		end
		
		for i=1, #self.objectLayers, 1 do
			self.objectLayers[i]:destroy()
		end
		
		for i=1, #self.tileSets, 1 do
			self.tileSets[i]:destroy()
		end
		
		self.world:removeSelf()
		self.world = nil
	end

end

--- Completely destroys the Map and then reloads it from disk. 
-- Will also recreate the visual and then rebuild the physical if it was in the first place.
-- @return The reloaded Map object.
function Map:reload()
	
	local createVisual = self.visualCreated
	local createPhysical = self.physicalCreated
	local propertyListeners = self:getPropertyListeners()
	local objectListeners = self:getObjectListeners()
		
	self:destroy()
	
	self = Map:new(self.filename, self.baseDirectory)
	
	-- Re add the property listeners
	for propertyName, callbacks in pairs(propertyListeners) do
		for i = 1, #callbacks, 1 do
			self:addPropertyListener(propertyName, callbacks[i])
		end
	end

	-- Re add the object listeners
	for objectType, callbacks in pairs(objectListeners) do
		for i = 1, #callbacks, 1 do
			self:addObjectListener(objectType, callbacks[i])
		end
	end
	
	if createVisual then
		lime.createVisual(self)
	end
	
	if createPhysical then
		lime.buildPhysical(self)
	end
	
	return self
end
