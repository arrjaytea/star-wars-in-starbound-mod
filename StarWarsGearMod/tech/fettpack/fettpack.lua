function init()
  data.lastJump = false
  data.lastBoost = nil
  data.ranOut = false
end

function input(args)
  local currentJump = args.moves["jump"]
  local currentBoost = nil

  if not tech.onGround() then
    if not tech.canJump() and currentJump and not data.lastJump then
      if args.moves["right"] and args.moves["up"] then
        currentBoost = "boostRightUp"
      elseif args.moves["right"] and args.moves["down"] then
        currentBoost = "boostRightDown"
      elseif args.moves["left"] and args.moves["up"] then
        currentBoost = "boostLeftUp"
      elseif args.moves["left"] and args.moves["down"] then
        currentBoost = "boostLeftDown"
      elseif args.moves["right"] then
        currentBoost = "boostRight"
      elseif args.moves["down"] then
        currentBoost = "boostDown"
      elseif args.moves["left"] then
        currentBoost = "boostLeft"
      elseif args.moves["up"] then
        currentBoost = "boostUp"
      end
    elseif currentJump and data.lastBoost then
      currentBoost = data.lastBoost
    end
  end

  data.lastJump = currentJump
  data.lastBoost = currentBoost

  return currentBoost
end

function update(args)
  local boostControlForce = tech.parameter("boostControlForce")
  local boostSpeed = tech.parameter("boostSpeed")
  local energyUsagePerSecond = tech.parameter("energyUsagePerSecond")
  local energyUsage = energyUsagePerSecond * args.dt

  if args.availableEnergy < energyUsage then
    data.ranOut = true
  elseif tech.onGround() or tech.inLiquid() then
    data.ranOut = false
  end

  local boosting = false
  local diag = 1 / math.sqrt(2)

  if not data.ranOut then
    boosting = true
    if args.actions["boostRightUp"] then
      tech.control({boostSpeed * diag, boostSpeed * diag}, boostControlForce, true, true)
    elseif args.actions["boostRightDown"] then
      tech.control({boostSpeed * diag, -boostSpeed * diag}, boostControlForce, true, true)
    elseif args.actions["boostLeftUp"] then
      tech.control({-boostSpeed * diag, boostSpeed * diag}, boostControlForce, true, true)
    elseif args.actions["boostLeftDown"] then
      tech.control({-boostSpeed * diag, -boostSpeed * diag}, boostControlForce, true, true)
    elseif args.actions["boostRight"] then
      tech.control({boostSpeed, 0}, boostControlForce, true, true)
    elseif args.actions["boostDown"] then
      tech.control({0, -boostSpeed}, boostControlForce, true, true)
    elseif args.actions["boostLeft"] then
      tech.control({-boostSpeed, 0}, boostControlForce, true, true)
    elseif args.actions["boostUp"] then
      tech.control({0, boostSpeed}, boostControlForce, true, true)
    else
      boosting = false
    end
  end

  if boosting then
    tech.setAnimationState("boosting", "on")
    tech.setParticleEmitterActive("boostParticles", true)
    return energyUsage
  else
    tech.setAnimationState("boosting", "off")
    tech.setParticleEmitterActive("boostParticles", false)
    return 0
  end
end
