local love = require "love"

enemyTypes ={}

enemyTypes.Squid = {
    name = "squid",
    pos = {0 , 0},
    health = 28,
    collisionshape = {13,14},
    offset = {2,1},
    effects = {
        update = function (self)
        end
    },
    sprite = (function (self)
        
        local spr = love.graphics.newImage("assets/sprites/enemies/squidli1.png")
        spr:setFilter("nearest", "nearest")
        return spr
    end)(),
    active = true
    
}

return enemyTypes