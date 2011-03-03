--[[  NamedObjects.lua - Garbage-collection friendly name-object & object-name mapping facility.
--
-- Copyright (c) Frank Siebenlist. All rights reserved.
-- The use and distribution terms for this software are covered by the
-- Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php).
-- By using this software in any fashion, you are agreeing to be bound by
-- the terms of this license.
-- You must not remove this notice, or any other, from this software.
--
--]]

--- Garbage-collection friendly name-object and object-name mapping facility.
--
--[[
module("NamedObjects")  -- only here to please luadoc
--]]

-- module-table to be returned
local NamedObjects = {}

-------------------------------------------------------------------------------
-- Localize the main functions

local registerDisplayObject, registerNameObject, getObject, getName, removeNameObject, removeNameObjectContext = NamedObjects.registerDisplayObject, NamedObjects.registerNameObject, NamedObjects.getObject, NamedObjects.getName, NamedObjects.removeNameObject, NamedObjects.removeNameObjectContext

-------------------------------------------------------------------------------
-- for every context, we have an association  of two mapping tables
-- anAssocT = AssocTForContextT[aContext]
-- aNameForObjectT  = anAssocT.nameForObjectT
-- anObjectForNameT = anAssocT.objectForNameT
-- aName = aNameForObjectT[anObject]
-- anObject = aNameForObjectT[aName]

local AssocTForContextT = setmetatable({}, {__mode = 'k'})

-- we maintain a "weak" table-set for mappings without a context
-- i.e. the caller should maintain the context
local WeakContextT = {}
local NameForObjectWeakT = setmetatable({}, {__mode = 'k'})
local ObjectForNameWeakT = setmetatable({}, {__mode = 'v'})
local WeakAssocT = {}
WeakAssocT.nameForObjectT = NameForObjectWeakT
WeakAssocT.objectForNameT = ObjectForNameWeakT
AssocTForContextT[WeakContextT] = WeakAssocT

-- predefine a PermanentContext that holds on to object refs
local PermanentContextT = {}
AssocTForContextT[PermanentContextT] = {["nameForObjectT"] = {}, ["objectForNameT"] = {}}

-- Prepopulate for name-object for PermanentContext and WeakContext with PermanentContext
AssocTForContextT[PermanentContextT].objectForNameT["PermanentContext"] = PermanentContextT
AssocTForContextT[PermanentContextT].nameForObjectT[PermanentContextT] = "PermanentContext"
AssocTForContextT[PermanentContextT].objectForNameT["WeakContext"] = WeakContextT
AssocTForContextT[PermanentContextT].nameForObjectT[WeakContextT] = "WeakContext"

-- table to register display objects - used to detect orphans
local displayObjectT = setmetatable({}, {__mode = 'k'})

-------------------------------------------------------------------------------
-- local helper functions

-- Local function to remove a name-object entry by name
local function removeByName(aName)
	for aContext, anAssocT in pairs(AssocTForContextT) do
		local anObject = anAssocT.objectForNameT[aName]
		if(anObject) then 
			anAssocT.objectForNameT[aName] = nil
			anAssocT.nameForObjectT[anObject] = nil
			return anObject
		end
	end
	return nil
end

-- Local function to remove a name-object entry by object
local function removeByObject(anObject)
	for aContext, anAssocT in pairs(AssocTForContextT) do
		local aName = anAssocT.nameForObjectT[anObject]
		if(aName) then 
			anAssocT.objectForNameT[aName] = nil
			anAssocT.nameForObjectT[anObject] = nil
			return aName
		end
	end
	return nil
end

local function objectOrDOOrphan(anObject)
	if(NamedObjects.isDisplayObjectOrphan(anObject))then return nil, anObject
	else return anObject end
end


-------------------------------------------------------------------------------
-- Corona specific functions

local coronaMetaTable = getmetatable(display.getCurrentStage())

--- Returns whether aDisplayObject is a Corona display object.
-- note that all Corona types seem to share the same metatable, which is used for the test.
--@param aDisplayObject table - possible display object.
--@param autoDORegister boolean - default is true.
--@return boolean - true if object is a display object
NamedObjects.isDisplayObject = function(aDisplayObject, autoDORegister)
	autoRegister = autoRegister or true
	local res = (type(aDisplayObject) == "table" and getmetatable(aDisplayObject) == coronaMetaTable)
	if(res)then
		if(autoDORegister)then displayObjectT[aDisplayObject] = true end
		return true
	else return false end
end

--- Returns whether aDisplayObject is registered as a display object.
function NamedObjects.isRegisteredDisplayObject(aDisplayObject)
	return aDisplayObject~=nil and displayObjectT[aDisplayObject]==true
end

--- If the object aDisplayObject is a display object, then it is registered in a weak table as a display object.
--@param aDisplayObject object that is registered as a display object if it is one.
--@return boolean - true if aDisplayObject is registered - false otherwise.
function NamedObjects.registerDisplayObject(aDisplayObject)
	return NamedObjects.isDisplayObject(aDisplayObject, true)
end

--- Returns whether anObject is an orphaned display object, i.e. a former display object that has been removeSelf'ed. The latter has removed the display object's functionality but leaves a table orphan. Detection can be used to avoid further usage and to remove for example event handlers registered for that object. Correct detection depends on previous registration thru implicit or explicit registerDisplayObject().
--@return boolean - true means anObject is an orphaned DO, while false means dunno...(as a DO may not have been registered)
function NamedObjects.isDisplayObjectOrphan(anObject)
	if(anObject==nil)then return false end
	NamedObjects.registerDisplayObject(anObject)
	return NamedObjects.isRegisteredDisplayObject(anObject) and (not NamedObjects.isDisplayObject(anObject))
end

-------------------------------------------------------------------------------
-- Main functions

--- Register the mapping of anObject and aName within aContext.
-- The name-object association is a 1-1 unique mapping within the application. The names are
-- unique and will only point at one object at the time while the objects will only map to a single name at
-- the time. Reregistering a name with an other object will result in a removal of any existing name-object mapping entry.
-- The context refers to the object that the mapping is anchored to for its life-time and existence.
-- As long as the context exists and is not garbage collected, the mapping entry will exist.
-- A context object can be garbage collected if the application doesn't hold any more references to it.
-- One can also explicitly remove a single name-object mapping with removeNameObjectContext(aNameOrAnObject), or all name-object mappings associated with a context thru removeNameObjectContext(aContext).
-- There are two predefined contexts to facility common use cases that are refered to thru the follwoing names: "WeakContext" and "PermanentContext".
-- If the context to a name-object mapping is "WeakContext", then this mapping will be removed if the object itself 
-- gets garbage collected or explictly removed. 
-- If the context to name-object mapping is "PermanentContext", then the name-object facility will hold real references to the object such that it will remain to exist for the duration of the program even if the application itself doesn't hold anymore references to it.
--@param aName string unique identifier for anObject within the application
--@param anObject object/table/function to be mapped to aName
--@param aContext object/table/function or resolvable name - name-object association is linked to existence of this context - if this object is garbage collected or removed then the name-object association is removed also.
function NamedObjects.registerNameObject(aName, anObject, aContext)
	assert( type(aName) == "string", "NamedObjects.registerNameObject: aName has to be a string and not equal to WeakContext or PermanentContext" )
	assert(type(anObject) == "table" or type(anObject) == "function" or type(anObject) == "userdata", "NamedObjects.registerNameObject: anObject has to be a referenced object")
	assert(aName ~= "WeakContext" and aName ~= "PermanentContext" and anObject ~= WeakContextT and anObject ~= PermanentContextT,"NamedObjects.registerNameObject: cannot change WeakContext or PermanentContext name-object mapping")
	if(type(aContext) == "string") then
		if(aContext == aName)then aContext = anObject
		else aContext = NamedObjects.getObject(aContext) end
	end
	assert(type(aContext) == "table" or type(aContext) == "function" or type(aContext) == "userdata", "NamedObjects.registerNameObject: aContext has to be or resolve to a referenced object")
	-- first remove any existing association within any possible context - name-object is 1-1 unique mapping
	NamedObjects.registerDisplayObject(anObject)
	NamedObjects.registerDisplayObject(aContext)
	removeByName(aName)
	removeByObject(anObject)
	-- find the Context specific mapping table - create if not found
	local assocT = AssocTForContextT[aContext]
	if(assocT == nil)then  -- create entry
		AssocTForContextT[aContext] = {["nameForObjectT"] = {}, ["objectForNameT"] = {}}
		assocT = AssocTForContextT[aContext]
	end
	-- assign the two-way mapping
	assocT.nameForObjectT[anObject] = aName
	assocT.objectForNameT[aName] = anObject
end


--- Returns the registered object for aName - note that the name-object mapping is 1-1 and unique within the app's context.
-- If object is an orphaned display object (DO), returns nil plus the orphaned object
--@param aName string - name for object
--@return object or nil if not found - nil,object for orphaned DO
function NamedObjects.getObject(aName)
	assert( type(aName) == "string", "NamedObjects.getObject: aName has to be a string" )
	for aContext, anAssocT in pairs(AssocTForContextT) do
		local anObject = anAssocT.objectForNameT[aName]
		if(anObject)then return objectOrDOOrphan(anObject) end
	end
	return nil
end


--- Returns the registered name for anObject - note that the name-object mapping is 1-1 and unique within the app's context.
-- If object is an orphaned display object (DO), returns nil plus the orphaned object's name
--@param anObject object
--@return string (name) or nil if not found - nil,string for orphaned DO
function NamedObjects.getName(anObject)
	assert(type(anObject) == "table" or type(anObject) == "function" or type(anObject) == "userdata", "NamedObjects.getName: anObject has to be a reference to a object")
	NamedObjects.registerDisplayObject(anObject)
	for aContext, anAssocT in pairs(AssocTForContextT) do
		local aName = anAssocT.nameForObjectT[anObject]
		if(aName) then
			if(NamedObjects.isDisplayObjectOrphan(anObject))then return nil, aName 
			else return aName end
		end
	end
	return nil
end

--- Removes map-entry for given aNameOrObject from name-object registration system. 
-- Application logic should not rely on any garbage collection for the removal of name-object mappings,
-- but should instead remove mapping entries explictly thru removeNameObject() or removeNameObjectContext(). Note that no (display-)objects are actually removed or deleted, only their name-object mapping entry is removed. Although removing the mapping entry may remove the last explicit reference which may result in a garbage collection of the object.
--@param aNameOrObject - if string removes name-object entry associated with that name - if object removes entry associated with that object (note that WeakContext or PermanentContext entries cannot be removed)
--@return name or object - the other part of any found association
function NamedObjects.removeNameObject(aNameOrObject)
	if(aNameOrObject == nil)then return end  -- bad corner case
	if(type(aNameOrObject) == "string")then 
		assert(aNameOrObject ~= "WeakContext" and aNameOrObject ~= "PermanentContext","NamedObjects.removeNameObject: cannot remove WeakContext or PermanentContext name-object mapping")
		-- find and remove any existing object for name mapping
		return removeByName(aNameOrObject)
	else
		assert(aNameOrObject ~= WeakContextT and aNameOrObject ~= PermanentContextT,"NamedObjects.removeNameObject: cannot remove WeakContext or PermanentContext name-object mapping")
		-- find and remove any existing name for object mapping
		NamedObjects.registerDisplayObject(aNameOrObject)
		return removeByObject(aNameOrObject)
	end
end

--- Removes all name-objects mappings associated with aContext and returns an array-table with references to all removed objects. The latter can optionally be used for clean-up purposes.
-- Application logic should not rely on any garbage collection for the removal of name-object mappings,
-- but should instead remove mapping entries explictly thru removeNameObject() or removeNameObjectContext(). Note that no (display-)objects are actually removed or deleted, only their name-object mapping entry is removed. Although removing the mapping entry may remove the last explicit reference which may result in a garbage collection of the object.
--@param aContext object or name - (note that WeakContext or PermanentContext cannot be removed)
--@return array-table with all objects that were part of the removed mappings (for possible cleanup purposes)
function NamedObjects.removeNameObjectContext(aContext)
	if(type(aContext) == "string") then aContext = NamedObjects.getObject("aContext") end
	if(aContext==nil or AssocTForContextT[aContext]==nil) then return {} end
	assert(aContext ~= WeakContextT and aContext ~= PermanentContextT,"NamedObjects.removeNameObjectContext: cannot remove WeakContext or PermanentContext")
	local objectsT = {}
	local anAssocT = AssocTForContextT[aContext]
	for anObject,aName in pairs(anAssocT.nameForObjectT)do
		table.insert(objectsT,anObject)
	end
	AssocTForContextT[aContext] = nil -- blow away the context table
	return objectsT
end


-------------------------------------------------------------------------------
-- Debug functions

-- (Debug) Returns an array-table of all registered context-objects.
--@return array-table of all context-objects.
function NamedObjects.getAllContexts()
	local contextsT = {}
	for aContext, _anAssocT in pairs(AssocTForContextT)do
		table.insert(contextsT,aContext)
	end
	return contextsT
end

-- (Debug) Returns two array-tables of all the registered names and objects within aContext or within all contexts if aContext==nil.
--@param aContext object - default==nil implies for all contexts
--@return list of two array-tables with all names and all objects found in the context's name-object mappings.
function NamedObjects.getAllNamesAllObjects(aContext)
	local afcT
	if(aContext ~= nil)then
		if(AssocTForContextT[aContext] == nil) then return {} end
		afcT = {[aContext] = AssocTForContextT[aContext]}
	end
	afcT = afcT or AssocTForContextT
	local namesT,objectsT = {},{}
	for _c, anAssocT in pairs(afcT)do
		for anObject,aName in pairs(anAssocT.nameForObjectT)do
			table.insert(namesT,aName)
			table.insert(objectsT,anObject)
		end
	end
	table.sort(namesT)
	return namesT,objectsT
end

-- (Debug) Dumps content of all internal mapping tables to stdout.
function NamedObjects.dump()
	print("start NamedObjects.dump")
	local n=0; for k,v in pairs(displayObjectT)do n = n+1 end
--	print("NdisplayObjectT:",n)
	for k,v in pairs(displayObjectT)do print("displayObjectT:", k,v) end
	for aContext, anAssocT in pairs(AssocTForContextT) do
		for name,object in pairs(anAssocT.objectForNameT) do
			print("aContext,name,object",aContext, name,object)
		end
--		for object,name in pairs(anAssocT.nameForObjectT) do
--			print("nameForObjectT:",object,name)
--		end
	end
	print("end NamedObjects.dump")
end

-- (Debug) Dumps content of all internal mapping tables to stdout.
function NamedObjects.dumpKV(t,s)
	local s = s or ""
	local ksk,ks,kv = {},{},{}
	for k,v in pairs(t)do ksk[tostring(k)]=k; table.insert(ks,tostring(k)) end
	table.sort(ks)		
	for i,kk in ipairs(ks)do table.insert(kv,"["..kk.."]".."="..tostring(t[ksk[kk]])) end
	s = s .. "{" .. tostring(t).." "..table.concat(kv,", ") .."}"
	print(s)
end

function NamedObjects.callOnce(aFunction)
	local once = true
	return function(...) if(once)then aFunction(...);once=false end end
end



-------------------------------------------------------------------------------
-- Final return
return NamedObjects
-------------------------------------------------------------------------------

