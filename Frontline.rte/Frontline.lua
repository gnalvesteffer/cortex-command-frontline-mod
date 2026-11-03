-- Frontline balance and roster. All prices are in gold ounces.
local CONFIG = {
    DEPLOY_COOLDOWN_MS = 10000, FORWARD_DEPLOY_COOLDOWN_MS = 20000, -- Shared by manual and automatic deployment.
    START_FUNDS = 450, INCOME_PER_SECOND = 5, BOUNTY = 35,
    TEAM_UNIT_CAP = 50, MAX_BATCH = 6,
    UNIT_ARMOR_COST = 60, UNIT_ARMOR_HEALTH = 50,
    FORWARD_SHIP_PASSENGERS = 3, FORWARD_LANDING_OFFSET = 150, FORWARD_SHIP_SEPARATION = 170, FORWARD_DROP_HEIGHT = 650,
    GRACE_MS = 15000, OUTPOST_CAPTURE_SECONDS = 8, OUTPOST_INCOME = 2, OUTPOST_RADIUS = 180,
    MINER_GOLD_SCAN_STEP = 24, MINER_CHECK_INTERVAL_MS = 1000, MINER_RESCAN_INTERVAL_MS = 15000, MINER_DIG_DISTANCE = 45,
    ENEMY_BASE_SUPPORT_EXCLUSION_RADIUS = 600, -- Applied equally to both teams.
    CALLIN_STRIKE_COST = 220, CALLIN_STRIKE_COOLDOWN_MS = 45000,
    CALLIN_STRIKE_DELAY_MS = 3000, CALLIN_PRECISION_HEIGHT = 600, CALLIN_PRECISION_SPEED = 60, CALLIN_PRECISION_FLIGHT_MS = 5000, CALLIN_MEDIC_COST = 120,
    CALLIN_MEDIC_COOLDOWN_MS = 30000, CALLIN_HEAL = 35,
    CALLIN_COVER_COST = 140, CALLIN_COVER_COOLDOWN_MS = 40000, CALLIN_COVER_DELAY_MS = 4000,
    CALLIN_MINES_COST = 180, CALLIN_MINES_COOLDOWN_MS = 45000, CALLIN_MINES_DELAY_MS = 4000, SUPPORT_DROP_APPROACH_MS = 2000,
    CALLIN_BOMB_COST = 260, CALLIN_BOMB_COOLDOWN_MS = 55000, CALLIN_BOMB_DELAY_MS = 4000,
    CALLIN_TURRET_COST = 300, CALLIN_TURRET_COOLDOWN_MS = 90000, CALLIN_TURRET_DELAY_MS = 4000,
    CALLIN_ORBITAL_COST = 175, CALLIN_ORBITAL_COOLDOWN_MS = 75000,
    CALLIN_ORBITAL_DELAY_MS = 3000, CALLIN_ORBITAL_SHOTS = 48, CALLIN_ORBITAL_BONUS_SHOTS = 24,
    CALLIN_ORBITAL_DURATION_MS = 5000, CALLIN_ORBITAL_RADIUS = 150,
    CALLIN_ORBITAL_HEIGHT = 350, CALLIN_ORBITAL_SPEED = 150, CALLIN_ORBITAL_SOUND_EVERY = 4,
    CALLIN_SHIELD_COST = 200, CALLIN_SHIELD_COOLDOWN_MS = 60000, CALLIN_SHIELD_DURATION_MS = 20000, CALLIN_JAM_RADIUS = 180,
    BASE_ARMOR_COST = 200, BASE_ARMOR_HEALTH = 50, BASE_ARMOR_LEVELS = 3,
    BASE_REPAIR_COST = 120, BASE_REPAIR_HEALTH = 50, BASE_TURRET_COST = 350,
    BASE_TOWER_DISTANCE = 436, BASE_TOWER_HEIGHT = 136, BASE_TURRET_HEIGHT = 121,
    roster = {
        {name="Coalition Light", actor="Soldier Light", mod="Coalition.rte", price=75, unlock=0},
        {name="Coalition Heavy", actor="Soldier Heavy", mod="Coalition.rte", price=120, unlock=1},
        {name="Dummy", actor="Dummy", mod="Dummy.rte", price=105, unlock=2},
        {name="Browncoat Light", actor="Browncoat", mod="Browncoats.rte", price=145, unlock=3},
        {name="Gatling Drone", actor="Gatling Drone", mod="Coalition.rte", price=260, unlock=2, vehicle=true},
        {name="Miner", actor="Soldier Light", mod="Coalition.rte", price=100, unlock=0, research=11, miner=true},
        {name="Ronin Bandit", actor="Bandit", mod="Ronin.rte", price=50, unlock=0},
    },
    weapons = {
        {name="Pistol", preset="Pistol", mod="Base.rte", price=5, unlock=0},
        {name="SMG", preset="SMG", mod="Base.rte", price=30, unlock=0, research=6},
        {name="Shotgun", preset="Shotgun", mod="Coalition.rte", price=25, unlock=0, research=7},
        {name="Assault Rifle", preset="Assault Rifle", mod="Coalition.rte", price=45, unlock=0, research=14},
        {name="Sniper Rifle", preset="Sniper Rifle", mod="Coalition.rte", price=70, unlock=0, research=8},
        {name="Missile Launcher", preset="Missile Launcher", mod="Coalition.rte", price=95, unlock=2, research=9},
        {name="Gatling Gun", preset="Gatling Gun", mod="Coalition.rte", price=120, unlock=2},
    },
    research = {
        {name="Income +2/s", price=180, max=10, kind="income"},
        {name="Bounty +15", price=160, max=10, kind="bounty"},
        {name="Infantry: Heavy Troop", price=200, max=1, kind="tier", tier=1},
        {name="Faction: Dummy / Gatling", price=350, max=1, kind="tier", tier=2},
        {name="Faction: Browncoat", price=500, max=1, kind="tier", tier=3},
        {name="Equipment: SMG", price=150, max=1, kind="equipment"},
        {name="Equipment: Shotgun", price=160, max=1, kind="equipment"},
        {name="Equipment: Sniper Rifle", price=180, max=1, kind="equipment", requires=1},
        {name="Equipment: Missile Launcher", price=260, max=1, kind="equipment", requires=2},
        {name="Support: More cover / mines", price=250, max=1, kind="support", requires=1},
        {name="Support: Longer orbital burst (+24 rounds)", price=350, max=1, kind="support", requires=2},
        {name="Training: Perception +5%", price=250, max=10, kind="training"},
        {name="Industry: Mining squad", price=200, max=1, kind="mining"},
        {name="Equipment: Assault Rifle", price=150, max=1, kind="equipment"},
        {name="Equipment: Medikit packs", price=200, max=1, kind="equipment"},
        {name="Equipment: Grenade packs", price=220, max=1, kind="equipment"},
        {name="Equipment: Sidearms", price=180, max=1, kind="equipment"},
        {name="Equipment: Unit armor (+50 HP)", price=260, max=1, kind="equipment"},
    }
}

-- A right click walks through the same ordered options in reverse.
local function cycleOption(options,current,direction)
    for i,value in ipairs(options) do
        if value==current then return options[(i-1+direction)%#options+1] end
    end
    return options[1]
end

local function freshTeam()
    return {funds=CONFIG.START_FUNDS, levels={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, tier=0,
        counts={2,0,0,0,0}, weapons={1,1,1,1,1,1,1}, sidearms={}, medkits={}, grenades={}, armor={}, order="Rush", orderTarget=2, forward=0, auto=true, timer=Timer(), lastDeployCooldown=CONFIG.DEPLOY_COOLDOWN_MS, deaths=0, preset="Custom",        strikeTimer=Timer(), medicTimer=Timer(), coverTimer=Timer(), minesTimer=Timer(), bombTimer=Timer(), turretTimer=Timer(), orbitalTimer=Timer(), shieldTimer=Timer(), baseArmor=0, turretID=nil, turret=nil, stats={deployed=0,captures=0,earned=0,brainDamage=0,troopDamage=0}}
end

function Frontline:StartActivity()
    self.originalHudDisabled=FrameMan:IsHudDisabled(0)
    local ok,method=pcall(function() return PrimitiveMan.DrawScreenBoxFillPrimitive end)
    self.screenUI=ok and method~=nil
    self.teams = {[0]=freshTeam(), [1]=freshTeam()}
    if self.SetTeamFunds then for team=0,1 do self:SetTeamFunds(self.teams[team].funds,team) end end
    self.settings={startFunds=CONFIG.START_FUNDS,income=CONFIG.INCOME_PER_SECOND,unitCap=CONFIG.TEAM_UNIT_CAP,outpostBonuses=true,callins=true}
    self.teams[1].auto = true
    self.callinTarget=2
    self.orderAssignments={}
    self.miners={}
    self.deliveries={}
    self.frontlineCraft={}
    self.inTransit={}
    self.goldSites={}
    self.minerTimer=Timer()
    self.goldRescanTimer=Timer()
    self.researchPage=1
    self.rosterPage=1
    self.pendingStrikes={}
    self.pendingOrbitals={}
    self.pendingDrops={}
    self.jamFields={}
    self.supportSounds={
        strike=CreateSoundContainer("Frontline Precision Order","Frontline.rte"),
        precisionCannon=CreateSoundContainer("Frontline Precision Cannon","Frontline.rte"),
        bomb=CreateSoundContainer("Frontline Bomb Drop","Frontline.rte"),
        orbital=CreateSoundContainer("Frontline Gatling Order","Frontline.rte"),
        mines=CreateSoundContainer("Frontline Mines Order","Frontline.rte"),
        cover=CreateSoundContainer("Frontline Cover Order","Frontline.rte"),
    }
    for team=0,1 do
        self.teams[team].strikeTimer.ElapsedSimTimeMS=CONFIG.CALLIN_STRIKE_COOLDOWN_MS
        self.teams[team].medicTimer.ElapsedSimTimeMS=CONFIG.CALLIN_MEDIC_COOLDOWN_MS
        self.teams[team].coverTimer.ElapsedSimTimeMS=CONFIG.CALLIN_COVER_COOLDOWN_MS
        self.teams[team].minesTimer.ElapsedSimTimeMS=CONFIG.CALLIN_MINES_COOLDOWN_MS
        self.teams[team].bombTimer.ElapsedSimTimeMS=CONFIG.CALLIN_BOMB_COOLDOWN_MS
        self.teams[team].turretTimer.ElapsedSimTimeMS=CONFIG.CALLIN_TURRET_COOLDOWN_MS
        self.teams[team].orbitalTimer.ElapsedSimTimeMS=CONFIG.CALLIN_ORBITAL_COOLDOWN_MS
        self.teams[team].shieldTimer.ElapsedSimTimeMS=CONFIG.CALLIN_SHIELD_COOLDOWN_MS
    end
    self.matchTimer=Timer()
    self.battleStarted=false
    self.setupStep=1
    self.outposts={}
    self:ScanGoldSites()
    local postCount=SceneMan.SceneWidth>=15000 and 9 or (SceneMan.SceneWidth>=10000 and 5 or 3)
    local names=postCount==3 and {"WEST", "CENTER", "EAST"} or nil
    local bonuses={"Income +2/s", "Research -20%", "Call-ins -20%"}
    for i=1,postCount do
        local x=SceneMan.SceneWidth*i/(postCount+1)
        local ground=SceneMan:MovePointToGround(Vector(x,0),0,4)
        local kind=(i-1)%3+1
        self.outposts[i]={name=names and names[i] or ("POST "..i), bonus=bonuses[kind], kind=kind, owner=-1, progress=0, x=x, groundY=ground.Y}
    end
    -- Native bunker modules are destructible and have open entrances on both sides.
    for _,post in ipairs(self.outposts) do
        local structure=CreateTerrainObject("Tunnel A","Base.rte")
        if structure then
            structure.Pos=Vector(post.x,post.groundY-24)
            SceneMan:AddSceneObject(structure)
        end
    end
    self.noticeTimer=Timer()
    self.aiInterval=math.max(2000,6000-(self.Difficulty or 50)*40)
    self.tab="Setup"
    for team=0,1 do self.teams[team].timer.ElapsedSimTimeMS=math.max(CONFIG.DEPLOY_COOLDOWN_MS,CONFIG.FORWARD_DEPLOY_COOLDOWN_MS) end
    -- Record the ground before placing bunker modules, which can themselves
    -- be hit by a downward terrain probe.
    self.baseGround={}
    for team=0,1 do
        local baseX=team==0 and 180 or SceneMan.SceneWidth-180
        self.baseGround[team]=SceneMan:MovePointToGround(Vector(baseX,0),0,2).Y
    end
    -- Place mirrored, destructible bunker modules before spawning the brains.
    -- The vault's open end faces the battlefield and its floor meets the ground.
    for team=0,1 do
        local vault=team==0 and CreateTerrainObject("Frontline Mirrored Brain Vault", "Frontline.rte") or CreateTerrainObject("Brain Vault", "Base.rte")
        if vault then
            vault.Pos=Vector(team==0 and 180 or SceneMan.SceneWidth-180, self.baseGround[team]-31)
            vault.Team=team
            SceneMan:AddSceneObject(vault)
        end
    end
    -- Join a roofed approach directly to each vault, with a short end
    -- segment and matching roof details. The corridor stays open to troops.
    for team=0,1 do
        local sections={{distance=340,preset="Tunnel A"},{distance=436,preset="Tunnel A"},{distance=508,preset="Tunnel B"}}
        for _,section in ipairs(sections) do
            local corridor=CreateTerrainObject(section.preset,"Base.rte")
            if corridor then
                local x=team==0 and section.distance or SceneMan.SceneWidth-section.distance
                corridor.Pos=Vector(x,self.baseGround[team]-40)
                corridor.Team=team
                SceneMan:AddSceneObject(corridor)
            end
        end
        local upper=CreateTerrainObject("Tunnel A","Base.rte")
        if upper then
            local x=team==0 and CONFIG.BASE_TOWER_DISTANCE or SceneMan.SceneWidth-CONFIG.BASE_TOWER_DISTANCE
            upper.Pos=Vector(x,self.baseGround[team]-CONFIG.BASE_TOWER_HEIGHT)
            upper.Team=team
            SceneMan:AddSceneObject(upper)
        end
        for _,detail in ipairs({{distance=340,height=100},{distance=436,height=196},{distance=508,height=100}}) do
            local roof=CreateTerrainObject("Tut Roof Attachment","Base.rte")
            if roof then
                local x=team==0 and detail.distance-12 or SceneMan.SceneWidth-detail.distance-12
                roof.Pos=Vector(x,self.baseGround[team]-detail.height)
                roof.Team=team
                SceneMan:AddSceneObject(roof)
            end
        end
    end
    self.brains = {}
    for team=0,1 do
        local brain=CreateAHuman("Brain Robot", "Base.rte")
        brain.Team=team
        brain.Pos=Vector(team==0 and 180 or SceneMan.SceneWidth-180, self.baseGround[team]-30)
        brain.HFlipped=team==1
        local weapon=CreateHDFirearm("Gatling Gun","Coalition.rte")
        if weapon then brain:AddInventoryItem(weapon) end
        brain.AIMode=Actor.AIMODE_SENTRY
        MovableMan:AddActor(brain)
        self.brains[team]=brain
    end
    -- Space randomized cover between the bases, leaving their spawn lanes clear.
    -- Ground level is sampled from the scene so cover follows the rolling terrain.
    local cover={
        {preset="Zombie Cave Rock", yOffset=0},
        {preset="Zombie Cave Under Rock 1", yOffset=0},
        {preset="Zombie Cave Under Rock 2", yOffset=0},
        {preset="Concrete Barrier", yOffset=-22},
        {preset="Metal Crate Small A FG", yOffset=-22},
    }
    local x=650
    while x<SceneMan.SceneWidth-650 do
        local entry=cover[math.random(#cover)]
        local tooClose=false
        for _,post in ipairs(self.outposts) do
            if math.abs(post.x-x)<180 then tooClose=true; break end
        end
        local object=not tooClose and CreateTerrainObject(entry.preset,"Base.rte") or nil
        if object then
            local ground=SceneMan:MovePointToGround(Vector(x,0),0,2)
            object.Pos=ground+Vector(0,entry.yOffset)
            SceneMan:AddSceneObject(object)
        end
        x=x+math.random(220,360)
    end
    self.previousBrainHealth={[0]=self.brains[0].Health or 100,[1]=self.brains[1].Health or 100}
    self.previousTroopHealth={}
    self:SetPlayerBrain(self.brains[0], 0)
    self:SetViewState(Activity.OBSERVE, 0)
    self:SetObservationTarget(Vector(700,self.baseGround[0]-40),0)
    self.panel=true
    self.cursorX=200; self.cursorY=100
    self.message="Build a batch and click DEPLOY."
    self.aiTimer=Timer()
    MusicMan:PlayDynamicSong("Generic Battle Music")
end

-- Native gold-dig mode digs blindly when it cannot see ore. Scan actual
-- terrain for deposits and only use that mode when a miner is beside one.
function Frontline:GoldAtColumn(x)
    local hit=Vector(0,0)
    if SceneMan:CastMaterialRay(Vector(x,0),Vector(0,SceneMan.SceneHeight-1),rte.goldID,hit,2,false) then return hit end
    return nil
end

function Frontline:ScanGoldSites()
    self.goldSites={}
    local previous
    for x=12,SceneMan.SceneWidth-12,CONFIG.MINER_GOLD_SCAN_STEP do
        local hit=self:GoldAtColumn(x)
        if hit then
            if previous and x-previous.lastX<=CONFIG.MINER_GOLD_SCAN_STEP and math.abs(hit.Y-previous.y)<80 then
                table.insert(previous.columns,x)
                previous.lastX=x
            else
                previous={columns={x},lastX=x,y=hit.Y}
                table.insert(self.goldSites,previous)
            end
        end
    end
end

function Frontline:GoldAtSite(site,nearX)
    local best,bestDistance
    for _,x in ipairs(site.columns) do
        local hit=self:GoldAtColumn(x)
        if hit then
            local distance=math.abs(x-nearX)
            if not bestDistance or distance<bestDistance then best,bestDistance=hit,distance end
        end
    end
    return best
end

function Frontline:UpdateMiner(actor,state)
    local previousSite=state.site
    local target=state.site and self:GoldAtSite(state.site,actor.Pos.X) or nil
    if not target then
        local best,bestDistance
        for _,site in ipairs(self.goldSites) do
            local hit=self:GoldAtSite(site,actor.Pos.X)
            if hit then
                local distance=math.abs(hit.X-actor.Pos.X)+math.abs(hit.Y-actor.Pos.Y)*0.2
                if not bestDistance or distance<bestDistance then best,bestDistance=site,distance; target=hit end
            end
        end
        state.site=best
    end
    if not target then
        if state.mode~="idle" then actor:ClearAIWaypoints(); actor.AIMode=Actor.AIMODE_SENTRY end
        state.mode="idle"
    elseif math.abs(actor.Pos.X-target.X)<=CONFIG.MINER_DIG_DISTANCE and math.abs(actor.Pos.Y-target.Y)<=120 then
        if state.mode~="dig" then actor:ClearAIWaypoints(); actor.AIMode=Actor.AIMODE_GOLDDIG end
        state.mode="dig"
    elseif state.mode~="travel" or actor.AIMode~=Actor.AIMODE_GOTO or state.site~=previousSite then
        actor:ClearAIWaypoints()
        actor.AIMode=Actor.AIMODE_GOTO
        actor:AddAISceneWaypoint(Vector(target.X,math.max(0,target.Y-55)))
        state.mode="travel"
    end
end

function Frontline:UpdateMiners()
    if not next(self.miners) then return end
    -- Drop exhausted sites once for all miners. Re-scan occasionally if loose
    -- gold later settles back into the terrain.
    for i=#self.goldSites,1,-1 do
        local site=self.goldSites[i]
        if not self:GoldAtSite(site,site.columns[1]) then table.remove(self.goldSites,i) end
    end
    if #self.goldSites==0 and self.goldRescanTimer:IsPastSimMS(CONFIG.MINER_RESCAN_INTERVAL_MS) then
        self.goldRescanTimer:Reset()
        self:ScanGoldSites()
    end
    local present={}
    for actor in MovableMan.Actors do
        local state=self.miners[actor.UniqueID]
        if state then
            present[actor.UniqueID]=true
            if actor.Health>0 then self:UpdateMiner(actor,state) end
        end
    end
    for id in pairs(self.miners) do if not present[id] then self.miners[id]=nil end end
end

-- Stationary base defenses do not consume the field army cap or receive orders.
function Frontline:IsFieldUnit(actor)
    local team=actor.Team
    return (team==0 or team==1) and actor.UniqueID~=self.brains[team].UniqueID
        and actor.UniqueID~=self.teams[team].turretID and (IsAHuman(actor) or IsACrab(actor))
end

function Frontline:BaseUpgrade(team,kind)
    local t=self.teams[team]
    local brain=self.brains[team]
    if not self.battleStarted then return false,"Complete match setup first" end
    if not MovableMan:IsActor(brain) or brain.Health<=0 then return false,"Brain is unavailable" end
    local cost
    if kind=="armor" then
        if t.baseArmor>=CONFIG.BASE_ARMOR_LEVELS then return false,"Armor fully upgraded" end
        cost=CONFIG.BASE_ARMOR_COST*(t.baseArmor+1)
        if t.funds<cost then return false,"Not enough funds" end
        brain.MaxHealth=brain.MaxHealth+CONFIG.BASE_ARMOR_HEALTH
        brain.Health=brain.Health+CONFIG.BASE_ARMOR_HEALTH
        t.baseArmor=t.baseArmor+1
    elseif kind=="repair" then
        if brain.Health>=brain.MaxHealth then return false,"Brain already at full health" end
        cost=CONFIG.BASE_REPAIR_COST
        if t.funds<cost then return false,"Not enough funds" end
        brain.Health=math.min(brain.MaxHealth,brain.Health+CONFIG.BASE_REPAIR_HEALTH)
    elseif kind=="turret" then
        if t.turret and MovableMan:IsActor(t.turret) then return false,"Base turret already active" end
        cost=CONFIG.BASE_TURRET_COST
        if t.funds<cost then return false,"Not enough funds" end
        local turret=CreateACrab("Gatling Turret","Coalition.rte")
        if not turret then return false,"Turret preset unavailable" end
        turret.Team=team
        -- The tunnel's floor begins 24 pixels below its center; the turret
        -- mount extends 9 pixels below its origin, so it rests on that floor.
        local x=team==0 and CONFIG.BASE_TOWER_DISTANCE or SceneMan.SceneWidth-CONFIG.BASE_TOWER_DISTANCE
        turret.Pos=Vector(x,self.baseGround[team]-CONFIG.BASE_TURRET_HEIGHT)
        turret.HFlipped=team==1
        turret.AIMode=Actor.AIMODE_SENTRY
        turret.PinStrength=100000
        t.turretID=turret.UniqueID
        t.turret=turret
        MovableMan:AddActor(turret)
    else
        return false,"Unknown base upgrade"
    end
    t.funds=t.funds-cost
    if team==0 then self:Notify("Base "..kind.." purchased") end
    return true,"Base upgrade purchased"
end

function Frontline:UnitCount(team)
    local count,active=0,{}
    for actor in MovableMan.Actors do
        if actor.Team==team and self:IsFieldUnit(actor) then
            count=count+1
            active[actor.UniqueID]=true
        end
    end
    -- Reserve each passenger's slot until they appear in the world or their
    -- destroyed craft's survivor grace expires; never count both at once.
    for id,passenger in pairs(self.inTransit) do
        if passenger.team==team and not active[id] then count=count+1 end
    end
    return count
end

-- Reapply current orders after a passenger leaves its ship. A short grace
-- period after a destroyed craft lets any ejected survivors enter the scene.
function Frontline:UpdateDeliveries()
    for actor in MovableMan.Actors do
        local passenger=self.inTransit[actor.UniqueID]
        if passenger then
            self.inTransit[actor.UniqueID]=nil
            actor.Perceptiveness=math.min(1,0.5+0.05*(self.teams[passenger.team].levels[10] or 0))
            if passenger.miner then
                self.miners[actor.UniqueID]={}
                self:UpdateMiner(actor,self.miners[actor.UniqueID])
            else
                self:AssignOrder(actor,passenger.team)
            end
        end
    end
    for i=#self.deliveries,1,-1 do
        local delivery=self.deliveries[i]
        if not MovableMan:IsActor(delivery.ship) then
            if not delivery.lostTimer then delivery.lostTimer=Timer()
            elseif delivery.lostTimer:IsPastSimMS(2000) then
                for _,id in ipairs(delivery.passengers) do self.inTransit[id]=nil end
                table.remove(self.deliveries,i)
            end
        end
    end
end

local function weaponUnlocked(t,weapon)
    return weapon.unlock<=t.tier and (not weapon.research or t.levels[weapon.research]>0)
end

function Frontline:Batch(team)
    local t=self.teams[team]
    local cost, count=0,0
    for i,entry in ipairs(CONFIG.roster) do
        local n=t.counts[i] or 0
        local weapon=CONFIG.weapons[t.weapons[i] or 6]
        if n>0 and not entry.vehicle and not entry.miner and not weaponUnlocked(t,weapon) then return nil,nil,"Weapon is locked" end
        if n>0 and (entry.unlock>t.tier or (entry.research and (t.levels[entry.research] or 0)==0)) then return nil,nil,"Unit is locked" end
        count=count+n
        if n>0 and t.armor[i] and (t.levels[16] or 0)==0 then return nil,nil,"Unit armor is locked" end
        local extra=t.armor[i] and CONFIG.UNIT_ARMOR_COST or 0
        if not entry.vehicle and not entry.miner then
            local sidearm=t.sidearms[i] or 0
            if n>0 and sidearm>0 and (t.levels[15] or 0)==0 then return nil,nil,"Sidearms are locked" end
            if n>0 and sidearm==2 and (t.levels[7] or 0)==0 then return nil,nil,"Rocket sidearm is locked" end
            if n>0 and t.medkits[i] and (t.levels[13] or 0)==0 then return nil,nil,"Medikits are locked" end
            if n>0 and t.grenades[i] and (t.levels[14] or 0)==0 then return nil,nil,"Grenades are locked" end
            extra=extra+(sidearm==1 and 10 or (sidearm==2 and 95 or 0))+(t.medkits[i] and 45 or 0)+(t.grenades[i] and 45 or 0)
        end
        cost=cost+n*(entry.price+(entry.vehicle and 0 or (entry.miner and 25 or weapon.price))+extra+(t.forward>0 and 25 or 0))
    end
    return cost,count
end

-- Apply the chosen order to a unit; Advance resumes its attack after reaching
-- the post, while Defend becomes a sentry on arrival.
function Frontline:AssignOrder(actor,team)
    local t=self.teams[team]
    if self.miners[actor.UniqueID] then return end
    actor:ClearAIWaypoints()
    self.orderAssignments[actor.UniqueID]=nil
    if t.order=="Rush" then
        actor.AIMode=Actor.AIMODE_BRAINHUNT
    else
        local target=self.outposts[t.orderTarget]
        actor.AIMode=Actor.AIMODE_GOTO
        local spread=(actor.UniqueID%7-3)*20
        actor:AddAISceneWaypoint(Vector(target.x+spread,target.groundY-20))
        self.orderAssignments[actor.UniqueID]={order=t.order,target=t.orderTarget}
    end
end

function Frontline:ApplyTeamOrder(team)
    for actor in MovableMan.Actors do
        if actor.Team==team and self:IsFieldUnit(actor) then
            self:AssignOrder(actor,team)
        end
    end
    if team==0 then self:Notify("Order: "..self.teams[team].order.." "..self.outposts[self.teams[team].orderTarget].name) end
end

function Frontline:UpdateOrders()
    local alive={}
    for actor in MovableMan.Actors do
        local assignment=self.orderAssignments[actor.UniqueID]
        if assignment then
            alive[actor.UniqueID]=true
            local target=self.outposts[assignment.target]
            if math.abs(actor.Pos.X-target.x)<90 and math.abs(actor.Pos.Y-target.groundY)<120 then
                if assignment.order=="Advance" and target.owner~=actor.Team then
                    -- Stay in the capture zone until it is secured.
                    actor.AIMode=Actor.AIMODE_SENTRY
                else
                    actor:ClearAIWaypoints()
                    actor.AIMode=assignment.order=="Defend" and Actor.AIMODE_SENTRY or Actor.AIMODE_BRAINHUNT
                    self.orderAssignments[actor.UniqueID]=nil
                end
            end
        end
    end
    for id in pairs(self.orderAssignments) do if not alive[id] then self.orderAssignments[id]=nil end end
end

-- The last deployment and the selected destination both constrain the next
-- batch, so switching destinations cannot shorten an active cooldown.
function Frontline:DeployCooldown(team)
    local t=self.teams[team]
    local destination=t.forward>0 and CONFIG.FORWARD_DEPLOY_COOLDOWN_MS or CONFIG.DEPLOY_COOLDOWN_MS
    return math.max(t.lastDeployCooldown or CONFIG.DEPLOY_COOLDOWN_MS,destination)
end

function Frontline:Deploy(team)
    local t=self.teams[team]
    local cost,count,err=self:Batch(team)
    if not cost then return false,err end
    if count==0 then return false,"Select at least one unit" end
    if not self.battleStarted then return false,"Complete match setup first" end
    if t.forward>0 and self.outposts[t.forward].owner~=team then return false,"Forward outpost is not yours" end
    if not self.matchTimer:IsPastSimMS(CONFIG.GRACE_MS) then return false,"Opening grace period" end
    if not t.timer:IsPastSimMS(self:DeployCooldown(team)) then return false,"Deployment cooling down" end
    if t.funds<cost then return false,"Not enough funds" end
    if self:UnitCount(team)+count>self.settings.unitCap then return false,"Team unit cap reached" end
    -- Construct the complete batch before charging or adding anything to the world.
    local actors={}
    for i,entry in ipairs(CONFIG.roster) do
        for n=1,(t.counts[i] or 0) do
            local actor=entry.vehicle and CreateACrab(entry.actor,entry.mod) or CreateAHuman(entry.actor,entry.mod)
            local weapon=CONFIG.weapons[t.weapons[i] or 6]
            local gun=not entry.vehicle and CreateHDFirearm(entry.miner and "Pistol" or weapon.preset,entry.miner and "Base.rte" or weapon.mod) or nil
            local digger=entry.miner and CreateHDFirearm("Light Digger","Base.rte") or nil
            if not actor or (not entry.vehicle and not gun) or (entry.miner and not digger) then return false,"Missing unit or equipment preset" end
            if gun then actor:AddInventoryItem(gun) end
            if digger then actor:AddInventoryItem(digger) end
            if not entry.vehicle and not entry.miner then
                local sidearm=t.sidearms[i] or 0
                if sidearm>0 then
                    local side=CreateHDFirearm(sidearm==1 and "Pistol" or "Missile Launcher",sidearm==1 and "Base.rte" or "Coalition.rte")
                    if not side then return false,"Sidearm preset unavailable" end
                    actor:AddInventoryItem(side)
                end
                for n=1,3 do
                    if t.medkits[i] then local item=CreateHDFirearm("Medikit","Base.rte"); if not item then return false,"Medikit preset unavailable" end; actor:AddInventoryItem(item) end
                    if t.grenades[i] then local item=CreateTDExplosive("Frag Grenade","Base.rte"); if not item then return false,"Grenade preset unavailable" end; actor:AddInventoryItem(item) end
                end
            end
            actor.Team=team
            if t.armor[i] then
                actor.MaxHealth=actor.MaxHealth+CONFIG.UNIT_ARMOR_HEALTH
                actor.Health=actor.Health+CONFIG.UNIT_ARMOR_HEALTH
            end
            actor.Perceptiveness=math.min(1,0.5+0.05*(t.levels[10] or 0))
            actor.HFlipped=team==1
            table.insert(actors,{actor=actor,miner=entry.miner==true})
        end
    end
    if t.forward>0 then
        -- Construct every ship before committing the purchase. Split loads by
        -- both passenger count and inventory mass so vanilla craft can fly.
        local ships={}
        for _,passenger in ipairs(actors) do
            local group=ships[#ships]
            local mass=passenger.actor.Mass or 0
            if not group or #group.passengers>=group.capacity or (group.maxMass>=0 and group.mass+mass>group.maxMass) then
                local ship=CreateACDropShip("Dropship MK1","Base.rte")
                if not ship then return false,"Dropship preset unavailable" end
                group={ship=ship,passengers={},mass=0,maxMass=ship.MaxInventoryMass,
                    capacity=math.max(1,math.min(CONFIG.FORWARD_SHIP_PASSENGERS,ship.MaxPassengers))}
                table.insert(ships,group)
            end
            if group.maxMass>=0 and mass>group.maxMass then return false,"Unit too heavy for dropship" end
            table.insert(group.passengers,passenger)
            group.mass=group.mass+mass
        end
        local post=self.outposts[t.forward]
        for index,group in ipairs(ships) do
            local ship=group.ship
            local direction=team==0 and -1 or 1
            local x=math.max(120,math.min(SceneMan.SceneWidth-120,post.x+direction*(CONFIG.FORWARD_LANDING_OFFSET+(index-1)*CONFIG.FORWARD_SHIP_SEPARATION)))
            ship.Team=team
            ship:SetGoldValue(0)
            self.frontlineCraft[ship.UniqueID]=true
            ship.Pos=Vector(x,math.max(-50,post.groundY-CONFIG.FORWARD_DROP_HEIGHT))
            ship.AIMode=Actor.AIMODE_DELIVER
            ship:SetControllerMode(Controller.CIM_AI,-1)
            local delivery={ship=ship,team=team,passengers={}}
            for _,passenger in ipairs(group.passengers) do
                local actor=passenger.actor
                local id=actor.UniqueID
                self.inTransit[id]={team=team,miner=passenger.miner}
                table.insert(delivery.passengers,id)
                actor.AIMode=passenger.miner and Actor.AIMODE_SENTRY or Actor.AIMODE_BRAINHUNT
                ship:AddInventoryItem(actor)
            end
            MovableMan:AddActor(ship)
            table.insert(self.deliveries,delivery)
        end
    else
        for i,passenger in ipairs(actors) do
            local actor=passenger.actor
            local slot=(t.stats.deployed+i-1)%6
            local x=(team==0 and 200 or SceneMan.SceneWidth-200)+(team==0 and 1 or -1)*(slot*18)
            actor.Pos=Vector(x,self.baseGround[team]-35)
            if passenger.miner then
                self.miners[actor.UniqueID]={}
                actor.AIMode=Actor.AIMODE_SENTRY
            else self:AssignOrder(actor,team) end
            MovableMan:AddActor(actor)
            if passenger.miner then self:UpdateMiner(actor,self.miners[actor.UniqueID]) end
        end
    end
    t.funds=t.funds-cost
    t.stats.deployed=t.stats.deployed+count
    t.lastDeployCooldown=t.forward>0 and CONFIG.FORWARD_DEPLOY_COOLDOWN_MS or CONFIG.DEPLOY_COOLDOWN_MS
    t.timer:Reset()
    if team==0 then self:Notify(t.forward>0 and ("Dropship incoming: "..count.." units") or ("Squad deployed: "..count.." units")) end
    return true,"Batch deployed"
end

function Frontline:PostBonusCount(team,kind)
    local count=0
    if self.settings.outpostBonuses then
        for _,post in ipairs(self.outposts) do
            if post.owner==team and post.kind==kind then count=count+1 end
        end
    end
    return count
end

function Frontline:ResearchCost(team,index)
    local t=self.teams[team]
    local price=CONFIG.research[index].price*((t.levels[index] or 0)+1)
    return self:PostBonusCount(team,2)>0 and math.ceil(price*0.8) or price
end

function Frontline:TeamIncome(team)
    return self.settings.income+2*self.teams[team].levels[1]+self:PostBonusCount(team,1)*CONFIG.OUTPOST_INCOME
end

function Frontline:CallinCooldown(team,base)
    return self:PostBonusCount(team,3)>0 and math.ceil(base*0.8) or base
end

function Frontline:Research(team,index)
    local t=self.teams[team]
    local r=CONFIG.research[index]
    if (t.levels[index] or 0)>=r.max then return false,"Already researched" end
    if r.kind=="tier" and r.tier>1 and t.tier<r.tier-1 then return false,"Research the previous tier first" end
    if r.requires and t.tier<r.requires then return false,"Requires earlier infantry or faction research" end
    local price=self:ResearchCost(team,index)
    if t.funds<price then return false,"Not enough funds" end
    t.funds=t.funds-price
    t.levels[index]=(t.levels[index] or 0)+1
    if r.kind=="tier" then t.tier=r.tier end
    if r.kind=="training" then
        for actor in MovableMan.Actors do
            if actor.Team==team and self:IsFieldUnit(actor) then actor.Perceptiveness=math.min(1,0.5+0.05*t.levels[index]) end
        end
    end
    if team==0 then self:Notify("Research complete: "..r.name) end
    return true,"Research complete"
end

function Frontline:Notify(message)
    self.message=message
    self.noticeTimer:Reset()
end

-- Capture advances only for an uncontested team in the zone. Ownership changes
-- after the opposing team has crossed the full capture bar.
function Frontline:OutpostCount(team)
    local count=0
    for _,outpost in ipairs(self.outposts) do
        if outpost.owner==team then count=count+1 end
    end
    return count
end

function Frontline:UpdateOutpost(dt)
    local present={}
    for i=1,#self.outposts do present[i]={[0]=false,[1]=false} end
    for actor in MovableMan.Actors do
        if self:IsFieldUnit(actor) then
            for i,outpost in ipairs(self.outposts) do
                if math.abs(actor.Pos.X-outpost.x)<=CONFIG.OUTPOST_RADIUS then
                    present[i][actor.Team]=true
                end
            end
        end
    end
    for i,outpost in ipairs(self.outposts) do
        if present[i][0] ~= present[i][1] then
            local direction=present[i][0] and 1 or -1
            outpost.progress=math.max(-1,math.min(1,outpost.progress+direction*dt/CONFIG.OUTPOST_CAPTURE_SECONDS))
            local newOwner=outpost.progress>=1 and 0 or (outpost.progress<=-1 and 1 or outpost.owner)
            if newOwner~=outpost.owner then
                outpost.owner=newOwner
                self.teams[newOwner].stats.captures=self.teams[newOwner].stats.captures+1
                self:Notify(newOwner==0 and (outpost.name.." captured: "..outpost.bonus) or ("Enemy captured "..outpost.name.." outpost!"))
            end
        end
    end
end

function Frontline:SetPreset(team,choice)
    local t=self.teams[team]
    local basic=(t.levels[12] or 0)>0 and 1 or 6
    if choice=="Rush" then t.counts={4,0,0,0}; t.weapons={basic,basic,basic,basic}
    elseif choice=="Assault" then
        t.counts=t.tier>=1 and {1,2,0,0} or {3,0,0,0}
        t.weapons=t.tier>=1 and {basic,2,basic,basic} or {basic,basic,basic,basic}
    elseif choice=="Specialist" then
        t.counts=t.tier>=2 and {1,1,1,0} or (t.tier>=1 and {2,1,0,0} or {2,0,0,0})
        t.weapons={t.levels[6]>0 and 4 or basic,t.levels[7]>0 and 5 or (t.tier>=1 and 2 or basic),t.tier>=2 and 3 or basic,basic}
    end
    t.preset=choice
end

function Frontline:SaveSquad(team)
    local t=self.teams[team]
    t.savedSquad={counts={},weapons={},sidearms={},medkits={},grenades={},armor={}}
    for i=1,#CONFIG.roster do
        t.savedSquad.counts[i]=t.counts[i] or 0
        t.savedSquad.weapons[i]=t.weapons[i] or 6
        t.savedSquad.sidearms[i]=t.sidearms[i]; t.savedSquad.medkits[i]=t.medkits[i]; t.savedSquad.grenades[i]=t.grenades[i]; t.savedSquad.armor[i]=t.armor[i]
    end
    if team==0 then self:Notify("Custom squad saved for this match") end
end

function Frontline:LoadSquad(team)
    local t=self.teams[team]
    if not t.savedSquad then
        if team==0 then self:Notify("No custom squad saved yet") end
        return false
    end
    for i=1,#CONFIG.roster do
        t.counts[i]=t.savedSquad.counts[i]
        t.weapons[i]=t.savedSquad.weapons[i]
        t.sidearms[i]=t.savedSquad.sidearms[i]; t.medkits[i]=t.savedSquad.medkits[i]; t.grenades[i]=t.savedSquad.grenades[i]; t.armor[i]=t.savedSquad.armor[i]
    end
    t.preset="Saved"
    if team==0 then self:Notify("Custom squad loaded") end
    return true
end

function Frontline:AutoReason(team)
    local t=self.teams[team]
    local cost,count,err=self:Batch(team)
    if not cost then return err end
    if count==0 then return "Empty batch" end
    if not self.battleStarted then return "Match setup" end
    if not self.matchTimer:IsPastSimMS(CONFIG.GRACE_MS) then return "Grace "..math.max(0,math.ceil((CONFIG.GRACE_MS-self.matchTimer.ElapsedSimTimeMS)/1000)).."s" end
    if t.forward>0 and self.outposts[t.forward].owner~=team then return "Forward post lost" end
    local cooldown=self:DeployCooldown(team)
    if not t.timer:IsPastSimMS(cooldown) then return "Cooldown "..math.max(0,math.ceil((cooldown-t.timer.ElapsedSimTimeMS)/1000)).."s" end
    if t.funds<cost then return "Need "..math.ceil(cost-t.funds).." oz" end
    if self:UnitCount(team)+count>self.settings.unitCap then return "Unit cap" end
    return "Ready"
end

-- Support cannot be targeted near the opposing starting bunker. This checks
-- both teams and every call-in before charging funds or starting cooldowns.
function Frontline:SupportTargetAllowed(team,x)
    local enemyBaseX=team==0 and SceneMan.SceneWidth-180 or 180
    return math.abs(x-enemyBaseX)>CONFIG.ENEMY_BASE_SUPPORT_EXCLUSION_RADIUS
end

-- Jammers belong to the deploying team and prevent hostile support orders
-- within their horizontal radius. Friendly support is unaffected.
function Frontline:ShieldBlocks(target,attacker)
    for _,field in ipairs(self.jamFields) do
        if math.abs(field.x-target.x)<=CONFIG.CALLIN_JAM_RADIUS and field.team~=attacker and not field.timer:IsPastSimMS(CONFIG.CALLIN_SHIELD_DURATION_MS) then return true end
    end
    return false
end

-- The outline shows the support-jamming area, not a physical shield.
function Frontline:DrawShieldField(target,team)
    local color=team==0 and 215 or 13
    local previousX,previousY
    for i=0,24 do
        local angle=math.pi*i/24
        local x=target.x+math.cos(angle)*CONFIG.CALLIN_JAM_RADIUS
        local y=target.groundY-12-math.sin(angle)*130
        if previousX then
            PrimitiveMan:DrawLinePrimitive(Vector(previousX,previousY),Vector(x,y),color)
            PrimitiveMan:DrawLinePrimitive(Vector(previousX,previousY-1),Vector(x,y-1),color)
        end
        previousX,previousY=x,y
    end
end

function Frontline:BeginTargeting(kind)
    self.targeting=kind
    self.panel=false
    self.panelCameraOffset=nil
    self:Notify("Move cursor to target; click to confirm, Tab to cancel")
end

function Frontline:UpdateTargeting()
    local offset=CameraMan:GetOffset(0)
    local move=UInputMan:GetMouseMovement(0)
    self.cursorX=math.max(8,math.min(FrameMan.PlayerScreenWidth-8,self.cursorX+move.X))
    self.cursorY=math.max(8,math.min(FrameMan.PlayerScreenHeight-8,self.cursorY+move.Y))
    local x=math.max(30,math.min(SceneMan.SceneWidth-30,offset.X+self.cursorX))
    local ground=SceneMan:MovePointToGround(Vector(x,0),0,4)
    local label="TARGET: "..string.upper(self.targeting).." (CLICK)"
    local allowed=self:SupportTargetAllowed(0,x)
    if self.targeting=="shield" and allowed then
        self:DrawShieldField({x=x,groundY=ground.Y},0)
        label="PLACE SUPPORT JAMMER (CLICK)"
    end
    if not allowed then label="ENEMY BASE: SUPPORT RESTRICTED" end
    local targetColor=allowed and 120 or 13
    PrimitiveMan:DrawLinePrimitive(Vector(x-15,ground.Y-45),Vector(x+15,ground.Y-45),targetColor)
    PrimitiveMan:DrawLinePrimitive(Vector(x,ground.Y-60),Vector(x,ground.Y-30),targetColor)
    PrimitiveMan:DrawTextPrimitive(Vector(x,ground.Y-70),label,true,1)
    if UInputMan:KeyPressed(Key.TAB) then self.targeting=nil; self.panel=true; return end
    if UInputMan:MouseButtonPressed(MouseButtons.MOUSE_LEFT) then
        local target={name="target area",x=x,groundY=ground.Y,owner=-1}
        local ok,msg=self:CallIn(0,self.targeting,target)
        -- Leave the battlefield visible after confirming, including when the
        -- order fails; the compact HUD shows the result and Tab reopens us.
        self.targeting=nil; self.panel=false
        if not ok then self:Notify(msg) end
    end
end

-- Create a fresh craft immediately before it enters the scene. Craft timers
-- run even while an object is waiting off-map, and stale timers can scuttle it.
function Frontline:CreateSupportShip(team,kind,count,x,startY)
    local ship=CreateACDropShip("Dropship MK1","Base.rte")
    if not ship then return nil end
    local payload={}
    for i=1,count do
        local item
        if kind=="bomb" then item=CreateTDExplosive("Frontline Heavy Bomb","Frontline.rte")
        elseif kind=="turret" then item=CreateACrab("Gatling Turret","Coalition.rte")
        elseif kind=="mines" then item=CreateMOSRotating("Anti Personnel Mine Active","Base.rte")
        else item=CreateMOSRotating("Frontline Cover Pod","Frontline.rte") end
        if not item then return nil end
        item.Team=team
        if kind=="mines" then item.Sharpness=team end
        table.insert(payload,item)
    end
    ship.Team=team
    ship:SetGoldValue(0)
    ship.Pos=Vector(x,startY)
    ship.PinStrength=1000000
    ship.CanEnterOrbit=false
    ship.AIMode=Actor.AIMODE_SENTRY
    ship:SetControllerMode(Controller.CIM_DISABLED,-1)
    for _,item in ipairs(payload) do ship:AddInventoryItem(item) end
    return ship
end

function Frontline:CallIn(team,kind,index)
    local t=self.teams[team]
    local outpost=type(index)=="table" and index or self.outposts[index]
    if not outpost then return false,"Choose a valid target" end
    if not self.battleStarted then return false,"Complete match setup first" end
    if not self.settings.callins then return false,"Call-ins disabled in setup" end
    if not self.matchTimer:IsPastSimMS(CONFIG.GRACE_MS) then return false,"Call-ins unavailable during grace" end
    local options={
        strike={timer=t.strikeTimer,cooldown=CONFIG.CALLIN_STRIKE_COOLDOWN_MS,cost=CONFIG.CALLIN_STRIKE_COST},
        medic={timer=t.medicTimer,cooldown=CONFIG.CALLIN_MEDIC_COOLDOWN_MS,cost=CONFIG.CALLIN_MEDIC_COST},
        cover={timer=t.coverTimer,cooldown=CONFIG.CALLIN_COVER_COOLDOWN_MS,cost=CONFIG.CALLIN_COVER_COST},
        mines={timer=t.minesTimer,cooldown=CONFIG.CALLIN_MINES_COOLDOWN_MS,cost=CONFIG.CALLIN_MINES_COST},
        bomb={timer=t.bombTimer,cooldown=CONFIG.CALLIN_BOMB_COOLDOWN_MS,cost=CONFIG.CALLIN_BOMB_COST},
        turret={timer=t.turretTimer,cooldown=CONFIG.CALLIN_TURRET_COOLDOWN_MS,cost=CONFIG.CALLIN_TURRET_COST},
        orbital={timer=t.orbitalTimer,cooldown=CONFIG.CALLIN_ORBITAL_COOLDOWN_MS,cost=CONFIG.CALLIN_ORBITAL_COST},
        shield={timer=t.shieldTimer,cooldown=CONFIG.CALLIN_SHIELD_COOLDOWN_MS,cost=CONFIG.CALLIN_SHIELD_COST},
    }
    local option=options[kind]
    if not option then return false,"Unknown call-in" end
    if not self:SupportTargetAllowed(team,outpost.x) then return false,"Support restricted near enemy base" end
    if self:ShieldBlocks(outpost,team) then return false,"Enemy jammer blocks support here" end
    local timer,cooldown,cost=option.timer,self:CallinCooldown(team,option.cooldown),option.cost
    if not timer:IsPastSimMS(cooldown) then return false,"Call-in cooling down" end
    if t.funds<cost then return false,"Not enough funds" end
    if kind=="strike" then
        table.insert(self.pendingStrikes,{team=team,index=type(index)=="number" and index or nil,target=outpost,timer=Timer(),projectileTimer=nil})
        self:Notify((team==0 and "Your" or "Enemy").." precision strike inbound at "..outpost.name.."! Friendly fire!")
    elseif kind=="shield" then
        table.insert(self.jamFields,{x=outpost.x,groundY=outpost.groundY,team=team,timer=Timer()})
        self:Notify((team==0 and "Your" or "Enemy").." support jammer active for 20s")
    elseif kind=="orbital" then
        local probe=CreateMOPixel("Frontline Orbital Round","Frontline.rte")
        if not probe then return false,"Orbital ammunition unavailable" end
        table.insert(self.pendingOrbitals,{team=team,index=type(index)=="number" and index or nil,target=outpost,timer=Timer(),shots=0,total=CONFIG.CALLIN_ORBITAL_SHOTS+(t.levels[9]>0 and CONFIG.CALLIN_ORBITAL_BONUS_SHOTS or 0),sound=CreateSoundContainer("Frontline Orbital Gatling", "Frontline.rte")})
        self:Notify((team==0 and "Your" or "Enemy").." orbital Gatling cannon targeting "..outpost.name.."! Fragmentation; friendly fire!")
    elseif kind=="bomb" then
        -- Scripted bomb run: dropship flies horizontally, drops 3 bombs at intervals.
        local ship = CreateACDropShip("Dropship MK1","Base.rte")
        if not ship then return false, "Bomb dropship unavailable" end
        ship.Team = team
        ship:SetGoldValue(0)
        -- Start off to the left of target at high altitude
        ship.Pos = Vector(outpost.x - 600, math.max(50, outpost.groundY - 400))
        ship.AIMode = Actor.AIMODE_SENTRY
        ship:SetControllerMode(Controller.CIM_DISABLED,-1)
        MovableMan:AddActor(ship)
        table.insert(self.pendingDrops, {team=team, kind="bomb", target=outpost, ship=ship, timer=Timer(), arrivalTimer=Timer(), delay=0, cost=cost, bombsDropped=0, totalBombs=3, flightDistance=1200, startX=outpost.x-600})
        self:Notify((team==0 and "Your" or "Enemy").." bomb run inbound (3 bombs)! Friendly fire!")
    elseif kind=="turret" then
        -- Static turret dropped at target location.
        local ship = self:CreateSupportShip(team, "turret", 1, outpost.x, math.max(50, outpost.groundY-650))
        if not ship then return false, "Turret dropship unavailable" end
        table.insert(self.pendingDrops, {team=team, kind="turret", target=outpost, ship=ship, timer=Timer(), delay=CONFIG.CALLIN_TURRET_DELAY_MS, cost=cost})
        self:Notify((team==0 and "Your" or "Enemy").." turret dropship inbound (4s)!")
    elseif kind=="mines" or kind=="cover" then
        local count = 3 + (t.levels[8]>0 and 2 or 0)
        local startY = math.max(50, outpost.groundY-650)
        local releaseY = math.max(startY, outpost.groundY-350)
        local delay = kind=="mines" and CONFIG.CALLIN_MINES_DELAY_MS or CONFIG.CALLIN_COVER_DELAY_MS
        if not self:CreateSupportShip(team, kind, count, outpost.x, startY) then return false, "Support delivery preset unavailable" end
        table.insert(self.pendingDrops, {team=team, kind=kind, target=outpost, timer=Timer(), delay=delay,
            startY=startY, releaseY=releaseY, count=count, cost=cost})
        self:Notify((team==0 and "Your" or "Enemy").." "..kind.." dropship inbound ("..math.ceil(delay/1000).."s)!")
    else
        local wounded={}
        for actor in MovableMan.Actors do
            if actor.Team==team and self:IsFieldUnit(actor)
                and math.abs(actor.Pos.X-outpost.x)<=CONFIG.OUTPOST_RADIUS and actor.Health>0 and actor.Health<actor.MaxHealth then
                table.insert(wounded,actor)
            end
        end
        if #wounded==0 then return false,"No wounded allies near target" end
        for _,actor in ipairs(wounded) do actor.Health=math.min(actor.MaxHealth,actor.Health+CONFIG.CALLIN_HEAL) end
        self:Notify((team==0 and "Your" or "Enemy").." medics treated "..#wounded.." at "..outpost.name)
    end
    t.funds=t.funds-cost
    timer:Reset()
    local cue=self.supportSounds[kind]
    if cue then cue:Play() end
    return true,"Call-in ordered"
end

-- Mark ordered attacks on the battlefield so the target and remaining time
-- remain visible after the command panel closes.
function Frontline:DrawCallInMarker(target,team,label)
    local x,y=target.x,target.groundY
    local color=team==0 and 120 or 13
    PrimitiveMan:DrawLinePrimitive(Vector(x-15,y-45),Vector(x+15,y-45),color)
    PrimitiveMan:DrawLinePrimitive(Vector(x,y-60),Vector(x,y-30),color)
    PrimitiveMan:DrawTextPrimitive(Vector(x,y-75),label,true,1)
end

function Frontline:UpdateCallIns()
    for i=#self.jamFields,1,-1 do
        if self.jamFields[i].timer:IsPastSimMS(CONFIG.CALLIN_SHIELD_DURATION_MS) then table.remove(self.jamFields,i) end
    end
    -- Process scripted bomb runs (fly horizontally, drop bombs at intervals).
    for i=#self.pendingDrops,1,-1 do
        local order=self.pendingDrops[i]
        if order.kind=="bomb" then
            -- If ship is destroyed, remove the pending drop.
            if not MovableMan:IsActor(order.ship) or (order.ship.Health and order.ship.Health<=0) then
                table.remove(self.pendingDrops, i)
            else
                local elapsed = order.timer.ElapsedSimTimeMS
                local flightSpeed = 120  -- pixels per second
                local currentX = order.startX + (elapsed * flightSpeed / 1000)
                order.ship.Pos.X = currentX
                
                -- Drop bombs at intervals along the flight path
                local bombIntervalMs = 800
                local bombsDue = math.min(order.totalBombs, math.floor(elapsed / bombIntervalMs))
                
                while order.bombsDropped < bombsDue do
                    -- Create bomb as pixel entity that falls and explodes on impact.
                    local item = CreateMOPixel("Bomb Run Bomb","Frontline.rte")
                    if item then
                        item.Pos = Vector(order.ship.Pos.X, order.ship.Pos.Y + 30)
                        item.Vel = Vector(flightSpeed * 0.5, 20)
                        item.Team = order.team
                        MovableMan:AddParticle(item)
                        order.bombsDropped = order.bombsDropped + 1
                    end
                end
                
                -- Remove ship when it has flown past the target area or dropped all bombs
                if currentX > order.startX + order.flightDistance or order.bombsDropped >= order.totalBombs then
                    order.ship.PinStrength = 0
                    order.ship.CanEnterOrbit = true
                    order.ship.AIMode = Actor.AIMODE_RETURN
                    order.ship:SetControllerMode(Controller.CIM_AI,-1)
                    table.remove(self.pendingDrops, i)
                end
            end
        end
    end
    
    -- Process regular dropship deliveries.
    for i=#self.pendingDrops,1,-1 do
        local order=self.pendingDrops[i]
        local target,ship=order.target,order.ship
        if not order.timer:IsPastSimMS(order.delay) then
            local remaining=math.max(0,math.ceil((order.delay-order.timer.ElapsedSimTimeMS)/1000))
            self:DrawCallInMarker(target,order.team,string.upper(order.kind).." SHIP ARRIVES IN "..remaining.."s")
        elseif not order.arrivalTimer then
            if self:ShieldBlocks(target,order.team) then
                self.teams[order.team].funds=self.teams[order.team].funds+order.cost
                self:Notify("Jammer intercepted "..order.kind.." drop; cost refunded")
                table.remove(self.pendingDrops,i)
            else
                -- Create and add the ship after the countdown, with fresh timers.
                ship=self:CreateSupportShip(order.team,order.kind,order.count,target.x,order.startY)
                if not ship then
                    self.teams[order.team].funds=self.teams[order.team].funds+order.cost
                    self:Notify("Support dropship unavailable; cost refunded")
                    table.remove(self.pendingDrops,i)
                else
                    order.ship=ship
                    self.frontlineCraft[ship.UniqueID]=true
                    MovableMan:AddActor(ship)
                    order.arrivalTimer=Timer()
                    self:Notify(string.upper(order.kind).." dropship arriving at "..target.name)
                end
            end
        elseif not MovableMan:IsActor(ship) or (ship.Health and ship.Health<=0) then
            self:Notify("Support dropship lost before delivery")
            table.remove(self.pendingDrops,i)
        elseif self:ShieldBlocks(target,order.team) then
            self.teams[order.team].funds=self.teams[order.team].funds+order.cost
            self:Notify("Jammer intercepted "..order.kind.." drop; cost refunded")
            ship.PinStrength=0
            ship.CanEnterOrbit=true
            ship.AIMode=Actor.AIMODE_RETURN
            ship:SetControllerMode(Controller.CIM_AI,-1)
            table.remove(self.pendingDrops,i)
        else
            local progress=math.min(1,order.arrivalTimer.ElapsedSimTimeMS/CONFIG.SUPPORT_DROP_APPROACH_MS)
            ship.Pos=Vector(target.x,order.startY+(order.releaseY-order.startY)*progress)
            if not order.arrivalTimer:IsPastSimMS(CONFIG.SUPPORT_DROP_APPROACH_MS) then
                local remaining=math.max(0,math.ceil((CONFIG.SUPPORT_DROP_APPROACH_MS-order.arrivalTimer.ElapsedSimTimeMS)/1000))
                self:DrawCallInMarker(target,order.team,string.upper(order.kind).." DROP IN "..remaining.."s")
            else
                -- Opening a hatch early ejects cargo automatically, so wait
                -- until the craft has arrived at the release point.
                if order.kind=="turret" then
                    -- Place turret on ground at target location.
                    local item=ship:RemoveInventoryItemAtIndex(0)
                    if item then
                        local ground=SceneMan:MovePointToGround(Vector(ship.Pos.X,0),0,4)
                        item.Pos=Vector(ship.Pos.X,ground.Y-12)
                        item.Team=order.team
                        item.AIMode=Actor.AIMODE_SENTRY
                        item.PinStrength=100000
                        MovableMan:AddActor(item)
                    end
                else
                    ship:OpenHatch()
                    local dropY=ship.Pos.Y+(ship.Radius or 50)+12
                    for n=1,order.count do
                        local item=ship:RemoveInventoryItemAtIndex(0)
                        if item then
                            local spread=n-(order.count+1)/2
                            item.Pos=Vector(ship.Pos.X+spread*16,dropY)
                            item.Vel=Vector(spread*(order.kind=="cover" and 5 or 8),10)
                            item.Team=order.team
                            MovableMan:AddParticle(item)
                        end
                    end
                end
                ship.PinStrength=0
                ship.CanEnterOrbit=true
                ship.AIMode=Actor.AIMODE_RETURN
                ship:SetControllerMode(Controller.CIM_AI,-1)
                local warning=order.kind=="cover" and "" or "! Friendly fire!"
                self:Notify(string.upper(order.kind).." delivered at "..target.name..warning)
                table.remove(self.pendingDrops,i)
            end
        end
    end
    for i=#self.pendingOrbitals,1,-1 do
        local salvo=self.pendingOrbitals[i]
        local post=salvo.target or self.outposts[salvo.index]
        local elapsed=salvo.timer.ElapsedSimTimeMS
        if elapsed<CONFIG.CALLIN_ORBITAL_DELAY_MS then
            self:DrawCallInMarker(post,salvo.team,"GATLING CANNON IN "..math.max(0,math.ceil((CONFIG.CALLIN_ORBITAL_DELAY_MS-elapsed)/1000)).."s")
        else
            local burstDuration=(salvo.total-1)*CONFIG.CALLIN_ORBITAL_DURATION_MS/(CONFIG.CALLIN_ORBITAL_SHOTS-1)
            local burstLeft=math.max(0,math.ceil((burstDuration-(elapsed-CONFIG.CALLIN_ORBITAL_DELAY_MS))/1000))
            self:DrawCallInMarker(post,salvo.team,"GATLING FIRING: "..burstLeft.."s | FRIENDLY FIRE!")
            -- Keep the initial 48 rounds spread over five seconds. The research
            -- upgrade adds more rounds at the same rate, extending the barrage.
            local due=math.min(salvo.total,1+math.floor((elapsed-CONFIG.CALLIN_ORBITAL_DELAY_MS)*(CONFIG.CALLIN_ORBITAL_SHOTS-1)/CONFIG.CALLIN_ORBITAL_DURATION_MS))
            while salvo.shots<due do
                if not self:ShieldBlocks(post,salvo.team) then
                    local round=CreateMOPixel("Frontline Orbital Round","Frontline.rte")
                    if round then
                        local x=math.max(1,math.min(SceneMan.SceneWidth-2,post.x+math.random(-CONFIG.CALLIN_ORBITAL_RADIUS,CONFIG.CALLIN_ORBITAL_RADIUS)))
                        local ground=SceneMan:MovePointToGround(Vector(x,0),0,4)
                        round.Pos=ground+Vector(0,-CONFIG.CALLIN_ORBITAL_HEIGHT)
                        round.Vel=Vector(0,CONFIG.CALLIN_ORBITAL_SPEED)
                        round.Team=salvo.team
                        MovableMan:AddParticle(round)
                        if salvo.sound and salvo.shots%CONFIG.CALLIN_ORBITAL_SOUND_EVERY==0 then salvo.sound:Play(ground) end
                    end
                end
                salvo.shots=salvo.shots+1
            end
            if salvo.shots>=salvo.total then
                table.remove(self.pendingOrbitals,i)
                self:Notify("Orbital gatling finished at "..post.name)
            end
        end
    end
    for i=#self.pendingStrikes,1,-1 do
        local strike=self.pendingStrikes[i]
        local post=strike.target or self.outposts[strike.index]
        if not strike.timer:IsPastSimMS(CONFIG.CALLIN_STRIKE_DELAY_MS) then
            self:DrawCallInMarker(post,strike.team,"PRECISION FIRE IN "..math.max(0,math.ceil((CONFIG.CALLIN_STRIKE_DELAY_MS-strike.timer.ElapsedSimTimeMS)/1000)).."s")
        elseif not strike.projectileTimer then
            local projectile=CreateMOPixel("Frontline Precision Projectile","Frontline.rte")
            if projectile and not self:ShieldBlocks(post,strike.team) then
                local ground=SceneMan:MovePointToGround(Vector(post.x,0),0,4)
                projectile.Pos=Vector(ground.X,math.max(0,ground.Y-CONFIG.CALLIN_PRECISION_HEIGHT))
                projectile.Vel=Vector(0,CONFIG.CALLIN_PRECISION_SPEED)
                projectile.Team=strike.team
                MovableMan:AddParticle(projectile)
                strike.projectile=projectile
                local cannon=self.supportSounds.precisionCannon
                if cannon then cannon:Play() end
                strike.projectileTimer=Timer()
                self:Notify("Orbital precision projectile descending at "..post.name)
            else
                self.teams[strike.team].funds=self.teams[strike.team].funds+CONFIG.CALLIN_STRIKE_COST
                self:Notify("Jammer intercepted precision strike; cost refunded")
                table.remove(self.pendingStrikes,i)
            end
        elseif strike.projectileTimer:IsPastSimMS(CONFIG.CALLIN_PRECISION_FLIGHT_MS) or not MovableMan:IsParticle(strike.projectile) then
            table.remove(self.pendingStrikes,i)
            self:Notify("Orbital precision strike completed at "..post.name)
        else
            self:DrawCallInMarker(post,strike.team,"PRECISION PROJECTILE DESCENDING!")
        end
    end
end

-- Observed health loss is an approximate battle statistic, not kill attribution.
-- Actors removed between updates and noncombat health loss cannot be attributed.
function Frontline:RecordTroopLoss()
    local current={}
    for actor in MovableMan.Actors do
        local team=actor.Team
        if self:IsFieldUnit(actor) then
            local health=math.max(0,actor.Health or 0)
            local previous=self.previousTroopHealth[actor.UniqueID]
            if previous and health<previous then
                self.teams[1-team].stats.troopDamage=self.teams[1-team].stats.troopDamage+(previous-health)
            end
            current[actor.UniqueID]=health
        end
    end
    self.previousTroopHealth=current
end

function Frontline:RecordBrainLoss()
    for team=0,1 do
        local brain=self.brains[team]
        local current=MovableMan:IsActor(brain) and math.max(0,brain.Health or 0) or 0
        local previous=self.previousBrainHealth[team]
        if current<previous then
            self.teams[1-team].stats.brainDamage=self.teams[1-team].stats.brainDamage+(previous-current)
        end
        self.previousBrainHealth[team]=current
    end
end

function Frontline:MatchTimeText()
    local seconds=self.battleStarted and math.floor(self.matchTimer.ElapsedSimTimeMS/1000) or 0
    return string.format("%d:%02d",math.floor(seconds/60),seconds%60)
end

-- The engine refunds any cargo on returning craft before this callback.
-- Our ships cost no gold, and cargo was already paid for by Frontline.
function Frontline:CraftEnteredOrbit(craft)
    if not self.frontlineCraft[craft.UniqueID] then return end
    self.frontlineCraft[craft.UniqueID]=nil
    local team=craft.Team
    if team~=0 and team~=1 then return end
    local cargoRefund=craft:GetTotalValue(0,0.9,0.9)
    if cargoRefund>0 then
        local funds=self:GetTeamFunds(team)-cargoRefund
        self:SetTeamFunds(funds,team)
        self.teams[team].funds=funds
        if team==0 then FrameMan:ClearScreenText(0) end
    end
end

function Frontline:EndActivity()
    self:ClearCompactHUD()
    FrameMan:SetHudDisabled(self.originalHudDisabled,0)
    if not self.resultReady then return end
    local t=self.teams[0]
    local result=self.WinnerTeam==0 and "VICTORY" or (self.WinnerTeam==1 and "DEFEAT" or "DRAW")
    local summary=result.."   Match time: "..self:MatchTimeText().."\nDeployed: "..t.stats.deployed.."   Friendly losses: "..self:GetTeamDeathCount(0).."\nEnemy losses: "..self:GetTeamDeathCount(1).."   Captures: "..t.stats.captures.."\nFunds earned: "..math.floor(t.stats.earned).."   Enemy brain health lost: "..math.floor(t.stats.brainDamage).."\nEnemy troop health lost (observed): "..math.floor(t.stats.troopDamage)
    FrameMan:SetScreenText(summary,0,0,-1,true)
end

function Frontline:StartBattle()
    if self.battleStarted then return end
    self.battleStarted=true
    self.matchTimer:Reset()
    self.aiTimer:Reset()
    self.tab="Squad"
    self:Notify("Battle starting: 15 second grace period")
end

-- The opponent uses the same team state and purchase/deployment functions as
-- the player. Its difficulty controls decision frequency, not free resources.
function Frontline:UpdateAI()
    local team=1
    local ai=self.teams[team]
    
    -- Pick a personality at match start for randomized playstyle
    if not self.aiPersonality then
        local roll=math.random(1,4)
        if roll==1 then self.aiPersonality="aggressive"
        elseif roll==2 then self.aiPersonality="defensive"
        elseif roll==3 then self.aiPersonality="economic"
        else self.aiPersonality="balanced" end
    end
    
    -- Track player behavior for adaptive strategy
    if not self.playerBehavior then
        self.playerBehavior={deployments=0,callinsUsed=0,researchFocus="",lastDeployTime=0}
    end
    
    local posts={}
    for i=1,#self.outposts do posts[i]={allies=0,enemies=0,wounded=0,threats=0} end
    local enemyVehicle=false
    local fieldActors={}
    for actor in MovableMan.Actors do
        if self:IsFieldUnit(actor) then
            table.insert(fieldActors,actor)
            if actor.Team==0 and IsACrab(actor) then enemyVehicle=true end
            for i,post in ipairs(self.outposts) do
                local dist=math.abs(actor.Pos.X-post.x)
                if dist<=CONFIG.OUTPOST_RADIUS then
                    if actor.Team==team then
                        posts[i].allies=posts[i].allies+1
                        if actor.Health>0 and actor.Health<actor.MaxHealth then posts[i].wounded=posts[i].wounded+1 end
                    else posts[i].enemies=posts[i].enemies+1 end
                end
                if actor.Team==0 and dist<=CONFIG.OUTPOST_RADIUS*2 then posts[i].threats=posts[i].threats+1 end
            end
        end
    end
    local pressured=self:UnitCount(0)>self:UnitCount(1)+2 or self:OutpostCount(0)>self:OutpostCount(1)
    
    -- Adaptive research priorities based on personality and player focus
    local priorities
    if self.aiPersonality=="aggressive" then
        priorities={3,4,7,8,2,6,1,10,11,16,13,14,15,9,5}
    elseif self.aiPersonality=="defensive" then
        priorities={1,12,3,6,2,10,16,13,14,15,8,7,9,4,5}
    elseif self.aiPersonality=="economic" then
        priorities={1,12,11,3,6,2,10,16,13,14,15,8,7,9,4,5}
    else
        priorities=pressured and {12,3,4,7,8,2,1,10,11,16,13,14,15,9,6,5} or {1,12,3,6,2,4,11,10,16,13,14,15,8,7,9,5}
    end
    
    -- Counter player's research focus if detected
    if self.playerBehavior.researchFocus=="infantry" then
        table.insert(priorities,2); table.insert(priorities,4)
    elseif self.playerBehavior.researchFocus=="vehicles" then
        table.insert(priorities,3); table.insert(priorities,6)
    end
    
    -- Invest from the same budget and keep a reserve for troop deployments.
    local brain=self.brains[team]
    if brain.Health<brain.MaxHealth-25 and ai.funds>=CONFIG.BASE_REPAIR_COST+240 then
        self:BaseUpgrade(team,"repair")
    elseif (not ai.turret or not MovableMan:IsActor(ai.turret)) and ai.funds>=CONFIG.BASE_TURRET_COST+300 then
        self:BaseUpgrade(team,"turret")
    elseif ai.baseArmor<CONFIG.BASE_ARMOR_LEVELS and ai.funds>=CONFIG.BASE_ARMOR_COST*(ai.baseArmor+1)+400 then
        self:BaseUpgrade(team,"armor")
    end
    
    for _,index in ipairs(priorities) do
        local r=CONFIG.research[index]
        local target=(index==1 or index==2) and (ai.funds>=3000 and 10 or 2) or (index==10 and ai.funds>=3000 and 10 or 1)
        if (ai.levels[index] or 0)<math.min(r.max,target) and ai.funds>=self:ResearchCost(team,index)+240 then
            local ok=self:Research(team,index)
            if ok then break end
        end
    end
    
    -- Build mixed batches with personality-based variation
    local batchSize=3+math.random(0,1)
    if self.aiPersonality=="aggressive" and ai.funds>5000 then batchSize=4+math.random(0,1)
    elseif self.aiPersonality=="defensive" then batchSize=2+math.random(0,1) end
    
    if ai.tier>=3 and ai.funds>=650 then
        ai.counts={1,0,0,1,1}
    elseif ai.tier>=2 and ai.funds>=480 then
        ai.counts={1,1,0,0,1}
    elseif ai.tier>=2 then
        ai.counts={1,1,1,0,0}
    elseif ai.tier>=1 then
        ai.counts={1,2,0,0,0}
    else
        ai.counts={1,0,0,0,0,0,2}
    end
    if (ai.levels[11] or 0)>0 and ai.funds>=550 then ai.counts[6]=1 end
    
    local basic=(ai.levels[12] or 0)>0 and 1 or 6
    -- Adaptive weapon selection based on player threats
    local weaponChoice=basic
    if enemyVehicle and (ai.levels[7] or 0)>0 then weaponChoice=5
    elseif ai.tier>=1 then weaponChoice=2 end
    
    ai.weapons={weaponChoice,weaponChoice,ai.tier>=2 and 3 or basic,basic,basic,basic,basic}
    ai.sidearms={}; ai.medkits={}; ai.grenades={}; ai.armor={}
    if ai.funds>=1000 then
        for i,entry in ipairs(CONFIG.roster) do
            if (ai.counts[i] or 0)>0 and (ai.levels[16] or 0)>0 then ai.armor[i]=true end
            if not entry.vehicle and not entry.miner and (ai.counts[i] or 0)>0 then
                ai.sidearms[i]=(ai.levels[15] or 0)>0 and (enemyVehicle and (ai.levels[7] or 0)>0 and 2 or 1) or 0
                ai.medkits[i]=(ai.levels[13] or 0)>0
                ai.grenades[i]=(ai.levels[14] or 0)>0
            end
        end
    end
    ai.preset="AI mixed"
    
    -- Attack the nearest unsecured post from the AI side, then attack the base.
    local target=0
    for i=#self.outposts,1,-1 do if self.outposts[i].owner~=team then target=i; break end end
    local desired=target>0 and "Advance" or "Rush"
    if target==0 and posts[3].threats>=2 then desired="Defend"; target=3 end
    
    -- Adaptive strategy: if player is aggressive, switch to defense temporarily
    if self.playerBehavior.deployments>5 and not pressured then
        desired="Advance"
    elseif pressured and self.aiPersonality=="defensive" then
        desired="Defend"
    end
    
    if ai.order~=desired or (target>0 and ai.orderTarget~=target) then
        ai.order=desired
        if target>0 then ai.orderTarget=target end
        self:ApplyTeamOrder(team)
    end
    
    ai.forward=0
    if ai.funds>=600 then
        for i=1,#self.outposts do
            if self.outposts[i].owner==team and posts[i].enemies==0 then ai.forward=i; break end
        end
    end
    
    -- Use the same six-unit batch limit as the player, adding riflemen only
    -- when the complete batch remains affordable with a modest reserve.
    local cost,count=self:Batch(team)
    while cost and count<CONFIG.MAX_BATCH and self:UnitCount(team)+count<self.settings.unitCap do
        ai.counts[1]=(ai.counts[1] or 0)+1
        local nextCost,nextCount=self:Batch(team)
        if not nextCost or nextCost>ai.funds-200 then
            ai.counts[1]=ai.counts[1]-1
            break
        end
        cost,count=nextCost,nextCount
    end
    
    if not self.settings.callins or not self.matchTimer:IsPastSimMS(CONFIG.GRACE_MS) then return end
    
    -- Intercept an incoming hostile warning at an owned post when affordable.
    if ai.funds>=CONFIG.CALLIN_SHIELD_COST+150 then
        for _,pendingList in ipairs({self.pendingStrikes,self.pendingOrbitals,self.pendingDrops}) do
            for _,pending in ipairs(pendingList) do
                if pending.team~=team and not pending.projectileTimer then
                    local target=pending.target or self.outposts[pending.index]
                    for i,post in ipairs(self.outposts) do
                        if target and post.owner==team and math.abs(post.x-target.x)<=CONFIG.OUTPOST_RADIUS then
                            local ok=self:CallIn(team,"shield",target); if ok then return end
                        end
                    end
                end
            end
        end
    end
    
    -- Heal wounded squads when it is worthwhile, conserving a deployment reserve.
    if ai.funds>=CONFIG.CALLIN_MEDIC_COST+240 then
        for i=1,#posts do if posts[i].wounded>=2 then local ok=self:CallIn(team,"medic",i); if ok then return end end end
    end
    
    -- Rotate among all three offensive call-ins when enemies are concentrated
    -- and friendly troops are clear. CallIn enforces the same cooldowns and cost.
    if ai.funds>=CONFIG.CALLIN_STRIKE_COST+300 then
        local kinds={"strike","bomb","orbital"}
        local start=ai.offenseChoice or 1
        
        -- Adaptive: use orbital more if player has many units
        if self.aiPersonality=="aggressive" and self:UnitCount(0)>8 then
            kinds={"orbital","bomb","strike"}
        end
        
        for i=1,#posts do
            if posts[i].enemies>=2 and posts[i].allies==0 then
                for offset=0,#kinds-1 do
                    local choice=(start+offset-1)%#kinds+1
                    local kind=kinds[choice]
                    local prices={strike=CONFIG.CALLIN_STRIKE_COST,bomb=CONFIG.CALLIN_BOMB_COST,orbital=CONFIG.CALLIN_ORBITAL_COST}
                    if ai.funds>=prices[kind]+240 then
                        local ok=self:CallIn(team,kind,i)
                        if ok then ai.offenseChoice=choice%#kinds+1; return end
                    end
                end
            end
        end
    end
    
    -- Outside capture zones, strike isolated concentrations without hitting allies.
    if ai.funds>=CONFIG.CALLIN_STRIKE_COST+300 then
        for _,candidate in ipairs(fieldActors) do
            if candidate.Team==0 then
                local enemies,allies=0,0
                for _,actor in ipairs(fieldActors) do
                    if math.abs(actor.Pos.X-candidate.Pos.X)<120 then
                        if actor.Team==0 then enemies=enemies+1 else allies=allies+1 end
                    end
                end
                if enemies>=2 and allies==0 then
                    local ground=SceneMan:MovePointToGround(Vector(candidate.Pos.X,0),0,4)
                    local target={name="enemy concentration",x=candidate.Pos.X,groundY=ground.Y,owner=-1}
                    local ok=self:CallIn(team,"strike",target); if ok then return end
                end
            end
        end
    end
    
    -- Fortify threatened posts, alternating cover and mines.
    if ai.funds>=CONFIG.CALLIN_COVER_COST+300 then
        local kinds=ai.fortifyChoice=="mines" and {"mines","cover"} or {"cover","mines"}
        
        -- Adaptive: fortify more if player is aggressive
        if self.playerBehavior.deployments>5 then
            for i=#posts,1,-1 do
                if self.outposts[i].owner==team and posts[i].allies>0 then
                    for _,kind in ipairs(kinds) do
                        local cost=kind=="mines" and CONFIG.CALLIN_MINES_COST or CONFIG.CALLIN_COVER_COST
                        if ai.funds>=cost+240 then
                            local ok=self:CallIn(team,kind,i)
                            if ok then ai.fortifyChoice=kind=="mines" and "cover" or "mines"; return end
                        end
                    end
                end
            end
        else
            for i=#posts,1,-1 do
                if self.outposts[i].owner==team and posts[i].allies>0 and posts[i].threats>0 then
                    for _,kind in ipairs(kinds) do
                        local cost=kind=="mines" and CONFIG.CALLIN_MINES_COST or CONFIG.CALLIN_COVER_COST
                        if ai.funds>=cost+240 then
                            local ok=self:CallIn(team,kind,i)
                            if ok then ai.fortifyChoice=kind=="mines" and "cover" or "mines"; return end
                        end
                    end
                end
            end
        end
    end
end

-- Use the engine's normal reach and pickup action, keeping inventory and orders.
-- Compare every carried firearm so units do not swap back to weaker drops.
function Frontline:UpdateWeaponPickups()
    for actor in MovableMan.Actors do
        if (actor.Team==0 or actor.Team==1) and actor.UniqueID~=self.brains[actor.Team].UniqueID
            and not self.miners[actor.UniqueID] and IsAHuman(actor) and actor.Health>0 then
            local item=actor.ItemInReach
            if item and IsHDFirearm(item) and item:IsPickupableBy(actor) and item.Vel.Largest<3 then
                local value=item:GetGoldValue(0,1,1)
                local best=0
                local held=actor.EquippedItem
                if held and IsHDFirearm(held) then best=held:GetGoldValue(0,1,1) end
                for carried in actor.Inventory do
                    if IsHDFirearm(carried) then best=math.max(best,carried:GetGoldValue(0,1,1)) end
                end
                if value>best then actor:GetController():SetState(Controller.WEAPON_PICKUP,true) end
            end
        end
    end
end

function Frontline:UpdateActivity()
    if self.ActivityState==Activity.OVER then return end
    -- Read engine deposits, including any gold returned by miners, before spending.
    if self.GetTeamFunds then for team=0,1 do self.teams[team].funds=self:GetTeamFunds(team) end end
    if self.battleStarted then
    self:RecordBrainLoss()
    self:RecordTroopLoss()
    local dead0=not MovableMan:IsActor(self.brains[0])
    local dead1=not MovableMan:IsActor(self.brains[1])
    if dead0 or dead1 then
        self.WinnerTeam=dead0 and (dead1 and Activity.NOTEAM or 1) or 0
        self.resultReady=true
        ActivityMan:EndActivity()
        return
    end
    self:UpdateOutpost(TimerMan.DeltaTimeSecs)
    self:UpdateDeliveries()
    self:UpdateOrders()
    self:UpdateWeaponPickups()
    if self.minerTimer:IsPastSimMS(CONFIG.MINER_CHECK_INTERVAL_MS) then
        self.minerTimer:Reset()
        self:UpdateMiners()
    end
    -- Credit carried ore when automatic gold deposit is disabled in game settings.
    for actor in MovableMan.Actors do
        if self.miners[actor.UniqueID] and actor.GoldCarried and actor.GoldCarried>0 then
            self.teams[actor.Team].funds=self.teams[actor.Team].funds+actor.GoldCarried
            actor.GoldCarried=0
        end
    end
    self:UpdateCallIns()
    for team=0,1 do
        local t=self.teams[team]
        local income=self:TeamIncome(team)
        local earned=income*TimerMan.DeltaTimeSecs
        t.funds=t.funds+earned
        t.stats.earned=t.stats.earned+earned
        local opponent=1-team
        local deaths=self:GetTeamDeathCount(opponent)
        if deaths>t.deaths then
            local bounty=(deaths-t.deaths)*(CONFIG.BOUNTY+15*t.levels[2])
            t.funds=t.funds+bounty
            t.stats.earned=t.stats.earned+bounty
            t.deaths=deaths
        end
        if t.auto then self:Deploy(team) end
        end
        if team==0 then self.playerBehavior.deployments=self.playerBehavior.deployments+1 end
    if self.aiTimer:IsPastSimMS(self.aiInterval) then
        self.aiTimer:Reset()
        self:UpdateAI()
    end
    if self.brains[0].Health and self.brainHealth and self.brains[0].Health<self.brainHealth-5 then self:Notify("Warning: your brain is under attack!") end
    self.brainHealth=self.brains[0].Health
    else
        self.matchTimer:Reset()
    end
    self:DrawOutpost()
    if self.battleStarted and not self.targeting and UInputMan:KeyPressed(Key.TAB) then self.panel=not self.panel end
    FrameMan:SetHudDisabled(self.panel or self.originalHudDisabled,0)
    if self.panel then
        self:ClearCompactHUD()
        -- Observation mode also consumes the mouse. Hold its camera still while
        -- the panel owns the cursor, and release it again when the panel closes.
        if not self.panelCameraOffset then
            local offset=CameraMan:GetOffset(0)
            self.panelCameraOffset=Vector(offset.X,offset.Y)
        end
        local offset=self.panelCameraOffset
        local center=offset+Vector(FrameMan.PlayerScreenWidth/2,FrameMan.PlayerScreenHeight/2)
        self:SetObservationTarget(center,0)
        CameraMan:SetOffset(offset,0)
        CameraMan:SetScrollTarget(center,1,0)
        if self.battleStarted then self:DrawPanel() else self:DrawWizard() end
    else
        self.panelCameraOffset=nil
        if self.targeting then self:ClearCompactHUD(); self:UpdateTargeting() else self:DrawHUD() end
    end
    if self.SetTeamFunds then for team=0,1 do self:SetTeamFunds(self.teams[team].funds,team) end end
end

function Frontline:DrawOutpost()
    for _,outpost in ipairs(self.outposts) do
        local x,y=outpost.x,outpost.groundY
        local color=outpost.owner==0 and 120 or (outpost.owner==1 and 13 or 86)
        PrimitiveMan:DrawLinePrimitive(Vector(x,y-8),Vector(x,y-105),color)
        PrimitiveMan:DrawTextPrimitive(Vector(x,y-125),outpost.name.." "..outpost.bonus,true,1)
        PrimitiveMan:DrawBoxPrimitive(Vector(x-40,y-112),Vector(x+40,y-107),120)
        local progress=math.floor((outpost.progress+1)*40)
        PrimitiveMan:DrawBoxFillPrimitive(Vector(x-39,y-111),Vector(x-39+progress,y-108),color)
    end
    for _,field in ipairs(self.jamFields) do
        if not field.timer:IsPastSimMS(CONFIG.CALLIN_SHIELD_DURATION_MS) then
            self:DrawShieldField(field,field.team)
            local seconds=math.max(0,math.ceil((CONFIG.CALLIN_SHIELD_DURATION_MS-field.timer.ElapsedSimTimeMS)/1000))
            local label=field.team==0 and "SUPPORT JAMMER " or "ENEMY SUPPORT JAMMER "
            PrimitiveMan:DrawTextPrimitive(Vector(field.x,field.groundY-165),label..seconds.."s",true,1)
        end
    end
end

-- Newer builds may expose screen-space primitives. Fall back to the original
-- camera-relative primitives on stock engines, where the HUD can still jitter.
function Frontline:UIDrawBoxFill(screen,a,b,color)
    if self.screenUI then PrimitiveMan:DrawScreenBoxFillPrimitive(screen,a,b,color)
    else PrimitiveMan:DrawBoxFillPrimitive(screen,a,b,color) end
end
function Frontline:UIDrawBox(screen,a,b,color)
    if self.screenUI then PrimitiveMan:DrawScreenBoxPrimitive(screen,a,b,color)
    else PrimitiveMan:DrawBoxPrimitive(screen,a,b,color) end
end
function Frontline:UIDrawText(screen,p,label,small,alignment)
    if self.screenUI then PrimitiveMan:DrawScreenTextPrimitive(screen,p,label,small,alignment)
    else PrimitiveMan:DrawTextPrimitive(screen,p,label,small,alignment) end
end

-- Stock engines offer fixed screen text but not screen-space drawing primitives.
-- Use it for the compact HUD so camera interpolation cannot move it between
-- the simulation update and the render pass.
function Frontline:ClearCompactHUD()
    if self.compactScreenText then
        FrameMan:ClearScreenText(0)
        self.compactScreenText=false
    end
end

function Frontline:DrawHUD()
    local t=self.teams[0]
    local offset=CameraMan:GetOffset(0)
    local cost,count=self:Batch(0)
    local income=self:TeamIncome(0)
    local owned=self:OutpostCount(0).."-"..self:OutpostCount(1)
    local lines={}
    local function text(y,s) lines[#lines+1]={y=y,text=s} end
    local bonusIncome=self:PostBonusCount(0,1)*CONFIG.OUTPOST_INCOME
    local researchDiscount=self:PostBonusCount(0,2)>0 and 20 or 0
    local supportDiscount=self:PostBonusCount(0,3)>0 and 20 or 0
    text(26,"FRONTLINE | TAB: COMMAND | Funds: "..math.floor(t.funds).." +"..income.."/s | Bounty: "..(CONFIG.BOUNTY+15*t.levels[2]))
    text(38,"Batch: "..(count or 0).." / "..(cost or 0).." oz | Units: "..self:UnitCount(0).." vs "..self:UnitCount(1).." / "..self.settings.unitCap.." | Deploy: "..self:AutoReason(0).." | Auto: "..(t.auto and "ON" or "OFF"))
    text(50,"Posts: "..owned.." | Post bonuses: +"..bonusIncome.."/s | Research -"..researchDiscount.."% | Support -"..supportDiscount.."%")
    text(62,"Deaths: "..self:GetTeamDeathCount(0).." / "..self:GetTeamDeathCount(1).." | Match time: "..self:MatchTimeText())
    if not self.noticeTimer:IsPastSimMS(5000) then text(76,self.message) end
    local ok,screenText=pcall(function() return FrameMan.SetScreenText end)
    if not self.screenUI and ok and screenText then
        local values={}
        for _,line in ipairs(lines) do values[#values+1]=line.text end
        FrameMan:SetScreenText(table.concat(values,"\n"),0,0,-1,false)
        self.compactScreenText=true
    else
        local function pos(x,y) return self.screenUI and Vector(x,y) or offset+Vector(x,y) end
        self:UIDrawBoxFill(0,pos(8,22),pos(math.min(620,FrameMan.PlayerScreenWidth-8),94),245)
        self:UIDrawBox(0,pos(8,22),pos(math.min(620,FrameMan.PlayerScreenWidth-8),94),120)
        for _,line in ipairs(lines) do self:UIDrawText(0,pos(14,line.y),line.text,true,0) end
    end
end

function Frontline:DrawWizard()
    local offset=CameraMan:GetOffset(0)
    local move=UInputMan:GetMouseMovement(0)
    self.cursorX=math.max(8,math.min(465,self.cursorX+move.X))
    self.cursorY=math.max(8,math.min(400,self.cursorY+move.Y))
    local click=UInputMan:MouseButtonPressed(MouseButtons.MOUSE_LEFT)
    local rightClick=UInputMan:MouseButtonPressed(MouseButtons.MOUSE_RIGHT)
    local function pos(x,y) return self.screenUI and Vector(x,y) or offset+Vector(x,y) end
    local function text(x,y,label) self:UIDrawText(0,pos(x,y),label,#label>42,0) end
    local function button(x,y,w,label,action,reversible)
        self:UIDrawBoxFill(0,pos(x,y),pos(x+w,y+18),182)
        self:UIDrawBox(0,pos(x,y),pos(x+w,y+18),206)
        self:UIDrawText(0,pos(x+4,y+3),label,#label*7>w-8,0)
        if self.cursorX>=x and self.cursorX<=x+w and self.cursorY>=y and self.cursorY<=y+18 then
            if click then action(1) elseif rightClick and reversible then action(-1) end
        end
    end
    self:UIDrawBoxFill(0,pos(8,8),pos(465,400),245)
    self:UIDrawBox(0,pos(8,8),pos(465,400),120)
    text(20,18,"FRONTLINE MATCH SETUP")
    if self.setupStep==1 then
        text(20,44,"STEP 1 OF 2: CHOOSE MATCH SETTINGS")
        text(20,62,"Left click: next; right click: previous. Both teams use it.")
        button(20,86,300,"STARTING FUNDS: "..self.settings.startFunds,function(step)
            local new=cycleOption({250,450,750},self.settings.startFunds,step)
            local delta=new-self.settings.startFunds
            self.teams[0].funds=self.teams[0].funds+delta
            self.teams[1].funds=self.teams[1].funds+delta
            self.settings.startFunds=new
        end,true)
        button(20,115,300,"BASE INCOME / SEC: "..self.settings.income,function(step) self.settings.income=cycleOption({3,5,8,10,15,20,25},self.settings.income,step) end,true)
        button(20,144,300,"TEAM UNIT CAP: "..self.settings.unitCap,function(step) self.settings.unitCap=cycleOption({8,12,16,32,50},self.settings.unitCap,step) end,true)
        button(20,173,300,"OUTPOST BONUSES: "..(self.settings.outpostBonuses and "ON" or "OFF"),function() self.settings.outpostBonuses=not self.settings.outpostBonuses end,true)
        button(20,202,300,"CALL-INS: "..(self.settings.callins and "ON" or "OFF"),function() self.settings.callins=not self.settings.callins end,true)
        text(20,235,"Difficulty is selected in the game's match setup.")
        button(20,270,150,"NEXT: REVIEW",function() self.setupStep=2 end)
    else
        text(20,44,"STEP 2 OF 2: REVIEW AND START")
        text(20,70,"Starting funds: "..self.settings.startFunds.." oz")
        text(20,90,"Income: "..self.settings.income.."/s    Unit cap: "..self.settings.unitCap)
        text(20,110,"Outpost bonuses: "..(self.settings.outpostBonuses and "ON" or "OFF"))
        text(20,130,"Call-ins: "..(self.settings.callins and "ON" or "OFF"))
        text(20,160,"No income or deployments occur during setup.")
        text(20,180,"Starting begins a 15-second deployment grace period.")
        button(20,220,120,"BACK",function() self.setupStep=1 end)
        button(155,220,160,"START BATTLE",function() self:StartBattle() end)
    end
    self:UIDrawBoxFill(0,pos(self.cursorX-2,self.cursorY-2),pos(self.cursorX+2,self.cursorY+2),120)
end

function Frontline:DrawPanel()
    local t=self.teams[0]
    local screen=0
    local offset=CameraMan:GetOffset(screen)
    local move=UInputMan:GetMouseMovement(0)
    self.cursorX=math.max(8,math.min(465,self.cursorX+move.X))
    self.cursorY=math.max(8,math.min(430,self.cursorY+move.Y))
    local mouse=Vector(self.cursorX,self.cursorY)
    local click=UInputMan:MouseButtonPressed(MouseButtons.MOUSE_LEFT)
    local rightClick=UInputMan:MouseButtonPressed(MouseButtons.MOUSE_RIGHT)
    local function pos(x,y) return self.screenUI and Vector(x,y) or offset+Vector(x,y) end
    -- Larger game font for short labels; long lines stay small so they fit.
    local function text(x,y,s,small)
        if small==nil then small=#s>42 end
        self:UIDrawText(screen,pos(x,y),s,small,0)
    end
    -- Dark fills preserve contrast with the game's pale text at both font sizes.
    local function button(x,y,w,label,state,action,reversible)
        local colors={selected=192,available=182,disabled=247,locked=242}
        self:UIDrawBoxFill(screen,pos(x,y),pos(x+w,y+15),colors[state] or colors.available)
        local border=state=="selected" and 120 or ((state=="disabled" or state=="locked") and 94 or 206)
        self:UIDrawBox(screen,pos(x,y),pos(x+w,y+15),border)
        -- The large font is roughly seven pixels per character in this UI.
        -- Keep long button labels in the small font rather than clipping them.
        text(x+3,y+2,label,#label*7>w-6)
        if mouse.X>=x and mouse.X<=x+w and mouse.Y>=y and mouse.Y<=y+15 then
            if click then action(1) elseif rightClick and reversible then action(-1) end
        end
    end
    self:UIDrawBoxFill(screen,pos(8,8),pos(465,430),245)
    self:UIDrawBox(screen,pos(8,8),pos(465,430),120)
    text(15,14,"FRONTLINE COMMAND  |  TAB: CLOSE",false)
    local cost,count=self:Batch(0)
    local income=self:TeamIncome(0)
    text(15,28,"Funds "..math.floor(t.funds).." oz   +"..income.."/s   Bounty "..(CONFIG.BOUNTY+15*t.levels[2]))
    text(15,40,"Batch "..(count or 0).." / "..(cost or 0).." oz   Units "..self:UnitCount(0).."/"..self.settings.unitCap.."   "..self:AutoReason(0))
    local tabs={"Squad","Research","Battle","Support","Base","Setup"}
    for i,name in ipairs(tabs) do button(15+(i-1)*74,56,70,name,self.tab==name and "selected" or "available",function() self.tab=name end) end
    if self.tab=="Squad" then
        text(15,79,"Select quantity and each unit type's weapon. Max "..CONFIG.MAX_BATCH.." per batch.")
        -- Display cheaper Ronin first without changing the stable roster IDs
        -- used by saved squads and the AI.
        for displayIndex,i in ipairs({7,1,2,3,4,5,6}) do
          local r=CONFIG.roster[i]
          if math.floor((displayIndex-1)/4)+1==self.rosterPage then
            local y=96+((displayIndex-1)%4)*39
            local unlocked=r.unlock<=t.tier and (not r.research or (t.levels[r.research] or 0)>0)
            text(15,y,r.name.." ("..r.price.." oz)"..(unlocked and "" or " [LOCKED]"))
            button(230,y-2,18,"-",unlocked and "available" or "locked",function() t.counts[i]=math.max(0,(t.counts[i] or 0)-1); t.preset="Custom" end)
            text(256,y,tostring(t.counts[i] or 0))
            button(275,y-2,18,"+",unlocked and "available" or "locked",function()
                local _,n=self:Batch(0)
                if unlocked and n and n<CONFIG.MAX_BATCH then t.counts[i]=(t.counts[i] or 0)+1; t.preset="Custom" end
            end)
            local weapon=CONFIG.weapons[t.weapons[i] or 6]
            local special=r.vehicle or r.miner
            button(15,y+14,special and 238 or 100,(r.vehicle and "Built-in gatling" or (r.miner and "FIXED: Pistol + Light Digger (+25/unit)" or (weapon.name.." +"..weapon.price))),unlocked and weaponUnlocked(t,weapon) and "available" or "locked",function(step)
                if unlocked and not special then
                    local nextIndex=((t.weapons[i] or 6)-1+step)%#CONFIG.weapons+1
                    while not weaponUnlocked(t,CONFIG.weapons[nextIndex]) do nextIndex=(nextIndex-1+step)%#CONFIG.weapons+1 end
                    t.weapons[i]=nextIndex; t.preset="Custom"
                end
            end,true)
            if not special then
                local side=t.sidearms[i] or 0
                button(117,y+14,60,side==0 and "SIDE: -" or (side==1 and "Pistol +10" or "RPG +95"),unlocked and (t.levels[15] or 0)>0 and "available" or "locked",function(step)
                    if unlocked and (t.levels[15] or 0)>0 then
                        local nextSide=(side+step)%3
                        if nextSide==2 and (t.levels[7] or 0)==0 then nextSide=(nextSide+step)%3 end
                        t.sidearms[i]=nextSide; t.preset="Custom"
                    end
                end,true)
                button(179,y+14,36,t.medkits[i] and "MED X" or "MED",unlocked and (t.levels[13] or 0)>0 and (t.medkits[i] and "selected" or "available") or "locked",function() if unlocked and (t.levels[13] or 0)>0 then t.medkits[i]=not t.medkits[i]; t.preset="Custom" end end,true)
                button(217,y+14,36,t.grenades[i] and "GRN X" or "GRN",unlocked and (t.levels[14] or 0)>0 and (t.grenades[i] and "selected" or "available") or "locked",function() if unlocked and (t.levels[14] or 0)>0 then t.grenades[i]=not t.grenades[i]; t.preset="Custom" end end,true)
            end
            button(255,y+14,40,t.armor[i] and "ARM X" or "ARM",unlocked and (t.levels[16] or 0)>0 and (t.armor[i] and "selected" or "available") or "locked",function()
                if unlocked and (t.levels[16] or 0)>0 then t.armor[i]=not t.armor[i]; t.preset="Custom" end
            end,true)
          end
        end
        button(310,238,140,"UNITS PAGE "..self.rosterPage.." / 2","available",function() self.rosterPage=self.rosterPage==1 and 2 or 1 end,true)
        text(310,83,"ORDERS: all troops")
        for i,order in ipairs({"Rush","Advance","Defend"}) do
            button(310+(i-1)*47,96,45,order,t.order==order and "selected" or "available",function()
                t.order=order; self:ApplyTeamOrder(0)
            end)
        end
        local deployment=t.forward==0 and "BASE" or self.outposts[t.forward].name
        button(310,119,140,"SPAWN: "..deployment..(t.forward>0 and " (+25/unit)" or ""),"available",function(step) t.forward=(t.forward+step)%(#self.outposts+1) end,true)
        text(310,143,t.order=="Rush" and "RUSH: enemy brain" or ("TARGET: "..self.outposts[t.orderTarget].name))
        button(310,158,64,"< PREV","available",function()
            t.orderTarget=(t.orderTarget-2)%#self.outposts+1
            if t.order~="Rush" then self:ApplyTeamOrder(0) end
        end)
        button(381,158,69,"NEXT >","available",function()
            t.orderTarget=t.orderTarget%#self.outposts+1
            if t.order~="Rush" then self:ApplyTeamOrder(0) end
        end)
        text(310,181,"Advance: capture, then attack",true)
        text(310,193,"Defend: capture and hold",true)
        text(310,205,"Forward: +25/unit, "..(CONFIG.FORWARD_DEPLOY_COOLDOWN_MS/1000).."s cooldown",true)
        text(310,217,"MED / GRN: +45 each",true)
        text(310,229,"ARM: +"..CONFIG.UNIT_ARMOR_COST.."/unit",true)
        text(15,266,"Squad presets: "..t.preset.." (changes current selection)")
        for i,name in ipairs({"Rush","Assault","Specialist"}) do
            button(15+(i-1)*105,280,98,name,t.preset==name and "selected" or "available",function() self:SetPreset(0,name) end)
        end
        button(15,306,98,"SAVE CUSTOM","available",function() self:SaveSquad(0) end)
        button(120,306,98,"LOAD CUSTOM",t.savedSquad and "available" or "disabled",function() self:LoadSquad(0) end)
        text(225,310,"Saved for this match")
    elseif self.tab=="Research" then
        text(15,80,"ECONOMY: repeatable income and bounty upgrades")
        text(15,94,"INFANTRY / EQUIPMENT / FACTIONS: unlock tiers in order")
        button(350,80,100,"PAGE "..self.researchPage.." / 2","available",function() self.researchPage=self.researchPage==1 and 2 or 1 end,true)
        for i,r in ipairs(CONFIG.research) do
          if math.floor((i-1)/9)+1==self.researchPage then
            local y=106+((i-1)%9)*23
            local price=self:ResearchCost(0,i)
            local locked=(r.kind=="tier" and r.tier>1 and t.tier<r.tier-1) or (r.requires and t.tier<r.requires)
            local state=(t.levels[i] or 0)>=r.max and "selected" or (locked and "locked" or (t.funds<price and "disabled" or "available"))
            local label=r.name.."  "..t.levels[i].."/"..r.max.."   "..price.." oz"
            button(15,y,325,label,state,function() local _,msg=self:Research(0,i); if msg~="Research complete" then self:Notify(msg) end end)
            if locked then text(350,y+3,"Prior tier") end
          end
        end
        text(15,335,"Research outposts reduce costs by 20%.")
    elseif self.tab=="Battle" then
        text(15,84,"OUTPOSTS: hold for bonuses (income stacks)")
        for i,outpost in ipairs(self.outposts) do
            local owner=outpost.owner==0 and "YOUR TEAM" or (outpost.owner==1 and "ENEMY" or "NEUTRAL")
            text(15,86+i*12,outpost.name..": "..owner.."  "..outpost.bonus.."  "..math.floor((outpost.progress+1)*50).."%")
        end
        text(15,215,"YOUR UNITS: "..self:UnitCount(0).." / "..self.settings.unitCap)
        text(15,230,"ENEMY UNITS: "..self:UnitCount(1).." / "..self.settings.unitCap)
        text(15,245,"Opening grace: "..math.max(0,math.ceil((CONFIG.GRACE_MS-self.matchTimer.ElapsedSimTimeMS)/1000)).."s")
        text(15,265,"Forward deployments arrive by dropship at captured outposts.")
        text(15,280,"Rush attacks the brain. Advance captures then attacks.")
        text(15,295,"Defend goes to the selected outpost and holds there.")
    elseif self.tab=="Support" then
        text(15,84,"Choose support, then click a location on the battlefield.")
        text(15,99,"Tab cancels targeting. Place the jammer anywhere.")
        local strikeLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_STRIKE_COOLDOWN_MS)-t.strikeTimer.ElapsedSimTimeMS)/1000))
        local medicLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_MEDIC_COOLDOWN_MS)-t.medicTimer.ElapsedSimTimeMS)/1000))
        button(15,122,205,"PRECISION "..CONFIG.CALLIN_STRIKE_COST.." oz  "..(strikeLeft>0 and strikeLeft.."s" or "READY"),strikeLeft==0 and t.funds>=CONFIG.CALLIN_STRIKE_COST and "available" or "disabled",function() self:BeginTargeting("strike") end)
        button(230,122,205,"MEDICS "..CONFIG.CALLIN_MEDIC_COST.." oz  "..(medicLeft>0 and medicLeft.."s" or "READY"),medicLeft==0 and t.funds>=CONFIG.CALLIN_MEDIC_COST and "available" or "disabled",function() self:BeginTargeting("medic") end)
        text(15,143,"Precision: 3s warning | Dropships: 4s until arrival.")
        local coverLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_COVER_COOLDOWN_MS)-t.coverTimer.ElapsedSimTimeMS)/1000))
        local minesLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_MINES_COOLDOWN_MS)-t.minesTimer.ElapsedSimTimeMS)/1000))
        local bombLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_BOMB_COOLDOWN_MS)-t.bombTimer.ElapsedSimTimeMS)/1000))
        button(15,159,135,"COVER "..CONFIG.CALLIN_COVER_COST.." "..(coverLeft>0 and coverLeft.."s" or "READY"),coverLeft==0 and t.funds>=CONFIG.CALLIN_COVER_COST and "available" or "disabled",function() self:BeginTargeting("cover") end)
        button(155,159,135,"MINES "..CONFIG.CALLIN_MINES_COST.." "..(minesLeft>0 and minesLeft.."s" or "READY"),minesLeft==0 and t.funds>=CONFIG.CALLIN_MINES_COST and "available" or "disabled",function() self:BeginTargeting("mines") end)
        button(295,159,135,"BOMB "..CONFIG.CALLIN_BOMB_COST.." "..(bombLeft>0 and bombLeft.."s" or "READY"),bombLeft==0 and t.funds>=CONFIG.CALLIN_BOMB_COST and "available" or "disabled",function() self:BeginTargeting("bomb") end)
        local turretLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_TURRET_COOLDOWN_MS)-t.turretTimer.ElapsedSimTimeMS)/1000))
        button(15,181,205,"STATIC TURRET "..CONFIG.CALLIN_TURRET_COST.." "..(turretLeft>0 and turretLeft.."s" or "READY"),turretLeft==0 and t.funds>=CONFIG.CALLIN_TURRET_COST and "available" or "disabled",function() self:BeginTargeting("turret") end)
        local orbitalLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_ORBITAL_COOLDOWN_MS)-t.orbitalTimer.ElapsedSimTimeMS)/1000))
        button(15,203,205,"ORBITAL GATLING CANNON "..CONFIG.CALLIN_ORBITAL_COST.." "..(orbitalLeft>0 and orbitalLeft.."s" or "READY"),orbitalLeft==0 and t.funds>=CONFIG.CALLIN_ORBITAL_COST and "available" or "disabled",function() self:BeginTargeting("orbital") end)
        text(225,185,CONFIG.CALLIN_ORBITAL_SHOTS.." frag rounds; 5s burst; friendly fire",true)
        local shieldLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_SHIELD_COOLDOWN_MS)-t.shieldTimer.ElapsedSimTimeMS)/1000))
        button(15,225,205,"JAMMER "..CONFIG.CALLIN_SHIELD_COST.." "..(shieldLeft>0 and shieldLeft.."s" or "READY"),shieldLeft==0 and t.funds>=CONFIG.CALLIN_SHIELD_COST and "available" or "disabled",function() self:BeginTargeting("shield") end)
        text(15,230,"Jammer: place anywhere to disrupt enemy support for 20s.")
        text(15,245,"Blocks hostile call-ins aimed inside the outlined area.")
        text(15,260,"Does not stop weapons, grenades, or bombs already falling.")
        text(15,277,"Friendly support works normally. Radius: 180 pixels.")
        text(15,293,"Support is restricted within 600px of the enemy base.")
    elseif self.tab=="Base" then
        local brain=self.brains[0]
        text(15,84,"BASE DEFENSES")
        text(15,104,"Brain health: "..math.floor(brain.Health).." / "..math.floor(brain.MaxHealth))
        text(15,120,"Armor level: "..t.baseArmor.." / "..CONFIG.BASE_ARMOR_LEVELS)
        local active=t.turret and MovableMan:IsActor(t.turret)
        text(15,136,"Upper-room turret: "..(active and "ACTIVE" or "ABSENT"))
        local armorCost=CONFIG.BASE_ARMOR_COST*(t.baseArmor+1)
        button(15,160,300,"ARMOR +50 HP  "..armorCost.." oz",t.baseArmor<CONFIG.BASE_ARMOR_LEVELS and t.funds>=armorCost and "available" or "disabled",function() local ok,msg=self:BaseUpgrade(0,"armor"); if not ok then self:Notify(msg) end end)
        button(15,185,300,"REPAIR +50 HP  "..CONFIG.BASE_REPAIR_COST.." oz",brain.Health<brain.MaxHealth and t.funds>=CONFIG.BASE_REPAIR_COST and "available" or "disabled",function() local ok,msg=self:BaseUpgrade(0,"repair"); if not ok then self:Notify(msg) end end)
        button(15,210,300,"GATLING TURRET  "..CONFIG.BASE_TURRET_COST.." oz",not active and t.funds>=CONFIG.BASE_TURRET_COST and "available" or "disabled",function() local ok,msg=self:BaseUpgrade(0,"turret"); if not ok then self:Notify(msg) end end)
        text(15,239,"Turret is destructible and can be rebuilt if lost.")
        text(15,254,"Stationary defenses do not count toward unit cap.")
    else
        local editable=false
        text(15,84,"MATCH SETUP: locked after battle starts")
        local function setting(label,y,value,action)
            button(15,y,300,label..": "..tostring(value),editable and "available" or "disabled",function()
                if editable then action() else self:Notify("Setup locked after battle starts") end
            end)
        end
        setting("Starting funds",109,self.settings.startFunds,function()
            local new=self.settings.startFunds==450 and 750 or (self.settings.startFunds==750 and 250 or 450)
            local delta=new-self.settings.startFunds
            if self.teams[0].funds+delta>=0 and self.teams[1].funds+delta>=0 then
                self.teams[0].funds=self.teams[0].funds+delta; self.teams[1].funds=self.teams[1].funds+delta; self.settings.startFunds=new
            else self:Notify("Insufficient unspent funds to lower start") end
        end)
        setting("Base income / sec",136,self.settings.income,function() self.settings.income=({[3]=5,[5]=8,[8]=10,[10]=15,[15]=20,[20]=25,[25]=3})[self.settings.income] or 5 end)
        setting("Team unit cap",163,self.settings.unitCap,function() self.settings.unitCap=({[8]=12,[12]=16,[16]=32,[32]=50,[50]=8})[self.settings.unitCap] or 50 end)
        setting("Outpost bonuses",190,self.settings.outpostBonuses and "ON" or "OFF",function() self.settings.outpostBonuses=not self.settings.outpostBonuses end)
        setting("Call-ins",217,self.settings.callins and "ON" or "OFF",function() self.settings.callins=not self.settings.callins end)
        text(15,250,"Click a setting to cycle it. Changes affect both teams.")
        text(15,266,"Difficulty is chosen in the game setup screen.")
    end
    button(15,348,125,"DEPLOY ("..(cost or 0).." oz)",self:AutoReason(0)=="Ready" and "available" or "disabled",function() local _,msg=self:Deploy(0); if msg~="Batch deployed" then self:Notify(msg) end end)
    button(150,348,100,"AUTO: "..(t.auto and "ON" or "OFF"),t.auto and "selected" or "available",function() t.auto=not t.auto end,true)
    text(260,352,self:AutoReason(0))
    text(15,375,self.message)
    text(15,393,"L/R: next/previous; blue = selected; red = locked",true)
    text(15,407,"The battle continues while this panel is open.")
    self:UIDrawBoxFill(screen,pos(mouse.X-2,mouse.Y-2),pos(mouse.X+2,mouse.Y+2),120)
end
