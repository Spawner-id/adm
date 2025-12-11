-- Visual Pet Spawner with Input UI (LocalScript - place in StarterPlayer > StarterCharacterScripts)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = script.Parent
local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
local playerGui = player:WaitForChild("PlayerGui", 10)

-- Safety check
if not humanoidRootPart or not playerGui then
	warn("Failed to load character components")
	return
end

-- Pet Library
local PET_LIBRARY = {
	["cat"] = {
		Name = "Cat",
		Type = "Ground",
		MeshId = "rbxassetid://6828454591",
		Size = Vector3.new(1.5, 1.5, 2),
		Color = Color3.fromRGB(255, 170, 127),
	},
	["dog"] = {
		Name = "Dog",
		Type = "Ground",
		MeshId = "rbxassetid://6828454591",
		Size = Vector3.new(2, 1.8, 2.5),
		Color = Color3.fromRGB(139, 90, 43),
	},
	["dragon"] = {
		Name = "Dragon",
		Type = "Flying",
		MeshId = "rbxassetid://6828454591",
		Size = Vector3.new(2.5, 2, 3),
		Color = Color3.fromRGB(255, 50, 50),
	},
	["phoenix"] = {
		Name = "Phoenix",
		Type = "Flying",
		MeshId = "rbxassetid://6828454591",
		Size = Vector3.new(2.2, 2, 2.8),
		Color = Color3.fromRGB(255, 140, 0),
	},
	["unicorn"] = {
		Name = "Unicorn",
		Type = "Ground",
		MeshId = "rbxassetid://6828454591",
		Size = Vector3.new(2, 2.2, 2.5),
		Color = Color3.fromRGB(255, 192, 203),
	},
}

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

-- Create pet model
local function createPet(petData)
	local pet = Instance.new("Part")
	pet.Name = "Pet_" .. petData.Name
	pet.Size = petData.Size
	pet.Color = petData.Color
	pet.Material = Enum.Material.SmoothPlastic
	pet.CanCollide = false
	pet.Anchored = true
	pet.CastShadow = true
	
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = petData.MeshId
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = pet
	
	-- Add glow effect
	local glow = Instance.new("Part")
	glow.Name = "Glow"
	glow.Size = petData.Size * 1.15
	glow.Color = petData.Color
	glow.Material = Enum.Material.Neon
	glow.Transparency = 0.6
	glow.CanCollide = false
	glow.Anchored = true
	glow.CastShadow = false
	
	local glowMesh = Instance.new("SpecialMesh")
	glowMesh.MeshType = Enum.MeshType.Sphere
	glowMesh.Parent = glow
	glow.Parent = pet
	
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

-- Spawn new pet
local function spawnPet(petName)
	-- Despawn existing pet
	despawnPet()
	
	-- Find pet data
	local petData = PET_LIBRARY[petName:lower()]
	if not petData then
		warn("Pet not found: " .. petName)
		return false, "Pet '" .. petName .. "' not found!"
	end
	
	-- Create pet
	local pet = createPet(petData)
	currentPet = {
		pet = pet,
		data = petData,
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
		local data = currentPet.data
		local glow = pet:FindFirstChild("Glow")
		local isFlying = data.Type == "Flying"
		
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
	
	return true, "Spawned " .. petData.Name .. "!"
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
	mainFrame.Size = UDim2.new(0, 400, 0, 280)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -140)
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
	title.Text = "🐾 Pet Spawner"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 26
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 15)
	titleCorner.Parent = title
	
	-- Input Label
	local inputLabel = Instance.new("TextLabel")
	inputLabel.Size = UDim2.new(1, -40, 0, 30)
	inputLabel.Position = UDim2.new(0, 20, 0, 80)
	inputLabel.BackgroundTransparency = 1
	inputLabel.Text = "Enter Pet Name:"
	inputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	inputLabel.TextSize = 16
	inputLabel.Font = Enum.Font.Gotham
	inputLabel.TextXAlignment = Enum.TextXAlignment.Left
	inputLabel.Parent = mainFrame
	
	-- Text Input Box
	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(1, -40, 0, 45)
	textBox.Position = UDim2.new(0, 20, 0, 115)
	textBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	textBox.BorderSizePixel = 0
	textBox.PlaceholderText = "e.g., cat, dog, dragon..."
	textBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	textBox.Text = ""
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.TextSize = 18
	textBox.Font = Enum.Font.Gotham
	textBox.ClearTextOnFocus = false
	textBox.Parent = mainFrame
	
	local textBoxCorner = Instance.new("UICorner")
	textBoxCorner.CornerRadius = UDim.new(0, 8)
	textBoxCorner.Parent = textBox
	
	-- Spawn Button
	local spawnBtn = Instance.new("TextButton")
	spawnBtn.Size = UDim2.new(0, 160, 0, 45)
	spawnBtn.Position = UDim2.new(0, 20, 0, 175)
	spawnBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
	spawnBtn.BorderSizePixel = 0
	spawnBtn.Text = "✓ Spawn Pet"
	spawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	spawnBtn.TextSize = 18
	spawnBtn.Font = Enum.Font.GothamBold
	spawnBtn.Parent = mainFrame
	
	local spawnBtnCorner = Instance.new("UICorner")
	spawnBtnCorner.CornerRadius = UDim.new(0, 8)
	spawnBtnCorner.Parent = spawnBtn
	
	-- Despawn Button
	local despawnBtn = Instance.new("TextButton")
	despawnBtn.Size = UDim2.new(0, 160, 0, 45)
	despawnBtn.Position = UDim2.new(1, -180, 0, 175)
	despawnBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	despawnBtn.BorderSizePixel = 0
	despawnBtn.Text = "✕ Remove Pet"
	despawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	despawnBtn.TextSize = 18
	despawnBtn.Font = Enum.Font.GothamBold
	despawnBtn.Parent = mainFrame
	
	local despawnBtnCorner = Instance.new("UICorner")
	despawnBtnCorner.CornerRadius = UDim.new(0, 8)
	despawnBtnCorner.Parent = despawnBtn
	
	-- Status Label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -40, 0, 30)
	statusLabel.Position = UDim2.new(0, 20, 0, 235)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Available: cat, dog, dragon, phoenix, unicorn"
	statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	statusLabel.TextSize = 12
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextWrapped = true
	statusLabel.Parent = mainFrame
	
	-- Spawn Button Click
	spawnBtn.MouseButton1Click:Connect(function()
		local petName = textBox.Text
		if petName == "" then
			statusLabel.Text = "⚠️ Please enter a pet name!"
			statusLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
			return
		end
		
		local success, message = spawnPet(petName)
		statusLabel.Text = message
		if success then
			statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			textBox.Text = ""
		else
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	end)
	
	-- Despawn Button Click
	despawnBtn.MouseButton1Click:Connect(function()
		despawnPet()
		statusLabel.Text = "Pet removed!"
		statusLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
	end)
	
	-- Enter key to spawn
	textBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			spawnBtn.MouseButton1Click:Fire()
		end
	end)
	
	screenGui.Parent = playerGui
end

createSpawnerGUI()

-- Cleanup on death
local humanoid = character:FindFirstChild("Humanoid")
if humanoid then
	humanoid.Died:Connect(function()
		despawnPet()
	end)
end

print("✅ Pet Spawner loaded! Use the GUI to spawn pets")
