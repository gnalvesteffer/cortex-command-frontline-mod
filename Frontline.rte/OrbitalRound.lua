-- One small fan of physical fragments on the first impact, including direct hits.
local function fragment(self)
    if self.fragmented then return end
    self.fragmented = true
    -- A small flash and a fan of shrapnel: no large bomb-sized blast.
    local flash = CreateMOSParticle("Explosion Smoke Small", "Base.rte")
    if flash then
        flash.Pos = self.Pos
        flash.Vel = Vector(0, -4)
        flash.Team = self.Team
        MovableMan:AddParticle(flash)
    end
    for i = 1, 8 do
        local shard = CreateMOPixel("Frontline Orbital Fragment", "Frontline.rte")
        if shard then
            shard.Pos = self.Pos + Vector(0, -2)
            shard.Vel = Vector((i - 4.5) * 9 + math.random(-5, 5), -math.random(18, 42))
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
