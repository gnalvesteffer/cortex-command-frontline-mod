Frontline={}; Actor={AIMODE_SENTRY=1,AIMODE_BRAINHUNT=2,AIMODE_GOTO=3,AIMODE_DELIVER=5,AIMODE_RETURN=6}; Controller={CIM_AI=1,CIM_DISABLED=0}; Activity={OBSERVE=1,OVER=2,NOTEAM=-1}
Key={TAB=1}; MouseButtons={MOUSE_LEFT=1,MOUSE_RIGHT=2}; rte={goldID=2}
function Timer() return {ElapsedSimTimeMS=0, IsPastSimMS=function(s,n) return s.ElapsedSimTimeMS>=n end, Reset=function(s) s.ElapsedSimTimeMS=0 end} end
function Vector(x,y) return setmetatable({X=x,Y=y},{__add=function(a,b) return Vector(a.X+b.X,a.Y+b.Y) end}) end
local nextId=0
function CreateAHuman(n,m) nextId=nextId+1; return {Team=0,UniqueID=nextId,name=n,module=m,Health=100,MaxHealth=100,Height=70,AddInventoryItem=function(self,item) self.inventory=item end,ClearAIWaypoints=function(self) self.waypoint=nil end,AddAISceneWaypoint=function(self,v) self.waypoint=v end} end
function CreateACrab(n,m) local a=CreateAHuman(n,m); a.vehicle=true; return a end
function CreateACDropShip(n,m)
    nextId=nextId+1
    return {name=n,ship=true,UniqueID=nextId,MaxPassengers=4,MaxInventoryMass=800,InventorySize=0,cargo={},Pos=Vector(0,0),Health=100,
        SetControllerMode=function(self,mode) self.controller=mode end,
        SetGoldValue=function(self,value) self.goldValue=value end,
        GetTotalValue=function(self) return self.returnValue or 0 end,
        OpenHatch=function(self) self.hatchOpen=true; self.openedWithCargo=#self.cargo; self.cargo={}; self.InventorySize=0 end,
        RemoveInventoryItemAtIndex=function(self,index)
            local item=table.remove(self.cargo,index+1); self.InventorySize=#self.cargo
            if item then assert(item._cargoOwner=='ship'); item._cargoOwner='lua' end
            return item
        end,
        AddInventoryItem=function(self,item)
            assert(not item._borrowed and not item._cargoOwner,'cargo must transfer from its owner')
            item._cargoOwner='ship'; table.insert(self.cargo,item); self.InventorySize=#self.cargo
        end}
end
local function entity(name)
    local item={name=name,numberValues={}}
    function item:SetNumberValue(key,value) self.numberValues[key]=value end
    function item:GetNumberValue(key) return self.numberValues[key] or 0 end
    return item
end
local firearmCreates={}
function CreateHDFirearm(presetOrQualifiedName,module)
    local presetName,moduleName=presetOrQualifiedName,module
    local qualified=module==nil
    if qualified then moduleName,presetName=presetOrQualifiedName:match("^([^/]+)/(.+)$") end
    table.insert(firearmCreates,{name=presetName,module=moduleName,qualified=qualified})
    if presetName=="Broken Firearm" then return nil end
    local values={["Base.rte/Pistol"]=5,["Coalition.rte/Shotgun"]=120,
        ["Mod A.rte/Rifle A"]=400,["Mod C.rte/Rifle B"]=260,["Mod D.rte/Plasma Cannon"]=900,
        ["Mod E.rte/Heavy Rifle"]=500,["Mod F.rte/Portable Vehicle Killer"]=650,
        ["Mod G.rte/Gatling Gun"]=2000,["Mod H.rte/Old Rifle"]=130}
    return {name=presetName,module=moduleName,qualified=qualified,
        GetGoldValue=function() return values[(moduleName or "").."/"..(presetName or "")] or 0 end}
end
function CreateTDExplosive(n,m)
    local item={name=n,module=m,Activate=function(self) self.activated=true end}
    function item:GibThis() self.gibbed=true; MovableMan:AddParticle(self) end
    return item
end
function CreateMOSRotating(n,m)
    nextId=nextId+1
    local item=entity(n); item.module=m; item.entityType='MOSRotating'; item.UniqueID=nextId
    function item:GibThis() self.gibbed=true; self.ToDelete=true end
    return item
end
function CreateMOPixel(n,m) local item=entity(n); item.entityType='MOPixel'; return item end
function CreateMOSParticle(n,m) return entity(n) end
function ToTDExplosive(item) return item end
-- ToActor returns a borrowed view; the original removed cargo remains owned.
function ToActor(item)
    return setmetatable({_borrowed=true},{__index=item,__newindex=function(_,key,value) item[key]=value end})
end
function CreateSoundContainer() return {Play=function(self) self.playCount=(self.playCount or 0)+1 end} end
function CreateTerrainObject(name) return {name=name} end
local function iterator(items)
    local index=0
    return function() index=index+1; return items[index] end
end
local presets={
    {ClassName="HDFirearm",GetModuleAndPresetName=function() return "Mod A.rte/Rifle A" end},
    {ClassName="HDFirearm",GetModuleAndPresetName=function() return "Base.rte/Pistol" end},
    {ClassName="HDFirearm",GetModuleAndPresetName=function() return "Mod B.rte/Broken Firearm" end},
    {ClassName="HDFirearm",GetModuleAndPresetName=function() return "Coalition.rte/Shotgun" end},
    {ClassName="HDFirearm",GetModuleAndPresetName=function() return "Mod C.rte/Rifle B" end},
    {ClassName="HDFirearm",GetModuleAndPresetName=function() return "Mod D.rte/Plasma Cannon" end},
    {ClassName="HDFirearm",GetModuleAndPresetName=function() return "Mod E.rte/Heavy Rifle" end},
    {ClassName="HDFirearm",GetModuleAndPresetName=function() return "Mod F.rte/Portable Vehicle Killer" end},
    {ClassName="HDFirearm",GetModuleAndPresetName=function() return "Mod G.rte/Gatling Gun" end},
    {ClassName="HDFirearm",GetModuleAndPresetName=function() return "Mod H.rte/Old Rifle" end},
    {ClassName="MOSRotating",GetModuleAndPresetName=function() return "Base.rte/Not a firearm" end},
}
PresetMan={Modules=iterator({
    {Presets=iterator({presets[1],presets[2],presets[3],presets[4]})},
    {Presets=iterator({presets[5],presets[6],presets[7],presets[8],presets[9],presets[10],presets[11],presets[1]})},
})}
local actors={}
MovableMan={
    Actors=(function() local i=0; return function() i=i+1; if not actors[i] then i=0; return nil end; return actors[i] end end)(),
    AddActor=function(s,a) assert(not a._borrowed,'AddActor cannot adopt a borrowed cast'); table.insert(actors,a) end,
    AddMO=function(s,a)
        assert(not a._borrowed and a._cargoOwner=='lua','AddMO must adopt the original removed cargo')
        a._cargoOwner='world'; table.insert(actors,a)
    end,
    AddParticle=function(s,p) s.lastParticle=p; s.particleCount=(s.particleCount or 0)+1; s.particles=s.particles or {}; table.insert(s.particles,p) end,
    AddItem=function(s,item) s.items=s.items or {}; table.insert(s.items,item) end,
    IsActor=function(s,a) return a~=nil and not a.deleted end,
    IsParticle=function(s,p) for _,item in ipairs(s.particles or {}) do if item==p then return not p.ToDelete end end; return false end,
}
MovableMan.Particles=(function() local i=0; return function() i=i+1; local items=MovableMan.particles or {}; if not items[i] then i=0; return nil end; return items[i] end end)()
function MovableMan:FindObjectByUniqueID(id)
    for _,item in ipairs(self.particles or {}) do if item.UniqueID==id then return item end end
    for _,item in ipairs(self.items or {}) do if item.UniqueID==id then return item end end
    for _,item in ipairs(actors) do if item.UniqueID==id then return item end end
    return nil
end
function IsAHuman(a) return not a.vehicle and not a.ship end; function IsACrab(a) return a.vehicle==true end
function ToMOSRotating(item) return item end
local sceneObjects={}
SceneMan={SceneWidth=5200, SceneHeight=800, CastMaterialRay=function() return false end, AddSceneObject=function(_,o) table.insert(sceneObjects,o) end, MovePointToGround=function(_,p) return Vector(p.X,600) end}; MusicMan={PlayDynamicSong=function() end}
FrameMan={PlayerScreenWidth=640,IsHudDisabled=function() return false end,SetHudDisabled=function() end}; PrimitiveMan={DrawLinePrimitive=function() end,DrawTextPrimitive=function() end}
TimerMan={DeltaTimeSecs=1}; UInputMan={KeyPressed=function()return false end}; ActivityMan={EndActivity=function() end}
function Frontline:SetPlayerBrain() end; function Frontline:SetViewState() end; function Frontline:SetObservationTarget() end
function Frontline:GetTeamDeathCount(team) return self.deathCounts[team] end
assert(loadfile('Frontline.rte/Frontline.lua'))()
local activity=setmetatable({deathCounts={[0]=0,[1]=0}}, {__index=Frontline})
activity:StartActivity(); activity:StartBattle(); activity.matchTimer.ElapsedSimTimeMS=15000
local loadedFirearms=activity:LoadedFirearmPresetNames()
assert(#loadedFirearms==10 and loadedFirearms[1]=='Base.rte/Pistol'
    and loadedFirearms[10]=='Mod H.rte/Old Rifle',
    'loaded firearm discovery must visit each module preset list, deduplicate qualified names and sort them')
assert(activity.teams[0].counts[6]==3 and activity.teams[1].counts[6]==3, 'both teams must start with three Ronin Bandits selected')
activity:UpdateAI()
assert(activity:UnitCount(1)==3, 'AI first deployment must be exactly three Ronin Bandits')
local aiTeam=activity.teams[1]
assert(activity:MaxSquadSize(1)==3)
aiTeam.counts={0,0,0,0,0,4}
local _,_,aiSizeError=activity:Batch(1)
assert(aiSizeError=='Squad size limit')
local aiDeployed,aiDeployError=activity.commanders[1]:Deploy()
assert(not aiDeployed and aiDeployError=='Squad size limit','AI deployments must obey the unresearched three-unit cap')
aiTeam.counts={0,0,0,0,0,3}
local panelText,panelEntries,tabOrder,supportDescriptionLines={},{},{},{}
activity.UIDrawBoxFill=function() end
activity.UIDrawBox=function() end
activity.UIDrawText=function(_,_,position,label,small)
    panelText[#panelText+1]=label
    panelEntries[#panelEntries+1]={x=position.X,y=position.Y,label=label,small=small}
    if label:find('Shield destroys',1,true) or label:find('projectiles in its bubble.',1,true)
        or label:find('Jammer blocks enemy',1,true) or label:find('strikes, bombs, orbital fire.',1,true) then
        supportDescriptionLines[#supportDescriptionLines+1]={x=position.X,y=position.Y,label=label,small=small}
    end
    if position.Y==57 and ({Squad=true,Research=true,Support=true,Base=true,Battle=true,Setup=true})[label] then
        tabOrder[#tabOrder+1]=label
    end
end
CameraMan={GetOffset=function() return Vector(0,0) end}
UInputMan.GetMouseMovement=function() return Vector(0,0) end
UInputMan.MouseButtonPressed=function() return false end
activity.tab='Support'; activity:DrawPanel()
local supportLabels=table.concat(panelText,' ')
local function smallFontWidthEstimate(label) return #label*5 end
assert(#supportDescriptionLines==4 and supportLabels:find('WEAPON CACHE POD',1,true)
    and supportLabels:find('1000 oz | LOCKED',1,true),
    'personnel column must expose both call-ins, the locked 1000-oz Assault Squad, and Energy Shield/Jammer descriptions')
for _,line in ipairs(supportDescriptionLines) do
    assert(line.small and line.x==315 and line.y>=307 and line.y<=346
        and line.x+smallFontWidthEstimate(line.label)<=465,
        'Support description must remain in-column: '..line.label)
end
print('Support Energy Shield/Jammer description lines fit the column width (x + estimated small-font width <= 465)')
assert(table.concat(tabOrder,',')=='Squad,Research,Support,Base,Battle,Setup','Battle must be the penultimate tab, immediately before Setup')
local researchTextStart=#panelText
activity.tab='Research'; activity.researchPage=3; activity:DrawPanel()
assert(table.concat(panelText,' ',researchTextStart+1):find('Assault Squad',1,true),
    'Support Network research page must include Assault Squad index 30')
activity.tab='Support'; activity.researchPage=1
local panelTextStart=#panelText
activity.tab='Squad'; activity:DrawPanel()
local squadPanelText=table.concat(panelText,' ',panelTextStart+1)
assert(squadPanelText:find('Squad 3/3 (six +1 upgrades to 9)',1,true),'squad panel must show the starting size and six +1 capacity upgrades')
activity.tab='Support'
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
local expectedCosts={[1]=300,[2]=360,[3]=320,[4]=500,[5]=700,[6]=1000,[7]=300,[8]=340,[9]=400,[10]=600,[11]=400,[12]=700,[13]=500,[14]=400,[15]=500,[16]=700,[17]=400,[18]=440,[19]=480,[20]=600,[21]=600,[22]=280,[23]=360,[24]=800,[25]=1000,[26]=520,[27]=1200,[28]=700,[29]=500,[30]=700}
for index,price in pairs(expectedCosts) do
    assert(activity:ResearchCost(0,index)==price, 'research index '..index..' should cost '..price..' oz before outpost discount')
end
for _,kind in ipairs({'strike','medic','cover','mines','bomb','turret','orbital','shield','bubble','mining','weaponPod','assaultSquad'}) do
    local ok,message=activity.commanders[0]:CallIn(kind, 2)
    assert(not ok and message:find('Research',1,true), kind..' must be gated by its research node')
end
assert(not activity.commanders[0]:Research(4), 'Coalition Heavy must require Coalition Light research')
assert(activity.commanders[0]:Research(1)); assert(not activity.commanders[0]:Research(5))
assert(activity.commanders[0]:Research(4) and team.tier==1)
assert(not activity.commanders[0]:Research(6), 'Browncoat must require Dummy / Gatling research')
assert(activity.commanders[0]:Research(5) and team.tier==2)
assert(activity.commanders[0]:Research(6) and team.tier==3)
assert(not activity.commanders[0]:Research(12), 'medic level 2 must require level 1')
assert(activity.commanders[0]:Research(11)); assert(not activity.commanders[0]:Research(13), 'Support Jammer must require Cover'); assert(activity.commanders[0]:Research(14))
assert(activity.commanders[0]:Research(28) and team.levels[28]==1)
assert(activity.commanders[0]:Research(30) and team.levels[30]==1)
assert(activity.commanders[0]:CallIn('weaponPod', 2))
local podDelivery=activity.pendingDrops[#activity.pendingDrops]
local loadedPodPresets={}
for _,name in ipairs(activity:LoadedFirearmPresetNames()) do loadedPodPresets[name]=true end
assert(podDelivery.kind=='weaponPod' and #podDelivery.weaponPresets==3)
local selectedPresets={}
for _,presetName in ipairs(podDelivery.weaponPresets) do
    local module,name=presetName:match("^([^/]+)/(.+)$")
    assert(loadedPodPresets[presetName] and module and name~='Broken Firearm' and not selectedPresets[presetName],
        'pod must keep distinct, qualified loaded firearm preset names until release')
    selectedPresets[presetName]=true
end
podDelivery.timer.ElapsedSimTimeMS=3000; activity:UpdateCallIns()
local pod=MovableMan:FindObjectByUniqueID(podDelivery.podID)
assert(pod and pod.name=='Frontline Weapon Pod' and pod.Team==0 and pod.Vel.Y>0
    and pod:GetNumberValue('WeaponPodOpenDelayMs')==1000,'weapon call-in must spawn a falling physical pod')
assert(loadfile('Frontline.rte/WeaponPod.lua'))()
local freshPod={Vel=Vector(0,5)}
function freshPod:GetNumberValue() return nil end
function freshPod:SetNumberValue(key,value) self.landed=value end
OnCollideWithTerrain(freshPod,0)
assert(freshPod.landed==1 and freshPod.Vel.Y==0,'fresh pods without the landing number must still stop safely')
OnCollideWithTerrain(pod,0)
assert(pod:GetNumberValue('WeaponPodLanded')==1 and pod.Vel.Y==0,'terrain collision must notify the activity of the pod landing')
activity:UpdateCallIns()
assert(podDelivery.landedTimer,'landed pod must enter its opening delay')
podDelivery.landedTimer.ElapsedSimTimeMS=1000
local itemsBefore=#(MovableMan.items or {})
activity:UpdateCallIns()
assert(pod.gibbed and #(MovableMan.items or {})-itemsBefore==3,'opened pod must release exactly three firearms through MovableMan:AddItem')
for index=itemsBefore+1,#MovableMan.items do
    local weapon=MovableMan.items[index]
    assert(weapon.Team==0 and weapon.ToSettle and weapon.Pos.Y==588 and weapon.module
        and weapon.qualified and weapon.name~='Broken Firearm')
end

do
local squadTarget={name='off-post legal target',x=2600,groundY=600,owner=-1}
local function withRandomChoices(choices,callback)
    local previousRandom=math.random
    local choiceIndex=0
    math.random=function(lower,upper)
        choiceIndex=choiceIndex+1
        local choice=choices[choiceIndex]
        assert(choice and choice>=lower and choice<=upper,'random sample must draw within the current Fisher-Yates bounds')
        return choice
    end
    local result={pcall(callback)}
    math.random=previousRandom
    assert(result[1],result[2])
    return unpack(result,2)
end
local fundsBeforeSquad=25000; team.funds=fundsBeforeSquad
local illegalTarget={name='inside enemy base exclusion',x=SceneMan.SceneWidth-180-899,groundY=600,owner=-1}
assert(activity:SupportTargetAllowed(0,SceneMan.SceneWidth-180-901)
    and not activity:SupportTargetAllowed(0,SceneMan.SceneWidth-180-899)
    and activity:SupportTargetAllowed(1,180+901)
    and not activity:SupportTargetAllowed(1,180+899),
    'support exclusion must be symmetric at 900 pixels and retain legitimate distant targets')
local illegalCallin,illegalMessage=activity.commanders[0]:CallIn('assaultSquad',illegalTarget)
assert(not illegalCallin and illegalMessage=='Support restricted near enemy base'
    and team.funds==fundsBeforeSquad and team.assaultSquadTimer.ElapsedSimTimeMS==120000,
    'Assault Squad must reject illegal targets without spending funds or starting cooldown')
assert(activity:PostBonusCount(0,3)==0 and activity:CallinCooldown(0,120000)==120000,
    'Assault Squad base cooldown must be exactly 120,000 ms without call-in post discounts')
assert(withRandomChoices({1,2,3},function()
    return activity.commanders[0]:CallIn('assaultSquad',squadTarget)
end),'research-unlocked Assault Squad must accept any legal target position')
assert(team.funds==fundsBeforeSquad-1000 and team.assaultSquadTimer.ElapsedSimTimeMS==0,
    'one ordered Assault Squad must debit exactly 1000 oz and start its 120-second cooldown')
local assaultDelivery=activity.pendingDrops[#activity.pendingDrops]
assert(assaultDelivery.kind=='assaultSquad' and assaultDelivery.target==squadTarget
    and assaultDelivery.count==3 and assaultDelivery.delay==4000 and #assaultDelivery.squad==3,
    'Assault Squad must queue the standard three-person Coalition Light dropship payload at the requested position')
local eligiblePool=activity:AssaultSquadWeaponPresets()
assert(#eligiblePool==7,'every creatable, positive-value exotic above the stock ceiling must remain eligible')
local eligibleNames={}
for _,name in ipairs(eligiblePool) do eligibleNames[name]=true end
for _,name in ipairs({'Mod A.rte/Rifle A','Mod C.rte/Rifle B','Mod D.rte/Plasma Cannon',
    'Mod E.rte/Heavy Rifle','Mod F.rte/Portable Vehicle Killer','Mod G.rte/Gatling Gun',
    'Mod H.rte/Old Rifle'}) do
    assert(eligibleNames[name],'full eligible exotic pool must contain '..name)
end
local function assertAssaultLoadout(squad)
    local names={}
    for _,actor in ipairs(squad) do
        local weapon=actor.inventory
        local qualifiedName=weapon and (weapon.module.."/"..weapon.name)
        assert(actor.name=='Soldier Light' and actor.module=='Coalition.rte' and actor.Team==0
            and actor.Health==200 and actor.MaxHealth==200
            and weapon and weapon.Team==0 and weapon.qualified and eligibleNames[qualifiedName]
            and weapon:GetGoldValue(0,1,1)>120,
            'each Coalition Light passenger must carry a team-owned, loaded upper-tier firearm at 200 HP')
        names[#names+1]=qualifiedName
    end
    return names
end
local firstNames=assertAssaultLoadout(assaultDelivery.squad)
local function weaponSet(names)
    local result={}
    for _,name in ipairs(names) do
        assert(not result[name],'each squad must sample without replacement')
        result[name]=true
    end
    return result
end
local firstSet=weaponSet(firstNames)
assert(not firstSet['Mod G.rte/Gatling Gun'] and firstSet['Mod A.rte/Rifle A'],
    'random sampling must allow a full eligible squad without favoring the highest-value Gatling')
local passengerIDs={}
for _,actor in ipairs(assaultDelivery.squad) do passengerIDs[actor.UniqueID]=true end
team.assaultSquadTimer.ElapsedSimTimeMS=119999
local coolingDown,cooldownMessage=activity.commanders[0]:CallIn('assaultSquad',squadTarget)
assert(not coolingDown and cooldownMessage=='Call-in cooling down' and team.funds==fundsBeforeSquad-1000,
    'Assault Squad must remain unavailable until its full 120,000 ms cooldown elapses')
team.assaultSquadTimer.ElapsedSimTimeMS=120000
local secondCall,secondMessage=withRandomChoices({7,6,5},function()
    return activity.commanders[0]:CallIn('assaultSquad',squadTarget)
end)
assert(secondCall,secondMessage)
local secondDelivery=activity.pendingDrops[#activity.pendingDrops]
local secondNames=assertAssaultLoadout(secondDelivery.squad)
local secondSet=weaponSet(secondNames)
assert(not (firstSet['Mod A.rte/Rifle A'] and secondSet['Mod A.rte/Rifle A'])
    or not (firstSet['Mod C.rte/Rifle B'] and secondSet['Mod C.rte/Rifle B'])
    or not (firstSet['Mod D.rte/Plasma Cannon'] and secondSet['Mod D.rte/Plasma Cannon']),
    'successive squads must be able to draw different eligible weapons')
assert(secondSet['Mod G.rte/Gatling Gun'],
    'eligible high-value Gatlings remain selectable without being guaranteed in every squad')
assaultDelivery.timer.ElapsedSimTimeMS=4000
activity:UpdateCallIns()
local assaultShip=assaultDelivery.ship
assert(assaultShip and #assaultShip.cargo==3 and assaultShip.cargo[1].name=='Soldier Light',
    'Assault Squad must enter the normal support dropship delivery path with exactly three actors')
assaultDelivery.arrivalTimer.ElapsedSimTimeMS=2000
activity:UpdateCallIns()
local delivered={}
for _,actor in ipairs(actors) do
    if passengerIDs[actor.UniqueID] then delivered[#delivered+1]=actor end
end
assert(#delivered==3 and assaultShip.hatchOpen and assaultShip.openedWithCargo==0,
    'normal dropship arrival must deliver and open with all three squad actors extracted')
for _,actor in ipairs(delivered) do
    assert(actor.Team==0 and actor.module=='Coalition.rte' and actor.Pos.Y==565
        and actor.Health==200 and actor.MaxHealth==200
        and actor.inventory and actor.inventory.module~='Base.rte' and actor.inventory.module~='Coalition.rte',
        'each delivered soldier must retain 200 HP and its exotic firearm after dropship delivery')
end
local savedAssaultPresets,savedLoadedPresets=activity.assaultWeaponPresets,activity.weaponPodPresets
activity.assaultWeaponPresets=nil
activity.weaponPodPresets={'Mod F.rte/Portable Vehicle Killer','Mod A.rte/Rifle A','Mod C.rte/Rifle B'}
local portableNamedPool=activity:AssaultSquadWeaponPresets()
local hasPortableNamed=false
for _,name in ipairs(portableNamedPool or {}) do
    if name=='Mod F.rte/Portable Vehicle Killer' then hasPortableNamed=true end
end
assert(hasPortableNamed,'portable infantry firearms remain eligible when their preset name mentions a vehicle')
activity.assaultWeaponPresets=nil
activity.weaponPodPresets={'Mod A.rte/Rifle A','Mod C.rte/Rifle B','Base.rte/Pistol','Coalition.rte/Shotgun'}
local fallbackExotics,fallbackStock=activity:AssaultSquadWeaponPresets()
assert(#fallbackExotics==2 and #fallbackStock==2,
    'full exotic pool should remain intact, with stock weapons available only for a short pool')
local fallbackSquad,fallbackNames=withRandomChoices({1,2,1},function()
    return activity:CreateAssaultSquadPayload(0)
end)
local fallbackExoticCount=0
for _,name in ipairs(fallbackNames) do
    if name:find('Mod ',1,true) then fallbackExoticCount=fallbackExoticCount+1 end
end
assert(fallbackExoticCount==2 and #fallbackSquad==3,
    'stock weapons should fill only the remaining squad slot when fewer than three exotics qualify')
activity.assaultWeaponPresets=nil
activity.weaponPodPresets={'Base.rte/Pistol','Coalition.rte/Shotgun'}
local missingFirearms,missingFirearmMessage=activity:AssaultSquadWeaponPresets()
assert(not missingFirearms and missingFirearmMessage:find('three loaded firearms',1,true),
    'Assault Squad must reject fewer than three loaded spawnable firearms')
activity.assaultWeaponPresets=savedAssaultPresets
activity.weaponPodPresets=savedLoadedPresets
print('Assault Squad research, legal targeting, random loaded arsenal, 200 HP, cost/cooldown and dropship delivery verified')
end

local ai=activity.teams[1]
local oldFunds,oldAuto,oldTurretLevel,oldBaseArmor,oldTurret=ai.funds,ai.auto,ai.turretLevel,ai.baseArmor,ai.turret
local oldStatsDeployed,oldPersonality=ai.stats.deployed,activity.aiPersonality
local oldPlayerBehavior
if activity.playerBehavior then
    oldPlayerBehavior={}
    for key,value in pairs(activity.playerBehavior) do oldPlayerBehavior[key]=value end
end
local oldAIFields={}
for _,key in ipairs({"autoDeploy","forward","orderPhase","attackTarget","rallyTarget","order","orderTarget",
    "counts","weapons","sidearms","medkits","grenades","armor","offenseChoice","fortifyChoice"}) do
    oldAIFields[key]=ai[key]
end
local oldLevels,oldTimerValues={},{}
for index=1,30 do oldLevels[index]=ai.levels[index]; ai.levels[index]=10 end
ai.levels[13]=2; ai.levels[29]=6; ai.levels[28]=1
local callinTimers={ai.strikeTimer,ai.medicTimer,ai.coverTimer,ai.minesTimer,ai.bombTimer,
    ai.turretTimer,ai.orbitalTimer,ai.shieldTimer,ai.bubbleTimer,ai.weaponPodTimer,ai.assaultSquadTimer}
for index,timer in ipairs(callinTimers) do oldTimerValues[index]=timer.ElapsedSimTimeMS; timer.ElapsedSimTimeMS=0 end
ai.weaponPodTimer.ElapsedSimTimeMS=1000000
ai.auto=false; ai.turretLevel=2; ai.baseArmor=3; ai.turret={Health=100}; ai.funds=5000
local supplyPost=activity.outposts[3]; local oldOwner=supplyPost.owner; supplyPost.owner=1
local existingAIActors={}
for _,actor in ipairs(actors) do if actor.Team==1 then existingAIActors[actor]=true end end
local supplyActor=CreateAHuman('Soldier Light','Coalition.rte'); supplyActor.Team=1
supplyActor.Pos=Vector(supplyPost.x,565); MovableMan:AddActor(supplyActor)
activity.aiPersonality='balanced'
local dropsBeforeAI=#activity.pendingDrops
activity:UpdateAI()
local aiPod
for index=dropsBeforeAI+1,#activity.pendingDrops do
    local order=activity.pendingDrops[index]
    if order.kind=='weaponPod' and order.team==1 then aiPod=order end
end
assert(aiPod and aiPod.target==supplyPost and #aiPod.weaponPresets==3 and aiPod.cost>0
    and ai.funds<=5000-aiPod.cost,
    'AI should pay the configured pod cost and target a three-firearm cache at an occupied friendly post')
for _,actor in ipairs(actors) do
    if actor.Team==1 and not existingAIActors[actor] then actor.deleted=true end
end
supplyActor.deleted=true; supplyPost.owner=oldOwner
for index=1,30 do ai.levels[index]=oldLevels[index] end
for index,timer in ipairs(callinTimers) do timer.ElapsedSimTimeMS=oldTimerValues[index] end
ai.funds=oldFunds; ai.auto=oldAuto; ai.turretLevel=oldTurretLevel; ai.baseArmor=oldBaseArmor
ai.turret=oldTurret; ai.stats.deployed=oldStatsDeployed; activity.aiPersonality=oldPersonality
for key,value in pairs(oldAIFields) do ai[key]=value end
activity.playerBehavior=oldPlayerBehavior
for index=#activity.pendingDrops,1,-1 do
    if activity.pendingDrops[index]==aiPod then table.remove(activity.pendingDrops,index) end
end
print('AI weapon cache pod uses the researched, affordable, off-cooldown call-in at an occupied friendly post')
assert(not activity.commanders[0]:Research(24), 'precision strike must require orbital barrage research')
assert(not activity.commanders[0]:Research(25), 'Carpet Bomb must require precision-strike research')
assert(activity.commanders[0]:Research(21))
assert(activity.commanders[0]:CallIn('orbital', 2))
local barrage=activity.pendingOrbitals[#activity.pendingOrbitals]
barrage.timer.ElapsedSimTimeMS=3000; activity:UpdateCallIns()
assert(barrage.shots==1)
local round
for index=#MovableMan.particles,1,-1 do
    if MovableMan.particles[index].name=='Frontline Orbital Round' then round=MovableMan.particles[index]; break end
end
assert(round and round:GetNumberValue('FragmentCount')==16,'orbital rounds must receive the configured fragment count')
assert(loadfile('Frontline.rte/OrbitalRound.lua'))()
local particleStart=#MovableMan.particles
OnCollideWithTerrain(round,0)
assert(#MovableMan.particles-particleStart==17,'orbital impact must emit one smoke particle and sixteen fragments')
local minX,maxX,minY,maxY=math.huge,-math.huge,math.huge,-math.huge
for index=particleStart+2,#MovableMan.particles do
    local shard=MovableMan.particles[index]
    assert(shard.name=='Frontline Orbital Fragment' and shard.Team==0)
    minX=math.min(minX,shard.Vel.X); maxX=math.max(maxX,shard.Vel.X)
    minY=math.min(minY,shard.Vel.Y); maxY=math.max(maxY,shard.Vel.Y)
end
assert(minX<0 and maxX>0 and minY<0 and maxY>0,'fragments must travel in multiple directions')
local particlesAfterImpact=#MovableMan.particles
OnCollideWithTerrain(round,0)
assert(#MovableMan.particles==particlesAfterImpact,'a round must fragment only once')
local function assertFragmentFallback(value,present)
    local fallback=CreateMOPixel('Frontline Orbital Round','Frontline.rte')
    fallback.Pos=Vector(20,20); fallback.Team=1
    if present then fallback:SetNumberValue('FragmentCount',value) end
    local before=#MovableMan.particles
    OnCollideWithTerrain(fallback,0)
    local count=0
    for index=before+1,#MovableMan.particles do
        if MovableMan.particles[index].name=='Frontline Orbital Fragment' then count=count+1 end
    end
    assert(count==16,'missing, invalid, or zero fragment counts must use the safe fallback')
end
assertFragmentFallback(nil,false)
assertFragmentFallback(0,true)
assertFragmentFallback('invalid',true)
assert(activity.commanders[0]:Research(24))
assert(activity.commanders[0]:Research(25))
assert(activity.commanders[0]:Research(22)); assert(activity.commanders[0]:Research(13))
assert(team.levels[13]==1 and activity:ResearchCost(0,13)==800, 'the second Support Jammer upgrade must retain its 800 oz price')
assert(not activity.commanders[0]:Research(27), 'Energy Shield must require Support Jammer Lv.2')
assert(not activity.commanders[0]:CallIn('bubble', 2), 'Energy Shield must stay unavailable after only one Jammer upgrade')
assert(not activity.commanders[0]:Research(26), 'turret must require minefield research')
assert(activity.commanders[0]:Research(23)); assert(activity.commanders[0]:Research(26))
local actorsBeforeTurret=#actors
assert(activity.commanders[0]:CallIn('turret', 2))
local turret=activity.pendingDrops[#activity.pendingDrops]
assert(turret.count==1, 'turret drops must provide an explicit single-item cargo count')
turret.timer.ElapsedSimTimeMS=4000; activity:UpdateCallIns()
assert(turret.ship and turret.ship.cargo[1].name=='Gatling Turret')
turret.arrivalTimer.ElapsedSimTimeMS=2000; activity:UpdateCallIns()
assert(#actors==actorsBeforeTurret+2 and actors[#actors].name=='Gatling Turret' and actors[#actors].Team==0,
    'turret dropship must deliver its turret without a nil loop limit')
local injured=CreateAHuman('Soldier Light','Coalition.rte'); injured.Team=0; injured.Pos=Vector(target.x,565); injured.Health=50; injured.MaxHealth=100; table.insert(actors,injured)
local actorsBeforeMedic=#actors
assert(activity.commanders[0]:CallIn('medic', 2)); assert(injured.Health==50, 'medic support must deploy a robot, not heal instantly')
local medic=activity.pendingDrops[#activity.pendingDrops]
assert(medic.kind=='medic' and medic.count==1)
medic.timer.ElapsedSimTimeMS=4000; activity:UpdateCallIns()
assert(medic.ship and medic.ship.cargo[1].name=='Medic Drone')
medic.arrivalTimer.ElapsedSimTimeMS=2000; activity:UpdateCallIns()
assert(#actors==actorsBeforeMedic+2 and actors[#actors].name=='Medic Drone' and actors[#actors].Team==0,
    'medic delivery must add the support ship and actor; before='..actorsBeforeMedic..' after='..#actors..' last='..tostring(actors[#actors].name))
assert(medic.ship.openedWithCargo==0, 'medic cargo must be removed before opening the hatch auto-ejects it')
local shieldOK,shieldMessage=activity.commanders[0]:CallIn('shield', 2); assert(shieldOK,shieldMessage); assert(activity.jamFields[#activity.jamFields].duration==60000)
assert(activity.commanders[0]:CallIn('mining', 2)); local mining=activity.pendingDrops[#activity.pendingDrops]; assert(mining.kind=='mining' and mining.miner)
assert(mining.miner.inventory.name=='Light Digger','mining support must carry a real digger')
local medicUpgrade,medicUpgradeError=activity.commanders[0]:Research(12); assert(medicUpgrade,medicUpgradeError)
assert(not activity.commanders[0]:Research(27), 'Energy Shield must require Support Jammer Lv.2')
local shieldUpgrade,shieldUpgradeError=activity.commanders[0]:Research(13); assert(shieldUpgrade,shieldUpgradeError)
assert(team.levels[13]==2)
local savedTurretResearch=team.levels[26]
team.levels[26]=0
assert(not activity.commanders[0]:Research(27),'Energy Shield must still require Turret after Jammer Lv.2 is complete')
team.levels[26]=savedTurretResearch
local bubbleUnlock,bubbleUnlockError=activity.commanders[0]:Research(27); assert(bubbleUnlock,bubbleUnlockError)
assert(activity.commanders[0]:CallIn('bubble', 2))
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
assert(activity.commanders[0]:CallIn('medic', 2)); local upgradedMedic=activity.pendingDrops[#activity.pendingDrops]
assert(upgradedMedic.count==2, 'Medic Drone Lv.2 must deliver two robots')
upgradedMedic.timer.ElapsedSimTimeMS=4000; activity:UpdateCallIns()
assert(upgradedMedic.ship.InventorySize==2)
upgradedMedic.arrivalTimer.ElapsedSimTimeMS=2000; activity:UpdateCallIns()
assert(#actors==actorsBeforeUpgrade+3 and actors[#actors].name=='Medic Drone' and actors[#actors-1].name=='Medic Drone')
team.shieldTimer.ElapsedSimTimeMS=60000; assert(activity.commanders[0]:CallIn('shield', 2)); assert(activity.jamFields[#activity.jamFields].duration==90000)
mining.timer.ElapsedSimTimeMS=4000; activity:UpdateCallIns(); assert(mining.arrivalTimer and mining.ship)
local miner=mining.ship.cargo[1]
assert(miner.name=='Dummy' and miner._cargoOwner=='ship' and mining.miner==nil,
    'the ship owns the miner after loading; the order must not retain a stale reference')
mining.arrivalTimer.ElapsedSimTimeMS=2000; activity:UpdateCallIns()
assert(miner._cargoOwner=='world' and miner.Pos.X==target.x and miner.Pos.Y==592 and miner.PinStrength==0)
assert(activity.commanders[0]:CallIn('bomb', 2)); local bomb=activity.pendingDrops[#activity.pendingDrops]
assert(bomb.startX==target.x-192 and bomb.flightDistance==360)
local bombParticleCount=MovableMan.particleCount
bomb.timer.ElapsedSimTimeMS=799; activity:UpdateCallIns()
assert(MovableMan.particleCount==bombParticleCount and bomb.bombsDropped==0,
    'carpet bomb must not release a physical payload before its first interval')
bomb.timer.ElapsedSimTimeMS=800; activity:UpdateCallIns()
local dropped=MovableMan.lastParticle
assert(MovableMan.particleCount==bombParticleCount+1 and bomb.bombsDropped==1,
    'first due interval must release exactly one physical bomb')
assert(dropped.name=='Frontline Carpet Bomb' and dropped.module=='Frontline.rte'
    and dropped.entityType=='MOSRotating' and dropped.Team==0 and dropped.Pos.X==target.x-96
    and dropped.Pos.Y==bomb.ship.Pos.Y+(bomb.ship.Radius or 50)+12
    and dropped.Vel.X==0 and dropped.Vel.Y==20,
    'first visible Standard Bomb shell must preserve its team, release position, and velocity')
activity:UpdateCallIns()
assert(MovableMan.particleCount==bombParticleCount+1 and bomb.bombsDropped==1,
    'rechecking the same due time must not duplicate the first bomb')
bomb.timer.ElapsedSimTimeMS=1600; activity:UpdateCallIns()
local secondBomb=MovableMan.lastParticle
assert(MovableMan.particleCount==bombParticleCount+2 and bomb.bombsDropped==2
    and secondBomb.Pos.X==target.x
    and secondBomb.Pos.Y==bomb.ship.Pos.Y+(bomb.ship.Radius or 50)+12 and secondBomb.Team==0
    and secondBomb.Vel.X==0 and secondBomb.Vel.Y==20,
    'second visible bomb shell must release directly over the target')
bomb.timer.ElapsedSimTimeMS=2400; activity:UpdateCallIns()
local thirdBomb=MovableMan.lastParticle
assert(MovableMan.particleCount==bombParticleCount+3 and bomb.bombsDropped==3
    and thirdBomb.Pos.X==target.x+96
    and thirdBomb.Pos.Y==bomb.ship.Pos.Y+(bomb.ship.Radius or 50)+12 and thirdBomb.Team==0
    and thirdBomb.Vel.X==0 and thirdBomb.Vel.Y==20,
    'third visible bomb shell must continue across the target')
activity:UpdateCallIns()
assert(MovableMan.particleCount==bombParticleCount+3,
    'completed bomb run must not release extra visible shells')
assert(loadfile('Frontline.rte/BombRunBomb.lua'))()
local impactWrapper=CreateMOSRotating('Frontline Carpet Bomb','Frontline.rte')
impactWrapper.Pos=Vector(target.x,600); impactWrapper.Team=0
local impactParticlesBefore=#MovableMan.particles
OnCollideWithTerrain(impactWrapper,0)
local heavyBomb=MovableMan.lastParticle
assert(impactWrapper.ToDelete and #MovableMan.particles-impactParticlesBefore==2)
assert(heavyBomb.name=='Frontline Heavy Bomb' and heavyBomb.module=='Frontline.rte'
    and heavyBomb.Team==0 and heavyBomb.activated,
    'visible shell impact must spawn and activate the heavy explosive payload')
local impactParticlesAfter=#MovableMan.particles
OnCollideWithMO(impactWrapper,nil,nil)
assert(#MovableMan.particles==impactParticlesAfter,'a carpet bomb shell must activate its payload only once')
for _,field in ipairs(activity.jamFields) do field.timer.ElapsedSimTimeMS=field.duration end
activity:UpdateCallIns()
local enemyTeam=activity.teams[1]; enemyTeam.levels[25]=1; enemyTeam.funds=5000; enemyTeam.bombTimer.ElapsedSimTimeMS=55000
assert(activity.commanders[1]:CallIn('bomb', 2)); local enemyBomb=activity.pendingDrops[#activity.pendingDrops]
assert(enemyBomb.startX==target.x+192 and enemyBomb.direction==-1)
local enemyParticleCount=MovableMan.particleCount
enemyBomb.timer.ElapsedSimTimeMS=800; activity:UpdateCallIns()
local enemyReleased=MovableMan.lastParticle
assert(MovableMan.particleCount==enemyParticleCount+1 and enemyBomb.bombsDropped==1
    and enemyReleased.name=='Frontline Carpet Bomb' and enemyReleased.entityType=='MOSRotating'
    and enemyReleased.Pos.X==target.x+96 and enemyReleased.Team==1
    and enemyReleased.Vel.X==0 and enemyReleased.Vel.Y==20,
    'enemy bomb run must release its visible shell in the mirrored direction with the correct team and velocity')
assert(not enemyReleased.ToDelete and not enemyReleased.gibbed)
print('Support research gates, physical deliveries, orbital fragments, and bidirectional carpet bombing passed')
local treeText,graphText,graphLines,nodes={},{},{},{}
local lastBox
activity.UIDrawBoxFill=function(_,_,a,b) lastBox={x=a.X,y=a.Y,r=b.X,b=b.Y} end
activity.UIDrawBox=function() end
PrimitiveMan.DrawLinePrimitive=function(_,from,to)
    if activity.tab=='Research' and activity.researchPage==4 then
        graphLines[#graphLines+1]={from=from,to=to}
    end
end
activity.UIDrawText=function(_,_,position,label,small)
    treeText[#treeText+1]=label
    if activity.tab=='Research' and activity.researchPage==4 then
        graphText[#graphText+1]={x=position.X,y=position.Y,r=position.X+#label*(small and 5 or 7),b=position.Y+(small and 6 or 10),label=label}
        for _,name in ipairs({'Cover','Support Jammer','Mines','Turret','Energy Shield'}) do
            if label:find(name..'  ',1,true)==1 then nodes[name]=lastBox end
        end
    end
end
CameraMan={GetOffset=function() return Vector(0,0) end}
UInputMan.GetMouseMovement=function() return Vector(0,0) end
UInputMan.MouseButtonPressed=function() return false end
local savedJammerLevel,savedEnergyShieldLevel=team.levels[13],team.levels[27]
team.levels[13],team.levels[27]=1,0
activity.tab='Squad'; activity:DrawPanel()
for page=1,4 do activity.researchPage=page; activity.tab='Research'; activity:DrawPanel() end
local treeLabels=table.concat(treeText,' ')
local treeBarrage=treeLabels:find('Orbital Gatling Barrage',1,true)
local treePrecision=treeLabels:find('Orbital Precision Strike',1,true)
local treeCarpetBomb=treeLabels:find('Carpet Bomb',1,true)
local treeEnergyShield=treeLabels:find('Energy Shield',1,true)
local treeCover=treeLabels:find('Cover',1,true)
local treeJammer=treeLabels:find('Support Jammer',1,true)
local treeSquadSize=treeLabels:find('Squad Size +1',1,true)
assert(treeBarrage and treePrecision and treeCarpetBomb and treeSquadSize
    and treeBarrage<treePrecision and treePrecision<treeCarpetBomb,
    'tech tree must show squad-size research and the requested offensive progression')
assert(treeCover and treeJammer and treeCover<treeJammer and treeEnergyShield and treeEnergyShield>treeJammer,
    'research order mismatch: Cover='..tostring(treeCover)..' Jammer='..tostring(treeJammer)..' Energy Shield='..tostring(treeEnergyShield))
assert(#graphLines>0 and nodes.Cover and nodes['Support Jammer'] and nodes.Mines and nodes.Turret and nodes['Energy Shield'])
local function crosses(rect,line)
    local a,b=line.from,line.to
    if a.X==b.X then
        return a.X>rect.x and a.X<rect.r and math.max(a.Y,b.Y)>rect.y and math.min(a.Y,b.Y)<rect.b
    end
    assert(a.Y==b.Y,'dependency segments must be orthogonal')
    return a.Y>rect.y and a.Y<rect.b and math.max(a.X,b.X)>rect.x and math.min(a.X,b.X)<rect.r
end
for _,line in ipairs(graphLines) do
    assert(line.from.X>=8 and line.to.X<=465 and line.from.Y>=8 and line.to.Y<=430)
    for name,rect in pairs(nodes) do assert(not crosses(rect,line),'connector crosses '..name) end
    for _,rect in ipairs(graphText) do assert(not crosses(rect,line),'connector crosses label '..rect.label) end
end
-- Trace each drawn polyline from its source border; stop on the first node.
-- This verifies direct graph edges, including the fork and both shield inputs.
local function onBorder(rect,p)
    return p.X>=rect.x-1 and p.X<=rect.r+1 and p.Y>=rect.y-1 and p.Y<=rect.b+1
        and (math.abs(p.X-rect.x)<=1 or math.abs(p.X-rect.r)<=1
            or math.abs(p.Y-rect.y)<=1 or math.abs(p.Y-rect.b)<=1)
end
local actual={}
for name,rect in pairs(nodes) do
    local queue,visited={},{}
    for _,line in ipairs(graphLines) do if onBorder(rect,line.from) then queue[#queue+1]=line.from end end
    while #queue>0 do
        local p=table.remove(queue)
        local key=p.X..','..p.Y
        if not visited[key] then
            visited[key]=true
            for _,line in ipairs(graphLines) do
                if line.from.X==p.X and line.from.Y==p.Y then
                    local destination
                    for other,box in pairs(nodes) do
                        if other~=name and onBorder(box,line.to) then destination=other; break end
                    end
                    if destination then actual[name..'>'..destination]=true
                    else queue[#queue+1]=line.to end
                end
            end
        end
    end
end
local expected={['Cover>Support Jammer']=true,['Cover>Mines']=true,['Mines>Turret']=true,
    ['Support Jammer>Energy Shield']=true,['Turret>Energy Shield']=true}
for edge in pairs(expected) do assert(actual[edge],'missing dependency edge '..edge) end
for edge in pairs(actual) do assert(expected[edge],'unexpected dependency edge '..edge) end
assert(treeLabels:find('Requires: Turret',1,true) and treeLabels:find('and Support Jammer Lv.2',1,true),
    'both Energy Shield requirements must remain visible')
team.levels[13],team.levels[27]=savedJammerLevel,savedEnergyShieldLevel
local buttonDown
UInputMan.MouseButtonPressed=function(_,which) return buttonDown==which end
local function clickPanel(x,y,which)
    activity.cursorX=x; activity.cursorY=y; buttonDown=which; activity:DrawPanel()
end
activity.tab='Research'; activity.researchPage=1
clickPanel(400,85,MouseButtons.MOUSE_RIGHT)
assert(activity.researchPage==4, 'right-clicking the research page control must wrap backward')
clickPanel(400,85,MouseButtons.MOUSE_LEFT)
assert(activity.researchPage==1, 'left-clicking the research page control must wrap forward')
activity.tab='Squad'
local squad=activity.teams[0]
squad.orderTarget=1
clickPanel(400,165,MouseButtons.MOUSE_RIGHT)
assert(squad.orderTarget==1, 'right-clicking NEXT must not reverse its indicated direction')
clickPanel(400,165,MouseButtons.MOUSE_LEFT)
assert(squad.orderTarget==2, 'left-clicking NEXT must select the next target')
clickPanel(320,158,MouseButtons.MOUSE_LEFT)
assert(squad.orderTarget==1, 'left-clicking PREV must select the previous target')
clickPanel(320,158,MouseButtons.MOUSE_RIGHT)
assert(squad.orderTarget==1, 'right-clicking PREV must not reverse its indicated direction')
squad.counts[6]=0
clickPanel(280,100,MouseButtons.MOUSE_RIGHT)
assert(squad.counts[6]==0, 'right-clicking + must not decrease the count')
clickPanel(280,100,MouseButtons.MOUSE_LEFT)
assert(squad.counts[6]==1, 'left-clicking + must increment the count')
clickPanel(235,100,MouseButtons.MOUSE_RIGHT)
assert(squad.counts[6]==1, 'right-clicking - must not increment the count')
clickPanel(235,100,MouseButtons.MOUSE_LEFT)
assert(squad.counts[6]==0, 'left-clicking - must decrement the count')
activity.setupStep=1
activity.settings.startFunds=450
activity.cursorX=100; activity.cursorY=95; buttonDown=MouseButtons.MOUSE_LEFT; activity:DrawWizard()
assert(activity.settings.startFunds==750,'wizard left-click must advance the funds value')
buttonDown=MouseButtons.MOUSE_RIGHT; activity:DrawWizard()
assert(activity.settings.startFunds==450,'wizard right-click must reverse the funds value')
local wizardCycles={{y=124,key='income',left=8,right=5},{y=153,key='unitCap',left=8,right=50},
    {y=182,key='outpostBonuses',left=false,right=true},{y=211,key='callins',left=false,right=true}}
for _,cycle in ipairs(wizardCycles) do
    activity.cursorY=cycle.y; buttonDown=MouseButtons.MOUSE_LEFT; activity:DrawWizard()
    assert(activity.settings[cycle.key]==cycle.left,'wizard left-click must advance '..cycle.key)
    buttonDown=MouseButtons.MOUSE_RIGHT; activity:DrawWizard()
    assert(activity.settings[cycle.key]==cycle.right,'wizard right-click must reverse '..cycle.key)
end
activity.battleStarted=false; activity.tab='Setup'
activity.teams[0].funds=5000; activity.teams[1].funds=5000
local panelCycles={{y=116,key='startFunds',left=750,right=450},{y=143,key='income',left=8,right=5},
    {y=170,key='unitCap',left=8,right=50},{y=197,key='outpostBonuses',left=false,right=true},
    {y=224,key='callins',left=false,right=true}}
for _,cycle in ipairs(panelCycles) do
    clickPanel(100,cycle.y,MouseButtons.MOUSE_LEFT)
    assert(activity.settings[cycle.key]==cycle.left,'panel left-click failed for '..cycle.key..': actual='..tostring(activity.settings[cycle.key])..' battleStarted='..tostring(activity.battleStarted))
    clickPanel(100,cycle.y,MouseButtons.MOUSE_RIGHT)
    assert(activity.settings[cycle.key]==cycle.right,'panel right-click must reverse '..cycle.key)
end
activity.battleStarted=true; activity.tab='Squad'
local squad=activity.teams[0]
squad.forward=1
clickPanel(320,125,MouseButtons.MOUSE_LEFT); assert(squad.forward==2)
clickPanel(320,125,MouseButtons.MOUSE_RIGHT); assert(squad.forward==1)
activity.rosterPage=1
clickPanel(320,245,MouseButtons.MOUSE_RIGHT); assert(activity.rosterPage==2)
clickPanel(320,245,MouseButtons.MOUSE_LEFT); assert(activity.rosterPage==1)
squad.weapons[6]=1
clickPanel(20,111,MouseButtons.MOUSE_LEFT); assert(squad.weapons[6]==7)
clickPanel(20,111,MouseButtons.MOUSE_RIGHT); assert(squad.weapons[6]==1)
local savedSidearm,savedSidearmUnlock,savedRpgUnlock=squad.sidearms[6],squad.levels[19],squad.levels[10]
squad.sidearms[6]=0; squad.levels[19]=1; squad.levels[10]=1
clickPanel(130,111,MouseButtons.MOUSE_LEFT); assert(squad.sidearms[6]==1)
clickPanel(130,111,MouseButtons.MOUSE_LEFT); assert(squad.sidearms[6]==2)
clickPanel(130,111,MouseButtons.MOUSE_RIGHT); assert(squad.sidearms[6]==1)
clickPanel(130,111,MouseButtons.MOUSE_RIGHT); assert(squad.sidearms[6]==0)
squad.sidearms[6]=savedSidearm; squad.levels[19]=savedSidearmUnlock; squad.levels[10]=savedRpgUnlock
local equipmentUnlocks={medkits={17,179},grenades={18,217},armor={20,255}}
for key,equipment in pairs(equipmentUnlocks) do
    local index=equipment[1]; local savedLevel=squad.levels[index]
    squad.levels[index]=1; squad[key][6]=false
    clickPanel(equipment[2]+5,111,MouseButtons.MOUSE_LEFT); assert(squad[key][6])
    clickPanel(equipment[2]+5,111,MouseButtons.MOUSE_RIGHT); assert(not squad[key][6])
    squad.levels[index]=savedLevel
end
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
activity.aiPersonality="defensive"
ai.funds=0
ai.orderPhase=nil; ai.attackTarget=nil; ai.rallyTarget=nil
local staged=0
for _,actor in ipairs(actors) do
    if actor.Team==1 and actor.name=="Bandit" and activity:IsFieldUnit(actor) then
        actor.Pos=Vector(rally.x,rally.groundY)
        staged=staged+1
    end
end
assert(staged==3, 'AI begins with its three starting Ronin Bandits; staged='..staged)
activity:UpdateAI()
assert(ai.orderPhase=='assembling' and ai.order=='Defend' and ai.orderTarget==1,
    'AI should hold a captured outpost and assemble before attacking')
for i=1,3 do
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
-- Only successful player deployments count toward the AI's adaptive response threshold.
activity:UpdateAI()
local player=activity.teams[0]
local savedPlayerCounts,savedPlayerFunds,savedPlayerTimer={},player.funds,player.timer.ElapsedSimTimeMS
local savedPlayerStats,savedPlayerCooldown=player.stats.deployed,player.lastDeployCooldown
local savedPlayerForward=player.forward
for index,count in ipairs(player.counts) do savedPlayerCounts[index]=count end
local savedBehaviorDeployments=activity.playerBehavior.deployments
activity:UpdateAI()
assert(activity.playerBehavior.deployments==savedBehaviorDeployments,
    'an AI decision without a player deployment must not increment the player event counter')
player.forward=0
player.counts={0,0,0,0,0,0}
player.timer.ElapsedSimTimeMS=activity:DeployCooldown(0)
local failedDeploy=activity.commanders[0]:Deploy()
assert(not failedDeploy and activity.playerBehavior.deployments==savedBehaviorDeployments,
    'a rejected player deployment must not count as an adaptive event')
for index=1,6 do
    player.counts={0,0,0,0,0,1}
    player.funds=10000
    player.timer.ElapsedSimTimeMS=activity:DeployCooldown(0)
    local deployed,deployError=activity.commanders[0]:Deploy()
    assert(deployed, 'real player deployment '..index..' must succeed: '..tostring(deployError))
    if index==1 then
        assert(activity.playerBehavior.deployments==savedBehaviorDeployments+1,
            'one successful player deployment must increment the adaptive event counter once')
    end
end
assert(activity.playerBehavior.deployments==savedBehaviorDeployments+6
    and activity.playerBehavior.deployments>5,
    'six successful deployments must cross the AI player-deployment response threshold')
player.counts=savedPlayerCounts; player.funds=savedPlayerFunds; player.timer.ElapsedSimTimeMS=savedPlayerTimer
player.stats.deployed=savedPlayerStats; player.lastDeployCooldown=savedPlayerCooldown; player.forward=savedPlayerForward


local savedUnitCap=activity.settings.unitCap
activity.settings.unitCap=50
-- A near-but-unaffordable optional research must not block a feasible deployment.
for index=1,28 do ai.levels[index]=10 end
ai.levels[28]=0
ai.funds=activity:ResearchCost(1,28)+239
ai.baseArmor=99; ai.turret={}
ai.timer.ElapsedSimTimeMS=100000
activity.settings.callins=false
local deploymentsBeforeBudgetChoice=ai.stats.deployed
activity:UpdateAI()
assert(ai.levels[28]==0 and ai.stats.deployed>deploymentsBeforeBudgetChoice,
    'AI should leave unaffordable optional research untouched and use its available budget for a legal deployment')
local deploymentsAfterBudgetChoice=ai.stats.deployed
activity:UpdateAI()
assert(ai.stats.deployed==deploymentsAfterBudgetChoice,
    'AI must respect the deployment cooldown after making a feasible purchase')
assert(ai.forward>0 and activity.outposts[ai.forward].owner==1,
    'AI forward choice: index='..tostring(ai.forward)..' funds='..ai.funds..' owner='..tostring(ai.forward>0 and activity.outposts[ai.forward].owner))
activity.aiTimer.ElapsedSimTimeMS=0
activity.panel=false
activity.DrawOutpost=function() end
activity.DrawHUD=function() end
activity:UpdateActivity()
assert(ai.stats.deployed==deploymentsAfterBudgetChoice,
    'the regular activity update must not bypass the AI deployment cooldown')
ai.funds=750; ai.levels[28]=1
ai.timer.ElapsedSimTimeMS=100000
activity:UpdateAI()
assert(ai.stats.deployed>deploymentsAfterBudgetChoice and (ai.forward==0 or activity.outposts[ai.forward].owner==1),
    'AI should deploy from an affordable legal destination after the cooldown expires')
activity.settings.unitCap=savedUnitCap
print('AI rally, coordinated advance, retargeting, budget-feasible deployment, cooldowns, and forward deployment passed')
print('Research pricing/progression, reversible UI controls, tech tree, and support panels passed')

-- Lost and jammed mining ships must not leave a borrowed passenger reference.
do
    local function miningOrder()
        actors={}
        local a=setmetatable({deathCounts={[0]=0,[1]=0}},{__index=Frontline})
        a:StartActivity(); a:StartBattle(); a.matchTimer.ElapsedSimTimeMS=15000
        a.teams[0].funds=1000; a.teams[0].levels[14]=1
        assert(a.commanders[0]:CallIn('mining',2))
        local drop=a.pendingDrops[1]
        drop.timer.ElapsedSimTimeMS=4000; a:UpdateCallIns()
        assert(drop.miner==nil and drop.ship.cargo[1]._cargoOwner=='ship')
        return a,drop
    end
    local lost,drop=miningOrder()
    drop.ship.deleted=true
    lost:UpdateCallIns()
    assert(#lost.pendingDrops==0,'destroyed ship must discard its order without accessing freed cargo')

    local jammed
    jammed,drop=miningOrder()
    local cargo=drop.ship.cargo[1]
    local before=jammed.teams[0].funds
    jammed.ShieldBlocks=function() return true end
    jammed:UpdateCallIns()
    assert(#jammed.pendingDrops==0 and drop.ship.InventorySize==0
        and cargo._cargoOwner=='lua' and cargo.ToDelete and jammed.teams[0].funds>before,
        'interception removes ship-owned cargo and refunds the order')

    actors={}
    local missing=setmetatable({deathCounts={[0]=0,[1]=0}},{__index=Frontline})
    missing:StartActivity(); missing:StartBattle(); missing.matchTimer.ElapsedSimTimeMS=15000
    missing.teams[0].funds=1000; missing.teams[0].levels[14]=1
    local firearm=CreateHDFirearm
    CreateHDFirearm=function(name,mod) if name=='Light Digger' then return nil end; return firearm(name,mod) end
    local ok=missing.commanders[0]:CallIn('mining',2)
    CreateHDFirearm=firearm
    assert(not ok and missing.teams[0].funds==1000 and #missing.pendingDrops==0,
        'missing miner equipment must reject the order without charging')
end
print('Mining, medic and turret cargo transfers preserve engine ownership')

-- Cover and mines research affects actual drops for both teams. Existing
-- prerequisite chains still unlock at level one, not at the new maximum.
for teamId=0,1 do
    actors={}
    local a=setmetatable({deathCounts={[0]=0,[1]=0}},{__index=Frontline})
    a:StartActivity(); a:StartBattle(); a.matchTimer.ElapsedSimTimeMS=15000
    local team=a.teams[teamId]
    team.funds=20000
    local commander=a.commanders[teamId]
    assert(not commander:Research(23) and not commander:Research(26),'minefield and turret need their level-one prerequisites')
    assert(not commander:CallIn('cover',2) and not commander:CallIn('mines',2))
    for level=1,3 do
        for _,spec in ipairs({
            {index=22,kind='cover',price=280*level,cost=140,timer=team.coverTimer,preset='Frontline Cover Pod'},
            {index=23,kind='mines',price=360*level,cost=180,timer=team.minesTimer,preset='Anti Personnel Mine Active'},
        }) do
            local before=team.funds
            assert(a:ResearchCost(teamId,spec.index)==spec.price)
            assert(commander:Research(spec.index) and team.funds==before-spec.price)
            if level==1 and spec.kind=='mines' then
                assert(commander:Research(26),'turret remains unlocked by Mines Lv.1')
            end
            spec.timer.ElapsedSimTimeMS=100000
            before=team.funds
            assert(commander:CallIn(spec.kind,2) and team.funds==before-spec.cost)
            local order=a.pendingDrops[#a.pendingDrops]
            assert(not commander:CallIn(spec.kind,2) and team.funds==before-spec.cost,
                'upgraded call-ins still enforce the normal cost and cooldown')
            order.timer.ElapsedSimTimeMS=4000; a:UpdateCallIns()
            assert(order.ship.InventorySize==level+2,'dropship cargo must match researched level')
            for _,item in ipairs(order.ship.cargo) do
                assert(item.name==spec.preset and item.Team==teamId,'every loaded payload has the correct type and team')
            end
            local oldCount=MovableMan.particleCount or 0
            order.arrivalTimer.ElapsedSimTimeMS=2000; a:UpdateCallIns()
            assert(MovableMan.particleCount==oldCount+level+2 and order.ship.openedWithCargo==0,
                'every upgraded payload must actually leave the ship')
            for i=oldCount+1,MovableMan.particleCount do
                local item=MovableMan.particles[i]
                assert(item.name==spec.preset and item.Team==teamId,'released payload must preserve its type and team')
            end
        end
    end
    local before=team.funds
    assert(not commander:Research(22) and not commander:Research(23) and team.funds==before,
        'both research tracks stop at level three without charging')
    for _,spec in ipairs({{kind='cover',timer=team.coverTimer},{kind='mines',timer=team.minesTimer}}) do
        spec.timer.ElapsedSimTimeMS=100000
        local beforeFunds=team.funds
        assert(commander:CallIn(spec.kind,2))
        local order=a.pendingDrops[#a.pendingDrops]
        local particles=MovableMan.particleCount or 0
        a.ShieldBlocks=function() return true end
        order.timer.ElapsedSimTimeMS=4000; a:UpdateCallIns()
        a.ShieldBlocks=nil
        assert(#a.pendingDrops==0 and team.funds==beforeFunds and (MovableMan.particleCount or 0)==particles,
            'jammers must intercept and refund upgraded payloads for either team')
    end
    if teamId==0 then
        local labels={}
        a.UIDrawBoxFill=function() end; a.UIDrawBox=function() end
        a.UIDrawText=function(_,_,_,label) labels[#labels+1]=label end
        a.tab='Support'; a:DrawPanel()
        local support=table.concat(labels,' ')
        assert(support:find('140 oz | L3:5',1,true) and support:find('180 oz | L3:5',1,true),
            'support panel must show actual levels and payload counts')
        labels={}; a.tab='Research'; a.researchPage=4; a:DrawPanel()
        local research=table.concat(labels,' ')
        assert(research:find('Cover  3/3  MAX',1,true) and research:find('Mines  3/3  MAX',1,true)
            and research:find('Lv1/2/3: Cover 3/4/5 | Mines 3/4/5',1,true),
            'research panel must show max status and each level’s payload')
    end
end
print('Both teams research and deliver cover and mines at 3/4/5 payloads')
