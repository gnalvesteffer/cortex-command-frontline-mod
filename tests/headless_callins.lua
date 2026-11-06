-- Appended only to a disposable copy of Frontline.lua by run_headless_frontline.sh.
-- Exercises every production TeamCommander:CallIn branch against the live engine.
local originalCallinHeadlessStartActivity = Frontline.StartActivity

local function writeCallinHeadlessResult(payload)
    local resultPath = os.getenv("FRONTLINE_TEST_RESULT")
    if not resultPath or resultPath == "" then return false end
    local file = io.open(resultPath, "w")
    if not file then return false end
    file:write(payload, "\n")
    file:close()
    return true
end

local function liveCallinObjects(collections, presetName, moduleName)
    local matches, seen = {}, {}
    for _, collection in ipairs(collections) do
        for object in collection do
            if object.PresetName == presetName and object.ModuleName == moduleName then
                local id = object.UniqueID
                if not seen[id] then
                    seen[id] = true
                    matches[id] = object
                end
            end
        end
    end
    return matches
end
local function allCallinParticleIds()
    local ids = {}
    for particle in MovableMan.Particles do ids[particle.UniqueID] = true end
    for particle in MovableMan.AddedParticles do ids[particle.UniqueID] = true end
    return ids
end

local function countNewCallinParticles(before)
    local count = 0
    for id in pairs(allCallinParticleIds()) do
        if not before[id] then count = count + 1 end
    end
    return count
end
local function countNewCallinBombFragments(before)
    local count = 0
    local function countIn(collection)
        for particle in collection do
            if not before[particle.UniqueID] and particle.ModuleName == "Base.rte"
                and (particle.PresetName == "Air Blast" or particle.PresetName == "Grenade Fragment Gray"
                    or particle.PresetName == "Fire Puff Large") then
                count = count + 1
            end
        end
    end
    countIn(MovableMan.Particles)
    countIn(MovableMan.AddedParticles)
    return count
end
local function countNewCallinPreset(presetName, before)
    local count = 0
    for _, collection in ipairs({MovableMan.Particles, MovableMan.AddedParticles}) do
        for particle in collection do
            if particle.PresetName == presetName and particle.ModuleName == "Base.rte"
                and not before[particle.UniqueID] then count = count + 1 end
        end
    end
    return count
end
local function countNewCallinPresetNear(presetName, before, x, y, radius)
    local count, radiusSquared = 0, radius * radius
    for _, collection in ipairs({MovableMan.Particles, MovableMan.AddedParticles}) do
        for particle in collection do
            if particle.PresetName == presetName and particle.ModuleName == "Base.rte"
                and not before[particle.UniqueID] then
                local dx, dy = particle.Pos.X - x, particle.Pos.Y - y
                if dx * dx + dy * dy <= radiusSquared then count = count + 1 end
            end
        end
    end
    return count
end




local function callinParticleIds(presetName, moduleName, team)
    local objects = liveCallinObjects({MovableMan.Particles, MovableMan.AddedParticles}, presetName, moduleName)
    local ids = {}
    for id, object in pairs(objects) do
        if team == nil or object.Team == team then ids[id] = true end
    end
    return ids
end

local function findCallinActor(uniqueID)
    for actor in MovableMan.Actors do
        if actor.UniqueID == uniqueID then return actor end
    end
    for actor in MovableMan.AddedActors do
        if actor.UniqueID == uniqueID then return actor end
    end
    return nil
end

local function findCallinOrbitalRound()
    for particle in MovableMan.Particles do
        if particle.PresetName == "Frontline Orbital Round" and particle.Team == 0
            and particle:GetNumberValue("FragmentCount") == CONFIG.supportEffects.orbital.fragments then return particle end
    end
    for particle in MovableMan.AddedParticles do
        if particle.PresetName == "Frontline Orbital Round" and particle.Team == 0
            and particle:GetNumberValue("FragmentCount") == CONFIG.supportEffects.orbital.fragments then return particle end
    end
    return nil
end
local function findCallinParticle(uniqueID)
    for particle in MovableMan.Particles do
        if particle.UniqueID == uniqueID then return particle end
    end
    for particle in MovableMan.AddedParticles do
        if particle.UniqueID == uniqueID then return particle end
    end
    return nil
end




local function runHeadlessCallinSuite(self)
    assert(not self.battleStarted, "call-in activity must begin before battle setup")
    local beforeBattle, beforeBattleError = self.commanders[0]:CallIn("strike", 2)
    assert(not beforeBattle and beforeBattleError == "Complete match setup first",
        "call-ins must reject before battle setup")
    self:StartBattle()
    self.settings.callins = true
    self.teams[0].auto = false
    self.teams[1].auto = false
    self.matchTimer.ElapsedSimTimeMS = CONFIG.GRACE_MS + 1

    local team = self.teams[0]
    local targetIndex = 2
    local target = self.outposts[targetIndex]
    assert(target and self:SupportTargetAllowed(0, target.x), "call-in test target must be a legal outpost")
    team.funds = 60000
    self:SetTeamFunds(team.funds, 0)
    local fundsBeforeUnknown = team.funds
    local unknown, unknownError = self.commanders[0]:CallIn("unknownSupport", targetIndex)
    assert(not unknown and unknownError == "Unknown call-in" and team.funds == fundsBeforeUnknown,
        "unknown call-in kinds must reject without charging funds")
    local originalOwner, originalKind = target.owner, target.kind
    local originalBonuses = self.settings.outpostBonuses
    self.settings.outpostBonuses = true
    target.owner, target.kind = 0, 3
    local discountedCooldown = self:CallinCooldown(0, CONFIG.CALLIN_STRIKE_COOLDOWN_MS)
    assert(discountedCooldown == math.max(1,
        math.ceil(CONFIG.CALLIN_STRIKE_COOLDOWN_MS * CONFIG.economy.callinCooldownMultiplier - 1e-9)),
        "owned command outpost must apply the production call-in cooldown discount")
    target.kind = 2
    local researchIndex = 21
    local research = CONFIG.research[researchIndex]
    local baseResearchCost = research.prices and research.prices[1] or research.price
    local discountedResearchCost = self:ResearchCost(0, researchIndex)
    assert(discountedResearchCost == math.max(1,
        math.ceil(baseResearchCost * CONFIG.economy.outpostResearchCostMultiplier - 1e-9)),
        "owned research outpost must apply the production research cost discount")
    target.owner, target.kind = originalOwner, originalKind
    self.settings.outpostBonuses = originalBonuses

    local cases = {
        {kind="strike", research=24, timer="strikeTimer", cost=CONFIG.CALLIN_STRIKE_COST, cooldown=CONFIG.CALLIN_STRIKE_COOLDOWN_MS},
        {kind="medic", research=11, effectLevel=12, levels={1, 2}, timer="medicTimer", cost=CONFIG.CALLIN_MEDIC_COST, cooldown=CONFIG.CALLIN_MEDIC_COOLDOWN_MS},
        {kind="cover", research=22, levels={1, 2, 3}, timer="coverTimer", cost=CONFIG.CALLIN_COVER_COST, cooldown=CONFIG.CALLIN_COVER_COOLDOWN_MS},
        {kind="mines", research=23, levels={1, 2, 3}, timer="minesTimer", cost=CONFIG.CALLIN_MINES_COST, cooldown=CONFIG.CALLIN_MINES_COOLDOWN_MS},
        {kind="bomb", research=25, timer="bombTimer", cost=CONFIG.CALLIN_BOMB_COST, cooldown=CONFIG.CALLIN_BOMB_COOLDOWN_MS},
        {kind="turret", research=26, timer="turretTimer", cost=CONFIG.CALLIN_TURRET_COST, cooldown=CONFIG.CALLIN_TURRET_COOLDOWN_MS},
        {kind="orbital", research=21, timer="orbitalTimer", cost=CONFIG.CALLIN_ORBITAL_COST, cooldown=CONFIG.CALLIN_ORBITAL_COOLDOWN_MS},
        {kind="shield", research=13, levels={1, 2}, timer="shieldTimer", cost=CONFIG.CALLIN_SHIELD_COST, cooldown=CONFIG.CALLIN_SHIELD_COOLDOWN_MS},
        {kind="bubble", research=27, timer="bubbleTimer", cost=CONFIG.CALLIN_BUBBLE_COST, cooldown=CONFIG.CALLIN_BUBBLE_COOLDOWN_MS},
        {kind="mining", research=14, timer="minesTimer", cost=CONFIG.supportEffects.miningCost, cooldown=CONFIG.CALLIN_MINES_COOLDOWN_MS},
        {kind="weaponPod", research=28, timer="weaponPodTimer", cost=CONFIG.CALLIN_WEAPON_POD_COST, cooldown=CONFIG.CALLIN_WEAPON_POD_COOLDOWN_MS},
        {kind="assaultSquad", research=30, timer="assaultSquadTimer", cost=CONFIG.CALLIN_ASSAULT_SQUAD_COST, cooldown=CONFIG.CALLIN_ASSAULT_SQUAD_COOLDOWN_MS},
    }

    local disabledBefore = team.funds
    self.settings.callins = false
    local disabled, disabledError = self.commanders[0]:CallIn("strike", targetIndex)
    assert(not disabled and disabledError == "Call-ins disabled in setup" and team.funds == disabledBefore,
        "disabled call-ins must reject without charging funds")
    self.settings.callins = true
    self.matchTimer.ElapsedSimTimeMS = 0
    local grace, graceError = self.commanders[0]:CallIn("strike", targetIndex)
    assert(not grace and graceError == "Call-ins unavailable during grace" and team.funds == disabledBefore,
        "call-ins must reject during grace without charging funds")
    self.matchTimer.ElapsedSimTimeMS = CONFIG.GRACE_MS + 1
    local invalidTarget, invalidTargetError = self.commanders[0]:CallIn("strike", 999)
    assert(not invalidTarget and invalidTargetError == "Choose a valid target" and team.funds == disabledBefore,
        "invalid outpost targets must reject without charging funds")

    for _, case in ipairs(cases) do
        local timer = team[case.timer]
        local fundsBefore = team.funds
        local timerBefore = timer.ElapsedSimTimeMS
        local gated, gateError = self.commanders[0]:CallIn(case.kind, targetIndex)
        assert(not gated and gateError:find(CONFIG.research[case.research].name, 1, true),
            case.kind .. " must reject before its " .. CONFIG.research[case.research].name .. " research is unlocked; got " .. tostring(gateError))
        assert(team.funds == fundsBefore and timer.ElapsedSimTimeMS == timerBefore,
            case.kind .. " research rejection must preserve funds and cooldown")
    end

    local researchOrder = {21, 22, 22, 22, 23, 23, 23, 24, 25, 26, 13, 13, 27, 11, 12, 14, 28, 30}
    for _, index in ipairs(researchOrder) do
        local price = self:ResearchCost(0, index)
        local fundsBefore = team.funds
        local researched, researchError = self.commanders[0]:Research(index)
        assert(researched, "required support research " .. index .. " failed: " .. tostring(researchError))
        assert(team.levels[index] > 0 and team.funds == fundsBefore - price,
            "research " .. index .. " must advance its level and debit its exact cost")
    end
    assert(team.levels[13] == 2 and team.levels[27] == 1 and team.levels[22] == 3
        and team.levels[23] == 3 and team.levels[12] == 1,
        "all three Cover/Mines levels, both Medic/Jammer levels, and Energy Shield must be researched")
    local assaultWeaponPresets,assaultStockPresets=self:AssaultSquadWeaponPresets()
    assert(assaultWeaponPresets and assaultStockPresets
        and #assaultWeaponPresets+#assaultStockPresets>=CONFIG.supportEffects.assaultSquad.count,
        "Assault Squad must retain enough eligible loaded firearms for its loadout")
    local assaultWeaponNames = {}
    for _, weaponPool in ipairs({assaultWeaponPresets,assaultStockPresets}) do
        for _, name in ipairs(weaponPool) do
            assert(not name:find("HeadlessTestExotics.rte/", 1, true),
                "Assault Squad selection must not rely on injected test-only firearms")
            local probe = CreateHDFirearm(name)
            assert(probe, "Assault Squad selection must instantiate loaded firearm " .. tostring(name))
            assert(type(probe.GetGoldValue) == "function" and probe:GetGoldValue(0, 1, 1) > 0,
                "Assault Squad selection must use a positive-value real firearm " .. tostring(name))
            probe.ToDelete = true
            assaultWeaponNames[name] = true
        end
    end
    local assaultObservedWeapons={}
    self:SetTeamFunds(team.funds, 0)

    local illegalTarget = {name="enemy base exclusion", x=SceneMan.SceneWidth-CONFIG.map.baseOffset,
        groundY=target.groundY, owner=-1}
    local fundsBeforeIllegal = team.funds
    local strikeTimerBeforeIllegal = team.strikeTimer.ElapsedSimTimeMS
    local illegal, illegalError = self.commanders[0]:CallIn("strike", illegalTarget)
    assert(not illegal and illegalError == "Support restricted near enemy base"
        and team.funds == fundsBeforeIllegal and team.strikeTimer.ElapsedSimTimeMS == strikeTimerBeforeIllegal,
        "support near the enemy base must reject without payment or cooldown")

    local results = {}
    local function expectOrder(list, kind)
        for index = #list, 1, -1 do
            if list[index].team == 0 and list[index].kind == kind and list[index].target == target then return list[index] end
        end
        error("missing queued " .. kind .. " effect")
    end
    local function actorIds(presetName, moduleName)
        return liveCallinObjects({MovableMan.Actors, MovableMan.AddedActors}, presetName, moduleName)
    end
    local function countNewCallinParticles(presetName, moduleName, before, teamId)
        local count = 0
        for id in pairs(callinParticleIds(presetName, moduleName, teamId)) do
            if not before[id] then count = count + 1 end
        end
        return count
    end
    local function countNewActors(presetName, moduleName, before)
        local count = 0
        for id in pairs(actorIds(presetName, moduleName)) do
            if not before[id] then count = count + 1 end
        end
        return count
    end
    local function finishDropshipDelivery(order, cargoCount)
        local expectedCargo = cargoCount or order.count
        order.timer.ElapsedSimTimeMS = order.delay + 1
        self:UpdateCallIns()
        assert(order.ship and order.ship.Team == 0 and order.ship.InventorySize == expectedCargo,
            order.kind .. " must create a team-0 dropship with the complete payload (ship="
                .. tostring(order.ship) .. " inventory=" .. tostring(order.ship and order.ship.InventorySize)
                .. " expected=" .. tostring(expectedCargo) .. ")")
        order.arrivalTimer.ElapsedSimTimeMS = CONFIG.supportEffects.delivery.approachMs + 1
        self:UpdateCallIns()
        assert(order.ship.InventorySize == 0, order.kind .. " dropship must release all cargo")
    end
    local function verifyDelivery(case, order)
        if case.kind == "cover" or case.kind == "mines" then
            local preset = case.kind == "cover" and "Frontline Cover Pod" or "Anti Personnel Mine Active"
            local module = case.kind == "cover" and "Frontline.rte" or "Base.rte"
            local before = callinParticleIds(preset, module, 0)
            finishDropshipDelivery(order)
            assert(countNewCallinParticles(preset, module, before, 0) == order.count,
                case.kind .. " must add exactly " .. order.count .. " team-0 live physical payloads")
        elseif case.kind == "medic" or case.kind == "turret" then
            local preset = case.kind == "medic" and "Medic Drone" or "Gatling Turret"
            local module = case.kind == "medic" and "Base.rte" or "Coalition.rte"
            local before = actorIds(preset, module)
            finishDropshipDelivery(order)
            assert(countNewActors(preset, module, before) == order.count,
                case.kind .. " must add the expected live actor payload")
            local ground = SceneMan:MovePointToGround(Vector(target.x, 0), 0, CONFIG.map.outposts.groundProbe)
            for id in pairs(actorIds(preset, module)) do
                if not before[id] then
                    local actor = findCallinActor(id)
                    local spread = case.kind == "medic" and CONFIG.supportEffects.delivery.medicSpread or 0
                    assert(actor and actor.Team == 0 and math.abs(actor.Pos.X - target.x) <= spread,
                        case.kind .. " payload must be team-owned and released at the target")
                    if case.kind == "turret" then
                        assert(math.abs(actor.Pos.Y - (ground.Y - CONFIG.supportEffects.delivery.turretDropOffset)) <= 1
                            and actor.AIMode == Actor.AIMODE_SENTRY
                            and actor.PinStrength == CONFIG.supportEffects.delivery.turretPinStrength,
                            "delivered turret must have configured terrain placement, ownership, and sentry behavior")
                    end
                end
            end
        elseif case.kind == "mining" then
            local miner = order.miner
            assert(miner and miner.PresetName == "Dummy" and miner.ModuleName == "Dummy.rte",
                "mining call-in must construct the Dummy miner")
            local hasPistol, hasDigger, gearNames = false, false, {}
            local equipped = miner.EquippedItem
            if equipped then
                gearNames[#gearNames + 1] = tostring(equipped.ModuleName) .. "/" .. tostring(equipped.PresetName)
                hasPistol = equipped.PresetName == "Pistol" and equipped.ModuleName == "Base.rte"
            end
            for item in miner.Inventory do
                gearNames[#gearNames + 1] = tostring(item.ModuleName) .. "/" .. tostring(item.PresetName)
                if item.PresetName == "Pistol" and item.ModuleName == "Base.rte" then hasPistol = true end
                if item.PresetName == "Light Digger" and item.ModuleName == "Base.rte" then hasDigger = true end
            end
            assert(hasPistol and hasDigger,
                "mining passenger must carry both its Base Pistol and Light Digger; size="
                    .. tostring(miner.InventorySize) .. " inventory=" .. table.concat(gearNames, ","))
            finishDropshipDelivery(order, 1)
            local liveMiner = findCallinActor(miner.UniqueID)
            assert(liveMiner and liveMiner.Team == 0 and self.miners[liveMiner.UniqueID]
                and liveMiner.PresetName == "Dummy" and liveMiner.ModuleName == "Dummy.rte",
                "mining call-in must release the same miner actor into the world")
        elseif case.kind == "assaultSquad" then
            local expected = {}
            local selectedThisCall = {}
            for _, passenger in ipairs(order.squad) do
                local selectedWeapon
                local equipped = passenger.EquippedItem
                if equipped then
                    local name = equipped.ModuleName .. "/" .. equipped.PresetName
                    if assaultWeaponNames[name] then selectedWeapon = name end
                end
                for item in passenger.Inventory do
                    local name = item.ModuleName .. "/" .. item.PresetName
                    if assaultWeaponNames[name] then selectedWeapon = name end
                end
                assert(selectedWeapon and not selectedThisCall[selectedWeapon],
                    "each staged Assault passenger must carry a distinct firearm from the real eligible pool")
                selectedThisCall[selectedWeapon] = true
                assaultObservedWeapons[selectedWeapon]=true
                expected[passenger.UniqueID] = selectedWeapon
            end
            finishDropshipDelivery(order)
            local delivered = 0
            for id, expectedWeapon in pairs(expected) do
                local actor = findCallinActor(id)
                assert(actor and actor.Team == 0 and actor.PresetName == "Soldier Light"
                    and actor.ModuleName == "Coalition.rte",
                    "assault squad must release each captured Coalition Light actor")
                assert(actor.Health == 200 and actor.MaxHealth == 200,
                    "each delivered Assault soldier must retain 200 current and maximum health")
                assert(math.abs(actor.Pos.X - target.x) <= CONFIG.supportEffects.delivery.medicSpread
                    and actor.Pos.Y < target.groundY,
                    "assault passenger must be deployed above target terrain within configured spread")
                local carried,carriedWeapons = false,{}
                local equipped = actor.EquippedItem
                if equipped then
                    local name=equipped.ModuleName.."/"..equipped.PresetName
                    carriedWeapons[#carriedWeapons+1]=name
                    if name==expectedWeapon then carried=true end
                end
                for item in actor.Inventory do
                    local name=item.ModuleName.."/"..item.PresetName
                    carriedWeapons[#carriedWeapons+1]=name
                    if name==expectedWeapon then carried=true end
                end
                assert(carried, "delivered Assault soldier must retain firearm " .. expectedWeapon
                    .. "; found " .. table.concat(carriedWeapons,","))
                if self.teams[0].order == "Rush" then
                    assert(actor.AIMode == Actor.AIMODE_BRAINHUNT and not self.orderAssignments[id],
                        "Rush assault passenger must receive the production Brain Hunt order")
                else
                    assert(self.orderAssignments[id] and self.orderAssignments[id].order == self.teams[0].order,
                        "assault passenger must receive the team's configured field order")
                end
                delivered = delivered + 1
            end
            assert(delivered == CONFIG.supportEffects.assaultSquad.count,
                "assault squad must deliver exactly the configured passenger count")
        end
    end

    local failures = {}
    for _, case in ipairs(cases) do
        local effectIndex = case.effectLevel or case.research
        local maximumLevel = team.levels[effectIndex] or 1
        local ok, result = pcall(function()
            local timer = team[case.timer]
            local fundsBefore = team.funds
            timer.ElapsedSimTimeMS = 0
            local coolingDown, cooldownError = self.commanders[0]:CallIn(case.kind, targetIndex)
            assert(not coolingDown and cooldownError == "Call-in cooling down"
                and team.funds == fundsBefore and timer.ElapsedSimTimeMS == 0,
                case.kind .. " must reject during cooldown without payment or timer reset")

            timer.ElapsedSimTimeMS = 1000000
            team.funds = case.cost - 1
            self:SetTeamFunds(team.funds, 0)
            local underfunded, fundsError = self.commanders[0]:CallIn(case.kind, targetIndex)
            assert(not underfunded and fundsError == "Not enough funds"
                and team.funds == case.cost - 1 and timer.ElapsedSimTimeMS == 1000000,
                case.kind .. " must reject insufficient funds without payment or cooldown")
            team.funds = fundsBefore
            self:SetTeamFunds(team.funds, 0)

            for _, callLevel in ipairs(case.levels or {maximumLevel}) do
                team.levels[effectIndex] = case.kind == "medic" and callLevel - 1 or callLevel
                timer.ElapsedSimTimeMS = 1000000
                local fundsAtOrder = team.funds
                local beforeStrikes, beforeDrops, beforeOrbitals = #self.pendingStrikes, #self.pendingDrops, #self.pendingOrbitals
                local beforeJammers = #self.jamFields
                local beforeBubbles = #(self.energyShields or {})
                local ordered, orderError = self.commanders[0]:CallIn(case.kind, targetIndex)
                if not ordered then
                    if case.kind == "weaponPod" and orderError == "No loaded firearm presets are available" then
                        assert(team.funds == fundsAtOrder and timer.ElapsedSimTimeMS == 1000000,
                            "blocked weapon cache asset check must not charge or start cooldown")
                        return "BLOCKED:loaded-firearm-presets-unavailable"
                    end
                end
                assert(ordered, case.kind .. " call-in failed: " .. tostring(orderError))
                assert(team.funds == fundsAtOrder - case.cost and timer.ElapsedSimTimeMS == 0,
                    case.kind .. " must debit exact cost and reset its cooldown after ordering")

                if case.kind == "strike" then
                    local order = self.pendingStrikes[#self.pendingStrikes]
                    assert(#self.pendingStrikes == beforeStrikes + 1 and order.team == 0 and order.target == target,
                        "precision strike must queue its requested target")
                    order.timer.ElapsedSimTimeMS = CONFIG.CALLIN_STRIKE_DELAY_MS + 1
                    self:UpdateCallIns()
                    local ground = SceneMan:MovePointToGround(Vector(target.x, 0), 0, 4)
                    local projectile = order.projectile
                    assert(projectile and projectile.Team == 0
                        and projectile.PresetName == "Frontline Precision Projectile"
                        and math.abs(projectile.Pos.X - ground.X) <= 1
                        and projectile.Pos.Y == math.max(0, ground.Y - CONFIG.CALLIN_PRECISION_HEIGHT)
                        and projectile.Vel.X == 0 and projectile.Vel.Y == CONFIG.CALLIN_PRECISION_SPEED,
                        "precision strike must create a team-0 projectile at the requested target and configured height/velocity")
                    local strikeTargetActor = CreateAHuman("Dummy", "Dummy.rte")
                    assert(strikeTargetActor, "Precision Strike impact fixture must create a real target actor")
                    strikeTargetActor.Team = 1
                    strikeTargetActor.Pos = Vector(ground.X, ground.Y - 80)
                    strikeTargetActor.PinStrength = 1000000
                    strikeTargetActor.AIMode = Actor.AIMODE_SENTRY
                    MovableMan:AddActor(strikeTargetActor)
                    projectile.HitsMOs = true
                    projectile.Pos = strikeTargetActor.Pos
                    projectile.Vel = Vector(0, CONFIG.CALLIN_PRECISION_SPEED)
                    self.headlessStrikeImpact = {
                        id=projectile.UniqueID, before=allCallinParticleIds(), updates=0,
                        x=ground.X, y=strikeTargetActor.Pos.Y,
                    }
                    order.projectileTimer.ElapsedSimTimeMS = CONFIG.CALLIN_PRECISION_FLIGHT_MS + 1
                    self:UpdateCallIns()
                    assert(#self.pendingStrikes == beforeStrikes,
                        "precision strike must remove its pending record after the configured flight duration")
                elseif case.kind == "orbital" then
                    local order = self.pendingOrbitals[#self.pendingOrbitals]
                    assert(#self.pendingOrbitals == beforeOrbitals + 1 and order.team == 0 and order.target == target,
                        "orbital barrage must queue its target")
                    local roundsBefore = callinParticleIds("Frontline Orbital Round", "Frontline.rte", 0)
                    order.timer.ElapsedSimTimeMS = CONFIG.CALLIN_ORBITAL_DELAY_MS - 1
                    self:UpdateCallIns()
                    assert(order.shots == 0
                        and countNewCallinParticles("Frontline Orbital Round", "Frontline.rte", roundsBefore, 0) == 0,
                        "orbital barrage must not fire before its delay")
                    order.timer.ElapsedSimTimeMS = CONFIG.CALLIN_ORBITAL_DELAY_MS + 1
                    self:UpdateCallIns()
                    assert(order.shots == 1,
                        "orbital barrage must fire its first round immediately after the delay")
                    local firstRound = findCallinOrbitalRound()
                    assert(firstRound and math.abs(firstRound.Pos.X - target.x) <= CONFIG.CALLIN_ORBITAL_RADIUS
                        and firstRound.Vel.Y == CONFIG.CALLIN_ORBITAL_SPEED
                        and firstRound:GetNumberValue("FragmentCount") == CONFIG.supportEffects.orbital.fragments,
                        "orbital first round must use its configured target radius, speed, and fragment count")
                    local halfway = math.floor(CONFIG.CALLIN_ORBITAL_DURATION_MS / 2)
                    order.timer.ElapsedSimTimeMS = CONFIG.CALLIN_ORBITAL_DELAY_MS + halfway
                    self:UpdateCallIns()
                    local expectedHalfway = 1 + math.floor(halfway
                        * (CONFIG.CALLIN_ORBITAL_SHOTS - 1) / CONFIG.CALLIN_ORBITAL_DURATION_MS)
                    assert(order.shots == expectedHalfway,
                        "orbital barrage cadence at half-duration must be " .. expectedHalfway .. " shots; got " .. order.shots)
                    order.timer.ElapsedSimTimeMS = CONFIG.CALLIN_ORBITAL_DELAY_MS
                        + CONFIG.CALLIN_ORBITAL_DURATION_MS
                            * (CONFIG.CALLIN_ORBITAL_SHOTS + CONFIG.CALLIN_ORBITAL_BONUS_SHOTS - 1)
                            / (CONFIG.CALLIN_ORBITAL_SHOTS - 1) + 1
                    self:UpdateCallIns()
                    local expectedShots = CONFIG.CALLIN_ORBITAL_SHOTS + CONFIG.CALLIN_ORBITAL_BONUS_SHOTS
                    local rounds = callinParticleIds("Frontline Orbital Round", "Frontline.rte", 0)
                    assert(order.shots == expectedShots,
                        "orbital barrage must fire all " .. expectedShots .. " configured shots including turret-research bonus; got " .. order.shots)
                    assert(countNewCallinParticles("Frontline Orbital Round", "Frontline.rte", roundsBefore, 0) == expectedShots,
                        "orbital barrage must create all " .. expectedShots .. " new live team-0 rounds")
                    assert(findCallinOrbitalRound(),
                        "orbital barrage rounds must carry their fragmentation behavior")
                    local liveRounds = 0
                    for id in pairs(callinParticleIds("Frontline Orbital Round", "Frontline.rte", 0)) do
                        if not roundsBefore[id] then liveRounds = liveRounds + 1 end
                    end
                    assert(liveRounds == expectedShots,
                        "orbital barrage must leave all " .. expectedShots .. " new rounds; got " .. liveRounds)
                    for id in pairs(rounds) do
                        if not roundsBefore[id] then
                            local round = findCallinParticle(id)
                            local roundGround = round and SceneMan:MovePointToGround(Vector(round.Pos.X, 0), 0,
                                CONFIG.map.outposts.groundProbe) or nil
                            assert(round and roundGround and round.Team == 0
                                and math.abs(round.Pos.X - target.x) <= CONFIG.CALLIN_ORBITAL_RADIUS
                                and math.abs(round.Pos.Y - (roundGround.Y - CONFIG.CALLIN_ORBITAL_HEIGHT)) <= 1
                                and round.Vel.X == 0 and round.Vel.Y == CONFIG.CALLIN_ORBITAL_SPEED
                                and round:GetNumberValue("FragmentCount") == CONFIG.supportEffects.orbital.fragments,
                                "each Orbital round must target the selected outpost with configured radius/height/velocity/team/fragments")
                        end
                    end
                    assert(#self.pendingOrbitals == beforeOrbitals,
                        "completed Orbital barrage must remove itself from pending orders")
                elseif case.kind == "bomb" then
                    local order = expectOrder(self.pendingDrops, "bomb")
                    assert(#self.pendingDrops == beforeDrops + 1 and order.ship and order.ship.Team == 0,
                        "carpet bomb must queue its physical dropship")
                    local beforeBombs = callinParticleIds("Frontline Carpet Bomb", "Frontline.rte")
                    order.timer.ElapsedSimTimeMS = CONFIG.supportEffects.bombRun.intervalMs * CONFIG.supportEffects.bombRun.count
                    self:UpdateCallIns()
                    assert(order.bombsDropped == CONFIG.supportEffects.bombRun.count,
                        "carpet bomb must release all configured physical shells")
                    assert(order.ship.AIMode == Actor.AIMODE_RETURN and order.ship.PinStrength == 0
                        and order.ship.CanEnterOrbit and #self.pendingDrops == beforeDrops,
                        "completed Carpet Bomb run must release its dropship for return and leave no pending order")
                    assert(countNewCallinParticles("Frontline Carpet Bomb", "Frontline.rte", beforeBombs)
                            == CONFIG.supportEffects.bombRun.count,
                        "carpet bomb must add exactly three live Frontline bomb shells")
                    local impactShellIds, impactPoints = {}, {}
                    local collisionTarget = CreateAHuman("Dummy", "Dummy.rte")
                    assert(collisionTarget, "Carpet Bomb MO collision fixture must create a real target actor")
                    collisionTarget.Team = 1
                    local collisionX = target.x + 600
                    if collisionX > SceneMan.SceneWidth - 40 then collisionX = target.x - 600 end
                    assert(math.abs(collisionX - target.x) >= 500,
                        "test map must provide room to isolate the MO impact from terrain blast effects")
                    local collisionGround = SceneMan:MovePointToGround(Vector(collisionX, 0), 0,
                        CONFIG.map.outposts.groundProbe)
                    collisionTarget.Pos = Vector(collisionX, collisionGround.Y - 100)
                    collisionTarget.PinStrength = 1000000
                    collisionTarget.AIMode = Actor.AIMODE_SENTRY
                    MovableMan:AddActor(collisionTarget)
                    self.headlessBombCollisionTargetId = collisionTarget.UniqueID
                    self.headlessBombCollisionTargetHealth = collisionTarget.Health
                    for id in pairs(callinParticleIds("Frontline Carpet Bomb", "Frontline.rte", 0)) do
                        if not beforeBombs[id] then
                            local shell = findCallinParticle(id)
                            local rotating = shell and ToMOSRotating(shell)
                            assert(rotating, "released Carpet Bomb collection object must cast to MOSRotating")
                            local impactNumber = #impactShellIds + 1
                            if impactNumber == CONFIG.supportEffects.bombRun.count then
                                rotating.Pos = Vector(collisionTarget.Pos.X, collisionTarget.Pos.Y - 30)
                                rotating.Vel = Vector(0, 200)
                                self.headlessBombMOShellId = id
                                impactPoints[#impactPoints + 1] = {x=collisionTarget.Pos.X,
                                    y=collisionTarget.Pos.Y - 30, count=1}
                            else
                                local impactX = target.x + (impactNumber == 1 and -150 or 150)
                                local impactGround = SceneMan:MovePointToGround(Vector(impactX, 0), 0,
                                    CONFIG.map.outposts.groundProbe)
                                rotating.Pos = Vector(impactX, impactGround.Y - 1)
                                rotating.Vel = Vector(0, 200)
                                impactPoints[#impactPoints + 1] = {x=impactX, y=impactGround.Y - 1, count=1}
                            end
                            table.insert(impactShellIds, id)
                        end
                    end
                    assert(#impactShellIds == CONFIG.supportEffects.bombRun.count,
                        "all released Carpet Bomb shells must be available for impact coverage")
                    self.headlessBombImpactShellIds = impactShellIds
                    self.headlessBombImpactParticlesBefore = allCallinParticleIds()
                    self.headlessBombImpactPoints = impactPoints
                elseif case.kind == "shield" then
                    local field = self.jamFields[#self.jamFields]
                    assert(#self.jamFields == beforeJammers + 1 and field.team == 0 and field.x == target.x
                        and field.duration == CONFIG.supportEffects.shieldDurationByLevel[callLevel + 1]
                        and self:ShieldBlocks(target, 1),
                        "Jammer must create the researched duration field and block hostile support")
                elseif case.kind == "bubble" then
                    local field = self.energyShields[#self.energyShields]
                    assert(#self.energyShields == beforeBubbles + 1 and field.team == 0 and field.x == target.x
                        and field.radius == CONFIG.supportEffects.bubbleShield.radius
                        and field.duration == CONFIG.supportEffects.bubbleShield.duration,
                        "Energy Shield must create a team-owned projectile field")
                    self.headlessBubbleProjectiles = {field=field}
                else
                    local order = expectOrder(self.pendingDrops, case.kind)
                    assert(#self.pendingDrops == beforeDrops + 1 and order.team == 0 and order.target == target,
                        case.kind .. " must queue its targeted delivery")
                    if case.kind == "weaponPod" then
                        assert(#order.weaponPresets == CONFIG.supportEffects.weaponPod.count,
                            "weapon cache must queue the configured firearm count as loaded preset names")
                        local seenPresets = {}
                        for _, presetName in ipairs(order.weaponPresets) do
                            assert(type(presetName) == "string" and presetName:find("/", 1, true)
                                and not seenPresets[presetName],
                                "weapon cache must queue distinct qualified firearm preset identities")
                            seenPresets[presetName] = true
                            local probe = CreateHDFirearm(presetName)
                            assert(probe, "weapon cache must resolve loaded firearm " .. tostring(presetName))
                            probe.ToDelete = true
                        end
                        self.headlessWeaponPodOrder = order
                    else
                        if case.kind == "cover" then
                            assert(order.count == CONFIG.supportEffects.dropCountByLevel.cover[callLevel],
                                "Cover payload count must match researched level " .. callLevel)
                        elseif case.kind == "mines" then
                            assert(order.count == CONFIG.supportEffects.dropCountByLevel.mines[callLevel],
                                "Minefield payload count must match researched level " .. callLevel)
                        elseif case.kind == "medic" then
                            assert(order.count == CONFIG.supportEffects.medicDronesByLevel[callLevel + 1],
                                "Medic Drone count must match researched level " .. callLevel)
                        elseif case.kind == "turret" then
                            assert(order.count == 1, "turret call-in must queue exactly one turret")
                        end
                        if case.kind=="assaultSquad" then
                            local fundsAfterDelivery=team.funds
                            team.funds=60000
                            self:SetTeamFunds(team.funds,0)
                            for repeatIndex=1,8 do
                                team.assaultSquadTimer.ElapsedSimTimeMS=case.cooldown+1
                                local beforeRepeat=#self.pendingDrops
                                local repeated,repeatError=self.commanders[0]:CallIn(case.kind,targetIndex)
                                assert(repeated,"repeated Assault Squad call-in failed: "..tostring(repeatError))
                                local repeatOrder=expectOrder(self.pendingDrops,case.kind)
                                assert(#self.pendingDrops==beforeRepeat+1
                                    and #repeatOrder.squad==CONFIG.supportEffects.assaultSquad.count,
                                    "each repeated Assault call must stage the configured squad count")
                                local selectedThisCall={}
                                for _,passenger in ipairs(repeatOrder.squad) do
                                    local selectedWeapon
                                    local equipped=passenger.EquippedItem
                                    if equipped then
                                        local name=equipped.ModuleName.."/"..equipped.PresetName
                                        if assaultWeaponNames[name] then selectedWeapon=name end
                                    end
                                    for item in passenger.Inventory do
                                        local name=item.ModuleName.."/"..item.PresetName
                                        if assaultWeaponNames[name] then selectedWeapon=name end
                                    end
                                    assert(selectedWeapon and not selectedThisCall[selectedWeapon],
                                        "repeated Assault squad must carry distinct firearms from the eligible pool")
                                    selectedThisCall[selectedWeapon]=true
                                    assaultObservedWeapons[selectedWeapon]=true
                                    passenger.ToDelete=true
                                end
                                table.remove(self.pendingDrops,beforeRepeat+1)
                            end
                            team.assaultSquadTimer.ElapsedSimTimeMS=case.cooldown+1
                            local variedWeaponCount=0
                            for _ in pairs(assaultObservedWeapons) do variedWeaponCount=variedWeaponCount+1 end
                            assert(#assaultWeaponPresets<=CONFIG.supportEffects.assaultSquad.count
                                or variedWeaponCount>CONFIG.supportEffects.assaultSquad.count,
                                "repeated Assault squads must vary selections across the full eligible exotic pool")
                            team.funds=fundsAfterDelivery
                            self:SetTeamFunds(team.funds,0)
                        end
                        verifyDelivery(case, order)
                    end
                end
                self:SetTeamFunds(team.funds, 0)
            end
            team.levels[effectIndex] = maximumLevel
            return (case.kind == "strike" or case.kind == "bubble" or case.kind == "bomb"
                or case.kind == "weaponPod") and "PENDING" or "PASS"
        end)
        team.levels[effectIndex] = maximumLevel
        if not ok then
            results[case.kind] = "FAIL"
            failures[#failures + 1] = case.kind .. ": " .. tostring(result)
        else
            results[case.kind] = result
        end
    end
    local deliveryFailure = nil
    local deliveryOk, deliveryError = pcall(function()
        self.jamFields = {}
        team.funds = 60000
        self:SetTeamFunds(team.funds, 0)
        team.coverTimer.ElapsedSimTimeMS = 1000000
        local beforeInterceptFunds = team.funds
        local interceptIndex = #self.pendingDrops + 1
        assert(self.commanders[0]:CallIn("cover", targetIndex), "Cover interception fixture must order")
        local interceptedOrder = self.pendingDrops[interceptIndex]
        table.insert(self.jamFields, {x=target.x, team=1, timer=Timer(), duration=1000000})
        interceptedOrder.timer.ElapsedSimTimeMS = interceptedOrder.delay + 1
        self:UpdateCallIns()
        assert(self.pendingDrops[interceptIndex] == nil
            and team.funds == beforeInterceptFunds,
            "delayed hostile Jammer interception must remove Cover delivery and refund its full cost")
        table.remove(self.jamFields, #self.jamFields)

        team.coverTimer.ElapsedSimTimeMS = 1000000
        local beforeLostFunds = team.funds
        local lostIndex = #self.pendingDrops + 1
        assert(self.commanders[0]:CallIn("cover", targetIndex), "lost-ship fixture must order Cover")
        local lostOrder = self.pendingDrops[lostIndex]
        lostOrder.timer.ElapsedSimTimeMS = lostOrder.delay + 1
        self:UpdateCallIns()
        assert(lostOrder.ship and lostOrder.arrivalTimer,
            "delayed Cover delivery must create its real dropship before loss is tested")
        lostOrder.ship.Health = 0
        self:UpdateCallIns()
        assert(self.pendingDrops[lostIndex] == nil and team.funds == beforeLostFunds - lostOrder.cost,
            "lost dropship must remove the delivery without an unearned refund")
        team.coverTimer.ElapsedSimTimeMS = 1000000
        local beforeArrivalInterceptFunds = team.funds
        local arrivalIndex = #self.pendingDrops + 1
        assert(self.commanders[0]:CallIn("cover", targetIndex), "in-flight Jammer fixture must order Cover")
        local arrivalOrder = self.pendingDrops[arrivalIndex]
        arrivalOrder.timer.ElapsedSimTimeMS = arrivalOrder.delay + 1
        self:UpdateCallIns()
        assert(arrivalOrder.ship and arrivalOrder.ship.InventorySize == arrivalOrder.count,
            "Cover delivery must load its real cargo before in-flight interception")
        table.insert(self.jamFields, {x=target.x, team=1, timer=Timer(), duration=1000000})
        self:UpdateCallIns()
        assert(self.pendingDrops[arrivalIndex] == nil and team.funds == beforeArrivalInterceptFunds
            and arrivalOrder.ship.AIMode == Actor.AIMODE_RETURN
            and arrivalOrder.ship.PinStrength == 0 and arrivalOrder.ship.CanEnterOrbit,
            "in-flight Jammer interception must refund, remove the delivery, and return the dropship")
        table.remove(self.jamFields, #self.jamFields)
        team.levels[24], team.levels[21] = 1, 1
        team.strikeTimer.ElapsedSimTimeMS = 1000000
        local strikeFunds = team.funds
        local strikeIndex = #self.pendingStrikes + 1
        assert(self.commanders[0]:CallIn("strike", targetIndex), "precision interception fixture must order")
        local strike = self.pendingStrikes[strikeIndex]
        table.insert(self.jamFields, {x=target.x, team=1, timer=Timer(), duration=1000000})
        strike.timer.ElapsedSimTimeMS = CONFIG.CALLIN_STRIKE_DELAY_MS + 1
        self:UpdateCallIns()
        assert(self.pendingStrikes[strikeIndex] == nil and not strike.projectile
            and team.funds == strikeFunds,
            "Jammer-intercepted delayed precision strike must be removed and fully refunded")
        table.remove(self.jamFields, #self.jamFields)

        team.orbitalTimer.ElapsedSimTimeMS = 1000000
        local orbitalFunds = team.funds
        local roundsBeforeJam = callinParticleIds("Frontline Orbital Round", "Frontline.rte", 0)
        local orbitalIndex = #self.pendingOrbitals + 1
        assert(self.commanders[0]:CallIn("orbital", targetIndex), "orbital interception fixture must order")
        local orbital = self.pendingOrbitals[orbitalIndex]
        table.insert(self.jamFields, {x=target.x, team=1, timer=Timer(), duration=1000000})
        orbital.timer.ElapsedSimTimeMS = CONFIG.CALLIN_ORBITAL_DELAY_MS
            + CONFIG.CALLIN_ORBITAL_DURATION_MS
                * (orbital.total - 1) / (CONFIG.CALLIN_ORBITAL_SHOTS - 1) + 1
        self:UpdateCallIns()
        assert(self.pendingOrbitals[orbitalIndex] == nil
            and countNewCallinParticles("Frontline Orbital Round", "Frontline.rte", roundsBeforeJam) == 0
            and team.funds == orbitalFunds - CONFIG.CALLIN_ORBITAL_COST,
            "Jammer must block every delayed orbital round and finish the salvo without refund")
        table.remove(self.jamFields, #self.jamFields)
        team.minesTimer.ElapsedSimTimeMS = 1000000
        local miningFunds = team.funds
        local miningIndex = #self.pendingDrops + 1
        local miningOrdered, miningError = self.commanders[0]:CallIn("mining", targetIndex)
        assert(miningOrdered, "Mining cancellation fixture must order: " .. tostring(miningError)
            .. " (funds=" .. tostring(team.funds) .. " minesTimer=" .. tostring(team.minesTimer.ElapsedSimTimeMS) .. ")")
        local miningOrder = self.pendingDrops[miningIndex]
        local miner = miningOrder.miner
        miningOrder.timer.ElapsedSimTimeMS = miningOrder.delay + 1
        self:UpdateCallIns()
        assert(miningOrder.ship and miningOrder.ship.InventorySize == 1,
            "Mining passenger must be loaded before cancellation")
        table.insert(self.jamFields, {x=target.x, team=1, timer=Timer(), duration=1000000})
        self:UpdateCallIns()
        assert(self.pendingDrops[miningIndex] == nil and team.funds == miningFunds
            and miningOrder.ship.InventorySize == 0 and miningOrder.ship.AIMode == Actor.AIMODE_RETURN
            and miner.ToDelete,
            "in-flight Mining interception must refund, return the dropship, and dispose of its ship-owned miner")
        table.remove(self.jamFields, #self.jamFields)

        team.weaponPodTimer.ElapsedSimTimeMS = 1000000
        local podJamFunds = team.funds
        local podJamIndex = #self.pendingDrops + 1
        assert(self.commanders[0]:CallIn("weaponPod", targetIndex), "Weapon Pod Jammer fixture must order")
        local podJamOrder = self.pendingDrops[podJamIndex]
        table.insert(self.jamFields, {x=target.x, team=1, timer=Timer(), duration=1000000})
        podJamOrder.timer.ElapsedSimTimeMS = podJamOrder.delay + 1
        self:UpdateCallIns()
        assert(self.pendingDrops[podJamIndex] == nil and team.funds == podJamFunds,
            "Jammer-intercepted Weapon Pod must be removed and refunded")
        table.remove(self.jamFields, #self.jamFields)

        team.weaponPodTimer.ElapsedSimTimeMS = 1000000
        local inFlightPodFunds = team.funds
        local inFlightPodIndex = #self.pendingDrops + 1
        assert(self.commanders[0]:CallIn("weaponPod", targetIndex),
            "in-flight Weapon Pod Jammer fixture must order")
        local inFlightPodOrder = self.pendingDrops[inFlightPodIndex]
        inFlightPodOrder.timer.ElapsedSimTimeMS = inFlightPodOrder.delay + 1
        self:UpdateCallIns()
        local inFlightPodObject = MovableMan:FindObjectByUniqueID(inFlightPodOrder.podID)
        local inFlightPod = inFlightPodObject and ToMOSRotating(inFlightPodObject) or nil
        assert(inFlightPod and MovableMan:IsParticle(inFlightPodObject) and not inFlightPodOrder.weapons,
            "Weapon Pod must exist in flight without pre-releasing its guns")
        table.insert(self.jamFields, {x=target.x, team=1, timer=Timer(), duration=1000000})
        self:UpdateCallIns()
        assert(self.pendingDrops[inFlightPodIndex] == nil and team.funds == inFlightPodFunds
            and inFlightPod.ToDelete,
            "in-flight hostile Jammer must dispose of the Weapon Pod and refund its order")
        table.remove(self.jamFields, #self.jamFields)

        team.weaponPodTimer.ElapsedSimTimeMS = 1000000
        local destroyedPodFunds = team.funds
        local destroyedPodIndex = #self.pendingDrops + 1
        assert(self.commanders[0]:CallIn("weaponPod", targetIndex), "destroyed pod fixture must order")
        local destroyedPodOrder = self.pendingDrops[destroyedPodIndex]
        destroyedPodOrder.timer.ElapsedSimTimeMS = destroyedPodOrder.delay + 1
        self:UpdateCallIns()
        local destroyedPodObject = destroyedPodOrder.podID
            and MovableMan:FindObjectByUniqueID(destroyedPodOrder.podID) or nil
        local destroyedPod = destroyedPodObject and ToMOSRotating(destroyedPodObject) or nil
        assert(destroyedPod and MovableMan:IsParticle(destroyedPodObject)
            and destroyedPod.PresetName == "Frontline Weapon Pod",
            "Weapon Pod must spawn and enter MovableMan before destruction behavior is tested")
        destroyedPod.ToDelete = true
        self:UpdateCallIns()
        assert(self.pendingDrops[destroyedPodIndex] == nil
            and team.funds == destroyedPodFunds - CONFIG.CALLIN_WEAPON_POD_COST,
            "destroyed unopened Weapon Pod must cancel without refund")

        team.assaultSquadTimer.ElapsedSimTimeMS = 1000000
        local assaultFunds = team.funds
        local assaultIndex = #self.pendingDrops + 1
        assert(self.commanders[0]:CallIn("assaultSquad", targetIndex), "Assault cancellation fixture must order")
        local assaultOrder = self.pendingDrops[assaultIndex]
        local passengers = assaultOrder.squad
        assaultOrder.timer.ElapsedSimTimeMS = assaultOrder.delay + 1
        table.insert(self.jamFields, {x=target.x, team=1, timer=Timer(), duration=1000000})
        self:UpdateCallIns()
        assert(self.pendingDrops[assaultIndex] == nil and team.funds == assaultFunds,
            "Jammer-intercepted Assault delivery must remove the order and refund its cost")
        for _, passenger in ipairs(passengers) do
            assert(passenger.ToDelete, "Jammer-intercepted Assault delivery must dispose of every staged passenger")
        end
        table.remove(self.jamFields, #self.jamFields)
    end)
    if not deliveryOk then
        deliveryFailure = tostring(deliveryError)
        failures[#failures + 1] = "delivery interception/loss: " .. deliveryFailure
    end

    local bombRunOk, bombRunError = pcall(function()
        self.jamFields = {}
        team.bombTimer.ElapsedSimTimeMS = 1000000
        team.funds = 60000
        self:SetTeamFunds(team.funds, 0)
        local prelaunchFunds = team.funds
        local prelaunchIndex = #self.pendingDrops + 1
        assert(self.commanders[0]:CallIn("bomb", targetIndex), "prelaunch bomb Jammer fixture must order")
        local prelaunch = self.pendingDrops[prelaunchIndex]
        table.insert(self.jamFields, {x=target.x, team=1, timer=Timer(), duration=1000000})
        prelaunch.timer.ElapsedSimTimeMS = 1
        self:UpdateCallIns()
        assert(self.pendingDrops[prelaunchIndex] == nil and prelaunch.bombsDropped == 0
            and team.funds == prelaunchFunds and prelaunch.ship.AIMode == Actor.AIMODE_RETURN
            and prelaunch.ship.PinStrength == 0 and prelaunch.ship.CanEnterOrbit,
            "prelaunch Jammer must cancel the bomb run, refund fully, and send its ship home")
        table.remove(self.jamFields, #self.jamFields)

        team.bombTimer.ElapsedSimTimeMS = 1000000
        local releasedIndex = #self.pendingDrops + 1
        assert(self.commanders[0]:CallIn("bomb", targetIndex), "post-release bomb Jammer fixture must order")
        local released = self.pendingDrops[releasedIndex]
        released.timer.ElapsedSimTimeMS = CONFIG.supportEffects.bombRun.intervalMs
        self:UpdateCallIns()
        assert(released.bombsDropped == 1 and self.pendingDrops[releasedIndex] == released,
            "bomb run must launch the first shell before testing a mid-run Jammer")
        local afterReleaseFunds = team.funds
        table.insert(self.jamFields, {x=target.x, team=1, timer=Timer(), duration=1000000})
        self:UpdateCallIns()
        assert(self.pendingDrops[releasedIndex] == nil and team.funds == afterReleaseFunds
            and released.bombsDropped == 1 and released.ship.AIMode == Actor.AIMODE_RETURN
            and released.ship.PinStrength == 0 and released.ship.CanEnterOrbit,
            "post-release Jammer must stop remaining bombs without refund and return the ship")
        table.remove(self.jamFields, #self.jamFields)

        team.bombTimer.ElapsedSimTimeMS = 1000000
        local lostFunds = team.funds
        local lostIndex = #self.pendingDrops + 1
        assert(self.commanders[0]:CallIn("bomb", targetIndex), "bomb ship loss fixture must order")
        local lost = self.pendingDrops[lostIndex]
        lost.ship.Health = 0
        self:UpdateCallIns()
        assert(self.pendingDrops[lostIndex] == nil and team.funds == lostFunds - CONFIG.CALLIN_BOMB_COST,
            "lost bomb-run ship must remove its pending run without refund")
    end)
    if not bombRunOk then
        results.bomb = "FAIL"
        failures[#failures + 1] = "bomb-run interception/loss: " .. tostring(bombRunError)
    end
    local jammerOk, jammerFailure = pcall(function()
        local enemy = self.teams[1]
        local originalStrikeResearch = enemy.levels[24] or 0
        enemy.levels[24] = 1
        enemy.funds = 1000
        enemy.strikeTimer.ElapsedSimTimeMS = 1000000
        local enemyFundsBefore = enemy.funds
        local enemyTimerBefore = enemy.strikeTimer.ElapsedSimTimeMS
        table.insert(self.jamFields, {x=target.x, groundY=target.groundY, team=0, timer=Timer(),
            duration=CONFIG.supportEffects.shieldDurationByLevel[1]})
        local jammerRadius = CONFIG.CALLIN_JAM_RADIUS
        assert(self:ShieldBlocks({x=target.x + jammerRadius}, 1)
            and self:ShieldBlocks({x=target.x - jammerRadius}, 1)
            and not self:ShieldBlocks({x=target.x + jammerRadius + 1}, 1)
            and not self:ShieldBlocks({x=target.x - jammerRadius - 1}, 1)
            and not self:ShieldBlocks(target, 0),
            "Jammer must block hostile support at inclusive radius boundaries but allow friendly support")
        local jammerBlocked, jammerError = self.commanders[1]:CallIn("strike", targetIndex)
        assert(not jammerBlocked and jammerError == "Enemy jammer blocks support here"
            and enemy.funds == enemyFundsBefore and enemy.strikeTimer.ElapsedSimTimeMS == enemyTimerBefore,
            "hostile Jammer must reject enemy support without payment or cooldown")
        local jammer = self.jamFields[#self.jamFields]
        assert(jammer and self:ShieldBlocks(target, 1), "active Jammer must block hostile support")
        for _, field in ipairs(self.jamFields) do field.timer.ElapsedSimTimeMS = field.duration + 1 end
        self:UpdateCallIns()
        assert(not self:ShieldBlocks(target, 1), "expired Jammer must stop blocking hostile support")
        assert(#self.jamFields == 0, "expired Jammer fields must be removed by production update")
        enemy.levels[24] = originalStrikeResearch
    end)
    if not jammerOk then
        results.shield = "FAIL"
        failures[#failures + 1] = "shield hostile-jammer rejection: " .. tostring(jammerFailure)
    end

    local teamOneOk, teamOneError = pcall(function()
        local enemy = self.teams[1]
        assert(self:SupportTargetAllowed(1, target.x), "team-1 target must be outside its enemy-base exclusion")
        enemy.funds = 60000
        self:SetTeamFunds(enemy.funds, 1)
        for _, researchIndex in ipairs({21, 24, 22}) do
            local researchCost = self:ResearchCost(1, researchIndex)
            local fundsBefore = enemy.funds
            local researched, researchError = self.commanders[1]:Research(researchIndex)
            assert(researched and enemy.levels[researchIndex] == 1
                and enemy.funds == fundsBefore - researchCost,
                "team-1 support research " .. researchIndex .. " must use production purchase and debit exact cost: "
                    .. tostring(researchError))
        end

        enemy.strikeTimer.ElapsedSimTimeMS = 1000000
        local strikeFunds = enemy.funds
        local strikeIndex = #self.pendingStrikes + 1
        local strikeOrdered, strikeError = self.commanders[1]:CallIn("strike", targetIndex)
        assert(strikeOrdered and enemy.funds == strikeFunds - CONFIG.CALLIN_STRIKE_COST
            and enemy.strikeTimer.ElapsedSimTimeMS == 0,
            "team-1 Precision Strike must order through production and debit its exact cost: " .. tostring(strikeError))
        local strike = self.pendingStrikes[strikeIndex]
        assert(strike and strike.team == 1 and strike.target == target,
            "team-1 Precision Strike must retain team ownership and requested target")
        strike.timer.ElapsedSimTimeMS = CONFIG.CALLIN_STRIKE_DELAY_MS + 1
        self:UpdateCallIns()
        local projectile = strike.projectile
        local ground = SceneMan:MovePointToGround(Vector(target.x, 0), 0, CONFIG.map.outposts.groundProbe)
        assert(projectile and projectile.Team == 1
            and projectile.PresetName == "Frontline Precision Projectile"
            and math.abs(projectile.Pos.X - ground.X) <= 1
            and projectile.Pos.Y == math.max(0, ground.Y - CONFIG.CALLIN_PRECISION_HEIGHT)
            and projectile.Vel.X == 0 and projectile.Vel.Y == CONFIG.CALLIN_PRECISION_SPEED,
            "team-1 Precision Strike must create the configured live projectile at its target with team ownership")

        enemy.coverTimer.ElapsedSimTimeMS = 1000000
        local coverFunds = enemy.funds
        local coverIndex = #self.pendingDrops + 1
        local beforeCoverPods = callinParticleIds("Frontline Cover Pod", "Frontline.rte")
        local coverOrdered, coverError = self.commanders[1]:CallIn("cover", targetIndex)
        assert(coverOrdered and enemy.funds == coverFunds - CONFIG.CALLIN_COVER_COST
            and enemy.coverTimer.ElapsedSimTimeMS == 0,
            "team-1 Cover must order through production and debit its exact cost: " .. tostring(coverError))
        local cover = self.pendingDrops[coverIndex]
        assert(cover and cover.kind == "cover" and cover.team == 1 and cover.target == target
            and cover.count == CONFIG.supportEffects.dropCountByLevel.cover[1],
            "team-1 Cover must queue the configured payload for its requested target")
        cover.timer.ElapsedSimTimeMS = cover.delay + 1
        self:UpdateCallIns()
        assert(cover.ship and cover.ship.Team == 1 and cover.ship.InventorySize == cover.count,
            "team-1 Cover must create a team-owned dropship carrying its complete payload")
        cover.arrivalTimer.ElapsedSimTimeMS = CONFIG.supportEffects.delivery.approachMs + 1
        self:UpdateCallIns()
        assert(cover.ship.InventorySize == 0
            and countNewCallinParticles("Frontline Cover Pod", "Frontline.rte", beforeCoverPods, 1) == cover.count,
            "team-1 dropship must release every Cover pod as a live team-owned effect")
        results.team1 = "PASS"
    end)
    if not teamOneOk then
        results.team1 = "FAIL"
        failures[#failures + 1] = "team-1 successful call-ins: " .. tostring(teamOneError)
    end

    -- Defer landing until subsequent real engine frames; never synthesize its landed flag.
    local weaponPodSetupOk, weaponPodSetupError = pcall(function()
        local order = self.headlessWeaponPodOrder
        assert(order and order.kind == "weaponPod" and order.team == 0 and order.target == target,
            "Weapon Pod landing fixture must retain its actual team-owned call-in order")
        local pendingOrder = false
        for _, queued in ipairs(self.pendingDrops) do
            if queued == order then pendingOrder = true end
        end
        assert(pendingOrder, "Weapon Pod pending order must remain live until physical landing")
        order.timer.ElapsedSimTimeMS = order.delay + 1
        self:UpdateCallIns()
        assert(type(order.podID) == "number", "production must assign a stable Weapon Pod ID when it spawns")
        local podObject = MovableMan:FindObjectByUniqueID(order.podID)
        local pod = podObject and ToMOSRotating(podObject) or nil
        assert(pod and MovableMan:IsParticle(podObject) and pod.PresetName == "Frontline Weapon Pod"
            and pod.Team == 0 and pod.Vel.Y == CONFIG.supportEffects.weaponPod.descentVelocity
            and not order.landedTimer,
            "Weapon Pod must start as an unopened team-owned falling physical object")
        local coverProbe = CreateMOSRotating("Frontline Cover Pod", "Frontline.rte")
        assert(coverProbe and pod:GetSpriteHeight() ~= coverProbe:GetSpriteHeight(),
            "Weapon Pod must use a visually distinct physical sprite from the cover payload")
        if coverProbe then coverProbe.ToDelete = true end
        local ground = SceneMan:MovePointToGround(Vector(target.x, 0), 0, CONFIG.map.outposts.groundProbe)
        pod.Pos = Vector(target.x, ground.Y - (pod.Radius or 12) - 2)
        pod.Vel = Vector(0, CONFIG.supportEffects.weaponPod.descentVelocity)
        self.headlessWeaponPodTest = {order=order,podId=order.podID,ground=ground,updates=0}
    end)
    if not weaponPodSetupOk then
        results.weaponPod = "FAIL"
        failures[#failures + 1] = "Weapon Pod real landing setup: " .. tostring(weaponPodSetupError)
    end

    local fields, blocked = {}, false
    for _, case in ipairs(cases) do
        local status = results[case.kind] or "FAIL"
        fields[#fields + 1] = case.kind .. "=" .. status
        if status:find("BLOCKED:", 1, true) then blocked = true end
    end
    fields[#fields + 1] = "team1=" .. (results.team1 or "FAIL")
    local prefix = #failures > 0 and "FAIL" or (blocked and "BLOCKED" or "PASS")
    local payload = prefix .. " callins " .. table.concat(fields, " ")
    if #failures > 0 then payload = payload .. " failures=" .. table.concat(failures, " | ") end
    return payload
end

Frontline.StartActivity = function(self, ...)
    originalCallinHeadlessStartActivity(self, ...)
    local ok, result = pcall(runHeadlessCallinSuite, self)
    if not ok then
        writeCallinHeadlessResult("FAIL callins setup: " .. tostring(result))
    else
        self.headlessCallinResult = result
        writeCallinHeadlessResult(result)
    end
end
local originalCallinHeadlessUpdateActivity = Frontline.UpdateActivity

local function recordCallinFixtureResult(self, kind, ok, failure)
    local result = self.headlessCallinResult
    if ok then
        result = result:gsub(kind .. "=PENDING", kind .. "=PASS")
    else
        result = result:gsub("^PASS", "FAIL") .. " failures=" .. kind .. ": " .. tostring(failure)
    end
    self.headlessCallinResult = result
    writeCallinHeadlessResult(result)
end

Frontline.UpdateActivity = function(self, ...)
    originalCallinHeadlessUpdateActivity(self, ...)
    local weaponPodTest = self.headlessWeaponPodTest
    if weaponPodTest then
        weaponPodTest.updates = weaponPodTest.updates + 1
        local order = weaponPodTest.order
        -- Resolve the live particle afresh each frame instead of retaining a collection wrapper.
        local podObject = MovableMan:FindObjectByUniqueID(weaponPodTest.podId)
        local pod = podObject and ToMOSRotating(podObject) or nil
        local isParticle = podObject and MovableMan:IsParticle(podObject) or false
        if not pod or not isParticle then
            local listed = allCallinParticleIds()[weaponPodTest.podId] == true
            self.headlessWeaponPodTest = nil
            recordCallinFixtureResult(self, "weaponPod", false,
                "Weapon Pod left MovableMan before landing (id=" .. tostring(weaponPodTest.podId)
                    .. ", found=" .. tostring(podObject ~= nil) .. ", MOSRotating=" .. tostring(pod ~= nil)
                    .. ", particle=" .. tostring(isParticle) .. ", inParticleCollections=" .. tostring(listed) .. ")")
        elseif order.landedTimer then
            local ok, failure = pcall(function()
                assert(pod:GetNumberValue("WeaponPodLanded") > 0 and math.abs(pod.Vel.Y) < 1,
                    "real terrain contact must set WeaponPodLanded and stop the falling pod")
                order.landedTimer.ElapsedSimTimeMS = CONFIG.supportEffects.weaponPod.openDelayMs
                self:UpdateCallIns()
                local pending = false
                for _, queued in ipairs(self.pendingDrops) do
                    if queued == order then pending = true end
                end
                local atBoundaryObject = MovableMan:FindObjectByUniqueID(weaponPodTest.podId)
                local atBoundaryPod = atBoundaryObject and ToMOSRotating(atBoundaryObject) or nil
                assert(atBoundaryPod and not atBoundaryPod.ToDelete and pending,
                    "physically landed Weapon Pod must remain closed through the exact opening-delay boundary")
                order.landedTimer.ElapsedSimTimeMS = CONFIG.supportEffects.weaponPod.openDelayMs + 1
                self:UpdateCallIns()
                assert(order.weapons and #order.weapons == CONFIG.supportEffects.weaponPod.count,
                    "opening Weapon Pod must construct all configured firearms before completing delivery")
                pending = false
                for _, queued in ipairs(self.pendingDrops) do
                    if queued == order then pending = true end
                end
                local livePod = findCallinParticle(weaponPodTest.podId)
                assert((not livePod or livePod.ToDelete) and not pending,
                    "opened Weapon Pod must remove its shell and complete the pending delivery")
                for index, weapon in ipairs(order.weapons) do
                    local spread = index - (#order.weapons + 1) / 2
                    assert(weapon.Team == 0 and MovableMan:IsDevice(weapon)
                        and ToHDFirearm(weapon) ~= nil
                        and math.abs(weapon.Pos.X - (order.target.x + spread * CONFIG.supportEffects.weaponPod.releaseSpread)) <= 1
                        and math.abs(weapon.Pos.Y - (weaponPodTest.ground.Y - 12)) <= 1
                        and weapon.Vel.X == spread * CONFIG.supportEffects.weaponPod.releaseHorizontalVelocity
                        and weapon.Vel.Y == CONFIG.supportEffects.weaponPod.releaseVerticalVelocity,
                        "Weapon Pod must physically dispense each team-owned usable firearm at its configured ground spread")
                end
            end)
            self.headlessWeaponPodTest = nil
            recordCallinFixtureResult(self, "weaponPod", ok, failure)
        elseif weaponPodTest.updates >= 8 then
            local landed = pod:GetNumberValue("WeaponPodLanded")
            local centerY, radius = pod.Pos.Y, pod.Radius or 0
            local velocity = pod.Vel.Y
            self.headlessWeaponPodTest = nil
            recordCallinFixtureResult(self, "weaponPod", false,
                "physical Weapon Pod terrain contact did not start the opening timer within eight updates"
                    .. " (landed=" .. tostring(landed) .. ", centerY=" .. tostring(centerY)
                    .. ", bottomY=" .. tostring(centerY + radius) .. ", groundY=" .. tostring(order.target.groundY)
                    .. ", velocityY=" .. tostring(velocity) .. ")")
        end
    end
    local strikeImpact = self.headlessStrikeImpact
    if strikeImpact then
        strikeImpact.updates = strikeImpact.updates + 1
        local projectile = findCallinParticle(strikeImpact.id)
        local removed = not projectile or projectile.ToDelete
        local blasts = countNewCallinPresetNear("Air Blast", strikeImpact.before,
            strikeImpact.x, strikeImpact.y, 250)
        if removed and blasts >= 1 then
            self.headlessStrikeImpact = nil
            recordCallinFixtureResult(self, "strike", true)
        elseif strikeImpact.updates >= 5 then
            self.headlessStrikeImpact = nil
            recordCallinFixtureResult(self, "strike", false,
                "precision projectile did not collide and detonate at target within five updates"
                    .. " (removed=" .. tostring(removed) .. ", live Air Blast=" .. blasts .. ")")
        end
    end
    local shellIds = self.headlessBombImpactShellIds
    if shellIds then
        self.headlessBombImpactUpdates = (self.headlessBombImpactUpdates or 0) + 1
        local impacted = 0
        for _, id in ipairs(shellIds) do
            local shell = findCallinParticle(id)
            if not shell or shell.ToDelete then impacted = impacted + 1 end
        end
        local moShell = findCallinParticle(self.headlessBombMOShellId)
        local moImpact = self.headlessBombMOShellId == nil or not moShell or moShell.ToDelete
        local obstacle = findCallinActor(self.headlessBombCollisionTargetId)
        local obstacleDamaged = self.headlessBombCollisionTargetId == nil or not obstacle
            or obstacle.ToDelete or obstacle.Health < self.headlessBombCollisionTargetHealth
        local blastCounts = {
            ["Air Blast"] = countNewCallinPreset("Air Blast", self.headlessBombImpactParticlesBefore),
            ["Grenade Fragment Gray"] = countNewCallinPreset("Grenade Fragment Gray", self.headlessBombImpactParticlesBefore),
            ["Fire Puff Large"] = countNewCallinPreset("Fire Puff Large", self.headlessBombImpactParticlesBefore),
        }
        local impactEffects = true
        local impactDetails = {}
        for _, point in ipairs(self.headlessBombImpactPoints) do
            local perType = {}
            for _, preset in ipairs({"Air Blast", "Grenade Fragment Gray", "Fire Puff Large"}) do
                perType[preset] = countNewCallinPresetNear(preset, self.headlessBombImpactParticlesBefore,
                    point.x, point.y, 125)
                if perType[preset] < point.count then impactEffects = false end
            end
            impactDetails[#impactDetails + 1] = "impact@" .. math.floor(point.x) .. ":"
                .. perType["Air Blast"] .. "/" .. perType["Grenade Fragment Gray"]
                .. "/" .. perType["Fire Puff Large"] .. " expected>=" .. point.count
        end
        if impacted == #shellIds and moImpact and obstacleDamaged and impactEffects
            and blastCounts["Air Blast"] >= #shellIds
            and blastCounts["Grenade Fragment Gray"] >= #shellIds
            and blastCounts["Fire Puff Large"] >= #shellIds then
            self.headlessBombImpactShellIds = nil
            self.headlessBombMOShellId = nil
            recordCallinFixtureResult(self, "bomb", true)
        elseif self.headlessBombImpactUpdates >= 5 then
            self.headlessBombImpactShellIds = nil
            local failure = "Carpet Bomb impacts=" .. impacted .. "/" .. #shellIds
                .. " MO shell removed=" .. tostring(moImpact)
                .. " collision target damaged=" .. tostring(obstacleDamaged)
                .. "; aggregate effects Air Blast=" .. blastCounts["Air Blast"]
                .. " Grenade Fragment Gray=" .. blastCounts["Grenade Fragment Gray"]
                .. " Fire Puff Large=" .. blastCounts["Fire Puff Large"]
                .. "; local effect attribution " .. table.concat(impactDetails, " | ")
            recordCallinFixtureResult(self, "bomb", false, failure)
        end
    end
    local projectiles = self.headlessBubbleProjectiles
    if not projectiles then return end
    if not projectiles.hostile then
        local hostile = CreateMOPixel("Frontline Precision Projectile", "Frontline.rte")
        local friendly = CreateMOPixel("Frontline Precision Projectile", "Frontline.rte")
        local edge = CreateMOPixel("Frontline Precision Projectile", "Frontline.rte")
        local outside = CreateMOPixel("Frontline Precision Projectile", "Frontline.rte")
        assert(hostile and friendly and edge and outside,
            "Energy Shield projectile interception fixtures must load")
        hostile.Team, edge.Team, outside.Team, friendly.Team = 1, 1, 1, 0
        hostile.Pos = Vector(projectiles.field.x, projectiles.field.centerY)
        friendly.Pos = Vector(projectiles.field.x, projectiles.field.centerY)
        edge.Pos = Vector(projectiles.field.x + projectiles.field.radius, projectiles.field.centerY)
        outside.Pos = Vector(projectiles.field.x + projectiles.field.radius + 1, projectiles.field.centerY)
        hostile.HitsMOs, friendly.HitsMOs, edge.HitsMOs, outside.HitsMOs = true, true, true, true
        hostile.Vel, friendly.Vel, edge.Vel, outside.Vel = Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0)
        MovableMan:AddParticle(hostile)
        MovableMan:AddParticle(friendly)
        MovableMan:AddParticle(edge)
        MovableMan:AddParticle(outside)
        projectiles.hostile, projectiles.friendly = hostile, friendly
        projectiles.edge, projectiles.outside = edge, outside
        return
    end
    self.headlessBubbleProjectiles = nil
    local ok, failure = pcall(function()
        assert(projectiles.edge.ToDelete and not projectiles.outside.ToDelete,
            "Energy Shield must intercept a hostile projectile at its inclusive radius and preserve one just outside")
        self:UpdateEnergyShields()
        assert(projectiles.hostile.ToDelete and not projectiles.friendly.ToDelete,
            "Energy Shield must intercept hostile projectiles and preserve friendly projectiles"
                .. " (hostile.ToDelete=" .. tostring(projectiles.hostile.ToDelete)
                .. ", friendly.ToDelete=" .. tostring(projectiles.friendly.ToDelete) .. ")")
        projectiles.field.timer.ElapsedSimTimeMS = projectiles.field.duration + 1
        self:UpdateEnergyShields()
        assert(#self.energyShields == 0, "expired Energy Shield must be removed by production update")
        local afterExpiry = CreateMOPixel("Frontline Precision Projectile", "Frontline.rte")
        assert(afterExpiry, "post-expiry Energy Shield projectile fixture must load")
        afterExpiry.Team = 1
        afterExpiry.Pos = Vector(projectiles.field.x, projectiles.field.centerY)
        afterExpiry.HitsMOs = true
        afterExpiry.Vel = Vector(0, 0)
        MovableMan:AddParticle(afterExpiry)
        self:UpdateEnergyShields()
        assert(not afterExpiry.ToDelete,
            "expired Energy Shield must not intercept hostile projectiles")
    end)
    recordCallinFixtureResult(self, "bubble", ok, failure)
end
