-- Visible falling shell; creates the active heavy explosive only on impact.
local function explode(self)
    if self.exploded then return end
    self.exploded=true
    local flash=CreateMOSParticle("Explosion Smoke Small","Base.rte")
    if flash then
        flash.Pos=self.Pos
        flash.Vel=Vector(0,-4)
        flash.Team=self.Team
        MovableMan:AddParticle(flash)
    end
    local bomb=CreateTDExplosive("Frontline Heavy Bomb","Frontline.rte")
    if bomb then
        bomb.Pos=self.Pos
        bomb.Vel=Vector(0,0)
        bomb.Team=self.Team
        local explosive=ToTDExplosive(bomb)
        if explosive then
            explosive:Activate()
            MovableMan:AddParticle(explosive)
        end
    end
    self.ToDelete=true
end

function OnCollideWithTerrain(self,terrainID)
    explode(self)
end

function OnCollideWithMO(self,other,root)
    explode(self)
end