Frontline={}; Actor={AIMODE_SENTRY=1,AIMODE_BRAINHUNT=2}; Activity={OBSERVE=1,OVER=2,NOTEAM=-1}
Key={TAB=1}; MouseButtons={MOUSE_LEFT=1}
function Timer() return {ElapsedSimTimeMS=0, IsPastSimMS=function(s,n) return s.ElapsedSimTimeMS>=n end, Reset=function(s) s.ElapsedSimTimeMS=0 end} end
function Vector(x,y) return setmetatable({X=x,Y=y},{__add=function(a,b) return Vector(a.X+b.X,a.Y+b.Y) end}) end
local nextId=0
function CreateAHuman(n,m) nextId=nextId+1; return {Team=0,UniqueID=nextId,name=n,AddInventoryItem=function() end} end
function CreateHDFirearm(n,m) return {name=n} end
function CreateTerrainObject() return {} end
local actors={}; MovableMan={Actors=(function() local i=0; return function() i=i+1; if not actors[i] then i=0; return nil end; return actors[i] end end)(), AddActor=function(s,a) table.insert(actors,a) end, IsActor=function(s,a) return a~=nil end}
function IsAHuman() return true end; function IsACrab() return false end
SceneMan={AddSceneObject=function() end}; MusicMan={PlayDynamicSong=function() end}
TimerMan={DeltaTimeSecs=1}; UInputMan={KeyPressed=function()return false end}
ActivityMan={EndActivity=function() end}
function Frontline:SetPlayerBrain() end; function Frontline:SetViewState() end; function Frontline:SetObservationTarget() end
function Frontline:GetTeamDeathCount(team) return self.deathCounts[team] end
assert(loadfile('Frontline.rte/Frontline.lua'))()
local a=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
a:StartActivity(); a.panel=false
a.DrawHUD=function() end
local p=a.teams[0]; assert(a:Batch(0)==210)
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
FrameMan={PlayerScreenWidth=960,PlayerScreenHeight=540}
local cameraOffset=Vector(120,80); local target
CameraMan={GetOffset=function() return cameraOffset end, SetOffset=function(_,v) cameraOffset=v end, SetScrollTarget=function(_,v) target=v end}
a.DrawPanel=function() end
a.panel=true; a:UpdateActivity(); assert(cameraOffset.X==120 and cameraOffset.Y==80 and target.X==600 and target.Y==350)
cameraOffset=Vector(150,100); a:UpdateActivity(); assert(cameraOffset.X==120 and cameraOffset.Y==80)
a.panel=false; a:UpdateActivity(); assert(a.panelCameraOffset==nil)
print('Camera is held while panel is open and released when closed')
local labels={}
PrimitiveMan={DrawBoxFillPrimitive=function() end,DrawBoxPrimitive=function() end,DrawTextPrimitive=function(_,_,_,s) labels[#labels+1]=s end}
Frontline.DrawHUD(a)
assert(#labels==4 and labels[1]:find('FRONTLINE') and labels[2]:find('Funds:') and labels[3]:find('Batch:') and labels[4]:find('Deploy:'))
print('Compact HUD renders economy, batch, capacity, and deployment status')
