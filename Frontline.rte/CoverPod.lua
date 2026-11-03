-- A falling cargo pod becomes solid, destructible cover at its landing point.
function OnCollideWithTerrain(self, terrainID)
    self.hasLanded = true
end

function Update(self)
    self.ToSettle = false
    if not self.hasLanded then return end
    local ground = SceneMan:MovePointToGround(self.Pos + Vector(0, -32), 0, 2)
    local crate = CreateTerrainObject("Metal Crate Small A FG", "Base.rte")
    if crate then
        crate.Pos = Vector(ground.X - 12, ground.Y - 24)
        crate.Team = self.Team
        SceneMan:AddSceneObject(crate)
    end
    self.ToDelete = true
end
