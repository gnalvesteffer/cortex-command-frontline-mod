-- Bomb run plane: flies across target area dropping multiple bomblets at intervals.
-- Simulates a dive bomber making a single pass, releasing cluster munitions.

local PLANE_SPEED = 40
local BOMB_INTERVAL_MS = 400
local MAX_BOMBS = 5
local FLIGHT_HEIGHT = 350

function BombRunPlane:Start()
    self.bombsDropped = 0
    self.flightDirection = 1
    self.startTimer = Timer()
end

function BombRunPlane:Update(dt)
    if not self.TargetX then return end
    
    -- Move the plane across the target area
    self.Pos.X = self.Pos.X + PLANE_SPEED * self.flightDirection * dt
    
    -- Drop a bomb at intervals as we fly
    local elapsed = self.startTimer.ElapsedSimTimeMS
    local bombsDue = math.min(MAX_BOMBS, math.floor(elapsed / BOMB_INTERVAL_MS))
    
    while self.bombsDropped < bombsDue do
        self:DropBomb()
        self.bombsDropped = self.bombsDropped + 1
    end
    
    -- Remove the plane when it has flown past the target area or dropped all bombs
    if math.abs(self.Pos.X - self.TargetX) > FLIGHT_HEIGHT * 2 or self.bombsDropped >= MAX_BOMBS then
        self:Kill()
    end
end

function BombRunPlane:DropBomb()
    -- Create a small bomb (bomblet) that falls to the ground
    local bomb = CreateTDExplosive("Frontline Bomblet", "Frontline.rte")
    if not bomb then return end
    
    bomb.Pos = Vector(self.Pos.X, self.Pos.Y + 20)
    bomb.Vel = Vector(PLANE_SPEED * self.flightDirection, 50)
    bomb.Team = self.Team
    
    ToTDExplosive(bomb):Activate()
    MovableMan:AddParticle(bomb)
end
