-- Appended only to a disposable copy of Frontline.lua by run_headless_frontline.sh.
-- The real engine must stamp the mirrored capture halls, then native infantry
-- must climb each stock shaft and the stationary hall troops must capture.
local originalHighlandsStart=Frontline.StartActivity
local originalHighlandsUpdate=Frontline.UpdateActivity
local originalCreateTerrainObject=CreateTerrainObject
local stampedParts={}
local bunkerPresets={['End B']=true,
    ['T-Junction B']=true,['Tunnel A']=true,['Shaft A']=true,['Background Ladder']=true}

CreateTerrainObject=function(name,moduleName)
    local object=originalCreateTerrainObject(name,moduleName)
    if bunkerPresets[name] then stampedParts[#stampedParts+1]={name=name,object=object,module=moduleName} end
    return object
end

local function writeHighlandsResult(payload)
    local resultPath=os.getenv('FRONTLINE_TEST_RESULT')
    if not resultPath or resultPath=='' then return false end
    local file=io.open(resultPath,'w')
    if not file then return false end
    file:write(payload,'\n'); file:close()
    return true
end

Frontline.StartActivity=function(self,...)
    originalHighlandsStart(self,...)
    local ok,failure=pcall(function()
        assert(SceneMan.Scene.PresetName=='Frontline Highlands Battlefield','runner must load the actual Highlands scene')
        assert(self.highlandsBunkerActive and #self.outposts==11,'Highlands must initialize both cave capture points')
        local counts={}
        for _,part in ipairs(stampedParts) do counts[part.name]=(counts[part.name] or 0)+1 end
        assert(counts['End B']==3 and counts['T-Junction B']==4 and counts['Shaft A']==10
            and counts['Background Ladder']==40,
            'actual engine must stamp all three halls, while scene data supplies the opposite right caps')
        local expected={{x=4200,segments=2},{x=11400,segments=2}}
        for index,entry in ipairs(expected) do
            local post=self.outposts[9+index]
            assert(post.level=='underground' and post.x==entry.x and post.x+expected[3-index].x==SceneMan.SceneWidth,
                'cave capture locations must be symmetric, distinct and underground')
            local hallCenterY=post.surfaceY+48+entry.segments*96
            assert(post.captureY==hallCenterY+4 and post.groundY==hallCenterY+24,
                'capture marker and floor must match the stamped hall elevation')
        end
        self:StartBattle()
        self.teams[0].auto=false
        self.teams[1].auto=false
        self.matchTimer.ElapsedSimTimeMS=16000
        local player=self.teams[0]
        player.forward=10; player.counts={0,0,0,0,0,1}
        player.weapons={1,1,1,1,1,1,1}; player.funds=10000; player.timer.ElapsedSimTimeMS=100000
        self:SetTeamFunds(player.funds,0)
        self.highlandsTraversalCases={}
        for index,entry in ipairs(expected) do
            local post=self.outposts[9+index]
            local direction=index==1 and 1 or -1
            local guard=CreateAHuman('Soldier Light','Coalition.rte')
            guard.Team=0; guard.Pos=Vector(entry.x-75,post.captureY); guard.AIMode=Actor.AIMODE_SENTRY
            MovableMan:AddActor(guard)
            local climber=CreateAHuman('Soldier Light','Coalition.rte')
            climber.Team=0; climber.Pos=Vector(entry.x,post.captureY); climber.AIMode=Actor.AIMODE_GOTO
            climber:AddAISceneWaypoint(Vector(entry.x+direction*160,CONFIG.map.highlandsBunker.surfaceY-40))
            MovableMan:AddActor(climber)
            local passage=CreateAHuman('Soldier Light','Coalition.rte')
            passage.Team=0; passage.Pos=Vector(entry.x+55,post.captureY); passage.AIMode=Actor.AIMODE_GOTO
            passage:AddAISceneWaypoint(Vector(entry.x+205,post.captureY))
            MovableMan:AddActor(passage)
            self.highlandsTraversalCases[index]={shaft=entry.x,post=post,climberID=climber.UniqueID,
                passageID=passage.UniqueID,passedRightEnd=false,lastPassageX=passage.Pos.X,
                exited=false,minY=climber.Pos.Y,lastX=climber.Pos.X,lastY=climber.Pos.Y,guardID=guard.UniqueID}
        end
        self.highlandsTraversalTick=0
    end)
    if not ok then
        local payload='FAIL highlands '..tostring(failure)
        if not writeHighlandsResult(payload) then ConsoleMan:PrintString(payload) end
        error(failure)
    end
end

Frontline.UpdateActivity=function(self,...)
    originalHighlandsUpdate(self,...)
    if not self.highlandsTraversalCases then return end
    self.highlandsTraversalTick=self.highlandsTraversalTick+1
    if not self.highlandsForwardDeliveryChecked and self.outposts[10].owner==0
        and self.teams[0].timer:IsPastSimMS(self:DeployCooldown(0)) then
        local deployed,reason=self.commanders[0]:Deploy()
        if not deployed then
            local payload='FAIL highlands forward deployment '..tostring(reason)
            if not writeHighlandsResult(payload) then ConsoleMan:PrintString(payload) end
            error(reason)
        end
        local target=self.outposts[10]
        local delivery=self.deliveries[#self.deliveries]
        assert(delivery and delivery.ship.Pos.Y<target.landingY
            and math.abs(delivery.ship.Pos.X-(target.landingX-CONFIG.FORWARD_LANDING_OFFSET))<2,
            'real forward Dropship must stage above the mirrored cave surface entry, not underground')
        self.highlandsForwardDeliveryChecked=true
    end
    for actor in MovableMan.Actors do
        for _,case in ipairs(self.highlandsTraversalCases) do
            if actor.UniqueID==case.climberID then
                case.minY=math.min(case.minY,actor.Pos.Y)
                case.lastX,case.lastY=actor.Pos.X,actor.Pos.Y
                if math.abs(actor.Pos.X-case.shaft)>60 and actor.Pos.Y<CONFIG.map.highlandsBunker.surfaceY then
                    case.exited=true
                end
            elseif actor.UniqueID==case.passageID then
                case.lastPassageX=actor.Pos.X
                if actor.Pos.X>=case.shaft+180 then case.passedRightEnd=true end
            end
        end
    end
    if self.highlandsTraversalTick==4800 then
        local ok,failure=pcall(function()
            for index,case in ipairs(self.highlandsTraversalCases) do
                assert(case.exited,'native infantry did not traverse Highlands shaft '..case.shaft
                    ..' (x='..tostring(case.lastX)..', y='..tostring(case.lastY)..', minY='..tostring(case.minY)..')')
                assert(case.passedRightEnd,'native infantry could not cross the right-end hall junction at '..case.shaft
                    ..' (x='..tostring(case.lastPassageX)..')')
                assert(case.post.owner==0,'hall guard did not capture cave outpost '..case.post.name
                    ..' (progress='..tostring(case.post.progress)..')')
            end
            assert(self.highlandsForwardDeliveryChecked,"real forward deployment to an owned cavern post was not exercised")
        end)
        local payload=ok and 'PASS highlands cave_posts=2 mirrored=PASS halls=2 stamped=PASS shafts=2/2 traversed=2/2 hall_passage=2/2 captured=2/2 forward=PASS'
            or 'FAIL highlands '..tostring(failure)
        if not writeHighlandsResult(payload) then ConsoleMan:PrintString(payload) end
        if not ok then error(failure) end
    end
end
