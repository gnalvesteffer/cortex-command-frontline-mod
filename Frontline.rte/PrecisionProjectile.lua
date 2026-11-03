-- A visible, high-altitude precision round detonates on its first impact.
local function detonate(self)
    if self.detonated then return end
    self.detonated = true
    -- Clustered charges make the precision strike's impact wider and stronger.
    for _,dx in ipairs({-24, 0, 24}) do
        local explosive = CreateTDExplosive("Standard Bomb", "Base.rte")
        if explosive then
            explosive.Pos = self.Pos + Vector(dx, -2)
            explosive.Team = self.Team
            explosive:GibThis()
            MovableMan:AddParticle(explosive)
        end
    end
    self.ToDelete = true
end

function OnCollideWithTerrain(self, terrainID)
    detonate(self)
end

function OnCollideWithMO(self, other, root)
    detonate(self)
end
