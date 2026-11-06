-- Capture production UI primitives and check visible text/control geometry.
-- ASCII glyph advances and ink vertical bounds were extracted from the stock
-- Base.rte/GUIs/Skins/Font{Small,Large}.png with GUIFont::Load's red-separator
-- algorithm (zero kerning). Bounds are conservative rectangles, not pixels;
-- another engine skin or non-ASCII text can have different metrics.
local fonts={
 small={width={2,2,4,6,4,4,5,2,3,3,4,4,2,4,2,4,4,3,4,4,4,4,4,4,4,4,2,2,4,4,4,4,8,4,4,4,4,4,4,4,4,2,4,4,4,6,5,4,4,4,4,4,4,4,4,6,4,4,4,3,4,3,4,4,2,4,4,4,4,4,4,4,4,2,3,4,2,6,4,4,4,4,4,4,4,4,4,6,4,4,4,4,2,4,4},
 top={-1,2,2,2,1,2,2,2,1,1,2,3,6,4,6,2,2,2,2,2,2,2,2,2,2,2,3,3,2,3,2,2,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,2,1,1,7,2,3,2,3,2,3,2,3,2,2,2,2,2,3,3,3,3,3,3,3,2,3,3,3,3,3,3,1,1,1,4},
 bottom={-1,8,5,8,9,8,8,5,9,9,6,7,9,6,8,8,8,8,8,8,8,8,8,8,8,8,7,8,8,7,8,8,9,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,8,8,8,8,8,8,8,8,8,9,8,9,4,9,5,8,8,8,8,8,8,10,8,8,10,8,8,8,8,8,10,10,8,8,8,8,8,8,8,10,8,9,9,9,6}},
 large={width={3,3,6,6,6,6,5,3,4,4,4,6,3,7,3,4,6,4,6,6,6,6,6,6,6,6,3,3,5,6,5,6,9,6,6,6,6,6,6,6,6,3,6,6,6,8,6,6,6,6,6,6,5,6,6,8,6,6,6,4,4,4,6,6,3,6,6,6,6,6,5,6,6,3,4,6,3,8,6,6,6,6,6,6,5,6,6,8,6,6,6,5,3,5,6},
 top={-1,4,4,4,4,4,4,4,3,3,4,5,9,7,9,4,4,4,4,4,4,4,4,4,4,4,5,5,4,6,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,4,3,3,10,5,7,4,7,4,7,4,7,4,5,5,4,4,7,7,7,7,7,7,7,4,7,7,7,7,7,7,3,3,3,7},
 bottom={-1,12,8,12,12,12,12,8,13,13,9,11,13,9,12,12,12,12,12,12,12,12,12,12,12,12,11,12,12,10,12,12,13,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,13,12,12,12,12,12,12,12,12,12,13,12,13,7,12,9,12,12,12,12,12,12,15,12,12,15,12,12,12,12,12,15,15,12,12,12,12,12,12,12,15,12,13,13,13,10}}
}
local function textRect(x,y,s,small)
 local f=small and fonts.small or fonts.large
 local width,top,bottom=0,math.huge,-math.huge
 for i=1,#s do
  local index=s:byte(i)-31
  assert(f.width[index], 'unsupported non-ASCII UI text')
  width=width+f.width[index]
  if f.top[index]>=0 then top=math.min(top,f.top[index]); bottom=math.max(bottom,f.bottom[index]) end
 end
 return {x=x,y=y+(top==math.huge and 0 or top),r=x+width,b=y+(bottom==-math.huge and 0 or bottom),label=s,kind='text'}
end
local function intersect(a,b) return a.x<b.r and b.x<a.r and a.y<b.b and b.y<a.b end
local function contains(a,b) return b.x>=a.x and b.y>=a.y and b.r<=a.r and b.b<=a.b end
local function describe(a) return (a.kind=='text' and ('text '..string.format('%q',a.label)) or a.kind)..(' [%d,%d-%d,%d]'):format(a.x,a.y,a.r,a.b) end
local function inspect(panel,screen,items)
 local errors={}
 if not contains(screen,panel) then errors[#errors+1]='panel outside viewport' end
 for _,item in ipairs(items) do
  if not contains(screen,item) then errors[#errors+1]=describe(item)..' outside viewport' end
  if not contains(panel,item) then errors[#errors+1]=describe(item)..' outside panel' end
  if item.owner and not contains(item.owner,item) then errors[#errors+1]=describe(item)..' overflows its button '..describe(item.owner) end
 end
 for i=1,#items do for j=i+1,#items do
  local a,b=items[i],items[j]
  if a~=b.owner and b~=a.owner and intersect(a,b) then errors[#errors+1]=describe(a)..' overlaps '..describe(b) end
 end end
 return errors
end
-- Exercise the detector itself, including intentionally nested button labels.
do
 local panel={x=0,y=0,r=100,b=100}; local box={kind='button',x=5,y=5,r=30,b=20}
 local inside={kind='text',label='OK',x=8,y=8,r=20,b=16,owner=box}
 assert(#inspect(panel,panel,{box,inside})==0,'button and its own label must be permitted')
 assert(#inspect(panel,panel,{{kind='text',label='outside',x=95,y=5,r=105,b=10}})>0,'overflow detector')
 assert(#inspect(panel,panel,{{kind='button',x=1,y=1,r=15,b=15},{kind='button',x=10,y=10,r=25,b=25}})>0,'overlap detector')
 assert(#inspect(panel,panel,{{kind='text',label='a',x=1,y=1,r=15,b=15},{kind='text',label='b',x=10,y=10,r=25,b=25}})>0,'text overlap detector')
 assert(#inspect({x=0,y=0,r=101,b=100},panel,{})>0,'panel viewport overflow detector')
 local overflow={kind='text',label='wide',x=8,y=8,r=35,b=16,owner=box}
 assert(#inspect(panel,panel,{box,overflow})>0,'button label overflow detector')
end

-- Minimal engine doubles follow the existing test_ai.lua harness. Only the
-- actual UI and activity code are loaded; draw calls below capture its output.
Frontline={}; Actor={AIMODE_SENTRY=1,AIMODE_BRAINHUNT=2,AIMODE_GOTO=3}; Activity={OBSERVE=1,OVER=2,NOTEAM=-1}
Key={TAB=1}; MouseButtons={MOUSE_LEFT=1,MOUSE_RIGHT=2}; rte={goldID=2}
function Timer() return {ElapsedSimTimeMS=0,IsPastSimMS=function(s,n) return s.ElapsedSimTimeMS>=n end,Reset=function(s) s.ElapsedSimTimeMS=0 end} end
function Vector(x,y) return setmetatable({X=x,Y=y},{__add=function(a,b) return Vector(a.X+b.X,a.Y+b.Y) end}) end
local nextId=0
function CreateAHuman(name) nextId=nextId+1; return {name=name,UniqueID=nextId,Team=0,Health=100,MaxHealth=100,Height=70,AddInventoryItem=function() end} end
function CreateACrab(name,module)
 local actor=CreateAHuman(name,module); actor.vehicle=true; actor.SpriteOffset=Vector(-13,-7); actor.SpriteHeight=16
 return actor
end
function CreateHDFirearm(name) return {name=name} end
function CreateSoundContainer() return {Play=function() end} end
function CreateTerrainObject(name) return {name=name} end
local actors={}
MovableMan={Actors=(function() local i=0; return function() i=i+1; if not actors[i] then i=0; return nil end; return actors[i] end end)(),AddActor=function(_,a) actors[#actors+1]=a end,IsActor=function(_,a) return a~=nil end}
MovableMan.Particles=function() return nil end
function IsAHuman(a) return not a.vehicle end
function IsACrab(a) return a.vehicle==true end
SceneMan={SceneWidth=5200,SceneHeight=800,Scene={PresetName='Frontline Battlefield'},CastMaterialRay=function() return false end,AddSceneObject=function() end,MovePointToGround=function(_,p) return Vector(p.X,600) end}
MusicMan={PlayDynamicSong=function() end}; FrameMan={PlayerScreenWidth=640,IsHudDisabled=function() return false end}
CameraMan={GetOffset=function() return Vector(0,0) end}
UInputMan={GetMouseMovement=function() return Vector(0,0) end,MouseButtonPressed=function() return false end}
PrimitiveMan={DrawLinePrimitive=function() end,DrawScreenBoxFillPrimitive=function() end}
function Frontline:SetPlayerBrain() end; function Frontline:SetViewState() end; function Frontline:SetObservationTarget() end
function Frontline:GetTeamDeathCount(team) return self.deathCounts[team] or 0 end
assert(loadfile('Frontline.rte/Frontline.lua'))()

local function capture(activity,draw,width,height)
 local items,background,lastFill,lastBorder,lines={},nil,nil,nil,{}
 PrimitiveMan.DrawLinePrimitive=function(_,a,b) lines[#lines+1]={a=a,b=b} end
 activity.UIDrawBoxFill=function(_,_,a,b)
  local rect={kind='button',x=a.X,y=a.Y,r=b.X+1,b=b.Y+1}
  if not background then background=rect else lastFill=rect end
  lastBorder=nil
 end
 activity.UIDrawBox=function(_,_,a,b)
  if lastFill and lastFill.x==a.X and lastFill.y==a.Y and lastFill.r==b.X+1 and lastFill.b==b.Y+1 then
   items[#items+1]=lastFill; lastBorder=lastFill
  end
 end
 activity.UIDrawText=function(_,_,p,label,small,alignment)
  assert(alignment==0,'layout harness requires left-aligned text')
  local text=textRect(p.X,p.Y,label,small)
  if lastBorder and p.X>=lastBorder.x and p.X<lastBorder.r and p.Y>=lastBorder.y and p.Y<lastBorder.b then text.owner=lastBorder end
  items[#items+1]=text; lastBorder=nil; lastFill=nil
 end
 FrameMan.PlayerScreenWidth=width; FrameMan.PlayerScreenHeight=height
 activity[draw](activity)
 assert(background,'UI did not draw its panel background')
 if draw=='DrawPanel' and activity.tab=='Research' and activity.researchPage==4 then
  local cards,ports={}, {}
  for _,item in ipairs(items) do
   if item.kind=='button' and item.x>=15 and item.r<=451 and item.y>=124 and item.y<=294 then
    cards[#cards+1]=item
    ports[item]={top=0,bottom=0}
   end
  end
  assert(#cards==5,'Defense Network must expose all five research node cards')
  for _,line in ipairs(lines) do
   local a,b=line.a,line.b
   assert(a.X==b.X or a.Y==b.Y,'research dependency line must be orthogonal')
   for _,endpoint in ipairs({a,b}) do
    for _,card in ipairs(cards) do
     local right,bottom=card.r-1,card.b-1
     if endpoint.X>=card.x and endpoint.X<=right and endpoint.Y>=card.y and endpoint.Y<=bottom then
      assert(endpoint.X==(card.x+right)/2 and (endpoint.Y==card.y or endpoint.Y==bottom),
       'research connector must meet a node only at its top/bottom center port')
      ports[card][endpoint.Y==card.y and 'top' or 'bottom']=ports[card][endpoint.Y==card.y and 'top' or 'bottom']+1
     end
    end
   end
   for _,card in ipairs(cards) do
    local right,bottom=card.r-1,card.b-1
    local crossing
    if a.X==b.X then
     crossing=a.X>card.x and a.X<right and math.max(a.Y,b.Y)>card.y and math.min(a.Y,b.Y)<bottom
    else
     crossing=a.Y>card.y and a.Y<bottom and math.max(a.X,b.X)>card.x and math.min(a.X,b.X)<right
    end
    assert(not crossing,string.format('dependency line (%s,%s)-(%s,%s) crosses research node card (%s,%s)-(%s,%s)',a.X,a.Y,b.X,b.Y,card.x,card.y,card.r,card.b))
   end
  end
  for _,card in ipairs(cards) do
   local p=ports[card]
   assert(p.top>0 or p.bottom>0,'each Defense Network node must connect through a centered top/bottom port')
  end
  local expected={
   {230,139,105,178,3}, {230,139,360,178,3}, {360,193,360,236,1},
   {105,193,230,294,3}, {360,251,230,294,3},
  }
  assert(#lines==13,'Defense Network must render all five expected prerequisite paths')
  local lineIndex=1
  local function cardAtPort(x,y,port)
   for _,card in ipairs(cards) do
    local center=(card.x+card.r-1)/2
    local edge=port=='bottom' and card.b-1 or card.y
    if center==x and edge==y then return card end
   end
  end
  for _,edge in ipairs(expected) do
   assert(cardAtPort(edge[1],edge[2],'bottom'),'expected edge source must use a node bottom-center port')
   assert(cardAtPort(edge[3],edge[4],'top'),'expected edge destination must use a node top-center port')
   local first,last=lines[lineIndex],lines[lineIndex+edge[5]-1]
   assert(first and last and first.a.X==edge[1] and first.a.Y==edge[2]
    and last.b.X==edge[3] and last.b.Y==edge[4],
    'each expected Defense Network edge must connect its bottom-center source to top-center destination')
   lineIndex=lineIndex+edge[5]
  end
  assert(lineIndex==#lines+1,'no extra Defense Network edge or path segment may be rendered')
 end
 return inspect(background,{x=0,y=0,r=width,b=height},items),items
end

local failures,uniqueFailures={},{}
local function recordProblems(label,width,height,problems)
 for _,problem in ipairs(problems) do
  local entry=uniqueFailures[problem]
  if not entry then
   entry={problem=problem,example=label..' '..width..'x'..height,count=0}
   uniqueFailures[problem]=entry
   failures[#failures+1]=entry
  end
  entry.count=entry.count+1
 end
end
local function run(label,activity,draw,width,height)
 local problems,items=capture(activity,draw,width,height)
 if draw=='DrawPanel' and activity.tab=='Battle' then
  for _,post in ipairs(activity.outposts) do
   local row
   local prefix=(post.level=='underground' and '[UNDERGROUND] ' or '')..post.name..':'
   for _,item in ipairs(items) do
    if item.label and item.label:find(prefix,1,true)==1 then row=item.label; break end
   end
   assert(row,'Battle view must render every outpost, including '..post.name)
   if post.owner==0 and post.progress==1 then
    assert(row:find('YOUR TEAM',1,true) and row:find('100%',1,true),
     'Battle view must render the long owned, fully captured outpost state')
   end
  end
 elseif draw=='DrawPanel' and activity.tab=='Squad' then
  local forward=activity.teams[0].forward
  local expected=forward==0 and 'SPAWN: BASE'
   or ('SPAWN: '..activity.outposts[forward].name..' (+'..activity:ForwardDeploymentCost(0)..'/unit)')
  local found=false
  for _,item in ipairs(items) do if item.label==expected then found=true end end
  assert(found,'Squad SPAWN must show the selected destination and its actual surcharge')
 elseif draw=='DrawPanel' and activity.tab=='Support' then
  local shield,jammer,projectiles,strikes=false,false,false,false
  for _,item in ipairs(items) do
   local label=item.label or ''
   if label:find('Shield destroys',1,true) then shield=true end
   if label:find('Jammer blocks',1,true) then jammer=true end
   if label:find('projectiles in its bubble',1,true) then projectiles=true end
   if label:find('strikes, bombs, orbital fire',1,true) then strikes=true end
  end
  assert(shield and jammer and projectiles and strikes,'Support view must render both complete descriptions')
 end
 recordProblems(label,width,height,problems)
end

-- DrawHUD uses actual PrimitiveMan methods here, rather than replacing the
-- UIDraw wrappers. Screen text is engine-laid-out: our double can inspect the
-- payload and options but cannot establish its wrapping or on-screen geometry.
local function runHUD(label,activity,width,height,screenUI,notice)
 local items,background={},nil
 local offset=screenUI and Vector(0,0) or Vector(120,80)
 CameraMan.GetOffset=function() return offset end
 activity.UIDrawBoxFill=nil; activity.UIDrawBox=nil; activity.UIDrawText=nil
 activity.screenUI=screenUI
 FrameMan.PlayerScreenWidth=width; FrameMan.PlayerScreenHeight=height
 activity.noticeTimer.ElapsedSimTimeMS=notice and 0 or 6000
 local function fill(_,_,a,b)
  background={kind='background',x=a.X-offset.X,y=a.Y-offset.Y,r=b.X-offset.X+1,b=b.Y-offset.Y+1}
 end
 local function text(_,_,p,s,small,alignment)
  assert(alignment==0,'HUD text must be left aligned for geometry capture')
  items[#items+1]=textRect(p.X-offset.X,p.Y-offset.Y,s,small)
 end
 PrimitiveMan.DrawScreenBoxFillPrimitive=fill; PrimitiveMan.DrawBoxFillPrimitive=fill
 PrimitiveMan.DrawScreenBoxPrimitive=function() end; PrimitiveMan.DrawBoxPrimitive=function() end
 PrimitiveMan.DrawScreenTextPrimitive=text; PrimitiveMan.DrawTextPrimitive=text
 FrameMan.SetScreenText=nil
 activity:DrawHUD()
 assert(background and #items>=4,'HUD must issue its background and text primitives')
 local messageDrawn=false
 for _,item in ipairs(items) do if item.label==activity.message then messageDrawn=true end end
 assert(messageDrawn==notice,'HUD must show the notice only while active')
 recordProblems(label,width,height,inspect(background,{x=0,y=0,r=width,b=height},items))

 if not screenUI then
  local payload,screen,centered
  FrameMan.SetScreenText=function(_,value,s,_,_,c) payload=value; screen=s; centered=c end
  activity:DrawHUD()
  assert(payload and screen==0 and centered==false and activity.compactScreenText,
   'stock HUD must send uncentered compact text to the engine')
  assert((payload:find(activity.message,1,true)~=nil)==notice,'stock HUD notice state must match')
  local expected={}
  for _,item in ipairs(items) do expected[#expected+1]=item.label end
  assert(payload==table.concat(expected,'\n'),'stock HUD must send the same content as the primitive path')
  assert(select(2,payload:gsub('\n',''))==(notice and 4 or 3),'stock HUD must send every line')
  FrameMan.SetScreenText=nil
 end
 CameraMan.GetOffset=function() return Vector(0,0) end
 activity.screenUI=true
end
local tabs={'Squad','Research','Support','Base','Battle','Setup'}
for _,scene in ipairs({{5200,3},{10400,5},{15600,9}}) do
 local sceneWidth=scene[1]
 actors={}; SceneMan.SceneWidth=sceneWidth
 local a=setmetatable({deathCounts={[0]=0,[1]=0}},{__index=Frontline})
 a:StartActivity(); a:StartBattle(); a.matchTimer.ElapsedSimTimeMS=15000; a.screenUI=true
 assert(#a.outposts==scene[2],'scenario must exercise its intended outpost count')
 a.tab='Squad'
 for _,post in ipairs(a.outposts) do post.owner=0 end
 for destination=0,#a.outposts do
  a.teams[0].forward=destination
  run(sceneWidth..' spawn '..destination,a,'DrawPanel',640,480)
 end
 for _,post in ipairs(a.outposts) do post.owner=-1 end
 for _,state in ipairs({'locked','unlocked','maxed','long'}) do
  local t=a.teams[0]
  for i=1,30 do t.levels[i]=state=='locked' and 0 or 1 end
  t.tier=state=='locked' and 0 or 3
  if state=='maxed' then t.levels[13]=2; t.levels[22]=3; t.levels[23]=3; t.levels[27]=1 end
  if state=='long' then
   a.matchTimer.ElapsedSimTimeMS=1234567890
   a.deathCounts={[0]=12345,[1]=67890}
   for _,post in ipairs(a.outposts) do post.owner=0; post.progress=1 end
   t.levels[2]=10; t.levels[3]=10; t.levels[15]=10; t.levels[29]=6
  end
  t.funds=state=='long' and 99999999 or 450
  t.forward=state=='long' and #a.outposts or 0
  a.message=state=='long' and 'Jammer intercepted precision strike; cost refunded' or 'Build a batch and click DEPLOY.'
  for _,viewport in ipairs({{640,480},{960,540}}) do
   for _,tab in ipairs(tabs) do
    a.tab=tab
    local pages=tab=='Research' and 4 or (tab=='Squad' and 2 or 1)
    for page=1,pages do
     if tab=='Research' then a.researchPage=page elseif tab=='Squad' then a.rosterPage=page end
     run(sceneWidth..' '..state..' '..tab..' page '..page,a,'DrawPanel',viewport[1],viewport[2])
    end
   end
   for step=1,2 do a.setupStep=step; run(sceneWidth..' '..state..' wizard step '..step,a,'DrawWizard',viewport[1],viewport[2]) end
   for _,mode in ipairs({true,false}) do
    for _,notice in ipairs({true,false}) do
     runHUD(sceneWidth..' '..state..' HUD '..(mode and 'screen' or 'world')..(notice and ' notice' or ' quiet'),a,viewport[1],viewport[2],mode,notice)
    end
   end
  end
 end
end
do
 local oldScene,oldWidth,oldHeight=SceneMan.Scene,SceneMan.SceneWidth,SceneMan.SceneHeight
 SceneMan.Scene={PresetName='Frontline Highlands Battlefield'}
 SceneMan.SceneWidth=15600; SceneMan.SceneHeight=1600; actors={}
 local highlands=setmetatable({deathCounts={[0]=0,[1]=0}},{__index=Frontline})
 highlands:StartActivity(); highlands:StartBattle(); highlands.tab='Battle'; highlands.screenUI=true
 assert(#highlands.outposts==11 and highlands.outposts[10].level=='underground'
  and highlands.outposts[11].level=='underground','Highlands UI must include both cavern capture points')
 run('Highlands underground outpost list',highlands,'DrawPanel',640,480)
 highlands.tab='Support'
 run('Highlands underground support controls',highlands,'DrawPanel',640,480)
 SceneMan.Scene=oldScene; SceneMan.SceneWidth=oldWidth; SceneMan.SceneHeight=oldHeight
end
if #failures>0 then
 local total=0
 for _,failure in ipairs(failures) do
  total=total+failure.count
  io.stderr:write(failure.example..': '..failure.problem..' ('..failure.count..' scenarios)\n')
 end
 error(total..' UI layout violations ('..#failures..' distinct)')
end
print('UI layout: HUD primitives, panel, wizard, tabs, research pages, states, 3/5/9 surface outposts and 11 Highlands outposts passed; engine screen text geometry not measurable in doubles')
