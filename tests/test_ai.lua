-- Behavior tests exercise the real activity with lightweight engine doubles.
Frontline={}
Actor={AIMODE_SENTRY=1,AIMODE_BRAINHUNT=2,AIMODE_GOTO=3,AIMODE_DELIVER=5,AIMODE_RETURN=6}
Controller={CIM_AI=1,CIM_DISABLED=0}
Activity={OBSERVE=1,OVER=2,NOTEAM=-1}
Key={TAB=1}; MouseButtons={MOUSE_LEFT=1,MOUSE_RIGHT=2}; rte={goldID=2}
function Timer() return {ElapsedSimTimeMS=0,IsPastSimMS=function(s,n) return s.ElapsedSimTimeMS>=n end,Reset=function(s) s.ElapsedSimTimeMS=0 end} end
function Vector(x,y) return setmetatable({X=x,Y=y},{__add=function(a,b) return Vector(a.X+b.X,a.Y+b.Y) end}) end
local nextId=0
function CreateAHuman(name)
    nextId=nextId+1
    return {name=name,UniqueID=nextId,Team=0,Health=100,MaxHealth=100,Height=70,
        AddInventoryItem=function(self,item) self.inventory=item end,
        ClearAIWaypoints=function(self) self.waypoint=nil end,
        AddAISceneWaypoint=function(self,v) self.waypoint=v end}
end
function CreateACrab(name) local actor=CreateAHuman(name); actor.vehicle=true; return actor end
function CreateHDFirearm(name) return {name=name} end
function CreateMOPixel(name) return {name=name} end
function CreateTDExplosive(name) return {name=name} end
function CreateACDropShip(name)
    nextId=nextId+1
    return {name=name,ship=true,UniqueID=nextId,MaxPassengers=4,MaxInventoryMass=800,InventorySize=0,cargo={},
        SetControllerMode=function() end,SetGoldValue=function() end,
        AddInventoryItem=function(self,item) table.insert(self.cargo,item); self.InventorySize=#self.cargo end}
end
function ToActor(actor) return actor end
function CreateSoundContainer() return {Play=function() end} end
function CreateTerrainObject(name) return {name=name} end
local actors={}
MovableMan={
    Actors=(function() local i=0; return function() i=i+1; if not actors[i] then i=0; return nil end; return actors[i] end end)(),
    AddActor=function(_,actor) table.insert(actors,actor) end,
    IsActor=function(_,actor) return actor~=nil and not actor.deleted end,
}
MovableMan.Particles=function() return nil end
function IsAHuman(actor) return not actor.vehicle and not actor.ship end
function IsACrab(actor) return actor.vehicle==true end
SceneMan={SceneWidth=5200,SceneHeight=800,CastMaterialRay=function() return false end,
    AddSceneObject=function() end,MovePointToGround=function(_,p) return Vector(p.X,600) end}
FrameMan={PlayerScreenWidth=640,IsHudDisabled=function() return false end,SetHudDisabled=function() end}
PrimitiveMan={}; MusicMan={PlayDynamicSong=function() end}
TimerMan={DeltaTimeSecs=1}; UInputMan={KeyPressed=function() return false end}
ActivityMan={EndActivity=function() end}
function Frontline:SetPlayerBrain() end
function Frontline:SetViewState() end
function Frontline:SetObservationTarget() end
function Frontline:GetTeamDeathCount(team) return self.deathCounts[team] end
assert(loadfile('Frontline.rte/Frontline.lua'))()

local function newBattle()
    actors={}
    local activity=setmetatable({deathCounts={[0]=0,[1]=0}},{__index=Frontline})
    activity:StartActivity()
    activity:StartBattle()
    activity.aiPersonality='balanced'
    activity.matchTimer.ElapsedSimTimeMS=15000
    activity.settings.callins=false
    return activity
end

-- Player aggression must reflect committed deployments, not attempts or frames.
do
    local activity=newBattle()
    local player=activity.teams[0]
    player.auto=false
    player.funds=0
    local beforeFunds=player.funds
    assert(not activity.commanders[0]:Deploy(),'an unaffordable batch must fail')
    assert(player.funds==beforeFunds and player.stats.deployed==0,'failed deployment must not charge or add units')
    player.funds=1000
    local cost=activity:Batch(0)
    assert(activity.commanders[0]:Deploy(),'an affordable, ready batch must deploy')
    assert(player.stats.deployed==3 and player.funds==1000-cost,'successful deployment must charge for exactly its batch')
    assert(activity.playerBehavior.lastDeployTime==15000 and activity.playerBehavior.lastDeploymentCount==3,
        'the observed deployment includes its match time and actual batch size')
    assert(not activity.commanders[0]:Deploy(),'an immediate second batch must respect the deployment cooldown')
    assert(player.stats.deployed==3 and player.funds==1000-cost,'cooldown failure must not spend or deploy')
    activity:UpdateAI()
    assert(activity.playerBehavior.deployments==1,'AI must observe one successful player deployment, not failed attempts')
    activity:UpdateAI()
    assert(activity.playerBehavior.deployments==1,'AI decisions must not count the same deployment twice')
    player.timer.ElapsedSimTimeMS=100000
    local createGun=CreateHDFirearm
    CreateHDFirearm=function() return nil end
    assert(not activity.commanders[0]:Deploy(),'a missing equipment preset must reject the whole batch')
    CreateHDFirearm=createGun
    assert(activity.playerBehavior.deployments==1 and player.stats.deployed==3 and player.funds==1000-cost,
        'a failed construction must not record or charge a deployment')
    assert(activity.commanders[0]:Deploy(),'a later valid batch must deploy')
    assert(activity.playerBehavior.deployments==2 and player.stats.deployed==6,
        'the signal counts successful batches, not their unit count')
end

-- Normal activity updates and automatic deployment must use the same accounting.
do
    local activity=newBattle()
    local player=activity.teams[0]
    activity.panel=false
    activity.DrawHUD=function() end
    activity.DrawOutpost=function() end
    player.auto=true
    player.funds=0
    local delta=TimerMan.DeltaTimeSecs
    TimerMan.DeltaTimeSecs=0
    activity:UpdateActivity()
    activity:UpdateActivity()
    assert(activity.playerBehavior.deployments==0,'failed automatic attempts and idle frames must not count as deployments')
    player.funds=1000
    activity:UpdateActivity()
    assert(activity.playerBehavior.deployments==1 and player.stats.deployed==3,'one automatic batch must be counted once')
    activity:UpdateActivity()
    assert(activity.playerBehavior.deployments==1,'automatic cooldown failures must not inflate the counter')
    TimerMan.DeltaTimeSecs=delta
end

-- Other observed player actions must likewise be recorded only when paid.
do
    local activity=newBattle()
    local player=activity.teams[0]
    player.funds=0
    assert(not activity.commanders[0]:Research(1),'unaffordable research must fail')
    player.funds=5000
    assert(activity.commanders[0]:Research(1),'affordable unlocked research must succeed')
    assert(activity.playerBehavior.researchPurchases==1,'only successful player research must be observed')
    assert(activity.playerBehavior.lastResearchIndex==1,'the observed research identifies the purchased upgrade')
    activity.settings.callins=true
    player.levels[24]=1
    assert(activity.commanders[0]:CallIn('strike',2),'unlocked, ready strike must succeed')
    assert(not activity.commanders[0]:CallIn('strike',2),'strike cooldown must reject a second call')
    assert(activity.playerBehavior.callinsUsed==1,'only successful player call-ins must be observed')
    assert(activity.playerBehavior.lastCallin=='strike','the observed call-in identifies the successful support kind')
    local enemy=activity.teams[1]
    enemy.funds=5000
    enemy.levels[24]=1
    assert(activity.commanders[1]:Research(1) and activity.commanders[1]:CallIn('strike',2),'the opponent can also purchase research and support')
    assert(activity.playerBehavior.researchPurchases==1 and activity.playerBehavior.callinsUsed==1,
        'opponent purchases must not be attributed to the player')
end

-- Passive-player adaptation requires repeated small batches, not just low investment.
do
    local activity=newBattle()
    activity.matchTimer.ElapsedSimTimeMS=61000
    local behavior=activity.playerBehavior
    behavior.deployments=3
    behavior.researchPurchases=0
    behavior.callinsUsed=0
    behavior.recentDeploymentCount=3
    behavior.lastDeploymentCount=3
    assert(activity:IsPlayerPassive(),'repeated small deployments with no investment should be passive')
    behavior.lastDeploymentCount=5
    assert(not activity:IsPlayerPassive(),'a large latest batch must not meet the small-wave condition')
    behavior.lastDeploymentCount=3
    behavior.recentDeploymentCount=2
    assert(not activity:IsPlayerPassive(),'insufficient recent batches must not meet the small-wave condition')
end

-- A home emergency must interrupt ordinary strategy and cease after attackers
-- leave; budget and deployment cooldown still apply during the emergency.
do
    local activity=newBattle()
    local ai=activity.teams[1]
    ai.funds=0
    activity:UpdateAI()
    assert(ai.goal~='defendBase','an unthreatened base should not demand emergency defense')
    local lone=CreateAHuman('Soldier Light')
    lone.Team=0; lone.Pos=Vector(activity.brains[1].Pos.X-200,565)
    MovableMan:AddActor(lone)
    local ally=CreateAHuman('Soldier Light')
    ally.Team=1; ally.Pos=Vector(activity.brains[1].Pos.X-200,565)
    MovableMan:AddActor(ally)
    local dead=CreateAHuman('Soldier Light')
    dead.Team=0; dead.Health=0; dead.Pos=Vector(activity.brains[1].Pos.X-200,565)
    MovableMan:AddActor(dead)
    activity:UpdateAI()
    assert(ai.goal~='defendBase','a lone enemy, friendly unit, and dead enemy are not a mass rush')
    local attackers={}
    for i=1,6 do
        local actor=CreateAHuman('Soldier Light')
        actor.Team=0
        actor.Pos=Vector(activity.brains[1].Pos.X-250-i*10,565)
        MovableMan:AddActor(actor)
        attackers[#attackers+1]=actor
    end
    local deployed=ai.stats.deployed
    activity:UpdateAI()
    assert(ai.goal=='defendBase' and ai.order=='Defend' and ai.orderTarget==0,
        'a base rush must override ordinary objectives with home defense')
    assert(ai.funds==0 and ai.stats.deployed==deployed,'base defense must not grant free deployments')
    ai.funds=1000
    ai.timer.ElapsedSimTimeMS=0
    activity:UpdateAI()
    assert(ai.stats.deployed==deployed,'base defense must not bypass the deployment cooldown')
    for _,actor in ipairs(attackers) do actor.Team=2 end
    activity:UpdateAI()
    assert(ai.goal~='defendBase' and not (ai.order=='Defend' and ai.orderTarget==0),
        'after attackers leave, the commander must reassess rather than remain stuck at home')
end

-- A legal, affordable squad must not be held hostage by an unavailable
-- research purchase; the commander still pays the normal batch price.
do
    local activity=newBattle()
    local ai=activity.teams[1]
    ai.funds=400
    activity:UpdateAI()
    local cost,count=activity:Batch(1)
    assert(count==3 and ai.stats.deployed==count,
        'with a scarce budget and a ready starting squad, the AI should deploy a feasible batch')
    assert(ai.funds==400-cost and ai.funds>=0,
        'the AI must pay the actual batch cost without borrowing for an unavailable investment')
end

-- An expensive forward post must not prevent an affordable home deployment.
do
    local activity=newBattle()
    local ai=activity.teams[1]
    activity.outposts[1].owner=1
    ai.funds=580
    activity:UpdateAI()
    assert(ai.forward==0 and ai.stats.deployed==3 and ai.funds==415,
        'the AI should choose the affordable base batch, retaining its reserve')

    activity=newBattle(); ai=activity.teams[1]
    activity.outposts[1].owner=1
    ai.funds=590
    local choose=activity.ChooseAIAction
    activity.ChooseAIAction=function(self,actions,pressured)
        for _,action in ipairs(actions) do
            if action.kind=='deployment' then return action end
        end
        return choose(self,actions,pressured)
    end
    activity:UpdateAI()
    local cost,count=activity:Batch(1)
    assert(ai.forward==1 and cost==390 and count==3 and ai.stats.deployed==3 and ai.funds==590-cost,
        'an affordable forward deployment must pay the same position-based price as the player')
end

-- Unlocking one troop type must not reduce a full batch to a single soldier.
do
    local activity=newBattle()
    local ai=activity.teams[1]
    ai.stats.deployed=3; ai.levels[1]=1; ai.funds=700
    activity:UpdateAI()
    assert(ai.stats.deployed==6 and ai.counts[1]==3 and ai.funds==460,
        'the AI should repeat its unlocked, affordable unit to fill the squad and pay for it')
end

-- A threatened base should spend its reserve on a legal emergency squad.
do
    local activity=newBattle()
    local ai=activity.teams[1]
    ai.stats.deployed=3; ai.funds=200
    for i=1,4 do
        local attacker=CreateAHuman('attacker')
        attacker.Team=0; attacker.Pos=Vector(activity.brains[1].Pos.X-100,565)
        MovableMan:AddActor(attacker)
    end
    activity:UpdateAI()
    assert(ai.order=='Defend' and ai.orderTarget==0 and ai.stats.deployed==6 and ai.funds==35,
        'home defense should buy the affordable emergency squad without granting money')
    activity:UpdateAI()
    assert(ai.stats.deployed==6 and ai.funds==35,'emergency deployment must still respect cooldown and funds')
end

-- Counters must actually affect selection; newly available equipment must also
-- enter research competition rather than being absent from every priority list.
do
    local function researchDecision(focus,equipmentOnly)
        local activity=newBattle()
        local ai=activity.teams[1]
        ai.funds=2000; ai.timer.ElapsedSimTimeMS=0
        activity.settings.income=8
        for i=1,29 do ai.levels[i]=10 end
        if equipmentOnly then ai.levels[18]=0; ai.levels[19]=0; ai.levels[20]=0
        else ai.levels[2]=0; ai.levels[3]=0 end
        activity.playerBehavior.researchFocus=focus
        local choose=activity.ChooseAIAction
        activity.ChooseAIAction=function(self,actions,pressured)
            local candidates={}
            for _,action in ipairs(actions) do if action.kind=='research' then candidates[#candidates+1]=action end end
            return choose(self,#candidates>0 and candidates or actions,pressured)
        end
        activity:UpdateAI()
        return ai.lastAIAction and ai.lastAIAction.target
    end
    local balancedResearch=researchDecision('',false)
    local infantryResearch=researchDecision('infantry',false)
    assert(balancedResearch==3 and infantryResearch==2,
        'observed infantry research should promote the income counter over bounty (balanced='
            ..tostring(balancedResearch)..', infantry='..tostring(infantryResearch)..')')
    assert(researchDecision('',true)==18,'equipment research must be available to the AI')
end

-- Repeated bonuses compound for both teams, transfer immediately and can be
-- disabled. Research purchases use the same rounded price shown by the UI.
do
    local activity=newBattle()
    for i=1,9 do
        local post=activity.outposts[i] or {name='extra',x=2600,groundY=600}
        post.kind=((i-1)%3)+1
        post.owner=0
        activity.outposts[i]=post
    end
    assert(activity:TeamIncome(0)==20 and activity:TeamIncome(1)==5)
    assert(activity:ResearchCost(0,3)==164 and activity:CallinCooldown(0,45000)==23040)
    for i=1,3 do activity.outposts[i].owner=1 end
    assert(activity:TeamIncome(0)==15 and activity:TeamIncome(1)==10)
    assert(activity:ResearchCost(0,3)==205 and activity:ResearchCost(1,3)==256)
    assert(activity:CallinCooldown(0,45000)==28800 and activity:CallinCooldown(1,45000)==36000)
    activity.teams[0].levels[2]=1
    assert(activity:TeamIncome(0)==17,'income research still adds 2/s independently of posts')
    activity.settings.outpostBonuses=false
    assert(activity:TeamIncome(0)==7 and activity:TeamIncome(1)==5)
    assert(activity:ResearchCost(0,3)==320 and activity:ResearchCost(1,3)==320)
    assert(activity:CallinCooldown(0,45000)==45000 and activity:CallinCooldown(1,45000)==45000)
    activity.settings.outpostBonuses=true
    for team=0,1 do
        local before=1000
        local price=activity:ResearchCost(team,3)
        activity.teams[team].funds=before
        assert(activity.commanders[team]:Research(3))
        assert(activity.teams[team].funds==before-price,'both teams pay the stacked research price')
    end
end

-- An identical world and personality must not make a different strategic
-- decision merely because unrelated engine randomness has advanced.
do
    local function decide(seed)
        math.randomseed(seed)
        local activity=newBattle()
        local ai=activity.teams[1]
        ai.funds=0
        activity:UpdateAI()
        return ai.goal,ai.goalTarget,ai.order,ai.orderTarget
    end
    local goal,target,order,orderTarget=decide(1)
    local otherGoal,otherTarget,otherOrder,otherOrderTarget=decide(98765)
    assert(goal==otherGoal and target==otherTarget and order==otherOrder and orderTarget==otherOrderTarget,
        'equivalent snapshots must make the same strategic decision')
end

-- Both command interfaces must reissue orders to their own field force, not
-- the opposing team, brain, or miners, and retain them for future arrivals.
for team=0,1 do
    local activity=newBattle()
    local commander=activity.commanders[team]
    local own=CreateAHuman('Soldier Light')
    own.Team=team; own.Pos=Vector(800,565); own.waypoint=Vector(1,1)
    MovableMan:AddActor(own)
    local second=CreateAHuman('Soldier Heavy')
    second.Team=team; second.Pos=Vector(850,565); second.waypoint=Vector(5,5)
    MovableMan:AddActor(second)
    local other=CreateAHuman('Soldier Light')
    other.Team=1-team; other.Pos=Vector(900,565); other.waypoint=Vector(2,2); other.AIMode=91
    MovableMan:AddActor(other)
    local miner=CreateAHuman('Miner')
    miner.Team=team; miner.Pos=Vector(700,565); miner.waypoint=Vector(3,3); miner.AIMode=92
    activity.miners[miner.UniqueID]={}
    MovableMan:AddActor(miner)
    local minerWaypoint,otherWaypoint=miner.waypoint,other.waypoint

    assert(commander:SetOrder('Advance',2))
    assert(own.AIMode==Actor.AIMODE_GOTO and own.waypoint
        and activity.orderAssignments[own.UniqueID].target==2,'advance assigns the selected post')
    assert(miner.AIMode==92 and miner.waypoint==minerWaypoint,'orders must not redirect miners')
    assert(other.AIMode==91 and other.waypoint==otherWaypoint,'orders must not redirect the opposing team')
    assert(activity.brains[team].AIMode==Actor.AIMODE_SENTRY,'orders must not redirect the brain')
    assert(not commander:SetOrder('Advance',0) and not commander:SetOrder('invalid',2)
        and not commander:SetOrder('Defend',#activity.outposts+1),'invalid orders and targets must be rejected')
    assert(activity.teams[team].order=='Advance' and activity.teams[team].orderTarget==2,
        'invalid commands must preserve the previous order')

    assert(commander:SetOrder('Defend',0))
    assert(own.AIMode==Actor.AIMODE_GOTO and activity.orderAssignments[own.UniqueID].base
        and math.abs(own.waypoint.X-activity.brains[team].Pos.X)<100,'home defense must target the issuing base')
    assert(commander:SetOrder('Rush',0))
    assert(own.AIMode==Actor.AIMODE_BRAINHUNT and own.waypoint==nil
        and activity.orderAssignments[own.UniqueID]==nil,'rush must clear stale defensive waypoints')
    assert(miner.AIMode==92 and miner.waypoint==minerWaypoint,'miners remain exempt through order transitions')

    local post=team==0 and 1 or 3
    activity.outposts[post].owner=team
    activity.teams[team].funds=5000
    assert(commander:SetForward(post))
    assert(commander:Deploy(),'owned forward deployment must create a delivery')
    local delivery=activity.deliveries[#activity.deliveries]
    assert(delivery and delivery.team==team and #delivery.ship.cargo>0)
    assert(commander:SetOrder('Defend',2))
    local arrived=table.remove(delivery.ship.cargo,1)
    delivery.ship.InventorySize=#delivery.ship.cargo
    arrived.Pos=Vector(activity.outposts[post].x,565)
    arrived.waypoint=Vector(4,4)
    MovableMan:AddActor(arrived)
    activity:UpdateDeliveries()
    assert(arrived.AIMode==Actor.AIMODE_GOTO and activity.orderAssignments[arrived.UniqueID].target==2
        and arrived.waypoint.X~=4,'disembarked troops must receive the current order, not a stale waypoint')
    local force={own,second,arrived}
    for _,unit in ipairs(force) do
        local assignment=activity.orderAssignments[unit.UniqueID]
        assert(unit.AIMode==Actor.AIMODE_GOTO and unit.waypoint and assignment
            and assignment.order=='Defend' and assignment.target==2,
            'existing soldiers and the arrival must all receive the same defense order')
    end
    assert(commander:SetOrder('Rush',0))
    activity:UpdateOrders()
    for _,unit in ipairs(force) do
        assert(unit.AIMode==Actor.AIMODE_BRAINHUNT and unit.waypoint==nil
            and activity.orderAssignments[unit.UniqueID]==nil,
            'rush must clear every stale waypoint and assignment, including after an order update')
    end
    assert(commander:SetOrder('Advance',2))
    for _,unit in ipairs(force) do
        local assignment=activity.orderAssignments[unit.UniqueID]
        assert(unit.AIMode==Actor.AIMODE_GOTO and unit.waypoint and assignment
            and assignment.order=='Advance' and assignment.target==2,
            'every soldier must advance to the same target')
        unit.Pos=Vector(activity.outposts[2].x,activity.outposts[2].groundY)
    end
    activity:UpdateOrders()
    for _,unit in ipairs(force) do
        assert(unit.AIMode==Actor.AIMODE_SENTRY and activity.orderAssignments[unit.UniqueID],
            'an arriving advance force must hold an uncaptured post')
    end
    activity.outposts[2].owner=team
    activity:UpdateOrders()
    for _,unit in ipairs(force) do
        assert(unit.AIMode==Actor.AIMODE_BRAINHUNT and unit.waypoint==nil
            and activity.orderAssignments[unit.UniqueID]==nil,
            'after capture every advancing soldier must resume attacking')
    end
    assert(commander:SetOrder('Defend',2))
    activity:UpdateOrders()
    for _,unit in ipairs(force) do
        assert(unit.AIMode==Actor.AIMODE_SENTRY and unit.waypoint==nil
            and activity.orderAssignments[unit.UniqueID]==nil,
            'every defender must hold the post after arrival')
    end
    assert(miner.AIMode==92 and miner.waypoint==minerWaypoint
        and other.AIMode==91 and other.waypoint==otherWaypoint,
        'miner and opposing soldier remain unchanged throughout mixed-squad transitions')
end

-- Identical commands for either side use the same errors, costs and cooldowns.
local function controllerEconomy(team)
    local activity=newBattle()
    local commander=activity.commanders[team]
    local t=activity.teams[team]
    activity.settings.callins=true
    local results={}
    local function failure(action)
        local before=t.funds
        local ok,reason=action()
        assert(not ok and type(reason)=='string' and t.funds==before,'rejected action must report an error without charging')
        results[#results+1]=reason
    end
    local function purchase(action)
        local before=t.funds
        local ok,reason=action()
        assert(ok and type(reason)=='string' and t.funds<before,'successful action must charge its normal price')
        results[#results+1]=before-t.funds
    end
    t.funds=0; t.levels[24]=1
    failure(function() return commander:Research(1) end)
    failure(function() return commander:BaseUpgrade('armor') end)
    failure(function() return commander:CallIn('strike',2) end)
    failure(function() return commander:Deploy() end)
    assert(not commander:SetForward(#activity.outposts+1) and t.forward==0,'invalid forward index must not change selection')
    assert(commander:SetForward(2),'forward selection may reference an unowned post')
    t.funds=5000
    failure(function() return commander:Deploy() end)
    assert(commander:SetForward(0))
    purchase(function() return commander:Research(1) end)
    purchase(function() return commander:BaseUpgrade('armor') end)
    purchase(function() return commander:CallIn('strike',2) end)
    failure(function() return commander:CallIn('strike',2) end)
    purchase(function() return commander:Deploy() end)
    failure(function() return commander:Deploy() end)
    return results
end
do
    local player,enemy=controllerEconomy(0),controllerEconomy(1)
    assert(#player==#enemy)
    for i=1,#player do
        assert(player[i]==enemy[i],'controller error/cost/cooldown parity mismatch at step '..i)
    end
end

print('Both team controllers apply orders, handle arrivals and enforce the same purchase rules')

print('AI deployment accounting, base emergency recovery, budget and cooldown passed')

-- Battle start makes exactly one draw; every persona still obeys the same
-- emergency order, funds and cooldown constraints.
do
    local expected={'aggressive','defensive','economic','balanced','strategic','raider','guardian','artillery','engineer','vanguard'}
    local original=math.random
    for index,name in ipairs(expected) do
        actors={}
        local a=setmetatable({deathCounts={[0]=0,[1]=0}},{__index=Frontline})
        a:StartActivity()
        local calls=0
        math.random=function(lo,hi) calls=calls+1; assert(lo==1 and hi==10); return index end
        a:StartBattle(); a:StartBattle()
        math.random=original
        assert(calls==1 and a.aiPersonality==name,'battle must choose exactly one of ten profiles')
        a.matchTimer.ElapsedSimTimeMS=15000; a.settings.callins=false
        local ai=a.teams[1]; ai.funds=0; ai.stats.deployed=3
        for i=1,4 do
            local enemy=CreateAHuman('attacker'); enemy.Team=0
            enemy.Pos=Vector(a.brains[1].Pos.X-100,565); MovableMan:AddActor(enemy)
        end
        a:UpdateAI()
        assert(a.aiPersonality==name and ai.order=='Defend' and ai.orderTarget==0
            and ai.stats.deployed==3,'every profile must defend without free troops')
        ai.funds=200; a:UpdateAI()
        assert(ai.stats.deployed==6 and ai.funds==35,'emergency troops must be purchased normally')
        a:UpdateAI()
        assert(ai.stats.deployed==6 and ai.funds==35,'every profile respects cooldown')
        a:StartActivity()
        assert(a.aiPersonality==nil,'restarting an activity must discard its previous profile')
        math.random=function(lo,hi) assert(lo==1 and hi==10); return index%10+1 end
        a:StartBattle()
        math.random=original
        assert(a.aiPersonality==expected[index%10+1],'a new match must draw a new profile')
    end
end

-- Safe objectives break first-post regrouping; only dispersed forces without a safe
-- advance objective keep assembling. Low temperature makes each fixture repeatable.
do
    local function fixture()
        local a=newBattle(); a.aiTemperature=0.001; a.teams[1].funds=0
        return a,a.teams[1]
    end
    local a,ai=fixture()
    a.outposts[3].owner=1
    for i=1,3 do
        local ally=CreateAHuman('ally'); ally.Team=1
        ally.Pos=Vector(a.outposts[3].x,565); MovableMan:AddActor(ally)
    end
    a:UpdateAI()
    assert(ai.goal=='advance' and ai.order=='Advance' and ai.orderTarget==2,
        'a concentrated force must advance toward the nearest safe neutral post')
    for actor in MovableMan.Actors do
        if actor.Team==1 and actor.UniqueID~=a.brains[1].UniqueID then actor.Pos=Vector(a.outposts[2].x,565) end
    end
    a:UpdateOrders()
    assert(a.orderAssignments[actors[#actors-1].UniqueID]~=nil,
        'advancing units should remain assigned while an uncaptured target is being secured')

    local rush,rushAI=fixture()
    for _,post in ipairs(rush.outposts) do post.owner=1 end
    rush:UpdateAI()
    assert(rushAI.goal=='rush' and rushAI.order=='Rush',
        'when all posts are held and no rally is needed, the AI should rush')

    local dispersed,dispersedAI=fixture()
    dispersed.outposts[1].owner=1; dispersed.outposts[3].owner=1
    for _,index in ipairs({1,3}) do
        local ally=CreateAHuman('ally'); ally.Team=1
        ally.Pos=Vector(dispersed.outposts[index].x,565); MovableMan:AddActor(ally)
    end
    local blocker=CreateAHuman('blocker'); blocker.Team=0
    blocker.Pos=Vector(dispersed.outposts[2].x,565); MovableMan:AddActor(blocker)
    dispersed:UpdateAI()
    assert(dispersedAI.goal=='regroup' and dispersedAI.order=='Defend',
        'dispersed allies may regroup when every uncaptured objective is contested')

    local threatened,threatAI=fixture()
    threatened.outposts[3].owner=1
    local ally=CreateAHuman('ally'); ally.Team=1; ally.Pos=Vector(threatened.outposts[3].x,565); MovableMan:AddActor(ally)
    local enemy=CreateAHuman('enemy'); enemy.Team=0; enemy.Pos=Vector(threatened.outposts[3].x,565); MovableMan:AddActor(enemy)
    threatened:UpdateAI()
    assert(threatAI.goal=='defendPost' and threatAI.order=='Defend' and threatAI.orderTarget==3,
        'a genuine threat to an owned post must take precedence over safe objectives')
end
print('AI advances to safe posts, rushes after securing them, regroups only when needed, and defends threats')
print('Ten match personas preserve legal emergency behavior and vary strategic orders')

-- Compare actual decisions across fixed battlefield, research and support
-- situations. Every profile must produce a different observable signature.
do
    local names={'aggressive','defensive','economic','balanced','strategic','raider','guardian','artillery','engineer','vanguard'}
    local function scenario(personality,which)
        math.randomseed(100)
        local a=newBattle(); a.aiPersonality=personality; a.aiTemperature=0.01
        local ai=a.teams[1]
        ai.stats.deployed=3; ai.funds=which<=2 and 0 or 2000; ai.timer.ElapsedSimTimeMS=0
        if which<=2 then
            a.outposts[3].owner=1
            for i=1,which+1 do
                local ally=CreateAHuman('ally'); ally.Team=1; ally.Pos=Vector(a.outposts[3].x,565); MovableMan:AddActor(ally)
            end
        else
            ai.baseArmor=3; ai.turret={Health=100}; ai.turretLevel=2
            for i=1,29 do ai.levels[i]=1 end
            if which==3 then
                ai.levels[29]=0
                for i=21,26 do ai.levels[i]=0 end
            else
                a.settings.callins=true; ai.levels[29]=6; a.outposts[3].owner=1
                for i=1,3 do
                    local ally=CreateAHuman('ally'); ally.Team=1; ally.Pos=Vector(a.outposts[3].x,565)
                    ally.Health=40; MovableMan:AddActor(ally)
                end
                if which==4 then
                    for i=1,3 do
                        local enemy=CreateAHuman('enemy'); enemy.Team=0; enemy.Pos=Vector(a.outposts[2].x,565)
                        MovableMan:AddActor(enemy)
                    end
                else a.playerBehavior.deployments=6 end
            end
        end
        a:UpdateAI()
        if which<=2 then return ai.goal end
        local action=ai.lastAIAction
        assert(action and ai.funds<2000,'candidate decisions must execute and pay their real price')
        return action.kind..':'..tostring(action.target)
    end
    local seen={}
    for _,name in ipairs(names) do
        local parts={}
        for which=1,5 do parts[which]=scenario(name,which) end
        local signature=table.concat(parts,'|')
        seen[name]=signature
        print('Persona decisions '..name..': '..signature)
    end
    assert(seen.aggressive~=seen.economic and seen.defensive~=seen.raider
        and seen.artillery~=seen.engineer,
        'personas should retain distinct offensive, defensive, and support/research commitments')
    local unique={}
    for _,signature in pairs(seen) do unique[signature]=true end
    local count=0
    for _ in pairs(unique) do count=count+1 end
    assert(count>=6,'persona scenario set should expose at least six distinct decision signatures')
end

-- Concentrations are considered off-post, on friendly posts and in neutral
-- territory; every available offense still uses normal call-in rules.
do
    local function setup(kind,x,amount,owner)
        local a=newBattle()
        a.settings.callins=true
        local ai=a.teams[1]; ai.funds=1000; ai.stats.deployed=3; ai.timer.ElapsedSimTimeMS=0
        ai.baseArmor=3; ai.turret={Health=100}; ai.turretLevel=2
        if owner then a.outposts[2].owner=owner end
        if kind=='orbital' then ai.levels[21]=1
        elseif kind=='strike' then ai.levels[21]=1; ai.levels[24]=1; ai.orbitalTimer.ElapsedSimTimeMS=0
        elseif kind=='bomb' then
            ai.levels[21]=1; ai.levels[24]=1; ai.levels[25]=1
            ai.orbitalTimer.ElapsedSimTimeMS=0; ai.strikeTimer.ElapsedSimTimeMS=0
        end
        for i=1,amount do
            local enemy=CreateAHuman('enemy'); enemy.Team=0
            enemy.Pos=Vector(x+(i-1)*20,565); MovableMan:AddActor(enemy)
        end
        return a,ai
    end
    local costs={strike=220,bomb=260,orbital=175}
    for _,kind in ipairs({'strike','bomb','orbital'}) do
        local a,ai=setup(kind,2100,3)
        a:UpdateAI()
        local order=kind=='strike' and a.pendingStrikes[1] or
            (kind=='orbital' and a.pendingOrbitals[1] or a.pendingDrops[1])
        assert(order and order.target.x>=2100 and order.target.x<=2140
            and ai.lastAIAction.kind=='offense' and ai.funds==1000-costs[kind],
            kind..' should target the off-post cluster and pay the normal cost')
        local timer=kind=='strike' and ai.strikeTimer or (kind=='bomb' and ai.bombTimer or ai.orbitalTimer)
        assert(timer.ElapsedSimTimeMS==0,'offensive support must start its usual cooldown')
    end
    for _,owner in ipairs({-1,1}) do
        local a=setup('orbital',2600,3,owner)
        a:UpdateAI()
        assert(#a.pendingOrbitals==1 and a.pendingOrbitals[1].target.x>=2600,
            'cluster targeting must work on neutral and owned posts')
    end
    local function noOffense(a,ai)
        a:UpdateAI()
        assert(#a.pendingStrikes==0 and #a.pendingOrbitals==0
            and (not ai.lastAIAction or ai.lastAIAction.kind~='offense'),
            'unavailable or unsafe support must not be ordered')
    end
    local a,ai=setup(nil,2100,3); noOffense(a,ai)
    a,ai=setup('strike',2100,3); ai.strikeTimer.ElapsedSimTimeMS=0; noOffense(a,ai)
    a,ai=setup('strike',2100,3); ai.funds=200; noOffense(a,ai)
    a,ai=setup('strike',2100,3)
    local ally=CreateAHuman('friendly'); ally.Team=1; ally.Pos=Vector(2250,565); MovableMan:AddActor(ally)
    noOffense(a,ai)
    a,ai=setup('strike',500,3); noOffense(a,ai)
    a,ai=setup('strike',2100,1); noOffense(a,ai)
    a,ai=setup('strike',2100,3); a.settings.callins=false; noOffense(a,ai)
    a,ai=setup('strike',2100,3); a.ShieldBlocks=function() return true end; noOffense(a,ai)
    a,ai=setup('strike',4800,3); noOffense(a,ai) -- friendly brain is inside the buffer
    a,ai=setup('strike',2100,3)
    local turret=CreateACrab('friendly turret'); turret.Team=1; turret.Pos=Vector(2250,565)
    ai.turret=turret; ai.turretID=turret.UniqueID; MovableMan:AddActor(turret)
    noOffense(a,ai)
    a,ai=setup('strike',2100,3)
    local ship=CreateACDropShip('friendly ship'); ship.Team=1; ship.Pos=Vector(2250,200)
    MovableMan:AddActor(ship)
    noOffense(a,ai)
    a,ai=setup('strike',2100,3)
    for _,actor in ipairs(actors) do
        if actor.Team==0 and actor.Pos.X>2000 then actor.Pos=Vector(actor.Pos.X,100) end
    end
    noOffense(a,ai)

    a,ai=setup('strike',750,1)
    local legal=CreateAHuman('enemy'); legal.Team=0; legal.Pos=Vector(810,565); MovableMan:AddActor(legal)
    a:UpdateAI()
    assert(a.pendingStrikes[1] and a.pendingStrikes[1].target.x==810,
        'an excluded first point must not hide a nearby legal concentration')

    a,ai=setup('strike',2100,3)
    a.outposts[3].owner=1
    for i=1,3 do
        local enemy=CreateAHuman('enemy'); enemy.Team=0; enemy.Pos=Vector(3500+i*15,565); MovableMan:AddActor(enemy)
    end
    a:UpdateAI()
    assert(a.pendingStrikes[1] and a.pendingStrikes[1].target.x>=3500,
        'equal clusters threatening a friendly outpost should take priority')

    -- A denser cluster must win even if a sparser group is iterated first.
    a,ai=setup('strike',1900,2)
    for i=1,4 do
        local enemy=CreateAHuman('enemy'); enemy.Team=0; enemy.Pos=Vector(3200+i*15,565); MovableMan:AddActor(enemy)
    end
    a:UpdateAI()
    assert(a.pendingStrikes[1] and a.pendingStrikes[1].target.x>=3200,
        'higher enemy density should beat the first sparse cluster')
end
print('AI targets safe feasible clusters with all three offensive supports')

-- Personas commit to distinct research and support policies through real
-- UpdateAI purchases and TeamCommander call-ins.
do
    local function researchChoice(personality)
        local a=newBattle(); a.aiPersonality=personality; a.aiTemperature=0.001
        a.settings.callins=false
        local ai=a.teams[1]
        ai.stats.deployed=3; ai.funds=1000; ai.timer.ElapsedSimTimeMS=0
        ai.baseArmor=3; ai.turret={Health=100}; ai.turretLevel=2
        for index=1,30 do ai.levels[index]=10 end
        ai.levels[21]=0; ai.levels[22]=0
        a:UpdateAI()
        assert(ai.lastAIAction and ai.lastAIAction.kind=='research',
            personality..' should make a real support-research purchase')
        return ai.lastAIAction.target,1000-ai.funds
    end
    local artilleryResearch,artilleryCost=researchChoice('artillery')
    local engineerResearch,engineerCost=researchChoice('engineer')
    assert(artilleryResearch==21 and artilleryCost==600
        and engineerResearch==22 and engineerCost==280,
        'artillery and engineer personas should purchase their distinct preferred support unlocks')

    local function supportChoice(personality)
        local a=newBattle(); a.aiPersonality=personality; a.aiTemperature=0.001
        a.settings.callins=true
        local ai=a.teams[1]
        ai.stats.deployed=3; ai.funds=420; ai.timer.ElapsedSimTimeMS=0
        ai.baseArmor=3; ai.turret={Health=100}; ai.turretLevel=2
        for index=1,30 do ai.levels[index]=10 end
        ai.levels[21]=1; ai.levels[22]=1; ai.levels[24]=0; ai.levels[25]=0
        for i=1,2 do
            local ally=CreateAHuman('field squad'); ally.Team=1
            ally.Pos=Vector(2100+i*10,565); MovableMan:AddActor(ally)
        end
        local fieldThreat=CreateAHuman('field threat'); fieldThreat.Team=0
        fieldThreat.Pos=Vector(2450,565); MovableMan:AddActor(fieldThreat)
        for i=1,2 do
            local enemy=CreateAHuman('enemy concentration'); enemy.Team=0
            enemy.Pos=Vector(3200+i*20,565); MovableMan:AddActor(enemy)
        end
        a:UpdateAI()
        return a,ai
    end
    local artillery,artilleryAI=supportChoice('artillery')
    assert(#artillery.pendingOrbitals==1 and #artillery.pendingDrops==0
        and artilleryAI.funds==420-175 and artilleryAI.orbitalTimer.ElapsedSimTimeMS==0,
        'artillery persona should choose a feasible researched orbital offense and pay its normal cost')
    local engineer,engineerAI=supportChoice('engineer')
    local fieldCover=engineer.pendingDrops[1]
    assert(fieldCover and fieldCover.kind=='cover' and #engineer.pendingOrbitals==0
        and fieldCover.target.name=='field squad' and fieldCover.target.x>=2100
        and fieldCover.target.x<=2120 and fieldCover.target.groundY==600
        and engineerAI.funds==420-140 and engineerAI.coverTimer.ElapsedSimTimeMS==0,
        'engineer persona should choose safe squad-position Cover over the available offensive alternative')
end

-- Cover protects legal field squads at their measured ground position while
-- retaining ordinary outpost support and all normal call-in gates.
do
    local function fieldCoverSetup(options)
        options=options or {}
        local a=newBattle(); a.aiPersonality='engineer'; a.aiTemperature=0.001
        a.settings.callins=options.callins~=false
        if options.matchTime then a.matchTimer.ElapsedSimTimeMS=options.matchTime end
        local ai=a.teams[1]
        ai.stats.deployed=3; ai.funds=options.funds or 400; ai.timer.ElapsedSimTimeMS=0
        ai.baseArmor=3; ai.turret={Health=100}; ai.turretLevel=2
        for index=1,30 do ai.levels[index]=10 end
        ai.levels[22]=options.coverLevel==nil and 1 or options.coverLevel
        if options.coverTimer then ai.coverTimer.ElapsedSimTimeMS=0 end
        local x=options.x or 2100
        if options.allies~=false then
            for i=1,2 do
                local ally=CreateAHuman('field squad'); ally.Team=1
                ally.Health=options.deadAllies and 0 or 100
                ally.Pos=Vector(x+i*10,565); MovableMan:AddActor(ally)
            end
        end
        if options.enemy~=false then
            local enemy=CreateAHuman('field threat'); enemy.Team=0
            enemy.Pos=Vector(options.enemyX or x+350,565); MovableMan:AddActor(enemy)
        end
        if options.jammer then
            a.jamFields[#a.jamFields+1]={x=x+15,team=0,timer=Timer(),duration=60000}
        end
        return a,ai
    end
    local a,ai=fieldCoverSetup()
    a:UpdateAI()
    local order=a.pendingDrops[1]
    assert(order and order.kind=='cover' and order.target.name=='field squad'
        and math.abs(order.target.x-2115)<=5 and order.target.groundY==600
        and math.abs(order.target.x-a.outposts[2].x)>180
        and ai.funds==260 and ai.coverTimer.ElapsedSimTimeMS==0,
        'field Cover must use a legal ground-probed squad location and the ordinary cost/cooldown')
    local function noFieldCover(a,reason)
        a:UpdateAI()
        for _,drop in ipairs(a.pendingDrops) do
            assert(drop.kind~='cover',reason)
        end
    end
    a=fieldCoverSetup({allies=false}); noFieldCover(a,'an enemy alone must not create a field Cover target')
    a=fieldCoverSetup({deadAllies=true}); noFieldCover(a,'dead friendly units cannot anchor Cover')
    a=fieldCoverSetup({enemyX=2160}); noFieldCover(a,'Cover must not drop into an enemy collision zone')
    a=fieldCoverSetup({enemyX=3000}); noFieldCover(a,'Cover requires a threatened squad or a deployment wave')
    a=fieldCoverSetup({x=700,enemyX=1050}); noFieldCover(a,'the enemy-base exclusion applies to field Cover')
    a=fieldCoverSetup({jammer=true}); noFieldCover(a,'an enemy jammer blocks the field Cover target')
    a=fieldCoverSetup({funds=379}); noFieldCover(a,'field Cover retains the AI call-in reserve requirement')
    a=fieldCoverSetup({coverTimer=true}); noFieldCover(a,'field Cover respects its normal cooldown')
    a=fieldCoverSetup({coverLevel=0}); noFieldCover(a,'field Cover still requires its research unlock')
    a=fieldCoverSetup({callins=false}); noFieldCover(a,'disabled call-ins cannot create field Cover')
    a=fieldCoverSetup({matchTime=14999}); noFieldCover(a,'the match grace period blocks field Cover')
end

-- The actual AI investment loop can buy both later support tiers.
for _,index in ipairs({22,23}) do
    local a=newBattle()
    local ai=a.teams[1]
    for i=1,29 do ai.levels[i]=10 end
    ai.levels[index]=1
    ai.baseArmor=3; ai.turret={Health=100}; ai.turretLevel=2
    ai.timer.ElapsedSimTimeMS=0
    for level=2,3 do
        ai.funds=5000
        local price=a:ResearchCost(1,index)
        a:UpdateAI()
        assert(ai.levels[index]==level and ai.lastAIAction.kind=='research'
            and ai.lastAIAction.target==index and ai.funds==5000-price,
            'AI must purchase each available Cover/Mines tier at its normal price')
    end
end
print('AI purchases Cover and Mines research levels 2 and 3')
-- The real AI investment loop rebuilds a destroyed, upgraded base turret.
do
    local a=newBattle()
    local ai=a.teams[1]
    ai.baseArmor=3
    for i=1,29 do ai.levels[i]=10 end
    a.settings.callins=false
    ai.funds=1000
    assert(a.commanders[1]:BaseUpgrade('turretUpgrade'),'fixture should begin with an upgraded AI turret')
    ai.funds=649
    for i=1,50 do
        local unit=CreateAHuman('field unit'); unit.Team=1
        unit.Pos=Vector(a.brains[1].Pos.X,565); MovableMan:AddActor(unit)
    end
    ai.funds=649
    ai.turret.Health=0
    a:UpdateAI()
    assert(ai.turret.Health==0 and ai.funds==649,
        'deferred rebuild mismatch: funds='..ai.funds..' action='..tostring(ai.lastAIAction and ai.lastAIAction.kind)..':'..tostring(ai.lastAIAction and ai.lastAIAction.target))
    ai.funds=650
    a:UpdateAI()
    assert(ai.turret~=nil and ai.turret.Health==200 and ai.turret.MaxHealth==200
        and ai.turret.name=='Frontline HE Turret' and ai.turretLevel==2
        and ai.funds==300 and ai.lastAIAction.kind=='baseUpgrade'
        and ai.lastAIAction.target=='turret',
        'AI should rebuild the destroyed turret as a full-health HE Mk2 for 350 oz')
end
print('AI rebuilds destroyed upgraded base turret after reserve is available')
