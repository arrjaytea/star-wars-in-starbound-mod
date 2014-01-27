function init()
	data.active = false
	data.ranOut = false
	tech.setVisible(false)
end

function uninit()
	if data.active then
		deactivate()
        return 0
	end
end

function input(args)  
	-- Action check
	if args.moves["special"] == 1 then
		if data.active then
			return "mechDeactivate"
		else
			return "mechActivate"
		end
	elseif args.moves["jump"] then
		return "mechJump"
	elseif args.moves["right"] or args.moves["left"] then
		return "mechMove"
	end

  return nil
end

function update(args)

	-- Mech parameters
	local mechCustomMovementParameters	= tech.parameter("mechCustomMovementParameters")
	local parentOffset					= tech.parameter("parentOffset")
	local mechCollisionTest				= tech.parameter("mechTransformCollisionTest")
	
	-- Jumping
	local mechJumpCost					= tech.parameter("mechJumpCost")
	local mechJumpSpeed 				= tech.parameter("mechJumpSpeed")
	local mechJumpForce 				= tech.parameter("mechJumpForce")
	local jumpEnergyUsed				= mechJumpCost * args.dt
	local isJumping 					= false
	
	if not data.active and args.actions["mechActivate"] then
		-- Calculate new position
		tech.setAnimationState("movement", "idle")
		mechCollisionTest[1] = mechCollisionTest[1] + tech.position()[1]
		mechCollisionTest[2] = mechCollisionTest[2] + tech.position()[2]
		mechCollisionTest[3] = mechCollisionTest[3] + tech.position()[1]
		mechCollisionTest[4] = mechCollisionTest[4] + tech.position()[2]
		
		-- Check collision for activate
		if not world.rectCollision(mechCollisionTest) then
			activate()
		else
			-- Make some kind of error noise
		end
	end
	
	if data.active then		
		-- Out of energy?
		if args.availableEnergy < jumpEnergyUsed then
			data.ranOut = true
		elseif tech.onGround() or tech.inLiquid() then
			data.ranOut = false
		end
		
		-- Actions
		if args.actions["mechDeactivate"] then
			-- Deactivate mech
			deactivate()
            return 0
		elseif args.actions["mechJump"] or args.actions["mechMove"] then
            -- Move & jump effects
            if args.actions["mechJump"] and not data.ranOut then
                isJumping = true
            end
			tech.setParticleEmitterActive("moveParticles", true)
			tech.setAnimationState("movement", "move")
		else
			-- Idle effects
			tech.setParticleEmitterActive("moveParticles", false)
			tech.setAnimationState("movement", "idle")
		end
		
		-- Calculate current angle and flip state
		local diff = world.distance(args.aimPosition, tech.position())
		local aimAngle = math.atan2(diff[2], diff[1])
		local flip = aimAngle > math.pi / 2 or aimAngle < -math.pi / 2

		-- Move mech
		tech.applyMovementParameters(mechCustomMovementParameters)

		-- Flip and offset player
		if flip then
			tech.setFlipped(true)
			local nudge = tech.stateNudge()
			tech.setParentOffset({-parentOffset[1] - nudge[1], parentOffset[2] + nudge[2]})
			tech.setParentFacingDirection(-1)
		else
			tech.setFlipped(false)
			local nudge = tech.stateNudge()
			tech.setParentOffset({parentOffset[1] + nudge[1], parentOffset[2] + nudge[2]})
			tech.setParentFacingDirection(1)
		end

		if isJumping then
            if not tech.canJump() then
                tech.yControl(mechJumpSpeed, mechJumpForce, true)
                return jumpEnergyUsed
            else
                tech.yControl(mechJumpSpeed*3, mechJumpForce, true)
                return jumpEnergyUsed*2
            end
		end
	end

  return 0
end

-- Activate mech
function activate()
	local mechTransformPositionChange = tech.parameter("mechTransformPositionChange")
	
	tech.burstParticleEmitter("mechActivateParticles")
	tech.translate(mechTransformPositionChange)
	tech.setVisible(true)
	tech.setParentAppearance("sit")
	tech.setToolUsageSuppressed(true)
	data.active = true
end

-- Deactivate mech
function deactivate()
	local mechTransformPositionChange = tech.parameter("mechTransformPositionChange")
	
	tech.setAnimationState("movement", "off")
	tech.burstParticleEmitter("mechDeactivateParticles")
	
	tech.translate({-mechTransformPositionChange[1], -mechTransformPositionChange[2]})
	tech.setVisible(false)
	tech.setParentAppearance("normal")
	tech.setToolUsageSuppressed(false)
	tech.setParentOffset({0, 0})
	tech.setParentFacingDirection(nil)
	data.active = false
	return 0
end
