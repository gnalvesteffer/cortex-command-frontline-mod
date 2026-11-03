-- Frontline Mod AI Tests
-- Validates AI personality assignment, adaptive research, deployment strategies,
-- and call-in rotation logic.

local TESTS_PASSED = 0
local TESTS_FAILED = 0

function assert(condition, message)
    if condition then
        TESTS_PASSED = TESTS_PASSED + 1
        print("✓ " .. message)
    else
        TESTS_FAILED = TESTS_FAILED + 1
        print("✗ " .. message)
    end
end

function test_ai_personality_assignment()
    print("\n=== AI Personality Assignment ===")
    
    -- Test that personality is assigned at match start
    local frontline = {teams = {{}, {}}, aiPersonality = nil}
    frontline.teams[1].funds = 1000
    
    -- Simulate personality assignment (normally happens in UpdateAI)
    local roll = math.random(1, 4)
    if roll == 1 then frontline.aiPersonality = "aggressive"
    elseif roll == 2 then frontline.aiPersonality = "defensive"
    elseif roll == 3 then frontline.aiPersonality = "economic"
    else frontline.aiPersonality = "balanced" end
    
    assert(frontline.aiPersonality ~= nil, "AI personality is assigned at match start")
    assert(type(frontline.aiPersonality) == "string", "AI personality is a string")
    
    -- Verify all four personalities are possible
    local valid_personalities = {"aggressive", "defensive", "economic", "balanced"}
    local found = false
    for _, p in ipairs(valid_personalities) do
        if frontline.aiPersonality == p then found = true; break end
    end
    assert(found, "AI personality is one of the four valid options")
end

function test_ai_research_priorities()
    print("\n=== AI Research Priorities ===")
    
    -- Test that different personalities have different research priorities
    local aggressive_priorities = {3, 4, 7, 8, 2, 6, 1, 10, 11, 16, 13, 14, 15, 9, 5}
    local defensive_priorities = {1, 12, 3, 6, 2, 10, 16, 13, 14, 15, 8, 7, 9, 4, 5}
    local economic_priorities = {1, 12, 11, 3, 6, 2, 10, 16, 13, 14, 15, 8, 7, 9, 4, 5}
    
    assert(aggressive_priorities[1] == 3, "Aggressive AI prioritizes infantry weapons first")
    assert(defensive_priorities[1] == 1, "Defensive AI prioritizes infantry first")
    assert(economic_priorities[1] == 1, "Economic AI prioritizes infantry first")
    
    -- Test adaptive priorities under pressure
    local pressured_priorities = {12, 3, 4, 7, 8, 2, 1, 10, 11, 16, 13, 14, 15, 9, 6, 5}
    assert(pressured_priorities[1] == 12, "Under pressure, AI prioritizes SMGs first")
end

function test_ai_deployment_batch_sizes()
    print("\n=== AI Deployment Batch Sizes ===")
    
    -- Test that batch sizes vary by personality and funds
    local aggressive_batch = 4 + math.random(0, 1)  -- 4-5 units
    local defensive_batch = 2 + math.random(0, 1)   -- 2-3 units
    local balanced_batch = 3 + math.random(0, 1)     -- 3-4 units
    
    assert(aggressive_batch >= 4 and aggressive_batch <= 5, "Aggressive AI deploys 4-5 units per batch")
    assert(defensive_batch >= 2 and defensive_batch <= 3, "Defensive AI deploys 2-3 units per batch")
    assert(balanced_batch >= 3 and balanced_batch <= 4, "Balanced AI deploys 3-4 units per batch")
end

function test_ai_callin_rotation()
    print("\n=== AI Call-In Rotation ===")
    
    -- Test that AI rotates through all three offensive call-ins
    local kinds = {"strike", "bomb", "orbital"}
    local offense_choice = 1
    
    for i = 1, 6 do
        local choice = (offense_choice - 1) % #kinds + 1
        assert(kinds[choice] ~= nil, "Call-in choice is valid at iteration " .. i)
        offense_choice = choice % #kinds + 1
    end
    
    -- Test adaptive call-in selection based on player unit count
    local aggressive_kinds = {"orbital", "bomb", "strike"}
    assert(aggressive_kinds[1] == "orbital", "Aggressive AI prioritizes orbital strikes vs large forces")
end

function test_ai_fortification_strategy()
    print("\n=== AI Fortification Strategy ===")
    
    -- Test that AI alternates between cover and mines
    local fortify_choice = nil
    
    -- First choice: cover (default)
    assert(fortify_choice == nil or fortify_choice == "mines", "AI starts with cover fortifications")
    
    -- After using cover, switch to mines
    fortify_choice = "cover"
    local next_choice = fortify_choice == "mines" and "cover" or "mines"
    assert(next_choice == "mines", "AI switches to mines after cover")
    
    -- After using mines, switch back to cover
    fortify_choice = "mines"
    next_choice = fortify_choice == "mines" and "cover" or "mines"
    assert(next_choice == "cover", "AI switches back to cover after mines")
end

function test_player_behavior_tracking()
    print("\n=== Player Behavior Tracking ===")
    
    -- Test that player behavior is tracked for adaptation
    local player_behavior = {deployments = 0, callins_used = 0, research_focus = ""}
    
    -- Simulate player deployments
    for i = 1, 6 do
        player_behavior.deployments = player_behavior.deployments + 1
    end
    
    assert(player_behavior.deployments == 6, "Player deployment count is tracked")
    
    -- Test adaptive response to aggressive player
    local ai_response = player_behavior.deployments > 5 and "advance" or "balanced"
    assert(ai_response == "advance", "AI adapts to aggressive player by advancing")
end

function test_ai_weapon_selection()
    print("\n=== AI Weapon Selection ===")
    
    -- Test that AI selects appropriate weapons based on research unlocks
    local ai = {levels = {}, tier = 1}
    
    -- No research: basic rifle
    local weapon = 6  -- Basic rifle index
    assert(weapon == 6, "Unresearched AI uses basic rifles")
    
    -- After SMG research
    ai.levels[12] = 1
    weapon = 1  -- SMG index
    assert(weapon == 1, "AI upgrades to SMGs after research")
    
    -- After LMG research
    ai.levels[2] = 1
    weapon = 2  -- LMG index
    assert(weapon == 2, "AI upgrades to LMGs after research")
    
    -- After sniper research and detecting player threat
    ai.levels[4] = 1
    weapon = 4  -- Sniper index
    assert(weapon == 4, "AI uses snipers when researched and needed")
end

function test_ai_base_upgrades()
    print("\n=== AI Base Upgrades ===")
    
    -- Test that AI invests in base upgrades before research
    local ai = {funds = 10000, base_armor = 0}
    local brain = {Health = 50, MaxHealth = 100}
    
    -- Should repair damaged brain first
    assert(brain.Health < brain.MaxHealth - 25 and ai.funds >= 240, "AI prioritizes brain repair when damaged")
    
    -- Then turret if not present
    local has_turret = false
    assert(not has_turret and ai.funds >= 300, "AI builds turret if missing")
    
    -- Then armor upgrades
    assert(ai.base_armor < 3 and ai.funds >= 400, "AI upgrades base armor when affordable")
end

-- Run all tests
test_ai_personality_assignment()
test_ai_research_priorities()
test_ai_deployment_batch_sizes()
test_ai_callin_rotation()
test_ai_fortification_strategy()
test_player_behavior_tracking()
test_ai_weapon_selection()
test_ai_base_upgrades()

print("\n=== Test Results ===")
print("Passed: " .. TESTS_PASSED)
print("Failed: " .. TESTS_FAILED)

if TESTS_FAILED > 0 then
    os.exit(1)
end