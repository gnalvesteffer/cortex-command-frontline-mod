-- One small fan of physical fragments on the first impact, including direct hits.
local function fragment(self)
    if self.fragmented then return end
    self.fragmented = true
    -- Each cannon shell carries an HE charge as well as its fragmentation fan.
    local explosive = CreateTDExplosive("Standard Bomb", "Base.rte")
    if explosive then
        explosive.Pos = self.Pos
        explosive.Team = self.Team
        explosive:GibThis()
        MovableMan:AddParticle(explosive)
    end
    for i = 1, 4 do
        local shard = CreateMOPixel("Frontline Orbital Fragment", "Frontline.rte")
        if shard then
            shard.Pos = self.Pos + Vector(0, -2)
            shard.Vel = Vector((i - 2.5) * 17 + math.random(-5, 5), -math.random(18, 42))
            shard.Team = self.Team
            shard.IgnoresTeamHits = false
            MovableMan:AddParticle(shard)
        end
    end
end

function OnCollideWithTerrain(self, terrainID)
    fragment(self)
end

function OnCollideWithMO(self, other, root)
    fragment(self)
end
