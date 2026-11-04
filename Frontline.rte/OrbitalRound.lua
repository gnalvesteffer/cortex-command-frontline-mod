-- Radial explosion: fragments fly outward in all directions.
local FALLBACK_FRAGMENT_COUNT=16
local function fragment(self)
    if self.fragmented then return end
    self.fragmented=true
    local fragmentCount=FALLBACK_FRAGMENT_COUNT
    if self.GetNumberValue then
        local value=self:GetNumberValue("FragmentCount")
        if type(value)=="number" and value==value and value>0 and value<1000 then
            local whole=math.floor(value)
            fragmentCount=whole>0 and whole or FALLBACK_FRAGMENT_COUNT
        end
    end
    local flash=CreateMOSParticle("Explosion Smoke Small","Base.rte")
    if flash then
        flash.Pos=self.Pos
        flash.Vel=Vector(0,-4)
        flash.Team=self.Team
        MovableMan:AddParticle(flash)
    end
    for i=1,fragmentCount do
        local angle=(i-1)*(2*math.pi/fragmentCount)+(math.random()*0.3-0.15)
        local speed=18+math.random(0,24)
        local shard=CreateMOPixel("Frontline Orbital Fragment","Frontline.rte")
        if shard then
            shard.Pos=self.Pos
            shard.Vel=Vector(math.cos(angle)*speed,math.sin(angle)*speed)
            shard.Team=self.Team
            shard.IgnoresTeamHits=false
            MovableMan:AddParticle(shard)
        end
    end
end

function OnCollideWithTerrain(self,terrainID)
    fragment(self)
end

function OnCollideWithMO(self,other,root)
    fragment(self)
end