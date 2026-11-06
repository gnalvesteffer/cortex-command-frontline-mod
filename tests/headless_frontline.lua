-- Appended only to a disposable copy of Frontline.lua by run_headless_frontline.sh.
-- This calls the actual Frontline activity lifecycle and deployment code.
local originalHeadlessStartActivity = Frontline.StartActivity
local originalHeadlessUpdateActivity = Frontline.UpdateActivity
local originalHeadlessCreateAHuman = CreateAHuman
local headlessCaptureActive = false
local headlessCapturedActors = {}

CreateAHuman = function(presetName, moduleName)
    local actor = originalHeadlessCreateAHuman(presetName, moduleName)
    if headlessCaptureActive and actor then
        headlessCapturedActors[#headlessCapturedActors + 1] = actor
    end
    return actor
end

local function assertDefaultPistol(actor)
    local pistolCount = 0
    local loadout = {}
    local equipped = actor.EquippedItem
    if equipped then
        loadout[#loadout + 1] = "equipped=" .. tostring(equipped.ModuleName) .. "/" .. tostring(equipped.PresetName)
        if equipped.PresetName == "Pistol" and equipped.ModuleName == "Base.rte" then pistolCount = pistolCount + 1 end
    end
    for item in actor.Inventory do
        loadout[#loadout + 1] = tostring(item.ModuleName) .. "/" .. tostring(item.PresetName)
        if item.PresetName == "Pistol" and item.ModuleName == "Base.rte" then pistolCount = pistolCount + 1 end
    end
    assert(pistolCount == 1, "Bandit must have exactly one Base.rte Pistol; got " .. pistolCount
        .. " (InventorySize=" .. tostring(actor.InventorySize) .. ", loadout=" .. table.concat(loadout, ",") .. ")")
end

local function writeHeadlessResult(payload)
    local resultPath = os.getenv("FRONTLINE_TEST_RESULT")
    if not resultPath or resultPath == "" then return false end
    local file = io.open(resultPath, "w")
    if not file then return false end
    file:write(payload, "\n")
    file:close()
    return true
end

Frontline.StartActivity = function(self, ...)
    originalHeadlessStartActivity(self, ...)
    local ok, failure = pcall(function()
        assert(self.battleStarted == false, "activity must begin before battle setup")
        -- Exercise the real pixel-accurate terrain ray and stock object anchors
        -- on an uneven part of the loaded battlefield, without stamping a prop.
        local anchors={{-60,-60,125,124},{-60,-30,115,63},{-45,-30,97,67},
            {0,0,24,24},{0,0,24,24}}
        for index,entry in ipairs(CONFIG.map.cover.presets) do
            local prop=CreateTerrainObject(entry.preset,"Base.rte")
            local expected=anchors[index]
            local offset=prop:GetBitmapOffset()
            assert(offset.X==expected[1] and offset.Y==expected[2]
                and prop:GetBitmapWidth()==expected[3] and prop:GetBitmapHeight()==expected[4],
                entry.preset.." stock bitmap origin/dimensions changed")
            local tested=false
            for x=700,SceneMan.SceneWidth-700,37 do
                local low,high=SceneMan.SceneHeight,0
                for dx=entry.footLeft,entry.footRight do
                    local y=SceneMan:MovePointToGround(Vector(x+dx,0),0,0).Y
                    low=math.min(low,y); high=math.max(high,y)
                end
                if high>low then
                    local position=surfaceCoverPosition(entry,x)
                    assert(position.X==x and position.Y+entry.bottom==high+2,
                        entry.preset.." must seat its footing on uneven real terrain")
                    tested=true
                    break
                end
            end
            assert(tested,entry.preset.." smoke needs uneven real terrain")
        end
        local team = self.teams[0]
        team.auto = false
        self:StartBattle()

        local function assertBaseTurretDurabilityAndLoadout(turret, presetName, weaponName)
            assert(turret and turret.PresetName == presetName
                and turret.Health == 600 and turret.MaxHealth == 600
                and turret.ImpulseDamageThreshold == 8000
                and turret.GibImpulseLimit == 30000 and turret.GibWoundLimit == 36,
                presetName .. " must load with reinforced health and body critical/gib thresholds")
            local mount = turret.Turret
            local weapon = mount and mount.MountedDevice
            assert(mount and mount.GibImpulseLimit == 24000 and mount.GibWoundLimit == 32
                and weapon and weapon.PresetName == weaponName,
                presetName .. " must retain its reinforced cannon mount and Frontline weapon")
        end
        assertBaseTurretDurabilityAndLoadout(self.teams[0].turret,
            "Frontline HE Base Turret", "Frontline HE Turret Cannon")
        local upgradedTurret = CreateACrab("Frontline HE Turret", "Frontline.rte")
        assertBaseTurretDurabilityAndLoadout(upgradedTurret,
            "Frontline HE Turret", "Frontline HE Turret Cannon Mk2")
        upgradedTurret.ToDelete = true

        local function assertStrongerFrontlineFragment(presetName, stockName, expectedSharpness)
            local fragment = CreateMOPixel(presetName, "Frontline.rte")
            local stock = CreateMOPixel(stockName, "Coalition.rte")
            assert(fragment and stock and fragment.Sharpness == expectedSharpness
                and fragment.Sharpness > stock.Sharpness
                and fragment.WoundDamageMultiplier == stock.WoundDamageMultiplier,
                presetName .. " must use a stronger Frontline-only damage preset than its stock fragment")
            fragment.ToDelete = true
            stock.ToDelete = true
        end
        assertStrongerFrontlineFragment("Frontline HE Fragment Gray",
            "Coalition Bunker Cannon Fragment Gray", 45)
        assertStrongerFrontlineFragment("Frontline HE Fragment Yellow",
            "Coalition Bunker Cannon Fragment Yellow", 35)
        assertStrongerFrontlineFragment("Frontline HE Fragment Gray Mk2",
            "Coalition Bunker Cannon Fragment Gray", 55)
        assertStrongerFrontlineFragment("Frontline HE Fragment Yellow Mk2",
            "Coalition Bunker Cannon Fragment Yellow", 42)

        self.matchTimer.ElapsedSimTimeMS = 15001
        team.timer.ElapsedSimTimeMS = 20001

        local cost, count, batchError = self:Batch(0)
        assert(cost == 165 and count == 3, "default squad batch mismatch: cost=" .. tostring(cost)
            .. " count=" .. tostring(count) .. " error=" .. tostring(batchError))

        team.funds = 164
        self:SetTeamFunds(team.funds, 0)
        headlessCapturedActors = {}
        headlessCaptureActive = true
        local rejected, rejectError = self.commanders[0]:Deploy()
        headlessCaptureActive = false
        assert(not rejected and rejectError == "Not enough funds", "underfunded deploy should reject; got " .. tostring(rejectError))
        assert(#headlessCapturedActors == 0, "underfunded deploy must not construct actors")
        assert(team.funds == 164 and team.stats.deployed == 0, "underfunded deploy must not charge funds or update deployment stats")
        assert(self:GetTeamFunds(0) == 164, "engine funds must remain 164 after rejected deploy")

        team.funds = 450
        self:SetTeamFunds(team.funds, 0)
        headlessCapturedActors = {}
        headlessCaptureActive = true
        local deployed, deployError = self.commanders[0]:Deploy()
        headlessCaptureActive = false
        assert(deployed, "real team-0 deployment failed: " .. tostring(deployError))
        assert(#headlessCapturedActors == 3, "deployment should construct exactly three actors; got " .. #headlessCapturedActors)
        assert(team.funds == 285 and team.stats.deployed == 3, "successful deployment funds/stats mismatch")
        self:SetTeamFunds(team.funds, 0)
        assert(self:GetTeamFunds(0) == 285, "engine funds should be 285 oz after deployment")

        local expectedIDs = {}
        for _, actor in ipairs(headlessCapturedActors) do
            assert(actor.Team == 0 and actor.PresetName == "Bandit" and actor.ModuleName == "Frontline.rte",
                "deployment must create a team-0 Frontline Bandit")
            assertDefaultPistol(actor)
            expectedIDs[actor.UniqueID] = true
        end
        self.__headlessExpectedActorIDs = expectedIDs
        self.__headlessDeploymentChecksPending = true
        self.__headlessDeploymentUpdatesRemaining = 2
    end)

    headlessCaptureActive = false
    if not ok then
        self.__headlessDeploymentChecksPending = false
        if not writeHeadlessResult("FAIL " .. tostring(failure)) then
            ConsoleMan:PrintString("FRONTLINE_HEADLESS_TEST_FAIL cannot write result: " .. tostring(failure))
        end
    end
end

Frontline.UpdateActivity = function(self, ...)
    originalHeadlessUpdateActivity(self, ...)
    if not self.__headlessDeploymentChecksPending then return end
    self.__headlessDeploymentUpdatesRemaining = self.__headlessDeploymentUpdatesRemaining - 1
    if self.__headlessDeploymentUpdatesRemaining > 0 then return end
    self.__headlessDeploymentChecksPending = false

    local ok, failure = pcall(function()
        local registered = {}
        for actor in MovableMan.Actors do
            if self.__headlessExpectedActorIDs[actor.UniqueID] then
                assert(actor.Team == 0 and actor.PresetName == "Bandit" and actor.ModuleName == "Frontline.rte",
                    "registered deployed actor identity/team changed")
                registered[actor.UniqueID] = true
            end
        end
        local registeredCount = 0
        for id in pairs(self.__headlessExpectedActorIDs) do
            assert(registered[id], "captured deployed actor did not register in MovableMan: " .. tostring(id))
            registeredCount = registeredCount + 1
        end
        assert(registeredCount == 3, "expected three registered captured actors; got " .. registeredCount)
    end)

    local payload = ok and "PASS deployment units=3 funds=285 inventory=Base.rte/Pistol insufficient-funds=unchanged"
        or "FAIL " .. tostring(failure)
    if not writeHeadlessResult(payload) then
        ConsoleMan:PrintString("FRONTLINE_HEADLESS_TEST_FAIL cannot write result: " .. payload)
    end
end
