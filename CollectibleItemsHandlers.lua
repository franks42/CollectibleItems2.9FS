module(..., package.seeall)

local ui = require("ui")
local NamedObjects = require("NamedObjects")
local NamedEventHandlers = require("NamedEventHandlers")

local STATE_IDLE = "Idle"
local STATE_WALKING = "Walking"
local STATE_JUMPING = "Jumping"
local DIRECTION_LEFT = -1
local DIRECTION_RIGHT = 1

-------------------------------------------------------------------------------
-- HUD Event Listeners

local onButtonLeftEvent = function(event)
	local player = NamedObjects.getObject("player")
	if(not player)then return end
	if event.phase == "press" then
		player.direction = DIRECTION_LEFT
		player.xScale = player.direction
		player.state = STATE_WALKING	
	else
		player.state = STATE_IDLE
	end
	player:prepare("anim" .. player.state)
	player:play()
end
NamedObjects.registerNameObject("onButtonLeftEvent",onButtonLeftEvent, "PermanentContext")

local onButtonRightEvent = function(event)
	local player = NamedObjects.getObject("player")
	if(not player)then return end
	if event.phase == "press" then
		player.direction = DIRECTION_RIGHT
		player.xScale = player.direction
		player.state = STATE_WALKING	
	else
		player.state = STATE_IDLE
	end
	player:prepare("anim" .. player.state)
	player:play()
end
NamedObjects.registerNameObject("onButtonRightEvent",onButtonRightEvent, "PermanentContext")

local onButtonAPress = function(event)
	local player = NamedObjects.getObject("player")
	if(not player)then return end
	if player.canJump then
		player:applyLinearImpulse(0, -5, player.x, player.y)
		player.state = STATE_JUMPING
		player:prepare("anim" .. player.state)
		player:play()
	end
end
NamedObjects.registerNameObject("onButtonAPress",onButtonAPress, "PermanentContext")

local onButtonBPress = function(event)
end
NamedObjects.registerNameObject("onButtonBPress",onButtonBPress, "PermanentContext")

-------------------------------------------------------------------------------
-- collision and enterFrame Event Listeners that define players movement 
-- based on player's state.

local function onCollisionPlayer(event )
	local player = event.target
	if(not player)then return end

 	if ( event.phase == "began" ) then
		if event.other.IsGround then
			player.canJump = true			
			if player.state == STATE_JUMPING then
				player.state = STATE_IDLE
				player:prepare("anim" .. player.state)
				player:play()
			end
		elseif event.other.IsPickup then
			local item = event.other
			-- Fade out the item
			transition.to(item, {time = 500, alpha = 0, onComplete = NamedObjects.getObject("onTransitionEndRemoveSelf")})
			-- Show score
			local text = nil
			if item.pickupType == "score" then
				text = display.newText( item.scoreValue .. " Points!", 0, 0, "Helvetica", 50 )
			elseif item.pickupType == "health" then
				text = display.newText( item.healthValue .. " Extra Health!", 0, 0, "Helvetica", 50 )
			end
			if text then
				text:setTextColor(100, 100, 100)
				text.x = display.contentCenterX
				text.y = text.height / 2
				transition.to(text, {time = 1000, alpha = 0, onComplete = NamedObjects.getObject("onTransitionEndRemoveSelf")})
			end
		end
	elseif ( event.phase == "ended" ) then
		if event.other.IsGround then
			player.canJump = false
		end
	end
end
NamedObjects.registerNameObject("onCollisionPlayer",onCollisionPlayer, "PermanentContext")

local dumpOnce = NamedObjects.callOnce(NamedObjects.dumpKV)

local function onUpdate(event)
	--dumpOnce(event)
	local target = event.target or Runtime
	local thisFunction = onUpdate
	local player = event.other or NamedObjects.getObject("player")
	if(player==nil or not NamedObjects.isDisplayObject(player))then 
		print("player is dead", player,event.name,thisFunction,onUpdate,target)
		NamedObjects.dumpKV(event)
		target:removeEventListener( event.name, thisFunction )
		return 
	end
	if player.state == STATE_WALKING then		
		player:applyForce(player.direction * 10, 0, player.x, player.y)	
	elseif player.state == STATE_IDLE then
		local vx, vy = player:getLinearVelocity()
		if vx ~= 0 then
			player:setLinearVelocity(vx * 0.9, vy)
		end
	end
end
NamedObjects.registerNameObject("onUpdate",onUpdate, "PermanentContext")
