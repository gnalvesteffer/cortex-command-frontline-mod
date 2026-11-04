-- The activity owns the firearm payload; this script reports physical landing.
function OnCollideWithTerrain(self, terrainID)
    local landed=self.GetNumberValue and self:GetNumberValue("WeaponPodLanded")
    if type(landed)~="number" or landed<=0 then
        self:SetNumberValue("WeaponPodLanded",1)
        self.Vel=Vector(0,0)
    end
end
