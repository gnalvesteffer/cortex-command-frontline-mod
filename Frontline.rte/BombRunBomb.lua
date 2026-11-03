-- Falling bomb that explodes on impact with terrain or actors.
local function explode(self)
    if self.exploded then return end
    self.exploded = true
    
    -- Create explosion smoke effect.
    local flash = CreateMOSParticle("Explosion Smoke Small", "Base.rte")
    if flash then
        flash.Pos = self.Pos
        flash.Vel = Vector(0, -4)
        flash.Team = self.Team
        MovableMan:AddParticle(flash)
    end
    
    -- Spawn explosive debris that damages nearby units.
    local bomb = CreateTDExplosive("Standard Bomb", "Base.rte")
    if bomb then
        bomb.Pos = self.Pos
        bomb.Vel = Vector(0, 0)
        bomb.Team = self.Team
        ToTDExplosive(bomb):Activate()
        MovableMan:AddParticle(bomb)
    end
end

function OnCollideWithTerrain(self, terrainID)
    explode(self)
end

function OnCollideWithMO(self, other, root)
    explode(self)
end