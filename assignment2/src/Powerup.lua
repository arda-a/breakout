--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Arda Abaka

    This Powerup should spawn randomly, be it on a timer or when the Ball hits a Block enough times,
    and gradually descend toward the player. Once collided with the Paddle, two more Balls should spawn 
    and behave identically to the original, including all collision and scoring points for the player. 
    Once the player wins and proceeds to the VictoryState for their current level, the Balls should reset so that there is only one active again.
]]

Powerup = Class{}

function Powerup:init(x,y,powerupType)
    -- simple positional and dimensional variables
    self.width = 16
    self.height = 16

    self.x = x
    self.y = y

    -- these variables are for keeping track of our velocity on both the
    -- X and Y axis, since the ball can move in two dimensions
    self.dy = 3
    self.dx = 0

    self.powerupType = powerupType
    self.inPlay = true
end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    return true
end

function Powerup:update(dt)
    --acceleration towards the player
    self.dy = self.dy + 0.3
    self.y = self.y + self.dy * dt

    if self.y >= VIRTUAL_HEIGHT then
        self.inPlay = false
    end
end

function Powerup:render()
    if self.inPlay then
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.powerupType], self.x, self.y)
    end
end