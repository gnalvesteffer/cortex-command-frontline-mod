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
local heavyBomb=supportLabels:find('500KG BOMB',1,true)
assert(barrage and precision and heavyBomb and barrage<precision and precision<heavyBomb, 'offensive supports must use the requested names and order')
assert(supportLabels:find('LOCKED',1,true), 'unresearched support options must display locked states')
local team=activity.teams[0]; team.funds=10000
local target=activity.outposts[2]
for _,kind in ipairs({'strike','medic','cover','mines','bomb','turret','orbital','shield','mining'}) do
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
assert(activity:Research(0,11)); assert(activity:Research(0,13)); assert(activity:Research(0,15))
assert(not activity:Research(0,25), 'precision strike must require orbital barrage research')
assert(not activity:Research(0,26), '500kg bomb must require precision-strike research')
assert(activity:Research(0,22))
assert(activity:Research(0,25))
assert(activity:Research(0,26))
assert(activity:Research(0,23))
assert(not activity:Research(0,27), 'turret must require minefield research')
assert(activity:Research(0,24)); assert(activity:Research(0,27))
local injured=CreateAHuman('Soldier Light','Coalition.rte'); injured.Team=0; injured.Pos=Vector(target.x,565); injured.Health=50; injured.MaxHealth=100; table.insert(actors,injured)
assert(activity:CallIn(0,'medic',2)); assert(injured.Health==100)
local shieldOK,shieldMessage=activity:CallIn(0,'shield',2); assert(shieldOK,shieldMessage); assert(activity.jamFields[#activity.jamFields].duration==60000)
assert(activity:CallIn(0,'mining',2)); local mining=activity.pendingDrops[#activity.pendingDrops]; assert(mining.kind=='mining' and mining.miner)
assert(activity:Research(0,12)); assert(activity:Research(0,14))
injured.Health=50; team.medicTimer.ElapsedSimTimeMS=30000
assert(activity:CallIn(0,'medic',2)); assert(injured.Health==100)
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
print('Support research gates, medic/shield upgrades, mining dispatch, and bomb targeting passed')
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
local treeBomb=treeLabels:find('500kg Bomb',1,true)
assert(treeBarrage and treePrecision and treeBomb and treeBarrage<treePrecision and treePrecision<treeBomb, 'tech tree must display the requested offensive progression')
activity.tab='Support'; activity:DrawPanel()
activity.tab='Squad'; activity:DrawPanel()
print('All research tree pages, support UI ordering, and squad roster render without Lua errors')
