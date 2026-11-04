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
FrameMan={IsHudDisabled=function() return false end,SetHudDisabled=function() end}
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
    activity.aiPersonality='balanced'
    activity:StartBattle()
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
    assert(not activity:Deploy(0),'an unaffordable batch must fail')
    assert(player.funds==beforeFunds and player.stats.deployed==0,'failed deployment must not charge or add units')
    player.funds=1000
    local cost=activity:Batch(0)
    assert(activity:Deploy(0),'an affordable, ready batch must deploy')
    assert(player.stats.deployed==3 and player.funds==1000-cost,'successful deployment must charge for exactly its batch')
    assert(activity.playerBehavior.lastDeployTime==15000 and activity.playerBehavior.lastDeploymentCount==3,
        'the observed deployment includes its match time and actual batch size')
    assert(not activity:Deploy(0),'an immediate second batch must respect the deployment cooldown')
    assert(player.stats.deployed==3 and player.funds==1000-cost,'cooldown failure must not spend or deploy')
    activity:UpdateAI()
    assert(activity.playerBehavior.deployments==1,'AI must observe one successful player deployment, not failed attempts')
    activity:UpdateAI()
    assert(activity.playerBehavior.deployments==1,'AI decisions must not count the same deployment twice')
    player.timer.ElapsedSimTimeMS=100000
    local createGun=CreateHDFirearm
    CreateHDFirearm=function() return nil end
    assert(not activity:Deploy(0),'a missing equipment preset must reject the whole batch')
    CreateHDFirearm=createGun
    assert(activity.playerBehavior.deployments==1 and player.stats.deployed==3 and player.funds==1000-cost,
        'a failed construction must not record or charge a deployment')
    assert(activity:Deploy(0),'a later valid batch must deploy')
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
    assert(not activity:Research(0,1),'unaffordable research must fail')
    player.funds=5000
    assert(activity:Research(0,1),'affordable unlocked research must succeed')
    assert(activity.playerBehavior.researchPurchases==1,'only successful player research must be observed')
    assert(activity.playerBehavior.lastResearchIndex==1,'the observed research identifies the purchased upgrade')
    activity.settings.callins=true
    player.levels[24]=1
    assert(activity:CallIn(0,'strike',2),'unlocked, ready strike must succeed')
    assert(not activity:CallIn(0,'strike',2),'strike cooldown must reject a second call')
    assert(activity.playerBehavior.callinsUsed==1,'only successful player call-ins must be observed')
    assert(activity.playerBehavior.lastCallin=='strike','the observed call-in identifies the successful support kind')
    local enemy=activity.teams[1]
    enemy.funds=5000
    enemy.levels[24]=1
    assert(activity:Research(1,1) and activity:CallIn(1,'strike',2),'the opponent can also purchase research and support')
    assert(activity.playerBehavior.researchPurchases==1 and activity.playerBehavior.callinsUsed==1,
        'opponent purchases must not be attributed to the player')
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

print('AI deployment accounting, base emergency recovery, budget and cooldown passed')
