-- Game constants
local GAME_WIDTH = 192
local GAME_HEIGHT = 192
local ENABLE_FLOCKING = true
local MIN_SPEED = 10
local MAX_SPEED = 70
local MIMIC_SPEED_WEIGHT = 1.0
local MIMIC_ROTATION_WEIGHT = 1.0
local MOVE_TOWARDS_EACH_OTHER_WEIGHT = 1.0
local RANDOMIZE_SPEED_WEIGHT = 1.0
local RANDOMIZE_ROTATION_WEIGHT = 1.0
local KEEP_DISTANCE_WEIGHT = 1.0
local BOID_COLORS = {
  { 205 / 255, 34 / 255, 150 / 255 },
  { 251 / 255, 134 / 255, 199 / 255 },
  { 251 / 255, 189 / 255, 182 / 255 },
  { 253 / 255, 217 / 255, 37 / 255 },
  { 252 / 255, 147 / 255, 1 / 255 },
  { 239 / 255, 59 / 255, 9 / 255 }
}

-- Game variables
local timeToPeep
local boids

-- Assets
local pushSound
local peepSounds

-- Initializes the game
function love.load()
  -- Initialize variables
  timeToPeep = 1.00

  -- Load assets
  pushSound = love.audio.newSource('sfx/push.wav', 'static')
  peepSounds = {
    love.audio.newSource('sfx/peep1.wav', 'static'),
    love.audio.newSource('sfx/peep2.wav', 'static'),
    love.audio.newSource('sfx/peep3.wav', 'static'),
    love.audio.newSource('sfx/peep4.wav', 'static')
  }

  -- Create 100 boids
  boids = {}
  for i = 1, 100 do
    createBoid(math.random(0, GAME_WIDTH), math.random(0, GAME_HEIGHT))
  end
end

-- Updates the game state
function love.update(dt)
  -- Make a random boid peep every so often
  timeToPeep = timeToPeep - dt
  if timeToPeep <= 0.00 then
    timeToPeep = math.random(0.80, 2.50)
    boids[math.random(1, #boids)].highlightTime = 0.30
    -- love.audio.play(peepSounds[math.random(1, #peepSounds)]:clone())
  end

  -- Get nearby boids to flock together
  if ENABLE_FLOCKING then
    for i = 1, #boids do
      local boid1 = boids[i]
      boid1.flockingDisabledTime = math.max(0.00, boid1.flockingDisabledTime - dt)
      boid1.highlightTime = math.max(0.00, boid1.highlightTime - dt)
      for j = i + 1, #boids do
        local boid2 = boids[j]
        if boid1.flockingDisabledTime <= 0.00 and boid2.flockingDisabledTime <= 0.00 then
          local dx = boid2.x - boid1.x
          if dx > GAME_WIDTH / 2 then
            dx = GAME_WIDTH - dx
          end
          local dy = boid2.y - boid1.y
          if dy > GAME_HEIGHT / 2 then
            dy = GAME_HEIGHT - dy
          end
          local squareDist = dx * dx + dy * dy
          if squareDist < 625 then
            local influence = math.min(math.max(0, 1.0 - squareDist / 600), 1)
            -- Mimic speed
            local speedDifference = boid2.speed - boid1.speed
            local speedChange = MIMIC_SPEED_WEIGHT * 0.5 * speedDifference * influence * dt
            boid1.speed = boundSpeed(boid1.speed + speedChange)
            boid2.speed = boundSpeed(boid2.speed - speedChange)
            -- Mimic rotation
            local rotationDifference = wrapAngle(boid2.rotation - boid1.rotation, true)
            local rotationChange = MIMIC_ROTATION_WEIGHT * 0.5 * rotationDifference * influence * dt
            boid1.rotation = wrapAngle(boid1.rotation + rotationChange)
            boid2.rotation = wrapAngle(boid2.rotation - rotationChange)
            -- Move the boids towards each other
            local angle = math.atan2(dy, dx)
            local boid1RotationChange = MOVE_TOWARDS_EACH_OTHER_WEIGHT * 0.2 * wrapAngle(boid1.rotation - angle, true) * (1 - influence) * dt
            boid1.rotation = wrapAngle(boid1.rotation - boid1RotationChange)
            local boid2RotationChange = MOVE_TOWARDS_EACH_OTHER_WEIGHT * 0.2 * wrapAngle(boid2.rotation - angle, true) * (1 - influence) * dt
            boid2.rotation = wrapAngle(boid2.rotation + boid2RotationChange)
            -- Move very close boids away from one another
            if squareDist < 25 then
              boid1.speed = boundSpeed(boid1.speed + KEEP_DISTANCE_WEIGHT * 15 * dt)
              boid2.speed = boundSpeed(boid2.speed - KEEP_DISTANCE_WEIGHT * 15 * dt)
              boid1.rotation = wrapAngle(boid1.rotation + KEEP_DISTANCE_WEIGHT * 7 * dt)
              boid2.rotation = wrapAngle(boid2.rotation - KEEP_DISTANCE_WEIGHT * 7 * dt)
            end
          end
        end
      end
    end
  end

  -- Upate the boids' state
  for _, boid in ipairs(boids) do
    -- Randomise the boid's movement a bit
    boid.speed = boundSpeed(boid.speed + RANDOMIZE_SPEED_WEIGHT * math.random(-150, 150) * dt)
    boid.rotation = wrapAngle(boid.rotation + RANDOMIZE_ROTATION_WEIGHT * math.random(-math.pi, math.pi) * dt)
    -- Move the boids
    boid.x = boid.x + boid.speed * math.cos(boid.rotation) * dt
    boid.y = boid.y + boid.speed * math.sin(boid.rotation) * dt
    -- Wrap the boids around the screen
    if boid.x < 0 then
      boid.x = GAME_WIDTH
    elseif boid.x > GAME_WIDTH then
      boid.x = 0
    end
    if boid.y < 0 then
      boid.y = GAME_HEIGHT
    elseif boid.y > GAME_HEIGHT then
      boid.y = 0
    end
  end
end

-- Renders the game
function love.draw()
  -- Clear the screen
  love.graphics.clear(157 / 255, 23 / 255, 107 / 255)

  -- Draw the boids
  for _, boid in ipairs(boids) do
    if boid.highlightTime > 0.00 then
      love.graphics.setColor(251 / 255, 238 / 255, 230 / 255)
      love.graphics.circle('line', boid.x, boid.y, 6)
      love.graphics.circle('line', boid.x, boid.y, 8)
      love.graphics.circle('line', boid.x, boid.y, 10)
    else
      love.graphics.setColor(boid.color)
    end
    love.graphics.polygon('fill', 
      boid.x + 5 * math.cos(boid.rotation), boid.y + 5 * math.sin(boid.rotation),
      boid.x + 4 * math.cos(boid.rotation + 0.8 * math.pi), boid.y + 4 * math.sin(boid.rotation + 0.8 * math.pi),
      boid.x + 4 * math.cos(boid.rotation - 0.8 * math.pi), boid.y + 4 * math.sin(boid.rotation - 0.8 * math.pi))
  end
end

-- Click to spawn more lil' boids
function love.mousepressed(x, y)
  local mouseX = x
  local mouseY = y
  for _, boid in ipairs(boids) do
    local dist, dx, dy = calculateDistance(mouseX, mouseY, boid.x, boid.y)
    if dist < 35 then
      boid.x = boid.x + 4 * dx / dist
      boid.y = boid.y + 4 * dy / dist
      boid.rotation = math.atan2(dy, dx)
      boid.flockingDisabledTime = 0.5
    end
  end
  love.audio.play(pushSound:clone())
end

-- Creates a new boid
function createBoid(x, y)
  table.insert(boids, {
    x = x,
    y = y,
    color = BOID_COLORS[math.random(1, #BOID_COLORS)],
    speed = math.random(MIN_SPEED, MAX_SPEED),
    rotation = math.random(0, 2 * math.pi),
    sprite = math.floor(math.random(1, 3)),
    highlightTime = 0.00,
    flockingDisabledTime = 0.00
  })
end

-- Takes in an angle in radians and returns the same angle bounded to 0 and 2 * math.pi,
--  or -math.pi and math.pi if allowNegative is set to true
function wrapAngle(angle, allowNegative)
  local wrappedAngle = ((angle % (2 * math.pi)) + 2 * math.pi) % (2 * math.pi)
  if allowNegative and wrappedAngle > math.pi then
    wrappedAngle = math.pi - wrappedAngle
  end
  return wrappedAngle
end

-- Keeps the given speed between MIN_SPEED and MAX_SPEED
function boundSpeed(speed)
  return math.min(math.max(MIN_SPEED, speed), MAX_SPEED)
end

-- Calculates the distance between two points
function calculateDistance(x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  local dist = math.sqrt(dx * dx + dy * dy)
  return dist, dx, dy
end
