-- Frontline balance and roster. All prices are in gold ounces.
local CONFIG = {
    DEPLOY_COOLDOWN_MS = 10000, -- Shared by manual and automatic deployment.
    START_FUNDS = 450, INCOME_PER_SECOND = 5, BOUNTY = 35,
    TEAM_UNIT_CAP = 32, MAX_BATCH = 6,
    GRACE_MS = 15000, OUTPOST_CAPTURE_SECONDS = 8, OUTPOST_INCOME = 2, OUTPOST_RADIUS = 180,
    CALLIN_STRIKE_COST = 220, CALLIN_STRIKE_COOLDOWN_MS = 45000,
    CALLIN_STRIKE_DELAY_MS = 3000, CALLIN_MEDIC_COST = 120,
    CALLIN_MEDIC_COOLDOWN_MS = 30000, CALLIN_HEAL = 35,
    CALLIN_COVER_COST = 140, CALLIN_COVER_COOLDOWN_MS = 40000,
    CALLIN_MINES_COST = 180, CALLIN_MINES_COOLDOWN_MS = 45000,
    CALLIN_BOMB_COST = 260, CALLIN_BOMB_COOLDOWN_MS = 55000,
    CALLIN_ORBITAL_COST = 350, CALLIN_ORBITAL_COOLDOWN_MS = 75000,
    CALLIN_ORBITAL_DELAY_MS = 3000, CALLIN_ORBITAL_SHOTS = 20, CALLIN_ORBITAL_SPACING_MS = 120,
    CALLIN_SHIELD_COST = 200, CALLIN_SHIELD_COOLDOWN_MS = 60000, CALLIN_SHIELD_DURATION_MS = 20000,
    BASE_ARMOR_COST = 200, BASE_ARMOR_HEALTH = 50, BASE_ARMOR_LEVELS = 3,
    BASE_REPAIR_COST = 120, BASE_REPAIR_HEALTH = 50, BASE_TURRET_COST = 350,
    roster = {
        {name="Coalition Light", actor="Soldier Light", mod="Coalition.rte", price=75, unlock=0},
        {name="Coalition Heavy", actor="Soldier Heavy", mod="Coalition.rte", price=120, unlock=1},
        {name="Dummy", actor="Dummy", mod="Dummy.rte", price=105, unlock=2},
        {name="Browncoat Light", actor="Browncoat", mod="Browncoats.rte", price=145, unlock=3},
        {name="Gatling Drone", actor="Gatling Drone", mod="Coalition.rte", price=260, unlock=2, vehicle=true},
    },
    weapons = {
        {name="Assault Rifle", preset="Assault Rifle", mod="Coalition.rte", price=30, unlock=0},
        {name="Shotgun", preset="Shotgun", mod="Coalition.rte", price=45, unlock=1},
        {name="Gatling Gun", preset="Gatling Gun", mod="Coalition.rte", price=80, unlock=2},
        {name="Sniper Rifle", preset="Sniper Rifle", mod="Coalition.rte", price=65, unlock=1, research=6},
        {name="Missile Launcher", preset="Missile Launcher", mod="Coalition.rte", price=95, unlock=2, research=7},
    },
    research = {
        {name="Income +2/s", price=180, max=5, kind="income"},
        {name="Bounty +15", price=160, max=5, kind="bounty"},
        {name="Infantry: Heavy / Shotgun", price=200, max=1, kind="tier", tier=1},
        {name="Faction: Dummy / Gatling", price=350, max=1, kind="tier", tier=2},
        {name="Faction: Browncoat", price=500, max=1, kind="tier", tier=3},
        {name="Equipment: Sniper Rifle", price=180, max=1, kind="equipment", requires=1},
        {name="Equipment: Missile Launcher", price=260, max=1, kind="equipment", requires=2},
        {name="Support: More cover / mines", price=250, max=1, kind="support", requires=1},
        {name="Support: Longer orbital burst", price=350, max=1, kind="support", requires=2},
    }
}

local function freshTeam()
    return {funds=CONFIG.START_FUNDS, levels={0,0,0,0,0,0,0,0,0}, tier=0,
        counts={2,0,0,0,0}, weapons={1,1,1,1,1}, order="Rush", orderTarget=2, forward=0, auto=false, timer=Timer(), deaths=0, preset="Custom", strikeTimer=Timer(), medicTimer=Timer(), coverTimer=Timer(), minesTimer=Timer(), bombTimer=Timer(), orbitalTimer=Timer(), shieldTimer=Timer(), baseArmor=0, turretID=nil, turret=nil, stats={deployed=0,captures=0,earned=0,brainDamage=0,troopDamage=0}}
end

function Frontline:StartActivity()
    self.originalHudDisabled=FrameMan:IsHudDisabled(0)
    local ok,method=pcall(function() return PrimitiveMan.DrawScreenBoxFillPrimitive end)
    self.screenUI=ok and method~=nil
    self.teams = {[0]=freshTeam(), [1]=freshTeam()}
    self.settings={startFunds=CONFIG.START_FUNDS,income=CONFIG.INCOME_PER_SECOND,unitCap=CONFIG.TEAM_UNIT_CAP,outpostBonuses=true,callins=true}
    self.teams[1].auto = true
    self.callinTarget=2
    self.orderAssignments={}
    self.pendingStrikes={}
    self.pendingOrbitals={}
    for team=0,1 do
        self.teams[team].strikeTimer.ElapsedSimTimeMS=CONFIG.CALLIN_STRIKE_COOLDOWN_MS
        self.teams[team].medicTimer.ElapsedSimTimeMS=CONFIG.CALLIN_MEDIC_COOLDOWN_MS
        self.teams[team].coverTimer.ElapsedSimTimeMS=CONFIG.CALLIN_COVER_COOLDOWN_MS
        self.teams[team].minesTimer.ElapsedSimTimeMS=CONFIG.CALLIN_MINES_COOLDOWN_MS
        self.teams[team].bombTimer.ElapsedSimTimeMS=CONFIG.CALLIN_BOMB_COOLDOWN_MS
        self.teams[team].orbitalTimer.ElapsedSimTimeMS=CONFIG.CALLIN_ORBITAL_COOLDOWN_MS
        self.teams[team].shieldTimer.ElapsedSimTimeMS=CONFIG.CALLIN_SHIELD_COOLDOWN_MS
    end
    self.matchTimer=Timer()
    self.battleStarted=false
    self.setupStep=1
    self.outposts={}
    for i,name in ipairs({"WEST", "CENTER", "EAST"}) do
        local x=SceneMan.SceneWidth*i/4
        local ground=SceneMan:MovePointToGround(Vector(x,250),0,4)
        self.outposts[i]={name=name, bonus=({"Income +2/s", "Research -20%", "Call-ins -20%"})[i], owner=-1, progress=0, x=x, groundY=ground.Y}
    end
    -- A small fortified communications post marks each capture zone. Its
    -- central passage is open; low cover is confined to the outer edges.
    for _,post in ipairs(self.outposts) do
        local structure=CreateTerrainObject("Frontline Outpost Structure","Frontline.rte")
        if structure then
            structure.Pos=Vector(post.x,post.groundY)
            SceneMan:AddSceneObject(structure)
        end
    end
    self.noticeTimer=Timer()
    self.aiInterval=math.max(2000,6000-(self.Difficulty or 50)*40)
    self.tab="Setup"
    for team=0,1 do self.teams[team].timer.ElapsedSimTimeMS=CONFIG.DEPLOY_COOLDOWN_MS end
    -- Place mirrored, destructible bunker modules before spawning the brains.
    -- The vault's open end faces the battlefield and its floor meets the ground.
    for team=0,1 do
        local vault=team==0 and CreateTerrainObject("Frontline Mirrored Brain Vault", "Frontline.rte") or CreateTerrainObject("Brain Vault", "Base.rte")
        if vault then
            vault.Pos=Vector(team==0 and 180 or SceneMan.SceneWidth-180, 569)
            vault.Team=team
            SceneMan:AddSceneObject(vault)
        end
    end
    self.brains = {}
    for team=0,1 do
        local brain=CreateAHuman("Brain Robot", "Base.rte")
        brain.Team=team
        brain.Pos=Vector(team==0 and 180 or SceneMan.SceneWidth-180, 570)
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
            local ground=SceneMan:MovePointToGround(Vector(x,250),0,2)
            object.Pos=ground+Vector(0,entry.yOffset)
            SceneMan:AddSceneObject(object)
        end
        x=x+math.random(220,360)
    end
    self.previousBrainHealth={[0]=self.brains[0].Health or 100,[1]=self.brains[1].Health or 100}
    self.previousTroopHealth={}
    self:SetPlayerBrain(self.brains[0], 0)
    self:SetViewState(Activity.OBSERVE, 0)
    self:SetObservationTarget(Vector(700,560),0)
    self.panel=true
    self.cursorX=200; self.cursorY=100
    self.message="Build a batch and click DEPLOY."
    self.aiTimer=Timer()
    MusicMan:PlayDynamicSong("Generic Battle Music")
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
        turret.Pos=Vector(team==0 and 180 or SceneMan.SceneWidth-180,455)
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
    local count=0
    for actor in MovableMan.Actors do
        if actor.Team==team and self:IsFieldUnit(actor) then count=count+1 end
    end
    return count
end

local function weaponUnlocked(t,weapon)
    return weapon.unlock<=t.tier and (not weapon.research or t.levels[weapon.research]>0)
end

function Frontline:Batch(team)
    local t=self.teams[team]
    local cost, count=0,0
    for i,entry in ipairs(CONFIG.roster) do
        local n=t.counts[i] or 0
        local weapon=CONFIG.weapons[t.weapons[i] or 1]
        if n>0 and not entry.vehicle and not weaponUnlocked(t,weapon) then return nil,nil,"Weapon is locked" end
        if n>0 and entry.unlock>t.tier then return nil,nil,"Unit is locked" end
        count=count+n
        cost=cost+n*(entry.price+(entry.vehicle and 0 or weapon.price)+(t.forward>0 and 25 or 0))
    end
    return cost,count
end

-- Apply the chosen order to a unit; Advance resumes its attack after reaching
-- the post, while Defend becomes a sentry on arrival.
function Frontline:AssignOrder(actor,team)
    local t=self.teams[team]
    actor:ClearAIWaypoints()
    self.orderAssignments[actor.UniqueID]=nil
    if t.order=="Rush" then
        actor.AIMode=Actor.AIMODE_BRAINHUNT
    else
        local target=self.outposts[t.orderTarget]
        actor.AIMode=Actor.AIMODE_GOTO
        actor:AddAISceneWaypoint(Vector(target.x,target.groundY-20))
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

function Frontline:Deploy(team)
    local t=self.teams[team]
    local cost,count,err=self:Batch(team)
    if not cost then return false,err end
    if count==0 then return false,"Select at least one unit" end
    if not self.battleStarted then return false,"Complete match setup first" end
    if t.forward>0 and self.outposts[t.forward].owner~=team then return false,"Forward outpost is not yours" end
    if not self.matchTimer:IsPastSimMS(CONFIG.GRACE_MS) then return false,"Opening grace period" end
    if not t.timer:IsPastSimMS(CONFIG.DEPLOY_COOLDOWN_MS) then return false,"Deployment cooling down" end
    if t.funds<cost then return false,"Not enough funds" end
    if self:UnitCount(team)+count>self.settings.unitCap then return false,"Team unit cap reached" end
    -- Construct the complete batch before charging or adding anything to the world.
    local actors={}
    for i,entry in ipairs(CONFIG.roster) do
        for n=1,(t.counts[i] or 0) do
            local actor=entry.vehicle and CreateACrab(entry.actor,entry.mod) or CreateAHuman(entry.actor,entry.mod)
            local weapon=CONFIG.weapons[t.weapons[i] or 1]
            local gun=not entry.vehicle and CreateHDFirearm(weapon.preset,weapon.mod) or nil
            if not actor or (not entry.vehicle and not gun) then return false,"Missing unit or equipment preset" end
            if gun then actor:AddInventoryItem(gun) end
            actor.Team=team
            actor.HFlipped=team==1
            self:AssignOrder(actor,team)
            table.insert(actors,actor)
        end
    end
    for i,actor in ipairs(actors) do
        if t.forward>0 then
            local post=self.outposts[t.forward]
            local x=post.x+(team==0 and -1 or 1)*(60+(i-1)*32)
            actor.Pos=SceneMan:MovePointToGround(Vector(x,250),actor.Height*0.3,2)
        else
            actor.Pos=Vector((team==0 and 335 or SceneMan.SceneWidth-335)+(team==0 and 1 or -1)*((i-1)*32), 565)
        end
        MovableMan:AddActor(actor)
    end
    t.funds=t.funds-cost
    t.stats.deployed=t.stats.deployed+count
    t.timer:Reset()
    if team==0 then self:Notify("Squad deployed: "..count.." units") end
    return true,"Batch deployed"
end

function Frontline:ResearchCost(team,index)
    local t=self.teams[team]
    local price=CONFIG.research[index].price*(t.levels[index]+1)
    return self.settings.outpostBonuses and self.outposts[2].owner==team and math.ceil(price*0.8) or price
end

function Frontline:TeamIncome(team)
    return self.settings.income+2*self.teams[team].levels[1]+(self.settings.outpostBonuses and self.outposts[1].owner==team and CONFIG.OUTPOST_INCOME or 0)
end

function Frontline:CallinCooldown(team,base)
    return self.settings.outpostBonuses and self.outposts[3].owner==team and math.ceil(base*0.8) or base
end

function Frontline:Research(team,index)
    local t=self.teams[team]
    local r=CONFIG.research[index]
    if t.levels[index]>=r.max then return false,"Already researched" end
    if r.kind=="tier" and r.tier>1 and t.tier<r.tier-1 then return false,"Research the previous tier first" end
    if r.requires and t.tier<r.requires then return false,"Requires earlier infantry or faction research" end
    local price=self:ResearchCost(team,index)
    if t.funds<price then return false,"Not enough funds" end
    t.funds=t.funds-price
    t.levels[index]=t.levels[index]+1
    if r.kind=="tier" then t.tier=r.tier end
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
    if choice=="Rush" then t.counts={4,0,0,0}; t.weapons={1,1,1,1}
    elseif choice=="Assault" then
        t.counts=t.tier>=1 and {1,2,0,0} or {3,0,0,0}
        t.weapons=t.tier>=1 and {1,2,1,1} or {1,1,1,1}
    elseif choice=="Specialist" then
        t.counts=t.tier>=2 and {1,1,1,0} or (t.tier>=1 and {2,1,0,0} or {2,0,0,0})
        t.weapons={t.levels[6]>0 and 4 or 1,t.levels[7]>0 and 5 or (t.tier>=1 and 2 or 1),t.tier>=2 and 3 or 1,1}
    end
    t.preset=choice
end

function Frontline:SaveSquad(team)
    local t=self.teams[team]
    t.savedSquad={counts={},weapons={}}
    for i=1,#CONFIG.roster do
        t.savedSquad.counts[i]=t.counts[i] or 0
        t.savedSquad.weapons[i]=t.weapons[i] or 1
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
    if not t.timer:IsPastSimMS(CONFIG.DEPLOY_COOLDOWN_MS) then return "Cooldown "..math.max(0,math.ceil((CONFIG.DEPLOY_COOLDOWN_MS-t.timer.ElapsedSimTimeMS)/1000)).."s" end
    if t.funds<cost then return "Need "..math.ceil(cost-t.funds).." oz" end
    if self:UnitCount(team)+count>self.settings.unitCap then return "Unit cap" end
    return "Ready"
end

function Frontline:ShieldBlocks(outpost,attacker)
    return outpost.shieldTimer and outpost.shieldTeam~=attacker and not outpost.shieldTimer:IsPastSimMS(CONFIG.CALLIN_SHIELD_DURATION_MS)
end

function Frontline:CallIn(team,kind,index)
    local t=self.teams[team]
    local outpost=self.outposts[index]
    if not outpost then return false,"Choose a valid outpost" end
    if not self.battleStarted then return false,"Complete match setup first" end
    if not self.settings.callins then return false,"Call-ins disabled in setup" end
    if not self.matchTimer:IsPastSimMS(CONFIG.GRACE_MS) then return false,"Call-ins unavailable during grace" end
    local options={
        strike={timer=t.strikeTimer,cooldown=CONFIG.CALLIN_STRIKE_COOLDOWN_MS,cost=CONFIG.CALLIN_STRIKE_COST},
        medic={timer=t.medicTimer,cooldown=CONFIG.CALLIN_MEDIC_COOLDOWN_MS,cost=CONFIG.CALLIN_MEDIC_COST},
        cover={timer=t.coverTimer,cooldown=CONFIG.CALLIN_COVER_COOLDOWN_MS,cost=CONFIG.CALLIN_COVER_COST},
        mines={timer=t.minesTimer,cooldown=CONFIG.CALLIN_MINES_COOLDOWN_MS,cost=CONFIG.CALLIN_MINES_COST},
        bomb={timer=t.bombTimer,cooldown=CONFIG.CALLIN_BOMB_COOLDOWN_MS,cost=CONFIG.CALLIN_BOMB_COST},
        orbital={timer=t.orbitalTimer,cooldown=CONFIG.CALLIN_ORBITAL_COOLDOWN_MS,cost=CONFIG.CALLIN_ORBITAL_COST},
        shield={timer=t.shieldTimer,cooldown=CONFIG.CALLIN_SHIELD_COOLDOWN_MS,cost=CONFIG.CALLIN_SHIELD_COST},
    }
    local option=options[kind]
    if not option then return false,"Unknown call-in" end
    local timer,cooldown,cost=option.timer,self:CallinCooldown(team,option.cooldown),option.cost
    if not timer:IsPastSimMS(cooldown) then return false,"Call-in cooling down" end
    if t.funds<cost then return false,"Not enough funds" end
    if kind=="strike" then
        table.insert(self.pendingStrikes,{team=team,index=index,timer=Timer()})
        self:Notify((team==0 and "Your" or "Enemy").." strike incoming at "..outpost.name.."! Friendly fire!")
    elseif kind=="shield" then
        if outpost.owner~=team then return false,"Shield requires your outpost" end
        outpost.shieldTeam=team
        outpost.shieldTimer=Timer()
        self:Notify(outpost.name.." shield active for 20s")
    elseif kind=="orbital" then
        local probe=CreateMOPixel("Frontline Orbital Round","Frontline.rte")
        if not probe then return false,"Orbital ammunition unavailable" end
        table.insert(self.pendingOrbitals,{team=team,index=index,timer=Timer(),shots=0,total=CONFIG.CALLIN_ORBITAL_SHOTS+(t.levels[9]>0 and 10 or 0)})
        self:Notify((team==0 and "Your" or "Enemy").." orbital cannon targeting "..outpost.name.."!")
    elseif kind=="cover" or kind=="mines" then
        -- Choose spaced positions clear of all actors. Do not charge if no
        -- placement is possible; prepare the entire delivery before placing it.
        local prepared={}
        local offsets={-130,-65,0,65,130}
        for _,dx in ipairs(offsets) do
            local x=outpost.x+dx
            local occupied=false
            for actor in MovableMan.Actors do
                if math.abs(actor.Pos.X-x)<45 then occupied=true; break end
            end
            if not occupied then
                local object
                if kind=="cover" then
                    object=CreateTerrainObject(#prepared%2==0 and "Concrete Barrier" or "Metal Crate Small A FG","Base.rte")
                else
                    object=CreateMOSRotating("Anti Personnel Mine Active","Base.rte")
                end
                if not object then return false,"Delivery preset unavailable" end
                local ground=SceneMan:MovePointToGround(Vector(x,250),0,2)
                object.Pos=ground+Vector(0,kind=="cover" and -22 or -12)
                object.Team=team
                if kind=="mines" then object.Sharpness=team; object.Vel=Vector(0,8) end
                table.insert(prepared,object)
                if #prepared>=(3+(t.levels[8]>0 and 2 or 0)) then break end
            end
        end
        if #prepared==0 then return false,"Area occupied; no safe delivery spots" end
        for _,object in ipairs(prepared) do
            if kind=="cover" then SceneMan:AddSceneObject(object) else MovableMan:AddParticle(object) end
        end
        self:Notify((kind=="cover" and "Cover" or "Mines").." delivered at "..outpost.name.." ("..#prepared..")")
    elseif kind=="bomb" then
        if self:ShieldBlocks(outpost,team) then return false,"Enemy shield blocks bomb" end
        local bomb=CreateTDExplosive("Standard Bomb","Base.rte")
        if not bomb then return false,"Bomb preset unavailable" end
        local ground=SceneMan:MovePointToGround(Vector(outpost.x,250),0,4)
        bomb.Pos=ground+Vector(0,-250)
        bomb.Vel=Vector(0,25)
        bomb.Team=team
        bomb:Activate()
        MovableMan:AddParticle(bomb)
        self:Notify((team==0 and "Your" or "Enemy").." bomb dropped at "..outpost.name.."! Friendly fire!")
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
    return true,"Call-in ordered"
end

function Frontline:UpdateCallIns()
    for i=#self.pendingOrbitals,1,-1 do
        local salvo=self.pendingOrbitals[i]
        local post=self.outposts[salvo.index]
        local elapsed=salvo.timer.ElapsedSimTimeMS
        if elapsed<CONFIG.CALLIN_ORBITAL_DELAY_MS then
            PrimitiveMan:DrawTextPrimitive(Vector(post.x,post.groundY-160),"ORBITAL CANNON INCOMING!",true,1)
        else
            local due=math.min(salvo.total,1+math.floor((elapsed-CONFIG.CALLIN_ORBITAL_DELAY_MS)/CONFIG.CALLIN_ORBITAL_SPACING_MS))
            while salvo.shots<due do
                local round=CreateMOPixel("Frontline Orbital Round","Frontline.rte")
                if round and not self:ShieldBlocks(post,salvo.team) then
                    local x=post.x-90+(salvo.shots%10)*20
                    local ground=SceneMan:MovePointToGround(Vector(x,250),0,4)
                    round.Pos=ground+Vector(0,-250)
                    round.Vel=Vector(0,120)
                    round.Team=salvo.team
                    MovableMan:AddParticle(round)
                end
                salvo.shots=salvo.shots+1
            end
            if salvo.shots>=salvo.total then
                table.remove(self.pendingOrbitals,i)
                self:Notify("Orbital cannon finished at "..post.name)
            end
        end
    end
    for i=#self.pendingStrikes,1,-1 do
        local strike=self.pendingStrikes[i]
        local post=self.outposts[strike.index]
        if strike.timer:IsPastSimMS(CONFIG.CALLIN_STRIKE_DELAY_MS) then
            local bomb=CreateTDExplosive("Standard Bomb","Base.rte")
            if bomb and self:ShieldBlocks(post,strike.team) then
                self:Notify("Shield intercepted strike at "..post.name)
            elseif bomb then
                local ground=SceneMan:MovePointToGround(Vector(post.x,250),0,4)
                bomb.Pos=ground+Vector(0,-18)
                bomb.Team=strike.team
                bomb:GibThis()
                MovableMan:AddParticle(bomb)
                self:Notify("Strike hit "..post.name.." outpost")
            else
                self.teams[strike.team].funds=self.teams[strike.team].funds+CONFIG.CALLIN_STRIKE_COST
                self:Notify("Strike unavailable; cost refunded")
            end
            table.remove(self.pendingStrikes,i)
        else
            PrimitiveMan:DrawTextPrimitive(Vector(post.x,post.groundY-145),"STRIKE INCOMING!",true,1)
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

function Frontline:EndActivity()
    FrameMan:SetHudDisabled(self.originalHudDisabled,0)
    if not self.resultReady then return end
    local t=self.teams[0]
    local result=self.WinnerTeam==0 and "VICTORY" or (self.WinnerTeam==1 and "DEFEAT" or "DRAW")
    local summary=result.."\nDeployed: "..t.stats.deployed.."   Friendly losses: "..self:GetTeamDeathCount(0).."\nEnemy losses: "..self:GetTeamDeathCount(1).."   Captures: "..t.stats.captures.."\nFunds earned: "..math.floor(t.stats.earned).."   Enemy brain health lost: "..math.floor(t.stats.brainDamage).."\nEnemy troop health lost (observed): "..math.floor(t.stats.troopDamage)
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
    local posts={}
    for i=1,#self.outposts do posts[i]={allies=0,enemies=0,wounded=0,threats=0} end
    local enemyVehicle=false
    for actor in MovableMan.Actors do
        if self:IsFieldUnit(actor) then
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
    -- Invest from the same budget and keep a reserve for troop deployments.
    local brain=self.brains[team]
    if brain.Health<brain.MaxHealth-25 and ai.funds>=CONFIG.BASE_REPAIR_COST+240 then
        self:BaseUpgrade(team,"repair")
    elseif (not ai.turret or not MovableMan:IsActor(ai.turret)) and ai.funds>=CONFIG.BASE_TURRET_COST+300 then
        self:BaseUpgrade(team,"turret")
    elseif ai.baseArmor<CONFIG.BASE_ARMOR_LEVELS and ai.funds>=CONFIG.BASE_ARMOR_COST*(ai.baseArmor+1)+400 then
        self:BaseUpgrade(team,"armor")
    end
    local priorities=pressured and {3,4,7,8,2,1,9,6,5} or {1,3,6,2,4,8,7,9,5}
    for _,index in ipairs(priorities) do
        local r=CONFIG.research[index]
        local target=(index==1 or index==2) and 2 or 1
        if ai.levels[index]<math.min(r.max,target) and ai.funds>=self:ResearchCost(team,index)+240 then
            local ok=self:Research(team,index)
            if ok then break end
        end
    end
    -- Build mixed batches from every unlocked faction and equipment branch.
    if ai.tier>=3 and ai.funds>=650 then
        ai.counts={1,0,0,1,1}
    elseif ai.tier>=2 and ai.funds>=480 then
        ai.counts={1,1,0,0,1}
    elseif ai.tier>=2 then
        ai.counts={1,1,1,0,0}
    elseif ai.tier>=1 then
        ai.counts={1,2,0,0,0}
    else
        ai.counts={3,0,0,0,0}
    end
    ai.weapons={ai.levels[6]>0 and 4 or 1,ai.levels[7]>0 and (enemyVehicle and 5 or 2) or (ai.tier>=1 and 2 or 1),ai.tier>=2 and 3 or 1,1,1}
    ai.preset="AI mixed"
    -- Attack the nearest unsecured post from the AI side, then attack the base.
    local target=0
    for i=#self.outposts,1,-1 do if self.outposts[i].owner~=team then target=i; break end end
    local desired=target>0 and "Advance" or "Rush"
    if target==0 and posts[3].threats>=2 then desired="Defend"; target=3 end
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
        for _,pending in ipairs(self.pendingStrikes) do
            if pending.team~=team and self.outposts[pending.index].owner==team then
                local ok=self:CallIn(team,"shield",pending.index); if ok then return end
            end
        end
        for _,pending in ipairs(self.pendingOrbitals) do
            if pending.team~=team and self.outposts[pending.index].owner==team then
                local ok=self:CallIn(team,"shield",pending.index); if ok then return end
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
    -- Fortify threatened posts, alternating cover and mines.
    if ai.funds>=CONFIG.CALLIN_COVER_COST+300 then
        local kinds=ai.fortifyChoice=="mines" and {"mines","cover"} or {"cover","mines"}
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

function Frontline:UpdateActivity()
    if self.ActivityState==Activity.OVER then return end
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
    self:UpdateOrders()
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
    if self.battleStarted and UInputMan:KeyPressed(Key.TAB) then self.panel=not self.panel end
    FrameMan:SetHudDisabled(self.panel or self.originalHudDisabled,0)
    if self.panel then
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
        self:DrawHUD()
    end
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

function Frontline:DrawHUD()
    local t=self.teams[0]
    local offset=CameraMan:GetOffset(0)
    local cost,count=self:Batch(0)
    local income=self:TeamIncome(0)
    local owned=self:OutpostCount(0).."-"..self:OutpostCount(1)
    local function pos(x,y) return self.screenUI and Vector(x,y) or offset+Vector(x,y) end
    local function text(y,s) self:UIDrawText(0,pos(14,y),s,true,0) end
    self:UIDrawBoxFill(0,pos(8,22),pos(360,97),245)
    self:UIDrawBox(0,pos(8,22),pos(360,97),120)
    text(26,"FRONTLINE   |   TAB: COMMAND")
    text(38,"Funds: "..math.floor(t.funds).."  +"..income.."/s   Bounty: "..(CONFIG.BOUNTY+15*t.levels[2]))
    text(50,"Batch: "..(count or 0).." / "..(cost or 0).." oz   Units: "..self:UnitCount(0).." vs "..self:UnitCount(1).." / "..self.settings.unitCap)
    text(62,"Deploy: "..self:AutoReason(0).."   Auto: "..(t.auto and "ON" or "OFF").."   Posts: "..owned)
    if not self.noticeTimer:IsPastSimMS(5000) then text(76,self.message) end
end

function Frontline:DrawWizard()
    local offset=CameraMan:GetOffset(0)
    local move=UInputMan:GetMouseMovement(0)
    self.cursorX=math.max(8,math.min(465,self.cursorX+move.X))
    self.cursorY=math.max(8,math.min(400,self.cursorY+move.Y))
    local click=UInputMan:MouseButtonPressed(MouseButtons.MOUSE_LEFT)
    local function pos(x,y) return self.screenUI and Vector(x,y) or offset+Vector(x,y) end
    local function text(x,y,label) self:UIDrawText(0,pos(x,y),label,#label>42,0) end
    local function button(x,y,w,label,action)
        self:UIDrawBoxFill(0,pos(x,y),pos(x+w,y+18),182)
        self:UIDrawBox(0,pos(x,y),pos(x+w,y+18),206)
        self:UIDrawText(0,pos(x+4,y+3),label,#label*7>w-8,0)
        if click and self.cursorX>=x and self.cursorX<=x+w and self.cursorY>=y and self.cursorY<=y+18 then action() end
    end
    self:UIDrawBoxFill(0,pos(8,8),pos(465,400),245)
    self:UIDrawBox(0,pos(8,8),pos(465,400),120)
    text(20,18,"FRONTLINE MATCH SETUP")
    if self.setupStep==1 then
        text(20,44,"STEP 1 OF 2: CHOOSE MATCH SETTINGS")
        text(20,62,"Click each option to cycle its value. Both teams use it.")
        button(20,86,300,"STARTING FUNDS: "..self.settings.startFunds,function()
            local new=self.settings.startFunds==450 and 750 or (self.settings.startFunds==750 and 250 or 450)
            local delta=new-self.settings.startFunds
            self.teams[0].funds=self.teams[0].funds+delta
            self.teams[1].funds=self.teams[1].funds+delta
            self.settings.startFunds=new
        end)
        button(20,115,300,"BASE INCOME / SEC: "..self.settings.income,function() self.settings.income=self.settings.income==5 and 8 or (self.settings.income==8 and 3 or 5) end)
        button(20,144,300,"TEAM UNIT CAP: "..self.settings.unitCap,function() self.settings.unitCap=self.settings.unitCap==32 and 8 or (self.settings.unitCap==8 and 12 or (self.settings.unitCap==12 and 16 or 32)) end)
        button(20,173,300,"OUTPOST BONUSES: "..(self.settings.outpostBonuses and "ON" or "OFF"),function() self.settings.outpostBonuses=not self.settings.outpostBonuses end)
        button(20,202,300,"CALL-INS: "..(self.settings.callins and "ON" or "OFF"),function() self.settings.callins=not self.settings.callins end)
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
    local function pos(x,y) return self.screenUI and Vector(x,y) or offset+Vector(x,y) end
    -- Larger game font for short labels; long lines stay small so they fit.
    local function text(x,y,s,small)
        if small==nil then small=#s>42 end
        self:UIDrawText(screen,pos(x,y),s,small,0)
    end
    -- Dark fills preserve contrast with the game's pale text at both font sizes.
    local function button(x,y,w,label,state,action)
        local colors={selected=192,available=182,disabled=247,locked=242}
        self:UIDrawBoxFill(screen,pos(x,y),pos(x+w,y+15),colors[state] or colors.available)
        local border=state=="selected" and 120 or ((state=="disabled" or state=="locked") and 94 or 206)
        self:UIDrawBox(screen,pos(x,y),pos(x+w,y+15),border)
        -- The large font is roughly seven pixels per character in this UI.
        -- Keep long button labels in the small font rather than clipping them.
        text(x+3,y+2,label,#label*7>w-6)
        if click and mouse.X>=x and mouse.X<=x+w and mouse.Y>=y and mouse.Y<=y+15 then action() end
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
        for i,r in ipairs(CONFIG.roster) do
            local y=96+(i-1)*32
            local unlocked=r.unlock<=t.tier
            text(15,y,r.name.." ("..r.price.." oz)"..(unlocked and "" or " [LOCKED]"))
            button(230,y-2,18,"-",unlocked and "available" or "locked",function() t.counts[i]=math.max(0,(t.counts[i] or 0)-1); t.preset="Custom" end)
            text(256,y,tostring(t.counts[i] or 0))
            button(275,y-2,18,"+",unlocked and "available" or "locked",function()
                local _,n=self:Batch(0)
                if unlocked and n and n<CONFIG.MAX_BATCH then t.counts[i]=(t.counts[i] or 0)+1; t.preset="Custom" end
            end)
            local weapon=CONFIG.weapons[t.weapons[i] or 1]
            button(15,y+14,280,r.vehicle and "Built-in gatling" or (weapon.name.." (+"..weapon.price.."/unit)"),unlocked and "available" or "locked",function()
                if unlocked and not r.vehicle then
                    local nextIndex=t.weapons[i]%#CONFIG.weapons+1
                    while not weaponUnlocked(t,CONFIG.weapons[nextIndex]) do nextIndex=nextIndex%#CONFIG.weapons+1 end
                    t.weapons[i]=nextIndex; t.preset="Custom"
                end
            end)
        end
        button(310,96,140,"ORDER: "..t.order,"available",function()
            t.order=t.order=="Rush" and "Advance" or (t.order=="Advance" and "Defend" or "Rush")
            self:ApplyTeamOrder(0)
        end)
        local deployment=t.forward==0 and "BASE" or self.outposts[t.forward].name
        button(310,119,140,"FROM: "..deployment,"available",function() t.forward=(t.forward+1)%4 end)
        button(310,142,140,"TARGET: "..self.outposts[t.orderTarget].name,"available",function()
            t.orderTarget=t.orderTarget%#self.outposts+1
            if t.order~="Rush" then self:ApplyTeamOrder(0) end
        end)
        text(310,165,"Orders apply to all troops")
        text(310,178,"Forward: +25/unit")
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
        for i,r in ipairs(CONFIG.research) do
            local y=106+(i-1)*23
            local price=self:ResearchCost(0,i)
            local locked=(r.kind=="tier" and r.tier>1 and t.tier<r.tier-1) or (r.requires and t.tier<r.requires)
            local state=t.levels[i]>=r.max and "selected" or (locked and "locked" or (t.funds<price and "disabled" or "available"))
            local label=r.name.."  "..t.levels[i].."/"..r.max.."   "..price.." oz"
            button(15,y,325,label,state,function() local _,msg=self:Research(0,i); if msg~="Research complete" then self:Notify(msg) end end)
            if locked then text(350,y+3,"Prior tier") end
        end
        text(15,320,"Hold CENTER to reduce research costs by 20%.")
    elseif self.tab=="Battle" then
        text(15,84,"OUTPOSTS: hold for unique bonuses")
        for i,outpost in ipairs(self.outposts) do
            local owner=outpost.owner==0 and "YOUR TEAM" or (outpost.owner==1 and "ENEMY" or "NEUTRAL")
            text(15,86+i*20,outpost.name..": "..owner.."  "..outpost.bonus.."  "..math.floor((outpost.progress+1)*50).."%")
        end
        text(15,174,"YOUR UNITS: "..self:UnitCount(0).." / "..self.settings.unitCap)
        text(15,191,"ENEMY UNITS: "..self:UnitCount(1).." / "..self.settings.unitCap)
        text(15,208,"Opening grace: "..math.max(0,math.ceil((CONFIG.GRACE_MS-self.matchTimer.ElapsedSimTimeMS)/1000)).."s")
        text(15,245,"In Squad, choose a captured outpost for forward deployment.")
        text(15,262,"Rush attacks the brain. Advance captures then attacks.")
        text(15,277,"Defend goes to the selected outpost and holds there.")
    elseif self.tab=="Support" then
        text(15,84,"CALL-INS: select an outpost, then order support")
        for i,post in ipairs(self.outposts) do
            button(15+(i-1)*100,99,94,post.name,self.callinTarget==i and "selected" or "available",function() self.callinTarget=i end)
        end
        local strikeLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_STRIKE_COOLDOWN_MS)-t.strikeTimer.ElapsedSimTimeMS)/1000))
        local medicLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_MEDIC_COOLDOWN_MS)-t.medicTimer.ElapsedSimTimeMS)/1000))
        button(15,122,205,"STRIKE "..CONFIG.CALLIN_STRIKE_COST.." oz  "..(strikeLeft>0 and strikeLeft.."s" or "READY"),strikeLeft==0 and t.funds>=CONFIG.CALLIN_STRIKE_COST and "available" or "disabled",function() local ok,msg=self:CallIn(0,"strike",self.callinTarget); if not ok then self:Notify(msg) end end)
        button(230,122,205,"MEDICS "..CONFIG.CALLIN_MEDIC_COST.." oz  "..(medicLeft>0 and medicLeft.."s" or "READY"),medicLeft==0 and t.funds>=CONFIG.CALLIN_MEDIC_COST and "available" or "disabled",function() local ok,msg=self:CallIn(0,"medic",self.callinTarget); if not ok then self:Notify(msg) end end)
        text(15,143,"Strike: 3s warning; damages ALL troops in blast.")
        local coverLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_COVER_COOLDOWN_MS)-t.coverTimer.ElapsedSimTimeMS)/1000))
        local minesLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_MINES_COOLDOWN_MS)-t.minesTimer.ElapsedSimTimeMS)/1000))
        local bombLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_BOMB_COOLDOWN_MS)-t.bombTimer.ElapsedSimTimeMS)/1000))
        button(15,159,135,"COVER "..CONFIG.CALLIN_COVER_COST.." "..(coverLeft>0 and coverLeft.."s" or "READY"),coverLeft==0 and t.funds>=CONFIG.CALLIN_COVER_COST and "available" or "disabled",function() local ok,msg=self:CallIn(0,"cover",self.callinTarget); if not ok then self:Notify(msg) end end)
        button(155,159,135,"MINES "..CONFIG.CALLIN_MINES_COST.." "..(minesLeft>0 and minesLeft.."s" or "READY"),minesLeft==0 and t.funds>=CONFIG.CALLIN_MINES_COST and "available" or "disabled",function() local ok,msg=self:CallIn(0,"mines",self.callinTarget); if not ok then self:Notify(msg) end end)
        button(295,159,135,"BOMB "..CONFIG.CALLIN_BOMB_COST.." "..(bombLeft>0 and bombLeft.."s" or "READY"),bombLeft==0 and t.funds>=CONFIG.CALLIN_BOMB_COST and "available" or "disabled",function() local ok,msg=self:CallIn(0,"bomb",self.callinTarget); if not ok then self:Notify(msg) end end)
        local orbitalLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_ORBITAL_COOLDOWN_MS)-t.orbitalTimer.ElapsedSimTimeMS)/1000))
        button(15,181,205,"ORBITAL "..CONFIG.CALLIN_ORBITAL_COST.." "..(orbitalLeft>0 and orbitalLeft.."s" or "READY"),orbitalLeft==0 and t.funds>=CONFIG.CALLIN_ORBITAL_COST and "available" or "disabled",function() local ok,msg=self:CallIn(0,"orbital",self.callinTarget); if not ok then self:Notify(msg) end end)
        text(225,185,"3s warning; sustained burst")
        local shieldLeft=math.max(0,math.ceil((self:CallinCooldown(0,CONFIG.CALLIN_SHIELD_COOLDOWN_MS)-t.shieldTimer.ElapsedSimTimeMS)/1000))
        button(15,207,205,"SHIELD "..CONFIG.CALLIN_SHIELD_COST.." "..(shieldLeft>0 and shieldLeft.."s" or "READY"),shieldLeft==0 and t.funds>=CONFIG.CALLIN_SHIELD_COST and "available" or "disabled",function() local ok,msg=self:CallIn(0,"shield",self.callinTarget); if not ok then self:Notify(msg) end end)
        text(15,230,"Shield blocks hostile strikes, bombs and orbital fire for 20s.")
        text(15,245,"Buy Support research for larger deliveries or longer bursts.")
    elseif self.tab=="Base" then
        local brain=self.brains[0]
        text(15,84,"BASE DEFENSES")
        text(15,104,"Brain health: "..math.floor(brain.Health).." / "..math.floor(brain.MaxHealth))
        text(15,120,"Armor level: "..t.baseArmor.." / "..CONFIG.BASE_ARMOR_LEVELS)
        local active=t.turret and MovableMan:IsActor(t.turret)
        text(15,136,"Roof turret: "..(active and "ACTIVE" or "ABSENT"))
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
        setting("Base income / sec",136,self.settings.income,function() self.settings.income=self.settings.income==5 and 8 or (self.settings.income==8 and 3 or 5) end)
        setting("Team unit cap",163,self.settings.unitCap,function() self.settings.unitCap=self.settings.unitCap==32 and 8 or (self.settings.unitCap==8 and 12 or (self.settings.unitCap==12 and 16 or 32)) end)
        setting("Outpost bonuses",190,self.settings.outpostBonuses and "ON" or "OFF",function() self.settings.outpostBonuses=not self.settings.outpostBonuses end)
        setting("Call-ins",217,self.settings.callins and "ON" or "OFF",function() self.settings.callins=not self.settings.callins end)
        text(15,250,"Click a setting to cycle it. Changes affect both teams.")
        text(15,266,"Difficulty is chosen in the game setup screen.")
    end
    button(15,348,125,"DEPLOY ("..(cost or 0).." oz)",self:AutoReason(0)=="Ready" and "available" or "disabled",function() local _,msg=self:Deploy(0); if msg~="Batch deployed" then self:Notify(msg) end end)
    button(150,348,100,"AUTO: "..(t.auto and "ON" or "OFF"),t.auto and "selected" or "available",function() t.auto=not t.auto end)
    text(260,352,self:AutoReason(0))
    text(15,375,self.message)
    text(15,393,"Blue = selected; gray = unavailable; red = locked")
    text(15,407,"The battle continues while this panel is open.")
    self:UIDrawBoxFill(screen,pos(mouse.X-2,mouse.Y-2),pos(mouse.X+2,mouse.Y+2),120)
end
