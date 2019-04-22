--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--paddle size increase counter related to self.score
local paddleSizeIncreaseCounter = 0

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.level = params.level

    self.recoverPoints = params.recoverPoints

    for k, ball in pairs(self.balls) do
        -- give ball random starting velocity
        ball.dx = math.random(-200, 200)
        ball.dy = math.random(-50, -60)
    end

    
    paddleSizeIncreaseCounter = math.floor(self.score / 5000)
    
    --active powerups
    self.powerups = {}

    --Are bricks unlocked, if any. They are only going to be unlocked if unlock powerup is claimed.
    self.bricksUnlocked = false
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)


    for k, ball in pairs(self.balls) do
        ball:update(dt)

        if ball:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        ball.y = self.paddle.y - 8
        ball.dy = -ball.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
        end

        gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do
        for k, ball in pairs(self.balls) do
            if ball ~= nil then
            -- only check collision if we're in play
                if brick.inPlay and ball:collides(brick) then

                    -- add to score
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)                      

                    -- trigger the brick's hit function, which removes it from play
                    brick:hit()

                    --if a brick hit two times, spawn a Powerup with 50 percent chance.
                    if brick.hitCount == 2 and math.random(0,1) == 1 then
                        local rndmPowerupType = math.random(9,10)
                        if not rndmPowerupType == 10 or not self.bricksUnlocked then
                            table.insert(self.powerups, Powerup(brick.x, brick.y, rndmPowerupType))
                        end
                    end

                    -- if we have enough points, recover a point of health
                    if self.score > self.recoverPoints then
                        -- can't go above 3 health
                        self.health = math.min(3, self.health + 1)

                        -- multiply recover points by 2
                        self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                        -- play recover sound effect
                        gSounds['recover']:play()
                    end

                    -- go to our victory screen if there are no more bricks left
                    if self:checkVictory() then
                        gSounds['victory']:play()

                        gStateMachine:change('victory', {
                            level = self.level,
                            paddle = self.paddle,
                            health = self.health,
                            score = self.score,
                            highScores = self.highScores,
                            ball = ball,
                            recoverPoints = self.recoverPoints
                        })
                    end

                    --
                    -- collision code for bricks
                    --
                    -- we check to see if the opposite side of our velocity is outside of the brick;
                    -- if it is, we trigger a collision on that side. else we're within the X + width of
                    -- the brick and should check to see if the top or bottom edge is outside of the brick,
                    -- colliding on the top or bottom accordingly 
                    --

                    -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                    if ball.x + 2 < brick.x and ball.dx > 0 then
                        
                        -- flip x velocity and reset position outside of brick
                        ball.dx = -ball.dx
                        ball.x = brick.x - 8
                    
                    -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                    elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                        
                        -- flip x velocity and reset position outside of brick
                        ball.dx = -ball.dx
                        ball.x = brick.x + 32
                    
                    -- top edge if no X collisions, always check
                    elseif ball.y < brick.y then
                        
                        -- flip y velocity and reset position outside of brick
                        ball.dy = -ball.dy
                        ball.y = brick.y - 8
                    
                    -- bottom edge if no X collisions or top collision, last possibility
                    else
                        
                        -- flip y velocity and reset position outside of brick
                        ball.dy = -ball.dy
                        ball.y = brick.y + 16
                    end

                    -- slightly scale the y velocity to speed up the game, capping at +- 150
                    if math.abs(ball.dy) < 150 then
                        ball.dy = ball.dy * 1.02
                    end

                    -- only allow colliding with one brick, for corners
                    goto brickLoopBreak
                end
            end
        end
    end
    ::brickLoopBreak::

    --Increase the paddle size every 5000 points.
    if math.floor(self.score / 5000) > paddleSizeIncreaseCounter and self.paddle.size < 3 then
        paddleSizeIncreaseCounter = paddleSizeIncreaseCounter + 1
        self.paddle.size = self.paddle.size + 1
    end 

    --Check if the ball table is empty
    local ballCounter = 0
    for k, ball in pairs(self.balls) do
        if ball ~= nil then
            ballCounter = ballCounter + 1
        end
    end   

    -- if ball goes below bounds, revert to serve state and decrease health
    for k, ball in pairs(self.balls) do
        if ball ~= nil then
            if ball.y >= VIRTUAL_HEIGHT then
                self.balls[k] = nil
                if ballCounter == 1 then
                    self.health = self.health - 1
                    gSounds['hurt']:play()

                    self.balls = {}
                    --to lower the size
                    if self.paddle.size > 1 then
                        self.paddle.size = self.paddle.size - 1
                    end
                    self.powerups = {}
                    if self.health == 0 then
                        gStateMachine:change('game-over', {
                            score = self.score,
                            highScores = self.highScores
                        })
                    else
                        gStateMachine:change('serve', {
                            paddle = self.paddle,
                            bricks = self.bricks,
                            health = self.health,
                            score = self.score,
                            highScores = self.highScores,
                            level = self.level,
                            recoverPoints = self.recoverPoints
                        })
                    end 
                    break
                end
            end 
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        --check if an unlock powerup was acquired
        if self.bricksUnlocked then
            self.bricks[k].locked = false
        end
        brick:update(dt)
    end

    --for gravity
    --If it collides with the paddle, consume powerup.
    for k, powerup in pairs(self.powerups) do
        if powerup ~= nil then
            powerup:update(dt)
            if powerup:collides(self.paddle) then
                --consumes the powerup and apply the effects
                --Spawn balls
                if powerup.powerupType == 9 then
                    local balldx = 0
                    local balldy = 0
            
                    for i, ball in pairs(self.balls) do
                        if ball ~= nil then
                            balldx = ball.dx
                            balldy = ball.dy
                            break
                        end
                    end
            
                    for i = 1,2 do
                        local b = Ball(math.random(7))
                        b:reset()
                        if i == 1 then b.x = b.x - 8
                        else b.x = b.x + 8 end
                        b.dx = balldx
                        b.dy = balldy
                        table.insert(self.balls, b)
                    end
                --Unlock bricks
                elseif powerup.powerupType == 10 then
                    self.bricksUnlocked = true
                end

                self.powerups[k] = nil
            -- elseif powerup.y >= VIRTUAL_HEIGHT then
            --     self.powerups[k] = nil
            end
        end
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    --render each Ball
    for k, ball in pairs(self.balls) do
        if ball ~= nil then
            ball:render()
        end
    end

    renderScore(self.score)
    renderHealth(self.health)

    --render powerups and do not render if it was collided with the paddle
    for k, powerup in pairs(self.powerups) do
        if powerup ~= nil then
            powerup:render()
        end
    end

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end