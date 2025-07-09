local love = require "love"
local BallTypes = require("balls")
local EnemyTypes = require("enemies")
local particleSystems = {}

local W, H = 320, 240
local scale = 3
local canvas

local dmgDoneTotal = 0
local multiplier = 1
local currBalls = {}
local currEnemies = {}
local backgroundTex
local spawnCount = 5

local shakeDuration = 0
local shakeMagnitude = 0
local shakeOffsetX, shakeOffsetY = 0, 0

local currLevel = 1
local isShopping = false
local hitTracker = {}


function applyDmg(dmg)
    dmgDoneTotal = dmgDoneTotal + dmg * multiplier
end

function clearBoth()
    dmgDoneTotal = 0
    multiplier = 1
end

function clearMult()
    multiplier = 1
end

function clearDmg()
    dmgDoneTotal = 0
end
function load_level()
    local current = currLevel
    isShopping = false
    
end


local function getEnemyHitbox(enemy)

    local spriteW = enemy.sprite:getWidth()
    local spriteH = enemy.sprite:getHeight()

    local x = enemy.pos[1] - spriteW / 2 + enemy.offset[1]
    local y = enemy.pos[2] - spriteH / 2 + enemy.offset[2]

    return {
        x = x,
        y = y,
        w = enemy.collisionshape[1],
        h = enemy.collisionshape[2]
    }
end

local function aabbCollide(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and
           bx < ax + aw and
           ay < by + bh and
           by < ay + ah
end

function spawnParticles(x, y, img)
    local ps = love.graphics.newParticleSystem(img, 50)
    ps:setParticleLifetime(0.3, 0.6)
    ps:setLinearAcceleration(-50, -50, 50, 50)
    ps:setSizes(1, 0)
    ps:setSpread(math.pi * 2)
    ps:setSpeed(50, 100)
    ps:setColors(1, 1, 1, 1, 1, 1, 1, 0)
    ps:setPosition(x, y)
    ps:emit(20)
    table.insert(particleSystems, ps)
end

function deepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function startShake(duration, magnitude)
    shakeDuration = duration
    shakeMagnitude = magnitude
end
function startTimeStop(duration)
    timeStopDuration = duration
    isTimeStopped = true
end

function love.load()
    load_level()
    

    affineShader = love.graphics.newShader("assets/shaders/ui/crt.glsl")
    affineShader:send("resolution", {W, H})
    affineShader:send("jitter", 0.002)            
    affineShader:send("alpha_scissor", 0.1) 
    math.randomseed(os.time())
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setMode(W * scale, H * scale, {fullscreen = false, resizable = false, vsync = true})
    canvas = love.graphics.newCanvas(W, H)
    canvas:setFilter("nearest", "nearest")
    backgroundTex = love.graphics.newImage("assets/sprites/boards/greenboard.png")
    backgroundTex:setFilter("nearest", "nearest")
    for i = 1, spawnCount do
        for name, temp in pairs(BallTypes) do
            local instance = deepCopy(temp)
            instance.pos[1] = math.random(21 + 8, 298 - 8)
            instance.pos[2] = math.random(49 + 8, 190 - 8)
            table.insert(currBalls, instance)
        end
    end
    for _, ball in ipairs(currBalls) do
        hitTracker[ball] = {}
    end

    for _, ball in ipairs(currBalls) do
        ball.effects.on_hit(ball)
        ball.effects.on_bounce(ball)
    end
        for name, temp in pairs(EnemyTypes) do
        local instance = deepCopy(temp)
        instance.pos[1] = math.random(21 + 8, 298 - 8)
        instance.pos[2] = math.random(49 + 8, 190 - 8)
        table.insert(currEnemies, instance)
    end
end



function love.update(dt)
    if isTimeStopped then
        timeStopDuration = timeStopDuration - dt
        if timeStopDuration <= 0 then
            isTimeStopped = false
            timeStopDuration = 0
        end
       
        return
    end

    for _, ene in ipairs(currEnemies) do
    if ene.active then
        local hitbox = getEnemyHitbox(ene)
        for _, ball in ipairs(currBalls) do
            if ball.active then
                local bx = ball.pos[1] - ball.radius
                local by = ball.pos[2] - ball.radius
                local bw = ball.radius * 2
                local bh = ball.radius * 2
                
                local collided = aabbCollide(hitbox.x, hitbox.y, hitbox.w, hitbox.h, bx, by, bw, bh)
                local alreadyHit = hitTracker[ball][ene]

                if collided and not alreadyHit then
                    -- First time hitting this enemy this collision
                    ene.health = ene.health - ball.dmg

                    if ene.health <= 0 then
                        ene.active = false
                        startShake(0.55, 2)
                        startTimeStop(0.1)
                    end

                    spawnParticles(ene.pos[1], ene.pos[2], ball.particleTex)
                    applyDmg(ball.dmg or 0)
                    if ene.active == true then 
                        startShake(0.25, 2)
                        startTimeStop(0.02)
                    end

                    

                    
                    hitTracker[ball][ene] = true
                elseif not collided and alreadyHit then
                    
                    hitTracker[ball][ene] = nil
                end
            end
        end
    

            
        end
    end
    for _, ball in ipairs(currBalls) do
        if ball.active and ball.effects.update then
            ball.effects.update(ball, dt)
        end
    end

    for i = #currBalls, 1, -1 do
        local ball = currBalls[i]
        if not ball.active then
            if ball.shouldDuplicate and ball.duplicate then
                local clones = ball:duplicate()
                for _, clone in ipairs(clones) do
                    table.insert(currBalls, clone)
                end
                ball.shouldDuplicate = false
            end
            table.remove(currBalls, i)
        end
    end

    for i = #particleSystems, 1, -1 do
        local ps = particleSystems[i]
        ps:update(dt)
        if ps:getCount() == 0 then
            table.remove(particleSystems, i)
        end
    end

    if shakeDuration > 0 then
        shakeDuration = shakeDuration - dt
        shakeOffsetX = love.math.random(-shakeMagnitude, shakeMagnitude)
        shakeOffsetY = love.math.random(-shakeMagnitude, shakeMagnitude)
    else
        shakeOffsetX, shakeOffsetY = 0, 0
    end
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(backgroundTex, 0, 0)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("DMG: " .. dmgDoneTotal, 20, 20)
    love.graphics.print("MULT: " .. multiplier, 80, 20)
    

    for _, ball in ipairs(currBalls) do
        if ball.active then
            love.graphics.setShader(ball.shader)
            ball.shader:send("outlineTex", ball.outlineTex)
            ball.shader:send("fillTex", ball.fillTex)
            ball.shader:send("maskTex", ball.maskTex)
            ball.shader:send("velocity", {ball.velocity[1], ball.velocity[2]})
            ball.shader:send("time", love.timer.getTime())
            love.graphics.draw(
                ball.fillTex,
                math.floor(ball.pos[1] + 0.5),
                math.floor(ball.pos[2] + 0.5),
                0,
                1,
                1,
                ball.fillTex:getWidth() / 2,
                ball.fillTex:getHeight() / 2
            )
            love.graphics.setShader()
        end
    end

    for _, ps in ipairs(particleSystems) do
        love.graphics.draw(ps)
    end

    for _, ene in ipairs(currEnemies) do
        if ene.active then
            love.graphics.draw(
                ene.sprite,
                math.floor(ene.pos[1] + 0.5),
                math.floor(ene.pos[2] + 0.5),
                0,1,1,ene.sprite:getWidth() / 2,
                ene.sprite:getHeight() / 2

            )
        end
    end

    love.graphics.setCanvas()

    
    

    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvas, shakeOffsetX, shakeOffsetY, 0, scale, scale)

    love.graphics.setShader(affineShader)
    love.graphics.draw(canvas, shakeOffsetX, shakeOffsetY, 0, scale, scale)
    love.graphics.setShader()
end
