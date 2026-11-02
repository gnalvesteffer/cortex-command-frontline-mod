Frontline={}; Actor={AIMODE_SENTRY=1,AIMODE_BRAINHUNT=2,AIMODE_GOTO=3,AIMODE_DELIVER=5}; Controller={CIM_AI=1}; Activity={OBSERVE=1,OVER=2,NOTEAM=-1}
Key={TAB=1}; MouseButtons={MOUSE_LEFT=1,MOUSE_RIGHT=2}; rte={goldID=2}
function Timer() return {ElapsedSimTimeMS=0, IsPastSimMS=function(s,n) return s.ElapsedSimTimeMS>=n end, Reset=function(s) s.ElapsedSimTimeMS=0 end} end
function Vector(x,y) return setmetatable({X=x,Y=y},{__add=function(a,b) return Vector(a.X+b.X,a.Y+b.Y) end}) end
local nextId=0
function CreateAHuman(n,m) nextId=nextId+1; return {Team=0,UniqueID=nextId,name=n,Health=100,MaxHealth=100,Height=70,AddInventoryItem=function(self,item) self.inventory=item end,ClearAIWaypoints=function(self) self.waypoint=nil end,AddAISceneWaypoint=function(self,v) self.waypoint=v end} end
function CreateACrab(n,m) local a=CreateAHuman(n,m); a.vehicle=true; return a end
function CreateACDropShip(n,m)
    nextId=nextId+1
    return {name=n,ship=true,UniqueID=nextId,MaxPassengers=4,MaxInventoryMass=800,InventorySize=0,cargo={},
        SetControllerMode=function(self,mode) self.controller=mode end,
        AddInventoryItem=function(self,item) table.insert(self.cargo,item); self.InventorySize=#self.cargo end}
end
function CreateHDFirearm(n,m) return {name=n} end
function CreateTDExplosive(n,m) return {name=n,GibThis=function(self) self.gibbed=true end,Activate=function(self) self.activated=true end} end
function CreateMOSRotating(n,m) return {name=n} end
function CreateMOPixel(n,m) return {name=n} end
function CreateSoundContainer() return {Play=function(self) self.playCount=(self.playCount or 0)+1 end} end
function CreateTerrainObject(name) return {name=name} end
local actors={}; MovableMan={Actors=(function() local i=0; return function() i=i+1; if not actors[i] then i=0; return nil end; return actors[i] end end)(), AddActor=function(s,a) table.insert(actors,a) end, AddParticle=function(s,p) s.lastParticle=p; s.particleCount=(s.particleCount or 0)+1; s.particles=s.particles or {}; table.insert(s.particles,p) end, IsActor=function(s,a) return a~=nil and not a.deleted end}
function IsAHuman(a) return not a.vehicle and not a.ship end; function IsACrab(a) return a.vehicle==true end
local sceneObjects={}
SceneMan={SceneWidth=5200, SceneHeight=800, CastMaterialRay=function() return false end, AddSceneObject=function(_,o) table.insert(sceneObjects,o) end, MovePointToGround=function(_,p) return Vector(p.X,600) end}; MusicMan={PlayDynamicSong=function() end}
FrameMan={IsHudDisabled=function() return false end,SetHudDisabled=function() end}
PrimitiveMan={}
TimerMan={DeltaTimeSecs=1}; UInputMan={KeyPressed=function()return false end}
ActivityMan={EndActivity=function() end}
function Frontline:SetPlayerBrain() end; function Frontline:SetViewState() end; function Frontline:SetObservationTarget() end
function Frontline:GetTeamDeathCount(team) return self.deathCounts[team] end
assert(loadfile('Frontline.rte/Frontline.lua'))()
-- Legacy rules tests use the researched assault-rifle loadout for stable prices.
local startActivity=Frontline.StartActivity
function Frontline:StartActivity()
    startActivity(self)
    for team=0,1 do self.teams[team].levels[12]=1; self.teams[team].weapons={1,1,1,1,1,1,1} end
end
local a=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
a:StartActivity(); assert(a.brains[0].Pos.X==180 and a.brains[1].Pos.X==5020); assert(a.brains[0].inventory.name=="Gatling Gun" and a.brains[1].inventory.name=="Gatling Gun" and a.brains[1].HFlipped); assert(sceneObjects[1].name=="Tunnel A" and sceneObjects[2].name=="Tunnel A" and sceneObjects[3].name=="Tunnel A"); assert(sceneObjects[4].name=="Frontline Mirrored Brain Vault" and sceneObjects[4].Team==0); assert(sceneObjects[5].name=="Brain Vault" and not sceneObjects[5].HFlipped and sceneObjects[5].Team==1); a.panel=false
a.DrawHUD=function() end
a.DrawOutpost=function() end
local p=a.teams[0]; assert(p.auto and a.settings.unitCap==50); p.auto=false; a.settings.unitCap=12; assert(a:Batch(0)==210)
assert(not a:Deploy(0)); assert(a:AutoReason(0)=="Match setup"); a:StartBattle(); assert(a:AutoReason(0):find("Grace")); a.matchTimer.ElapsedSimTimeMS=15000
local ok=a:Deploy(0); assert(ok and p.funds==240 and a:UnitCount(0)==2)
assert(not a:Deploy(0)); assert(p.funds==240)
p.timer.ElapsedSimTimeMS=10000; p.funds=209; assert(not a:Deploy(0)); assert(p.timer.ElapsedSimTimeMS==10000)
p.funds=1000; p.counts={6,0,0,0}; assert(a:Deploy(0)); p.timer.ElapsedSimTimeMS=10000
assert(not a:Deploy(0)); assert(a:UnitCount(0)==8)
p.funds=2000; p.counts={1,0,0,0}; assert(not a:Research(0,4)); assert(a:Research(0,3)); assert(a:Research(0,4)); assert(p.tier==2)
p.auto=true; p.funds=1000; a.teams[1].auto=false; a:UpdateActivity(); assert(a:UnitCount(0)==9); assert(p.timer.ElapsedSimTimeMS==0)
a:UpdateActivity(); assert(a:UnitCount(0)==9)
local before=p.funds; a.deathCounts[1]=2; a:UpdateActivity(); assert(p.funds==before+75)
print('Frontline Lua rules: batch costs, cooldown, capacity, research, auto deploy and bounty passed')
FrameMan={PlayerScreenWidth=960,PlayerScreenHeight=540,IsHudDisabled=function() return false end,SetHudDisabled=function() end}
local cameraOffset=Vector(120,80); local target
CameraMan={GetOffset=function() return cameraOffset end, SetOffset=function(_,v) cameraOffset=v end, SetScrollTarget=function(_,v) target=v end}
a.DrawPanel=function() end
a.panel=true; a:UpdateActivity(); assert(cameraOffset.X==120 and cameraOffset.Y==80 and target.X==600 and target.Y==350)
cameraOffset=Vector(150,100); a:UpdateActivity(); assert(cameraOffset.X==120 and cameraOffset.Y==80)
a.panel=false; a:UpdateActivity(); assert(a.panelCameraOffset==nil)
print('Camera is held while panel is open and released when closed')
local labels={}
PrimitiveMan={DrawLinePrimitive=function() end,DrawBoxFillPrimitive=function() end,DrawBoxPrimitive=function() end,DrawTextPrimitive=function(_,_,_,s) labels[#labels+1]=s end}
Frontline.DrawHUD(a)
assert(#labels>=4 and labels[1]:find('FRONTLINE') and labels[2]:find('Funds:') and labels[3]:find('Batch:') and labels[4]:find('Deploy:'))
print('Compact HUD renders economy, batch, capacity, and deployment status')
-- Independent per-row weapons, research prerequisites, and preset composition.
actors={}
local b=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
b:StartActivity(); b:StartBattle(); b.DrawHUD=function() end; b.DrawOutpost=function() end
local t=b.teams[0]; t.funds=5000
assert(not b:Research(0,6)); assert(b:Research(0,3)); assert(b:Research(0,6))
t.counts={1,1,0,0}; t.weapons={4,2,1,1}
assert(b:Batch(0)==75+65+120+45)
b:SetPreset(0,'Specialist'); assert(t.counts[1]==2 and t.weapons[1]==4 and t.weapons[2]==2)
b:SaveSquad(0); t.counts[1]=0; t.weapons[1]=1; assert(b:LoadSquad(0)); assert(t.counts[1]==2 and t.weapons[1]==4)
b.matchTimer.ElapsedSimTimeMS=15000; assert(b:Deploy(0)); assert(not b:Deploy(0))
-- Capture progresses only for an uncontested side and grants income.
for _,v in ipairs(actors) do if v.Pos then v.Pos=Vector(100,565) end end
local fighter=CreateAHuman('Soldier Light','Coalition.rte'); fighter.Team=0; fighter.Pos=Vector(2600,565); MovableMan:AddActor(fighter)
local middle=b.outposts[2]
middle.progress=0; middle.owner=-1; b:UpdateOutpost(8)
assert(middle.owner==0 and middle.progress==1 and b:OutpostCount(0)==1)
local enemy=CreateAHuman('Soldier Light','Coalition.rte'); enemy.Team=1; enemy.Pos=Vector(2600,565); MovableMan:AddActor(enemy)
b:UpdateOutpost(8); assert(middle.progress==1)
fighter.Pos=Vector(100,565); b:UpdateOutpost(16); assert(middle.owner==1 and middle.progress==-1)
local west=b.outposts[1]; fighter.Pos=Vector(west.x,565); b:UpdateOutpost(8); assert(west.owner==0 and b:OutpostCount(0)==1 and b:OutpostCount(1)==1)
local east=b.outposts[3]; fighter.Pos=Vector(east.x,565); b:UpdateOutpost(8); assert(east.owner==0 and b:OutpostCount(0)==2)
print('Per-unit loadouts, research prerequisites, presets, grace and contested outpost passed')
-- All tabs and world marker use the supported primitive signatures.
UInputMan.GetMouseMovement=function() return Vector(0,0) end
UInputMan.MouseButtonPressed=function() return false end
for _,tab in ipairs({'Squad','Research','Battle','Support','Base','Setup'}) do b.tab=tab; Frontline.DrawPanel(b) end
Frontline.DrawOutpost(b)
print('Squad, research, battle panels and outpost marker render without Lua errors')

-- Call-ins enforce grace, resources, independent cooldowns, and target effects.
local c=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
actors={}; c:StartActivity(); c:StartBattle(); c.DrawHUD=function() end; c.DrawOutpost=function() end
local ct=c.teams[0]; ct.funds=1000
assert(not c:CallIn(0,'strike',2)); c.matchTimer.ElapsedSimTimeMS=15000
assert(c:CallIn(0,'strike',2)); assert(ct.funds==780 and #c.pendingStrikes==1)
assert(not c:CallIn(0,'strike',2)); c.pendingStrikes[1].timer.ElapsedSimTimeMS=3000
c:UpdateCallIns(); assert(#c.pendingStrikes==0 and MovableMan.lastParticle.gibbed and MovableMan.lastParticle.Team==0)
local injured=CreateAHuman('Soldier Light','Coalition.rte'); injured.Team=0; injured.Pos=Vector(c.outposts[2].x,565); injured.Health=70; injured.MaxHealth=100; MovableMan:AddActor(injured)
assert(c:CallIn(0,'medic',2)); assert(injured.Health==100 and ct.funds==660)
assert(not c:CallIn(0,'medic',2)); assert(not c:CallIn(0,'medic',4))
print('Call-in costs, cooldowns, targeting, warning delay, explosion and healing passed')

-- Cover and mines avoid occupied lanes and independently enforce cooldowns.
ct.funds=2000
local objectCount=#sceneObjects
assert(c:CallIn(0,'cover',2)); assert(#sceneObjects>objectCount and ct.funds==1860)
assert(not c:CallIn(0,'cover',2)); assert(ct.funds==1860)
local previous=MovableMan.particleCount
assert(c:CallIn(0,'mines',2)); assert(MovableMan.particleCount>previous and MovableMan.lastParticle.Sharpness==0 and ct.funds==1680)
assert(c:CallIn(0,'bomb',2)); assert(MovableMan.lastParticle.activated and ct.funds==1420)
-- The orbital salvo warns, fires over time, and then completes.
assert(c:CallIn(0,'orbital',2)); assert(ct.funds==1070 and #c.pendingOrbitals==1)
local salvo=c.pendingOrbitals[1]; previous=MovableMan.particleCount
salvo.timer.ElapsedSimTimeMS=2999; c:UpdateCallIns(); assert(MovableMan.particleCount==previous)
salvo.timer.ElapsedSimTimeMS=3000; c:UpdateCallIns(); assert(MovableMan.particleCount==previous+1)
salvo.timer.ElapsedSimTimeMS=3000+95*45; c:UpdateCallIns(); assert(#c.pendingOrbitals==0 and MovableMan.particleCount==previous+96)
local minX,maxX=math.huge,-math.huge
for i=#MovableMan.particles-95,#MovableMan.particles do
    local round=MovableMan.particles[i]; assert(round.name=='Frontline Orbital Round')
    minX=math.min(minX,round.Pos.X); maxX=math.max(maxX,round.Pos.X)
    assert(math.abs(round.Pos.X-c.outposts[2].x)<=150 and round.Team==0)
end
assert(maxX-minX>200 and salvo.sound.playCount==24)
assert(not c:CallIn(0,'orbital',2))
print('Cover, mines, bomb and timed orbital salvo costs, effects and cooldowns passed')

-- Unique outpost bonuses and forward deployment.
local d=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
actors={}; d:StartActivity(); d:StartBattle(); local dt=d.teams[0]
dt.funds=5000; d.matchTimer.ElapsedSimTimeMS=15000
assert(d:TeamIncome(0)==5 and d:ResearchCost(0,3)==200 and d:CallinCooldown(0,45000)==45000)
d.outposts[1].owner=0; d.outposts[2].owner=0; d.outposts[3].owner=0
assert(d:TeamIncome(0)==7 and d:ResearchCost(0,3)==160 and d:CallinCooldown(0,45000)==36000)
d.settings.outpostBonuses=false; assert(d:TeamIncome(0)==5 and d:ResearchCost(0,3)==200); d.settings.outpostBonuses=true
dt.tier=2; dt.counts={0,0,0,0,1}; dt.weapons={1,1,1,1,1}; dt.forward=2; dt.order='Advance'
assert(d:Batch(0)==285); assert(d:Deploy(0)); local ship=actors[#actors]
assert(ship.ship and ship.AIMode==Actor.AIMODE_DELIVER and ship.InventorySize==1 and d:UnitCount(0)==1)
local vehicle=table.remove(ship.cargo); ship.InventorySize=#ship.cargo
vehicle.Pos=Vector(d.outposts[2].x-150,565); MovableMan:AddActor(vehicle); d:UpdateDeliveries()
assert(vehicle.vehicle and vehicle.AIMode==Actor.AIMODE_GOTO and math.abs(vehicle.waypoint.X-d.outposts[2].x)<=60 and d:UnitCount(0)==1)
dt.timer.ElapsedSimTimeMS=10000; d.outposts[2].owner=1; assert(not d:Deploy(0))
-- Support research upgrades and temporary shield interception.
d.outposts[1].owner=0; dt.funds=5000; assert(d:Research(0,8)); assert(d:Research(0,9))
assert(d:CallIn(0,'shield',1)); assert(d:ShieldBlocks(d.outposts[1],1) and not d:ShieldBlocks(d.outposts[1],0))
assert(not d:CallIn(1,'bomb',1)); d.jamFields[1].timer.ElapsedSimTimeMS=20000; assert(not d:ShieldBlocks(d.outposts[1],1))
assert(d:CallIn(0,'orbital',3)); assert(d.pendingOrbitals[1].total==144)
-- Brain damage is tracked as health lost, including non-player causes.
d.brains[1].Health=70; d:RecordBrainLoss(); assert(dt.stats.brainDamage==30)
local target=CreateAHuman('Dummy','Dummy.rte'); target.Team=1; target.Pos=Vector(3000,565); MovableMan:AddActor(target)
d:RecordTroopLoss(); target.Health=65; d:RecordTroopLoss(); assert(dt.stats.troopDamage==35)
d.WinnerTeam=0; d.resultReady=true; local report
FrameMan.SetScreenText=function(_,message) report=message end
d:EndActivity(); assert(report:find('VICTORY') and report:find('Enemy brain health lost: 30'))
print('Outpost bonuses, vehicle and forward orders, support upgrades, shields and match report passed')
-- Wizard prevents enemy deployment and income indefinitely until explicitly started.
actors={}; local w=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
w:StartActivity(); w.DrawOutpost=function() end; w.DrawWizard=function() end
w.matchTimer.ElapsedSimTimeMS=100000; w.aiTimer.ElapsedSimTimeMS=100000
local funds0,funds1=w.teams[0].funds,w.teams[1].funds
w:UpdateActivity(); assert(not w.battleStarted and w:UnitCount(1)==0 and w.teams[0].funds==funds0 and w.teams[1].funds==funds1)
assert(not w:Deploy(1) and not w:CallIn(0,'strike',2))
-- Click each wizard step, changing settings and starting the battle.
w.DrawWizard=nil; w.cursorX=25; w.cursorY=90
UInputMan.MouseButtonPressed=function() return true end
Frontline.DrawWizard(w); assert(w.settings.startFunds==750 and w.teams[0].funds==750 and w.teams[1].funds==750)
w.cursorX=25; w.cursorY=275; Frontline.DrawWizard(w); assert(w.setupStep==2)
w.cursorX=25; w.cursorY=225; Frontline.DrawWizard(w); assert(w.setupStep==1)
w.cursorX=25; w.cursorY=275; Frontline.DrawWizard(w); assert(w.setupStep==2)
w.cursorX=160; w.cursorY=225; Frontline.DrawWizard(w); assert(w.battleStarted and w.matchTimer.ElapsedSimTimeMS==0 and w.tab=='Squad')
assert(not w:Deploy(1)); w.matchTimer.ElapsedSimTimeMS=15000; assert(w:Deploy(1))
w.settings.callins=false; assert(not w:CallIn(0,'strike',1))
print('Setup wizard holds both teams, cycles settings, reviews and starts grace before deployments')

-- Issuing new orders updates living troops and preserves the brain's sentry mode.
local own=CreateAHuman('Soldier Light','Coalition.rte'); own.Team=0; own.Pos=Vector(500,565); MovableMan:AddActor(own)
w.teams[0].order='Defend'; w.teams[0].orderTarget=1; w:ApplyTeamOrder(0)
assert(own.AIMode==Actor.AIMODE_GOTO and math.abs(own.waypoint.X-w.outposts[1].x)<=60 and w.brains[0].AIMode==Actor.AIMODE_SENTRY)
own.Pos=Vector(w.outposts[1].x,565); w:UpdateOrders(); assert(own.AIMode==Actor.AIMODE_SENTRY)
w.teams[0].order='Advance'; w.teams[0].orderTarget=2; w:ApplyTeamOrder(0)
assert(own.AIMode==Actor.AIMODE_GOTO and math.abs(own.waypoint.X-w.outposts[2].x)<=60)
own.Pos=Vector(w.outposts[2].x,565); w:UpdateOrders(); assert(own.AIMode==Actor.AIMODE_SENTRY)
w.outposts[2].owner=0; w:UpdateOrders(); assert(own.AIMode==Actor.AIMODE_BRAINHUNT)
w.teams[0].order='Rush'; w:ApplyTeamOrder(0); assert(own.AIMode==Actor.AIMODE_BRAINHUNT and own.waypoint==nil)
print('Orders apply to existing units, defend holds, advance resumes, and brains stay in place')
-- The stock game HUD is hidden only while Frontline's panel is visible.
local hudDisabled
FrameMan.SetHudDisabled=function(_,value) hudDisabled=value end
w.DrawPanel=function() end; w.DrawHUD=function() end; w.panel=true; w:UpdateActivity(); assert(hudDisabled==true)
w.panel=false; w:UpdateActivity(); assert(hudDisabled==false)
-- New engines use screen coordinates, with the camera offset excluded.
local drawn
PrimitiveMan.DrawScreenBoxFillPrimitive=function(_,_,a) drawn=a end
PrimitiveMan.DrawScreenBoxPrimitive=function() end
PrimitiveMan.DrawScreenTextPrimitive=function() end
actors={}; local u=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
u:StartActivity(); assert(u.screenUI)
Frontline.DrawHUD(u); assert(drawn.X==8 and drawn.Y==22)
print('Panel HUD visibility is restored and screen-space mode ignores the camera offset')
-- The setup wizard starts at 32 per team and retains smaller options.
assert(u.settings.unitCap==50); u.cursorX=25; u.cursorY=149
UInputMan.MouseButtonPressed=function() return true end
Frontline.DrawWizard(u); assert(u.settings.unitCap==8)
Frontline.DrawWizard(u); assert(u.settings.unitCap==12)
Frontline.DrawWizard(u); assert(u.settings.unitCap==16)
Frontline.DrawWizard(u); assert(u.settings.unitCap==32)
Frontline.DrawWizard(u); assert(u.settings.unitCap==50)
print('Unit-cap choices cycle 50, 8, 12, 16 and 32 per team')

-- AI makes purchases and decisions through the same mechanisms as the player.
actors={}; local bot=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
bot:StartActivity(); bot:StartBattle(); bot.DrawHUD=function() end; bot.DrawOutpost=function() end
bot.matchTimer.ElapsedSimTimeMS=15000
local ai=bot.teams[1]; ai.funds=2000; ai.levels={2,2,1,1,1,1,1,1,1,1,1,1,1,1,1}; ai.tier=3
bot.outposts[3].owner=1
local enemyVehicle=CreateACrab('Gatling Drone','Coalition.rte'); enemyVehicle.Team=0; enemyVehicle.Pos=Vector(100,565); MovableMan:AddActor(enemyVehicle)
bot:UpdateAI(); assert(ai.counts[4]==1 and ai.counts[5]==1 and ai.weapons[2]==5 and ai.forward==3)
assert(ai.turret and ai.turret.name=='Gatling Turret'); ai.baseArmor=3
assert(ai.order=='Advance' and ai.orderTarget==2)
local aiCost,aiSize=bot:Batch(1); assert(aiSize>0 and aiSize<=6 and aiCost<=ai.funds-200)
-- Same base income with no difficulty multiplier.
bot.aiTimer.ElapsedSimTimeMS=0; bot.settings.outpostBonuses=false; ai.auto=false; bot.teams[0].auto=false
local f0,f1=bot.teams[0].funds,ai.funds; bot:UpdateActivity()
assert(bot.teams[0].funds-f0==5 and ai.funds-f1==9) -- AI owns two income upgrades.
-- Support reactions use normal costs/cooldowns and do not target friendly clusters.
local medic1=CreateAHuman('Soldier Light','Coalition.rte'); medic1.Team=1; medic1.Pos=Vector(bot.outposts[3].x,565); medic1.Health=40; MovableMan:AddActor(medic1)
local medic2=CreateAHuman('Soldier Light','Coalition.rte'); medic2.Team=1; medic2.Pos=Vector(bot.outposts[3].x+30,565); medic2.Health=40; MovableMan:AddActor(medic2)
ai.funds=2000; bot:UpdateAI(); assert(medic1.Health==75 and medic2.Health==75 and ai.funds==1880)
local foe1=CreateAHuman('Soldier Light','Coalition.rte'); foe1.Team=0; foe1.Pos=Vector(bot.outposts[2].x,565); MovableMan:AddActor(foe1)
local foe2=CreateAHuman('Soldier Light','Coalition.rte'); foe2.Team=0; foe2.Pos=Vector(bot.outposts[2].x+20,565); MovableMan:AddActor(foe2)
ai.funds=2000; bot:UpdateAI(); assert(#bot.pendingStrikes==1 and bot.pendingStrikes[1].team==1 and ai.funds==1780)
-- A hostile warning on an owned post prompts the same paid shield call-in.
local incoming={team=0,index=3,timer=Timer()}; table.insert(bot.pendingOrbitals,incoming)
ai.funds=2000; bot:UpdateAI(); assert(#bot.jamFields==1 and bot.jamFields[1].team==1 and ai.funds==1800)
print('AI uses shared income, research, units, forward orders, medics, strikes and shields')
-- The AI cycles through the other offensive call-ins and both fortification types.
ai.funds=2000; bot:UpdateAI(); assert(MovableMan.lastParticle.name=='Standard Bomb' and MovableMan.lastParticle.activated and ai.funds==1740)
ai.funds=2000; bot:UpdateAI(); assert(#bot.pendingOrbitals==2 and bot.pendingOrbitals[2].team==1 and ai.funds==1650)
foe1.Pos=Vector(bot.outposts[3].x-260,565); foe2.Pos=Vector(bot.outposts[3].x-260,565)
medic1.Health=100; medic2.Health=100; bot.pendingOrbitals={}; ai.funds=2000
local oldObjects=#sceneObjects; bot:UpdateAI(); assert(#sceneObjects>oldObjects and ai.funds==1860)
ai.funds=2000; bot:UpdateAI(); assert(MovableMan.lastParticle.name=='Anti Personnel Mine Active' and MovableMan.lastParticle.Sharpness==1 and ai.funds==1820)
print('AI can use bomb, orbital cannon, cover and mines through standard call-in rules')

-- Base upgrades spend funds, affect the brain and exclude the sentry from
-- mobile army capacity and issued commands. Both teams can purchase them.
actors={}; local base=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
base:StartActivity(); assert(not base:BaseUpgrade(0,'armor')); base:StartBattle()
local bt=base.teams[0]; bt.funds=2000
assert(base:BaseUpgrade(0,'armor')); assert(bt.baseArmor==1 and base.brains[0].Health==150 and base.brains[0].MaxHealth==150 and bt.funds==1800)
assert(not base:BaseUpgrade(0,'repair')); base.brains[0].Health=90
assert(base:BaseUpgrade(0,'repair')); assert(base.brains[0].Health==140 and bt.funds==1680)
assert(base:BaseUpgrade(0,'turret')); assert(bt.turret.name=='Gatling Turret' and bt.turret.AIMode==Actor.AIMODE_SENTRY and bt.funds==1330)
assert(base:UnitCount(0)==0 and not base:BaseUpgrade(0,'turret'))
bt.order='Advance'; base:ApplyTeamOrder(0); assert(bt.turret.AIMode==Actor.AIMODE_SENTRY and bt.turret.waypoint==nil)
base.settings.callins=false; local bi=base.teams[1]; bi.funds=2000
base:UpdateAI(); assert(bi.turret and bi.turret.name=='Gatling Turret' and bi.turret.Team==1)
print('Base armor, repair, roof turret, unit-cap exclusion and AI base purchases passed')

-- Larger maps get the right number of posts and income bonuses stack.
actors={}; SceneMan.SceneWidth=10400
local medium=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
medium:StartActivity(); assert(#medium.outposts==5)
medium.outposts[1].owner=0; medium.outposts[4].owner=0
assert(medium:TeamIncome(0)==9)
SceneMan.SceneWidth=15600
local large=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
large:StartActivity(); assert(#large.outposts==9)
SceneMan.SceneWidth=5200
-- An arbitrary location works for delayed support, with no outpost index.
large:StartBattle(); large.matchTimer.ElapsedSimTimeMS=15000
large.teams[0].funds=1000
local target={name='target area',x=3100,groundY=600,owner=-1}
assert(large:CallIn(0,'strike',target)); assert(large.pendingStrikes[1].target==target)
large.pendingStrikes[1].timer.ElapsedSimTimeMS=3000
large:UpdateCallIns(); assert(#large.pendingStrikes==0)
-- Training upgrades improve existing and future troops for either team.
actors={}; SceneMan.SceneWidth=5200
local trained=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
trained:StartActivity(); trained:StartBattle(); trained.teams[1].funds=1000
local trainee=CreateAHuman('Soldier Light','Coalition.rte'); trainee.Team=1; trainee.Pos=Vector(3000,565); MovableMan:AddActor(trainee)
assert(trained:Research(1,10)); assert(trainee.Perceptiveness==0.55)
print('Map scaling, stacked outpost income, arbitrary support targets, and training passed')
-- The mode imports engine fund changes and publishes its own income/spending.
local engineFunds={[0]=0,[1]=0}
function Frontline:SetTeamFunds(value,team) engineFunds[team]=value end
function Frontline:GetTeamFunds(team) return engineFunds[team] end
actors={}; local economy=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
economy:StartActivity(); economy:StartBattle(); economy.DrawHUD=function() end; economy.DrawOutpost=function() end
economy.teams[0].auto=false; economy.teams[1].auto=false
economy.panel=false; engineFunds[0]=500; economy:UpdateActivity()
assert(engineFunds[0]==505 and economy.teams[0].funds==505)
print('Engine funds changes and mode income share the same balance')
-- Miners require research, have fixed gear, and ignore team attack orders.
Actor.AIMODE_GOLDDIG=4
actors={}; local mines=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
mines:StartActivity(); mines:StartBattle(); mines.matchTimer.ElapsedSimTimeMS=15000
mines.teams[0].funds=2000; mines.teams[0].counts={0,0,0,0,0,1}
assert(not mines:Deploy(0)); assert(mines:Research(0,11)); assert(mines:Deploy(0))
local miner=actors[#actors]; assert(miner.AIMode==Actor.AIMODE_SENTRY and miner.inventory.name=='Light Digger')
mines.teams[0].order='Rush'; mines:ApplyTeamOrder(0); assert(miner.AIMode==Actor.AIMODE_SENTRY)
print('Mining research, fixed digger loadout, and persistent mining order passed')
-- Starter tier and separately priced, research-gated optional equipment.
actors={}; local kit=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
startActivity(kit); kit:StartBattle(); kit.matchTimer.ElapsedSimTimeMS=15000
local kt=kit.teams[0]; kt.funds=5000
assert(kt.levels[12]==0 and kt.weapons[1]==6 and kit:Batch(0)==180)
kt.counts={1,0,0,0,0,0,0}; kt.sidearms[1]=1; assert(not kit:Batch(0))
assert(kit:Research(0,15)); assert(kit:Research(0,13)); assert(kit:Research(0,14))
kt.medkits[1]=true; kt.grenades[1]=true
assert(kit:Batch(0)==190); assert(kit:Deploy(0))
assert(kit:Research(0,12)); kt.weapons[1]=1; assert(kit:Batch(0)==205)
kit:SaveSquad(0); kt.medkits[1]=false; kt.sidearms[1]=0; kit:LoadSquad(0)
assert(kt.medkits[1] and kt.grenades[1] and kt.sidearms[1]==1)
print('Starter weapon, equipment unlocks, full loadout costs, and saved loadouts passed')

-- Capture points must begin between the two bases on every battlefield size.
for _,case in ipairs({{width=5200,count=3},{width=10400,count=5},{width=15600,count=9}}) do
    actors={}; SceneMan.SceneWidth=case.width
    local layout=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
    layout:StartActivity()
    assert(#layout.outposts==case.count)
    local left,right=layout.brains[0].Pos.X,layout.brains[1].Pos.X
    for _,post in ipairs(layout.outposts) do
        assert(post.x>left and post.x<right, 'outpost outside base positions at width '..case.width)
    end
end
SceneMan.SceneWidth=5200
print('All map outposts start between the two brains')

-- Elevated scenes place both bases, deployments and turrets relative to ground.
local originalGround=SceneMan.MovePointToGround
SceneMan.SceneWidth=15600
SceneMan.MovePointToGround=function(_,p) return Vector(p.X,1100) end
actors={}; local tall=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
tall:StartActivity(); assert(#tall.outposts==9)
assert(tall.brains[0].Pos.Y==1070 and tall.brains[1].Pos.Y==1070)
tall:StartBattle(); tall.matchTimer.ElapsedSimTimeMS=15001; tall.teams[0].funds=5000
tall.teams[0].timer.ElapsedSimTimeMS=10001
assert(tall:Deploy(0)); assert(actors[#actors].Pos.Y==1065)
assert(tall:BaseUpgrade(0,'turret')); assert(tall.teams[0].turret.Pos.Y==955)
SceneMan.MovePointToGround=originalGround; SceneMan.SceneWidth=5200
print('Elevated battlefield spawns bases, squads and turrets at ground-relative heights')

-- Roster display order does not change the underlying squad indexes.
local rows={}
PrimitiveMan.DrawScreenTextPrimitive=function(_,_,_,label)
    if label:find('Ronin Bandit',1,true) or label:find('Coalition Light',1,true) then rows[#rows+1]=label end
end
UInputMan.MouseButtonPressed=function() return false end
tall.tab='Squad'; tall.rosterPage=1
Frontline.DrawPanel(tall)
assert(#rows>=2 and rows[1]:find('Ronin Bandit',1,true) and rows[2]:find('Coalition Light',1,true))
print('Ronin Bandit appears before Coalition Light without changing roster indexes')

-- Miners travel to gold before digging and seek a new site after depletion.
local goldLodes={{left=900,right=944,y=630,active=true},{left=1500,right=1544,y=640,active=true}}
SceneMan.CastMaterialRay=function(_,start,ray,material,hit)
    for _,lode in ipairs(goldLodes) do
        if lode.active and start.X>=lode.left and start.X<=lode.right then
            hit.X=start.X; hit.Y=lode.y; return true
        end
    end
    return false
end
actors={}; local seeker=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
seeker:StartActivity(); assert(#seeker.goldSites==2); seeker:StartBattle()
seeker.matchTimer.ElapsedSimTimeMS=15001; seeker.teams[0].timer.ElapsedSimTimeMS=10001
seeker.teams[0].funds=5000; seeker.teams[0].levels[11]=1; seeker.teams[0].counts={0,0,0,0,0,1}
assert(seeker:Deploy(0)); local goldMiner=actors[#actors]
assert(goldMiner.AIMode==Actor.AIMODE_GOTO and goldMiner.waypoint.X>=900 and goldMiner.waypoint.X<=944)
goldMiner.Pos=Vector(goldMiner.waypoint.X,565); seeker:UpdateMiners()
assert(goldMiner.AIMode==Actor.AIMODE_GOLDDIG)
goldLodes[1].active=false; seeker:UpdateMiners()
assert(goldMiner.AIMode==Actor.AIMODE_GOTO and goldMiner.waypoint.X>=1500 and goldMiner.waypoint.X<=1544)
goldLodes[2].active=false; seeker:UpdateMiners(); assert(goldMiner.AIMode==Actor.AIMODE_SENTRY)
seeker.teams[0].order='Rush'; seeker:ApplyTeamOrder(0); assert(goldMiner.AIMode==Actor.AIMODE_SENTRY)
SceneMan.CastMaterialRay=function() return false end
print('Miners seek nearby gold, dig only at the deposit, and retarget when depleted')

-- Right click cycles option controls backwards, but never performs purchases
-- or wizard navigation. Locked weapons are skipped in both directions.
actors={}; local reverse=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
reverse:StartActivity()
local pressed=MouseButtons.MOUSE_RIGHT
UInputMan.MouseButtonPressed=function(_,button) return button==pressed end
reverse.cursorX=25; reverse.cursorY=90; Frontline.DrawWizard(reverse)
assert(reverse.settings.startFunds==250)
Frontline.DrawWizard(reverse); assert(reverse.settings.startFunds==750)
pressed=MouseButtons.MOUSE_LEFT; Frontline.DrawWizard(reverse); assert(reverse.settings.startFunds==250)
pressed=MouseButtons.MOUSE_RIGHT; reverse.cursorY=120; Frontline.DrawWizard(reverse); assert(reverse.settings.income==3)
Frontline.DrawWizard(reverse); assert(reverse.settings.income==25)
reverse.cursorY=149; Frontline.DrawWizard(reverse); assert(reverse.settings.unitCap==32)
reverse.cursorY=275; Frontline.DrawWizard(reverse); assert(reverse.setupStep==1)
reverse:StartBattle(); reverse.tab='Squad'; reverse.rosterPage=1
local rt=reverse.teams[0]; rt.weapons[7]=6
reverse.cursorX=25; reverse.cursorY=115; Frontline.DrawPanel(reverse); assert(rt.weapons[7]==1)
pressed=MouseButtons.MOUSE_LEFT; Frontline.DrawPanel(reverse); assert(rt.weapons[7]==6)
rt.levels[15]=1; pressed=MouseButtons.MOUSE_RIGHT; reverse.cursorX=140
Frontline.DrawPanel(reverse); assert(rt.sidearms[7]==1) -- skip locked RPG
pressed=MouseButtons.MOUSE_LEFT; Frontline.DrawPanel(reverse); assert(rt.sidearms[7]==0)
rt.levels[7]=1; pressed=MouseButtons.MOUSE_RIGHT; Frontline.DrawPanel(reverse); assert(rt.sidearms[7]==2)
reverse.cursorX=315; reverse.cursorY=124; Frontline.DrawPanel(reverse); assert(rt.forward==3)
pressed=MouseButtons.MOUSE_LEFT; Frontline.DrawPanel(reverse); assert(rt.forward==0)
pressed=MouseButtons.MOUSE_RIGHT; reverse.cursorX=20; reverse.cursorY=352
local priorFunds=rt.funds; local priorDeployed=rt.stats.deployed
Frontline.DrawPanel(reverse); assert(rt.funds==priorFunds and rt.stats.deployed==priorDeployed)
reverse.cursorX=155; Frontline.DrawPanel(reverse); assert(rt.auto==false)
print('Right click reverses settings, weapons, sidearms and spawn choices without triggering actions')

-- Confirming support returns to the battlefield; cancelling reopens the panel.
actors={}; local watch=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
watch:StartActivity(); watch:StartBattle(); watch.matchTimer.ElapsedSimTimeMS=15001
watch.teams[0].funds=1000; watch.teams[0].strikeTimer.ElapsedSimTimeMS=45001
watch.panel=false; watch.targeting='strike'; watch.cursorX=200; watch.cursorY=100
UInputMan.MouseButtonPressed=function(_,button) return button==MouseButtons.MOUSE_LEFT end
UInputMan.KeyPressed=function() return false end
watch:UpdateTargeting(); assert(not watch.panel and watch.targeting==nil and #watch.pendingStrikes==1)
watch.targeting='cover'; UInputMan.MouseButtonPressed=function() return false end
UInputMan.KeyPressed=function() return true end
watch:UpdateTargeting(); assert(watch.panel and watch.targeting==nil)
UInputMan.KeyPressed=function() return false end
print('Support confirmation leaves the panel closed; cancelling reopens it')

-- Jammers can be placed away from outposts and block every enemy support.
actors={}; local visual=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
visual:StartActivity(); visual:StartBattle(); visual.matchTimer.ElapsedSimTimeMS=15001
visual.teams[0].funds=2000; visual.teams[1].funds=5000
visual.teams[0].shieldTimer.ElapsedSimTimeMS=60001
local target={name='target area',x=1500,groundY=600,owner=-1}
assert(visual:CallIn(0,'shield',target)); assert(#visual.jamFields==1 and visual.jamFields[1].x==1500)
assert(visual:ShieldBlocks({x=1680},1) and not visual:ShieldBlocks({x=1681},1))
assert(not visual:ShieldBlocks(target,0))
for _,kind in ipairs({'strike','medic','cover','mines','bomb','orbital','shield'}) do
    local funds=visual.teams[1].funds
    local ok,msg=visual:CallIn(1,kind,target)
    assert(not ok and msg:find('jammer',1,true) and visual.teams[1].funds==funds)
end
assert(visual:CallIn(0,'cover',target)) -- allied support is not blocked
assert(visual:CallIn(1,'bomb',{name='outside',x=1681,groundY=600}))
local lineCount,jamText=0,false
PrimitiveMan.DrawLinePrimitive=function() lineCount=lineCount+1 end
PrimitiveMan.DrawTextPrimitive=function(_,_,label) if label:find('SUPPORT JAMMER 20s',1,true) then jamText=true end end
Frontline.DrawOutpost(visual); assert(lineCount>40 and jamText)
visual.jamFields[1].timer.ElapsedSimTimeMS=20001; lineCount=0; jamText=false
Frontline.DrawOutpost(visual); assert(lineCount==#visual.outposts and not jamText and not visual:ShieldBlocks(target,1))
visual:UpdateCallIns(); assert(#visual.jamFields==0)
-- The preview and confirmation work at a neutral point beyond any capture zone.
visual.teams[0].shieldTimer.ElapsedSimTimeMS=60001
cameraOffset=Vector(1000,80); visual.targeting='shield'; visual.cursorX=500; visual.cursorY=100
local prompt=''; PrimitiveMan.DrawTextPrimitive=function(_,_,label) prompt=label end
UInputMan.MouseButtonPressed=function() return false end; UInputMan.KeyPressed=function() return false end
visual:UpdateTargeting(); assert(prompt:find('PLACE SUPPORT JAMMER',1,true))
UInputMan.MouseButtonPressed=function(_,button) return button==MouseButtons.MOUSE_LEFT end
visual:UpdateTargeting(); assert(#visual.jamFields==1 and visual.jamFields[1].x==1500 and not visual.panel)
print('Free jammer placement, all support types, friendly access, radius, countdown and expiry passed')

-- Jammers work for either team and can intercept an already queued strike.
actors={}; local counter=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
counter:StartActivity(); counter:StartBattle(); counter.matchTimer.ElapsedSimTimeMS=15001
for team=0,1 do counter.teams[team].funds=2000; counter.teams[team].strikeTimer.ElapsedSimTimeMS=45001; counter.teams[team].shieldTimer.ElapsedSimTimeMS=60001 end
local contested={name='contested ground',x=2300,groundY=600}
assert(counter:CallIn(0,'strike',contested)); assert(counter:CallIn(1,'shield',contested))
local countBefore=MovableMan.particleCount or 0
counter.pendingStrikes[1].timer.ElapsedSimTimeMS=3001; counter:UpdateCallIns()
assert(#counter.pendingStrikes==0 and (MovableMan.particleCount or 0)==countBefore)
local funds=counter.teams[0].funds
assert(not counter:CallIn(0,'cover',contested) and counter.teams[0].funds==funds)
assert(counter:CallIn(1,'cover',contested))
print('Enemy jammer intercepts queued strikes and preserves friendly support')

-- An enemy jammer pauses an active barrage and fire resumes after expiry.
actors={}; local jamBurst=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
jamBurst:StartActivity(); jamBurst:StartBattle(); jamBurst.matchTimer.ElapsedSimTimeMS=15001
for team=0,1 do jamBurst.teams[team].funds=2000; jamBurst.teams[team].orbitalTimer.ElapsedSimTimeMS=75001; jamBurst.teams[team].shieldTimer.ElapsedSimTimeMS=60001 end
local burstPoint={name='open ground',x=2200,groundY=600}
assert(jamBurst:CallIn(0,'orbital',burstPoint))
local burst=jamBurst.pendingOrbitals[1]; local beforeRounds=MovableMan.particleCount or 0
burst.timer.ElapsedSimTimeMS=3000; jamBurst:UpdateCallIns(); assert(MovableMan.particleCount==beforeRounds+1)
assert(jamBurst:CallIn(1,'shield',burstPoint))
burst.timer.ElapsedSimTimeMS=3000+10*45; jamBurst:UpdateCallIns(); assert(MovableMan.particleCount==beforeRounds+1)
jamBurst.jamFields[1].timer.ElapsedSimTimeMS=20001
burst.timer.ElapsedSimTimeMS=3000+11*45; jamBurst:UpdateCallIns(); assert(MovableMan.particleCount==beforeRounds+2)
print('Enemy jammers suppress an active orbital burst until their field expires')

-- Forward batches arrive in actual craft, reserve capacity in flight, and
-- receive the current order after disembarking. Destroyed craft free slots.
actors={}; local transport=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
transport:StartActivity(); transport:StartBattle(); transport.matchTimer.ElapsedSimTimeMS=15001
local tt=transport.teams[0]; tt.funds=5000; tt.timer.ElapsedSimTimeMS=10001; tt.levels[11]=1
transport.outposts[2].owner=0; transport.settings.unitCap=6; tt.forward=2; tt.counts={5,0,0,0,0,1}
local transportCost=transport:Batch(0); assert(transportCost==800)
assert(transport:Deploy(0)); assert(tt.funds==4200 and #transport.deliveries==2 and transport:UnitCount(0)==6)
local firstShip,secondShip=transport.deliveries[1].ship,transport.deliveries[2].ship
assert(firstShip.InventorySize==3 and secondShip.InventorySize==3 and firstShip.Team==0 and secondShip.Team==0)
assert(firstShip.AIMode==Actor.AIMODE_DELIVER and firstShip.Pos.X<transport.outposts[2].x)
tt.timer.ElapsedSimTimeMS=10001; tt.counts={1,0,0,0,0,0}; assert(not transport:Deploy(0))
-- Change orders while aboard; the passenger uses the latest order on arrival.
tt.order='Advance'; tt.orderTarget=3; tt.levels[10]=2
local firstPassenger=table.remove(firstShip.cargo,1); firstShip.InventorySize=#firstShip.cargo
firstPassenger.Pos=Vector(firstShip.Pos.X,565); MovableMan:AddActor(firstPassenger); transport:UpdateDeliveries()
assert(firstPassenger.AIMode==Actor.AIMODE_GOTO and math.abs(firstPassenger.waypoint.X-transport.outposts[3].x)<=60)
assert(firstPassenger.Perceptiveness==0.6 and transport:UnitCount(0)==6)
-- Miners resume seeking gold on disembark rather than receiving combat orders.
local forwardMiner=table.remove(secondShip.cargo,3); secondShip.InventorySize=#secondShip.cargo
forwardMiner.Pos=Vector(secondShip.Pos.X,565); MovableMan:AddActor(forwardMiner); transport:UpdateDeliveries()
assert(transport.miners[forwardMiner.UniqueID] and forwardMiner.AIMode==Actor.AIMODE_SENTRY and transport:UnitCount(0)==6)
secondShip.deleted=true; transport:UpdateDeliveries(); assert(transport:UnitCount(0)==6)
transport.deliveries[2].lostTimer.ElapsedSimTimeMS=2001; transport:UpdateDeliveries()
assert(#transport.deliveries==1 and transport:UnitCount(0)==4)
-- Missing transport fails atomically, with neither cost nor cooldown consumed.
actors={}; local missing=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
missing:StartActivity(); missing:StartBattle(); missing.matchTimer.ElapsedSimTimeMS=15001
missing.outposts[1].owner=0; missing.teams[0].forward=1; missing.teams[0].funds=1000; missing.teams[0].timer.ElapsedSimTimeMS=10001
local originalFactory=CreateACDropShip; CreateACDropShip=function() return nil end
local success,reason=missing:Deploy(0)
CreateACDropShip=originalFactory
assert(not success and reason:find('Dropship',1,true) and missing.teams[0].funds==1000 and missing.teams[0].timer.ElapsedSimTimeMS==10001 and #missing.deliveries==0)
print('Forward dropships reserve slots, deliver current orders, handle miners and release lost cargo slots')

-- Craft loads respect both the native passenger and mass limits.
actors={}; local payload=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
payload:StartActivity(); payload:StartBattle(); payload.matchTimer.ElapsedSimTimeMS=15001
payload.outposts[2].owner=1; local pt=payload.teams[1]; pt.forward=2; pt.funds=5000; pt.timer.ElapsedSimTimeMS=10001; pt.counts={3,0,0,0,0,0}
local originalHuman=CreateAHuman
CreateAHuman=function(n,m) local unit=originalHuman(n,m); unit.Mass=500; return unit end
assert(payload:Deploy(1)); assert(#payload.deliveries==3 and payload:UnitCount(1)==3)
for _,delivery in ipairs(payload.deliveries) do
    assert(delivery.ship.InventorySize==1 and delivery.ship.Pos.X>payload.outposts[2].x)
end
actors={}; local overweight=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
CreateAHuman=originalHuman; overweight:StartActivity(); overweight:StartBattle(); overweight.matchTimer.ElapsedSimTimeMS=15001
overweight.outposts[1].owner=0; local ot=overweight.teams[0]; ot.forward=1; ot.funds=1000; ot.timer.ElapsedSimTimeMS=10001; ot.counts={1,0,0,0,0,0}
CreateAHuman=function(n,m) local unit=originalHuman(n,m); unit.Mass=900; return unit end
local okHeavy,heavyReason=overweight:Deploy(0); CreateAHuman=originalHuman
assert(not okHeavy and heavyReason:find('heavy',1,true) and ot.funds==1000 and ot.timer.ElapsedSimTimeMS==10001 and #overweight.deliveries==0)
print('Dropship loads honor mass limits and reject overweight batches atomically')

-- On taller scenes the craft starts at a consistent height above its landing zone.
local originalHighGround=SceneMan.MovePointToGround
SceneMan.SceneWidth=15600; SceneMan.MovePointToGround=function(_,p) return Vector(p.X,1100) end
actors={}; local highTransit=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
highTransit:StartActivity(); highTransit:StartBattle(); highTransit.matchTimer.ElapsedSimTimeMS=15001
highTransit.outposts[1].owner=0; local ht=highTransit.teams[0]; ht.forward=1; ht.funds=1000; ht.timer.ElapsedSimTimeMS=10001; ht.counts={1,0,0,0,0,0}
assert(highTransit:Deploy(0)); assert(highTransit.deliveries[1].ship.Pos.Y==450 and highTransit:UnitCount(0)==1)
SceneMan.SceneWidth=5200; SceneMan.MovePointToGround=originalHighGround
print('Forward dropship approach height follows tall battlefield terrain')
