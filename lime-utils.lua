-- Project: Lime
--
-- Date: 09-Feb-2011
--
-- Version: 2.9
--
-- File name: lime-utils.lua
--
-- Author: Graham Ranson 
--
-- Support: www.justaddli.me
--
-- Copyright (C) 2011 MonkeyDead Studios Limited. All Rights Reserved.

--- A list of utility functions provided as part of Lime.

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

module(..., package.seeall)

----------------------------------------------------------------------------------------------------
----									REQUIRED MODULES										----
----------------------------------------------------------------------------------------------------

require "Json"


----------------------------------------------------------------------------------------------------
----									MODULE VARIABLES										----
----------------------------------------------------------------------------------------------------

version = 2.9

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

---Converts a world position into a tile (grid) position
-- @param map The current Map.
-- @param position The world position.
-- @returns The grid position.
function worldToGridPosition(map, position)

	position.column = math.ceil(position.x / map.tilewidth)
	position.row = math.ceil(position.y / map.tileheight)

	return position
end

--- Converts a screen position into a tile (grid) position.
-- @param map The current Map.
-- @param position The screen position.
-- @return The grid position.
function screenToGridPosition(map, position)
	return worldToGridPosition(map, {x=position.x - map.world.x, y=position.y - map.world.y})
end

--- Converts a screen position into a world position
-- @param map The current Map.
-- @param position The screen position.
-- @return The world position.
function screenToWorldPosition(map, position)

	local newPosition = {}
	
	if map.world then
		newPosition.x = position.x + map.world.x * -1
		newPosition.y = position.y + map.world.y * -1
	end
	
	return newPosition
end

--- Converts a world position into a screen position
-- @param map The current Map.
-- @param position The world position.
-- @return The screen position.
function worldToScreenPosition(map, position)

	local newPosition = {}
	
	if map.world then
		newPosition.x = position.x - map.world.x
		newPosition.y = position.y - map.world.y
	end
	
	return newPosition
end

--- Reads the entire contents of a file into a String.
-- @param path The complete path to the file.
-- @return A string containing the read in contents.
function readInFileContents(path)
		
	local handle = io.open( path, "r" )

	if(handle) then
		local contents = handle:read( "*a" )

		io.close( handle )

		return contents
	end
end

--- Reads the entire contents of a file into a table of lines.
-- @param path The complete path to the file.
-- @return A table of lines with the read in contents.
function readLines(path)
	local handle = io.open( path, "r" )
	local lines = {}
	
	while true do
	    line = handle:read()
	   	if line == nil then break end
	
		lines[#lines + 1] = line
	end
	
	handle:close()

	return lines
end

--[[
--- Split a String.
-- @param s The String to split.
-- @param delimiter The value to split the String on.
-- @returns A table consiting of all the split elements.
--]]

--- Split a string str in maximum maxNb parts given a delimiter delim.
-- from http://lua-users.org/wiki/SplitJoin - 
-- added  case "" for delim to split the str in array of chars.
--@param str String to split.
--@param delim Delimiter to split on.
--@param maxNb Maximum number of split parts. Optional.
--@return - Array of string-parts that were found during the split.
function splitString(str, delim, maxNb)
	
	-- Swapped to the new function for the addSuffixToFileName function.
	--[[
  	local result = { }
  	local from  = 1
  	local delim_from, delim_to = string.find( s, delimiter, from  )
  	
	while delim_from do
    	table.insert( result, string.sub( s, from , delim_from-1 ) )
    	from  = delim_to + 1
    	delim_from, delim_to = string.find( s, delimiter, from  )
  	end

  	table.insert( result, string.sub( s, from  ) )
 	return result
	--]]

	--[[
	local fields = {}
	local pattern = string.format("([^%s]+)", delimiter)
	s:gsub(pattern, function(c) fields[#fields+1] = c end)
	
	return fields
	--]]
	
	local result = {}
	if maxNb == nil or maxNb < 1 then
			maxNb = 0    -- No limit
	end
	if(delim == "")then
			local nb = 0
			for c in str:gmatch"." do
					nb = nb+1
					result[nb] = c
					if(nb==maxNb)then return result end
			end
			return result
	end
	if(string.find(str, delim) == nil) then
			-- eliminate bad case
			return { str }
	end
	local pat = "(.-)" .. delim .. "()"
	local nb = 0
	local lastPos
	for part, pos in string.gfind(str, pat) do
			nb = nb + 1
			result[nb] = part
			lastPos = pos
			if nb == maxNb then break end
	end
	-- Handle the last field
	if nb ~= maxNb then
			result[nb + 1] = string.sub(str, lastPos)
	end
	return result
end

--- Converts a string of either "true" or "false" to a boolean value. 
-- Case insensitive.
-- @param s The string to convert.
-- @return True or False based on the input string.
function stringToBool(s)
	if(s and type(s) == "string") then
		if(string.lower(s) == "true") then
			return true
		elseif(string.lower(s) == "false") then
			return false
		end
	end
	
	return nil
end

--- Converts a boolean value into a string.
-- @param bool The boolean to convert.
-- @return "true" or "false".
function boolToString(bool)
	if(bool) then
		return "true"
	else
		return "false"
	end
end

--- Adds a displayObject to a displayGroup
-- @param displayObject The object to add.
-- @param group The group to add the object to.
-- @return The displayObject
function addObjectToGroup(displayObject, group)
	
	if displayObject then
		
		if group then
		
			group:insert(displayObject)
			
		end
		
	end
	
	return displayObject
	
end

--- Moves an object a set distance.
-- (something that has an X and Y property)
-- @param object The object to move.
-- @param x The amount to move the object along the X axis.
-- @param y The amount to move the object along the Y axis.
function moveObject(object, x, y)
	
	if not object then
		return 
	end
	
	if not object.x or not object.y then
		return
	end
	
	object.x = round( (object.x + (x or 0) * -1) )
	object.y = round( object.y + (y or 0) )
	
end

--- Drags an object 
-- (something that has an X and Y property).
-- @param object The object to drag.
-- @param event The Touch event.
function dragObject(object, event)

	if not object then
		return 
	end
	
	if not object.x or not object.y then
		return
	end
	
	if(event.phase=="began") then

		object.touchPosition = {}
    	object.touchPosition.x = event.x - object.x
        object.touchPosition.y = event.y - object.y

    elseif(event.phase=="moved") then

		if not object.touchPosition then
			object.touchPosition = {}
	    	object.touchPosition.x = event.x - object.x
	        object.touchPosition.y = event.y - object.y
		end
		
   		object.x = event.x - object.touchPosition.x
        object.y = event.y - object.touchPosition.y

    end

end

--- Converts a 6 digit Hex value into its RGB elements.
-- @param hex The hex value to convert.
-- @returns A table with the r, g and b values.
function hexToRGB(hex)
	
	local colour = {}
	
	colour.r = tonumber(hex:sub(1, 2), 16)
	colour.g = tonumber(hex:sub(3, 4), 16)
	colour.b = tonumber(hex:sub(5, 6), 16)
	
	return colour
	
end

--- Extracts a filename from a path.
-- @param path The path to use.
-- @returns The extracted filename.
function getFilenameFromPath(path)

	local splitPath = splitString(path, "/")
		
	return splitPath[#splitPath]
end

--- Strips a filename from a path.
-- @param path The path to use.
-- @return The stripped path.
function stripFilenameFromPath(path)

	local splitPath = splitString(path, "/")
	
	local path = ""
	
	for i=1, #splitPath - 1, 1 do
		path = path .. splitPath[i] .. "/"
	end
	
	return path
	
end

--- Adds a suffix to a filename.
-- @param filename The filename to use.
-- @param suffix The suffix to use.
-- @return The new filename.
function addSuffixToFileName(filename, suffix)
	
	local splitFilename = {}
	local pattern = string.format("([^%s]+)", ".")
	filename:gsub(pattern, function(c) splitFilename[#splitFilename+1] = c end)
	
	if #splitFilename == 2 then
		splitFilename[1] = splitFilename[1] .. suffix
	end
	
	return table.concat(splitFilename, ".")
	
end

--- Gets the last directory in a path.
-- @param path The path to use.
-- @return The last directory.
function getLastDirectoryInPath(path)

	local strippedPath = stripFilenameFromPath(path)
	
	local splitPath = splitString(strippedPath, "/")
	
	return splitPath[#splitPath - 1]
	
end

--- Copies Properties from one object to another.
-- @param objectA The object that has the Properties.
-- @param objectB The object that will have the Properties coped to it. Must have an "addProperty" function.
function copyProperties(objectA, objectB)
	
	local properties = objectA:getProperties()
	
	for _k, value in pairs(properties) do
		objectB:addProperty(value)
	end
	
end

--- Adds a collision filter from an object to a body.
-- @param item The item to add the collision filter to.
function addCollisionFilterToBody(item)

	local categoryBits = item:getPropertyValue("categoryBits")
	local maskBits = item:getPropertyValue("maskBits")
	local groupIndex = item:getPropertyValue("groupIndex")
	
	if(categoryBits or maskBits or groupIndex) then
		
		local collisionFilter = {}
		
		collisionFilter.categoryBits = categoryBits
		collisionFilter.maskBits = maskBits
		collisionFilter.groupIndex = groupIndex
		
		item.filter = collisionFilter
	end
end

--- Applies physical properties to a body.
-- @param body The body to apply the properties to.
-- @param params The physical properties.
function applyPhysicalParametersToBody(body, params)
	if(body) then

		body.isAwake = stringToBool(params.isAwake)
		body.isBodyActive = stringToBool(params.isBodyActive) or true
		body.isBullet = stringToBool(params.isBullet)
		body.isSleepingAllowed = stringToBool(params.isSleepingAllowed)
		body.isFixedRotation = stringToBool(params.isFixedRotation)
		body.angularVelocity = params.angularVelocity
		body.linearDamping = params.linearDamping
		body.angularDamping = params.angularDamping
		body.bodyType = params.bodyType
	end
end

--- Adds the non-physical properties of an object to a body.
-- @param body The body to add the properties to.
-- @param object The object that has the properties.
function addPropertiesToBody(body, object)

	local properties = object:getProperties()
	local property = {}
	local propertyName = ""
	
	for key, _v in pairs(properties) do
		
		property = properties[key]
		
		if property then

			propertyName = property:getName()

			if propertyName ~= "isAwake" and
				propertyName ~= "isBodyActive" and
				propertyName ~= "isBullet" and
				propertyName ~= "isSleepingAllowed" and
				propertyName ~= "isFixedRotation" and
				propertyName ~= "angularVelocity" and
				propertyName ~= "linearDamping" and
				propertyName ~= "angularDamping" and
				propertyName ~= "bodyType" and
				propertyName ~= "friction" and
				propertyName ~= "bounce" and
				propertyName ~= "density" and
				propertyName ~= "points" then
	
				body[propertyName] = property:getValue()
			end
		end	
	end
end

--- Copies the Properties of one object to another. 
-- For adding to an object that doesn't have "addProperty" such as a Sprite.
-- @param objectA The object that has the Properties.
-- @param objectB The object that will have the Properties coped to it.
-- @param propertiesToIgnore A list of properties to not add if they exist. Optional.
function copyPropertiesToObject(objectA, objectB, propertiesToIgnore)

	local properties = objectA:getProperties()
	
	for key, property in pairs(properties) do
		
		local copyProperty = true
		
		if propertiesToIgnore then
			
			for i = 1, #propertiesToIgnore, 1 do
				if propertiesToIgnore[i] == key then
					copyProperty = false
					break	
				end			
			end
			
		end
		
		if copyProperty then
			objectB[key] = property:getValue()		
		end

	end
	
end

--- Clamps a position to within bounds.
-- @param x The X position to clamp.
-- @param y The Y position to clamp.
-- @param bounds The bounding box for the clamping. A table with x, y, width and height. X and y are top left corner.
-- @return The clamped X position.
-- @return The clamped Y position.
function clampPosition(x, y, bounds)

	if math.abs(x) > bounds.width - display.contentWidth then
		x = - ( bounds.width - display.contentWidth) 
	elseif x > bounds.x then
		x = bounds.x
	end
	
	if math.abs(y) > bounds.height - display.contentHeight then
		y = - ( bounds.height - display.contentHeight )
	elseif y > bounds.y then
		y = bounds.y
	end
	
	return x, y
end

--- Calculates a viewpoint for a given position.
-- @param group The display group.
-- @param x The X position for the viewpoint.
-- @param y The Y position for the viewpoint.
-- @return The calculated viewpoint.
function calculateViewpoint(group, x, y)
	local xPos = x or (group.x + group.width / 2) -- Don't like this
	local yPos = y or (group.y + group.height / 2) -- Don't like this

	local actualPosition = { x = xPos, y = yPos }
	local centreOfView = { x = display.contentWidth / 2, y = display.contentHeight / 2}
	
	local viewPoint = { x = centreOfView.x - actualPosition.x, y = centreOfView.y - actualPosition.y }
         
	return viewPoint
end

--- Rounds a number.
-- @param number The number to round.
-- @param fudge A value to add to the number before rounding. Optional.
-- @return The rounded number.
function round(number, fudge)
	
	local fudgeValue = fudge or 0
	
	return (math.floor(number + fudgeValue))
end

--- Encodes a table into a JSON object and writes it out to a file in the documents directory.
-- @param path The path to the new file.
-- @param table The table to save.
function saveOutTable(path, table)
	
	if Json then
	
		local path = system.pathForFile( path, system.DocumentsDirectory )

		file = io.open( path, "w" )
    	file:write( Json.Encode(table) )
   		io.close( file )
   		
   	end
	
end

--- Reads a JSON object from a file and decodes it.
-- @param path The path to the file.
-- @param baseDirectory The base directory for the path. Default is system.DocumentsDirectory.
-- @return If successful returns a table with the data from the file. Otherwise returns nil.
function readInTable(path, baseDirectory)

	if Json then
		
		local path = system.pathForFile( path, baseDirectory or system.DocumentsDirectory )

		file = io.open( path, "r" )
		
		if file then
	
			local table = Json.Decode( file:read( "*a" ) ) 
	
			io.close( file )
	
			return table
			
		else
			return nil
		end
	
	end
end

--- Converts a string into a table.
-- @param string The string to convert.
-- @param delimiter What the string should be split on.
-- @return table The converted table.
function stringToIntTable(string, delimiter)

	if string then
	
    	local table = splitString(string, delimiter or " ")
        
        for i,v in ipairs(table) do 
        	table[i] = tonumber(table[i]) 
        end
        
        return table
    end
end

--- Converts a table into a string.
-- @param table The table to convert.
-- @param indent Indentation amount. Used for recursive calls.
-- @return string The converted string.
function tableToString(table, indent) 
    local str = "" 

    if(indent == nil) then 
        indent = 0 
    end 

    -- Check the type 
    if(type(table) == "string") then 
        str = str .. (" "):rep(indent) .. table .. "\n" 
    elseif(type(table) == "number") then 
        str = str .. (" "):rep(indent) .. table .. "\n" 
    elseif(type(table) == "boolean") then 
        if(table == true) then 
            str = str .. "true" 
        else 
            str = str .. "false" 
        end 
    elseif(type(table) == "table") then 
        local i, v 
        for i, v in pairs(table) do 
            -- Check for a table in a table 
            if(type(v) == "table") then 
                str = str .. (" "):rep(indent) .. i .. ":\n" 
                str = str .. tableToString(v, indent + 2) 
            else 
                str = str .. (" "):rep(indent) .. i .. ": " .. tableToString(v, 0) 
            end 
        end 
    else 
       -- print_debug(1, "Error: unknown data type: %s", type(data)) 
    end 

    return str 
end

--- Prints out a table to the Console.
-- @param table The table to print.
-- @param indent Indentation amount. Used for recursive calls.
function printTable(table, indent)
	print(tableToString(table, indent))
end

--- Loads in a config file and copies all the stored properties over to an object.
-- @param definition The value from the Tiled property.
-- @param object The object to set the properties on. Must have a setProperty function!
function readInConfigFile(definition, object)
	
	if definition and object then
		local splitDefinition = splitString(definition, "|")

		-- Set the default path and directory assuming definition is just a single string
		local baseDirectory = system.ResourceDirectory
		local path = definition
		
		if #splitDefinition == 2 then
			
			-- Get the new base directory
			local baseDirectory = system.ResourceDirectory
			
			if string.lower(splitDefinition[1]) == "resource" then
				baseDirectory = system.ResourceDirectory
			elseif string.lower(splitDefinition[1]) == "documents" then
				baseDirectory = system.DocumentsDirectory
			end
			
			-- Get the new path
			path = splitDefinition[2]
		end
		
		-- Read in and decode the data
		local configData = readInTable(path, baseDirectory )
			
		if configData then
			
			-- Set all the lovely new properties on the object
			-- First deal with the configFiles before the "normal" props
			if configData["configFiles"] then
			
				value = configData["configFiles"]
				
				for i=0, #value, 1 do
					readInConfigFile(value[i], object)
				end
			end
			
			for key, value in pairs(configData) do 
				if key ~= "configFiles" then
					object:setProperty(key, value)
				end
			end
			
			if(lime.isDebugModeEnabled()) then
				print("Lime-Lychee: Loaded Config File - " .. path)
			end
		end
		
	end
end

--- Makes tiles on screen visible.
-- Sets tiles that are just off screen to be invisible and those on screen to be visible.
-- @usage If your application has a lot of sprites that end up off screen then it may benefit from calling 
-- this function either on a per frame basis or when moving the camera/grid.
-- @param map The current Map.
function showScreenSpaceTiles(map)
	
	-- Use 1,1 to get top left corner as 0,0 returns nil
	local screenPos = {x = 1, y = 1}

	local gridPos = screenToGridPosition(map, screenPos)
	
	-- Find out how many tiles fit on screen width / height
	local numTilesScreenWidth  = display.contentWidth / map.tilewidth
	local numTilesScreenHeight = display.contentHeight / map.tileheight
	
	local tempTile  = 0
	
	-- Loop through tile layers
	for i = 1, #map.tileLayers, 1 do
		-- Loop through tile columns
		for j = (gridPos.column - 1), (gridPos.column + numTilesScreenWidth + 1), 1 do
			-- Loop through tile rows
			for k = (gridPos.row - 1), (gridPos.row + numTilesScreenHeight + 1), 1 do
				-- Grab the tile at the current row / column
				tempTile = map.tileLayers[i]:getTileAt{row = k, column = j}
				
				-- Check if there was a tile
				if tempTile then
					if j < gridPos.column or j > (gridPos.column + numTilesScreenWidth) or k < gridPos.row or k > gridPos.row + numTilesScreenHeight then
					
						-- Extra check suggested by Pavel Nakaznenko
						if (tempTile:isOnScreen()) then
							tempTile.sprite.isVisible = true
						else
							-- If the tile is just off screen make invisible					
							tempTile.sprite.isVisible = false
						end
						
						-- If the tile is just off screen make invisible
						--tempTile.sprite.isVisible = false
					else
						-- If the tile is onscreen then make visible
						tempTile.sprite.isVisible = true
					end
				end
			end
		end
	end
end

--- Safely loads an external module.
-- @param moduleName The name of the module. Ex. "ui"
-- @return The loaded module or nil if none found.
function loadModuleSafely(moduleName)

	local path = system.pathForFile(moduleName .. ".lua", system.ResourceDirectory)
	
	if path then
		return require(moduleName)
	end

end

--- Converts a string into a number safely.
-- @param string The string to convert.
-- @return The number value or the original string if not numeric.
function convertStringToNumberSafely(string)

	local numberValue = tonumber(string)
	
	if numberValue then
		return numberValue
	end
	
	return string

end

--- Converts a string into a boolean safely.
-- @param string The string to convert.
-- @return The boolean value or the original string if not a boolean.
function convertStringToBoolSafely(string)

	if type(string) ~= "string" then
		return string
	end
	
	local boolValue = stringToBool(string)
	
	if boolValue ~= nil then
		return boolValue
	end
	
	return string

end

--- Returns a value from a seed if it exists.
-- @param The value string from Tiled. Should be "seed:seedName".
-- @return The seed value or the passed in value if it is not a seed.
function getValueFromSeed(value)
	
	if value then
	
		if type(value) == "string" then
			
			local splitValue = splitString(value, ":")
			
			if #splitValue > 1 then
				
				if splitValue[1] == "seed" then
					
					local seed = loadModuleSafely("lime-seed-" .. splitValue[2])
					
					if seed then
						
						local params = nil
						
						if splitValue[3] then
							params = splitString(splitValue[3], ",")
						end
	
						return seed.main(params)
						
					end
					
				end
				
			end
			
		end
		
	end
	
	-- Not a seed property so just return whatever it is
	return value
	
end

---Converts a frame count into minutes, seconds and tenths.
-- Can be used to display a timer like this -- minutes .. ":" .. seconds .. ":" .. tenths
-- @param frameCount The count of the frames
-- @param fps The current fps. Either 30 or 60, will default to 30.
-- @return minutes Minute value.
-- @return seconds Second value.
-- @return tenths  Tenths of second value.
function convertFramesToTime(frameCount, fps)
		
	local decimalSeconds = frameCount / (fps or 30)
	local minutes = round(decimalSeconds / 60)
	decimalSeconds = decimalSeconds - (minutes * 60)
	seconds = round(decimalSeconds)
	local tenths = round((decimalSeconds - seconds) * 10)
		
	return minutes, seconds, tenths
end
