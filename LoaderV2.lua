-- Visual Pet Spawner for Adopt Me Pets (LocalScript - place in StarterPlayer > StarterCharacterScripts)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = script.Parent
local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
local playerGui = player:WaitForChild("PlayerGui", 10)

-- Safety check
if not humanoidRootPart or not playerGui then
	warn("Failed to load character components")
	return
end

-- Get player's pet inventory
local clientData = require(ReplicatedStorage.ClientModules.Core.ClientData)
local playerData = clientData.get_data()[tostring(player)]
local petInventory = playerData.inventory.pets

-- Settings
local SETTINGS = {
	FollowDistance = 4,
	FollowHeight = 0.5,
	FlyingHeight = 3,
	FollowSpeed = 0.2,
	RotationSpeed = 0.15,
	BobHeight = 0.3,
	BobSpeed = 3,
	SidewaysBob = 0.2,
}

-- Current spawned pet
local currentPet = nil
local petConnection = nil
local bobTime = 0

-- Create pet model from Adopt Me data
local function createPet(petData)
	local pet = Instance.new("Part")
	pet.Name = "Pet_" .. (petData.id or "Unknown")
	pet.Size = Vector3.new(2, 2, 2)
	pet.Color = Color3.fromRGB(255, 255, 255)
	pet.Material = Enum.Material.SmoothPlastic
	pet.CanCollide = false
	pet.Anchored = true
	pet.CastShadow = true
	
	-- Try to get pet appearance from properties
	if petData.properties then
		local props = petData.properties
		
		-- Add mesh if available
		if props.mesh_id or props.MeshId then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = "rbxassetid://" .. (props.mesh_id or props.MeshId)
			if props.texture_id or props.TextureId then
				mesh.TextureId = "rbxassetid://" .. (props.texture_id or props.TextureId)
			end
			mesh.Parent = pet
		end
	end
	
	-- Add neon glow if it's a neon pet
	if petData.neon or (petData.properties and petData.properties.neon) then
		local glow = Instance.new("Part")
		glow.Name = "NeonGlow"
		glow.Size = pet.Size * 1.15
		glow.Color = Color3.fromRGB(100, 255, 255)
		glow.Material = Enum.Material.Neon
		glow.Transparency = 0.5
		glow.CanCollide = false
		glow.Anchored = true
		glow.CastShadow = false
		
		local glowMesh = Instance.new("SpecialMesh")
		glowMesh.MeshType = Enum.MeshType.Sphere
		glowMesh.Parent = glow
		glow.Parent = pet
	end
	
	pet.Parent = workspace
	return pet
end

-- Despawn current pet
local function despawnPet()
	if currentPet and currentPet.pet then
		currentPet.pet:Destroy()
	end
	if petConnection then
		petConnection:Disconnect()
	end
	currentPet = nil
	bobTime = 0
end

-- Spawn pet by unique ID
local function spawnPet(petUniqueId)
	-- Despawn existing pet
	despawnPet()
	
	-- Find pet in inventory by unique ID
	local petData = nil
	for i, v in pairs(petInventory) do
		if v.unique == petUniqueId or i == petUniqueId then
			petData = v
			break
		end
	end
	
	if not petData then
		warn("Pet not found: " .. tostring(petUniqueId))
		return false, "Pet not found in inventory!"
	end
	
	-- Create pet
	local pet = createPet(petData)
	local isFlying = petData.properties and (petData.properties.flyable or petData.properties.fly)
	
	currentPet = {
		pet = pet,
		data = petData,
		isFlying = isFlying,
	}
	
	-- Start following behavior
	petConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not character or not character.Parent then
			despawnPet()
			return
		end
		
		if not humanoidRootPart or not humanoidRootPart.Parent then
			return
		end
		
		if not currentPet or not currentPet.pet or not currentPet.pet.Parent then
			return
		end
		
		local pet = currentPet.pet
		local glow = pet:FindFirstChild("NeonGlow")
		local isFlying = currentPet.isFlying
		
		local rootPos = humanoidRootPart.Position
		local rootCFrame = humanoidRootPart.CFrame
		local velocity = humanoidRootPart.AssemblyLinearVelocity
		local isMoving = velocity.Magnitude > 1
		
		-- Calculate target position
		local backwardOffset = -rootCFrame.LookVector * SETTINGS.FollowDistance
		local targetPos = rootPos + backwardOffset
		
		-- Height based on pet type
		local heightOffset = isFlying and SETTINGS.FlyingHeight or SETTINGS.FollowHeight
		targetPos = targetPos + Vector3.new(0, heightOffset, 0)
		
		-- Bobbing animation
		bobTime = bobTime + deltaTime * SETTINGS.BobSpeed * (isMoving and 1.5 or 1)
		local bobOffset = math.sin(bobTime) * SETTINGS.BobHeight * (isFlying and 1.5 or 1)
		local sidewaysOffset = math.cos(bobTime * 0.5) * SETTINGS.SidewaysBob
		
		targetPos = targetPos + Vector3.new(sidewaysOffset, bobOffset, 0)
		
		-- Smooth movement
		local currentPos = pet.Position
		local newPos = currentPos:Lerp(targetPos, SETTINGS.FollowSpeed)
		
		-- Rotation
		local moveDirection = (targetPos - currentPos).Unit
		if moveDirection.Magnitude > 0.1 then
			local targetCFrame = CFrame.lookAt(newPos, newPos + moveDirection)
			pet.CFrame = pet.CFrame:Lerp(targetCFrame, SETTINGS.RotationSpeed)
		else
			pet.CFrame = CFrame.new(newPos) * pet.CFrame.Rotation
		end
		
		-- Flying pets tilt
		if isFlying then
			pet.CFrame = pet.CFrame * CFrame.Angles(math.rad(15), 0, math.sin(bobTime) * 0.1)
		end
		
		-- Update glow
		if glow then
			glow.CFrame = pet.CFrame
		end
	end)
	
	local petName = petData.id or petData.name or "Pet"
	return true, "Spawned " .. petName .. "!"
end

-- Create Spawner GUI
local function createSpawnerGUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PetSpawnerGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 450, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -225, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 60)
	title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	title.BorderSizePixel = 0
	title.Text = "🐾 My Pet Inventory"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 26
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 15)
	titleCorner.Parent = title
	
	-- Scroll Frame for pets
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -140)
	scrollFrame.Position = UDim2.new(0, 10, 0, 70)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.Parent = mainFrame
	
	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scrollFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = scrollFrame
	
	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 10)
	listPadding.PaddingLeft = UDim.new(0, 10)
	listPadding.PaddingRight = UDim.new(0, 10)
	listPadding.Parent = scrollFrame
	
	-- Create pet list items
	local petCount = 0
	for uniqueId, petData in pairs(petInventory) do
		petCount = petCount + 1
		
		local petButton = Instance.new("TextButton")
		petButton.Size = UDim2.new(1, -10, 0, 60)
		petButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		petButton.BorderSizePixel = 0
		petButton.Text = ""
		petButton.AutoButtonColor = false
		petButton.Parent = scrollFrame
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = petButton
		
		-- Pet name
		local petName = Instance.new("TextLabel")
		petName.Size = UDim2.new(1, -70, 0, 25)
		petName.Position = UDim2.new(0, 15, 0, 8)
		petName.BackgroundTransparency = 1
		petName.Text = petData.id or petData.name or "Pet #" .. petCount
		petName.TextColor3 = Color3.fromRGB(255, 255, 255)
		petName.TextSize = 18
		petName.Font = Enum.Font.GothamBold
		petName.TextXAlignment = Enum.TextXAlignment.Left
		petName.Parent = petButton
		
		-- Pet info
		local petInfo = Instance.new("TextLabel")
		petInfo.Size = UDim2.new(1, -70, 0, 20)
		petInfo.Position = UDim2.new(0, 15, 0, 33)
		petInfo.BackgroundTransparency = 1
		local infoText = "Unique: " .. tostring(uniqueId)
		if petData.properties then
			if petData.properties.flyable then
				infoText = infoText .. " | ✈️ Flyable"
			end
			if petData.properties.rideable then
				infoText = infoText .. " | 🏇 Rideable"
			end
			if petData.properties.neon or petData.neon then
				infoText = infoText .. " | ✨ Neon"
			end
		end
		petInfo.Text = infoText
		petInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
		petInfo.TextSize = 12
		petInfo.Font = Enum.Font.Gotham
		petInfo.TextXAlignment = Enum.TextXAlignment.Left
		petInfo.Parent = petButton
		
		-- Spawn button
		local spawnBtn = Instance.new("TextButton")
		spawnBtn.Size = UDim2.new(0, 50, 0, 40)
		spawnBtn.Position = UDim2.new(1, -60, 0.5, -20)
		spawnBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
		spawnBtn.Text = "✓"
		spawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		spawnBtn.TextSize = 20
		spawnBtn.Font = Enum.Font.GothamBold
		spawnBtn.Parent = petButton
		
		local spawnBtnCorner = Instance.new("UICorner")
		spawnBtnCorner.CornerRadius = UDim.new(0, 6)
		spawnBtnCorner.Parent = spawnBtn
		
		-- Click to spawn
		spawnBtn.MouseButton1Click:Connect(function()
			local success, message = spawnPet(uniqueId)
			if success then
				statusLabel.Text = message
				statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			else
				statusLabel.Text = message
				statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			end
		end)
		
		-- Hover effect
		petButton.MouseEnter:Connect(function()
			petButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		end)
		
		petButton.MouseLeave:Connect(function()
			petButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		end)
	end
	
	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, petCount * 68 + 20)
	
	-- Despawn Button
	local despawnBtn = Instance.new("TextButton")
	despawnBtn.Size = UDim2.new(1, -40, 0, 50)
	despawnBtn.Position = UDim2.new(0, 20, 1, -65)
	despawnBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	despawnBtn.BorderSizePixel = 0
	despawnBtn.Text = "✕ Remove Current Pet"
	despawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	despawnBtn.TextSize = 18
	despawnBtn.Font = Enum.Font.GothamBold
	despawnBtn.Parent = mainFrame
	
	local despawnBtnCorner = Instance.new("UICorner")
	despawnBtnCorner.CornerRadius = UDim.new(0, 8)
	despawnBtnCorner.Parent = despawnBtn
	
	-- Status Label
	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -40, 0, 30)
	statusLabel.Position = UDim2.new(0, 20, 1, -100)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Select a pet to spawn"
	statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	statusLabel.TextSize = 14
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = mainFrame
	
	-- Despawn button click
	despawnBtn.MouseButton1Click:Connect(function()
		despawnPet()
		statusLabel.Text = "Pet removed!"
		statusLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
	end)
	
	screenGui.Parent = playerGui
	print("✅ Pet Spawner GUI loaded with " .. petCount .. " pets!")
end

-- Create the GUI
createSpawnerGUI()

-- Cleanup on death
local humanoid = character:FindFirstChild("Humanoid")
if humanoid then
	humanoid.Died:Connect(function()
		despawnPet()
	end)
end
