Frontline={}; Actor={AIMODE_SENTRY=1,AIMODE_BRAINHUNT=2,AIMODE_GOTO=3,AIMODE_SQUAD=4,AIMODE_DELIVER=5,AIMODE_RETURN=6}; Controller={CIM_AI=1,CIM_DISABLED=0}; Activity={OBSERVE=1,OVER=2,NOTEAM=-1}
Key={TAB=1}; MouseButtons={MOUSE_LEFT=1,MOUSE_RIGHT=2}; rte={goldID=2,grassID=1,NoMOID=255}
function Timer() return {ElapsedSimTimeMS=0, IsPastSimMS=function(s,n) return s.ElapsedSimTimeMS>=n end, Reset=function(s) s.ElapsedSimTimeMS=0 end} end
function Vector(x,y) x=x or 0; y=y or 0; local v={X=x,Y=y,Magnitude=math.sqrt(x*x+y*y)}; return setmetatable(v,{__add=function(a,b) return Vector(a.X+b.X,a.Y+b.Y) end}) end
local nextId=0
function CreateAHuman(n,m) nextId=nextId+1; local a={Team=0,UniqueID=nextId,ID=nextId,name=n,module=m,Health=100,MaxHealth=100,Height=70,inventoryItems={}}; function a:AddInventoryItem(item) self.inventory=item; table.insert(self.inventoryItems,item) end; function a:ClearAIWaypoints() self.waypoint=nil end; function a:AddAISceneWaypoint(v) self.waypoint=v end; return a end
local turretMuzzles={
    ["Frontline HE Base Turret"]={x=11,y=-8},
    ["Frontline HE Turret"]={x=11,y=-8},
}
function CreateACrab(n,m)
    local a=CreateAHuman(n,m); a.vehicle=true; a.MuzzleOffset=turretMuzzles[n]
    a.SpriteOffset=Vector(-13,-7); a.SpriteHeight=16
    return a
end
-- Rows/offsets are measured from Base.rte's material bitmaps and bunker INI.
local bunkerGeometry={
    ["Tunnel A"]={width=96,height=96,bitmapOffsetY=-48,roofPixelY=0,walkablePixelY=72,openingTop=24,openingBottom=71},
    ["Tunnel B"]={width=48,height=96,bitmapOffsetY=-48,roofPixelY=0,walkablePixelY=72,openingTop=24,openingBottom=71},
    ["Brain Vault"]={bitmapOffsetY=-94,walkablePixelY=119},
    ["Frontline Mirrored Brain Vault"]={bitmapOffsetY=-94,walkablePixelY=119},
}
function CreateTerrainObject(name)
    local geometry=bunkerGeometry[name] or {}
    return {name=name,width=geometry.width,height=geometry.height,
        bitmapOffsetY=geometry.bitmapOffsetY,roofPixelY=geometry.roofPixelY,walkablePixelY=geometry.walkablePixelY,
        openingTop=geometry.openingTop,openingBottom=geometry.openingBottom}
end
function CreateACDropShip(n,m)
    nextId=nextId+1
    return {name=n,ship=true,UniqueID=nextId,MaxPassengers=4,MaxInventoryMass=800,InventorySize=0,cargo={},
        SetControllerMode=function(self,mode) self.controller=mode end,
        SetGoldValue=function(self,value) self.goldValue=value end,
        GetTotalValue=function(self) return self.returnValue or 0 end,
        OpenHatch=function(self) self.hatchOpen=true; self.openedWithCargo=#self.cargo; self.cargo={}; self.InventorySize=0 end,
        RemoveInventoryItemAtIndex=function(self,index) local item=table.remove(self.cargo,index+1); self.InventorySize=#self.cargo; return item end,
        AddInventoryItem=function(self,item) table.insert(self.cargo,item); self.InventorySize=#self.cargo end}
end
local function entity(name)
    local item={name=name,numberValues={}}
    function item:SetNumberValue(key,value) self.numberValues[key]=value end
    function item:GetNumberValue(key) return self.numberValues[key] or 0 end
    function item:GibThis() self.gibbed=true; self.ToDelete=true end
    return item
end
function CreateHDFirearm(n,m) return {name=n,module=m} end
function CreateTDExplosive(n,m) return {name=n,module=m,GibThis=function(self) self.gibbed=true end,Activate=function(self) self.activated=true end} end
function CreateMOSRotating(n,m) local item=entity(n); item.module=m; item.entityType='MOSRotating'; return item end
function CreateMOPixel(n,m) return entity(n) end
function CreateMOSParticle(n,m) return entity(n) end
function ToTDExplosive(item) return item end
function ToActor(item) return item end
function CreateSoundContainer() return {Play=function(self) self.playCount=(self.playCount or 0)+1 end} end
-- The test fixture above models the actual bitmap dimensions and surface rows.
local actors={}
MovableMan={
    Actors=(function() local i=0; return function() i=i+1; if not actors[i] then i=0; return nil end; return actors[i] end end)(),
    AddActor=function(s,a) table.insert(actors,a) end,
    AddMO=function(s,a) table.insert(actors,a) end,
    AddParticle=function(s,p) s.lastParticle=p; s.particleCount=(s.particleCount or 0)+1; s.particles=s.particles or {}; table.insert(s.particles,p) end,
    AddItem=function(s,item) s.items=s.items or {}; table.insert(s.items,item) end,
    GetMOFromID=function(s,id) for _,a in ipairs(actors) do if a.ID==id then return a end end end,
    GetRootMOID=function(_,id) return id end,
    ValidMO=function(_,a) return a~=nil and a.Health>0 end,
    IsActor=function(s,a) return a~=nil and not a.deleted end,
    IsParticle=function(s,p) for _,item in ipairs(s.particles or {}) do if item==p then return not p.ToDelete end end; return false end,
}
MovableMan.Particles=(function() local i=0; return function() i=i+1; local items=MovableMan.particles or {}; if not items[i] then i=0; return nil end; return items[i] end end)()
function IsAHuman(a) return not a.vehicle and not a.ship end; function IsACrab(a) return a.vehicle==true end
local sceneObjects={}
SceneMan={SceneWidth=5200, SceneHeight=800, Scene={PresetName="Frontline Battlefield"}, CastMaterialRay=function() return false end,
    CastMORay=function() return rte.NoMOID end,
    ShortestDistance=function(_,a,b) return Vector(b.X-a.X,b.Y-a.Y) end,
    AddSceneObject=function(_,o) table.insert(sceneObjects,o) end,
    MovePointToGround=function(_,p) return Vector(p.X,600) end}; MusicMan={PlayDynamicSong=function() end}
FrameMan={PlayerScreenWidth=640,IsHudDisabled=function() return false end,SetHudDisabled=function() end}
PrimitiveMan={}
TimerMan={DeltaTimeSecs=1}; UInputMan={KeyPressed=function()return false end}
function GetPPM() return 20 end
ActivityMan={EndActivity=function() end}
function Frontline:SetPlayerBrain() end; function Frontline:SetViewState() end; function Frontline:SetObservationTarget() end
function Frontline:GetTeamDeathCount(team) return self.deathCounts[team] end
assert(loadfile('Frontline.rte/Frontline.lua'))()
-- Legacy rules tests use the researched assault-rifle loadout for stable prices.
local startActivity=Frontline.StartActivity
function Frontline:StartActivity()
    startActivity(self)
    for team=0,1 do self.teams[team].levels[11]=1; self.teams[team].levels[12]=1; self.teams[team].weapons={1,1,1,1,1,1,1} end
end
-- Contact rows represent substantial stock bitmap mass, above stray bottom pixels.
do
    local props={
        {"Zombie Cave Rock",40,-42,52},
        {"Zombie Cave Under Rock 1",22,-45,15},
        {"Zombie Cave Under Rock 2",28,-43,18},
        {"Concrete Barrier",21,2,21},
        {"Metal Crate Small A FG",21,0,23},
    }
    local oldGround,oldRandom=SceneMan.MovePointToGround,math.random
    for _,width in ipairs({5200,10400,15600}) do
        SceneMan.SceneWidth=width
        for index,prop in ipairs(props) do
            for _,slope in ipairs({-1,1}) do
                local calls={}
                SceneMan.MovePointToGround=function(_,p,height,accuracy)
                    if accuracy==0 then calls[p.X]=true end
                    return Vector(p.X,600+slope*(p.X-650))
                end
                math.random=function(low,high) return high and low or index end
                sceneObjects={}; actors={}
                local layout=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
                layout:StartActivity()
                local placed
                for _,object in ipairs(sceneObjects) do
                    if object.name==prop[1] and object.Pos.X==650 then placed=object; break end
                end
                assert(placed,prop[1]..' must be placed on every map size')
                local deepest=600+math.max(slope*prop[3],slope*prop[4])
                assert(placed.Pos.Y+prop[2]==deepest+2,prop[1]..' must meet the downhill footing')
                for dx=prop[3],prop[4] do
                    assert(calls[650+dx],prop[1]..' must probe every footing column without skipping pixels')
                end
            end
        end
    end
    SceneMan.SceneWidth=5200; SceneMan.MovePointToGround=oldGround; math.random=oldRandom
    sceneObjects={}; actors={}
end
local a=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
a:StartActivity()
assert(a.brains[0].Pos.X==180 and a.brains[1].Pos.X==5020)
assert(a.brains[0].inventory.name=="Gatling Gun" and a.brains[1].inventory.name=="Gatling Gun" and a.brains[1].HFlipped)
assert(sceneObjects[1].name=="Frontline Mirrored Brain Vault" and sceneObjects[1].Team==0 and sceneObjects[1].Pos.X==180)
assert(sceneObjects[2].name=="Brain Vault" and sceneObjects[2].Team==1 and sceneObjects[2].Pos.X==5020)
for _,postX in ipairs({1300,2600,3900}) do
    for _,object in ipairs(sceneObjects) do
        assert(object.name~="Tunnel A" or object.Pos.X~=postX,"surface-only map outposts must not receive underground tunnels")
    end
end
local expectedLeft={{340,570,"Tunnel A"},{436,570,"Tunnel A"},{508,570,"Tunnel B"},{484,498,"Tunnel A"}}
local expectedRight={{4860,570,"Tunnel A"},{4764,570,"Tunnel A"},{4692,570,"Tunnel B"},{4716,498,"Tunnel A"}}
for index,expected in ipairs(expectedLeft) do
    local left,right=sceneObjects[2+index],sceneObjects[6+index]
    assert(left.name==expected[3] and left.Pos.X==expected[1] and left.Pos.Y==expected[2] and left.Team==0 and left.HFlipped)
    assert(right.name==expectedRight[index][3] and right.Pos.X==expectedRight[index][1] and right.Pos.Y==expectedRight[index][2]
        and right.Team==1 and not right.HFlipped and left.Pos.X+right.Pos.X==SceneMan.SceneWidth)
    if index>1 and index<=3 then
        local span=(left.width+sceneObjects[2+index-1].width)/2
        assert(math.abs(left.Pos.X-sceneObjects[2+index-1].Pos.X)==span)
        assert(math.abs(right.Pos.X-sceneObjects[6+index-1].Pos.X)==span)
    end
end
local hallway=sceneObjects[3]
local finalHall=sceneObjects[5]
local enemyFinalHall=sceneObjects[9]
local upperLeft,upperRight=sceneObjects[6],sceneObjects[10]
local function materialFloorY(object)
    return object.Pos.Y+object.bitmapOffsetY+object.walkablePixelY
end
local playerHallFloor=materialFloorY(hallway)
local enemyHallFloor=materialFloorY(sceneObjects[7])
local playerVaultFloor=materialFloorY(sceneObjects[1])
local enemyVaultFloor=materialFloorY(sceneObjects[2])
local hallwayRoof=hallway.Pos.Y+hallway.bitmapOffsetY+hallway.roofPixelY
local upperOpeningTop=upperLeft.Pos.Y+upperLeft.bitmapOffsetY+upperLeft.openingTop
local upperOpeningBottom=upperLeft.Pos.Y+upperLeft.bitmapOffsetY+upperLeft.openingBottom
local playerExit=finalHall.Pos.X+finalHall.width/2
local enemyExit=enemyFinalHall.Pos.X-enemyFinalHall.width/2
local playerOuterRoomEdge=upperLeft.Pos.X+upperLeft.width/2
local enemyOuterRoomEdge=upperRight.Pos.X-upperRight.width/2
assert(playerHallFloor==playerVaultFloor and enemyHallFloor==enemyVaultFloor
    and playerHallFloor==enemyHallFloor and playerHallFloor==594,
    'measured walkable material surfaces must align at ground-6 in both mirrored bunkers')
assert(playerOuterRoomEdge==playerExit and enemyOuterRoomEdge==enemyExit
    and playerExit+enemyExit==SceneMan.SceneWidth,
    'the upper turret rooms must meet the outer exits using the actual Tunnel A/B asset widths')
local function worldMuzzle(turret)
    local direction=turret.HFlipped and -1 or 1
    return turret.Pos.X+turret.MuzzleOffset.x*direction,turret.Pos.Y+turret.MuzzleOffset.y
end
for _,turret in ipairs({{object=CreateACrab("Frontline HE Base Turret"),team=0},{object=CreateACrab("Frontline HE Base Turret"),team=1},
    {object=CreateACrab("Frontline HE Turret"),team=0},{object=CreateACrab("Frontline HE Turret"),team=1}}) do
    local object=turret.object
    local room=turret.team==0 and upperLeft or upperRight
    object.Pos=Vector(room.Pos.X,room.Pos.Y+15)
    object.HFlipped=turret.team==1
    assert(object.Pos.Y+object.SpriteOffset.Y+object.SpriteHeight==materialFloorY(room),
        'base HE and Mk2 turret sprite bottom must meet the upper Tunnel A floor')
    local muzzleX,muzzleY=worldMuzzle(object)
    assert(muzzleY>=upperOpeningTop and muzzleY<=upperOpeningBottom and muzzleY<hallwayRoof,
        'both base cannon muzzle variants must lie in the upper Tunnel A bore above the lower corridor roof')
    local exit=turret.team==0 and playerExit or enemyExit
    assert(turret.team==0 and muzzleX>room.Pos.X and muzzleX<exit
        or turret.team==1 and muzzleX<room.Pos.X and muzzleX>exit,
        'both mirrored custom cannon muzzles must remain inside the outward half of the upper bore')
end
assert(hallway.Pos.Y-upperLeft.Pos.Y==72 and sceneObjects[7].Pos.Y-upperRight.Pos.Y==72,
    'moving the hallway down must preserve upper room and turret vertical alignment')
assert(508+24<1300-200 and 4692-24>3900+200,'base bunker entrances must remain separate from open outpost pads')
for _,object in ipairs(sceneObjects) do assert(object.name~="Tut Roof Attachment","bunker must not add floating roof attachments") end
do
    local oldWidth,oldHeight,oldScene=SceneMan.SceneWidth,SceneMan.SceneHeight,SceneMan.Scene
    local oldGround,oldRandom=SceneMan.MovePointToGround,math.random
    sceneObjects={}; actors={}
    SceneMan.SceneWidth=15600; SceneMan.SceneHeight=1600; SceneMan.Scene={PresetName="Frontline Highlands Battlefield"}
    local coverGroundProbes={}
    SceneMan.MovePointToGround=function(_,point,_,accuracy)
        if accuracy==0 then table.insert(coverGroundProbes,point.X) end
        return Vector(point.X,600)
    end
    math.random=function(low,high) return high and low or 1 end
    local highland=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
    highland:StartActivity()
    local counts={}
    local coverBodies={
        ["Zombie Cave Rock"]={-60,64},
        ["Zombie Cave Under Rock 1"]={-60,54},
        ["Zombie Cave Under Rock 2"]={-45,51},
        ["Concrete Barrier"]={0,23},
        ["Metal Crate Small A FG"]={0,23},
    }
    for _,object in ipairs(sceneObjects) do
        counts[object.name]=(counts[object.name] or 0)+1
        if object.name=="End B" and object.Pos.X==6720 then assert(not object.HFlipped and object.Pos.Y==1486) end
        if object.name=="End B" and (object.Pos.X==4008 or object.Pos.X==11208) then
            assert(not object.HFlipped and object.Pos.Y==1390)
        end
        if object.name=="T-Junction B" then
            assert((object.Pos.X==6912 or object.Pos.X==7200) and object.Pos.Y==1486
                or (object.Pos.X==4200 or object.Pos.X==11400) and object.Pos.Y==1390)
        end
        for _,layout in ipairs({{x=6912,segments=3},{x=7200,segments=3},
            {x=4200,segments=2},{x=11400,segments=2}}) do
            local shaftX=layout.x
            local hallY=1150+48+layout.segments*96
            if object.name=="Shaft A" and object.Pos.X==shaftX then
                assert(object.Pos.Y>=1198 and object.Pos.Y<=1198+(layout.segments-1)*96
                    and (object.Pos.Y-1198)%96==0)
            end
            if object.name=="Background Ladder" and object.Pos.X==shaftX-12 then
                assert(object.Pos.Y>=1150 and object.Pos.Y<=hallY-72 and (object.Pos.Y-1150)%24==0)
            end
            local body=coverBodies[object.name]
            if body then
                local left,right=object.Pos.X+body[1],object.Pos.X+body[2]
                assert(left>shaftX+100 or right<shaftX-100,
                    "Highlands surface cover footprint must leave the full shaft clearance open")
            end
        end
        end
    assert(counts["End B"]==3 and counts["T-Junction B"]==4
        and counts["Shaft A"]==10 and counts["Background Ladder"]==40,
        "Highlands must stamp three bunker halls with accessible mirrored shafts")
    assert(#highland.outposts==11,"Highlands must retain nine surface points and append two cavern capture points")
    for i=1,9 do
        assert(highland.outposts[i].level=="surface" and highland.outposts[i].x==1560*i,
            "the nine original Highlands surface outposts must stay at their existing coordinates")
    end
    local west,east=highland.outposts[10],highland.outposts[11]
    assert(west.level=="underground" and east.level=="underground" and west.x+east.x==SceneMan.SceneWidth)
    assert(west.captureY==east.captureY and west.groundY==east.groundY
        and west.landingX+east.landingX==SceneMan.SceneWidth and west.landingY==east.landingY)
    assert(west.bonus==east.bonus and west.bonus=="Call-ins -20%")
    for _,probeX in ipairs(coverGroundProbes) do
        for _,shaftX in ipairs({6912,7200,4200,11400}) do
            assert(math.abs(probeX-shaftX)>100,"cover footing probes must avoid each Highlands shaft mouth")
        end
    end
    assert(counts["Zombie Cave Rock"]>0,"Highlands cover loop should still place grounded cover away from shafts")
    SceneMan.SceneWidth=oldWidth; SceneMan.SceneHeight=oldHeight; SceneMan.Scene=oldScene
    SceneMan.MovePointToGround=oldGround; math.random=oldRandom
    sceneObjects={}; actors={}
end
a.panel=false
a.DrawHUD=function() end
a.DrawOutpost=function() end
local p=a.teams[0]
assert(p.auto and a.settings.unitCap==50 and p.counts[6]==3 and a:MaxSquadSize(0)==3)
p.auto=false; a.settings.unitCap=12; assert(a:Batch(0)==165)
assert(not a.commanders[0]:Deploy()); assert(a:AutoReason(0)=="Match setup")
a:StartBattle(); assert(a:AutoReason(0):find("Grace")); a.matchTimer.ElapsedSimTimeMS=15000
local ok=a.commanders[0]:Deploy(); assert(ok and p.funds==285 and a:UnitCount(0)==3)
assert(not a.commanders[0]:Deploy()); assert(p.funds==285)
p.timer.ElapsedSimTimeMS=10000; p.funds=109; assert(not a.commanders[0]:Deploy()); assert(p.timer.ElapsedSimTimeMS==10000)
p.funds=10000; p.levels[1]=1
local function assertCapacity(level)
    local maximum=3+level
    assert(a:MaxSquadSize(0)==maximum)
    p.counts={0,0,0,0,0,maximum}
    local cost,count=a:Batch(0); assert(cost and count==maximum)
    p.counts[6]=maximum+1
    local _,_,limit=a:Batch(0); assert(limit=="Squad size limit")
    p.counts[6]=maximum
end
assertCapacity(0)
p.counts={6,0,0,0}
assert(not a.commanders[0]:Deploy() and a:AutoReason(0)=="Squad size limit")
for level=1,6 do
    assert(a.commanders[0]:Research(29)); assertCapacity(level)
end
assert(p.levels[29]==6)
actors={}
assert(a.commanders[0]:Deploy()); assert(a:UnitCount(0)==9)
p.timer.ElapsedSimTimeMS=10000; p.funds=2000; p.counts={1,0,0,0}
assert(not a.commanders[0]:Research(5)); assert(a.commanders[0]:Research(4)); assert(p.tier==1); assert(a.commanders[0]:Research(5)); assert(p.tier==2)
p.auto=true; p.funds=1000; a.teams[1].auto=false; a:UpdateActivity(); assert(a:UnitCount(0)==10); assert(p.timer.ElapsedSimTimeMS==0)
a:UpdateActivity(); assert(a:UnitCount(0)==10)
local before=p.funds; p.levels[3]=1; a.deathCounts[1]=2; a:UpdateActivity(); assert(p.funds==before+105)
print('Frontline Lua rules: three-unit start, researched squad caps, cooldowns, research, auto deploy and bounty passed')
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
assert(#labels>=4 and labels[1]:find('FRONTLINE') and labels[1]:find('Funds:') and labels[2]:find('Batch:') and labels[2]:find('Deploy:'))
print('Compact HUD renders economy, batch, capacity, and deployment status')
-- Independent per-row weapons and research prerequisites.
actors={}
local b=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
b:StartActivity(); b:StartBattle(); b.DrawHUD=function() end; b.DrawOutpost=function() end
local t=b.teams[0]; t.funds=5000
assert(not b.commanders[0]:Research(6))
assert(b.commanders[0]:Research(1)); assert(b.commanders[0]:Research(4)); assert(not b.commanders[0]:Research(6))
assert(b.commanders[0]:Research(5)); assert(b.commanders[0]:Research(6))
assert(b.commanders[0]:Research(7)); assert(b.commanders[0]:Research(16))
assert(b.commanders[0]:Research(9))
t.counts={1,1,0,0}; t.weapons={4,2,1,1}
assert(b:Batch(0)==270)
b.matchTimer.ElapsedSimTimeMS=15000; assert(b.commanders[0]:Deploy()); assert(not b.commanders[0]:Deploy())
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
print('Per-unit loadouts, research prerequisites, grace and contested outpost passed')
-- All tabs and world marker use the supported primitive signatures.
UInputMan.GetMouseMovement=function() return Vector(0,0) end
UInputMan.MouseButtonPressed=function() return false end
for _,tab in ipairs({'Squad','Research','Battle','Support','Base','Setup'}) do b.tab=tab; Frontline.DrawPanel(b) end
Frontline.DrawOutpost(b)
print('Squad, research, battle panels and outpost marker render without Lua errors')

-- Call-ins enforce grace, resources, independent cooldowns, and target effects.
local c=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
actors={}; c:StartActivity(); c:StartBattle(); c.DrawHUD=function() end; c.DrawOutpost=function() end
for _,index in ipairs({21,22,23,24,25,26}) do c.teams[0].levels[index]=1 end
local ct=c.teams[0]; ct.funds=1000
assert(not c.commanders[0]:CallIn('strike', 2)); c.matchTimer.ElapsedSimTimeMS=15000
assert(c.commanders[0]:CallIn('strike', 2)); assert(ct.funds==780 and #c.pendingStrikes==1 and c.supportSounds.strike.playCount==1)
assert(not c.commanders[0]:CallIn('strike', 2) and c.supportSounds.strike.playCount==1); c.pendingStrikes[1].timer.ElapsedSimTimeMS=3000
c:UpdateCallIns(); assert(#c.pendingStrikes==1 and MovableMan.lastParticle.name=="Frontline Precision Projectile" and MovableMan.lastParticle.Team==0 and c.supportSounds.precisionCannon.playCount==1)
c.pendingStrikes[1].projectileTimer.ElapsedSimTimeMS=5000; c:UpdateCallIns(); assert(#c.pendingStrikes==0)
local injured=CreateAHuman('Soldier Light','Coalition.rte'); injured.Team=0; injured.Pos=Vector(c.outposts[2].x,565); injured.Health=70; injured.MaxHealth=100; MovableMan:AddActor(injured)
local actorsBeforeMedicalRobot=#actors
assert(c.commanders[0]:CallIn('medic', 2)); assert(injured.Health==70 and ct.funds==660 and c.pendingDrops[#c.pendingDrops].kind=='medic')
assert(not c.commanders[0]:CallIn('medic', 2)); assert(not c.commanders[0]:CallIn('medic', 4))
local medicDrop=c.pendingDrops[#c.pendingDrops]
medicDrop.timer.ElapsedSimTimeMS=4000; c:UpdateCallIns()
assert(medicDrop.ship.cargo[1].name=='Medic Drone')
medicDrop.arrivalTimer.ElapsedSimTimeMS=2000; c:UpdateCallIns()
assert(actors[#actors].name=='Medic Drone' and actors[#actors].Team==0 and #c.pendingDrops==0 and medicDrop.ship.openedWithCargo==0,
    'medic call-in should release a friendly medical robot before opening the dropship hatch')
print('Call-in costs, cooldowns, targeting, warning delay, explosions and medical robot dispatch passed')

-- Cover and mines avoid occupied lanes and independently enforce cooldowns.
ct.funds=2000
local objectCount=#sceneObjects
assert(c.commanders[0]:CallIn('cover', 2)); assert(#sceneObjects==objectCount and ct.funds==1860 and #c.pendingDrops==1)
assert(not c.commanders[0]:CallIn('cover', 2)); assert(ct.funds==1860)
local coverDrop=c.pendingDrops[1]; assert(coverDrop.kind=='cover' and coverDrop.count==3 and c.supportSounds.cover.playCount==1)
local previous=MovableMan.particleCount or 0
coverDrop.timer.ElapsedSimTimeMS=3999; c:UpdateCallIns(); assert(coverDrop.ship==nil and (MovableMan.particleCount or 0)==previous)
coverDrop.timer.ElapsedSimTimeMS=4000; c:UpdateCallIns(); assert(coverDrop.ship and coverDrop.ship.InventorySize==3)
coverDrop.arrivalTimer.ElapsedSimTimeMS=2000; c:UpdateCallIns()
assert(#c.pendingDrops==0 and MovableMan.particleCount==previous+3 and MovableMan.lastParticle.name=='Frontline Cover Pod')
previous=MovableMan.particleCount
local markerText,previousText={},PrimitiveMan.DrawTextPrimitive
PrimitiveMan.DrawTextPrimitive=function(_,pos,label,...) markerText[#markerText+1]=label end
local shipCount=#actors
assert(c.commanders[0]:CallIn('mines', 2)); assert(MovableMan.particleCount==previous and #actors==shipCount and ct.funds==1680 and #c.pendingDrops==1)
local mineDrop=c.pendingDrops[1]; assert(mineDrop.ship==nil and mineDrop.count==3 and c.supportSounds.mines.playCount==1)
c:UpdateCallIns(); assert(table.concat(markerText):find("MINES SHIP ARRIVES IN 4s",1,true))
mineDrop.timer.ElapsedSimTimeMS=3999; c:UpdateCallIns(); assert(MovableMan.particleCount==previous and mineDrop.ship==nil)
mineDrop.timer.ElapsedSimTimeMS=4000; c:UpdateCallIns(); assert(MovableMan.particleCount==previous and #actors==shipCount+1 and mineDrop.arrivalTimer and mineDrop.ship.InventorySize==3 and mineDrop.ship.goldValue==0 and mineDrop.ship.controller==Controller.CIM_DISABLED and not mineDrop.ship.hatchOpen)
mineDrop.arrivalTimer.ElapsedSimTimeMS=1999; c:UpdateCallIns(); assert(MovableMan.particleCount==previous and not mineDrop.ship.hatchOpen)
mineDrop.arrivalTimer.ElapsedSimTimeMS=2000; c:UpdateCallIns(); assert(MovableMan.particleCount==previous+3 and MovableMan.lastParticle.Sharpness==0 and mineDrop.ship.InventorySize==0 and mineDrop.ship.hatchOpen and mineDrop.ship.controller==Controller.CIM_AI)
previous=MovableMan.particleCount
assert(c.commanders[0]:CallIn('bomb', 2)); assert(MovableMan.particleCount==previous and ct.funds==1420 and #c.pendingDrops==1)
local bombDrop=c.pendingDrops[1]; assert(c.supportSounds.bomb.playCount==1); markerText={}
bombDrop.timer.ElapsedSimTimeMS=799
c:UpdateCallIns()
assert(MovableMan.particleCount==previous and bombDrop.bombsDropped==0)
bombDrop.timer.ElapsedSimTimeMS=800; c:UpdateCallIns()
assert(MovableMan.particleCount==previous+1 and bombDrop.bombsDropped==1)
local releasedBomb=MovableMan.lastParticle
assert(releasedBomb.name=='Frontline Carpet Bomb' and releasedBomb.module=='Frontline.rte'
    and releasedBomb.entityType=='MOSRotating' and releasedBomb.Team==0
    and releasedBomb.Pos.X==bombDrop.startX+96
    and releasedBomb.Pos.Y==bombDrop.ship.Pos.Y+(bombDrop.ship.Radius or 50)+12
    and releasedBomb.Vel.X==0 and releasedBomb.Vel.Y==20,
    'first carpet-bomb shell must remain a visible non-explosive payload at its original release position and velocity')
bombDrop.timer.ElapsedSimTimeMS=1600; c:UpdateCallIns(); assert(MovableMan.particleCount==previous+2)
bombDrop.timer.ElapsedSimTimeMS=2400; c:UpdateCallIns()
assert(MovableMan.particleCount==previous+3 and #c.pendingDrops==0
    and MovableMan.lastParticle.name=='Frontline Carpet Bomb' and MovableMan.lastParticle.entityType=='MOSRotating'
    and MovableMan.lastParticle.Pos.X==bombDrop.startX+288
    and MovableMan.lastParticle.Team==0 and MovableMan.lastParticle.Vel.Y==20)
-- The orbital salvo warns, fires over time, and then completes.
assert(c.commanders[0]:CallIn('orbital', 2)); assert(ct.funds==1245 and #c.pendingOrbitals==1 and c.supportSounds.orbital.playCount==1)
local salvo=c.pendingOrbitals[1]; previous=MovableMan.particleCount
salvo.timer.ElapsedSimTimeMS=2999; markerText={}; c:UpdateCallIns(); assert(MovableMan.particleCount==previous and table.concat(markerText):find("GATLING CANNON IN 1s",1,true))
salvo.timer.ElapsedSimTimeMS=3000; c:UpdateCallIns(); assert(MovableMan.particleCount==previous+1)
salvo.timer.ElapsedSimTimeMS=3000+4999; c:UpdateCallIns(); assert(#c.pendingOrbitals==1 and MovableMan.particleCount==previous+71)
salvo.timer.ElapsedSimTimeMS=3000+5000; c:UpdateCallIns()
assert(#c.pendingOrbitals==1 and MovableMan.particleCount==previous+72 and salvo.shots==72)
salvo.timer.ElapsedSimTimeMS=3000+7536; c:UpdateCallIns()
assert(#c.pendingOrbitals==0 and MovableMan.particleCount==previous+108 and salvo.shots==108)
local minX,maxX=math.huge,-math.huge
for i=#MovableMan.particles-107,#MovableMan.particles do
    local round=MovableMan.particles[i]; assert(round.name=='Frontline Orbital Round')
    minX=math.min(minX,round.Pos.X); maxX=math.max(maxX,round.Pos.X)
    assert(math.abs(round.Pos.X-c.outposts[2].x)<=150 and round.Team==0)
end
assert(maxX-minX>200 and salvo.sound.playCount==27)
assert(not c.commanders[0]:CallIn('orbital', 2))
PrimitiveMan.DrawTextPrimitive=previousText
print('Cover, mines, bomb and timed orbital salvo costs, effects and cooldowns passed')

-- Outpost bonuses and forward deployment.
local d=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
actors={}; d:StartActivity(); d:StartBattle(); local dt=d.teams[0]
dt.funds=5000; d.matchTimer.ElapsedSimTimeMS=15000
assert(d:TeamIncome(0)==5 and d:ResearchCost(0,3)==320 and d:CallinCooldown(0,45000)==45000)
d.outposts[1].owner=0; d.outposts[2].owner=0; d.outposts[3].owner=0
assert(d:TeamIncome(0)==10 and d:ResearchCost(0,3)==256 and d:CallinCooldown(0,45000)==36000)
d.settings.outpostBonuses=false; assert(d:TeamIncome(0)==5 and d:ResearchCost(0,3)==320); d.settings.outpostBonuses=true
dt.tier=2; dt.levels[5]=1; dt.counts={0,0,0,0,1}; dt.weapons={1,1,1,1,1}; d.commanders[0]:SetForward(2); d.commanders[0]:SetOrder('Advance',2)
assert(d:Batch(0)==310); assert(d.commanders[0]:Deploy()); local ship=actors[#actors]
assert(ship.ship and ship.AIMode==Actor.AIMODE_DELIVER and ship.InventorySize==1 and d:UnitCount(0)==1)
local vehicle=table.remove(ship.cargo); ship.InventorySize=#ship.cargo
vehicle.Pos=Vector(d.outposts[2].x-150,565); MovableMan:AddActor(vehicle); d:UpdateDeliveries()
assert(vehicle.vehicle and vehicle.AIMode==Actor.AIMODE_GOTO and math.abs(vehicle.waypoint.X-d.outposts[2].x)<=60 and d:UnitCount(0)==1)
dt.timer.ElapsedSimTimeMS=10000; d.outposts[2].owner=1; assert(not d.commanders[0]:Deploy())
-- Support research upgrades and temporary shield interception.
dt.funds=5000
assert(d.commanders[0]:Research(8)); assert(d.commanders[0]:Research(9)); assert(d.commanders[0]:Research(22)); assert(d.commanders[0]:Research(13)); assert(d.commanders[0]:Research(21))
assert(d.commanders[0]:CallIn('shield', 1)); assert(d:ShieldBlocks(d.outposts[1],1) and not d:ShieldBlocks(d.outposts[1],0))
 d.teams[1].levels[25]=1
assert(not d.commanders[1]:CallIn('bomb', 1)); d.jamFields[1].timer.ElapsedSimTimeMS=60000; assert(not d:ShieldBlocks(d.outposts[1],1))
assert(d.commanders[0]:CallIn('orbital', 3)); assert(d.pendingOrbitals[1].total==72)
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
assert(not w.commanders[1]:Deploy() and not w.commanders[0]:CallIn('strike', 2))
-- Click each wizard step, changing settings and starting the battle.
w.DrawWizard=nil; w.cursorX=25; w.cursorY=90
UInputMan.MouseButtonPressed=function() return true end
Frontline.DrawWizard(w); assert(w.settings.startFunds==750 and w.teams[0].funds==750 and w.teams[1].funds==750)
w.cursorX=25; w.cursorY=275; Frontline.DrawWizard(w); assert(w.setupStep==2)
w.cursorX=25; w.cursorY=225; Frontline.DrawWizard(w); assert(w.setupStep==1)
w.cursorX=25; w.cursorY=275; Frontline.DrawWizard(w); assert(w.setupStep==2)
w.cursorX=160; w.cursorY=225; Frontline.DrawWizard(w); assert(w.battleStarted and w.matchTimer.ElapsedSimTimeMS==0 and w.tab=='Squad')
assert(not w.commanders[1]:Deploy()); w.matchTimer.ElapsedSimTimeMS=15000; assert(w.commanders[1]:Deploy())
w.settings.callins=false; assert(not w.commanders[0]:CallIn('strike', 1))
print('Setup wizard holds both teams, cycles settings, reviews and starts grace before deployments')

-- Issuing new orders updates living troops and preserves the brain's sentry mode.
local own=CreateAHuman('Soldier Light','Coalition.rte'); own.Team=0; own.Pos=Vector(500,565); MovableMan:AddActor(own)
w.commanders[0]:SetOrder('Defend',1)
assert(own.AIMode==Actor.AIMODE_GOTO and math.abs(own.waypoint.X-w.outposts[1].x)<=60 and w.brains[0].AIMode==Actor.AIMODE_SENTRY)
own.Pos=Vector(w.outposts[1].x,565); w:UpdateOrders(); assert(own.AIMode==Actor.AIMODE_SENTRY)
w.commanders[0]:SetOrder('Advance',2)
assert(own.AIMode==Actor.AIMODE_GOTO and math.abs(own.waypoint.X-w.outposts[2].x)<=60)
own.Pos=Vector(w.outposts[2].x,565); w:UpdateOrders(); assert(own.AIMode==Actor.AIMODE_SENTRY)
w.outposts[2].owner=0; w:UpdateOrders(); assert(own.AIMode==Actor.AIMODE_BRAINHUNT)
w.commanders[0]:SetOrder('Rush',2); assert(own.AIMode==Actor.AIMODE_BRAINHUNT and own.waypoint==nil)
print('Orders apply to existing units, defend holds, advance resumes, and brains stay in place')
-- The stock game HUD is hidden only while Frontline's panel is visible.
local hudDisabled,externalHudState=false,false
FrameMan.IsHudDisabled=function(_,screen) assert(screen==0); return externalHudState end
FrameMan.SetHudDisabled=function(_,value,screen)
    assert(type(value)=="boolean" and screen==0,"HUD setter requires a boolean state for the player screen")
    hudDisabled=value
end
w.DrawPanel=function() end; w.DrawHUD=function() end; w.panel=true; w:UpdateActivity(); assert(hudDisabled==true)
w.panel=false; w:UpdateActivity(); assert(hudDisabled==false)
-- A resumed activity can lose its Lua fields while the HUD is in either state.
w.originalHudDisabled=nil; w.panel=nil; externalHudState=true; w:UpdateActivity()
assert(w.originalHudDisabled==true and w.panel==false and hudDisabled==true)
w.panel=true; w:UpdateActivity(); assert(hudDisabled==true)
w.panel=false; w:UpdateActivity(); assert(hudDisabled==true)
w.originalHudDisabled=nil; externalHudState=false; w:EndActivity()
assert(hudDisabled==false,"EndActivity must restore a real boolean HUD state")
-- Reusing an activity object for a fresh match must recapture the engine's new HUD baseline.
w.originalHudDisabled=true; externalHudState=false; w:StartActivity()
assert(w.originalHudDisabled==false and w.panel==true)
w.DrawWizard=function() end; w:UpdateActivity(); assert(hudDisabled==true)
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

-- A mass rush must interrupt normal objectives and send forces to the enemy base.
actors={}; local rush=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
rush:StartActivity(); rush:StartBattle(); rush.matchTimer.ElapsedSimTimeMS=15000
local ra=rush.teams[1]
for index=1,29 do ra.levels[index]=10 end
ra.tier=3; ra.funds=5000; ra.baseArmor=3; ra.turretLevel=2
ra.turret=CreateAHuman('Gatling Turret','Base.rte'); ra.turret.Team=1; ra.turret.Health=100; ra.turretID=ra.turret.UniqueID
ra.timer.ElapsedSimTimeMS=100000; ra.stats.deployed=0
rush.aiPersonality='economic'; rush:UpdateAI()
assert(ra.order=='Advance' and ra.orderTarget>0,'normal AI strategy should keep advancing when its base is not threatened')
local unitsBefore=ra.stats.deployed
for i=1,6 do
    local attacker=CreateAHuman('Soldier Light','Coalition.rte')
    attacker.Team=0; attacker.Pos=Vector(rush.brains[1].Pos.X-500+i*8,565); attacker.Health=100
    MovableMan:AddActor(attacker)
end
ra.timer.ElapsedSimTimeMS=100000; ra.funds=5000
rush.aiTimer.ElapsedSimTimeMS=0
rush.aiEmergencyTimer.ElapsedSimTimeMS=250
rush.panel=false; rush.DrawOutpost=function() end; rush.DrawHUD=function() end
local aiDecisionCount=0
local performAIUpdate=rush.UpdateAI
rush.UpdateAI=function(self) aiDecisionCount=aiDecisionCount+1; return performAIUpdate(self) end
assert(rush.aiTimer.ElapsedSimTimeMS<rush.aiInterval,'the ordinary decision interval has not elapsed')
rush:UpdateActivity()
assert(aiDecisionCount==1,'urgent event should invoke one full AI decision')
rush:UpdateActivity()
assert(aiDecisionCount==1,'persistent threat must not run the full AI again before the next bounded check')
assert(ra.order=='Defend' and ra.orderTarget==0 and ra.orderPhase=='assembling'
    and ra.attackTarget==nil and ra.forward==0,
    'overwhelming base rush must supersede forward strategy with home defense')
assert(ra.stats.deployed>unitsBefore and ra.lastAIAction and ra.lastAIAction.kind=='deployment',
    'counter-rush response must commit an available force through a real defensive deployment')
local baseOrders=0
for id,assignment in pairs(rush.orderAssignments) do
    if assignment.base then
        baseOrders=baseOrders+1
        for actor in MovableMan.Actors do
            if actor.UniqueID==id then assert(actor.AIMode==Actor.AIMODE_GOTO) end
        end
    end
end
assert(baseOrders>0,'field units must receive real base-defense waypoints')
print('AI preserves normal advance, then deploys and reassigns forces to repel a mass base rush')

-- Capacity decisions must include units reserved aboard forward dropships.
actors={}; local reserved=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
reserved:StartActivity(); reserved:StartBattle(); reserved.matchTimer.ElapsedSimTimeMS=15000
reserved.settings.unitCap=8; reserved.settings.callins=false
local reservedAI=reserved.teams[1]
reservedAI.funds=400; reservedAI.stats.deployed=3; reservedAI.tier=3
reservedAI.timer.ElapsedSimTimeMS=100000; reservedAI.baseArmor=3; reservedAI.turretLevel=2
for index=1,29 do reservedAI.levels[index]=10 end
for id=9001,9006 do reserved.inTransit[id]={team=1} end
assert(reserved:UnitCount(1)==6)
reserved:UpdateAI()
assert(reservedAI.stats.deployed==5 and reservedAI.lastAIAction.kind=='deployment'
    and reserved:UnitCount(1)==reserved.settings.unitCap,
    'AI should select the two legal open slots after accounting for six in-flight reservations')
print('AI capacity decisions include in-flight passenger reservations')

-- AI makes purchases and decisions through the same mechanisms as the player.
actors={}; local bot=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
bot:StartActivity(); bot:StartBattle(); bot.DrawHUD=function() end; bot.DrawOutpost=function() end
bot.matchTimer.ElapsedSimTimeMS=15000
local ai=bot.teams[1]; ai.funds=2000; ai.levels={2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1}; ai.tier=3; ai.stats.deployed=2
ai.timer.ElapsedSimTimeMS=0 -- Hold deployment cooldown so the funded turret upgrade can be selected.
for i=1,27 do ai.levels[i]=1 end
bot.outposts[3].owner=1
local enemyVehicle=CreateACrab('Gatling Drone','Coalition.rte'); enemyVehicle.Team=0; enemyVehicle.Pos=Vector(100,565); MovableMan:AddActor(enemyVehicle)
bot.aiTemperature=0.001 -- Deterministic for AI decision tests (below softmax threshold)
bot:UpdateAI(); assert(bot:MaxSquadSize(1)==3 and ai.forward==3)
-- With temperature-based selection, verify AI made a valid investment decision
assert(ai.lastAIAction ~= nil, "AI must make an investment decision")
ai.baseArmor=3
assert(ai.order=='Advance' and ai.orderTarget==2)
local aiCost,aiSize=bot:Batch(1); assert(aiSize>0 and aiSize<=bot:MaxSquadSize(1))
-- Same base income with no difficulty multiplier.
bot.aiTimer.ElapsedSimTimeMS=0; bot.settings.outpostBonuses=false; ai.auto=false; bot.teams[0].auto=false
local f0,f1=bot.teams[0].funds,ai.funds; bot:UpdateActivity()
assert(bot.teams[0].funds-f0==5 and ai.funds-f1==7,
    'base income deltas: player='..tostring(bot.teams[0].funds-f0)..' AI='..tostring(ai.funds-f1))
-- Support reactions use normal costs/cooldowns and do not target friendly clusters.
local medic1=CreateAHuman('Soldier Light','Coalition.rte'); medic1.Team=1; medic1.Pos=Vector(bot.outposts[3].x,565); medic1.Health=40; MovableMan:AddActor(medic1)
local medic2=CreateAHuman('Soldier Light','Coalition.rte'); medic2.Team=1; medic2.Pos=Vector(bot.outposts[3].x+30,565); medic2.Health=40; MovableMan:AddActor(medic2)
for index=1,29 do ai.levels[index]=10 end
ai.levels[13]=2; ai.levels[29]=6
ai.turretLevel=2; ai.baseArmor=3; ai.auto=false
ai.funds=400; bot:UpdateAI(); assert(medic1.Health==40 and medic2.Health==40 and ai.funds==280)
local medicalDrop=bot.pendingDrops[#bot.pendingDrops]
assert(medicalDrop.kind=='medic' and medicalDrop.count==2,'AI selected '..tostring(medicalDrop.kind)..' with '..tostring(medicalDrop.count)..' units instead of a two-drone medic drop')
medicalDrop.timer.ElapsedSimTimeMS=4000; bot:UpdateCallIns()
medicalDrop.arrivalTimer.ElapsedSimTimeMS=2000; bot:UpdateCallIns()
assert(bot.pendingDrops[#bot.pendingDrops]~=medicalDrop, 'AI medic action must complete through the same dropship delivery path')
local foe1=CreateAHuman('Soldier Light','Coalition.rte'); foe1.Team=0; foe1.Pos=Vector(bot.outposts[2].x,565); MovableMan:AddActor(foe1)
local foe2=CreateAHuman('Soldier Light','Coalition.rte'); foe2.Team=0; foe2.Pos=Vector(bot.outposts[2].x+20,565); MovableMan:AddActor(foe2)
bot.aiPersonality="aggressive"; ai.offenseChoice=1; ai.minesTimer.ElapsedSimTimeMS=0
bot.aiTemperature=0.001 -- Deterministic for AI strike/call-in decision tests
ai.funds=2000; bot:UpdateAI(); assert(#bot.pendingStrikes==1 and bot.pendingStrikes[1].team==1 and ai.funds==1780,'AI strike mismatch: strikes='..#bot.pendingStrikes..' funds='..ai.funds..' drops='..#bot.pendingDrops)
-- A hostile warning on an owned post prompts the same paid shield call-in.
local incoming={team=0,index=3,timer=Timer()}; table.insert(bot.pendingOrbitals,incoming)
ai.funds=2000; bot.aiTemperature=0.001; bot:UpdateAI(); assert(#bot.jamFields==1 and bot.jamFields[1].team==1 and ai.funds==1800)
print('AI uses shared income, research, units, forward orders, medics, strikes and shields')
-- The AI cycles through the other offensive call-ins and both fortification types.
local dropsBeforeBomb=#bot.pendingDrops
ai.funds=2000; bot.aiTemperature=0.001; bot:UpdateAI()
local bombDrop=bot.pendingDrops[#bot.pendingDrops]
assert(#bot.pendingDrops==dropsBeforeBomb+1 and bombDrop.kind=='bomb' and bombDrop.totalBombs==3 and ai.funds==1740,
    'AI should add a three-bomb run; drops='..#bot.pendingDrops..' funds='..ai.funds)
-- The bomb craft has left the target area before another salvo is considered.
bombDrop.ship.Pos=Vector(bot.outposts[2].x+1000,200)
ai.funds=2000; bot.aiTemperature=0.001; bot:UpdateAI(); assert(#bot.pendingOrbitals==2 and bot.pendingOrbitals[2].team==1 and ai.funds==1825)
foe1.Pos=Vector(bot.outposts[3].x-260,565); foe2.Pos=Vector(bot.outposts[3].x-260,565)
medic1.Health=100; medic2.Health=100; bot.pendingOrbitals={}; ai.funds=2000; ai.levels[14]=1; bot.aiPersonality="defensive"
local oldDrops=#bot.pendingDrops; bot.aiTemperature=0.001; bot:UpdateAI(); assert(#bot.pendingDrops==oldDrops+1 and bot.pendingDrops[#bot.pendingDrops].kind=='turret' and ai.funds==1700)
ai.minesTimer.ElapsedSimTimeMS=45000; ai.levels[22]=0 -- Isolate the Mines call-in from the defensive Cover preference.
ai.funds=2000; bot.aiTemperature=0.001; bot:UpdateAI(); assert(bot.pendingDrops[#bot.pendingDrops].kind=='mines' and bot.pendingDrops[#bot.pendingDrops].team==1 and ai.funds==1820,
    'AI expected mines, got '..tostring(bot.pendingDrops[#bot.pendingDrops] and bot.pendingDrops[#bot.pendingDrops].kind)..' funds='..tostring(ai.funds))
print('AI can use bomb, orbital cannon, turret and mines through standard call-in rules')


-- Free opening turrets are symmetric and stationary; paid upgrades retain
-- the existing range, durability, rebuild and mobile-army exclusion behavior.
actors={}; local base=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
base:StartActivity(); assert(not base.commanders[0]:BaseUpgrade('armor'))
local startingFunds={base.teams[0].funds,base.teams[1].funds}
base:StartBattle()
local bt=base.teams[0]; local enemyBaseTurret=base.teams[1].turret
local expectedTurretAimDistance=549.6
assert(bt.turret and bt.turret.name=='Frontline HE Base Turret' and bt.turretLevel==1
    and bt.turret.Team==0 and bt.turret.Pos.X==484 and bt.turret.Pos.Y==513 and not bt.turret.HFlipped
    and bt.turret.AIMode==Actor.AIMODE_SENTRY and bt.turret.Health==600 and bt.turret.MaxHealth==600
    and bt.turret.AimDistance==expectedTurretAimDistance and bt.turret.PinStrength==100000,
    'player must start with the configured free baseline HE turret')
assert(enemyBaseTurret and enemyBaseTurret.name=='Frontline HE Base Turret' and base.teams[1].turretLevel==1
    and enemyBaseTurret.Team==1 and enemyBaseTurret.Pos.X==4716 and enemyBaseTurret.Pos.Y==513 and enemyBaseTurret.HFlipped
    and enemyBaseTurret.AIMode==Actor.AIMODE_SENTRY and enemyBaseTurret.Health==600 and enemyBaseTurret.MaxHealth==600
    and enemyBaseTurret.AimDistance==expectedTurretAimDistance and enemyBaseTurret.PinStrength==100000,
    'enemy must start with the configured free mirrored baseline HE turret')
assert(base.teams[0].funds==startingFunds[1] and base.teams[1].funds==startingFunds[2],
    'granting both opening turrets must not spend either team’s funds')
local function countLiveBaseTurrets()
    local count=0
    for _,actor in ipairs(actors) do
        if (actor.name=='Frontline HE Base Turret' or actor.name=='Frontline HE Turret')
            and not actor.deleted and not actor.ToDelete and actor.Health>0 then count=count+1 end
    end
    return count
end
assert(countLiveBaseTurrets()==2)
base:StartBattle()
assert(countLiveBaseTurrets()==2 and base.teams[0].turret==bt.turret and base.teams[1].turret==enemyBaseTurret,
    'repeated start calls must not create duplicate base turrets')
base:UpdateActivity()
assert(countLiveBaseTurrets()==2,'ordinary updates must not recreate opening turrets')
assert(not base.commanders[0]:BaseUpgrade('turret'),'opening turret must not be purchasable a second time')
bt.funds=2000
assert(base.commanders[0]:BaseUpgrade('armor')); assert(bt.baseArmor==1 and base.brains[0].Health==150 and base.brains[0].MaxHealth==150 and bt.funds==1800)
assert(not base.commanders[0]:BaseUpgrade('repair')); base.brains[0].Health=90
assert(base.commanders[0]:BaseUpgrade('repair')); assert(base.brains[0].Health==140 and bt.funds==1680)
assert(bt.turret.name=='Frontline HE Base Turret' and bt.funds==1680)
local playerMuzzleX,playerMuzzleY=worldMuzzle(bt.turret)
assert(bt.turret.AIMode==Actor.AIMODE_SENTRY and bt.turret.AimDistance==expectedTurretAimDistance
    and bt.turret.Health==600 and bt.turret.MaxHealth==600
    and bt.turret.Pos.X==484 and bt.turret.Pos.Y==513 and not bt.turret.HFlipped
    and playerMuzzleX>upperLeft.Pos.X and playerMuzzleX<playerExit and playerMuzzleY>=upperOpeningTop and playerMuzzleY<=upperOpeningBottom
    and bt.turret.Pos.Y+bt.turret.SpriteOffset.Y+bt.turret.SpriteHeight==materialFloorY(upperLeft))
local gatling=bt.turret
assert(base.commanders[0]:BaseUpgrade('turretUpgrade'))
local upgradedPlayerMuzzleX,upgradedPlayerMuzzleY=worldMuzzle(bt.turret)
assert(gatling.ToDelete and bt.turret.name=='Frontline HE Turret'
    and bt.turret.AimDistance==expectedTurretAimDistance and bt.turret.Health==600 and bt.turret.MaxHealth==600
    and upgradedPlayerMuzzleX>upperLeft.Pos.X and upgradedPlayerMuzzleX<playerExit and upgradedPlayerMuzzleY>=upperOpeningTop
    and upgradedPlayerMuzzleY<=upperOpeningBottom and bt.funds==1030
    and bt.turret.Pos.Y+bt.turret.SpriteOffset.Y+bt.turret.SpriteHeight==materialFloorY(upperLeft),
    'HE upgrade retains floor contact, doubled health/range, and outward fragmentation cannon')
assert(base:UnitCount(0)==0 and not base.commanders[0]:BaseUpgrade('turret'),
    'stationary HE base turret must not count as a field unit or be purchased twice')
bt.turret.deleted=true; bt.funds=1000
assert(base.commanders[0]:BaseUpgrade('turret'))
assert(bt.turret.name=='Frontline HE Turret' and bt.turret.Health==600 and bt.turret.MaxHealth==600
    and bt.turret.AimDistance==expectedTurretAimDistance
    and bt.turret.Pos.Y+bt.turret.SpriteOffset.Y+bt.turret.SpriteHeight==materialFloorY(upperLeft),
    'rebuilt upgraded turret must retain HE variant, health, range and floor position')
assert(not base.commanders[0]:BaseUpgrade('turret'))
base.commanders[0]:SetOrder('Advance',2); assert(bt.turret.AIMode==Actor.AIMODE_SENTRY and bt.turret.waypoint==nil)
base.settings.callins=false
local bi=base.teams[1]
for index=1,29 do bi.levels[index]=10 end
bi.baseArmor=3; bi.auto=false; bi.funds=0; bi.timer.ElapsedSimTimeMS=0
base:UpdateAI()
assert(bi.turret and bi.turret.name=='Frontline HE Base Turret'
    and bi.turret.AimDistance==expectedTurretAimDistance and bi.turret.Health==600 and bi.turret.MaxHealth==600
    and bi.turret.Team==1 and bi.turret.Pos.X==4716 and bi.turret.Pos.Y==513 and bi.turret.HFlipped
    and bi.turret.Pos.Y+bi.turret.SpriteOffset.Y+bi.turret.SpriteHeight==materialFloorY(upperRight))
bi.funds=2000
base:UpdateAI()
local upgradedEnemyMuzzleX,upgradedEnemyMuzzleY=worldMuzzle(bi.turret)
assert(bi.turret.name=='Frontline HE Turret' and bi.turret.AimDistance==expectedTurretAimDistance
    and bi.turret.Health==600 and bi.turret.MaxHealth==600
    and upgradedEnemyMuzzleX<upperRight.Pos.X and upgradedEnemyMuzzleX>enemyExit and upgradedEnemyMuzzleY>=upperOpeningTop
    and upgradedEnemyMuzzleY<=upperOpeningBottom
    and bi.turret.Pos.Y+bi.turret.SpriteOffset.Y+bi.turret.SpriteHeight==materialFloorY(upperRight),
    'AI HE turret must preserve doubled health/range and clear mirrored lane')
print('Base armor, repair, symmetric turret geometry, HE range, unit-cap exclusion and AI upgrades passed')

-- Larger maps get the right number of posts and income bonuses stack.
actors={}; SceneMan.SceneWidth=10400
local medium=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
medium:StartActivity(); assert(#medium.outposts==5)
medium.outposts[1].owner=0; medium.outposts[4].owner=0
assert(medium:TeamIncome(0)==15)
SceneMan.SceneWidth=15600
local large=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
large:StartActivity(); assert(#large.outposts==9)
SceneMan.SceneWidth=5200
-- An arbitrary location works for delayed support, with no outpost index.
large:StartBattle(); large.matchTimer.ElapsedSimTimeMS=15000
large.teams[0].funds=2500
local target={name='target area',x=3100,groundY=600,owner=-1}
assert(large.commanders[0]:Research(21)); assert(large.commanders[0]:Research(24))
assert(large.commanders[0]:CallIn('strike', target)); assert(large.pendingStrikes[1].target==target)
large.pendingStrikes[1].timer.ElapsedSimTimeMS=3000
large:UpdateCallIns(); assert(#large.pendingStrikes==1 and MovableMan.lastParticle.name=="Frontline Precision Projectile")
large.pendingStrikes[1].projectileTimer.ElapsedSimTimeMS=5000; large:UpdateCallIns(); assert(#large.pendingStrikes==0)
-- Training upgrades improve existing and future troops for either team.
actors={}; SceneMan.SceneWidth=5200
local trained=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
trained:StartActivity(); trained:StartBattle(); trained.teams[1].funds=1000
local trainee=CreateAHuman('Soldier Light','Coalition.rte'); trainee.Team=1; trainee.Pos=Vector(3000,565); MovableMan:AddActor(trainee)
assert(trained.commanders[1]:Research(15)); assert(trainee.Perceptiveness==0.55)
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
-- Returning Frontline craft cannot refund their hull or paid cargo.
local ship=CreateACDropShip('Dropship MK1','Base.rte'); ship.Team=0; ship:SetGoldValue(0); ship.returnValue=45
local oldClear=FrameMan.ClearScreenText; FrameMan.ClearScreenText=function() end
economy.frontlineCraft[ship.UniqueID]=true; engineFunds[0]=550; economy.teams[0].funds=505
economy:CraftEnteredOrbit(ship); assert(engineFunds[0]==505 and economy.teams[0].funds==505)
engineFunds[0]=550; economy:CraftEnteredOrbit(ship); assert(engineFunds[0]==550)
FrameMan.ClearScreenText=oldClear
print('Returning Frontline ships cannot refund their hull or cargo')

do
-- Starter tier and separately priced, research-gated optional equipment.
actors={}; local kit=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
startActivity(kit); kit:StartBattle(); kit.matchTimer.ElapsedSimTimeMS=15000
local kt=kit.teams[0]; kt.funds=5000
assert(kt.weapons[1]==1 and kt.counts[6]==3 and kit:Batch(0)==165)
kt.counts={1,0,0,0,0,0}; kt.sidearms[1]=1; assert(not kit:Batch(0))
assert(kit.commanders[0]:Research(1)); assert(kit.commanders[0]:Research(19)); assert(kit.commanders[0]:Research(17)); assert(kit.commanders[0]:Research(18))
kt.medkits[1]=true; kt.grenades[1]=true
assert(kit:Batch(0)==180)
local playerFirstActor=#actors+1
assert(kit.commanders[0]:Deploy())
assert(kt.medkits[1] and kt.grenades[1] and kt.sidearms[1]==1)
local function countSafeGrenades(actor)
    local count=0
    for _,item in ipairs(actor.inventoryItems) do
        if item.name=='Frag Grenade' and item.module=='Coalition.rte' then count=count+1 end
    end
    return count
end
assert(actors[playerFirstActor].module=='Frontline.rte' and countSafeGrenades(actors[playerFirstActor])==3,
    'player deployment must use the Frontline actor and exactly three safe Coalition Frag Grenades')
local aiKit=kit.teams[1]
aiKit.funds=5000; aiKit.levels[1]=1; aiKit.levels[17]=1; aiKit.levels[18]=1; aiKit.counts={1,0,0,0,0,0}; aiKit.grenades[1]=true
local aiFirstActor=#actors+1
assert(kit.commanders[1]:Deploy())
assert(actors[aiFirstActor].module=='Frontline.rte' and countSafeGrenades(actors[aiFirstActor])==3,
    'AI deployment must use the same Frontline actor and three safe Coalition Frag Grenades')
print('Three-unit start and research-gated optional equipment use the safe timed-fuze grenade pack')
actors={}
local thrower=CreateAHuman('Soldier Light','Frontline.rte'); thrower.Team=0
thrower.Pos=Vector(100,200); thrower.EyePos=Vector(100,200); thrower.AIMode=Actor.AIMODE_GOTO
local throwTarget=CreateAHuman('Soldier Light','Coalition.rte'); throwTarget.Team=1
throwTarget.ID=9001; throwTarget.Pos=Vector(300,200); throwTarget.EyePos=Vector(300,190); throwTarget.Vel=Vector(5,0)
local throwAlly=CreateAHuman('Soldier Light','Frontline.rte'); throwAlly.Team=0
throwAlly.Pos=Vector(600,400); throwAlly.IndividualRadius=10
MovableMan:AddActor(thrower); MovableMan:AddActor(throwTarget); MovableMan:AddActor(throwAlly)
local rayHit=throwTarget.ID
SceneMan.CastMORay=function() return rayHit end
local grenade={
    MuzzlePos=Vector(110,200),
    GetCalculatedMaxThrowVelIncludingArmThrowStrength=function() return 15 end,
    GetNumberValue=function(_,key) return key=='TrajectoryGuideBlastRadius' and 75 or 0 end,
}
local receivedAimPoint,receivedVelocity
local canThrow=function(aimPoint,velocity)
    receivedAimPoint=aimPoint; receivedVelocity=velocity; return 0
end
assert(kit:CanFrontlineThrowGrenade(thrower,throwTarget,grenade,canThrow),
    'a visible reachable enemy with clear friendly landing space must pass the throw policy')
assert(receivedAimPoint.X==300 and receivedAimPoint.Y==195 and receivedVelocity.Magnitude==0,
    'the safety solver must use Native ThrowTarget’s un-led aim point despite target velocity')
throwAlly.Pos=Vector(426,195)
assert(kit:CanFrontlineThrowGrenade(thrower,throwTarget,grenade,canThrow),
    'safety clearance must use the native un-led landing aim, not a second velocity lead')
throwAlly.Pos=Vector(310,195)
assert(not kit:CanFrontlineThrowGrenade(thrower,throwTarget,grenade,canThrow),
    'the throw policy must reject a landing area containing a teammate')
throwAlly.Pos=Vector(600,400); rayHit=throwAlly.ID
assert(not kit:CanFrontlineThrowGrenade(thrower,throwTarget,grenade,canThrow),
    'the throw policy must reject an enemy obscured by a friendly')
rayHit=throwTarget.ID
assert(not kit:CanFrontlineThrowGrenade(thrower,throwTarget,grenade,function() return nil end),
    'the throw policy must reject an unreachable ballistic solution')
rayHit=throwTarget.ID
local firearm={name='Assault Rifle'}
local grenadeDevice={
    MuzzlePos=grenade.MuzzlePos,
    GetCalculatedMaxThrowVelIncludingArmThrowStrength=grenade.GetCalculatedMaxThrowVelIncludingArmThrowStrength,
    GetNumberValue=grenade.GetNumberValue,
    HasObjectInGroup=function(_,group) return group=='Bombs - Grenades' end,
}
thrower.EquippedItem=firearm; thrower.ThrowableIsReady=true
local inventoryIndex=0
thrower.Inventory=function()
    inventoryIndex=inventoryIndex+1
    if inventoryIndex==1 then return grenadeDevice end
end
function thrower:IsPlayerControlled() return false end
function thrower:HasObjectInGroup(group) return group=='Bombs - Grenades' end
function thrower:EquipDeviceInGroup(group,force) self.EquippedItem=grenadeDevice; return group=='Bombs - Grenades' and force end
function thrower:EquipFirearm() self.EquippedItem=firearm; return true end
local nativeAttackCount,nativeSawSquadMode=0,false
local function nativeLikeAttack(self,owner)
    nativeAttackCount=nativeAttackCount+1
    nativeSawSquadMode=owner.AIMode==Actor.AIMODE_SQUAD
    local distance=SceneMan:ShortestDistance(owner.Pos,self.Target.Pos,false)
    if owner.AIMode~=Actor.AIMODE_SQUAD and owner.AIMode~=Actor.AIMODE_SENTRY
        and self.Target.HFlipped==owner.HFlipped and owner:EquipDeviceInGroup("Bombs - Grenades",true)
        and distance.Magnitude>100
        and distance.Magnitude<grenadeDevice:GetCalculatedMaxThrowVelIncludingArmThrowStrength()*GetPPM()
        and (self.Target.Pos.Y+20)>owner.Pos.Y then
        self.NextBehavior=coroutine.create(HumanBehaviors.ThrowTarget)
        self.NextBehaviorName='ThrowTarget'
    elseif owner:EquipFirearm(true) then
        self.NextBehaviorName='NativeFirearm'
    end
end
thrower.AI={Target=throwTarget,ReloadTimer=Timer(),TargetLostTimer={Reset=function() end,SetSimTimeLimitMS=function() end},
    CreateAttackBehavior=nativeLikeAttack}
HumanBehaviors={GetGrenadeAngle=function() return 0 end,ThrowTarget=function() end,Sentry=function() end}
ActivityMan.GetActivity=function() return kit end
ToThrownDevice=function(item) return item end
thrower.AI:CreateAttackBehavior(thrower)
assert(thrower.AI.NextBehaviorName=='ThrowTarget' and not nativeSawSquadMode,
    'the native-like selector must prefer its grenade branch for this unsafe-target fixture')
nativeAttackCount=0; thrower.EquippedItem=firearm
local nativeCreateCount,nativeUpdateCount,nativeDestroyCount=0,0,0
NativeHumanAI={Create=function(_,owner)
    nativeCreateCount=nativeCreateCount+1
    owner.AI.Update=function() nativeUpdateCount=nativeUpdateCount+1 end
    owner.AI.Destroy=function() nativeDestroyCount=nativeDestroyCount+1 end
    return owner.AI
end}
assert(loadfile('Frontline.rte/FrontlineGrenadeAI.lua'))()
local FrontlineCreate=Create
thrower.AI=NativeHumanAI:Create(thrower)
FrontlineCreate(thrower)
assert(nativeCreateCount==1,'the copied preset must create native AI once before the Frontline hook')
thrower.AI:Update(thrower); ThreadedUpdateAI(thrower); thrower.AI:Destroy(thrower)
assert(nativeUpdateCount==1 and nativeDestroyCount==1,'the Frontline hook must leave native update and destroy to the copied preset')
thrower.AI:CreateAttackBehavior(thrower)
assert(thrower.AI.NextBehaviorName=='ThrowTarget' and thrower.EquippedItem==grenadeDevice
    and nativeAttackCount==0 and thrower.AIMode==Actor.AIMODE_GOTO,
    'Frontline AI must use the native throw behavior without changing its formation/order mode')
throwAlly.Pos=Vector(310,195)
thrower.AI:CreateAttackBehavior(thrower)
assert(thrower.AI.NextBehaviorName=='NativeFirearm' and thrower.EquippedItem==firearm
    and nativeAttackCount==1 and nativeSawSquadMode and thrower.AIMode==Actor.AIMODE_GOTO,
    'unsafe throws must bypass native grenade preference, select a firearm, and restore the order mode')
end

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
assert(tall.commanders[0]:Deploy()); assert(actors[#actors].Pos.Y==1065)
assert(tall.teams[0].turret.Pos.Y==1013 and not tall.commanders[0]:BaseUpgrade('turret'))
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
Actor.AIMODE_GOLDDIG=4
actors={}; local seeker=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
seeker:StartActivity(); assert(#seeker.goldSites==2); seeker:StartBattle()
seeker.matchTimer.ElapsedSimTimeMS=15001; seeker.teams[0].funds=5000
assert(seeker.commanders[0]:Research(14)); assert(seeker.commanders[0]:CallIn('mining', 1))
local miningDrop=seeker.pendingDrops[1]
miningDrop.timer.ElapsedSimTimeMS=4000; seeker:UpdateCallIns()
local goldMiner=miningDrop.ship.cargo[1]
miningDrop.arrivalTimer.ElapsedSimTimeMS=2000; seeker:UpdateCallIns()
assert(goldMiner.AIMode==Actor.AIMODE_GOTO and goldMiner.waypoint.X>=1500 and goldMiner.waypoint.X<=1544)
goldMiner.Pos=Vector(goldMiner.waypoint.X,565); seeker:UpdateMiners()
assert(goldMiner.AIMode==Actor.AIMODE_GOLDDIG)
goldLodes[2].active=false; seeker:UpdateMiners()
assert(goldMiner.AIMode==Actor.AIMODE_GOTO and goldMiner.waypoint.X>=900 and goldMiner.waypoint.X<=944)
goldLodes[1].active=false; seeker:UpdateMiners(); assert(goldMiner.AIMode==Actor.AIMODE_SENTRY)
seeker.commanders[0]:SetOrder('Rush',2); assert(goldMiner.AIMode==Actor.AIMODE_SENTRY)
SceneMan.CastMaterialRay=function() return false end
print('Mining call-in delivers a miner that seeks, digs, and retargets depleted deposits')

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
local rt=reverse.teams[0]; rt.tier=2; rt.weapons[6]=6; rt.levels[10]=1
reverse.cursorX=25; reverse.cursorY=115; Frontline.DrawPanel(reverse); assert(rt.weapons[6]==1)
pressed=MouseButtons.MOUSE_LEFT; Frontline.DrawPanel(reverse); assert(rt.weapons[6]==6)
rt.levels[19]=1; rt.levels[10]=0; pressed=MouseButtons.MOUSE_RIGHT; reverse.cursorX=140
Frontline.DrawPanel(reverse); assert(rt.sidearms[6]==1) -- skip locked RPG
pressed=MouseButtons.MOUSE_LEFT; Frontline.DrawPanel(reverse); assert(rt.sidearms[6]==0)
rt.levels[10]=1; pressed=MouseButtons.MOUSE_RIGHT; Frontline.DrawPanel(reverse); assert(rt.sidearms[6]==2)
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
watch.teams[0].levels[24]=1
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
for team=0,1 do for _,index in ipairs({21,22,23,24,25,26}) do visual.teams[team].levels[index]=1 end; visual.teams[team].levels[13]=2 end
visual.teams[0].shieldTimer.ElapsedSimTimeMS=60001
local target={name='target area',x=1500,groundY=600,owner=-1}
assert(visual.commanders[0]:CallIn('shield', target)); assert(#visual.jamFields==1 and visual.jamFields[1].x==1500)
assert(visual:ShieldBlocks({x=1680},1) and not visual:ShieldBlocks({x=1681},1))
assert(not visual:ShieldBlocks(target,0))
for _,kind in ipairs({'strike','medic','cover','mines','bomb','orbital','shield'}) do
    local funds=visual.teams[1].funds
    local ok,msg=visual.commanders[1]:CallIn(kind, target)
    assert(not ok and msg:find('jammer',1,true) and visual.teams[1].funds==funds)
end
assert(visual.commanders[0]:CallIn('cover', target)) -- allied support is not blocked
assert(visual.commanders[1]:CallIn('bomb', {name='outside',x=1681,groundY=600}))
local lineCount,jamText=0,false
PrimitiveMan.DrawLinePrimitive=function() lineCount=lineCount+1 end
PrimitiveMan.DrawTextPrimitive=function(_,_,label) if label:find('SUPPORT JAMMER 90s',1,true) then jamText=true end end
Frontline.DrawOutpost(visual); assert(lineCount>40 and jamText)
visual.jamFields[1].timer.ElapsedSimTimeMS=90000; lineCount=0; jamText=false
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
for team=0,1 do for _,index in ipairs({21,22,23,24,25,26}) do counter.teams[team].levels[index]=1 end; counter.teams[team].levels[13]=2 end
local contested={name='contested ground',x=2300,groundY=600}
assert(counter.commanders[0]:CallIn('strike', contested)); assert(counter.commanders[1]:CallIn('shield', contested))
local countBefore=MovableMan.particleCount or 0
counter.pendingStrikes[1].timer.ElapsedSimTimeMS=3001; counter:UpdateCallIns()
assert(#counter.pendingStrikes==0 and (MovableMan.particleCount or 0)==countBefore)
local funds=counter.teams[0].funds
assert(not counter.commanders[0]:CallIn('cover', contested) and counter.teams[0].funds==funds)
assert(counter.commanders[1]:CallIn('cover', contested))
print('Enemy jammer intercepts queued strikes and preserves friendly support')
-- A jammer raised during the four-second wait cancels an incoming delivery
-- before its ship appears and returns the purchase price.
local activeJammer=counter.jamFields[1]; counter.jamFields={}; counter.pendingDrops={}
counter.teams[0].funds=2000; counter.teams[0].bombTimer.ElapsedSimTimeMS=55000
assert(counter.commanders[0]:CallIn('bomb', contested)); local pendingBomb=counter.pendingDrops[1]
local actorsBefore=#actors; counter.jamFields={activeJammer}
pendingBomb.timer.ElapsedSimTimeMS=4000; counter:UpdateCallIns()
assert(#counter.pendingDrops==0 and #actors==actorsBefore and counter.teams[0].funds==2000)
-- If a jammer catches a run after release, cancel remaining bombs without refunding.
counter.jamFields={}; counter.teams[0].bombTimer.ElapsedSimTimeMS=55000
assert(counter.commanders[0]:CallIn('bomb', contested)); local partialRun=counter.pendingDrops[1]
local fundsAfterPurchase=counter.teams[0].funds
local particlesBeforePartial=MovableMan.particleCount or 0
partialRun.timer.ElapsedSimTimeMS=800; counter:UpdateCallIns()
assert(partialRun.bombsDropped==1 and MovableMan.particleCount==particlesBeforePartial+1)
counter.jamFields={activeJammer}
partialRun.timer.ElapsedSimTimeMS=1600; counter:UpdateCallIns()
assert(#counter.pendingDrops==0 and counter.teams[0].funds==fundsAfterPurchase,
    'a partially released bomb run must not receive a full refund')
print('Jammer intercepts an incoming support dropship before arrival')


-- An enemy jammer pauses an active barrage and fire resumes after expiry.
actors={}; local jamBurst=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
jamBurst:StartActivity(); jamBurst:StartBattle(); jamBurst.matchTimer.ElapsedSimTimeMS=15001
for team=0,1 do jamBurst.teams[team].funds=2000; jamBurst.teams[team].orbitalTimer.ElapsedSimTimeMS=75001; jamBurst.teams[team].shieldTimer.ElapsedSimTimeMS=60001 end
for team=0,1 do for _,index in ipairs({13,21,22}) do jamBurst.teams[team].levels[index]=1 end end
local burstPoint={name='open ground',x=2200,groundY=600}
assert(jamBurst.commanders[0]:CallIn('orbital', burstPoint))
local burst=jamBurst.pendingOrbitals[1]; local beforeRounds=MovableMan.particleCount or 0
burst.timer.ElapsedSimTimeMS=3000; jamBurst:UpdateCallIns(); assert(MovableMan.particleCount==beforeRounds+1)
assert(jamBurst.commanders[1]:CallIn('shield', burstPoint))
burst.timer.ElapsedSimTimeMS=3000+1064; jamBurst:UpdateCallIns(); assert(MovableMan.particleCount==beforeRounds+1)
jamBurst.jamFields[1].timer.ElapsedSimTimeMS=60000
burst.timer.ElapsedSimTimeMS=3000+1171; jamBurst:UpdateCallIns(); assert(MovableMan.particleCount==beforeRounds+2)
print('Enemy jammers suppress an active orbital burst until their field expires')

-- Forward batches arrive in actual craft, reserve capacity in flight, and
-- receive the current order after disembarking. Destroyed craft free slots.
actors={}; local transport=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
transport:StartActivity(); transport:StartBattle(); transport.matchTimer.ElapsedSimTimeMS=15001
local tt=transport.teams[0]; tt.funds=5000; tt.timer.ElapsedSimTimeMS=20001; tt.levels[11]=1
assert(transport.commanders[0]:Research(1))
transport.outposts[2].owner=0; transport.settings.unitCap=6; transport.commanders[0]:SetForward(2); tt.levels[29]=3; tt.counts={5,0,0,0,0,1}
local transportCost=transport:Batch(0); assert(transportCost==755)
assert(transport.commanders[0]:Deploy()); assert(tt.funds==3945 and #transport.deliveries==2 and transport:UnitCount(0)==6)
local firstShip,secondShip=transport.deliveries[1].ship,transport.deliveries[2].ship
assert(firstShip.InventorySize==3 and secondShip.InventorySize==3 and firstShip.Team==0 and secondShip.Team==0)
assert(firstShip.AIMode==Actor.AIMODE_DELIVER and firstShip.Pos.X<transport.outposts[2].x)
tt.timer.ElapsedSimTimeMS=10001; tt.counts={1,0,0,0,0,0}; assert(not transport.commanders[0]:Deploy())
-- Change orders while aboard; the passenger uses the latest order on arrival.
transport.commanders[0]:SetOrder('Advance',3); tt.levels[15]=2
local firstPassenger=table.remove(firstShip.cargo,1); firstShip.InventorySize=#firstShip.cargo
firstPassenger.Pos=Vector(firstShip.Pos.X,565); MovableMan:AddActor(firstPassenger); transport:UpdateDeliveries()
assert(firstPassenger.AIMode==Actor.AIMODE_GOTO and math.abs(firstPassenger.waypoint.X-transport.outposts[3].x)<=60)
assert(firstPassenger.Perceptiveness==0.6 and transport:UnitCount(0)==6)
secondShip.deleted=true; transport:UpdateDeliveries(); assert(transport:UnitCount(0)==6)
transport.deliveries[2].lostTimer.ElapsedSimTimeMS=2001; transport:UpdateDeliveries()
assert(#transport.deliveries==1 and transport:UnitCount(0)==3)
-- Missing transport fails atomically, with neither cost nor cooldown consumed.
actors={}; local missing=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
missing:StartActivity(); missing:StartBattle(); missing.matchTimer.ElapsedSimTimeMS=15001
missing.outposts[1].owner=0; missing.teams[0].forward=1; missing.teams[0].funds=1000; missing.teams[0].timer.ElapsedSimTimeMS=20001
local originalFactory=CreateACDropShip; CreateACDropShip=function() return nil end
local success,reason=missing.commanders[0]:Deploy()
CreateACDropShip=originalFactory
assert(not success and reason:find('Dropship',1,true) and missing.teams[0].funds==1000 and missing.teams[0].timer.ElapsedSimTimeMS==20001 and #missing.deliveries==0)
print('Forward dropships reserve slots, deliver current orders, and release lost cargo slots')

-- Craft loads respect both the native passenger and mass limits.
actors={}; local payload=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
payload:StartActivity(); payload:StartBattle(); payload.matchTimer.ElapsedSimTimeMS=15001
payload.outposts[2].owner=1; local pt=payload.teams[1]; pt.forward=2; pt.funds=5000; pt.timer.ElapsedSimTimeMS=20001; pt.counts={3,0,0,0,0,0}
assert(payload.commanders[1]:Research(1))
local originalHuman=CreateAHuman
CreateAHuman=function(n,m) local unit=originalHuman(n,m); unit.Mass=500; return unit end
assert(payload.commanders[1]:Deploy()); assert(#payload.deliveries==3 and payload:UnitCount(1)==3)
for _,delivery in ipairs(payload.deliveries) do
    assert(delivery.ship.InventorySize==1 and delivery.ship.Pos.X>payload.outposts[2].x)
end
actors={}; local overweight=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
CreateAHuman=originalHuman; overweight:StartActivity(); overweight:StartBattle(); overweight.matchTimer.ElapsedSimTimeMS=15001
overweight.outposts[1].owner=0; local ot=overweight.teams[0]; ot.forward=1; ot.funds=1000; ot.timer.ElapsedSimTimeMS=20001; ot.counts={1,0,0,0,0,0}
ot.levels[1]=1
CreateAHuman=function(n,m) local unit=originalHuman(n,m); unit.Mass=900; return unit end
local okHeavy,heavyReason=overweight.commanders[0]:Deploy(); CreateAHuman=originalHuman
assert(not okHeavy and heavyReason:find('heavy',1,true) and ot.funds==1000 and ot.timer.ElapsedSimTimeMS==20001 and #overweight.deliveries==0)
print('Dropship loads honor mass limits and reject overweight batches atomically')

-- On taller scenes the craft starts at a consistent height above its landing zone.
local originalHighGround=SceneMan.MovePointToGround
SceneMan.SceneWidth=15600; SceneMan.MovePointToGround=function(_,p) return Vector(p.X,1100) end
actors={}; local highTransit=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
highTransit:StartActivity(); highTransit:StartBattle(); highTransit.matchTimer.ElapsedSimTimeMS=15001
highTransit.outposts[1].owner=0; local ht=highTransit.teams[0]; ht.forward=1; ht.funds=1000; ht.timer.ElapsedSimTimeMS=20001; ht.counts={1,0,0,0,0,0}
ht.levels[1]=1
assert(highTransit.commanders[0]:Deploy()); assert(highTransit.deliveries[1].ship.Pos.Y==450 and highTransit:UnitCount(0)==1)
SceneMan.SceneWidth=5200; SceneMan.MovePointToGround=originalHighGround
print('Forward dropship approach height follows tall battlefield terrain')

-- Both deployment modes and sides share the effective cooldown. A new
-- destination cannot bypass the prior deployment's longer interval.
actors={}; local cooldowns=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
cooldowns:StartActivity(); cooldowns:StartBattle(); cooldowns.matchTimer.ElapsedSimTimeMS=15001
cooldowns.DrawHUD=function() end; cooldowns.DrawOutpost=function() end; cooldowns.panel=false
local side=cooldowns.teams[0]; side.funds=50000; side.counts={1,0,0,0,0,0}; side.auto=false
side.levels[1]=1
cooldowns.teams[1].auto=false; cooldowns.outposts[2].owner=0
assert(cooldowns.commanders[0]:Deploy()); side.timer.ElapsedSimTimeMS=10000; side.forward=2
assert(not cooldowns.commanders[0]:Deploy() and cooldowns:AutoReason(0)=='Cooldown 10s')
side.auto=true; cooldowns:SetTeamFunds(side.funds,0); local before=side.stats.deployed
cooldowns:UpdateActivity(); assert(side.stats.deployed==before)
side.auto=false; side.timer.ElapsedSimTimeMS=19999; assert(not cooldowns.commanders[0]:Deploy())
side.timer.ElapsedSimTimeMS=20000; assert(cooldowns.commanders[0]:Deploy() and side.lastDeployCooldown==20000)
side.forward=0; side.timer.ElapsedSimTimeMS=10000; assert(not cooldowns.commanders[0]:Deploy())
side.timer.ElapsedSimTimeMS=20000; assert(cooldowns.commanders[0]:Deploy() and side.lastDeployCooldown==10000)
side.timer.ElapsedSimTimeMS=10000; assert(cooldowns.commanders[0]:Deploy())
local enemy=cooldowns.teams[1]; cooldowns.outposts[3].owner=1; enemy.forward=3; enemy.funds=50000; enemy.counts={1,0,0,0,0,0}
enemy.levels[1]=1
assert(cooldowns.commanders[1]:Deploy()); enemy.forward=0; enemy.timer.ElapsedSimTimeMS=10000; assert(not cooldowns.commanders[1]:Deploy())
enemy.timer.ElapsedSimTimeMS=20000; assert(cooldowns.commanders[1]:Deploy())
print('Base and outpost cooldowns apply to manual, auto, destination changes, and both teams')


-- Every support respects both teams' enemy-base exclusion before charging.
actors={}; local restricted=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
restricted:StartActivity(); restricted:StartBattle(); restricted.matchTimer.ElapsedSimTimeMS=15001
for team=0,1 do
    local t=restricted.teams[team]; t.funds=5000
    for _,index in ipairs({11,13,14,21,22,23,24,25,26,27,28,30}) do t.levels[index]=1 end
    local enemyX=team==0 and SceneMan.SceneWidth-180 or 180
    local sign=team==0 and -1 or 1
    assert(not restricted:SupportTargetAllowed(team,enemyX+sign*900))
    assert(restricted:SupportTargetAllowed(team,enemyX+sign*901))
    assert(restricted:SupportTargetAllowed(team,team==0 and 180 or SceneMan.SceneWidth-180))
    for _,kind in ipairs({'strike','medic','cover','mines','bomb','turret','orbital','shield','bubble','mining','weaponPod','assaultSquad'}) do
        local before=t.funds
        local ok,reason=restricted.commanders[team]:CallIn(kind, {name='enemy base',x=enemyX,groundY=600})
        assert(not ok and reason:find('restricted',1,true) and t.funds==before,
            kind..' must reject targets near the enemy base before charging funds')
    end
end
-- Allied bases are not excluded for a defensive support call.
assert(restricted:SupportTargetAllowed(0,180) and restricted:SupportTargetAllowed(1,SceneMan.SceneWidth-180))
print('900px enemy-base support exclusion applies to both teams and all call-ins')

-- Compact HUD totals stacking income and discounts, both sides' deaths
-- and elapsed match time. Disabled outpost bonuses must not be advertised.
actors={}; SceneMan.SceneWidth=15600
local scoreboard=setmetatable({deathCounts={[0]=4,[1]=7}}, {__index=Frontline})
scoreboard:StartActivity(); scoreboard:StartBattle(); scoreboard.matchTimer.ElapsedSimTimeMS=125000
scoreboard.outposts[1].owner=0; scoreboard.outposts[4].owner=0
scoreboard.outposts[2].owner=0; scoreboard.outposts[5].owner=0; scoreboard.outposts[3].owner=0
local hudText={}; PrimitiveMan.DrawScreenTextPrimitive=function(_,_,_,label) hudText[#hudText+1]=label end
Frontline.DrawHUD(scoreboard); local hud=table.concat(hudText,' | ')
assert(hud:find('Post bonuses: +10/s',1,true) and hud:find('Research -36%',1,true) and hud:find('Support -20%',1,true))
assert(hud:find('Deaths: 4 / 7',1,true) and hud:find('Match time: 2:05',1,true))
scoreboard.settings.outpostBonuses=false; hudText={}; Frontline.DrawHUD(scoreboard); hud=table.concat(hudText,' | ')
assert(hud:find('Post bonuses: +0/s',1,true) and hud:find('Research -0%',1,true) and hud:find('Support -0%',1,true))
scoreboard.WinnerTeam=0; scoreboard.resultReady=true; local finalReport
FrameMan.SetScreenText=function(_,message) finalReport=message end
scoreboard:EndActivity(); assert(finalReport:find('Match time: 2:05',1,true) and finalReport:find('Friendly losses: 4',1,true) and finalReport:find('Enemy losses: 7',1,true))
SceneMan.SceneWidth=5200
print('HUD shows actual combined outpost bonuses, team deaths and match time')

-- Research unlocks optional per-unit armor for either side, including miners
-- and drones. It changes both health and batch cost.
actors={}; local plating=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
plating:StartActivity(); plating:StartBattle(); plating.matchTimer.ElapsedSimTimeMS=15001
local armorTeam=plating.teams[0]; armorTeam.funds=5000; armorTeam.timer.ElapsedSimTimeMS=10001
armorTeam.counts={2,0,0,0,0,0}; armorTeam.armor[1]=true
assert(not plating:Batch(0)); assert(plating.commanders[0]:Research(1)); assert(plating.commanders[0]:Research(20)); assert(plating:Batch(0)==280)
assert(plating.commanders[0]:Deploy()); assert(actors[#actors].MaxHealth==150 and actors[#actors].Health==150 and actors[#actors-1].Health==150)
armorTeam.timer.ElapsedSimTimeMS=10001; assert(plating.commanders[0]:Research(4)); assert(plating.commanders[0]:Research(5))
armorTeam.counts={0,0,0,0,1,1}; armorTeam.armor[5]=true; armorTeam.armor[6]=true
assert(plating:Batch(0)==435); assert(plating.commanders[0]:Deploy()); assert(actors[#actors].Health==150 and actors[#actors-1].Health==150)
local opponentArmor=plating.teams[1]; opponentArmor.funds=5000
assert(plating.commanders[1]:Research(1)); assert(plating.commanders[1]:Research(20))
opponentArmor.armor[1]=true; opponentArmor.counts={1,0,0,0,0,0}; assert(plating:Batch(1)==140)
print('Armor research, per-unit cost and health, drones and both teams passed')

-- Stock builds use the engine's screen-space text instead of scene primitives.
local compactText, compactCleared
FrameMan.SetScreenText=function(_,value,screen,blink,duration,centered) compactText=value; assert(screen==0 and centered==false) end
FrameMan.ClearScreenText=function() compactCleared=true end
scoreboard.screenUI=false
scoreboard.noticeTimer.ElapsedSimTimeMS=6000
cameraOffset=Vector(123,456)
Frontline.DrawHUD(scoreboard)
assert(compactText:find('Post bonuses:',1,true) and compactText:find('Match time:',1,true))
assert(select(2,compactText:gsub('\n',''))==3 and compactText:find(' | ',1,true))
local before=compactText
cameraOffset=Vector(900,20)
Frontline.DrawHUD(scoreboard)
assert(compactText==before)
scoreboard:ClearCompactHUD()
assert(compactCleared and not scoreboard.compactScreenText)
print('Stock compact HUD uses camera-independent screen text and clears when hidden')

-- A cover pod converts to a ground-aligned, destructible crate on impact.
local podEnv=setmetatable({}, {__index=_G})
local podScript=assert(loadfile('Frontline.rte/CoverPod.lua')); setfenv(podScript,podEnv); podScript()
local pod={Pos=Vector(1200,560),Team=1}; local placedBefore=#sceneObjects
podEnv.OnCollideWithTerrain(pod,1); podEnv.Update(pod)
local crate=sceneObjects[#sceneObjects]
assert(#sceneObjects==placedBefore+1 and crate.name=='Metal Crate Small A FG' and crate.Team==1 and crate.Pos.X==1188 and crate.Pos.Y==576 and pod.ToDelete)
print('Cover pods become ground-aligned destructible crates')

-- Forward pricing is symmetric, position based and rounded up in 25 oz tiers.
;(function()
    local originalWidth=SceneMan.SceneWidth
    for _,scenario in ipairs({{5200,3},{11000,5},{15600,9}}) do
        SceneMan.SceneWidth=scenario[1]
        actors={}
        local activity=setmetatable({deathCounts={[0]=0,[1]=0}},{__index=Frontline})
        activity:StartActivity(); activity:StartBattle(); activity.matchTimer.ElapsedSimTimeMS=15001
        assert(#activity.outposts==scenario[2])
        local span=scenario[1]-360
        for team=0,1 do
            local t=activity.teams[team]
            t.levels[29]=6; t.funds=10000; t.timer.ElapsedSimTimeMS=20001
            t.counts={0,0,0,0,0,1}; t.forward=0
            assert(activity:ForwardDeploymentCost(team)==0 and activity:Batch(team)==55)
            local last=0
            for step=1,scenario[2] do
                local index=team==0 and step or scenario[2]+1-step
                local post=activity.outposts[index]
                t.forward=index
                local expected=25*step
                assert(activity:ForwardDeploymentCost(team)==expected and expected>=last)
                last=expected
                assert(activity:Batch(team)==55+expected)
            end
            t.forward=1
            local post=activity.outposts[1]
            local originalX=post.x
            local function check(distance,expected)
                post.x=team==0 and 180+distance or scenario[1]-180-distance
                assert(activity:ForwardDeploymentCost(team)==expected)
            end
            check(-1,0); check(0,0); check(span+1,25*scenario[2])
            for tier=1,scenario[2]-1 do
                local boundary=span*tier/scenario[2]
                check(boundary-0.01,25*tier)
                check(boundary,25*tier)
                check(boundary+0.01,25*(tier+1))
            end
            post.x=originalX
            t.forward=team==0 and scenario[2] or 1
            for _,size in ipairs({1,3,9}) do
                t.counts={0,0,0,0,0,size}
                assert(activity:Batch(team)==size*(55+activity:ForwardDeploymentCost(team)))
            end
            t.counts={0,0,0,0,0,3}
            local cost=activity:Batch(team)
            activity.outposts[t.forward].owner=1-team
            assert(not activity.commanders[team]:Deploy() and t.funds==10000)
            activity.outposts[t.forward].owner=team
            t.funds=cost-1
            assert(not activity.commanders[team]:Deploy() and t.funds==cost-1)
            t.funds=cost
            assert(activity.commanders[team]:Deploy() and t.funds==0)
            t.funds=cost
            assert(not activity.commanders[team]:Deploy() and t.funds==cost)
        end
    end
    SceneMan.SceneWidth=originalWidth
end)()
print('Forward deployment pricing scales by position, squad size and team')
;(function()
    local oldScene,oldWidth,oldHeight=SceneMan.Scene,SceneMan.SceneWidth,SceneMan.SceneHeight
    local oldGround=SceneMan.MovePointToGround
    SceneMan.Scene={PresetName="Frontline Highlands Battlefield"}
    SceneMan.SceneWidth=15600; SceneMan.SceneHeight=1600
    SceneMan.MovePointToGround=function(_,point) return Vector(point.X,1150) end
    actors={}
    local caves=setmetatable({deathCounts={[0]=0,[1]=0}},{__index=Frontline})
    caves:StartActivity(); caves:StartBattle(); actors={}
    caves.matchTimer.ElapsedSimTimeMS=16000
    local west,east=caves.outposts[10],caves.outposts[11]
    caves.teams[0].forward=10
    assert(caves:ForwardDeploymentCost(0)==75)
    caves.teams[1].forward=11
    assert(caves:ForwardDeploymentCost(1)==75,"paired cave deployments must retain the nine surface cost tiers")

    local function addActor(team,x,y,vehicle)
        local unit=vehicle and CreateACrab("Test Vehicle","Base.rte") or CreateAHuman("Test Soldier","Base.rte")
        unit.Team=team; unit.Pos=Vector(x,y); actors[#actors+1]=unit
        return unit
    end
    local aiClimber=addActor(1,west.x,west.captureY,false)
    for _,post in ipairs(caves.outposts) do post.owner=1 end
    west.owner=-1
    caves.aiPersonality="balanced"; caves.aiTemperature=0
    local aiSnapshot=caves:CollectAISnapshot(1)
    local strategicGoal=caves:ChooseAIStrategicGoal(aiSnapshot,caves.teams[1])
    assert(strategicGoal.goal=="advance" and strategicGoal.target==10
        and aiSnapshot.posts[10].allies==1,
        "AI strategic targeting must select the mirrored underground capture point at its Y level")
    assert(caves.commanders[1]:SetOrder("Advance",strategicGoal.target)
        and aiClimber.AIMode==Actor.AIMODE_GOTO and aiClimber.waypoint.Y==west.captureY,
        "AI must route its selected cave capture goal to the walkable hall, not surface terrain")
    for _,post in ipairs(caves.outposts) do post.owner=-1 end
    actors={}; caves.orderAssignments={}
    local surfaceUnit=addActor(0,west.x,west.surfaceY-20,false)
    caves:UpdateOutpost(8)
    assert(west.progress==0 and west.owner==-1,"same-X surface units must not contest the underground capture zone")
    local snapshot=caves:CollectAISnapshot(1)
    assert(snapshot.posts[10].enemies==0 and snapshot.posts[10].threats==0,
        "surface units above a cave must not register as underground AI threats")

    actors={}
    local vehicle=addActor(0,west.x,west.captureY,true)
    caves:UpdateOutpost(8)
    assert(west.progress==0 and caves:CollectAISnapshot(1).posts[10].enemies==0,
        "non-climbing vehicles cannot capture or threaten an underground post")
    assert(caves.commanders[0]:SetOrder("Defend",10))
    local vehicleOrder=caves.orderAssignments[vehicle.UniqueID]
    assert(vehicleOrder.surfaceHold and math.abs(vehicle.waypoint.X-west.landingX)<100,
        "non-climbing vehicles must stage at the surface entry, not enter the shaft")

    actors={}
    local climber=addActor(0,west.x,west.captureY,false)
    local hostile=addActor(1,west.x,west.captureY,false)
    caves:UpdateOutpost(8)
    snapshot=caves:CollectAISnapshot(1)
    assert(west.progress==0 and snapshot.posts[10].allies==1 and snapshot.posts[10].enemies==1,
        "Y-aware cave capture and AI proximity must contest the actual underground hall")
    actors={climber}
    assert(caves.commanders[0]:SetOrder("Advance",10))
    assert(climber.AIMode==Actor.AIMODE_GOTO and climber.waypoint.Y==west.captureY,
        "human orders must target the walkable underground capture level")
    caves:UpdateOutpost(8)
    assert(west.owner==0 and caves:PostBonusCount(0,3)==1,
        "a human reaching the underground hall captures its real outpost bonus")

    west.owner=1
    assert(select(2,caves:CheckUrgentAIThreats(1)),"AI must react to threats inside its underground outpost")
    actors={surfaceUnit}
    assert(not select(2,caves:CheckUrgentAIThreats(1)),
        "AI must ignore same-X surface traffic for an underground defense")
    west.owner=0
    actors={}

    local player=caves.teams[0]
    player.forward=10; west.owner=0; player.funds=10000; player.timer.ElapsedSimTimeMS=100000
    player.counts={0,0,0,0,0,1}
    assert(caves.commanders[0]:Deploy())
    local delivery=caves.deliveries[#caves.deliveries]
    assert(delivery.ship.Pos.Y<west.surfaceY and math.abs(delivery.ship.Pos.X-west.landingX)<200,
        "forward dropships for cave posts must deliver at the paired surface entry")

    player.levels[25]=1
    player.bombTimer.ElapsedSimTimeMS=100000
    assert(caves.commanders[0]:CallIn("bomb",10))
    local bomb=caves.pendingDrops[#caves.pendingDrops]
    assert(bomb.target.x==west.landingX and bomb.target.groundY==west.landingY
        and bomb.ship.Pos.Y<west.surfaceY,"air support for a cave post must target above-ground entry terrain")
    player.levels[13]=1
    player.shieldTimer.ElapsedSimTimeMS=100000
    assert(caves.commanders[0]:CallIn("shield",10))
    local caveJam=caves.jamFields[#caves.jamFields]
    assert(caveJam.groundY==west.groundY
        and caves:ShieldBlocks({x=west.x,groundY=west.groundY},1)
        and not caves:ShieldBlocks({x=west.x,groundY=west.surfaceY},1),
        "underground defensive support stays in its cave and does not alias the surface above")

    assert(west.x+east.x==SceneMan.SceneWidth and west.landingX+east.landingX==SceneMan.SceneWidth)
    SceneMan.Scene=oldScene; SceneMan.SceneWidth=oldWidth; SceneMan.SceneHeight=oldHeight
    SceneMan.MovePointToGround=oldGround; actors={}
end)()
print('Highlands cavern outposts: level-aware capture, AI, orders and surface-safe support passed')
