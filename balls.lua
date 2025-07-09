local ballShaders = require "ballShaders"
local love = require "love"
local BallTypes = {}

BallTypes.White = {
    name = "cue ball",
    pos = {0, 0},
    velocity = {400, 400},
    radius = 8,
    bouncesLeft = 10,
    dmg = 8.5,
    pierce = false,
    active = true,
    dmgDone = 0,
    tags = {},
    friction = 0.75,
    shouldDuplicate = false,

    particleTex = (function()
        local img = love.graphics.newImage("assets/sprites/balls/particles/cue_ball.png")
        img:setFilter("nearest", "nearest")
        return img
    end)(),

    shader = ballShaders["default"],
    outlineTex = (function()
        local img = love.graphics.newImage("assets/sprites/balls/outline/blackOutline.png")
        img:setFilter("nearest", "nearest")
        return img
    end)(),

    fillTex = (function()
        local img = love.graphics.newImage("assets/sprites/balls/textures/white.png")
        img:setFilter("nearest", "nearest")
        return img
    end)(),

    maskTex = (function()
        local img = love.graphics.newImage("assets/sprites/balls/alpha/blackOutline.png")
        img:setFilter("nearest", "nearest")
        return img
    end)(),

    duplicate = function(self)
        local clones = {}
        for i = 1, 2 do
            local newBall = {}
            for k, v in pairs(self) do
                if type(v) == "table" then
                    newBall[k] = {}
                    for kk, vv in pairs(v) do
                        newBall[k][kk] = vv
                    end
                else
                    newBall[k] = v
                end
            end
            local angle = math.random() * 2 * math.pi
            newBall.pos = {self.pos[1], self.pos[2]}
            newBall.velocity = {math.cos(angle) * 150, math.sin(angle) * 150}
            newBall.bouncesLeft = 3
            newBall.dmgDone = 0
            newBall.active = true
            newBall.shouldDuplicate = false
            table.insert(clones, newBall)
        end
        return clones
    end,

    effects = {
        on_hit = function(self)
            self.dmgDone = self.dmgDone + self.dmg
            
        end,

        on_bounce = function(self)
            self.bouncesLeft = self.bouncesLeft - 1
            if self.bouncesLeft <= 0 then
                self.active = false
                self.shouldDuplicate = false
                spawnParticles(self.pos[1], self.pos[2], self.particleTex)
            end
        end,

        update = function(self, dt)
            self.pos[1] = self.pos[1] + self.velocity[1] * dt
            self.pos[2] = self.pos[2] + self.velocity[2] * dt
            local f = math.pow(self.friction, dt)
            self.velocity[1] = self.velocity[1] * f
            self.velocity[2] = self.velocity[2] * f

            local speedSqr = self.velocity[1]^2 + self.velocity[2]^2
            if speedSqr < 3500 then
                self.active = false
                self.shouldDuplicate = true
                spawnParticles(self.pos[1], self.pos[2], self.particleTex)
                return
            end

            local bounced = false

            if self.pos[1] - self.radius < 21 then
                self.pos[1] = 21 + self.radius
                self.velocity[1] = -self.velocity[1]
                bounced = true
            elseif self.pos[1] + self.radius > 298 then
                self.pos[1] = 298 - self.radius
                self.velocity[1] = -self.velocity[1]
                bounced = true
            end

            if self.pos[2] - self.radius < 49 then
                self.pos[2] = 49 + self.radius
                self.velocity[2] = -self.velocity[2]
                bounced = true
            elseif self.pos[2] + self.radius > 190 then
                self.pos[2] = 190 - self.radius
                self.velocity[2] = -self.velocity[2]
                bounced = true
            end

            if bounced then
                self.effects.on_bounce(self)
            end
        end
    }
}

return BallTypes
