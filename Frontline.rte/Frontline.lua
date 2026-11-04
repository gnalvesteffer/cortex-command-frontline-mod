-- Frontline balance and roster. All prices are in gold ounces.
local CONFIG = {
-- Keep balance, map, AI, and presentation tuning in this CONFIG object.
    DEPLOY_COOLDOWN_MS = 10000, FORWARD_DEPLOY_COOLDOWN_MS = 20000, -- Shared by manual and automatic deployment.
    START_FUNDS = 450, INCOME_PER_SECOND = 5, BOUNTY = 35,
    TEAM_UNIT_CAP = 50, STARTING_SQUAD_SIZE=3, MAX_SQUAD_SIZE=9, SQUAD_SIZE_RESEARCH=29,
    UNIT_ARMOR_COST = 60, UNIT_ARMOR_HEALTH = 50,
    FORWARD_SHIP_PASSENGERS = 3, FORWARD_LANDING_OFFSET = 150, FORWARD_SHIP_SEPARATION = 170, FORWARD_DROP_HEIGHT = 650,
    GRACE_MS = 15000, OUTPOST_CAPTURE_SECONDS = 8, OUTPOST_INCOME = 2, OUTPOST_RADIUS = 180,
    MINER_GOLD_SCAN_STEP = 24, MINER_CHECK_INTERVAL_MS = 1000, MINER_RESCAN_INTERVAL_MS = 15000, MINER_DIG_DISTANCE = 45,
    economy={incomePerResearchLevel=2,bountyPerResearch=15,outpostResearchCostMultiplier=0.8,callinCooldownMultiplier=0.8},
    researchEffects={
        unitTierByIndex={[4]=1,[5]=2,[6]=3},
        training={basePerception=0.5,perLevel=0.05,maximumPerception=1},
    },
    orders={formationSlots=7,formationSpacing=20,formationCenter=3,arrivalRadiusX=90,arrivalRadiusY=120,waypointOffsetY=20},
    ENEMY_BASE_SUPPORT_EXCLUSION_RADIUS = 600, -- Applied equally to both teams.
    -- Support call-in balance
    CALLIN_STRIKE_COST = 220, CALLIN_STRIKE_COOLDOWN_MS = 45000,
    CALLIN_STRIKE_DELAY_MS = 3000, CALLIN_PRECISION_HEIGHT = 600, CALLIN_PRECISION_SPEED = 60, CALLIN_PRECISION_FLIGHT_MS = 5000, CALLIN_MEDIC_COST = 120,
    CALLIN_MEDIC_COOLDOWN_MS = 30000, CALLIN_MEDIC_DELAY_MS=4000,
    CALLIN_COVER_COST = 140, CALLIN_COVER_COOLDOWN_MS = 40000, CALLIN_COVER_DELAY_MS = 4000,
    CALLIN_MINES_COST = 180, CALLIN_MINES_COOLDOWN_MS = 45000, CALLIN_MINES_DELAY_MS = 4000,
    CALLIN_BOMB_COST = 260, CALLIN_BOMB_COOLDOWN_MS = 55000, CALLIN_BOMB_DELAY_MS = 4000,
    CALLIN_TURRET_COST = 300, CALLIN_TURRET_COOLDOWN_MS = 90000, CALLIN_TURRET_DELAY_MS = 4000,
    CALLIN_ORBITAL_COST = 175, CALLIN_ORBITAL_COOLDOWN_MS = 75000,
    CALLIN_ORBITAL_DELAY_MS = 3000, CALLIN_ORBITAL_SHOTS = 72, CALLIN_ORBITAL_BONUS_SHOTS = 36,
    CALLIN_ORBITAL_DURATION_MS = 5000, CALLIN_ORBITAL_RADIUS = 150,
    CALLIN_ORBITAL_HEIGHT = 350, CALLIN_ORBITAL_SPEED = 150, CALLIN_ORBITAL_SOUND_EVERY = 4,
    CALLIN_SHIELD_COST = 200, CALLIN_SHIELD_COOLDOWN_MS = 60000, CALLIN_JAM_RADIUS = 180,
    CALLIN_BUBBLE_COST=280, CALLIN_BUBBLE_COOLDOWN_MS=75000,
    CALLIN_WEAPON_POD_COST=320, CALLIN_WEAPON_POD_COOLDOWN_MS=60000, CALLIN_WEAPON_POD_DELAY_MS=3000,
    BASE_ARMOR_COST = 200, BASE_ARMOR_HEALTH = 50, BASE_ARMOR_LEVELS = 3,
    BASE_REPAIR_COST = 120, BASE_REPAIR_HEALTH = 50, BASE_TURRET_COST = 350, BASE_TURRET_UPGRADE_COST=650,
    BASE_TURRET_RANGE_MULTIPLIER=1.5, BASE_TURRET_AIM_DISTANCE=30,
    BASE_TOWER_DISTANCE=484, BASE_TOWER_HEIGHT=112, BASE_TURRET_PIN_STRENGTH=100000,
    -- Unit and equipment catalogs
    roster = {
        {name="Coalition Light", actor="Soldier Light", mod="Coalition.rte", price=75, unlock=0, research=1},
        {name="Coalition Heavy", actor="Soldier Heavy", mod="Coalition.rte", price=120, unlock=1, research=4},
        {name="Dummy", actor="Dummy", mod="Dummy.rte", price=30, unlock=2, research=5},
        {name="Browncoat Light", actor="Browncoat", mod="Browncoats.rte", price=145, unlock=3, research=6},
        {name="Gatling Drone", actor="Gatling Drone", mod="Coalition.rte", price=260, unlock=2, research=5, vehicle=true},
        {name="Ronin Bandit", actor="Bandit", mod="Ronin.rte", price=50, unlock=0},
    },
    weapons = {
        {name="Pistol", preset="Pistol", mod="Base.rte", price=5, unlock=0},
        {name="SMG", preset="SMG", mod="Base.rte", price=30, unlock=0, research=7},
        {name="Shotgun", preset="Shotgun", mod="Coalition.rte", price=25, unlock=0, research=8},
        {name="Assault Rifle", preset="Assault Rifle", mod="Coalition.rte", price=45, unlock=0, research=16},
        {name="Sniper Rifle", preset="Sniper Rifle", mod="Coalition.rte", price=70, unlock=0, research=9},
        {name="Missile Launcher", preset="Missile Launcher", mod="Coalition.rte", price=95, unlock=2, research=10},
        {name="Gatling Gun", preset="Gatling Gun", mod="Coalition.rte", price=120, unlock=2},
    },
    research = {
        -- Unit unlocks
        {name="Unit: Coalition Light", price=300, max=1, kind="unit"},
        {name="Income +2/s", price=360, max=10, kind="income"},
        {name="Bounty +15", price=320, max=10, kind="bounty"},
        {name="Unit: Coalition Heavy", price=500, max=1, kind="unit", requires=1},
        {name="Unit: Dummy / Gatling Drone", price=700, max=1, kind="unit", requires=4},
        {name="Unit: Browncoat Light", price=1000, max=1, kind="unit", requires=5},
        
        -- Equipment unlocks
        {name="Equipment: SMG", price=300, max=1, kind="equipment"},
        {name="Equipment: Shotgun", price=340, max=1, kind="equipment"},
        {name="Equipment: Sniper Rifle", price=400, max=1, kind="equipment"},
        {name="Equipment: Missile Launcher", price=600, max=1, kind="equipment"},
        
        -- Support unlocks (multi-level)
        {name="Support: Medic Drone Lv.1", price=400, max=1, kind="support"},
        {name="Support: Medic Drone Lv.2", price=700, max=1, kind="support", requires=11},
        {name="Support: Jammer", price=500, prices={500,800}, max=2, kind="support", requires=22},

        -- Industry
        {name="Industry: Mining squad call-in", price=400, max=1, kind="mining"},

        -- Training and additional equipment
        {name="Training: Perception +5%", price=500, max=10, kind="training"},
        {name="Equipment: Assault Rifle", price=700, max=1, kind="equipment"},
        {name="Equipment: Medikit packs", price=400, max=1, kind="equipment"},
        {name="Equipment: Grenade packs", price=440, max=1, kind="equipment"},
        {name="Equipment: Sidearms", price=480, max=1, kind="equipment"},
        {name="Equipment: Unit armor (+50 HP)", price=600, max=1, kind="equipment"},

        -- Offense escalates from orbital barrage to precision strike to bomb;
        -- defense progresses from cover through mines to a turret.
        {name="Support: Orbital Gatling Barrage", price=600, max=1, kind="support"},
        {name="Support: Cover delivery", price=280, max=1, kind="support"},
        {name="Support: Minefield delivery", price=360, max=1, kind="support", requires=22},
        {name="Support: Orbital Precision Strike", price=800, max=1, kind="support", requires=21},
        {name="Support: Carpet Bomb", price=1000, max=1, kind="support", requires=24},
        {name="Support: Static turret", price=520, max=1, kind="support", requires=23},
        {name="Support: Energy Shield", price=1200, max=1, kind="support", requires=26, requiresAll={{index=13,level=2}}},
        {name="Support: Weapon Cache Pod", price=700, max=1, kind="support", requires=14},
        {name="Squad Size +1", price=500, prices={500,700,900,1100,1300,1500}, max=6, kind="capacity"},
}
}
CONFIG.supportResearch={strike=24,medic=11,cover=22,mines=23,bomb=25,turret=26,orbital=21,shield=13,bubble=27,mining=14,weaponPod=28}
CONFIG.matchSetup={
    defaults={startFunds=CONFIG.START_FUNDS,income=CONFIG.INCOME_PER_SECOND,unitCap=CONFIG.TEAM_UNIT_CAP,outpostBonuses=true,callins=true},
    options={
        startFunds={250,450,750},
        income={3,5,8,10,15,20,25},
        unitCap={8,12,16,32,50},
        toggles={false,true},
    },
}
CONFIG.ai={
    utility={
        defend={base=35,threat=14,ally=-5,defensive=12,pressured=12},
        advance={base=42,neutral=12,enemies=-7,aggressive=10,economicNeutral=8},
        rush={base=30,allPostsHeld=25,aggressive=10},
        intercept={base=100,threat=8},
        heal={base=38,wounded=8},
        offense={base=25,enemies=12,aggressive=12},
        mine={base=40,incomePost=8,economic=25,pressured=-10},
        supply={base=16,ally=4},
        fortify={base=22,threat=10,ally=-2,defensive=12,pressured=8},
        regroup={base=12,strength=8,defensive=10,aggressive=-6},
        deployment={base=30,aggressive=10,defensive=10,economic=-5,costBurden=5,deficit=5},
        research={base=20,economic=10,defensive=2,costBurden=8},
        baseUpgrade={base=24,defensive=10,costBurden=5,damage=35},
    },
    researchPriorities={
        aggressive={3,4,5,6,7,8,9,2,29,10,11,12,13,14,15,16,17},
        defensive={3,10,11,12,6,7,8,9,2,29,13,14,15,16,17,4,5},
        economic={2,1,29,13,3,6,7,8,9,10,11,12,14,15,16,17,4,5},
        balancedPressured={3,4,5,6,7,8,9,2,29,10,11,12,13,14,15,16,17},
        balancedNeutral={3,6,7,8,9,2,29,10,11,12,13,14,15,16,17,4,5},
    },
    researchResponses={infantry={2,4},vehicles={3,6}},
    playerResearchFocus={[1]="infantry",[4]="infantry",[5]="vehicles",[6]="infantry",
        [7]="infantry",[8]="infantry",[9]="infantry",[10]="vehicles",[16]="infantry"},
    researchTargets={repeatable={[1]=true,[2]=true,[13]=true,[29]=true},missile=10,supportFirst=21,supportLast=28},
    roster={roninIndex=6,initialRonins=CONFIG.STARTING_SQUAD_SIZE,selectableCount=5},
    weaponResearch={pistol=1,smg=7,shotgun=8,sniper=9,missile=10,assault=16,sidearms=19,medkits=17,grenades=18,armor=20},
    weaponIndices={pistol=1,smg=2,shotgun=3,assault=4,sniper=5,missile=6},
    strategy={attackGroupSize=6},
    tuning={
        pressureUnitAdvantage=2,
        researchReserve=240,
        baseRepairReserve=240,
        baseTurretReserve=300,
        baseArmorReserve=400,
        highResearchFunds=3000,
        highResearchLevels=10,
        normalResearchLevels=2,
        deploymentReserve=200,
        firstBatchSize=CONFIG.STARTING_SQUAD_SIZE,
        normalBatchMin=3,
        normalBatchRandom=1,
        aggressiveFunds=5000,
        aggressiveBatchMin=4,
        aggressiveBatchRandom=1,
        defensiveBatchMin=2,
        defensiveBatchRandom=1,
        equipmentFunds=1000,
        callinReserve=240,
        threatRadiusMultiplier=2,
        baseRushRadius=800,
        baseRushMinimumStrength=4,
        baseRushClearStrength=2,
        baseDefenseBatchSize=6,
        enemyClusterRadius=120,
        enemyClusterMinimum=2,
        playerDeploymentWindowMs=30000,
        playerRushDeploymentCount=3,
        playerCallinWindowMs=20000,
        playerDeploymentsBeforeFortify=5,
        playerDeploymentsForRushBonus=5,
        rushBonus=4,
        targetTieBreak=0.01,
        woundedMinimum=2,
        enemyPostMinimum=2,
        enemyVehicleThreat=8,
        antiVehicleTier=2,
        fortifyPreference=2,
        turretPriority=4,
        interceptReserve=150,
        brainHealthMargin=25,
        singleLevelResearchTarget=1,
        researchRankPenalty=0.6,
        personalityCount=4,
        baseRushVerticalRadius=300,
        goalSwitchMargin=12,
        postThreatUrgency=80,
        deploymentUrgency=80,
        regroupUtility=45,
        decisionInterval={minimum=1000,base=3000,difficultyScale=30,defaultDifficulty=50},
        emergencyCheckInterval=250,
        tacticalCostBurden=5,
        bubbleProtectionUtility=6,
    },
}
CONFIG.unitSurcharges={
    pistol=10, rocket=95, medikit=45, grenade=45, minerWeapon=25, forwardDeployment=25,
}
CONFIG.supportEffects={
    shieldDurationByLevel={20000,60000,90000},
    medicDronesByLevel={0,1,2},
    miningCost=200,
    miningPinStrength=1000000,
    mineAndCoverDropCount=3,
    orbital={fragments=16},
    weaponPod={count=3,openDelayMs=1000,descentVelocity=45,releaseSpread=30,releaseHorizontalVelocity=10,releaseVerticalVelocity=4},
    bombRun={count=3,targetLead=192,height=400,flightDistance=360,speed=120,
        dropClearance=12,intervalMs=800,horizontalVelocityMultiplier=0,verticalVelocity=20,shipRadiusFallback=50},
    delivery={approachMs=2000,shipRadiusFallback=50,dropClearance=12,releaseSpread=16,releaseVerticalVelocity=10,
        coverHorizontalVelocity=5,otherHorizontalVelocity=8,turretPinStrength=100000,shipPinStrength=1000000,
        medicSpread=36,medicVerticalOffset=45,turretDropOffset=12,miningGroundOffset=8},
    jammerDrawing={segments=24,lineOffset=1,groundOffset=12,verticalRadius=130},
    bubbleShield={duration=30000,radius=180,verticalOffset=90,drawSegments=48},
}
CONFIG.map={
    outposts={
        largeSceneWidth=15000,mediumSceneWidth=10000,
        smallCount=3,mediumCount=5,largeCount=9,
        smallNames={"WEST","CENTER","EAST"},
        bonuses={"Income +2/s","Research -20%","Call-ins -20%"},
        groundProbe=4,structureYOffset=24,
    },
    mining={scanMargin=12,depositMergeVertical=80,verticalDistanceWeight=0.2,verticalDigRange=120},
    baseApproach={
        -- Keep the tunnel floor at ground level alongside the vault opening.
        corridorYOffset=40,
        -- Tunnel A/B footprints are 96/48px wide; centers meet edge-to-edge.
        sections={{distance=340,preset="Tunnel A"},{distance=436,preset="Tunnel A"},{distance=508,preset="Tunnel B"}},
    },
    baseDeployment={edgeOffset=200,slotCount=6,slotSpacing=18,groundOffset=35,positionMargin=120,minimumShipHeight=-50},
    baseOffset=180,groundProbe=2,vaultYOffset=31,brainYOffset=30,
    cover={minimumShipHeight=50,startOffset=650,releaseOffset=350,endOffset=650,minOutpostDistance=180,stepMin=220,stepMax=360,groundProbe=2,
        minerSpawnYOffset=100,
        presets={
            {preset="Zombie Cave Rock",yOffset=0},
            {preset="Zombie Cave Under Rock 1",yOffset=0},
            {preset="Zombie Cave Under Rock 2",yOffset=0},
            {preset="Concrete Barrier",yOffset=-22},
            {preset="Metal Crate Small A FG",yOffset=-22},
        }},
}

-- A right click walks through the same ordered options in reverse.
local function cycleOption(options,current,direction)
    for i,value in ipairs(options) do
        if value==current then return options[(i-1+direction)%#options+1] end
    end
    return options[1]
end
local function copyArray(source)
    local copy={}
    for i,value in ipairs(source) do copy[i]=value end
    return copy
end

local function scoreAIAction(action, personality, pressured)
    local score=action.utility or 0
    local weights=CONFIG.ai.utility[action.kind]
    if not weights then return score end
    score=score+weights.base
    if action.kind=="defend" then
        score=score+action.threats*weights.threat+action.allies*weights.ally
        if personality=="defensive" then score=score+weights.defensive end
        if pressured then score=score+weights.pressured end
    elseif action.kind=="advance" then
        score=score+(action.neutral and weights.neutral or 0)+action.enemies*weights.enemies
        if personality=="aggressive" then score=score+weights.aggressive end
        if personality=="economic" and action.neutral then score=score+weights.economicNeutral end
    elseif action.kind=="rush" then
        if action.allPostsHeld then score=score+weights.allPostsHeld end
        if personality=="aggressive" then score=score+weights.aggressive end
    elseif action.kind=="intercept" then
        score=score+action.threats*weights.threat
    elseif action.kind=="heal" then
        score=score+action.wounded*weights.wounded
    elseif action.kind=="offense" then
        score=score+action.enemies*weights.enemies
        if personality=="aggressive" then score=score+weights.aggressive end
    elseif action.kind=="mine" then
        if action.incomePost then score=score+weights.incomePost end
        if personality=="economic" then score=score+weights.economic end
        if pressured then score=score+weights.pressured end
    elseif action.kind=="supply" then
        score=score+action.allies*weights.ally
    elseif action.kind=="fortify" then
        score=score+action.threats*weights.threat+action.allies*weights.ally
        if personality=="defensive" then score=score+weights.defensive end
        if pressured then score=score+weights.pressured end
    elseif action.kind=="regroup" then
        score=score+action.allies*weights.strength
        if personality=="defensive" then score=score+weights.defensive end
        if personality=="aggressive" then score=score+weights.aggressive end
    elseif action.kind=="deployment" or action.kind=="research" or action.kind=="baseUpgrade" then
        if weights[personality] then score=score+weights[personality] end
        if action.rank then score=score-math.max(0,action.rank-1)*CONFIG.ai.tuning.researchRankPenalty end
        if weights.costBurden and action.cost and action.availableFunds and action.availableFunds>0 then
            score=score-(action.cost/action.availableFunds)*weights.costBurden
        end
        if action.kind=="deployment" then
            score=score+(action.deficit or 0)*weights.deficit+(action.urgent or 0)
        end
        if action.kind=="baseUpgrade" then score=score+(action.damageRatio or 0)*weights.damage end
    end
    if action.kind~="deployment" and action.kind~="research" and action.kind~="baseUpgrade"
        and action.cost and action.availableFunds and action.availableFunds>0 then
        score=score-(action.cost/action.availableFunds)*CONFIG.ai.tuning.tacticalCostBurden
    end
    return score
end

local function chooseAIAction(actions, personality, pressured)
    local best
    for _,action in ipairs(actions) do
        action.score=scoreAIAction(action,personality,pressured)
        if not best or action.score>best.score then best=action end
    end
    return best
end

function Frontline:ChooseAIAction(actions, pressured)
    return chooseAIAction(actions,self.aiPersonality,pressured)
end

-- Each side makes decisions through the same team-bound commander.
local TeamCommander={}
TeamCommander.__index=TeamCommander

local function freshTeam()
    local levels={}
    for i=1,#CONFIG.research do levels[i]=0 end
    return {funds=CONFIG.START_FUNDS, levels=levels, tier=0,
        counts={0,0,0,0,0,CONFIG.STARTING_SQUAD_SIZE}, weapons={1,1,1,1,1,1}, sidearms={}, medkits={}, grenades={}, armor={}, order="Rush", orderTarget=2, forward=0, auto=true, timer=Timer(), lastDeployCooldown=CONFIG.DEPLOY_COOLDOWN_MS, deaths=0, strikeTimer=Timer(), medicTimer=Timer(), coverTimer=Timer(), minesTimer=Timer(), bombTimer=Timer(), turretTimer=Timer(), orbitalTimer=Timer(), shieldTimer=Timer(), bubbleTimer=Timer(), weaponPodTimer=Timer(), baseArmor=0, turretLevel=0, turretID=nil, turret=nil, stats={deployed=0,captures=0,earned=0,brainDamage=0,troopDamage=0}}
end
function Frontline:MaxSquadSize(team)
    return math.min(CONFIG.MAX_SQUAD_SIZE,CONFIG.STARTING_SQUAD_SIZE+(self.teams[team].levels[CONFIG.SQUAD_SIZE_RESEARCH] or 0))
end
CONFIG.researchPages={
    {title="FOUNDATIONS",columns={
        {title="ECONOMY",items={2,3,15,29}},
        {title="INFANTRY",items={1,4,5,6}},
    }},
    {title="ARSENAL",columns={
        {title="WEAPONS",items={7,8,9,10,16}},
        {title="EQUIPMENT",items={17,18,19,20}},
    }},
    {title="SUPPORT NETWORK",columns={
        {title="MEDIC / INDUSTRY",items={11,12,14,28}},
        {title="DEFENSE",items={22,13,23,26,27}},
        {title="OFFENSE",items={21,24,25}},
    }},
}
CONFIG.researchLabels={
    [1]="Coalition Light", [2]="Income +2/s", [3]="Bounty +15",
    [4]="Coalition Heavy", [5]="Dummy / Gatling", [6]="Browncoat Light",
    [7]="SMG", [8]="Shotgun", [9]="Sniper Rifle", [10]="Missile Launcher",
    [11]="MEDIC DRONE I", [12]="MEDIC DRONE II",
    [13]="Support Jammer", [14]="Mining Call-In",
    [15]="Perception +5%", [16]="Assault Rifle",
    [17]="Medikit Packs", [18]="Grenade Packs", [19]="Sidearms", [20]="Unit Armor",
    [21]="Orbital Gatling Barrage", [22]="Cover", [23]="Mines",
    [24]="Orbital Precision Strike", [25]="Carpet Bomb", [26]="Turret",
    [27]="Energy Shield", [28]="Weapon Cache Pod", [29]="Squad Size +1",
}
CONFIG.researchPageOptions={1,2,3}

function Frontline:StartActivity()
    self.originalHudDisabled=FrameMan:IsHudDisabled(0)
    local ok,method=pcall(function() return PrimitiveMan.DrawScreenBoxFillPrimitive end)
    self.screenUI=ok and method~=nil
    self.teams = {[0]=freshTeam(), [1]=freshTeam()}
    self.commanders={}
    for team=0,1 do
        self.commanders[team]=setmetatable({activity=self,team=team},TeamCommander)
    end
    for team=0,1 do self.teams[team].bubbleTimer=Timer() end
    self.playerBehavior={deployments=0,researchPurchases=0,callinsUsed=0,lastDeployTime=0,
        lastDeploymentCount=0,lastResearchIndex=nil,lastCallin=nil,lastCallinTime=nil,researchFocus="",
        recentDeployments={},researchFocusCounts={infantry=0,vehicles=0}}
    if self.SetTeamFunds then for team=0,1 do self:SetTeamFunds(self.teams[team].funds,team) end end
    local defaults=CONFIG.matchSetup.defaults
    self.settings={startFunds=defaults.startFunds,income=defaults.income,unitCap=defaults.unitCap,
        outpostBonuses=defaults.outpostBonuses,callins=defaults.callins}
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
    self.energyShields={}
    self.supportSounds={
        strike=CreateSoundContainer("Frontline Precision Order","Frontline.rte"),
        precisionCannon=CreateSoundContainer("Frontline Precision Cannon","Frontline.rte"),
        bomb=CreateSoundContainer("Frontline Bomb Drop","Frontline.rte"),
        orbital=CreateSoundContainer("Frontline Gatling Order","Frontline.rte"),
        mines=CreateSoundContainer("Frontline Mines Order","Frontline.rte"),
        cover=CreateSoundContainer("Frontline Cover Order","Frontline.rte"),
        weaponPod=CreateSoundContainer("Frontline Cover Order","Frontline.rte"),
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
        self.teams[team].bubbleTimer.ElapsedSimTimeMS=CONFIG.CALLIN_BUBBLE_COOLDOWN_MS
        self.teams[team].weaponPodTimer.ElapsedSimTimeMS=CONFIG.CALLIN_WEAPON_POD_COOLDOWN_MS
    end
    self.matchTimer=Timer()
    self.battleStarted=false
    self.setupStep=1
    self.outposts={}
    self:ScanGoldSites()
    local outpostConfig=CONFIG.map.outposts
    local postCount=SceneMan.SceneWidth>=outpostConfig.largeSceneWidth and outpostConfig.largeCount
        or (SceneMan.SceneWidth>=outpostConfig.mediumSceneWidth and outpostConfig.mediumCount or outpostConfig.smallCount)
    local names=postCount==outpostConfig.smallCount and outpostConfig.smallNames or nil
    for i=1,postCount do
        local x=SceneMan.SceneWidth*i/(postCount+1)
        local ground=SceneMan:MovePointToGround(Vector(x,0),0,outpostConfig.groundProbe)
        local kind=(i-1)%#outpostConfig.bonuses+1
        self.outposts[i]={name=names and names[i] or ("POST "..i), bonus=outpostConfig.bonuses[kind], kind=kind, owner=-1, progress=0, x=x, groundY=ground.Y}
    end
    -- Native bunker modules are destructible and have open entrances on both sides.
    for _,post in ipairs(self.outposts) do
        local structure=CreateTerrainObject("Tunnel A","Base.rte")
        if structure then
            structure.Pos=Vector(post.x,post.groundY-outpostConfig.structureYOffset)
            SceneMan:AddSceneObject(structure)
        end
    end
    self.noticeTimer=Timer()
    self.aiInterval=math.max(CONFIG.ai.tuning.decisionInterval.minimum,
        CONFIG.ai.tuning.decisionInterval.base-(self.Difficulty or CONFIG.ai.tuning.decisionInterval.defaultDifficulty)*CONFIG.ai.tuning.decisionInterval.difficultyScale)
    self.tab="Setup"
    for team=0,1 do self.teams[team].timer.ElapsedSimTimeMS=math.max(CONFIG.DEPLOY_COOLDOWN_MS,CONFIG.FORWARD_DEPLOY_COOLDOWN_MS) end
    -- Record the ground before placing bunker modules, which can themselves
    -- be hit by a downward terrain probe.
    self.baseGround={}
    for team=0,1 do
        local baseX=team==0 and CONFIG.map.baseOffset or SceneMan.SceneWidth-CONFIG.map.baseOffset
        self.baseGround[team]=SceneMan:MovePointToGround(Vector(baseX,0),0,CONFIG.map.groundProbe).Y
    end
    -- Place mirrored, destructible bunker modules before spawning the brains.
    -- The vault's open end faces the battlefield and its floor meets the ground.
    for team=0,1 do
        local vault=team==0 and CreateTerrainObject("Frontline Mirrored Brain Vault", "Frontline.rte") or CreateTerrainObject("Brain Vault", "Base.rte")
        if vault then
            vault.Pos=Vector(team==0 and CONFIG.map.baseOffset or SceneMan.SceneWidth-CONFIG.map.baseOffset, self.baseGround[team]-CONFIG.map.vaultYOffset)
            vault.Team=team
            SceneMan:AddSceneObject(vault)
        end
    end
    -- Mirror corridor modules along the base approach. The upper Tunnel A
    -- room's outward edge meets the Tunnel B exit; its turret faces the field.
    for team=0,1 do
        local sections=CONFIG.map.baseApproach.sections
        for _,section in ipairs(sections) do
            local corridor=CreateTerrainObject(section.preset,"Base.rte")
            if corridor then
                local x=team==0 and section.distance or SceneMan.SceneWidth-section.distance
                corridor.Pos=Vector(x,self.baseGround[team]-CONFIG.map.baseApproach.corridorYOffset)
                corridor.Team=team
                corridor.HFlipped=team==0
                SceneMan:AddSceneObject(corridor)
            end
        end
        local upper=CreateTerrainObject("Tunnel A","Base.rte")
        if upper then
            local x=team==0 and CONFIG.BASE_TOWER_DISTANCE or SceneMan.SceneWidth-CONFIG.BASE_TOWER_DISTANCE
            upper.Pos=Vector(x,self.baseGround[team]-CONFIG.BASE_TOWER_HEIGHT)
            upper.Team=team
            upper.HFlipped=team==0
            SceneMan:AddSceneObject(upper)
        end
    end
    self.brains = {}
    for team=0,1 do
        local brain=CreateAHuman("Brain Robot", "Base.rte")
        brain.Team=team
        brain.Pos=Vector(team==0 and CONFIG.map.baseOffset or SceneMan.SceneWidth-CONFIG.map.baseOffset, self.baseGround[team]-CONFIG.map.brainYOffset)
        brain.HFlipped=team==1
        local weapon=CreateHDFirearm("Gatling Gun","Coalition.rte")
        if weapon then brain:AddInventoryItem(weapon) end
        brain.AIMode=Actor.AIMODE_SENTRY
        MovableMan:AddActor(brain)
        self.brains[team]=brain
    end
    -- Space randomized cover between the bases, leaving their spawn lanes clear.
    -- Ground level is sampled from the scene so cover follows the rolling terrain.
    local cover=CONFIG.map.cover
    local x=cover.startOffset
    while x<SceneMan.SceneWidth-cover.endOffset do
        local entry=cover.presets[math.random(#cover.presets)]
        local tooClose=false
        for _,post in ipairs(self.outposts) do
            if math.abs(post.x-x)<cover.minOutpostDistance then tooClose=true; break end
        end
        local object=not tooClose and CreateTerrainObject(entry.preset,"Base.rte") or nil
        if object then
            local ground=SceneMan:MovePointToGround(Vector(x,0),0,cover.groundProbe)
            object.Pos=ground+Vector(0,entry.yOffset)
            SceneMan:AddSceneObject(object)
        end
        x=x+math.random(cover.stepMin,cover.stepMax)
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
    self.aiEmergencyTimer=Timer()
    self.aiUrgentBaseActive=false
    self.aiUrgentPostActive=false
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
    for x=CONFIG.map.mining.scanMargin,SceneMan.SceneWidth-CONFIG.map.mining.scanMargin,CONFIG.MINER_GOLD_SCAN_STEP do
        local hit=self:GoldAtColumn(x)
        if hit then
            if previous and x-previous.lastX<=CONFIG.MINER_GOLD_SCAN_STEP and math.abs(hit.Y-previous.y)<CONFIG.map.mining.depositMergeVertical then
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
                local distance=math.abs(hit.X-actor.Pos.X)+math.abs(hit.Y-actor.Pos.Y)*CONFIG.map.mining.verticalDistanceWeight
                if not bestDistance or distance<bestDistance then best,bestDistance=site,distance; target=hit end
            end
        end
        state.site=best
    end
    if not target then
        if state.mode~="idle" then actor:ClearAIWaypoints(); actor.AIMode=Actor.AIMODE_SENTRY end
        state.mode="idle"
    elseif math.abs(actor.Pos.X-target.X)<=CONFIG.MINER_DIG_DISTANCE and math.abs(actor.Pos.Y-target.Y)<=CONFIG.map.mining.verticalDigRange then
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
    return (team==0 or team==1) and not actor.ToDelete and actor.UniqueID~=self.brains[team].UniqueID
        and actor.UniqueID~=self.teams[team].turretID and (IsAHuman(actor) or IsACrab(actor))
end

function TeamCommander:BaseUpgrade(kind)
    local team=self.team
    local self=self.activity
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
    elseif kind=="turret" or kind=="turretUpgrade" then
        local current=t.turret
        local active=current and MovableMan:IsActor(current) and (not current.Health or current.Health>0)
        local upgrading=kind=="turretUpgrade"
        if upgrading then
            if t.turretLevel>=2 then return false,"Base turret already upgraded" end
            if not active then return false,"Build a Gatling turret first" end
            cost=CONFIG.BASE_TURRET_UPGRADE_COST
        else
            if active then return false,"Base turret already active" end
            cost=CONFIG.BASE_TURRET_COST
        end
        if t.funds<cost then return false,"Not enough funds" end
        local upgraded=upgrading or (t.turretLevel>=2)
        local turret
        if upgraded then turret=CreateACrab("Frontline HE Turret","Frontline.rte")
        else turret=CreateACrab("Gatling Turret","Coalition.rte") end
        if not turret then return false,"Turret preset unavailable" end
        turret.Team=team
        local x=team==0 and CONFIG.BASE_TOWER_DISTANCE or SceneMan.SceneWidth-CONFIG.BASE_TOWER_DISTANCE
        turret.Pos=Vector(x,self.baseGround[team]-CONFIG.BASE_TOWER_HEIGHT)
        turret.HFlipped=team==1
        turret.AIMode=Actor.AIMODE_SENTRY
        turret.AimDistance=CONFIG.BASE_TURRET_AIM_DISTANCE*(upgraded and CONFIG.BASE_TURRET_RANGE_MULTIPLIER or 1)
        turret.PinStrength=CONFIG.BASE_TURRET_PIN_STRENGTH
        if current and MovableMan:IsActor(current) then current.ToDelete=true end
        t.turretLevel=upgraded and 2 or 1
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
            local training=CONFIG.researchEffects.training
            actor.Perceptiveness=math.min(training.maximumPerception,training.basePerception+training.perLevel*(self.teams[passenger.team].levels[15] or 0))
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
        if n>0 and t.armor[i] and (t.levels[20] or 0)==0 then return nil,nil,"Unit armor is locked" end
        local extra=t.armor[i] and CONFIG.UNIT_ARMOR_COST or 0
        if not entry.vehicle and not entry.miner then
            local sidearm=t.sidearms[i] or 0
            if n>0 and sidearm>0 and (t.levels[19] or 0)==0 then return nil,nil,"Sidearms are locked" end
            if n>0 and sidearm==2 and (t.levels[10] or 0)==0 then return nil,nil,"Rocket sidearm is locked" end
            if n>0 and t.medkits[i] and (t.levels[17] or 0)==0 then return nil,nil,"Medikits are locked" end
            if n>0 and t.grenades[i] and (t.levels[18] or 0)==0 then return nil,nil,"Grenades are locked" end
            extra=extra+(sidearm==1 and CONFIG.unitSurcharges.pistol or (sidearm==2 and CONFIG.unitSurcharges.rocket or 0))
                +(t.medkits[i] and CONFIG.unitSurcharges.medikit or 0)+(t.grenades[i] and CONFIG.unitSurcharges.grenade or 0)
        end
        cost=cost+n*(entry.price+(entry.vehicle and 0 or (entry.miner and CONFIG.unitSurcharges.minerWeapon or weapon.price))+extra+(t.forward>0 and CONFIG.unitSurcharges.forwardDeployment or 0))
    end
    if count>self:MaxSquadSize(team) then return nil,nil,"Squad size limit" end
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
        local spread=(actor.UniqueID%CONFIG.orders.formationSlots-CONFIG.orders.formationCenter)*CONFIG.orders.formationSpacing
        if t.order=="Defend" and t.orderTarget==0 then
            local baseX=self.brains[team].Pos.X
            local baseY=self.baseGround[team]
            actor.AIMode=Actor.AIMODE_GOTO
            actor:AddAISceneWaypoint(Vector(baseX+spread,baseY-CONFIG.orders.waypointOffsetY))
            self.orderAssignments[actor.UniqueID]={order=t.order,base=true,targetX=baseX,targetY=baseY}
        else
            local target=self.outposts[t.orderTarget]
            actor.AIMode=Actor.AIMODE_GOTO
            actor:AddAISceneWaypoint(Vector(target.x+spread,target.groundY-CONFIG.orders.waypointOffsetY))
            self.orderAssignments[actor.UniqueID]={order=t.order,target=t.orderTarget}
        end
    end
end

function TeamCommander:SetOrder(order,target)
    local team=self.team
    local self=self.activity
    if order~="Rush" and order~="Advance" and order~="Defend" then return false,"Unknown order" end
    if type(target)~="number" or target%1~=0 or
        (target==0 and order=="Advance") or (target~=0 and not self.outposts[target]) then
        return false,"Choose a valid order target"
    end
    local t=self.teams[team]
    t.order=order
    t.orderTarget=target
    for actor in MovableMan.Actors do
        if actor.Team==team and not self.inTransit[actor.UniqueID] and self:IsFieldUnit(actor) then
            self:AssignOrder(actor,team)
        end
    end
    if team==0 then
        local destination=target==0 and "BASE" or self.outposts[target].name
        self:Notify("Order: "..order.." "..destination)
    end
    return true,"Order set"
end

function TeamCommander:SetForward(index)
    local activity=self.activity
    if type(index)~="number" or index%1~=0 or (index~=0 and not activity.outposts[index]) then
        return false,"Choose a valid deployment destination"
    end
    activity.teams[self.team].forward=index
    return true,"Deployment destination set"
end

function Frontline:UpdateOrders()
    local alive={}
    for actor in MovableMan.Actors do
        local assignment=self.orderAssignments[actor.UniqueID]
        if assignment then
            alive[actor.UniqueID]=true
            if assignment.base then
                if math.abs(actor.Pos.X-assignment.targetX)<CONFIG.orders.arrivalRadiusX
                    and math.abs(actor.Pos.Y-assignment.targetY)<CONFIG.orders.arrivalRadiusY then
                    actor:ClearAIWaypoints()
                    actor.AIMode=Actor.AIMODE_SENTRY
                    self.orderAssignments[actor.UniqueID]=nil
                end
            else
                local target=self.outposts[assignment.target]
                if math.abs(actor.Pos.X-target.x)<CONFIG.orders.arrivalRadiusX and math.abs(actor.Pos.Y-target.groundY)<CONFIG.orders.arrivalRadiusY then
                    if assignment.order=="Advance" and target.owner~=actor.Team then
                        -- Stay in the capture zone until it is secured.
                        if actor.AIMode~=Actor.AIMODE_SENTRY then
                            actor:ClearAIWaypoints()
                            actor.AIMode=Actor.AIMODE_SENTRY
                        end
                    else
                        actor:ClearAIWaypoints()
                        actor.AIMode=assignment.order=="Defend" and Actor.AIMODE_SENTRY or Actor.AIMODE_BRAINHUNT
                        self.orderAssignments[actor.UniqueID]=nil
                    end
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

function Frontline:RecordPlayerAction(team,kind,detail)
    if team~=0 then return end
    local behavior=self.playerBehavior
    if not behavior then
        behavior={deployments=0,researchPurchases=0,callinsUsed=0,lastDeployTime=0,
            lastDeploymentCount=0,lastResearchIndex=nil,lastCallin=nil,lastCallinTime=nil,researchFocus="",
            recentDeployments={},researchFocusCounts={infantry=0,vehicles=0}}
        self.playerBehavior=behavior
    end
    local now=self.matchTimer.ElapsedSimTimeMS
    if kind=="deployment" then
        behavior.deployments=behavior.deployments+1
        behavior.lastDeployTime=now
        behavior.lastDeploymentCount=detail
        local recent=behavior.recentDeployments or {}
        behavior.recentDeployments=recent
        recent[#recent+1]=now
        while #recent>8 do table.remove(recent,1) end
        while recent[1] and now-recent[1]>CONFIG.ai.tuning.playerDeploymentWindowMs do table.remove(recent,1) end
        behavior.recentDeploymentCount=#recent
    elseif kind=="research" then
        behavior.researchPurchases=behavior.researchPurchases+1
        behavior.lastResearchIndex=detail
        local focus=CONFIG.ai.playerResearchFocus[detail]
        if focus then
            behavior.researchFocusCounts=behavior.researchFocusCounts or {infantry=0,vehicles=0}
            behavior.researchFocusCounts[focus]=behavior.researchFocusCounts[focus]+1
            local other=focus=="infantry" and "vehicles" or "infantry"
            if behavior.researchFocusCounts[focus]>=behavior.researchFocusCounts[other] then behavior.researchFocus=focus end
        end
    elseif kind=="callin" then
        behavior.callinsUsed=behavior.callinsUsed+1
        behavior.lastCallin=detail
        behavior.lastCallinTime=now
    end
end

function TeamCommander:Deploy()
    local team=self.team
    local self=self.activity
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
            local training=CONFIG.researchEffects.training
            actor.Perceptiveness=math.min(training.maximumPerception,training.basePerception+training.perLevel*(t.levels[15] or 0))
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
            local margin=CONFIG.map.baseDeployment.positionMargin
            local x=math.max(margin,math.min(SceneMan.SceneWidth-margin,post.x+direction*(CONFIG.FORWARD_LANDING_OFFSET+(index-1)*CONFIG.FORWARD_SHIP_SEPARATION)))
            ship.Team=team
            ship:SetGoldValue(0)
            self.frontlineCraft[ship.UniqueID]=true
            ship.Pos=Vector(x,math.max(CONFIG.map.baseDeployment.minimumShipHeight,post.groundY-CONFIG.FORWARD_DROP_HEIGHT))
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
            local slot=(t.stats.deployed+i-1)%CONFIG.map.baseDeployment.slotCount
            local deployment=CONFIG.map.baseDeployment
            local x=(team==0 and deployment.edgeOffset or SceneMan.SceneWidth-deployment.edgeOffset)+(team==0 and 1 or -1)*(slot*deployment.slotSpacing)
            actor.Pos=Vector(x,self.baseGround[team]-deployment.groundOffset)
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
    self:RecordPlayerAction(team,"deployment",count)
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
    local research=CONFIG.research[index]
    local level=(t.levels[index] or 0)+1
    local price=research.prices and research.prices[level] or research.price*level
    return self:PostBonusCount(team,2)>0 and math.ceil(price*CONFIG.economy.outpostResearchCostMultiplier) or price
end

function Frontline:TeamIncome(team)
    return self.settings.income+CONFIG.economy.incomePerResearchLevel*self.teams[team].levels[2]+self:PostBonusCount(team,1)*CONFIG.OUTPOST_INCOME
end

function Frontline:CallinCooldown(team,base)
    return self:PostBonusCount(team,3)>0 and math.ceil(base*CONFIG.economy.callinCooldownMultiplier) or base
end

local function researchUnlocked(levels,research)
    if research.requires and (levels[research.requires] or 0)<(research.requiresLevel or 1) then return false end
    for _,requirement in ipairs(research.requiresAll or {}) do
        if (levels[requirement.index] or 0)<(requirement.level or 1) then return false end
    end
    return true
end

local function researchRequirementText(index,level)
    local label=CONFIG.researchLabels[index]
    return level>1 and (label.." Lv."..level) or label
end

function TeamCommander:Research(index)
    local team=self.team
    local self=self.activity
    local t=self.teams[team]
    local r=CONFIG.research[index]
    if not r then return false,"Unknown research" end
    if (t.levels[index] or 0)>=r.max then return false,"Already researched" end
    if not researchUnlocked(t.levels,r) then return false,"Research prerequisite required" end
    local price=self:ResearchCost(team,index)
    if t.funds<price then return false,"Not enough funds" end
    t.funds=t.funds-price
    t.levels[index]=(t.levels[index] or 0)+1
    if r.kind=="unit" then t.tier=math.max(t.tier,CONFIG.researchEffects.unitTierByIndex[index] or 0) end
    if r.kind=="training" then
        for actor in MovableMan.Actors do
            local training=CONFIG.researchEffects.training
            if actor.Team==team and self:IsFieldUnit(actor) then actor.Perceptiveness=math.min(training.maximumPerception,training.basePerception+training.perLevel*t.levels[index]) end
        end
    end
    self:RecordPlayerAction(team,"research",index)
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
    local enemyBaseX=team==0 and SceneMan.SceneWidth-CONFIG.map.baseOffset or CONFIG.map.baseOffset
    return math.abs(x-enemyBaseX)>CONFIG.ENEMY_BASE_SUPPORT_EXCLUSION_RADIUS
end

-- Jammers belong to the deploying team and prevent hostile support orders
-- within their horizontal radius. Friendly support is unaffected.
function Frontline:ShieldBlocks(target,attacker)
    for _,field in ipairs(self.jamFields) do
        local duration=field.duration or CONFIG.supportEffects.shieldDurationByLevel[1]
        if math.abs(field.x-target.x)<=CONFIG.CALLIN_JAM_RADIUS and field.team~=attacker and not field.timer:IsPastSimMS(duration) then return true end
    end
    return false
end

-- Intercept already-fired hostile particles inside active energy bubbles.
function Frontline:UpdateEnergyShields()
    local shields=CONFIG.supportEffects.bubbleShield
    self.energyShields=self.energyShields or {}
    for i=#self.energyShields,1,-1 do
        local field=self.energyShields[i]
        if field.timer:IsPastSimMS(field.duration) then table.remove(self.energyShields,i) end
    end
    if #self.energyShields==0 then return end
    local radiusSquared=shields.radius*shields.radius
    for particle in MovableMan.Particles do
        if particle and not particle.ToDelete and particle.HitsMOs and (particle.Team or -1)>=0 then
            for _,field in ipairs(self.energyShields) do
                if particle.Team~=field.team then
                    local dx=particle.Pos.X-field.x
                    local dy=particle.Pos.Y-field.centerY
                    if dx*dx+dy*dy<=radiusSquared then
                        particle.ToDelete=true
                        break
                    end
                end
            end
        end
    end
end

-- The outline shows the support-jamming area, not a physical shield.
function Frontline:DrawShieldField(target,team)
    local color=team==0 and 215 or 13
    local previousX,previousY
    local config=CONFIG.supportEffects.jammerDrawing
    for i=0,config.segments do
        local angle=math.pi*i/config.segments
        local x=target.x+math.cos(angle)*CONFIG.CALLIN_JAM_RADIUS
        local y=target.groundY-config.groundOffset-math.sin(angle)*config.verticalRadius
        if previousX then
            PrimitiveMan:DrawLinePrimitive(Vector(previousX,previousY),Vector(x,y),color)
            PrimitiveMan:DrawLinePrimitive(Vector(previousX,previousY-1),Vector(x,y-1),color)
        end
        previousX,previousY=x,y
    end
end

function Frontline:DrawBubbleShield(field)
    local config=CONFIG.supportEffects.bubbleShield
    local centerY=field.centerY
    local color=field.team==0 and 215 or 13
    local previousX,previousY
    for i=0,config.drawSegments do
        local angle=2*math.pi*i/config.drawSegments
        local x=field.x+math.cos(angle)*config.radius
        local y=centerY+math.sin(angle)*config.radius
        if previousX then
            PrimitiveMan:DrawLinePrimitive(Vector(previousX,previousY),Vector(x,y),color)
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
    local ground=SceneMan:MovePointToGround(Vector(x,0),0,CONFIG.map.outposts.groundProbe)
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
        local ok,msg=self.commanders[0]:CallIn(self.targeting,target)
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
        elseif kind=="medic" then item=CreateACrab("Medic Drone","Base.rte")
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
    ship.PinStrength=CONFIG.supportEffects.delivery.shipPinStrength
    ship.CanEnterOrbit=false
    ship.AIMode=Actor.AIMODE_SENTRY
    ship:SetControllerMode(Controller.CIM_DISABLED,-1)
    for _,item in ipairs(payload) do ship:AddInventoryItem(item) end
    return ship
end

-- Cache every loaded firearm preset; rare mod weapons are valid pod results too.
function Frontline:CreateWeaponPodPayload()
    if not self.weaponPodPresets then
        local presets,seen={},{}
        if PresetMan and PresetMan.Modules then
            for module in PresetMan.Modules do
                if module.Presets then
                    for preset in module.Presets do
                        if preset.ClassName=="HDFirearm" then
                            local presetName,moduleName=preset:GetModuleAndPresetName()
                            if presetName and moduleName then
                                local key=moduleName.."/"..presetName
                                if not seen[key] then
                                    seen[key]=true
                                    table.insert(presets,{presetName=presetName,moduleName=moduleName})
                                end
                            end
                        end
                    end
                end
            end
        end
        self.weaponPodPresets=presets
    end
    local available={}
    for i,entry in ipairs(self.weaponPodPresets) do available[i]=entry end
    local weapons={}
    for _=1,CONFIG.supportEffects.weaponPod.count do
        local weapon
        while #available>0 and not weapon do
            local entry=table.remove(available,math.random(#available))
            weapon=CreateHDFirearm(entry.presetName,entry.moduleName)
        end
        if not weapon then return nil,"No loaded firearm presets are available" end
        table.insert(weapons,weapon)
    end
    return weapons
end

function Frontline:DropWeaponPod(order)
    local config=CONFIG.supportEffects.weaponPod
    local pod=CreateMOSRotating("Frontline Weapon Pod","Frontline.rte")
    if not pod then return false end
    pod.Pos=Vector(order.target.x,order.startY)
    pod.Vel=Vector(0,config.descentVelocity)
    pod.Team=order.team
    pod:SetNumberValue("WeaponPodOpenDelayMs",config.openDelayMs)
    MovableMan:AddParticle(pod)
    order.pod=pod
    return true
end

function Frontline:ReleaseWeaponPod(order)
    local config=CONFIG.supportEffects.weaponPod
    local ground=SceneMan:MovePointToGround(Vector(order.target.x,0),0,CONFIG.map.outposts.groundProbe)
    for index,weapon in ipairs(order.weapons) do
        local spread=index-(#order.weapons+1)/2
        weapon.Pos=Vector(order.target.x+spread*config.releaseSpread,ground.Y-12)
        weapon.Vel=Vector(spread*config.releaseHorizontalVelocity,config.releaseVerticalVelocity)
        weapon.Team=order.team
        weapon.ToSettle=true
        MovableMan:AddItem(weapon)
    end
    order.pod:SetNumberValue("WeaponPodOpened",1)
    order.pod:GibThis()
end


function TeamCommander:CallIn(kind,index)
    local team=self.team
    local self=self.activity
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
        bubble={timer=t.bubbleTimer,cooldown=CONFIG.CALLIN_BUBBLE_COOLDOWN_MS,cost=CONFIG.CALLIN_BUBBLE_COST},
        mining={timer=t.minesTimer,cooldown=CONFIG.CALLIN_MINES_COOLDOWN_MS,cost=CONFIG.supportEffects.miningCost},
        weaponPod={timer=t.weaponPodTimer,cooldown=CONFIG.CALLIN_WEAPON_POD_COOLDOWN_MS,cost=CONFIG.CALLIN_WEAPON_POD_COST},
    }
    local option=options[kind]
    if not option then return false,"Unknown call-in" end
    local required=CONFIG.supportResearch[kind]
    if required and (t.levels[required] or 0)==0 then
        return false,"Research "..CONFIG.research[required].name.." first"
    end
    if not self:SupportTargetAllowed(team,outpost.x) then return false,"Support restricted near enemy base" end
    if self:ShieldBlocks(outpost,team) then return false,"Enemy jammer blocks support here" end
    local timer,cooldown,cost=option.timer,self:CallinCooldown(team,option.cooldown),option.cost
    if not timer:IsPastSimMS(cooldown) then return false,"Call-in cooling down" end
    if t.funds<cost then return false,"Not enough funds" end
    if kind=="strike" then
        table.insert(self.pendingStrikes,{team=team,index=type(index)=="number" and index or nil,target=outpost,timer=Timer(),projectileTimer=nil})
        self:Notify((team==0 and "Your" or "Enemy").." precision strike inbound at "..outpost.name.."! Friendly fire!")
    elseif kind=="mining" then
        -- Create the miner as cargo without adding it to the world before loading.
        local ground=SceneMan:MovePointToGround(Vector(outpost.x,0),0,CONFIG.map.outposts.groundProbe)
        local startY=math.max(CONFIG.map.cover.minimumShipHeight,ground.Y-CONFIG.map.cover.startOffset)
        local miner=CreateAHuman("Dummy","Dummy.rte")
        if not miner then return false,"Mining unit unavailable" end
        miner.Team=team
        miner.Pos=Vector(outpost.x,ground.Y+CONFIG.map.cover.minerSpawnYOffset)
        miner.PinStrength=CONFIG.supportEffects.miningPinStrength
        table.insert(self.pendingDrops,{team=team,kind="mining",target=outpost,timer=Timer(),delay=CONFIG.CALLIN_MINES_DELAY_MS,cost=cost,miner=miner,count=0,startY=startY,releaseY=math.max(startY,ground.Y-CONFIG.map.cover.releaseOffset)})
        self:Notify((team==0 and "Your" or "Enemy").." mining squad inbound ("..math.ceil(CONFIG.CALLIN_MINES_DELAY_MS/1000).."s)!")
    elseif kind=="shield" then
        -- Shield duration scales with research level
        local shieldLevel=(t.levels[13] or 0)+1
        local duration=CONFIG.supportEffects.shieldDurationByLevel[shieldLevel]

        table.insert(self.jamFields,{x=outpost.x,groundY=outpost.groundY,team=team,timer=Timer(),duration=duration})
        self:Notify((team==0 and "Your" or "Enemy").." support jammer active for "..math.floor(duration/1000).."s")
    elseif kind=="bubble" then
        local config=CONFIG.supportEffects.bubbleShield
        self.energyShields=self.energyShields or {}
        table.insert(self.energyShields,{x=outpost.x,groundY=outpost.groundY,centerY=outpost.groundY-config.verticalOffset,
            radius=config.radius,team=team,timer=Timer(),duration=config.duration})
        self:Notify((team==0 and "Your" or "Enemy").." energy shield active for "..math.floor(config.duration/1000).."s")
    elseif kind=="orbital" then
        local probe=CreateMOPixel("Frontline Orbital Round","Frontline.rte")
        if not probe then return false,"Orbital ammunition unavailable" end
        table.insert(self.pendingOrbitals,{team=team,index=type(index)=="number" and index or nil,target=outpost,timer=Timer(),shots=0,total=CONFIG.CALLIN_ORBITAL_SHOTS+(t.levels[26]>0 and CONFIG.CALLIN_ORBITAL_BONUS_SHOTS or 0),fragments=CONFIG.supportEffects.orbital.fragments,sound=CreateSoundContainer("Frontline Orbital Gatling", "Frontline.rte")})
        self:Notify((team==0 and "Your" or "Enemy").." orbital Gatling cannon targeting "..outpost.name.."! Fragmentation; friendly fire!")
    elseif kind=="bomb" then
        -- Scripted bomb run: dropship flies horizontally, drops 3 bombs at intervals.
        local ship = CreateACDropShip("Dropship MK1","Base.rte")
        if not ship then return false, "Bomb dropship unavailable" end
        ship.Team = team
        ship:SetGoldValue(0)
        -- Three timed releases sweep across the requested target.
        local run=CONFIG.supportEffects.bombRun
        local direction=team==0 and 1 or -1
        local startX=outpost.x-direction*run.targetLead
        local startY=math.max(CONFIG.map.cover.minimumShipHeight,outpost.groundY-run.height)
        ship.Pos=Vector(startX,startY)
        ship.AIMode=Actor.AIMODE_SENTRY
        ship:SetControllerMode(Controller.CIM_DISABLED,-1)
        MovableMan:AddActor(ship)
        table.insert(self.pendingDrops,{team=team,kind="bomb",target=outpost,ship=ship,timer=Timer(),delay=0,cost=cost,
            bombsDropped=0,totalBombs=run.count,flightDistance=run.flightDistance,direction=direction,startX=startX,startY=startY})
        self:Notify((team==0 and "Your" or "Enemy").." bomb run inbound ("..run.count.." bombs)! Friendly fire!")
    elseif kind=="turret" then
        -- Static turret dropped at target location.
        local startY=math.max(CONFIG.map.cover.minimumShipHeight,outpost.groundY-CONFIG.map.cover.startOffset)
        local releaseY=math.max(startY,outpost.groundY-CONFIG.map.cover.releaseOffset)
        table.insert(self.pendingDrops,{team=team,kind="turret",target=outpost,timer=Timer(),
            delay=CONFIG.CALLIN_TURRET_DELAY_MS,cost=cost,count=1,startY=startY,releaseY=releaseY})
        self:Notify((team==0 and "Your" or "Enemy").." turret dropship inbound (4s)!")
    elseif kind=="mines" or kind=="cover" then
        local count=CONFIG.supportEffects.mineAndCoverDropCount
        local startY=math.max(CONFIG.map.cover.minimumShipHeight,outpost.groundY-CONFIG.map.cover.startOffset)
        local releaseY = math.max(startY, outpost.groundY-CONFIG.map.cover.releaseOffset)
        local delay = kind=="mines" and CONFIG.CALLIN_MINES_DELAY_MS or CONFIG.CALLIN_COVER_DELAY_MS
        table.insert(self.pendingDrops, {team=team, kind=kind, target=outpost, timer=Timer(), delay=delay,
            startY=startY, releaseY=releaseY, count=count, cost=cost})
        self:Notify((team==0 and "Your" or "Enemy").." "..kind.." dropship inbound ("..math.ceil(delay/1000).."s)!")
    elseif kind=="medic" then
        local medicLevel=(t.levels[12] or 0)>0 and 3 or 2
        local count=CONFIG.supportEffects.medicDronesByLevel[medicLevel]
        local startY=math.max(CONFIG.map.cover.minimumShipHeight,outpost.groundY-CONFIG.map.cover.startOffset)
        local releaseY=math.max(startY,outpost.groundY-CONFIG.map.cover.releaseOffset)
        table.insert(self.pendingDrops,{team=team,kind="medic",target=outpost,timer=Timer(),
            delay=CONFIG.CALLIN_MEDIC_DELAY_MS,startY=startY,releaseY=releaseY,count=count,cost=cost})
        self:Notify((team==0 and "Your" or "Enemy").." medical robot dropship inbound ("..math.ceil(CONFIG.CALLIN_MEDIC_DELAY_MS/1000).."s)!")
    elseif kind=="weaponPod" then
        local weapons,errorMessage=self:CreateWeaponPodPayload()
        if not weapons then return false,errorMessage end
        local ground=SceneMan:MovePointToGround(Vector(outpost.x,0),0,CONFIG.map.outposts.groundProbe)
        local startY=math.max(CONFIG.map.cover.minimumShipHeight,ground.Y-CONFIG.map.cover.startOffset)
        table.insert(self.pendingDrops,{team=team,kind="weaponPod",target=outpost,timer=Timer(),
            delay=CONFIG.CALLIN_WEAPON_POD_DELAY_MS,startY=startY,cost=cost,weapons=weapons})
        self:Notify((team==0 and "Your" or "Enemy").." weapon cache pod inbound!")
    end
    t.funds=t.funds-cost
    timer:Reset()
    self:RecordPlayerAction(team,"callin",kind)
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
        local field=self.jamFields[i]
        local duration=field.duration or CONFIG.supportEffects.shieldDurationByLevel[1]
        if field.timer:IsPastSimMS(duration) then table.remove(self.jamFields,i) end
    end
    self:UpdateEnergyShields()
    -- Process scripted bomb runs (fly horizontally, drop bombs at intervals).
    -- Bomb runs and weapon pods are physical support deliveries, not cargo ships.
    for i=#self.pendingDrops,1,-1 do
        local order=self.pendingDrops[i]
        if order.kind=="weaponPod" then
            local config=CONFIG.supportEffects.weaponPod
            if not order.timer:IsPastSimMS(order.delay) then
                local remaining=math.max(0,math.ceil((order.delay-order.timer.ElapsedSimTimeMS)/1000))
                self:DrawCallInMarker(order.target,order.team,"WEAPON CACHE POD IN "..remaining.."s")
            elseif not order.pod then
                if self:ShieldBlocks(order.target,order.team) then
                    self.teams[order.team].funds=self.teams[order.team].funds+order.cost
                    self:Notify("Jammer intercepted weapon pod; cost refunded")
                    table.remove(self.pendingDrops,i)
                elseif not self:DropWeaponPod(order) then
                    self.teams[order.team].funds=self.teams[order.team].funds+order.cost
                    self:Notify("Weapon cache pod unavailable; cost refunded")
                    table.remove(self.pendingDrops,i)
                else
                    self:Notify("Weapon cache pod descending at "..order.target.name)
                end
            elseif order.pod.ToDelete then
                self:Notify("Weapon cache pod destroyed before opening")
                table.remove(self.pendingDrops,i)
            elseif self:ShieldBlocks(order.target,order.team) then
                order.pod.ToDelete=true
                self.teams[order.team].funds=self.teams[order.team].funds+order.cost
                self:Notify("Jammer intercepted weapon pod; cost refunded")
                table.remove(self.pendingDrops,i)
            elseif order.pod:GetNumberValue("WeaponPodLanded")>0 then
                if not order.landedTimer then
                    order.landedTimer=Timer()
                    self:DrawCallInMarker(order.target,order.team,"WEAPON CACHE POD OPENING")
                elseif order.landedTimer:IsPastSimMS(config.openDelayMs) then
                    self:ReleaseWeaponPod(order)
                    self:Notify("Weapon cache pod opened at "..order.target.name)
                    table.remove(self.pendingDrops,i)
                end
            end
        elseif order.kind=="bomb" then
            if not MovableMan:IsActor(order.ship) or (order.ship.Health and order.ship.Health<=0) then
                table.remove(self.pendingDrops,i)
            elseif self:ShieldBlocks(order.target,order.team) then
                local refund=(order.bombsDropped or 0)==0
                if refund then self.teams[order.team].funds=self.teams[order.team].funds+order.cost end
                order.ship.PinStrength=0
                order.ship.CanEnterOrbit=true
                order.ship.AIMode=Actor.AIMODE_RETURN
                order.ship:SetControllerMode(Controller.CIM_AI,-1)
                self:Notify(refund and "Jammer intercepted bomb run; cost refunded" or "Jammer intercepted remaining bombs; no refund")
                table.remove(self.pendingDrops,i)
            else
                local run=CONFIG.supportEffects.bombRun
                local elapsed=order.timer.ElapsedSimTimeMS
                local currentX=order.startX+order.direction*(elapsed*run.speed/1000)
                order.ship.Pos=Vector(currentX,order.startY)
                local bombsDue=math.min(order.totalBombs,math.floor(elapsed/run.intervalMs))
                while order.bombsDropped<bombsDue do
                    local item=CreateMOPixel("Bomb Run Bomb","Frontline.rte")
                    if not item then break end
                    item.Pos=Vector(currentX,order.ship.Pos.Y+(order.ship.Radius or run.shipRadiusFallback)+run.dropClearance)
                    item.Vel=Vector(order.direction*run.speed*run.horizontalVelocityMultiplier,run.verticalVelocity)
                    item.Team=order.team
                    MovableMan:AddParticle(item)
                    order.bombsDropped=order.bombsDropped+1
                end
                local passed=order.direction>0 and currentX>order.startX+order.flightDistance
                    or order.direction<0 and currentX<order.startX-order.flightDistance
                if passed or order.bombsDropped>=order.totalBombs then
                    order.ship.PinStrength=0
                    order.ship.CanEnterOrbit=true
                    order.ship.AIMode=Actor.AIMODE_RETURN
                    order.ship:SetControllerMode(Controller.CIM_AI,-1)
                    table.remove(self.pendingDrops,i)
                end
            end
        end
    end
    
    -- Process regular dropship deliveries.
    for i=#self.pendingDrops,1,-1 do
        local order=self.pendingDrops[i]
        if order.kind~="bomb" and order.kind~="weaponPod" then
        local target,ship=order.target,order.ship
        if not order.timer:IsPastSimMS(order.delay) then
            local remaining=math.max(0,math.ceil((order.delay-order.timer.ElapsedSimTimeMS)/1000))
            self:DrawCallInMarker(target,order.team,string.upper(order.kind).." SHIP ARRIVES IN "..remaining.."s")
        elseif not order.arrivalTimer then
            if self:ShieldBlocks(target,order.team) then
                self.teams[order.team].funds=self.teams[order.team].funds+order.cost
                if order.miner then order.miner.ToDelete=true end
                self:Notify("Jammer intercepted "..order.kind.." drop; cost refunded")
                table.remove(self.pendingDrops,i)
            else
                -- Create and add the ship after the countdown, with fresh timers.
                ship=self:CreateSupportShip(order.team,order.kind,order.count,target.x,order.startY)
                if not ship then
                    self.teams[order.team].funds=self.teams[order.team].funds+order.cost
                    if order.miner then order.miner.ToDelete=true end
                    self:Notify("Support dropship unavailable; cost refunded")
                    table.remove(self.pendingDrops,i)
                else
                    order.ship=ship
                    if order.miner then ship:AddInventoryItem(order.miner) end
                    self.frontlineCraft[ship.UniqueID]=true
                    MovableMan:AddActor(ship)
                    order.arrivalTimer=Timer()
                    self:Notify(string.upper(order.kind).." dropship arriving at "..target.name)
                end
            end
        elseif not MovableMan:IsActor(ship) or (ship.Health and ship.Health<=0) then
            if order.miner then order.miner.ToDelete=true end
            self:Notify("Support dropship lost before delivery")
            table.remove(self.pendingDrops,i)
        elseif self:ShieldBlocks(target,order.team) then
            self.teams[order.team].funds=self.teams[order.team].funds+order.cost
            if order.miner then order.miner.ToDelete=true end
            ship.PinStrength=0
            ship.CanEnterOrbit=true
            ship.AIMode=Actor.AIMODE_RETURN
            ship:SetControllerMode(Controller.CIM_AI,-1)
            table.remove(self.pendingDrops,i)
        else
            local delivery=CONFIG.supportEffects.delivery
            local progress=math.min(1,order.arrivalTimer.ElapsedSimTimeMS/delivery.approachMs)
            ship.Pos=Vector(target.x,order.startY+(order.releaseY-order.startY)*progress)
            if not order.arrivalTimer:IsPastSimMS(delivery.approachMs) then
                local remaining=math.max(0,math.ceil((delivery.approachMs-order.arrivalTimer.ElapsedSimTimeMS)/1000))
                self:DrawCallInMarker(target,order.team,string.upper(order.kind).." DROP IN "..remaining.."s")
            else
                -- Opening a hatch early ejects cargo automatically, so wait
                -- until the craft has arrived at the release point.
                if order.kind=="turret" then
                    -- Place turret on ground at target location.
                    local cargo=ship:RemoveInventoryItemAtIndex(0)
                    local item=cargo and ToActor(cargo) or nil
                    if item then
                        local ground=SceneMan:MovePointToGround(Vector(ship.Pos.X,0),0,CONFIG.map.outposts.groundProbe)
                        item.Pos=Vector(ship.Pos.X,ground.Y-delivery.turretDropOffset)
                        item.Team=order.team
                        item.AIMode=Actor.AIMODE_SENTRY
                        item.PinStrength=delivery.turretPinStrength
                        MovableMan:AddActor(item)
                    end
                elseif order.kind=="medic" then
                    local ground=SceneMan:MovePointToGround(Vector(target.x,0),0,CONFIG.map.outposts.groundProbe)
                    local drones={}
                    for n=1,order.count do
                        local cargo=ship:RemoveInventoryItemAtIndex(0)
                        local drone=cargo and ToActor(cargo) or nil
                        if drone then table.insert(drones,drone) end
                    end
                    -- Open after extracting the robots: the engine ejects any
                    -- cargo still aboard as soon as the hatch opens.
                    ship:OpenHatch()
                    for n,drone in ipairs(drones) do
                        local spread=n-(#drones+1)/2
                        drone.Pos=Vector(target.x+spread*delivery.medicSpread,ground.Y-delivery.medicVerticalOffset)
                        drone.Team=order.team
                        drone.HFlipped=order.team==1
                        self:AssignOrder(drone,order.team)
                        MovableMan:AddActor(drone)
                    end
                elseif order.kind=="mining" then
                    -- Release the Dummy miner from the dropship at the target.
                    local cargo=ship:RemoveInventoryItemAtIndex(0)
                    local miner=cargo and ToActor(cargo) or nil
                    ship:OpenHatch()
                    if miner and not miner.Dead then
                        local ground=SceneMan:MovePointToGround(Vector(order.target.x,0),0,CONFIG.map.outposts.groundProbe)
                        miner.Pos=Vector(order.target.x,ground.Y-delivery.miningGroundOffset)
                        miner.PinStrength=0
                        MovableMan:AddActor(miner)
                        self.miners[miner.UniqueID]={}
                        self:UpdateMiner(miner,self.miners[miner.UniqueID])
                    elseif miner then
                        miner.ToDelete=true
                    end
                else
                    local dropY=ship.Pos.Y+(ship.Radius or delivery.shipRadiusFallback)+delivery.dropClearance
                    local items={}
                    for n=1,order.count do
                        local item=ship:RemoveInventoryItemAtIndex(0)
                        if item then table.insert(items,item) end
                    end
                    -- Open only after removing payloads; the engine ejects any
                    -- cargo still aboard as soon as the hatch opens.
                    ship:OpenHatch()
                    for n,item in ipairs(items) do
                        local spread=n-(#items+1)/2
                        item.Pos=Vector(ship.Pos.X+spread*delivery.releaseSpread,dropY)
                        item.Vel=Vector(spread*(order.kind=="cover" and delivery.coverHorizontalVelocity or delivery.otherHorizontalVelocity),delivery.releaseVerticalVelocity)
                        item.Team=order.team
                        MovableMan:AddParticle(item)
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
            -- Keep the base round count spread over the configured duration.
            -- The research upgrade adds more rounds at the same firing cadence.
            local due=math.min(salvo.total,1+math.floor((elapsed-CONFIG.CALLIN_ORBITAL_DELAY_MS)*(CONFIG.CALLIN_ORBITAL_SHOTS-1)/CONFIG.CALLIN_ORBITAL_DURATION_MS))
            while salvo.shots<due do
                if not self:ShieldBlocks(post,salvo.team) then
                    local round=CreateMOPixel("Frontline Orbital Round","Frontline.rte")
                    if round then
                        round:SetNumberValue("FragmentCount",salvo.fragments)
                        local x=math.max(1,math.min(SceneMan.SceneWidth-2,post.x+math.random(-CONFIG.CALLIN_ORBITAL_RADIUS,CONFIG.CALLIN_ORBITAL_RADIUS)))
                        local ground=SceneMan:MovePointToGround(Vector(x,0),0,CONFIG.map.outposts.groundProbe)
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
    self.aiEmergencyTimer:Reset()
    self.aiUrgentBaseActive=false
    self.aiUrgentPostActive=false
    self.tab="Squad"
    self:Notify("Battle starting: 15 second grace period")
end

-- The opponent uses the same team state and purchase/deployment functions as
-- the player. Its difficulty controls decision frequency, not free resources.
function Frontline:CollectAISnapshot(team)
    local posts={}
    for i,post in ipairs(self.outposts) do
        posts[i]={owner=post.owner,progress=post.progress,x=post.x,groundY=post.groundY,
            allies=0,enemies=0,wounded=0,threats=0,projectiles=0,alliedStrength=0,enemyStrength=0}
    end
    local fieldActors={}
    local unitCounts={[0]=0,[1]=0}
    local forceStrength={[0]=0,[1]=0}
    local enemyVehicle=false
    local base=self.brains[team]
    local enemyBaseThreatStrength=0
    local radius=CONFIG.ai.tuning.baseRushRadius
    local vertical=CONFIG.ai.tuning.baseRushVerticalRadius
    for actor in MovableMan.Actors do
        if self:IsFieldUnit(actor) and actor.Health>0 then
            fieldActors[#fieldActors+1]=actor
            unitCounts[actor.Team]=unitCounts[actor.Team]+1
            local vehicle=IsACrab(actor)
            local health=actor.MaxHealth and actor.MaxHealth>0 and math.max(0,math.min(1,actor.Health/actor.MaxHealth)) or 1
            local strength=health*(vehicle and 3 or 1)
            forceStrength[actor.Team]=forceStrength[actor.Team]+strength
            local dx=actor.Pos.X-base.Pos.X
            local dy=actor.Pos.Y-base.Pos.Y
            if actor.Team==0 and dx*dx+dy*dy<=radius*radius and math.abs(dy)<=vertical then
                enemyBaseThreatStrength=enemyBaseThreatStrength+strength
            end
            if actor.Team==0 and vehicle then enemyVehicle=true end
            for i,post in ipairs(self.outposts) do
                local distance=math.abs(actor.Pos.X-post.x)
                if distance<=CONFIG.OUTPOST_RADIUS then
                    if actor.Team==team then
                        posts[i].allies=posts[i].allies+1
                        posts[i].alliedStrength=posts[i].alliedStrength+strength
                        if actor.Health<actor.MaxHealth then posts[i].wounded=posts[i].wounded+1 end
                    else
                        posts[i].enemies=posts[i].enemies+1
                        posts[i].enemyStrength=posts[i].enemyStrength+strength
                    end
                end
                if actor.Team~=team and distance<=CONFIG.OUTPOST_RADIUS*CONFIG.ai.tuning.threatRadiusMultiplier then
                    posts[i].threats=posts[i].threats+1
                end
            end
        end
    end
    for particle in MovableMan.Particles do
        if particle and not particle.ToDelete and particle.HitsMOs and particle.Team~=team then
            for i,post in ipairs(self.outposts) do
                local dx=particle.Pos.X-post.x
                local dy=particle.Pos.Y-post.groundY
                if dx*dx+dy*dy<=CONFIG.OUTPOST_RADIUS*CONFIG.OUTPOST_RADIUS then
                    posts[i].projectiles=posts[i].projectiles+1
                end
            end
        end
    end
    local owned={[0]=0,[1]=0}
    for _,post in ipairs(self.outposts) do
        if post.owner==0 then owned[0]=owned[0]+1 elseif post.owner==1 then owned[1]=owned[1]+1 end
    end
    local urgentPostDefense=false
    for i,post in ipairs(self.outposts) do
        if post.owner==team and posts[i].threats>0 then urgentPostDefense=true; break end
    end
    local brainHealth=base.MaxHealth and base.MaxHealth>0 and base.Health/base.MaxHealth or 1
    local baseRushThreshold=self.teams[team].goal=="defendBase"
        and CONFIG.ai.tuning.baseRushClearStrength or CONFIG.ai.tuning.baseRushMinimumStrength
    local behavior=self.playerBehavior or {}
    local now=self.matchTimer.ElapsedSimTimeMS
    local recent=behavior.recentDeployments or {}
    while recent[1] and now-recent[1]>CONFIG.ai.tuning.playerDeploymentWindowMs do table.remove(recent,1) end
    local playerCallinRecently=behavior.lastCallinTime
        and now-behavior.lastCallinTime<=CONFIG.ai.tuning.playerCallinWindowMs or false
    local deploymentBurst=#recent>=CONFIG.ai.tuning.playerRushDeploymentCount
    return {
        team=team,posts=posts,fieldActors=fieldActors,unitCounts=unitCounts,forceStrength=forceStrength,ownedPosts=owned,
        enemyVehicle=enemyVehicle,baseThreatStrength=enemyBaseThreatStrength,
        urgentBaseDefense=enemyBaseThreatStrength>=baseRushThreshold,
        urgentPostDefense=urgentPostDefense,
        pressured=unitCounts[0]>unitCounts[1]+CONFIG.ai.tuning.pressureUnitAdvantage
            or forceStrength[0]>forceStrength[1]+CONFIG.ai.tuning.pressureUnitAdvantage
            or owned[0]>owned[1] or deploymentBurst or playerCallinRecently,
        funds=self.teams[team].funds,income=self:TeamIncome(team),
        freeUnitSlots=math.max(0,self.settings.unitCap-self:UnitCount(team)),
        brainHealthFraction=brainHealth,now=now,playerDeploymentBurst=deploymentBurst,
        playerDeployments=behavior.deployments or 0,playerCallinsUsed=behavior.callinsUsed or 0,
        playerResearchPurchases=behavior.researchPurchases or 0,
        playerCallinRecently=playerCallinRecently,playerResearchFocus=behavior.researchFocus or "",
    }
end
function Frontline:CheckUrgentAIThreats(team)
    local base=self.brains[team]
    local baseStrength=0
    local postThreat=false
    local radius=CONFIG.ai.tuning.baseRushRadius
    local vertical=CONFIG.ai.tuning.baseRushVerticalRadius
    for actor in MovableMan.Actors do
        if actor.Team==1-team and actor.Health>0 and self:IsFieldUnit(actor) then
            local vehicle=IsACrab(actor)
            local health=actor.MaxHealth and actor.MaxHealth>0 and math.max(0,math.min(1,actor.Health/actor.MaxHealth)) or 1
            if vehicle then health=health*3 end
            local dx=actor.Pos.X-base.Pos.X
            local dy=actor.Pos.Y-base.Pos.Y
            if dx*dx+dy*dy<=radius*radius and math.abs(dy)<=vertical then
                baseStrength=baseStrength+health
            end
            for _,post in ipairs(self.outposts) do
                if post.owner==team and math.abs(actor.Pos.X-post.x)<=CONFIG.OUTPOST_RADIUS*CONFIG.ai.tuning.threatRadiusMultiplier then
                    postThreat=true
                    break
                end
            end
        end
    end
    local threshold=self.teams[team].goal=="defendBase"
        and CONFIG.ai.tuning.baseRushClearStrength or CONFIG.ai.tuning.baseRushMinimumStrength
    return baseStrength>=threshold,postThreat
end

function Frontline:ChooseAIStrategicGoal(snapshot,ai)
    local goals={}
    local allPostsHeld=true
    local rallyTarget=0
    local strongestRally=0
    for i,post in ipairs(self.outposts) do
        local situation=snapshot.posts[i]
        if post.owner~=snapshot.team then
            allPostsHeld=false
            local nearest=math.abs(self.brains[snapshot.team].Pos.X-post.x)
            for _,actor in ipairs(snapshot.fieldActors) do
                if actor.Team==snapshot.team then nearest=math.min(nearest,math.abs(actor.Pos.X-post.x)) end
            end
            local progress=snapshot.team==0 and post.progress or -post.progress
            local distanceValue=math.max(-20,12-nearest/80)
            goals[#goals+1]={goal="advance",kind="advance",target=i,neutral=post.owner==-1,
                enemies=situation.enemies,utility=distanceValue+(post.owner==-1 and 4 or 0)
                    +progress*12+i*CONFIG.ai.tuning.targetTieBreak}
        elseif situation.threats>0 then
            goals[#goals+1]={goal="defendPost",kind="defend",target=i,threats=situation.threats,
                allies=situation.allies,utility=situation.threats*CONFIG.ai.tuning.postThreatUrgency}
        elseif situation.allies>strongestRally then
            strongestRally=situation.allies
            rallyTarget=i
        end
    end
    if snapshot.urgentBaseDefense then
        return {goal="defendBase",kind="defend",target=0,score=math.huge,urgent=true}
    end
    if rallyTarget>0 and strongestRally<CONFIG.ai.strategy.attackGroupSize then
        goals[#goals+1]={goal="regroup",kind="regroup",target=rallyTarget,allies=strongestRally,
            utility=CONFIG.ai.tuning.regroupUtility}
    end
    if allPostsHeld then
        goals[#goals+1]={goal="rush",kind="rush",allPostsHeld=true,
            utility=snapshot.playerDeployments>CONFIG.ai.tuning.playerDeploymentsForRushBonus
                and CONFIG.ai.tuning.rushBonus or 0}
    end
    local chosen=self:ChooseAIAction(goals,snapshot.pressured)
    if not chosen then return {goal="advance",kind="advance",target=1,score=0} end
    local current
    for _,candidate in ipairs(goals) do
        if candidate.goal==ai.goal and candidate.target==(ai.goalTarget or 0) then current=candidate; break end
    end
    if current and current~=chosen and chosen.score<current.score+CONFIG.ai.tuning.goalSwitchMargin then chosen=current end
    return chosen
end

function Frontline:UpdateAI()
    local team=1
    local aiTuning=CONFIG.ai.tuning
    local ai=self.teams[team]
    
    -- Pick a personality at match start for randomized playstyle
    if not self.aiPersonality then
        local roll=math.random(1,CONFIG.ai.tuning.personalityCount)
        if roll==1 then self.aiPersonality="aggressive"
        elseif roll==2 then self.aiPersonality="defensive"
        elseif roll==3 then self.aiPersonality="economic"
        else self.aiPersonality="balanced" end
    end
    
    if not self.playerBehavior then
        self.playerBehavior={deployments=0,researchPurchases=0,callinsUsed=0,lastDeployTime=0,
            lastDeploymentCount=0,lastResearchIndex=nil,lastCallin=nil,lastCallinTime=nil,researchFocus="",
            recentDeployments={},researchFocusCounts={infantry=0,vehicles=0}}
    end
    local snapshot=self:CollectAISnapshot(team)
    self.aiSnapshot=snapshot
    local posts=snapshot.posts
    local enemyVehicle=snapshot.enemyVehicle
    local fieldActors=snapshot.fieldActors
    local urgentBaseDefense=snapshot.urgentBaseDefense
    local pressured=snapshot.pressured
    -- Each decision gets a private priority list before adapting to player research.
    local configured=CONFIG.ai.researchPriorities
    local priorities
    if self.aiPersonality=="aggressive" then priorities=copyArray(configured.aggressive)
    elseif self.aiPersonality=="defensive" then priorities=copyArray(configured.defensive)
    elseif self.aiPersonality=="economic" then priorities=copyArray(configured.economic)
    else priorities=copyArray(pressured and configured.balancedPressured or configured.balancedNeutral) end
    
    -- Counter player's research focus if detected
    local responses=CONFIG.ai.researchResponses
    if snapshot.playerResearchFocus=="infantry" then
        for _,index in ipairs(responses.infantry) do table.insert(priorities,index) end
    elseif snapshot.playerResearchFocus=="vehicles" then
        for _,index in ipairs(responses.vehicles) do table.insert(priorities,index) end
    end
    table.insert(priorities,1,1)
    local supportRange=CONFIG.ai.researchTargets
    for index=supportRange.supportFirst,supportRange.supportLast do priorities[#priorities+1]=index end
    
    -- Compete feasible purchases in one budget choice instead of spending in a fixed category order.
    local investments={}
    local function addInvestment(action)
        action.availableFunds=ai.funds
        investments[#investments+1]=action
    end
    local brain=self.brains[team]
    local targets=CONFIG.ai.researchTargets
    local repairCost=CONFIG.BASE_REPAIR_COST
    if brain.Health<brain.MaxHealth-aiTuning.brainHealthMargin
        and ai.funds>=repairCost+aiTuning.baseRepairReserve then
        addInvestment({kind="baseUpgrade",purchase="repair",cost=repairCost,
            utility=28,damageRatio=(brain.MaxHealth-brain.Health)/brain.MaxHealth})
    end
    local turretActive=ai.turret and MovableMan:IsActor(ai.turret) and (not ai.turret.Health or ai.turret.Health>0)
    if not turretActive and ai.funds>=CONFIG.BASE_TURRET_COST+aiTuning.baseTurretReserve then
        addInvestment({kind="baseUpgrade",purchase="turret",cost=CONFIG.BASE_TURRET_COST,utility=30})
    elseif turretActive and ai.turretLevel<2 and ai.funds>=CONFIG.BASE_TURRET_UPGRADE_COST+aiTuning.baseTurretReserve then
        addInvestment({kind="baseUpgrade",purchase="turretUpgrade",cost=CONFIG.BASE_TURRET_UPGRADE_COST,utility=22})
    end
    local armorCost=CONFIG.BASE_ARMOR_COST*(ai.baseArmor+1)
    if ai.baseArmor<CONFIG.BASE_ARMOR_LEVELS and ai.funds>=armorCost+aiTuning.baseArmorReserve then
        addInvestment({kind="baseUpgrade",purchase="armor",cost=armorCost,utility=14-ai.baseArmor*2})
    end

    local seenResearch={}
    for rank,index in ipairs(priorities) do
        local r=CONFIG.research[index]
        if r and not seenResearch[index] then
            seenResearch[index]=true
            local researchTarget=targets.repeatable[index] and (ai.funds>=aiTuning.highResearchFunds and aiTuning.highResearchLevels or aiTuning.normalResearchLevels)
                or (index==targets.missile and ai.funds>=aiTuning.highResearchFunds and aiTuning.highResearchLevels or aiTuning.singleLevelResearchTarget)
            if researchUnlocked(ai.levels,r) and (ai.levels[index] or 0)<math.min(r.max,researchTarget) then
                local cost=self:ResearchCost(team,index)
                if ai.funds>=cost+aiTuning.researchReserve then
                    local utility=0
                    if r.kind=="income" then utility=math.max(0,8-snapshot.income)*3
                    elseif r.kind=="unit" then utility=14
                    elseif r.kind=="capacity" then utility=snapshot.freeUnitSlots<6 and 8 or 0
                    elseif r.kind=="equipment" and index==targets.missile and enemyVehicle then utility=30
                    end
                    if r.kind=="support" and pressured then utility=utility+5 end
                    if snapshot.urgentBaseDefense or snapshot.urgentPostDefense then utility=utility-15 end
                    addInvestment({kind="research",purchase=index,cost=cost,rank=rank,utility=utility})
                end
            end
        end
    end
    
    -- The AI starts with the same three-unit squad as the player.
    local batchSize=ai.stats.deployed==0 and aiTuning.firstBatchSize or (aiTuning.normalBatchMin+math.random(0,aiTuning.normalBatchRandom))
    if ai.stats.deployed>0 then
        if self.aiPersonality=="aggressive" and ai.funds>aiTuning.aggressiveFunds then
            batchSize=aiTuning.aggressiveBatchMin+math.random(0,aiTuning.aggressiveBatchRandom)
        elseif self.aiPersonality=="defensive" then
            batchSize=aiTuning.defensiveBatchMin+math.random(0,aiTuning.defensiveBatchRandom)
        end
    end
    if urgentBaseDefense and ai.stats.deployed>0 then batchSize=aiTuning.baseDefenseBatchSize end

    ai.counts={}
    for i=1,#CONFIG.roster do ai.counts[i]=0 end
    local squadLimit=math.min(self:MaxSquadSize(team),batchSize,snapshot.freeUnitSlots)
    local selectedCount=0
    if ai.stats.deployed==0 then
        ai.counts[CONFIG.ai.roster.roninIndex]=math.min(CONFIG.ai.roster.initialRonins,squadLimit)
        selectedCount=ai.counts[CONFIG.ai.roster.roninIndex]
    else
        for i,entry in ipairs(CONFIG.roster) do
            if i<=CONFIG.ai.roster.selectableCount and selectedCount<squadLimit
                and entry.unlock<=ai.tier and (not entry.research or (ai.levels[entry.research] or 0)>0) then
                ai.counts[i]=1
                selectedCount=selectedCount+1
            end
        end
    end

    -- Keep every selected weapon researched and available.
    local research=CONFIG.ai.weaponResearch
    local weaponIndices=CONFIG.ai.weaponIndices
    local basic=weaponIndices.pistol
    local weaponChoice=basic
    if enemyVehicle and ai.tier>=aiTuning.antiVehicleTier and (ai.levels[research.missile] or 0)>0 then weaponChoice=weaponIndices.missile
    elseif (ai.levels[research.sniper] or 0)>0 then weaponChoice=weaponIndices.sniper
    elseif (ai.levels[research.assault] or 0)>0 then weaponChoice=weaponIndices.assault
    elseif (ai.levels[research.shotgun] or 0)>0 then weaponChoice=weaponIndices.shotgun
    elseif (ai.levels[research.smg] or 0)>0 then weaponChoice=weaponIndices.smg end
    ai.weapons={weaponChoice,weaponChoice,weaponChoice,weaponChoice,weaponChoice,basic}
    if ai.funds>=aiTuning.equipmentFunds then
        for i,entry in ipairs(CONFIG.roster) do
            if (ai.counts[i] or 0)>0 and (ai.levels[research.armor] or 0)>0 then ai.armor[i]=true end
            if not entry.vehicle and not entry.miner and (ai.counts[i] or 0)>0 then
                ai.sidearms[i]=(ai.levels[research.sidearms] or 0)>0 and (enemyVehicle and (ai.levels[research.missile] or 0)>0 and 2 or 1) or 0
                ai.medkits[i]=(ai.levels[research.medkits] or 0)>0
                ai.grenades[i]=(ai.levels[research.grenades] or 0)>0
            end
        end
    end
    
    local decision=self:ChooseAIStrategicGoal(snapshot,ai)
    local target=decision.target or 0
    local desired
    ai.goal=decision.goal
    ai.goalTarget=target
    ai.goalScore=decision.score
    if decision.goal=="defendBase" then
        desired="Defend"
        ai.orderPhase="assembling"
        ai.attackTarget=nil
        ai.rallyTarget=0
    elseif decision.goal=="defendPost" then
        desired="Defend"
        ai.orderPhase="assembling"
        ai.attackTarget=nil
        ai.rallyTarget=target
    elseif decision.goal=="regroup" then
        desired="Defend"
        ai.orderPhase="assembling"
        ai.attackTarget=nil
        ai.rallyTarget=target
    elseif decision.goal=="advance" then
        desired="Advance"
        ai.orderPhase="attacking"
        ai.attackTarget=target
        ai.rallyTarget=nil
    else
        desired="Rush"
        ai.orderPhase="attacking"
        ai.attackTarget=nil
        ai.rallyTarget=nil
    end
    local commander=self.commanders[team]
    if ai.order~=desired or ai.orderTarget~=target then commander:SetOrder(desired,target) end
    local forward=0
    if not urgentBaseDefense then
        local preferred=ai.orderPhase=="assembling" and ai.rallyTarget or nil
        if preferred and self.outposts[preferred].owner==team and posts[preferred].enemies==0 then
            forward=preferred
        else
            local bestScore=-math.huge
            for i,post in ipairs(self.outposts) do
                if post.owner==team and posts[i].enemies==0 then
                    local score=posts[i].allies
                    if ai.attackTarget then score=score-math.abs(post.x-self.outposts[ai.attackTarget].x)/CONFIG.OUTPOST_RADIUS end
                    if score>bestScore then bestScore=score; forward=i end
                end
            end
        end
    end
    commander:SetForward(forward)
    ai.autoDeploy=false
    if self.battleStarted and self.matchTimer:IsPastSimMS(CONFIG.GRACE_MS)
        and ai.timer:IsPastSimMS(self:DeployCooldown(team)) then
        local cost,count=self:Batch(team)
        if not cost or count==0 or cost>ai.funds-aiTuning.deploymentReserve then
            ai.counts={}
            for i=1,#CONFIG.roster do ai.counts[i]=0 end
            ai.counts[CONFIG.ai.roster.roninIndex]=math.min(CONFIG.ai.roster.initialRonins,self:MaxSquadSize(team),snapshot.freeUnitSlots)
            ai.weapons={1,1,1,1,1,1}
            ai.sidearms={}; ai.medkits={}; ai.grenades={}; ai.armor={}
            cost,count=self:Batch(team)
        end
        if cost and count>0 and cost<=ai.funds-aiTuning.deploymentReserve and count<=snapshot.freeUnitSlots then
            ai.autoDeploy=true
            local deficit=math.max(0,CONFIG.ai.strategy.attackGroupSize-snapshot.unitCounts[team])
                /CONFIG.ai.strategy.attackGroupSize
            addInvestment({kind="deployment",purchase="deploy",cost=cost,utility=20+deficit*20,
                deficit=deficit,urgent=(urgentBaseDefense or snapshot.urgentPostDefense) and aiTuning.deploymentUrgency or 0})
        end
    end
    
    local actions={}
    if self.settings.callins and self.matchTimer:IsPastSimMS(CONFIG.GRACE_MS) then
        -- Only create tactical actions after the same rules used by manual orders say they are feasible.
    local calls={
        strike={cost=CONFIG.CALLIN_STRIKE_COST,cooldown=CONFIG.CALLIN_STRIKE_COOLDOWN_MS,timer=ai.strikeTimer},
        medic={cost=CONFIG.CALLIN_MEDIC_COST,cooldown=CONFIG.CALLIN_MEDIC_COOLDOWN_MS,timer=ai.medicTimer},
        cover={cost=CONFIG.CALLIN_COVER_COST,cooldown=CONFIG.CALLIN_COVER_COOLDOWN_MS,timer=ai.coverTimer},
        mines={cost=CONFIG.CALLIN_MINES_COST,cooldown=CONFIG.CALLIN_MINES_COOLDOWN_MS,timer=ai.minesTimer},
        mining={cost=CONFIG.supportEffects.miningCost,cooldown=CONFIG.CALLIN_MINES_COOLDOWN_MS,timer=ai.minesTimer},
        bomb={cost=CONFIG.CALLIN_BOMB_COST,cooldown=CONFIG.CALLIN_BOMB_COOLDOWN_MS,timer=ai.bombTimer},
        orbital={cost=CONFIG.CALLIN_ORBITAL_COST,cooldown=CONFIG.CALLIN_ORBITAL_COOLDOWN_MS,timer=ai.orbitalTimer},
        shield={cost=CONFIG.CALLIN_SHIELD_COST,cooldown=CONFIG.CALLIN_SHIELD_COOLDOWN_MS,timer=ai.shieldTimer},
        bubble={cost=CONFIG.CALLIN_BUBBLE_COST,cooldown=CONFIG.CALLIN_BUBBLE_COOLDOWN_MS,timer=ai.bubbleTimer},
        turret={cost=CONFIG.CALLIN_TURRET_COST,cooldown=CONFIG.CALLIN_TURRET_COOLDOWN_MS,timer=ai.turretTimer},
        weaponPod={cost=CONFIG.CALLIN_WEAPON_POD_COST,cooldown=CONFIG.CALLIN_WEAPON_POD_COOLDOWN_MS,timer=ai.weaponPodTimer},
    }
    local function addAction(kind,callin,target,context,reserve)
        local option=calls[callin]
        local required=CONFIG.supportResearch[callin]
        local outpost=type(target)=="table" and target or self.outposts[target]
        if option and outpost and (ai.levels[required] or 0)>0
            and ai.funds>=option.cost+(reserve or aiTuning.callinReserve)
            and option.timer:IsPastSimMS(self:CallinCooldown(team,option.cooldown))
            and self:SupportTargetAllowed(team,outpost.x) and not self:ShieldBlocks(outpost,team) then
            context.kind=kind
            context.callin=callin
            context.target=target
            context.cost=option.cost
            context.availableFunds=ai.funds
            actions[#actions+1]=context
        end
    end

    -- Defensive interception protects owned posts before pending hostile fire lands.
    for _,pendingList in ipairs({self.pendingStrikes,self.pendingOrbitals,self.pendingDrops}) do
        for _,pending in ipairs(pendingList) do
            if pending.team~=team and not pending.projectileTimer then
                local target=pending.target or self.outposts[pending.index]
                for _,post in ipairs(self.outposts) do
                    if target and post.owner==team and math.abs(post.x-target.x)<=CONFIG.OUTPOST_RADIUS then
                        addAction("intercept","shield",target,{threats=1},aiTuning.interceptReserve)
                    end
                end
            end
        end
    end
    local minerPresent=false
    for _,actor in ipairs(fieldActors) do
        if actor.Team==team and self.miners[actor.UniqueID] then minerPresent=true; break end
    end
    for _,pending in ipairs(self.pendingDrops) do
        if pending.team==team and pending.kind=="mining" then minerPresent=true; break end
    end
    if not minerPresent and (ai.levels[14] or 0)>0 then
        for i,post in ipairs(self.outposts) do
            if post.owner==team and posts[i].enemies==0 then
                addAction("mine","mining",i,{incomePost=post.kind==1})
                break
            end
        end
    end
    for i,post in ipairs(self.outposts) do
        if posts[i].wounded>=aiTuning.woundedMinimum then
            addAction("heal","medic",i,{wounded=posts[i].wounded})
        end
        if post.owner==team and posts[i].allies>0 and posts[i].projectiles>0 then
            addAction("protect","bubble",i,{threats=posts[i].projectiles,allies=posts[i].allies,utility=aiTuning.bubbleProtectionUtility},aiTuning.interceptReserve)
        end
        if post.owner==team and posts[i].allies>0
            and (posts[i].threats>0 or snapshot.playerDeployments>aiTuning.playerDeploymentsBeforeFortify) then
            local kinds={"cover","mines","turret"}
            for _,kind in ipairs(kinds) do
                addAction("fortify",kind,i,{
                    threats=posts[i].threats,
                    allies=posts[i].allies,
                    utility=(kind==ai.fortifyChoice and aiTuning.fortifyPreference or (kind=="turret" and aiTuning.turretPriority or 0)),
                })
            end
        end
        if post.owner==team and posts[i].allies>0 then
            addAction("supply","weaponPod",i,{allies=posts[i].allies})
        end
        if posts[i].enemies>=aiTuning.enemyPostMinimum and posts[i].allies==0 then
            for choice,kind in ipairs({"strike","bomb","orbital"}) do
                local preference=choice==(ai.offenseChoice or 1) and 2 or 0
                if kind=="orbital" and self.aiPersonality=="aggressive" and self:UnitCount(0)>aiTuning.enemyVehicleThreat then preference=preference+8 end
                addAction("offense",kind,i,{
                    enemies=posts[i].enemies,
                    utility=preference,
                })
            end
        end
    end

    -- Area strikes may also target dense enemy groups outside capture zones.
    local seenClusters={}
    for _,candidate in ipairs(fieldActors) do
        if candidate.Team==0 then
            local enemies,allies=0,0
            for _,actor in ipairs(fieldActors) do
                if math.abs(actor.Pos.X-candidate.Pos.X)<aiTuning.enemyClusterRadius then
                    if actor.Team==0 then enemies=enemies+1 else allies=allies+1 end
                end
            end
            local cluster=math.floor(candidate.Pos.X/aiTuning.enemyClusterRadius)
            if enemies>=aiTuning.enemyClusterMinimum and allies==0 and not seenClusters[cluster] then
                seenClusters[cluster]=true
                local ground=SceneMan:MovePointToGround(Vector(candidate.Pos.X,0),0,4)
                local target={name="enemy concentration",x=candidate.Pos.X,groundY=ground.Y,owner=-1}
                addAction("offense","strike",target,{enemies=enemies})
            end
        end
    end

    end
    for _,investment in ipairs(investments) do actions[#actions+1]=investment end
    while #actions>0 do
        local action=self:ChooseAIAction(actions,pressured)
        for i,candidate in ipairs(actions) do
            if candidate==action then table.remove(actions,i); break end
        end
        local ok,reason
        if action.kind=="deployment" then
            ok,reason=commander:Deploy()
        elseif action.kind=="research" then
            ok,reason=commander:Research(action.purchase)
        elseif action.kind=="baseUpgrade" then
            ok,reason=commander:BaseUpgrade(action.purchase)
        else
            ok,reason=commander:CallIn(action.callin,action.target)
        end
        if ok then
            ai.lastAIAction={kind=action.kind,target=action.target or action.purchase,
                cost=action.cost,score=action.score}
            if action.kind=="offense" then
                local sequence={strike=1,bomb=2,orbital=3}
                ai.offenseChoice=(sequence[action.callin]%3)+1
            elseif action.kind=="fortify" then
                ai.fortifyChoice=action.callin=="mines" and "cover" or "mines"
            end
            return
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
            local bounty=(deaths-t.deaths)*(CONFIG.BOUNTY+CONFIG.economy.bountyPerResearch*(t.levels[3] or 0))
            t.funds=t.funds+bounty
            t.stats.earned=t.stats.earned+bounty
            t.deaths=deaths
        end
        if team==0 and t.auto then self.commanders[team]:Deploy() end
        end
    local aiUpdated=false
    if self.aiEmergencyTimer:IsPastSimMS(CONFIG.ai.tuning.emergencyCheckInterval) then
        self.aiEmergencyTimer:Reset()
        local urgentBase,urgentPost=self:CheckUrgentAIThreats(1)
        local shouldInterrupt=(urgentBase and not self.aiUrgentBaseActive)
            or (urgentPost and not self.aiUrgentPostActive)
        self.aiUrgentBaseActive=urgentBase
        self.aiUrgentPostActive=urgentPost
        if shouldInterrupt then
            self.aiTimer:Reset()
            self:UpdateAI()
            aiUpdated=true
        end
    end
    if not aiUpdated and self.aiTimer:IsPastSimMS(self.aiInterval) then
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
        local duration=field.duration or CONFIG.supportEffects.shieldDurationByLevel[1]
        if not field.timer:IsPastSimMS(duration) then
            self:DrawShieldField(field,field.team)
            local seconds=math.max(0,math.ceil((duration-field.timer.ElapsedSimTimeMS)/1000))
            local label=field.team==0 and "SUPPORT JAMMER " or "ENEMY SUPPORT JAMMER "
            PrimitiveMan:DrawTextPrimitive(Vector(field.x,field.groundY-165),label..seconds.."s",true,1)
        end
    end
    for _,field in ipairs(self.energyShields) do
        if not field.timer:IsPastSimMS(field.duration) then
            self:DrawBubbleShield(field)
            local seconds=math.max(0,math.ceil((field.duration-field.timer.ElapsedSimTimeMS)/1000))
            PrimitiveMan:DrawTextPrimitive(Vector(field.x,field.groundY-165),"ENERGY SHIELD "..seconds.."s",true,1)
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
    local researchDiscount=self:PostBonusCount(0,2)>0 and math.floor((1-CONFIG.economy.outpostResearchCostMultiplier)*100+0.5) or 0
    local supportDiscount=self:PostBonusCount(0,3)>0 and math.floor((1-CONFIG.economy.callinCooldownMultiplier)*100+0.5) or 0
    text(26,"FRONTLINE | TAB: COMMAND | Funds: "..math.floor(t.funds).." +"..income.."/s | Bounty: "..(CONFIG.BOUNTY+CONFIG.economy.bountyPerResearch*(t.levels[3] or 0)))
    text(38,"Batch: "..(count or 0).." / "..(cost or 0).." oz | Units: "..self:UnitCount(0).." / "..self.settings.unitCap.." | Deploy: "..self:AutoReason(0))
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
        self:UIDrawText(0,pos(x+4,y+2),label,#label*7>w-8,0)
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
            local new=cycleOption(CONFIG.matchSetup.options.startFunds,self.settings.startFunds,step)
            local delta=new-self.settings.startFunds
            self.teams[0].funds=self.teams[0].funds+delta
            self.teams[1].funds=self.teams[1].funds+delta
            self.settings.startFunds=new
        end,true)
        button(20,115,300,"BASE INCOME / SEC: "..self.settings.income,function(step) self.settings.income=cycleOption(CONFIG.matchSetup.options.income,self.settings.income,step) end,true)
        button(20,144,300,"TEAM UNIT CAP: "..self.settings.unitCap,function(step) self.settings.unitCap=cycleOption(CONFIG.matchSetup.options.unitCap,self.settings.unitCap,step) end,true)
        button(20,173,300,"OUTPOST BONUSES: "..(self.settings.outpostBonuses and "ON" or "OFF"),function(step) self.settings.outpostBonuses=cycleOption(CONFIG.matchSetup.options.toggles,self.settings.outpostBonuses,step) end,true)
        button(20,202,300,"CALL-INS: "..(self.settings.callins and "ON" or "OFF"),function(step) self.settings.callins=cycleOption(CONFIG.matchSetup.options.toggles,self.settings.callins,step) end,true)
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
        text(x+3,y+1,label,#label*7>w-6)
        if mouse.X>=x and mouse.X<=x+w and mouse.Y>=y and mouse.Y<=y+15 then
            if click then action(1) elseif rightClick and reversible then action(-1) end
        end
    end
    local function adjustUnitCount(index,delta,unlocked)
        if not unlocked then return end
        local current=t.counts[index] or 0
        if delta>0 then
            local _,count=self:Batch(0)
            if not count or count>=self:MaxSquadSize(0) then return end
        end
        t.counts[index]=math.max(0,current+delta)
    end
    self:UIDrawBoxFill(screen,pos(8,8),pos(465,430),245)
    self:UIDrawBox(screen,pos(8,8),pos(465,430),120)
    text(15,14,"FRONTLINE COMMAND  |  TAB: CLOSE",false)
    local cost,count=self:Batch(0)
    local income=self:TeamIncome(0)
    text(15,28,"Funds "..math.floor(t.funds).." oz   +"..income.."/s   Bounty "..(CONFIG.BOUNTY+CONFIG.economy.bountyPerResearch*(t.levels[3] or 0)))
    text(15,40,"Batch "..(count or 0).." / "..(cost or 0).." oz   Units "..self:UnitCount(0).."/"..self.settings.unitCap.."   "..self:AutoReason(0))
    local tabs={"Squad","Research","Support","Base","Battle","Setup"}
    for i,name in ipairs(tabs) do button(15+(i-1)*74,56,70,name,self.tab==name and "selected" or "available",function() self.tab=name end) end
    if self.tab=="Squad" then
        text(15,79,"Select units and weapons. Squad "..(count or 0).."/"..self:MaxSquadSize(0).." (six +1 upgrades to 9).")
        -- Display cheaper Ronin first while keeping stable roster IDs.
        for displayIndex,i in ipairs({6,1,2,3,4,5}) do
            local r=CONFIG.roster[i]
            if math.floor((displayIndex-1)/4)+1==self.rosterPage then
                local y=96+((displayIndex-1)%4)*39
                local unlocked=r.unlock<=t.tier and (not r.research or (t.levels[r.research] or 0)>0)
                text(15,y,r.name.." ("..r.price.." oz)"..(unlocked and "" or " [LOCKED]"))
                button(230,y-2,18,"-",unlocked and "available" or "locked",function()
                    adjustUnitCount(i,-1,unlocked)
                end)
                text(256,y,tostring(t.counts[i] or 0))
                button(275,y-2,18,"+",unlocked and "available" or "locked",function()
                    adjustUnitCount(i,1,unlocked)
                end)
                local weapon=CONFIG.weapons[t.weapons[i] or 6]
                local special=r.vehicle or r.miner
                button(15,y+15,special and 238 or 100,
                    r.vehicle and "Built-in gatling" or (r.miner and "FIXED: Pistol + Light Digger (+25/unit)" or (weapon.name.." +"..weapon.price)),
                    unlocked and weaponUnlocked(t,weapon) and "available" or "locked",function(step)
                        if unlocked and not special then
                            local nextIndex=((t.weapons[i] or 6)-1+step)%#CONFIG.weapons+1
                            while not weaponUnlocked(t,CONFIG.weapons[nextIndex]) do
                                nextIndex=(nextIndex-1+step)%#CONFIG.weapons+1
                            end
                            t.weapons[i]=nextIndex
                        end
                    end,true)
                if not special then
                    local side=t.sidearms[i] or 0
                    button(117,y+15,60,side==0 and "SIDE: -" or (side==1 and "Pistol +10" or "RPG +95"),
                        unlocked and (t.levels[19] or 0)>0 and "available" or "locked",function(step)
                            if unlocked and (t.levels[19] or 0)>0 then
                                local nextSide=(side+step)%3
                                if nextSide==2 and (t.levels[10] or 0)==0 then nextSide=(nextSide+step)%3 end
                                t.sidearms[i]=nextSide
                            end
                        end,true)
                    button(179,y+15,36,t.medkits[i] and "MED X" or "MED",
                        unlocked and (t.levels[17] or 0)>0 and (t.medkits[i] and "selected" or "available") or "locked",
                        function() if unlocked and (t.levels[17] or 0)>0 then t.medkits[i]=not t.medkits[i] end end,true)
                    button(217,y+15,36,t.grenades[i] and "GRN X" or "GRN",
                        unlocked and (t.levels[18] or 0)>0 and (t.grenades[i] and "selected" or "available") or "locked",
                        function() if unlocked and (t.levels[18] or 0)>0 then t.grenades[i]=not t.grenades[i] end end,true)
                end
                button(255,y+15,40,t.armor[i] and "ARM X" or "ARM",
                    unlocked and (t.levels[20] or 0)>0 and (t.armor[i] and "selected" or "available") or "locked",
                    function() if unlocked and (t.levels[20] or 0)>0 then t.armor[i]=not t.armor[i] end end,true)
            end
        end
        button(310,238,140,"UNITS PAGE "..self.rosterPage.." / 2","available",function(step)
            self.rosterPage=cycleOption({1,2},self.rosterPage,step)
        end,true)
        text(310,80,"ORDERS: all troops")
        for i,order in ipairs({"Rush","Advance","Defend"}) do
            button(310+(i-1)*47,96,45,order,t.order==order and "selected" or "available",function()
                local target=t.orderTarget
                if target==0 and order=="Advance" then target=1 end
                self.commanders[0]:SetOrder(order,target)
            end)
        end
        local deployment=t.forward==0 and "BASE" or self.outposts[t.forward].name
        button(310,119,140,"SPAWN: "..deployment..(t.forward>0 and " (+25/unit)" or ""),"available",function(step)
            self.commanders[0]:SetForward((t.forward+step)%(#self.outposts+1))
        end,true)
        text(310,143,t.order=="Rush" and "RUSH: enemy brain" or ("TARGET: "..(t.orderTarget==0 and "BASE" or self.outposts[t.orderTarget].name)))
        button(310,158,64,"< PREV","available",function()
            local target
            if t.order=="Advance" then target=((t.orderTarget-2)%#self.outposts)+1
            else target=(t.orderTarget-1)%(#self.outposts+1) end
            self.commanders[0]:SetOrder(t.order,target)
        end)
        button(381,158,69,"NEXT >","available",function()
            local target
            if t.order=="Advance" then target=(t.orderTarget%#self.outposts)+1
            else target=(t.orderTarget+1)%(#self.outposts+1) end
            self.commanders[0]:SetOrder(t.order,target)
        end)
        text(310,181,"Advance: capture, then attack",true)
        text(310,193,"Defend: capture and hold",true)
        text(310,205,"Forward: +25/unit, "..(CONFIG.FORWARD_DEPLOY_COOLDOWN_MS/1000).."s cooldown",true)
        text(310,217,"MED / GRN: +45 each",true)
        text(310,229,"ARM: +"..CONFIG.UNIT_ARMOR_COST.."/unit",true)
        text(15,266,"SQUAD SIZE: "..self:MaxSquadSize(0).." MAX  |  RESEARCH "..(t.levels[CONFIG.SQUAD_SIZE_RESEARCH] or 0).."/6")
    elseif self.tab=="Research" then
        local page=CONFIG.researchPages[self.researchPage] or CONFIG.researchPages[1]
        text(15,80,"TECH TREE  |  Complete earlier nodes to open connected upgrades.")
        text(15,94,page.title.."  |  Click a node to research.")
        button(350,80,100,"PAGE "..self.researchPage.." / "..#CONFIG.researchPages,"available",function(step)
            self.researchPage=cycleOption(CONFIG.researchPageOptions,self.researchPage,step)
        end,true)
        local columns=#page.columns
        local nodeWidth=columns==3 and 140 or 210
        local columnGap=columns==3 and 150 or 225
        local rowSpacing=43
        local nodePositions={}
        for columnIndex,column in ipairs(page.columns) do
            local x=15+(columnIndex-1)*columnGap
            text(x,109,column.title,false)
            for row,index in ipairs(column.items) do
                local r=CONFIG.research[index]
                local y=125+(row-1)*rowSpacing
                local price=self:ResearchCost(0,index)
                local locked=not researchUnlocked(t.levels,r)
                nodePositions[index]={x=x,y=y}
                local function drawConnector(requirement)
                    local parent=nodePositions[requirement.index]
                    if parent then
                        PrimitiveMan:DrawLinePrimitive(pos(parent.x+nodeWidth/2,parent.y+16),pos(x+nodeWidth/2,y),locked and 94 or 120)
                    end
                end
                if r.requires then drawConnector({index=r.requires,level=r.requiresLevel or 1}) end
                for _,requirement in ipairs(r.requiresAll or {}) do drawConnector(requirement) end
                local state=(t.levels[index] or 0)>=r.max and "selected" or (locked and "locked" or (t.funds<price and "disabled" or "available"))
                local label=CONFIG.researchLabels[index].."  "..(t.levels[index] or 0).."/"..r.max.."  "..price.."oz"
                button(x,y,nodeWidth,label,state,function()
                    local _,msg=self.commanders[0]:Research(index)
                    if msg~="Research complete" then self:Notify(msg) end
                end)
                if locked then
                    local requirements={}
                    if r.requires then
                        table.insert(requirements,researchRequirementText(r.requires,r.requiresLevel or 1))
                    end
                    for _,requirement in ipairs(r.requiresAll or {}) do
                        table.insert(requirements,researchRequirementText(requirement.index,requirement.level or 1))
                    end
                    if #requirements>0 then
                        text(x,y+17,"Requires: "..requirements[1],true)
                        for requirementIndex=2,#requirements do
                            text(x,y+29,"and "..requirements[requirementIndex],true)
                        end
                    end
                end
            end
        end
        if columns<3 then text(15,335,"Connectors show prerequisites. Research outposts reduce costs by 20%.") end
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
        text(15,84,"Choose an unlocked support, then click a target on the battlefield.")
        text(15,99,"Research nodes unlock each call-in and show its prerequisites.")
        text(15,116,"OFFENSE",false); text(165,116,"DEFENSE",false); text(315,116,"PERSONNEL",false)
        local function supportOption(kind,label,cost,timer,cooldown,x,y)
            local required=CONFIG.supportResearch[kind]
            local unlocked=(t.levels[required] or 0)>0
            local seconds=math.max(0,math.ceil((self:CallinCooldown(0,cooldown)-timer.ElapsedSimTimeMS)/1000))
            local status=not unlocked and "LOCKED" or (seconds>0 and (seconds.."s") or "READY")
            local state=not unlocked and "locked" or (seconds==0 and t.funds>=cost and "available" or "disabled")
            button(x,y,140,label,state,function()
                if not unlocked then self:Notify("Research "..CONFIG.research[required].name.." first")
                else self:BeginTargeting(kind) end
            end)
            text(x,y+17,cost.." oz | "..status,true)
            if not unlocked then text(x,y+28,"Requires "..CONFIG.researchLabels[required],true) end
        end
        supportOption("orbital","ORBITAL GATLING BARRAGE",CONFIG.CALLIN_ORBITAL_COST,t.orbitalTimer,CONFIG.CALLIN_ORBITAL_COOLDOWN_MS,15,128)
        supportOption("strike","ORBITAL PRECISION STRIKE",CONFIG.CALLIN_STRIKE_COST,t.strikeTimer,CONFIG.CALLIN_STRIKE_COOLDOWN_MS,15,174)
        supportOption("bomb","CARPET BOMB",CONFIG.CALLIN_BOMB_COST,t.bombTimer,CONFIG.CALLIN_BOMB_COOLDOWN_MS,15,220)
        supportOption("cover","COVER",CONFIG.CALLIN_COVER_COST,t.coverTimer,CONFIG.CALLIN_COVER_COOLDOWN_MS,165,128)
        supportOption("mines","MINES",CONFIG.CALLIN_MINES_COST,t.minesTimer,CONFIG.CALLIN_MINES_COOLDOWN_MS,165,168)
        supportOption("turret","TURRET",CONFIG.CALLIN_TURRET_COST,t.turretTimer,CONFIG.CALLIN_TURRET_COOLDOWN_MS,165,208)
        supportOption("shield","JAMMER",CONFIG.CALLIN_SHIELD_COST,t.shieldTimer,CONFIG.CALLIN_SHIELD_COOLDOWN_MS,165,248)
        supportOption("bubble","ENERGY SHIELD",CONFIG.CALLIN_BUBBLE_COST,t.bubbleTimer,CONFIG.CALLIN_BUBBLE_COOLDOWN_MS,165,288)
        supportOption("medic","MEDIC DRONE",CONFIG.CALLIN_MEDIC_COST,t.medicTimer,CONFIG.CALLIN_MEDIC_COOLDOWN_MS,315,128)
        supportOption("mining","MINING",CONFIG.supportEffects.miningCost,t.minesTimer,CONFIG.CALLIN_MINES_COOLDOWN_MS,315,174)
        supportOption("weaponPod","WEAPON CACHE POD",CONFIG.CALLIN_WEAPON_POD_COST,t.weaponPodTimer,CONFIG.CALLIN_WEAPON_POD_COOLDOWN_MS,315,220)
        text(315,274,"Shield destroys hostile",true)
        text(315,286,"projectiles in its bubble.",true)
        text(315,301,"Jammer blocks enemy",true)
        text(315,313,"strikes, bombs, orbital fire.",true)
    elseif self.tab=="Base" then
        local brain=self.brains[0]
        text(15,84,"BASE DEFENSES")
        text(15,104,"Brain health: "..math.floor(brain.Health).." / "..math.floor(brain.MaxHealth))
        text(15,120,"Armor level: "..t.baseArmor.." / "..CONFIG.BASE_ARMOR_LEVELS)
        local active=t.turret and MovableMan:IsActor(t.turret) and (not t.turret.Health or t.turret.Health>0)
        local turretName=not active and "ABSENT" or (t.turretLevel>=2 and "ACTIVE (HE)" or "ACTIVE (GATLING)")
        text(15,136,"Upper-room turret: "..turretName)
        local armorCost=CONFIG.BASE_ARMOR_COST*(t.baseArmor+1)
        button(15,160,300,"ARMOR +50 HP  "..armorCost.." oz",t.baseArmor<CONFIG.BASE_ARMOR_LEVELS and t.funds>=armorCost and "available" or "disabled",function() local ok,msg=self.commanders[0]:BaseUpgrade("armor"); if not ok then self:Notify(msg) end end)
        button(15,185,300,"REPAIR +50 HP  "..CONFIG.BASE_REPAIR_COST.." oz",brain.Health<brain.MaxHealth and t.funds>=CONFIG.BASE_REPAIR_COST and "available" or "disabled",function() local ok,msg=self.commanders[0]:BaseUpgrade("repair"); if not ok then self:Notify(msg) end end)
        if active and t.turretLevel<2 then
            button(15,210,300,"UPGRADE TO HE TURRET  "..CONFIG.BASE_TURRET_UPGRADE_COST.." oz",t.funds>=CONFIG.BASE_TURRET_UPGRADE_COST and "available" or "disabled",function()
                local ok,msg=self.commanders[0]:BaseUpgrade("turretUpgrade"); if not ok then self:Notify(msg) end
            end)
        elseif active then
            button(15,210,300,"HE TURRET  |  RANGE "..math.floor(t.turret.AimDistance),"selected",function() end)
        else
            button(15,210,300,"GATLING TURRET  "..CONFIG.BASE_TURRET_COST.." oz",t.funds>=CONFIG.BASE_TURRET_COST and "available" or "disabled",function()
                local ok,msg=self.commanders[0]:BaseUpgrade("turret"); if not ok then self:Notify(msg) end
            end)
        end
        text(15,239,"Upgraded range: "..(CONFIG.BASE_TURRET_AIM_DISTANCE*CONFIG.BASE_TURRET_RANGE_MULTIPLIER).." (base "..CONFIG.BASE_TURRET_AIM_DISTANCE..").")
        text(15,254,"Stationary defenses do not count toward unit cap.")
    else
        local editable=not self.battleStarted
        text(15,84,editable and "MATCH SETUP: adjustable before battle" or "MATCH SETUP: locked after battle starts")
        local function setting(label,y,value,action,reversible)
            button(15,y,300,label..": "..tostring(value),editable and "available" or "disabled",function(step)
                if editable then action(step) else self:Notify("Setup locked after battle starts") end
            end,reversible)
        end
        setting("Starting funds",109,self.settings.startFunds,function(step)
            local new=cycleOption(CONFIG.matchSetup.options.startFunds,self.settings.startFunds,step)
            local delta=new-self.settings.startFunds
            if self.teams[0].funds+delta>=0 and self.teams[1].funds+delta>=0 then
                self.teams[0].funds=self.teams[0].funds+delta; self.teams[1].funds=self.teams[1].funds+delta; self.settings.startFunds=new
            else self:Notify("Insufficient unspent funds to lower start") end
        end,true)
        setting("Base income / sec",136,self.settings.income,function(step) self.settings.income=cycleOption(CONFIG.matchSetup.options.income,self.settings.income,step) end,true)
        setting("Team unit cap",163,self.settings.unitCap,function(step) self.settings.unitCap=cycleOption(CONFIG.matchSetup.options.unitCap,self.settings.unitCap,step) end,true)
        setting("Outpost bonuses",190,self.settings.outpostBonuses and "ON" or "OFF",function(step) self.settings.outpostBonuses=cycleOption(CONFIG.matchSetup.options.toggles,self.settings.outpostBonuses,step) end,true)
        setting("Call-ins",217,self.settings.callins and "ON" or "OFF",function(step) self.settings.callins=cycleOption(CONFIG.matchSetup.options.toggles,self.settings.callins,step) end,true)
        text(15,250,"Click a setting to cycle it. Changes affect both teams.")
        text(15,266,"Difficulty is chosen in the game setup screen.")
    end
    button(15,348,125,"DEPLOY ("..(cost or 0).." oz)",self:AutoReason(0)=="Ready" and "available" or "disabled",function() local _,msg=self.commanders[0]:Deploy(); if msg~="Batch deployed" then self:Notify(msg) end end)
    button(150,348,100,"AUTO: "..(t.auto and "ON" or "OFF"),t.auto and "selected" or "available",function() t.auto=not t.auto end,true)
    text(260,352,self:AutoReason(0))
    text(15,375,self.message)
    text(15,393,"Cycles: L next / R previous; +/- or arrows: L only.",true)
    text(15,407,"The battle continues while this panel is open.")
    self:UIDrawBoxFill(screen,pos(mouse.X-2,mouse.Y-2),pos(mouse.X+2,mouse.Y+2),120)
end
