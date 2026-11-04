-- Radial explosion: fragments fly outward in all directions.
local function fragment(self)
    if self.fragmented then return end
    self.fragmented = true
    local fragmentCount=self.FragmentCount
    local flash = CreateMOSParticle("Explosion Smoke Small", "Base.rte")
    if flash then
        flash.Pos = self.Pos
        flash.Vel = Vector(0, -4)
        flash.Team = self.Team
        MovableMan:AddParticle(flash)
    end
    for i = 1, fragmentCount do
        local shard = CreateMOPixel("Frontline Orbital Fragment", "Frontline.rte")
        if shard then
            local angle = (i - 1) * (2 * math.pi / fragmentCount) + math.random(-0.15, 0.15)
            local speed = 18 + math.random(0, 24)
            shard.Pos = self.Pos
            shard.Vel = Vector(math.cos(angle) * speed, math.sin(angle) * speed)
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