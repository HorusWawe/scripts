-- [[ Rscripts Risk Notice ]]
-- This script is not verified by rscripts.net. Deal with caution.
--
-- Stay safe:
--   • Never log in on unofficial Roblox sites or lookalike domains.
--   • Real Roblox links use roblox.com (check the .com ending).
--   • Treat fake Roblox login / "claim reward" pages as phishing.
-- [[ End Rscripts Risk Notice ]]
-- https://discord.gg/SZDQTaHd9d
-- this script has been made by nucax
-- KuromiX Doors :3
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()

-- used by Auto Library Code
plr.CharacterAdded:Connect(function(newChar)
	char = newChar
end)

-- Window
local Window = Rayfield:CreateWindow({
	Name = "HorusWawe Doors",
	LoadingTitle = "LOADINGGGGGGGGG",
	LoadingSubtitle = "author HorusWawe",
	ToggleUIKeybind = "K",
	ConfigurationSaving = { Enabled = false, FileName = "Horus_Doors" }
})

-- Tabs
local ESPTab = Window:CreateTab("ESP", nil)
local MiscTab = Window:CreateTab("Misc", nil)
local ConfigTab = Window:CreateTab("Config", nil)
local InfoTab = Window:CreateTab("Info", nil)

local flags = {
	doorESP      = false,
	espkeys      = false,
	espitems     = false,
	espbooks     = false,
	esprush      = false,
	esplocker    = false,
	espchest     = false,
	espgold      = false,
	esphumans    = false,
	hintrush     = false,
	getcode      = false,
	draweraura   = false,
	espfigure    = false,
}

local goldespvalue = 0

local esptable = {
	doors   = {},
	keys    = {},
	items   = {},
	books   = {},
	entity  = {},
	lockers = {},
	chests  = {},
	gold    = {},
	people  = {},
	figure  = {},
}

local entitynames = {
	"RushMoving", "AmbushMoving", "ScreechMoving",
	"HideMoving", "TimothyMoving", "DupeMoving",
	"FloorMoving", "FigureMoving", -- i dont know why but i will keep this in here to make this script more stable
}

local extraEntityNames = {
	"Eyes", "BackdoorRush", "BackdoorLookman", "GloombatSwarm",
	"A60", "A120", "JeffTheKiller",
}

local function isEntityName(name)
	if table.find(entitynames, name) or table.find(extraEntityNames, name) then
		return true
	end
	return name:sub(-6) == "Moving"
end

-- Scan interval variables
local doorScanInterval = 3

local function esp(target, color, labelPart, labelText)
	-- target can be a single Instance or a table of parts
	local highlights = {}
	local billboards = {}

	local function highlightInst(inst)
		if not inst or not inst.Parent then return end
		if inst:FindFirstChild("_KuromiESP_H") then return end
		local h = Instance.new("Highlight")
		h.Name = "_KuromiESP_H"
		h.Adornee = inst
		h.FillColor = color
		h.OutlineColor = color
		h.FillTransparency = 0.5
		h.OutlineTransparency = 0
		h.Parent = inst
		table.insert(highlights, h)
	end

	if typeof(target) == "table" then
		for _, part in pairs(target) do
			highlightInst(part)
		end
	else
		highlightInst(target)
	end

	-- Billboard label on labelPart
	if labelPart and labelPart.Parent then
		if not labelPart:FindFirstChild("_KuromiESP_BB") then
			local bb = Instance.new("BillboardGui")
			bb.Name = "_KuromiESP_BB"
			bb.Adornee = labelPart
			bb.Size = UDim2.fromScale(5, 2)
			bb.StudsOffset = Vector3.new(0, 3, 0)
			bb.AlwaysOnTop = true

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.TextScaled = true
			lbl.Text = labelText or ""
			lbl.TextColor3 = color
			lbl.Font = Enum.Font.GothamBold
			lbl.Parent = bb

			bb.Parent = labelPart
			table.insert(billboards, bb)
		end
	end

	local handle = {}
	function handle.delete()
		for _, h in pairs(highlights) do
			if h and h.Parent then h:Destroy() end
		end
		for _, bb in pairs(billboards) do
			if bb and bb.Parent then bb:Destroy() end
		end
	end

	return handle
end

local doorTransparencyBackup = {}
local doorTextRefs = {}

local function removeAllDoorESP()
	for door, t in pairs(doorTransparencyBackup) do
		if door and door.Parent then
			door.Transparency = t
		end
		local h = door:FindFirstChild("_KuromiESP_H")
		if h then h:Destroy() end
		local bb = door:FindFirstChild("_KuromiESP_BB")
		if bb then bb:Destroy() end
	end
	table.clear(doorTransparencyBackup)
	table.clear(doorTextRefs)
end

task.spawn(function()
	while true do
		if flags.doorESP then
			local rooms = Workspace:FindFirstChild("CurrentRooms")
			if rooms then
				for _, room in pairs(rooms:GetChildren()) do
					local door = room:FindFirstChild("RoomExit")
					if door then
						if not doorTransparencyBackup[door] then
							doorTransparencyBackup[door] = door.Transparency
						end
						door.Transparency = 0
						if not door:FindFirstChild("_KuromiESP_H") then
							local h = Instance.new("Highlight")
							h.Name = "_KuromiESP_H"
							h.Adornee = door
							h.FillColor = Color3.fromRGB(0, 255, 0)
							h.OutlineColor = Color3.fromRGB(0, 255, 0)
							h.FillTransparency = 0.5
							h.OutlineTransparency = 0
							h.Parent = door
						end
						if not doorTextRefs[door] then
							local roomNum = tonumber(room.Name)
							if roomNum then
								local bb = Instance.new("BillboardGui")
								bb.Name = "_KuromiESP_BB"
								bb.Adornee = door
								bb.Size = UDim2.fromScale(4, 2)
								bb.StudsOffset = Vector3.new(0, 3, 0)
								bb.AlwaysOnTop = true
								local lbl = Instance.new("TextLabel")
								lbl.Size = UDim2.fromScale(1, 1)
								lbl.BackgroundTransparency = 1
								lbl.TextScaled = true
								lbl.Text = tostring(roomNum + 1)
								lbl.TextColor3 = Color3.fromRGB(0, 255, 0)
								lbl.Font = Enum.Font.GothamBold
								lbl.Parent = bb
								bb.Parent = door
								doorTextRefs[door] = bb
							end
						end
					end
				end
			end
		else
			removeAllDoorESP()
		end
		task.wait(doorScanInterval)
	end
end)


-- Door ESP
ESPTab:CreateToggle({
	Name = "ESP Doors",
	CurrentValue = false,
	Flag = "esp_door",
	Callback = function(v)
		flags.doorESP = v
		if not v then removeAllDoorESP() end
	end
})

-- Keys / Levers ESP
ESPTab:CreateToggle({
	Name = "ESP Keys/Levers",
	CurrentValue = false,
	Flag = "esp_keys",
	Callback = function(Value)
		flags.espkeys = Value
		if not Value then return end

		local function check(v)
			if v:IsA("Model") and (v.Name == "LeverForGate" or v.Name == "KeyObtain") then
				task.wait(0.1)
				if v.Name == "KeyObtain" then
					local hitbox = v:WaitForChild("Hitbox")
					local parts = hitbox:GetChildren()
					local promptHitbox = hitbox:FindFirstChild("PromptHitbox")
					if promptHitbox then
						table.remove(parts, table.find(parts, promptHitbox))
					end
					local h = esp(parts, Color3.fromRGB(90, 255, 40), hitbox, "Key")
					table.insert(esptable.keys, h)

				elseif v.Name == "LeverForGate" then
					local h = esp(v, Color3.fromRGB(90, 255, 40), v.PrimaryPart, "Lever")
					table.insert(esptable.keys, h)

					v.PrimaryPart:WaitForChild("SoundToPlay").Played:Connect(function()
						h.delete()
					end)
				end
			end
		end

		local function setup(room)
			local assets = room:WaitForChild("Assets")
			assets.DescendantAdded:Connect(function(v)
				if flags.espkeys then check(v) end
			end)
			for _, v in pairs(assets:GetDescendants()) do
				check(v)
			end
		end

		local addconnect
		addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
			if flags.espkeys then setup(room) end
		end)

		for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
			if room:FindFirstChild("Assets") then
				setup(room)
			end
		end

		repeat task.wait() until not flags.espkeys
		addconnect:Disconnect()

		for _, v in pairs(esptable.keys) do v.delete() end
		table.clear(esptable.keys)
	end
})

-- Item ESP
ESPTab:CreateToggle({
	Name = "ESP Items",
	CurrentValue = false,
	Flag = "esp_items",
	Callback = function(Value)
		flags.espitems = Value
		if not Value then return end

		local function check(v)
			if v:IsA("Model") and (v:GetAttribute("Pickup") or v:GetAttribute("PropType")) then
				task.wait(0.1)
				local part = v:FindFirstChild("Handle") or v:FindFirstChild("Prop")
				if not part then return end
				local h = esp(part, Color3.fromRGB(160, 190, 255), part, v.Name)
				table.insert(esptable.items, h)
			end
		end

		local function setup(room)
			local assets = room:WaitForChild("Assets")
			if assets then
				local subaddcon
				subaddcon = assets.DescendantAdded:Connect(function(v)
					if flags.espitems then check(v) end
				end)
				for _, v in pairs(assets:GetDescendants()) do
					check(v)
				end
				task.spawn(function()
					repeat task.wait() until not flags.espitems
					subaddcon:Disconnect()
				end)
			end
		end

		local addconnect
		addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
			if flags.espitems then setup(room) end
		end)

		for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
			if room:FindFirstChild("Assets") then setup(room) end
		end

		repeat task.wait() until not flags.espitems
		addconnect:Disconnect()

		for _, v in pairs(esptable.items) do v.delete() end
		table.clear(esptable.items)
	end
})

-- Breaker / Book ESP
ESPTab:CreateToggle({
	Name = "ESP Breakers/Books",
	CurrentValue = false,
	Flag = "esp_books",
	Callback = function(Value)
		flags.espbooks = Value
		if not Value then return end

		local function check(v, room)
			if v:IsA("Model") and (v.Name == "LiveHintBook" or v.Name == "LiveBreakerPolePickup") then
				task.wait(0.1)
				local label = (v.Name == "LiveHintBook") and "Book" or "Breaker"
				local h = esp(v, Color3.fromRGB(160, 190, 255), v.PrimaryPart, label)
				table.insert(esptable.books, h)

				v.AncestryChanged:Connect(function()
					if not v:IsDescendantOf(room) then
						h.delete()
					end
				end)
			end
		end

		local function setup(room)
			if room.Name == "50" or room.Name == "100" then
				room.DescendantAdded:Connect(function(v)
					if flags.espbooks then check(v, room) end
				end)
				for _, v in pairs(room:GetDescendants()) do
					check(v, room)
				end
			end
		end

		local addconnect
		addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
			if flags.espbooks then setup(room) end
		end)

		for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
			setup(room)
		end

		repeat task.wait() until not flags.espbooks
		addconnect:Disconnect()

		for _, v in pairs(esptable.books) do v.delete() end
		table.clear(esptable.books)
	end
})

-- Entity ESP -- THE WHOLE FIGURE ESP LOGIC IS BROKEN BECAUSE OF A UPDATE
-- THATS WHY I ADDED A NEW ESP LOGIC WITH ANOTHER BUTTON. I MERGE BOTH INTO ONE BUTTON IN THE UI 
ESPTab:CreateToggle({
	Name = "ESP Entities (Rush, Ambush..)",
	CurrentValue = false,
	Flag = "esp_entities",
	Callback = function(Value)
		flags.esprush = Value
		if not Value then return end

		local addconnect
		addconnect = workspace.ChildAdded:Connect(function(v)
			if table.find(entitynames, v.Name) then
				task.wait(0.1)
				local h = esp(v, Color3.fromRGB(255, 25, 25), v.PrimaryPart, v.Name:gsub("Moving", ""))
				table.insert(esptable.entity, h)
			end
		end)

		local function setup(room)
			if room.Name == "50" or room.Name == "100" then
				local figuresetup = room:WaitForChild("FigureSetup")
				if figuresetup then
					local fig = figuresetup:WaitForChild("FigureRagdoll")
					task.wait(0.1)
					local h = esp(fig, Color3.fromRGB(255, 25, 25), fig.PrimaryPart, "Figure")
					table.insert(esptable.entity, h)
				end
			else
				local assets = room:WaitForChild("Assets")

				local function check(v)
					if v:IsA("Model") and table.find(entitynames, v.Name) then
						task.wait(0.1)
						local base = v:WaitForChild("Base")
						local h = esp(base, Color3.fromRGB(255, 25, 25), base, "Snare")
						table.insert(esptable.entity, h)
					end
				end

				assets.DescendantAdded:Connect(function(v)
					if flags.esprush then check(v) end
				end)

				for _, v in pairs(assets:GetDescendants()) do
					check(v)
				end
			end
		end

		local roomconnect
		roomconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
			if flags.esprush then setup(room) end
		end)

		for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
			setup(room)
		end

		repeat task.wait() until not flags.esprush
		addconnect:Disconnect()
		roomconnect:Disconnect()

		for _, v in pairs(esptable.entity) do v.delete() end
		table.clear(esptable.entity)
	end
})

-- Figure ESP
ESPTab:CreateToggle({
	Name = "ESP Figure (Figure)",
	CurrentValue = false,
	Flag = "esp_figure",
	Callback = function(Value)
		flags.espfigure = Value
		if not Value then
			for _, v in pairs(esptable.figure) do v.delete() end
			table.clear(esptable.figure)
			return
		end

		task.spawn(function()
			while flags.espfigure do
				local CurrentRooms = Workspace:FindFirstChild("CurrentRooms")
				if CurrentRooms then
					for _, room in pairs(CurrentRooms:GetChildren()) do
						if room.Name == "50" or room.Name == "100" then
							local FigureSetup = room:FindFirstChild("FigureSetup")
							if FigureSetup then
								local FigureRig = FigureSetup:FindFirstChild("FigureRig")
								if FigureRig then
									if not FigureRig:FindFirstChild("_KuromiESP_H") then
										local h = esp(FigureRig, Color3.fromRGB(255, 25, 25), FigureRig, "Figure")
										table.insert(esptable.figure, h)
									end
								end
							end
						end
					end
				end
				task.wait(1)
			end
		end)
	end
})

-- Locker / Closet ESP
ESPTab:CreateToggle({
	Name = "ESP Closets/Lockers",
	CurrentValue = false,
	Flag = "esp_lockers",
	Callback = function(Value)
		flags.esplocker = Value
		if not Value then return end

		local function check(v)
			if v:IsA("Model") then
				task.wait(0.1)
				if v.Name == "Wardrobe" then
					local h = esp(v.PrimaryPart, Color3.fromRGB(145, 100, 25), v.PrimaryPart, "Closet")
					table.insert(esptable.lockers, h)
				elseif v.Name == "Rooms_Locker" or v.Name == "Rooms_Locker_Fridge" then
					local h = esp(v.PrimaryPart, Color3.fromRGB(145, 100, 25), v.PrimaryPart, "Locker")
					table.insert(esptable.lockers, h)
				end
			end
		end

		local function setup(room)
			local assets = room:WaitForChild("Assets")
			if assets then
				local subaddcon
				subaddcon = assets.DescendantAdded:Connect(function(v)
					if flags.esplocker then check(v) end
				end)
				for _, v in pairs(assets:GetDescendants()) do
					check(v)
				end
				task.spawn(function()
					repeat task.wait() until not flags.esplocker
					subaddcon:Disconnect()
				end)
			end
		end

		local addconnect
		addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
			if flags.esplocker then setup(room) end
		end)

		for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
			if room:FindFirstChild("Assets") then setup(room) end
		end

		repeat task.wait() until not flags.esplocker
		addconnect:Disconnect()

		for _, v in pairs(esptable.lockers) do v.delete() end
		table.clear(esptable.lockers)
	end
})

-- Chest ESP
ESPTab:CreateToggle({
	Name = "ESP Chests",
	CurrentValue = false,
	Flag = "esp_chests",
	Callback = function(Value)
		flags.espchest = Value
		if not Value then return end

		local function check(v)
			if v:IsA("Model") then
				task.wait(0.1)
				if v.Name == "ChestBox" then
					local h = esp(v, Color3.fromRGB(205, 120, 255), v.PrimaryPart, "Chest")
					table.insert(esptable.chests, h)
				elseif v.Name == "ChestBoxLocked" then
					local h = esp(v, Color3.fromRGB(255, 120, 205), v.PrimaryPart, "Locked Chest")
					table.insert(esptable.chests, h)
				end
			end
		end

		local function setup(room)
			local subaddcon
			subaddcon = room.DescendantAdded:Connect(function(v)
				if flags.espchest then check(v) end
			end)
			for _, v in pairs(room:GetDescendants()) do
				check(v)
			end
			task.spawn(function()
				repeat task.wait() until not flags.espchest
				subaddcon:Disconnect()
			end)
		end

		local addconnect
		addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
			if flags.espchest then setup(room) end
		end)

		for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
			if room:FindFirstChild("Assets") then setup(room) end
		end

		repeat task.wait() until not flags.espchest
		addconnect:Disconnect()

		for _, v in pairs(esptable.chests) do v.delete() end
		table.clear(esptable.chests)
	end
})

-- Gold Pile ESP
ESPTab:CreateToggle({
	Name = "ESP Goldpiles",
	CurrentValue = false,
	Flag = "esp_gold",
	Callback = function(Value)
		flags.espgold = Value
		if not Value then return end

		local function check(v)
			if v:IsA("Model") then
				task.wait(0.1)
				local goldvalue = v:GetAttribute("GoldValue")
				if goldvalue and goldvalue >= goldespvalue then
					local hitbox = v:WaitForChild("Hitbox")
					local h = esp(hitbox:GetChildren(), Color3.fromRGB(255, 255, 0), hitbox, "GoldPile [" .. tostring(goldvalue) .. "]")
					table.insert(esptable.gold, h)
				end
			end
		end

		local function setup(room)
			local assets = room:WaitForChild("Assets")
			local subaddcon
			subaddcon = assets.DescendantAdded:Connect(function(v)
				if flags.espgold then check(v) end
			end)
			for _, v in pairs(assets:GetDescendants()) do
				check(v)
			end
			task.spawn(function()
				repeat task.wait() until not flags.espgold
				subaddcon:Disconnect()
			end)
		end

		local addconnect
		addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
			if flags.espgold then setup(room) end
		end)

		for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
			if room:FindFirstChild("Assets") then setup(room) end
		end

		repeat task.wait() until not flags.espgold
		addconnect:Disconnect()

		for _, v in pairs(esptable.gold) do v.delete() end
		table.clear(esptable.gold)
	end
})

-- Player ESP
ESPTab:CreateToggle({
	Name = "ESP Players",
	CurrentValue = false,
	Flag = "esp_players",
	Callback = function(Value)
		flags.esphumans = Value
		if not Value then return end

		local function personesp(v)
			v.CharacterAdded:Connect(function(vc)
				local torso = vc:WaitForChild("UpperTorso")
				task.wait(0.1)
				local h = esp(vc, Color3.fromRGB(255, 255, 255), torso, v.DisplayName)
				table.insert(esptable.people, h)
			end)

			if v.Character then
				local vc = v.Character
				local torso = vc:WaitForChild("UpperTorso")
				task.wait(0.1)
				local h = esp(vc, Color3.fromRGB(255, 255, 255), torso, v.DisplayName)
				table.insert(esptable.people, h)
			end
		end

		local addconnect
		addconnect = game.Players.PlayerAdded:Connect(function(v)
			if v ~= plr then personesp(v) end
		end)

		for _, v in pairs(game.Players:GetPlayers()) do
			if v ~= plr then personesp(v) end
		end

		repeat task.wait() until not flags.esphumans
		addconnect:Disconnect()

		for _, v in pairs(esptable.people) do v.delete() end
		table.clear(esptable.people)
	end
})


-- Movement Speed
local currentSpeed = 16

MiscTab:CreateSlider({
	Name = "Movement Speed",
	Range = {1, 21.5},
	Increment = 0.5,
	Suffix = " Speed",
	CurrentValue = 16,
	Flag = "misc_speed",
	Callback = function(value)
		currentSpeed = value
	end
})

task.spawn(function()
	while true do
		if plr.Character then
			local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.WalkSpeed ~= currentSpeed then
				humanoid.WalkSpeed = currentSpeed
			end
		end
		task.wait(0.1)
	end
end)

-- Auto Loot
MiscTab:CreateToggle({
	Name = "Auto Loot",
	CurrentValue = false,
	Flag = "misc_autoloot",
	Callback = function(Value)
		flags.draweraura = Value
		if not Value then return end

		local function check(v)
			if not v:IsA("Model") then return end

			local function tryLoot(prompt, posFunc)
				-- Only start a loop if the prompt hasn't already been used
				if prompt:GetAttribute("Interactions") then return end
				task.spawn(function()
					repeat
						task.wait(0.1)
						if plr:DistanceFromCharacter(posFunc()) <= 12 then
							fireproximityprompt(prompt)
						end
					until prompt:GetAttribute("Interactions") or not flags.draweraura
				end)
			end

			if v.Name == "DrawerContainer" then
				local knob = v:FindFirstChild("Knobs")
				if knob then
					local prompt = knob:FindFirstChild("ActivateEventPrompt")
					if prompt then
						tryLoot(prompt, function() return knob.Position end)
					end
				end

			elseif v.Name == "GoldPile" then
				local prompt = v:FindFirstChild("LootPrompt")
				if prompt and v.PrimaryPart then
					tryLoot(prompt, function() return v.PrimaryPart.Position end)
				end

			elseif v.Name:sub(1, 8) == "ChestBox" then
				local prompt = v:FindFirstChild("ActivateEventPrompt")
				if prompt and v.PrimaryPart then
					tryLoot(prompt, function() return v.PrimaryPart.Position end)
				end

			elseif v.Name == "RolltopContainer" then
				local prompt = v:FindFirstChild("ActivateEventPrompt")
				if prompt and v.PrimaryPart then
					tryLoot(prompt, function() return v.PrimaryPart.Position end)
				end
			end
		end

		local function setup(room)
			local subaddcon
			subaddcon = room.DescendantAdded:Connect(function(v)
				if flags.draweraura then check(v) end
			end)

			for _, v in pairs(room:GetDescendants()) do
				check(v)
			end

			task.spawn(function()
				repeat task.wait() until not flags.draweraura
				subaddcon:Disconnect()
			end)
		end

		local addconnect
		addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
			if flags.draweraura then setup(room) end
		end)

		for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
			if room:FindFirstChild("Assets") then
				setup(room)
			end
		end

		repeat task.wait() until not flags.draweraura
		addconnect:Disconnect()
	end
})

-- Notify Entities
MiscTab:CreateToggle({
	Name = "Notify Entities",
	CurrentValue = false,
	Flag = "misc_notify",
	Callback = function(Value)
		flags.hintrush = Value
		if not Value then return end

		local addconnect
		addconnect = workspace.ChildAdded:Connect(function(v)
			if table.find(entitynames, v.Name) then
				repeat task.wait() until plr:DistanceFromCharacter(v:GetPivot().Position) < 1000
					or not v:IsDescendantOf(workspace)

				if v:IsDescendantOf(workspace) then
					Rayfield:Notify({
						Title = "Entity Warning",
						Content = v.Name:gsub("Moving", ""):lower() .. " is coming, go hide!",
						Duration = 5,
					})
				end
			end
		end)

		repeat task.wait() until not flags.hintrush
		addconnect:Disconnect()
	end
})

-- Auto Library Code
MiscTab:CreateToggle({
	Name = "Auto Library Code",
	CurrentValue = false,
	Flag = "misc_libcode",
	Callback = function(Value)
		flags.getcode = Value
		if not Value then return end

		local function deciphercode()
			local paper = char:FindFirstChild("LibraryHintPaper")
			local hints = plr.PlayerGui:WaitForChild("PermUI"):WaitForChild("Hints")

			local code = {[1]="_",[2]="_",[3]="_",[4]="_",[5]="_"}

			if paper then
				for _, v in pairs(paper:WaitForChild("UI"):GetChildren()) do
					if v:IsA("ImageLabel") and v.Name ~= "Image" then
						for _, img in pairs(hints:GetChildren()) do
							if img:IsA("ImageLabel") and img.Visible
								and v.ImageRectOffset == img.ImageRectOffset then
								local num = img:FindFirstChild("TextLabel").Text
								code[tonumber(v.Name)] = num
							end
						end
					end
				end
			end

			return code
		end

		local addconnect
		addconnect = char.ChildAdded:Connect(function(v)
			if v:IsA("Tool") and v.Name == "LibraryHintPaper" then
				task.wait()
				local code = table.concat(deciphercode())

				if code:find("_") then
					Rayfield:Notify({
						Title = "Library Code",
						Content = "Get all hints first!",
						Duration = 5,
					})
				else
					Rayfield:Notify({
						Title = "Library Code",
						Content = "The code is: " .. code,
						Duration = 10,
					})
				end
			end
		end)

		repeat task.wait() until not flags.getcode
		addconnect:Disconnect()
	end
})

ConfigTab:CreateSection("Scan Intervals")

ConfigTab:CreateSlider({
	Name = "Door Scan Interval",
	Range = {1, 15},
	Increment = 1,
	Suffix = "s",
	CurrentValue = 3,
	Flag = "cfg_doorscan",
	Callback = function(value)
		doorScanInterval = value
	end
})

ConfigTab:CreateSlider({
	Name = "Min Gold Value (Goldpile ESP)",
	Range = {0, 500},
	Increment = 10,
	Suffix = " gold",
	CurrentValue = 0,
	Flag = "cfg_goldmin",
	Callback = function(value)
		goldespvalue = value
	end
})

local VisualTab = Window:CreateTab("Visuals", nil)

-- ---------- Fullbright ----------
local fbBackup, fbConn

VisualTab:CreateToggle({
	Name = "Fullbright",
	CurrentValue = false,
	Flag = "vis_fullbright",
	Callback = function(v)
		if v then
			fbBackup = {
				Brightness = Lighting.Brightness,
				ClockTime = Lighting.ClockTime,
				GlobalShadows = Lighting.GlobalShadows,
				Ambient = Lighting.Ambient,
				FogEnd = Lighting.FogEnd,
			}
			fbConn = RunService.RenderStepped:Connect(function()
				Lighting.Brightness = 2
				Lighting.ClockTime = 14
				Lighting.GlobalShadows = false
				Lighting.Ambient = Color3.fromRGB(170, 170, 170)
				Lighting.FogEnd = 1e9
			end)
		else
			if fbConn then fbConn:Disconnect() fbConn = nil end
			if fbBackup then
				for k, val in pairs(fbBackup) do
					Lighting[k] = val
				end
				fbBackup = nil
			end
		end
	end
})

-- ---------- FOV ----------
local fovEnabled = false
local fovValue = 70
local fovConn

VisualTab:CreateToggle({
	Name = "Custom FOV",
	CurrentValue = false,
	Flag = "vis_fov_toggle",
	Callback = function(v)
		fovEnabled = v
		if fovConn then fovConn:Disconnect() fovConn = nil end
		if v then
			fovConn = RunService.RenderStepped:Connect(function()
				local cam = Workspace.CurrentCamera
				if cam then cam.FieldOfView = fovValue end
			end)
		end
	end
})

VisualTab:CreateSlider({
	Name = "FOV",
	Range = {60, 120},
	Increment = 1,
	Suffix = "°",
	CurrentValue = 70,
	Flag = "vis_fov",
	Callback = function(value)
		fovValue = value
	end
})

-- ---------- Трейсеры к сущностям (нужен Drawing в экзекьюторе) ----------
local tracerConn
local tracerLines = {}

local function clearTracers()
	for _, line in pairs(tracerLines) do
		pcall(function() line:Remove() end)
	end
	table.clear(tracerLines)
end

VisualTab:CreateToggle({
	Name = "Tracers (Entities)",
	CurrentValue = false,
	Flag = "vis_tracers",
	Callback = function(v)
		if tracerConn then tracerConn:Disconnect() tracerConn = nil end
		clearTracers()
		if not v then return end

		if not (Drawing and Drawing.new) then
			Rayfield:Notify({
				Title = "Tracers",
				Content = "Твой экзекьютор не поддерживает Drawing",
				Duration = 5,
			})
			return
		end

		tracerConn = RunService.RenderStepped:Connect(function()
			local cam = Workspace.CurrentCamera
			if not cam then return end

			local vp = cam.ViewportSize
			local from = Vector2.new(vp.X / 2, vp.Y)

			for _, m in ipairs(Workspace:GetChildren()) do
				if m:IsA("Model") and isEntityName(m.Name) and not tracerLines[m] then
					local line = Drawing.new("Line")
					line.Thickness = 1.5
					line.Color = Color3.fromRGB(255, 25, 25)
					line.Transparency = 1
					line.Visible = false
					tracerLines[m] = line
				end
			end

			for m, line in pairs(tracerLines) do
				if not m.Parent then
					pcall(function() line:Remove() end)
					tracerLines[m] = nil
				else
					local pos, onScreen = cam:WorldToViewportPoint(m:GetPivot().Position)
					if onScreen and pos.Z > 0 then
						line.From = from
						line.To = Vector2.new(pos.X, pos.Y)
						line.Visible = true
					else
						line.Visible = false
					end
				end
			end
		end)
	end
})

-- ---------- Логгер имён: показывает РЕАЛЬНЫЕ имена новых объектов в workspace ----------
-- Включи, дождись сущности и посмотри консоль (F9) или уведомление.
local loggerOn = false

Workspace.ChildAdded:Connect(function(c)
	if not loggerOn then return end
	print("[ENTITY LOG] " .. c.Name .. " (" .. c.ClassName .. ")")
	Rayfield:Notify({
		Title = "Новый объект",
		Content = c.Name .. " [" .. c.ClassName .. "]",
		Duration = 4,
	})
end)

MiscTab:CreateToggle({
	Name = "Entity Name Logger",
	CurrentValue = false,
	Flag = "misc_logger",
	Callback = function(v)
		loggerOn = v
	end
})

-- ---------- Очистка для твоей существующей выгрузки ----------
-- Вызови visualsCleanup() в своей функции выгрузки.
local function visualsCleanup()
	if fbConn then fbConn:Disconnect() fbConn = nil end
	if fbBackup then
		for k, val in pairs(fbBackup) do
			Lighting[k] = val
		end
		fbBackup = nil
	end
	if fovConn then fovConn:Disconnect() fovConn = nil end
	if tracerConn then tracerConn:Disconnect() tracerConn = nil end
	clearTracers()
	loggerOn = false
end

InfoTab:CreateParagraph({
	Title = "Wilset Doors",
	Content = "Hi.. I hope you're enjoying this Script I made. my GitHub Repo a star or contribute: https://github.com/HorusWawe"
})
InfoTab:CreateDivider()
InfoTab:CreateParagraph({
	Title = "Last Updated",
	Content = "17th oct 2026"
})
InfoTab:CreateParagraph({
	Title = "By The Way",
	Content = "I am aware about the two buttons; ESP Entites and ESP Figure. I will merge the two functions when i have time to do so. "
})
InfoTab:CreateDivider()
InfoTab:CreateParagraph({
	Title = "To Do List",
	Content = "Toolshed ESP: add highlight to Toolshed_Small in Room 89 ?  Snare ESP: add highlight to each snare"
})
