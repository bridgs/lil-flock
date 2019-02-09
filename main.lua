-- Constants
local GAME_WIDTH = 200
local GAME_HEIGHT = 200
local RENDER_SCALE = 3
local ENABLE_FLOCKING = true
local MIN_SPEED = 10
local MAX_SPEED = 70
local MATCH_SPEED_WEIGHT = 1.0
local MATCH_ROTATION_WEIGHT = 1.0
local MOVE_TOWARDS_EACH_OTHER_WEIGHT = 1.0
local RANDOMIZE_SPEED_WEIGHT = 1.0
local RANDOMIZE_ROTATION_WEIGHT = 1.0
local KEEP_DISTANCE_WEIGHT = 1.0

-- Game objects
local boids

-- Images
local boidsImage

-- Sound effects
-- ...

-- Initializes the game
function love.load()
  -- Load images
  boidsImage = love.graphics.newImage('img/boids.png')
  boidsImage:setFilter('nearest', 'nearest')

  -- Load sound effects
  -- ...

  -- Create 50 boids to start
  boids = {}
  for i = 1, 50 do
    createBoid(math.random(0, GAME_WIDTH), math.random(0, GAME_HEIGHT))
  end
end

-- Updates the game state
function love.update(dt)
  -- Get nearby boids to flock together
  if ENABLE_FLOCKING then
    for i = 1, #boids do
      local boid1 = boids[i]
      for j = i + 1, #boids do
      local boid2 = boids[j]
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
          local speedChange = MATCH_SPEED_WEIGHT * 0.5 * speedDifference * influence * dt
          boid1.speed = boundSpeed(boid1.speed + speedChange)
          boid2.speed = boundSpeed(boid2.speed - speedChange)
          -- Mimic rotation
          local rotationDifference = wrapAngle(boid2.rotation - boid1.rotation, true)
          local rotationChange = MATCH_ROTATION_WEIGHT * 0.5 * rotationDifference * influence * dt
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
            boid1.speed = boundSpeed(boid1.speed + KEEP_DISTANCE_WEIGHT * 10 * dt)
            boid2.speed = boundSpeed(boid2.speed - KEEP_DISTANCE_WEIGHT * 10 * dt)
            boid1.rotation = wrapAngle(boid1.rotation + KEEP_DISTANCE_WEIGHT * 5 * dt)
            boid2.rotation = wrapAngle(boid2.rotation - KEEP_DISTANCE_WEIGHT * 5 * dt)
          end
        end
      end
    end
  end

  -- Upate the boids' state
  for _, boid in ipairs(boids) do
    -- Randomise the boid's movement a bit
    boid.speed = boundSpeed(boid.speed + RANDOMIZE_SPEED_WEIGHT * math.random(-100, 100) * dt)
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
  -- Resize the draw area
  love.graphics.scale(RENDER_SCALE, RENDER_SCALE)

  -- Clear the screen
  love.graphics.setColor(0 / 255, 0 / 255, 0 / 255, 1)
  love.graphics.rectangle('fill', 0, 0, GAME_WIDTH, GAME_HEIGHT)

  -- Draw the boids
  love.graphics.setColor(1, 1, 1, 1)
  for _, boid in ipairs(boids) do
    drawSprite(boidsImage, boid.sprite, 7, 5, boid.rotation, boid.x, boid.y)
  end
end

-- Click to spawn more lil' boids
function love.mousepressed()
  local mouseX = love.mouse.getX() / RENDER_SCALE
  local mouseY = love.mouse.getY() / RENDER_SCALE
  createBoid(mouseX, mouseY)
end

function createBoid(x, y)
  table.insert(boids, {
    x = x,
    y = y,
    speed = math.random(MIN_SPEED, MAX_SPEED),
    rotation = math.random(0, 2 * math.pi),
    sprite = math.floor(math.random(1, 3)),
    suggestedSpeedChange = 0,
    suggestedRotationChange = 0
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

-- Draws a sprite from a sprite sheet image, spriteNum=1 is the upper-leftmost sprite
function drawSprite(image, spriteNum, spriteWidth, spriteHeight, rotation, x, y)
  local columns = math.floor(image:getWidth() / spriteWidth)
  local col = (spriteNum - 1) % columns
  local row = math.floor((spriteNum - 1) / columns)
  local quad = love.graphics.newQuad(spriteWidth * col, spriteHeight * row, spriteWidth, spriteHeight, image:getDimensions())
  love.graphics.draw(image, quad, x, y, rotation, 1, 1, spriteWidth / 2, spriteHeight / 2)
end
