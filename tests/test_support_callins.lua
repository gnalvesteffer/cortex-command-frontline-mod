Frontline={}; Actor={AIMODE_SENTRY=1,AIMODE_BRAINHUNT=2,AIMODE_GOTO=3,AIMODE_DELIVER=5,AIMODE_RETURN=6}; Controller={CIM_AI=1,CIM_DISABLED=0}; Activity={OBSERVE=1,OVER=2,NOTEAM=-1}
Key={TAB=1}; MouseButtons={MOUSE_LEFT=1,MOUSE_RIGHT=2}; rte={goldID=2}
function Timer() return {ElapsedSimTimeMS=0, IsPastSimMS=function(s,n) return s.ElapsedSimTimeMS>=n end, Reset=function(s) s.ElapsedSimTimeMS=0 end} end
function Vector(x,y) return setmetatable({X=x,Y=y},{__add=function(a,b) return Vector(a.X+b.X,a.Y+b.Y) end}) end
local nextId=0
function CreateAHuman(n,m) nextId=nextId+1; return {Team=0,UniqueID=nextId,name=n,Health=100,MaxHealth=100,Height=70,AddInventoryItem=function(self,item) self.inventory=item end,ClearAIWaypoints=function(self) self.waypoint=nil end,AddAISceneWaypoint=function(self,v) self.waypoint=v end} end
function CreateACrab(n,m) local a=CreateAHuman(n,m); a.vehicle=true; return a end
function CreateACDropShip(n,m)
    nextId=nextId+1
    return {name=n,ship=true,UniqueID=nextId,MaxPassengers=4,MaxInventoryMass=800,InventorySize=0,cargo={},Pos=Vector(0,0),Health=100,
        SetControllerMode=function(self,mode) self.controller=mode end,
        SetGoldValue=function(self,value) self.goldValue=value end,
        GetTotalValue=function(self) return self.returnValue or 0 end,
        OpenHatch=function(self) self.hatchOpen=true end,
        RemoveInventoryItemAtIndex=function(self,index) local item=table.remove(self.cargo,index+1); self.InventorySize=#self.cargo; return item end,
        AddInventoryItem=function(self,item) table.insert(self.cargo,item); self.InventorySize=#self.cargo end}
end
function CreateHDFirearm(n,m) return {name=n} end
function CreateTDExplosive(n,m) return {name=n,GibThis=function(self) self.gibbed=true end,Activate=function(self) self.activated=true end} end
function CreateMOSRotating(n,m) return {name=n} end
function ToTDExplosive(item) return item end
function CreateMOPixel(n,m) return {name=n} end
function CreateSoundContainer() return {Play=function(self) self.playCount=(self.playCount or 0)+1 end} end
function CreateTerrainObject(name) return {name=name} end
local actors={}; MovableMan={Actors=(function() local i=0; return function() i=i+1; if not actors[i] then i=0; return nil end; return actors[i] end end)(), AddActor=function(s,a) table.insert(actors,a) end, AddParticle=function(s,p) s.lastParticle=p; s.particleCount=(s.particleCount or 0)+1; s.particles=s.particles or {}; table.insert(s.particles,p) end, IsActor=function(s,a) return a~=nil and not a.deleted end}
MovableMan.Particles=(function() local i=0; return function() i=i+1; local items=MovableMan.particles or {}; if not items[i] then i=0; return nil end; return items[i] end end)()
function IsAHuman(a) return not a.vehicle and not a.ship end; function IsACrab(a) return a.vehicle==true end
local sceneObjects={}
SceneMan={SceneWidth=5200, SceneHeight=800, CastMaterialRay=function() return false end, AddSceneObject=function(_,o) table.insert(sceneObjects,o) end, MovePointToGround=function(_,p) return Vector(p.X,600) end, Add=function(_,name,pos,team) local actor=CreateAHuman(name,"Dummy.rte"); actor.Team=team; actor.Pos=pos; table.insert(actors,actor); return actor end}; MusicMan={PlayDynamicSong=function() end}
FrameMan={IsHudDisabled=function() return false end,SetHudDisabled=function() end}; PrimitiveMan={DrawLinePrimitive=function() end,DrawTextPrimitive=function() end}
TimerMan={DeltaTimeSecs=1}; UInputMan={KeyPressed=function()return false end}; ActivityMan={EndActivity=function() end}
function Frontline:SetPlayerBrain() end; function Frontline:SetViewState() end; function Frontline:SetObservationTarget() end
function Frontline:GetTeamDeathCount(team) return self.deathCounts[team] end
assert(loadfile('Frontline.rte/Frontline.lua'))()
local activity=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
activity:StartActivity(); activity:StartBattle(); activity.matchTimer.ElapsedSimTimeMS=15000
assert(activity.teams[0].counts[6]==2 and activity.teams[1].counts[6]==2, 'both teams must start with two Ronin Bandits selected')
activity:UpdateAI()
assert(activity:UnitCount(1)==2, 'AI first deployment must be exactly two Ronin Bandits')
local panelText={}
activity.UIDrawBoxFill=function() end
activity.UIDrawBox=function() end
activity.UIDrawText=function(_,_,_,label) panelText[#panelText+1]=label end
CameraMan={GetOffset=function() return Vector(0,0) end}
UInputMan.GetMouseMovement=function() return Vector(0,0) end
UInputMan.MouseButtonPressed=function() return false end
activity.tab='Support'; activity:DrawPanel()
local supportLabels=table.concat(panelText,' ')
local barrage=supportLabels:find('ORBITAL GATLING BARRAGE',1,true)
local strategicChoices={
    {kind='advance',neutral=true,enemies=0,target=1},
    {kind='defend',threats=1,allies=1,target=2},
}
activity.aiPersonality='aggressive'
assert(activity:ChooseAIAction(strategicChoices,true).kind=='advance', 'aggressive AI should take a neutral post while pressure is manageable')
activity.aiPersonality='defensive'
assert(activity:ChooseAIAction(strategicChoices,true).kind=='defend', 'defensive AI should protect a threatened owned post under pressure')
activity.aiPersonality='economic'
local economyChoices={
    {kind='advance',neutral=true,enemies=0,target=1},
    {kind='mine',incomePost=true,target=2},
}
assert(activity:ChooseAIAction(economyChoices,false).kind=='mine', 'economic AI should prefer mining when its income utility exceeds a neutral advance')
local precision=supportLabels:find('ORBITAL PRECISION STRIKE',1,true)
local carpetBomb=supportLabels:find('CARPET BOMB',1,true)
local bubbleShield=supportLabels:find('ENERGY SHIELD',1,true)
assert(barrage and precision and carpetBomb and barrage<precision and precision<carpetBomb, 'offensive supports must use the requested names and order')
assert(bubbleShield and supportLabels:find('LOCKED',1,true), 'unresearched supports, including energy shield, must display locked states')
local team=activity.teams[0]; team.funds=25000
local target=activity.outposts[2]
local expectedCosts={[1]=300,[2]=360,[3]=320,[4]=500,[5]=700,[6]=1000,[7]=300,[8]=340,[9]=400,[10]=600,[11]=400,[12]=700,[13]=500,[14]=800,[15]=400,[16]=500,[17]=700,[18]=400,[19]=440,[20]=480,[21]=600,[22]=600,[23]=280,[24]=360,[25]=800,[26]=1000,[27]=520,[28]=1200}
for index,price in pairs(expectedCosts) do
    assert(activity:ResearchCost(0,index)==price, 'research index '..index..' should cost '..price..' oz before outpost discount')
end
for _,kind in ipairs({'strike','medic','cover','mines','bomb','turret','orbital','shield','bubble','mining'}) do
    local ok,message=activity:CallIn(0,kind,2)
    assert(not ok and message:find('Research',1,true), kind..' must be gated by its research node')
end
assert(not activity:Research(0,4), 'Coalition Heavy must require Coalition Light research')
assert(activity:Research(0,1)); assert(not activity:Research(0,5))
assert(activity:Research(0,4) and team.tier==1)
assert(not activity:Research(0,6), 'Browncoat must require Dummy / Gatling research')
assert(activity:Research(0,5) and team.tier==2)
assert(activity:Research(0,6) and team.tier==3)
assert(not activity:Research(0,12), 'medic level 2 must require level 1')
assert(not activity:Research(0,14), 'shield level 2 must require level 1')
assert(activity:Research(0,11)); assert(not activity:Research(0,13), 'Shield Lv.1 must require Cover'); assert(activity:Research(0,15))
assert(not activity:Research(0,25), 'precision strike must require orbital barrage research')
assert(not activity:Research(0,26), 'Carpet Bomb must require precision-strike research')
assert(activity:Research(0,22))
assert(activity:Research(0,25))
assert(activity:Research(0,26))
assert(activity:Research(0,23)); assert(activity:Research(0,13))
assert(not activity:Research(0,27), 'turret must require minefield research')
assert(activity:Research(0,24)); assert(activity:Research(0,27))
local actorsBeforeTurret=#actors
assert(activity:CallIn(0,'turret',2))
local turret=activity.pendingDrops[#activity.pendingDrops]
assert(turret.count==1, 'turret drops must provide an explicit single-item cargo count')
turret.timer.ElapsedSimTimeMS=4000; activity:UpdateCallIns()
assert(turret.ship and turret.ship.cargo[1].name=='Gatling Turret')
turret.arrivalTimer.ElapsedSimTimeMS=2000; activity:UpdateCallIns()
assert(#actors==actorsBeforeTurret+2 and actors[#actors].name=='Gatling Turret' and actors[#actors].Team==0,
    'turret dropship must deliver its turret without a nil loop limit')
local injured=CreateAHuman('Soldier Light','Coalition.rte'); injured.Team=0; injured.Pos=Vector(target.x,565); injured.Health=50; injured.MaxHealth=100; table.insert(actors,injured)
local actorsBeforeMedic=#actors
assert(activity:CallIn(0,'medic',2)); assert(injured.Health==50, 'medic support must deploy a robot, not heal instantly')
local medic=activity.pendingDrops[#activity.pendingDrops]
assert(medic.kind=='medic' and medic.count==1)
medic.timer.ElapsedSimTimeMS=4000; activity:UpdateCallIns()
assert(medic.ship and medic.ship.cargo[1].name=='Medic Drone')
medic.arrivalTimer.ElapsedSimTimeMS=2000; activity:UpdateCallIns()
assert(#actors==actorsBeforeMedic+2 and actors[#actors].name=='Medic Drone' and actors[#actors].Team==0)
local shieldOK,shieldMessage=activity:CallIn(0,'shield',2); assert(shieldOK,shieldMessage); assert(activity.jamFields[#activity.jamFields].duration==60000)
assert(activity:CallIn(0,'mining',2)); local mining=activity.pendingDrops[#activity.pendingDrops]; assert(mining.kind=='mining' and mining.miner)
local medicUpgrade,medicUpgradeError=activity:Research(0,12); assert(medicUpgrade,medicUpgradeError)
assert(not activity:Research(0,28), 'energy shield must require Shield Lv.2')
local shieldUpgrade,shieldUpgradeError=activity:Research(0,14); assert(shieldUpgrade,shieldUpgradeError)
local bubbleUnlock,bubbleUnlockError=activity:Research(0,28); assert(bubbleUnlock,bubbleUnlockError)
assert(activity:CallIn(0,'bubble',2))
local bubble=activity.energyShields[#activity.energyShields]
local hostile={Team=1,HitsMOs=true,Pos=Vector(bubble.x,bubble.centerY)}
local friendly={Team=0,HitsMOs=true,Pos=Vector(bubble.x,bubble.centerY)}
local outside={Team=1,HitsMOs=true,Pos=Vector(bubble.x+bubble.radius+1,bubble.centerY)}
MovableMan:AddParticle(hostile); MovableMan:AddParticle(friendly); MovableMan:AddParticle(outside)
activity:UpdateEnergyShields()
assert(hostile.ToDelete and not friendly.ToDelete and not outside.ToDelete,
    'energy shield must remove hostile projectiles in range but preserve friendly and outside projectiles')
injured.Health=50; team.medicTimer.ElapsedSimTimeMS=30000
local actorsBeforeUpgrade=#actors
assert(activity:CallIn(0,'medic',2)); local upgradedMedic=activity.pendingDrops[#activity.pendingDrops]
assert(upgradedMedic.count==2, 'Medic Drone Lv.2 must deliver two robots')
upgradedMedic.timer.ElapsedSimTimeMS=4000; activity:UpdateCallIns()
assert(upgradedMedic.ship.InventorySize==2)
upgradedMedic.arrivalTimer.ElapsedSimTimeMS=2000; activity:UpdateCallIns()
assert(#actors==actorsBeforeUpgrade+3 and actors[#actors].name=='Medic Drone' and actors[#actors-1].name=='Medic Drone')
team.shieldTimer.ElapsedSimTimeMS=60000; assert(activity:CallIn(0,'shield',2)); assert(activity.jamFields[#activity.jamFields].duration==90000)
mining.timer.ElapsedSimTimeMS=4000; activity:UpdateCallIns(); assert(mining.arrivalTimer and mining.ship)
assert(mining.ship.cargo[1]==mining.miner, 'dropship inventory must carry the researched Dummy miner')
mining.arrivalTimer.ElapsedSimTimeMS=2000; activity:UpdateCallIns()
assert(mining.miner.Pos.X==target.x and mining.miner.Pos.Y==592 and mining.miner.PinStrength==0)
team.minesTimer.ElapsedSimTimeMS=45000
assert(activity:CallIn(0,'bomb',2)); local bomb=activity.pendingDrops[#activity.pendingDrops]
assert(bomb.startX==target.x-120 and bomb.flightDistance==360)
bomb.timer.ElapsedSimTimeMS=800; activity:UpdateCallIns()
local dropped=MovableMan.lastParticle
assert(dropped.name=='Bomb Run Bomb' and math.abs(dropped.Pos.X-target.x)<=24, 'first scripted bomb must land near the selected target')
assert(dropped.Team==0 and bomb.bombsDropped==1)
assert(dropped.Pos.Y>bomb.ship.Pos.Y+(bomb.ship.Radius or 50), 'bomb must clear the dropship collision envelope before falling')
print('Support research gates, medical robot deliveries, shield upgrades, mining dispatch, and bomb targeting passed')
activity.UIDrawBoxFill=function() end
activity.UIDrawBox=function() end
local treeText={}
activity.UIDrawText=function(_,_,_,label) treeText[#treeText+1]=label end
CameraMan={GetOffset=function() return Vector(0,0) end}
UInputMan.GetMouseMovement=function() return Vector(0,0) end
UInputMan.MouseButtonPressed=function() return false end
activity.tab='Squad'; activity:DrawPanel()
for page=1,3 do activity.researchPage=page; activity.tab='Research'; activity:DrawPanel() end
local treeLabels=table.concat(treeText,' ')
local treeBarrage=treeLabels:find('Orbital Gatling Barrage',1,true)
local treePrecision=treeLabels:find('Orbital Precision Strike',1,true)
local treeCarpetBomb=treeLabels:find('Carpet Bomb',1,true)
local treeEnergyShield=treeLabels:find('Energy Shield',1,true)
local treeCover=treeLabels:find('Cover',1,true)
local treeShield=treeLabels:find('SHIELD I 60s',1,true)
assert(treeBarrage and treePrecision and treeCarpetBomb and treeBarrage<treePrecision and treePrecision<treeCarpetBomb,
    'tech tree must display the requested offensive progression')
assert(treeCover and treeShield and treeCover<treeShield and treeEnergyShield and treeEnergyShield>treeShield,
    'Cover must precede Shield Lv.1 and Energy Shield must appear after Shield Lv.2')
local buttonDown
UInputMan.MouseButtonPressed=function(_,which) return buttonDown==which end
local function clickPanel(x,y,which)
    activity.cursorX=x; activity.cursorY=y; buttonDown=which; activity:DrawPanel()
end
activity.tab='Research'; activity.researchPage=1
clickPanel(400,85,MouseButtons.MOUSE_RIGHT)
assert(activity.researchPage==3, 'right-clicking the research page control must wrap backward')
clickPanel(400,85,MouseButtons.MOUSE_LEFT)
assert(activity.researchPage==1, 'left-clicking the research page control must wrap forward')
activity.tab='Squad'
local squad=activity.teams[0]
squad.orderTarget=1
clickPanel(400,165,MouseButtons.MOUSE_RIGHT)
assert(squad.orderTarget==#activity.outposts, 'right-clicking NEXT must select the previous target and wrap')
clickPanel(400,165,MouseButtons.MOUSE_LEFT)
assert(squad.orderTarget==1, 'left-clicking NEXT must select the next target and wrap')
clickPanel(320,158,MouseButtons.MOUSE_LEFT)
assert(squad.orderTarget==#activity.outposts, 'left-clicking PREV must move backward and wrap')
clickPanel(320,158,MouseButtons.MOUSE_RIGHT)
assert(squad.orderTarget==1, 'right-clicking PREV must reverse direction and move forward')
squad.counts[6]=0
clickPanel(280,100,MouseButtons.MOUSE_RIGHT)
assert(squad.counts[6]==0, 'right-clicking + at zero must not decrement below zero')
clickPanel(280,100,MouseButtons.MOUSE_LEFT)
assert(squad.counts[6]==1, 'left-clicking + must increment the count')
clickPanel(235,100,MouseButtons.MOUSE_RIGHT)
assert(squad.counts[6]==2, 'right-clicking - must increment the count')
clickPanel(235,100,MouseButtons.MOUSE_LEFT)
assert(squad.counts[6]==1, 'left-clicking - must decrement the count')
activity.setupStep=1
activity.settings.startFunds=450
activity.cursorX=100; activity.cursorY=95; buttonDown=MouseButtons.MOUSE_LEFT; activity:DrawWizard()
assert(activity.settings.startFunds==750, 'wizard left-click must advance the funds value')
buttonDown=MouseButtons.MOUSE_RIGHT; activity:DrawWizard()
assert(activity.settings.startFunds==450, 'wizard right-click must return to the previous funds value')
buttonDown=nil
activity.tab='Support'; activity:DrawPanel()
activity.tab='Squad'; activity:DrawPanel()
-- The AI regroups at a safe captured post, advances as a single force, and retargets after capture.
for _,actor in ipairs(actors) do
    if actor.Team==0 and activity:IsFieldUnit(actor) then actor.Team=2 end
end
local ai=activity.teams[1]
local rally=activity.outposts[1]
rally.owner=1
ai.funds=0
ai.orderPhase=nil; ai.attackTarget=nil; ai.rallyTarget=nil
local staged=0
for _,actor in ipairs(actors) do
    if actor.Team==1 and activity:IsFieldUnit(actor) then
        actor.Pos=Vector(rally.x,rally.groundY)
        staged=staged+1
    end
end
assert(staged==2, 'AI begins with its two starting Ronin Bandits')
activity:UpdateAI()
assert(ai.orderPhase=='assembling' and ai.order=='Defend' and ai.orderTarget==1,
    'AI should hold a captured outpost and assemble before attacking')
for i=1,4 do
    local actor=CreateAHuman('Ronin Bandit','Ronin.rte')
    actor.Team=1; actor.Pos=Vector(rally.x,rally.groundY)
    MovableMan:AddActor(actor)
end
activity:UpdateAI()
local firstTarget=ai.attackTarget
assert(ai.orderPhase=='attacking' and ai.order=='Advance' and firstTarget and firstTarget~=1,
    'AI should mass-advance once six allies are gathered at a post')
activity:UpdateAI()
assert(ai.attackTarget==firstTarget and ai.orderTarget==firstTarget,
    'AI should retain an active objective instead of oscillating targets')
activity.outposts[firstTarget].owner=1
activity:UpdateAI()
assert(ai.orderPhase=='attacking' and ai.attackTarget~=firstTarget,
    'AI should retarget after capturing its current objective')
-- An urgent threat overrides a more attractive attack order.
local threat=CreateAHuman('Soldier Light','Coalition.rte')
threat.Team=0; threat.Pos=Vector(rally.x,rally.groundY); MovableMan:AddActor(threat)
ai.orderPhase='attacking'; ai.attackTarget=firstTarget; ai.orderTarget=firstTarget
activity:UpdateAI()
assert(ai.order=='Defend' and ai.orderTarget==1 and ai.rallyTarget==1,
    'urgent defense must order the force to the threatened owned post')
threat.Team=2


-- In the final approach to a researched upgrade, pause automatic deployment and use owned forward posts.
for index=1,28 do ai.levels[index]=10 end
ai.levels[28]=0
ai.funds=1040; ai.baseArmor=99; ai.turret={}
ai.timer.ElapsedSimTimeMS=100000
activity.settings.callins=false
local deploymentsBeforeSaving=ai.stats.deployed
activity:UpdateAI()
assert(ai.autoDeploy==false and ai.stats.deployed==deploymentsBeforeSaving,
    'AI should save a near-term research purchase rather than auto-deploying')
activity.aiTimer.ElapsedSimTimeMS=0
activity.panel=false
activity.DrawOutpost=function() end
activity.DrawHUD=function() end
activity:UpdateActivity()
assert(ai.stats.deployed==deploymentsBeforeSaving,
    'the regular activity update must not bypass the AI research-saving gate')
assert(ai.forward>0 and activity.outposts[ai.forward].owner==1,
    'AI should choose a safe outpost it owns for a forward deployment')
ai.levels[28]=1
activity:UpdateAI()
assert(ai.stats.deployed>deploymentsBeforeSaving and ai.forward>0 and activity.outposts[ai.forward].owner==1,
    'AI should resume deployment at an owned forward post after its savings goal is met')
print('AI rally, coordinated advance, retargeting, research saving, and forward deployment passed')
print('Research pricing/progression, reversible UI controls, tech tree, and support panels passed')
