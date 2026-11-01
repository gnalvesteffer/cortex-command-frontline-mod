-- Frontline balance and roster. All prices are in gold ounces.
local CONFIG = {
    DEPLOY_COOLDOWN_MS = 10000, -- Shared by manual and automatic deployment.
    START_FUNDS = 450, INCOME_PER_SECOND = 5, BOUNTY = 35,
    TEAM_UNIT_CAP = 12, MAX_BATCH = 6,
    roster = {
        {name="Coalition Light", actor="Soldier Light", mod="Coalition.rte", price=75, unlock=0},
        {name="Coalition Heavy", actor="Soldier Heavy", mod="Coalition.rte", price=120, unlock=1},
        {name="Dummy", actor="Dummy", mod="Dummy.rte", price=105, unlock=2},
        {name="Browncoat Light", actor="Browncoat", mod="Browncoats.rte", price=145, unlock=3},
    },
    weapons = {
        {name="Assault Rifle", preset="Assault Rifle", mod="Coalition.rte", price=30, unlock=0},
        {name="Shotgun", preset="Shotgun", mod="Coalition.rte", price=45, unlock=1},
        {name="Gatling Gun", preset="Gatling Gun", mod="Coalition.rte", price=80, unlock=2},
    },
    research = {
        {name="Income +2/s", price=180, max=5, kind="income"},
        {name="Bounty +15", price=160, max=5, kind="bounty"},
        {name="Heavy / Shotgun", price=200, max=1, kind="tier", tier=1},
        {name="Dummy / Gatling", price=350, max=1, kind="tier", tier=2},
        {name="Browncoat", price=500, max=1, kind="tier", tier=3},
    }
}

local function freshTeam()
    return {funds=CONFIG.START_FUNDS, levels={0,0,0,0,0}, tier=0,
        counts={2,0,0,0}, weapon=1, auto=false, timer=Timer(), deaths=0}
end

function Frontline:StartActivity()
    self.teams = {[0]=freshTeam(), [1]=freshTeam()}
    self.teams[1].auto = true
    for team=0,1 do self.teams[team].timer.ElapsedSimTimeMS=CONFIG.DEPLOY_COOLDOWN_MS end
    self.brains = {}
    for team=0,1 do
        local brain=CreateAHuman("Brain Robot", "Base.rte")
        brain.Team=team
        brain.Pos=Vector(team==0 and 180 or 3020, 570)
        brain.AIMode=Actor.AIMODE_SENTRY
        MovableMan:AddActor(brain)
        self.brains[team]=brain
    end
    for i=1,9 do
        local rock=CreateTerrainObject("Zombie Cave Rock", "Base.rte")
        if rock then
            rock.Pos=Vector(500+i*220+math.random(-65,65), 600)
            SceneMan:AddSceneObject(rock)
        end
    end
    self:SetPlayerBrain(self.brains[0], 0)
    self:SetViewState(Activity.OBSERVE, 0)
    self:SetObservationTarget(Vector(700,560),0)
    self.panel=true
    self.cursorX=200; self.cursorY=100
    self.message="Build a batch and click DEPLOY."
    self.aiTimer=Timer()
    MusicMan:PlayDynamicSong("Generic Battle Music")
end

function Frontline:UnitCount(team)
    local count=0
    for actor in MovableMan.Actors do
        if actor.Team==team and actor.UniqueID ~= self.brains[team].UniqueID and (IsAHuman(actor) or IsACrab(actor)) then count=count+1 end
    end
    return count
end

function Frontline:Batch(team)
    local t=self.teams[team]
    local cost, count=0,0
    local weapon=CONFIG.weapons[t.weapon]
    for i,entry in ipairs(CONFIG.roster) do
        local n=t.counts[i]
        if n>0 and entry.unlock>t.tier then return nil,nil,"Unit is locked" end
        count=count+n
        cost=cost+n*(entry.price+weapon.price)
    end
    if weapon.unlock>t.tier then return nil,nil,"Weapon is locked" end
    return cost,count
end

function Frontline:Deploy(team)
    local t=self.teams[team]
    local cost,count,err=self:Batch(team)
    if not cost then return false,err end
    if count==0 then return false,"Select at least one unit" end
    if not t.timer:IsPastSimMS(CONFIG.DEPLOY_COOLDOWN_MS) then return false,"Deployment cooling down" end
    if t.funds<cost then return false,"Not enough funds" end
    if self:UnitCount(team)+count>CONFIG.TEAM_UNIT_CAP then return false,"Team unit cap reached" end
    -- Construct the complete batch before charging or adding anything to the world.
    local actors={}
    for i,entry in ipairs(CONFIG.roster) do
        for n=1,t.counts[i] do
            local actor=CreateAHuman(entry.actor,entry.mod)
            local weapon=CONFIG.weapons[t.weapon]
            local gun=CreateHDFirearm(weapon.preset,weapon.mod)
            if not actor or not gun then return false,"Missing unit or equipment preset" end
            actor:AddInventoryItem(gun)
            actor.Team=team
            actor.HFlipped=team==1
            actor.AIMode=Actor.AIMODE_BRAINHUNT
            table.insert(actors,actor)
        end
    end
    for i,actor in ipairs(actors) do
        actor.Pos=Vector((team==0 and 335 or 2865)+(team==0 and 1 or -1)*((i-1)*32), 565)
        MovableMan:AddActor(actor)
    end
    t.funds=t.funds-cost
    t.timer:Reset()
    return true,"Batch deployed"
end

function Frontline:Research(team,index)
    local t=self.teams[team]
    local r=CONFIG.research[index]
    if t.levels[index]>=r.max then return false,"Already researched" end
    if r.kind=="tier" and r.tier>1 and t.tier<r.tier-1 then return false,"Research the previous tier first" end
    local price=r.price*(t.levels[index]+1)
    if t.funds<price then return false,"Not enough funds" end
    t.funds=t.funds-price
    t.levels[index]=t.levels[index]+1
    if r.kind=="tier" then t.tier=r.tier end
    return true,"Research complete"
end

function Frontline:UpdateActivity()
    if self.ActivityState==Activity.OVER then return end
    local dead0=not MovableMan:IsActor(self.brains[0])
    local dead1=not MovableMan:IsActor(self.brains[1])
    if dead0 or dead1 then
        self.WinnerTeam=dead0 and (dead1 and Activity.NOTEAM or 1) or 0
        ActivityMan:EndActivity()
        return
    end
    for team=0,1 do
        local t=self.teams[team]
        t.funds=t.funds+(CONFIG.INCOME_PER_SECOND+2*t.levels[1])*TimerMan.DeltaTimeSecs
        local opponent=1-team
        local deaths=self:GetTeamDeathCount(opponent)
        if deaths>t.deaths then
            t.funds=t.funds+(deaths-t.deaths)*(CONFIG.BOUNTY+15*t.levels[2])
            t.deaths=deaths
        end
        if t.auto then self:Deploy(team) end
    end
    if self.aiTimer:IsPastSimMS(4000) then
        self.aiTimer:Reset()
        local ai=self.teams[1]
        local order={3,1,4,2,5}
        for _,i in ipairs(order) do
            local r=CONFIG.research[i]
            if ai.levels[i]<math.min(r.max,1) and ai.funds>r.price+220 then
                local ok=self:Research(1,i)
                if ok then break end
            end
        end
        if ai.tier>=3 then ai.counts={0,0,0,2}; ai.weapon=3
        elseif ai.tier>=2 then ai.counts={0,0,2,0}; ai.weapon=2
        elseif ai.tier>=1 then ai.counts={0,2,0,0}; ai.weapon=1 end
    end
    if UInputMan:KeyPressed(Key.TAB) then self.panel=not self.panel end
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
        self:DrawPanel()
    else
        self.panelCameraOffset=nil
        self:DrawHUD()
    end
end

function Frontline:DrawHUD()
    local t=self.teams[0]
    local offset=CameraMan:GetOffset(0)
    local cost,count=self:Batch(0)
    local left=math.max(0,math.ceil((CONFIG.DEPLOY_COOLDOWN_MS-t.timer.ElapsedSimTimeMS)/1000))
    local function pos(x,y) return offset+Vector(x,y) end
    PrimitiveMan:DrawBoxFillPrimitive(0,pos(8,22),pos(320,79),245)
    PrimitiveMan:DrawBoxPrimitive(0,pos(8,22),pos(320,79),120)
    PrimitiveMan:DrawTextPrimitive(0,pos(14,26),"FRONTLINE  |  TAB: COMMAND",false,0)
    PrimitiveMan:DrawTextPrimitive(0,pos(14,39),"Funds: "..math.floor(t.funds).."  +"..(CONFIG.INCOME_PER_SECOND+2*t.levels[1]).."/s  Bounty: "..(CONFIG.BOUNTY+15*t.levels[2]),false,0)
    PrimitiveMan:DrawTextPrimitive(0,pos(14,52),"Batch: "..(count or 0).." / "..(cost or 0).." oz   Units: "..self:UnitCount(0).."/"..CONFIG.TEAM_UNIT_CAP,false,0)
    PrimitiveMan:DrawTextPrimitive(0,pos(14,65),"Deploy: "..(left>0 and (left.."s") or "READY").."   Auto: "..(t.auto and "ON" or "OFF"),false,0)
end

function Frontline:DrawPanel()
    local t=self.teams[0]
    local screen=0
    local offset=CameraMan:GetOffset(screen)
    local move=UInputMan:GetMouseMovement(0)
    self.cursorX=math.max(8,math.min(405,self.cursorX+move.X))
    self.cursorY=math.max(8,math.min(355,self.cursorY+move.Y))
    local mouse=Vector(self.cursorX,self.cursorY)
    local click=UInputMan:MouseButtonPressed(MouseButtons.MOUSE_LEFT)
    local function pos(x,y) return offset+Vector(x,y) end
    local function text(x,y,s) PrimitiveMan:DrawTextPrimitive(screen,pos(x,y),s,false,0) end
    local function button(x,y,w,label,action)
        PrimitiveMan:DrawBoxFillPrimitive(screen,pos(x,y),pos(x+w,y+15),13)
        PrimitiveMan:DrawBoxPrimitive(screen,pos(x,y),pos(x+w,y+15),120)
        text(x+3,y+3,label)
        if click and mouse.X>=x and mouse.X<=x+w and mouse.Y>=y and mouse.Y<=y+15 then action() end
    end
    PrimitiveMan:DrawBoxFillPrimitive(screen,pos(8,8),pos(405,355),245)
    PrimitiveMan:DrawBoxPrimitive(screen,pos(8,8),pos(405,355),120)
    text(15,14,"FRONTLINE COMMAND  |  TAB: CLOSE")
    local cost,count=self:Batch(0)
    local left=math.max(0,math.ceil((CONFIG.DEPLOY_COOLDOWN_MS-t.timer.ElapsedSimTimeMS)/1000))
    text(15,30,"Funds: "..math.floor(t.funds).."   Income: "..(CONFIG.INCOME_PER_SECOND+2*t.levels[1]).."/s   Bounty: "..(CONFIG.BOUNTY+15*t.levels[2]))
    text(15,43,"Batch: "..(count or 0).." units / "..(cost or 0).." oz   Team: "..self:UnitCount(0).."/"..CONFIG.TEAM_UNIT_CAP.."   Cooldown: "..left.."s")
    text(15,60,"UNITS (choose quantities)")
    for i,r in ipairs(CONFIG.roster) do
        local y=75+(i-1)*19
        text(15,y,r.name.."  "..r.price.." oz"..(r.unlock>t.tier and " [LOCKED]" or ""))
        button(265,y-2,18,"-",function() t.counts[i]=math.max(0,t.counts[i]-1) end)
        text(290,y,tostring(t.counts[i]))
        button(310,y-2,18,"+",function()
            local _,n=self:Batch(0)
            if r.unlock<=t.tier and n and n<CONFIG.MAX_BATCH then t.counts[i]=t.counts[i]+1 end
        end)
    end
    text(15,155,"EQUIPMENT: "..CONFIG.weapons[t.weapon].name.." (+"..CONFIG.weapons[t.weapon].price.."/unit)")
    button(310,151,75,"CHANGE",function()
        local nextIndex=t.weapon%#CONFIG.weapons+1
        if CONFIG.weapons[nextIndex].unlock>t.tier then nextIndex=1 end
        t.weapon=nextIndex
    end)
    text(15,176,"RESEARCH (click to purchase)")
    for i,r in ipairs(CONFIG.research) do
        local y=190+(i-1)*20
        local label=r.name.."  "..r.price*(t.levels[i]+1).." oz  "..t.levels[i].."/"..r.max
        button(15,y,240,label,function() local _,msg=self:Research(0,i); self.message=msg end)
    end
    button(270,190,115,"DEPLOY",function() local _,msg=self:Deploy(0); self.message=msg end)
    button(270,214,115,"AUTO: "..(t.auto and "ON" or "OFF"),function() t.auto=not t.auto end)
    text(15,302,self.message)
    text(15,319,"Choose a batch, then deploy. Cooldown applies to both modes.")
    text(15,334,"Research tiers unlock units and equipment for both teams.")
    PrimitiveMan:DrawBoxFillPrimitive(screen,pos(mouse.X-2,mouse.Y-2),pos(mouse.X+2,mouse.Y+2),120)
end
