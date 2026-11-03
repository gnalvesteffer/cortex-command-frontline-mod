-- A visible, high-altitude precision round detonates on its first impact.
local function detonate(self)
    if self.detonated then return end
    self.detonated = true
    local explosive = CreateTDExplosive("Standard Bomb", "Base.rte")
    if explosive then
        explosive.Pos = self.Pos
        explosive.Team = self.Team
        explosive:GibThis()
        MovableMan:AddParticle(explosive)
    end
end

function OnCollideWithTerrain(self, terrainID)
    detonate(self)
end

function OnCollideWithMO(self, other, root)
    detonate(self)
end
