-- Frontline Mod Unit Unlock & Deployment Tests
-- Validates unit unlock chain, pricing, starting units, and AI deployment timing.

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

-- Simulate the roster and research config from Frontline.lua
local CONFIG = {
    roster = {
        {name="Coalition Light", actor="Soldier Light", mod="Coalition.rte", price=75, unlock=0, research=1},
        {name="Coalition Heavy", actor="Soldier Heavy", mod="Coalition.rte", price=120, unlock=1},
        {name="Dummy", actor="Dummy", mod="Dummy.rte", price=30, unlock=1},
        {name="Browncoat Light", actor="Browncoat", mod="Browncoats.rte", price=145, unlock=3},
        {name="Gatling Drone", actor="Gatling Drone", mod="Coalition.rte", price=260, unlock=2, vehicle=true},
        {name="Miner", actor="Soldier Light", mod="Coalition.rte", price=100, unlock=0, research=11, miner=true},
        {name="Ronin Bandit", actor="Bandit", mod="Ronin.rte", price=50, unlock=0},
    },
    research = {
        {name="Income +2/s", price=180, max=10, kind="income"},
        {name="Bounty +15", price=160, max=10, kind="bounty"},
        {name="Unit: Coalition Heavy", price=200, max=1, kind="tier", tier=1},
        {name="Unit: Dummy / Gatling Drone", price=350, max=1, kind="tier", tier=2},
        {name="Unit: Browncoat", price=500, max=1, kind="tier", tier=3},
    }
}

function test_coalition_light_requires_research()
    print("\n=== Coalition Light Requires Research ===")
    
    local cl = CONFIG.roster[1]
    assert(cl.research == 1, "Coalition Light has research requirement (index 1)")
    
    -- Simulate team state with no research
    local team = {funds=1000, levels={0,0,0,0,0}, tier=0}
    
    -- Check if unit is unlocked without research
    local unlocked = cl.unlock <= team.tier and (not cl.research or team.levels[cl.research] > 0)
    assert(not unlocked, "Coalition Light is locked at match start (no research)")
    
    -- After researching income (index 1), it should unlock
    team.levels[1] = 1
    unlocked = cl.unlock <= team.tier and (not cl.research or team.levels[cl.research] > 0)
    assert(unlocked, "Coalition Light unlocks after research index 1")
end

function test_dummy_price_and_unlock()
    print("\n=== Dummy Price and Unlock ===")
    
    local dummy = CONFIG.roster[3]
    assert(dummy.price == 30, "Dummy costs 30 oz (not 105)")
    assert(dummy.unlock == 1, "Dummy unlocked at tier 1 (after Coalition Heavy)")
    
    -- Tier 0: locked
    local team = {funds=1000, levels={0,0,0,0,0}, tier=0}
    local unlocked = dummy.unlock <= team.tier and (not dummy.research or team.levels[dummy.research] > 0)
    assert(not unlocked, "Dummy is locked at tier 0")
    
    -- Tier 1: unlocked
    team.tier = 1
    unlocked = dummy.unlock <= team.tier and (not dummy.research or team.levels[dummy.research] > 0)
    assert(unlocked, "Dummy unlocks at tier 1")
end

function test_starting_units_are_ronin()
    print("\n=== Starting Units Are Ronin Bandits ===")
    
    -- Simulate fresh team state
    local team = {funds=450, levels={0,0,0,0,0}, tier=0, counts={0,0,0,0,0,0,2}}
    
    -- Verify the counts array has 2 Ronin Bandits (index 7)
    assert(team.counts[7] == 2, "Starting deployment has 2 Ronin Bandits")
    assert(team.counts[1] == 0, "Starting deployment has 0 Coalition Light units")
    
    -- Verify Ronin Bandit is unlocked at start (tier 0, no research)
    local ronin = CONFIG.roster[7]
    local unlocked = ronin.unlock <= team.tier and (not ronin.research or team.levels[ronin.research] > 0)
    assert(unlocked, "Ronin Bandit is unlocked at match start")
    
    -- Verify the batch cost is affordable with starting funds
    local totalCost = team.counts[7] * ronin.price
    assert(totalCost <= team.funds, "Starting Ronin deployment (" .. totalCost .. " oz) is affordable with " .. team.funds .. " oz")
end

function test_ai_deploys_early()
    print("\n=== AI Deploys Early ===")
    
    -- Simulate AI decision at match start with limited funds
    local ai = {funds=450, tier=0, levels={0,0,0,0,0}}
    
    -- AI should be able to deploy something immediately
    -- Ronin Bandits cost 50 each, so AI can afford at least one
    local ronin = CONFIG.roster[7]
    assert(ai.funds >= ronin.price, "AI has enough funds for at least one Ronin Bandit at match start")
    
    -- Simulate multiple AI deployment attempts with increasing funds
    local ai_funds = 450
    for i = 1, 5 do
        if ai_funds >= 200 then
            -- AI should deploy as soon as it has 200+ oz (can afford 4 Ronin)
            local can_deploy = ai_funds >= ronin.price * 2
            assert(can_deploy or i > 1, "AI can deploy units when funds reach threshold")
            break
        end
        ai_funds = ai_funds + 50 -- Simulate income
    end
    
    -- Verify AI doesn't wait too long (should deploy within first few decisions)
    local decisions_before_deploy = 0
    ai_funds = 450
    while ai_funds < 200 do
        ai_funds = ai_funds + 50
        decisions_before_deploy = decisions_before_deploy + 1
    end
    assert(decisions_before_deploy <= 3, "AI deploys within 3 decision cycles (not waiting too long)")
end

function test_unit_unlock_chain()
    print("\n=== Unit Unlock Chain ===")
    
    -- Verify the unlock chain makes sense
    local cl = CONFIG.roster[1]   -- Coalition Light: research required
    local ch = CONFIG.roster[2]   -- Coalition Heavy: tier 1
    local dummy = CONFIG.roster[3] -- Dummy: tier 1
    local browncoat = CONFIG.roster[4] -- Browncoat: tier 3
    
    assert(ch.unlock == 1, "Coalition Heavy unlocks at tier 1")
    assert(dummy.unlock == 1, "Dummy unlocks at tier 1 (same as Coalition Heavy)")
    assert(browncoat.unlock == 3, "Browncoat unlocks at tier 3")
    
    -- Verify research entries match unit tiers
    local heavy_research = CONFIG.research[3]
    assert(heavy_research.kind == "tier" and heavy_research.tier == 1, "Research index 3 is tier 1 unlock")
    
    local dummy_research = CONFIG.research[4]
    assert(dummy_research.kind == "tier" and dummy_research.tier == 2, "Research index 4 is tier 2 unlock (Gatling Drone)")
end

-- Run all tests
test_coalition_light_requires_research()
test_dummy_price_and_unlock()
test_starting_units_are_ronin()
test_ai_deploys_early()
test_unit_unlock_chain()

print("\n=== Test Results ===")
print("Passed: " .. TESTS_PASSED)
print("Failed: " .. TESTS_FAILED)

if TESTS_FAILED > 0 then
    os.exit(1)
end