local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local PickaxeStorage = DataStoreService:GetDataStore("PickaxeSaveSystem")

-- Save the player's owned pickaxes
local function saveData(player)
	local ownedpicks = {}
	local folder = player:FindFirstChild("OwnedPickaxes")
	if folder then
		for i, v in pairs(folder:GetChildren()) do
			if v:IsA("StringValue") then
				table.insert(ownedpicks, v.Value)
			end
		end
	end

	local success, err = pcall(function()
		PickaxeStorage:SetAsync(player.UserId .. "_Data", {Pickaxes = ownedpicks })
	end)

	if not success then
		warn("Failed to save: ", player.Name, err)
	end
end

-- Load data when the player joins
Players.PlayerAdded:Connect(function(player)
	local folder = Instance.new("Folder")
	folder.Name = "OwnedPickaxes"
	folder.Parent = player

	local success, data = pcall(function()
		return PickaxeStorage:GetAsync(player.UserId .. "_Data")
	end)

	local hasPickaxe = false

	-- Check if player already owns a "Pickaxe"
	for i, v in ipairs(data.Pickaxes) do
		if v == "Pickaxe" then
			hasPickaxe = true
			break
		end
	end

	-- If data loaded successfully and contains pickaxes
	if success and data and data.Pickaxes and hasPickaxe == true then
		print("successfully loaded player's owned pickaxes")
		for i, v in pairs(data.Pickaxes) do
			local value = Instance.new("StringValue")
			value.Name = v
			value.Value = v
			value.Parent = folder
		end
	else
		-- New player gets a default "Pickaxe"
		print("New player (no pickaxe)")
		local starter = Instance.new("StringValue")
		starter.Name = "Pickaxe"
		starter.Value = "Pickaxe"
		starter.Parent = folder
	end
end)

-- Save data when the player leaves
Players.PlayerRemoving:Connect(saveData)
