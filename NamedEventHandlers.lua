--[[  NamedEventHandlers.lua - .
--
-- Copyright (c) Frank Siebenlist. All rights reserved.
-- The use and distribution terms for this software are covered by the
-- Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php).
-- By using this software in any fashion, you are agreeing to be bound by
-- the terms of this license.
-- You must not remove this notice, or any other, from this software.
--
--]]

--- This NamedEventHandlers facility --
--[[
module(..., package.seeall)
--]]
local NamedEventHandlers = {}

local NamedObjects = require("NamedObjects")

NamedObjects.registerNameObject("Corona:Runtime", Runtime, "PermanentContext")
NamedObjects.registerNameObject("Corona:timer", timer, "PermanentContext")

-------------------------------------------------------------------------------
-- Event Handler Factory functions

--- Returns a timerEventHandler(event) that calls the given aSelfEventHandler(anObject,event) thru a closure over the given anObject. Furthermore, if anObject is a display object, it will registerDisplayObject(anObject), and adds auto-cancellation by checking if the anObject isDisplayObjectOrphan(anObject). Lastly, if a string is passed for anObject and/or aSelfEventHandler, the associated object or handler are looked up with getObject().
-- Auto timer-cancellation will be added to the returned handler if the anObject is either a display object or has a name-object entry. in those cases, the handler will auto-cancel when isDisplayObjectOrphan(anObject) or has no more name-object entry.
--@param anObject object or name resolving to object - possible display object 
--@param aSelfEventHandler function or name resolving to function - self-event handler signature of (anObject,event)
--@return timer event handler function with signature (event) for use with timer.performWithDelay()
function NamedEventHandlers.timerHandlerFactory(anObject, aSelfEventHandler)
	local aName, timerEventHandler
	if(type(anObject) == "string") then aName = anObject; anObject = NamedObjects.getObject(aName) end
	assert(type(anObject) == "table" or type(anObject) == "function" or type(anObject) == "userdata", "NamedObjects.timerHandlerFactory: anObject has to be a reference to or resolve to an object")
	if(type(aSelfEventHandler) == "string") then aSelfEventHandler = NamedObjects.getObject(aSelfEventHandler) end
	assert(type(aSelfEventHandler) == "function","timerHandlerFactory: aSelfEventHandler must be a function or resolve to a function thru NamedObjects.getObject(aSelfEventHandler)")
	aName = aName or NamedObjects.getName(anObject)
	NamedObjects.registerDisplayObject(anObject)
	if(aName)then
		-- auto-cancel if name-object entry is removed or if DOOrphan
		timerEventHandler = function(event)
			if(not NamedObjects.getName(anObject) or NamedObjects.isDisplayObjectOrphan(anObject))then
				NamedObjects.removeNameObject(anObject)  -- remove to be sure for DOOrphan
				print("timerHandlerFactory: cancelling timer for ", aName)
				timer.cancel(event.source)
				return
			end
			return aSelfEventHandler(anObject,event)
		end
	elseif(isDisplayObject(anObject))then  -- auto-cancel if DOOrphan
		timerEventHandler = function(event)
			if(NamedObjects.isDisplayObjectOrphan(anObject))then
				print("timerHandlerFactory: cancelling timer for display object ", aName or "*undefined*")
				timer.cancel(event.source)
				return
			end
			return aSelfEventHandler(anObject,event)
		end
	else  -- cannot deduce any auto-cancel logic - plain-vanilla closure handler construction
		timerEventHandler = function(event)
			return aSelfEventHandler(anObject,event)
		end
	end
	return timerEventHandler
end

--- Returns a runtimeEventHandler(event) that calls the given aSelfEventHandler(anObject,event) thru a closure over the given anObject. Furthermore, if anObject is a display object, it will registerDisplayObject(anObject), and adds auto-cancellation by checking if the anObject isDisplayObjectOrphan(anObject). Lastly, if a string is passed for anObject and/or aSelfEventHandler, the associated object or handler are looked up with getObject().
-- Auto timer-cancellation will be added to the returned handler if the anObject is either a display object or has a name-object entry. in those cases, the handler will auto-cancel when isDisplayObjectOrphan(anObject) or has no more name-object entry.
--@param eventTarget object - Runtime, System 
--@param eventName string - "enterFrame", "collision", "orientation", etc.
--@param anObject object or name resolving to object - possible display object 
--@param aSelfEventHandler function or name resolving to function - self-event handler signature of (anObject,event)
--@return timer event handler function with signature (event) for use with Runtime:addEventListener("enterFrame", runtimeEventHandler)
function NamedEventHandlers.eventHandlerFactory(eventTarget, eventName, anObject, aSelfEventHandler)
	--Global Events are broadcast
	-- Local Events send to single listener
	local aName, runtimeEventHandler
	if(type(anObject) == "string") then aName = anObject; anObject = NamedObjects.getObject(aName) end
	assert(type(anObject) == "table" or type(anObject) == "function" or type(anObject) == "userdata", "NamedObjects.timerHandlerFactory: anObject has to be a reference to or resolve to an object")
	if(type(aSelfEventHandler) == "string") then aSelfEventHandler = NamedObjects.getObject(aSelfEventHandler) end
	assert(type(aSelfEventHandler) == "function","timerHandlerFactory: aSelfEventHandler must be a function or resolve to a function thru NamedObjects.getObject(aSelfEventHandler)")
	aName = aName or NamedObjects.getName(anObject)
	NamedObjects.registerDisplayObject(anObject)
	if(aName)then
		-- auto-cancel if name-object entry is removed or if DOOrphan
		runtimeEventHandler = function(event)
			if(not NamedObjects.getName(anObject) or NamedObjects.isDisplayObjectOrphan(anObject))then
				NamedObjects.removeNameObject(anObject)  -- remove to be sure for DOOrphan
				print("timerHandlerFactory: cancelling timer for ", aName)
				timer.cancel(event.source)
				return
			end
			return aSelfEventHandler(anObject,event)
		end
	elseif(isDisplayObject(anObject))then  -- auto-cancel if DOOrphan
		runtimeEventHandler = function(event)
			if(NamedObjects.isDisplayObjectOrphan(anObject))then
				print("timerHandlerFactory: cancelling timer for display object ", aName or "*undefined*")
				timer.cancel(event.source)
				return
			end
			return aSelfEventHandler(anObject,event)
		end
	else  -- cannot deduce any auto-cancel logic - plain-vanilla closure handler construction
		runtimeEventHandler = function(event)
			return aSelfEventHandler(anObject,event)
		end
	end
	return runtimeEventHandler
end

-------------------------------------------------------------------------------
--- generic system table-event to local object event dispatcher
-- assigns the object-self to the event.target and then redispatches to the 
-- object itself. In that way, we can have mutiple system event handlers that
-- are tied to an object as the table-mechanism only allows us to register a
-- single system event handler with an object.
-- Usage for "enterFrame" events with a display object "ob": 
-- ob[enterFrame] = NamedEventHandlers.tableRuntimeLocalEventDispatcher
-- Register object-table event handler with Runtime like:
-- Runtime:addEventListener( "enterFrame", ob )
-- will then forward "enterFrame" event to object's event handlers like 
-- "myEnterFrameHandler(event)" that have been registered like:
-- ob:addEventListener( "enterFrame", myEnterFrameHandler )
NamedEventHandlers.tableRuntimeLocalEventDispatcher = function(self, event)
	if (not self.dispatchEvent) then 
		-- poor-man's test for display object existence
		-- if we're here, then only skeleton object exists and we should clean-up
		Runtime:removeEventListener( event.name, self )
		return true 
	else
		-- dispatch event to object itself
		-- copy as we cannot annotate and reuse the event table as bad things will happen
		local event2 = {}
		for k,v in pairs(event)do event2[k]=v end
		-- add self as the target such that the handler can find the self-state
		event2.target = self
		self:dispatchEvent(event2)
		return false
	end
end
NamedObjects.registerNameObject("tableRuntimeLocalEventDispatcher",NamedEventHandlers.tableRuntimeLocalEventDispatcher,"PermanentContext")
-------------------------------------------------------------------------------
-- Final return

return NamedEventHandlers
-------------------------------------------------------------------------------
