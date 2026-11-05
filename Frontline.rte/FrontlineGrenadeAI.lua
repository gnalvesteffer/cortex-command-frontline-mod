if not HumanBehaviors then require("AI/HumanBehaviors") end

local function inventoryGrenade(actor)
    local equipped=actor.EquippedItem
    if equipped and equipped.HasObjectInGroup and equipped:HasObjectInGroup("Bombs - Grenades") then
        return ToThrownDevice(equipped)
    end
    for item in actor.Inventory do
        if item.HasObjectInGroup and item:HasObjectInGroup("Bombs - Grenades") then
            return ToThrownDevice(item)
        end
    end
end

local function installFrontlineThrowPolicy(actor)
    local ai=actor.AI
    if not ai or ai.frontlineGrenadePolicyInstalled then return end
    local nativeCreateAttackBehavior=ai.CreateAttackBehavior
    if not nativeCreateAttackBehavior then return end
    ai.frontlineGrenadePolicyInstalled=true
    ai.CreateAttackBehavior=function(self,owner)
        if self.Target and not self.PickupHD and not owner:IsPlayerControlled()
            and owner:HasObjectInGroup("Bombs - Grenades") then
            local grenade=inventoryGrenade(owner)
            local activity=ActivityMan:GetActivity()
            if grenade and activity and activity.CanFrontlineThrowGrenade
                and activity:CanFrontlineThrowGrenade(owner,self.Target,grenade,HumanBehaviors.GetGrenadeAngle)
                and owner:EquipDeviceInGroup("Bombs - Grenades",true) and owner.ThrowableIsReady then
                self.ReloadTimer:Reset()
                self.TargetLostTimer:Reset()
                self.NextBehavior=coroutine.create(HumanBehaviors.ThrowTarget)
                self.NextBehaviorName="ThrowTarget"
                self.NextCleanup=function(currentAI)
                    currentAI.fire=false
                    currentAI.TargetLostTimer:SetSimTimeLimitMS(2000)
                end
                return
            end
            if not owner:EquipFirearm(true) then
                self.TargetLostTimer:Reset()
                self.NextBehavior=coroutine.create(HumanBehaviors.Sentry)
                self.NextBehaviorName="Sentry"
                self.NextCleanup=nil
                return
            end
            -- NativeHumanAI has its own grenade preference. Its selector must
            -- see SQUAD briefly so an unsafe grenade cannot bypass our gate.
            local aimode=owner.AIMode
            owner.AIMode=Actor.AIMODE_SQUAD
            nativeCreateAttackBehavior(self,owner)
            owner.AIMode=aimode
            return
        end
        return nativeCreateAttackBehavior(self,owner)
    end
end

function Create(self)
    installFrontlineThrowPolicy(self)
end

function ThreadedUpdateAI(self)
    installFrontlineThrowPolicy(self)
end
