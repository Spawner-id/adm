-- Visual Pet Spawner for Adopt Me (LocalScript - place in StarterPlayer > StarterCharacterScripts)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = script.Parent

-- Wait for character to load
local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
if not humanoidRootPart then
	warn("HumanoidRootPart not found")
	return
end

-- Wait for PlayerGui
repeat task.wait() until player:FindFirstChild("PlayerGui")
local playerGui = player.PlayerGui

-- Get Adopt Me services
local replicatedStorage = game:GetService("ReplicatedStorage")
local clientData, playerData, petInventory

-- Safe loading with error handling
local success, err = pcall(function()
	local fsys = require(replicatedStorage:WaitForChild("Fsys", 5))
	clientData = fsys.load("ClientData")
	
	-- Get player data
	local allData = clientData.get()
	playerData = allData.inventory
	petInventory = playerData.pets or {}
end)

if not success then
	warn("Failed to load pet data:", err)
	petInventory = {}
end

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

-- Create simple pet model
local function createPet(petData)
	local pet = Instance.new("Part")
	pet.Name = "VisualPet"
	pet.Size = Vector3.new(2, 2, 2)
	pet.Color = Color3.fromRGB(255, 150, 200)
	pet.Material = Enum.Material.SmoothPlastic
	pet.CanCollide = false
	pet.Anchored = true
	pet.CastShadow = true
	
	-- Add basic mesh
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1, 1.2)
	mesh.Parent = pet
	
	-- Add glow effect
	local glow = Instance.new("Part")
	glow.Name = "Glow"
	glow.Size = pet.Size * 1.2
	glow.Color = pet.Color
	glow.Material = Enum.Material.Neon
	glow.Transparency = 0.6
	glow.CanCollide = false
	glow.Anchored = true
	glow.CastShadow = false
	
	local glowMesh = Instance.new("SpecialMesh")
	glowMesh.MeshType = Enum.MeshType.Sphere
	glowMesh.Parent = glow
	glow.Parent = pet
	
	-- Add face
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 100)
	billboard.Adornee = pet
	billboard.AlwaysOnTop = true
	billboard.Parent = pet
	
	local face = Instance.new("TextLabel")
	face.Size = UDim2.new(1, 0, 1, 0)
	face.BackgroundTransparency = 1
	face.Text = "😊"
	face.TextSize = 60
	face.Parent = billboard
	
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

-- Spawn pet
local function spawnPet(petId, petData)
	despawnPet()
	
	local pet = createPet(petData)
	
	-- Check if flyable
	local isFlying = false
	if petData and type(petData) == "table" then
		if petData.flyable or petData.fly then
			isFlying = true
		end
	end
	
	currentPet = {
		pet = pet,
		data = petData,
		isFlying = isFlying,
	}
	
	-- Start following
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
		local glow = pet:FindFirstChild("Glow")
		local isFlying = currentPet.isFlying
		
		local rootPos = humanoidRootPart.Position
		local rootCFrame = humanoidRootPart.CFrame
		local velocity = humanoidRootPart.AssemblyLinearVelocity
		local isMoving = velocity.Magnitude > 1
		
		-- Target position
		local backwardOffset = -rootCFrame.LookVector * SETTINGS.FollowDistance
		local targetPos = rootPos + backwardOffset
		
		-- Height
		local heightOffset = isFlying and SETTINGS.FlyingHeight or SETTINGS.FollowHeight
		targetPos = targetPos + Vector3.new(0, heightOffset, 0)
		
		-- Bobbing
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
		
		-- Flying tilt
		if isFlying then
			pet.CFrame = pet.CFrame * CFrame.Angles(math.rad(15), 0, math.sin(bobTime) * 0.1)
		end
		
		-- Update glow
		if glow then
			glow.CFrame = pet.CFrame
		end
	end)
	
	return true, "Pet spawned!"
end

-- Create GUI
local function createGUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PetSpawnerGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 400, 0, 350)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -175)
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
	
	-- Pet count label
	local petCount = 0
	if petInventory then
		for _ in pairs(petInventory) do
			petCount = petCount + 1
		end
	end
	
	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1, -40, 0, 30)
	countLabel.Position = UDim2.new(0, 20, 0, 70)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = "Pets Found: " .. petCount
	countLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	countLabel.TextSize = 16
	countLabel.Font = Enum.Font.Gotham
	countLabel.TextXAlignment = Enum.TextXAlignment.Left
	countLabel.Parent = mainFrame
	
	-- Scroll Frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -180)
	scrollFrame.Position = UDim2.new(0, 10, 0, 105)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.Parent = mainFrame
	
	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scrollFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = scrollFrame
	
	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 8)
	listPadding.PaddingLeft = UDim.new(0, 8)
	listPadding.PaddingRight = UDim.new(0, 8)
	listPadding.Parent = scrollFrame
	
	-- Add pets to list
	local itemCount = 0
	if petInventory and type(petInventory) == "table" then
		for petId, petData in pairs(petInventory) do
			itemCount = itemCount + 1
			
			local petButton = Instance.new("TextButton")
			petButton.Size = UDim2.new(1, -10, 0, 50)
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
			petName.Size = UDim2.new(1, -60, 1, 0)
			petName.Position = UDim2.new(0, 10, 0, 0)
			petName.BackgroundTransparency = 1
			petName.Text = "Pet ID: " .. tostring(petId)
			petName.TextColor3 = Color3.fromRGB(255, 255, 255)
			petName.TextSize = 16
			petName.Font = Enum.Font.GothamBold
			petName.TextXAlignment = Enum.TextXAlignment.Left
			petName.Parent = petButton
			
			-- Spawn button
			local spawnBtn = Instance.new("TextButton")
			spawnBtn.Size = UDim2.new(0, 45, 0, 35)
			spawnBtn.Position = UDim2.new(1, -52, 0.5, -17.5)
			spawnBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
			spawnBtn.Text = "✓"
			spawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			spawnBtn.TextSize = 18
			spawnBtn.Font = Enum.Font.GothamBold
			spawnBtn.Parent = petButton
			
			local spawnBtnCorner = Instance.new("UICorner")
			spawnBtnCorner.CornerRadius = UDim.new(0, 6)
			spawnBtnCorner.Parent = spawnBtn
			
			-- Click handler
			spawnBtn.MouseButton1Click:Connect(function()
				local success, msg = spawnPet(petId, petData)
				statusLabel.Text = msg
				statusLabel.TextColor3 = success and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
			end)
			
			-- Hover
			petButton.MouseEnter:Connect(function()
				petButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			end)
			petButton.MouseLeave:Connect(function()
				petButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			end)
		end
	end
	
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, itemCount * 55 + 16)
	
	-- Despawn button
	local despawnBtn = Instance.new("TextButton")
	despawnBtn.Size = UDim2.new(1, -40, 0, 45)
	despawnBtn.Position = UDim2.new(0, 20, 1, -55)
	despawnBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	despawnBtn.Text = "✕ Remove Pet"
	despawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	despawnBtn.TextSize = 18
	despawnBtn.Font = Enum.Font.GothamBold
	despawnBtn.Parent = mainFrame
	
	local despawnBtnCorner = Instance.new("UICorner")
	despawnBtnCorner.CornerRadius = UDim.new(0, 8)
	despawnBtnCorner.Parent = despawnBtn
	
	-- Status label
	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -40, 0, 25)
	statusLabel.Position = UDim2.new(0, 20, 1, -85)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Select a pet to spawn"
	statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	statusLabel.TextSize = 14
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = mainFrame
	
	despawnBtn.MouseButton1Click:Connect(function()
		despawnPet()
		statusLabel.Text = "Pet removed!"
		statusLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
	end)
	
	screenGui.Parent = playerGui
	print("✅ Pet Spawner loaded with " .. petCount .. " pets!")
end

-- Wait a bit for everything to load
task.wait(2)
createGUI()

-- Cleanup on death
local humanoid = character:FindFirstChild("Humanoid")
if humanoid then
	humanoid.Died:Connect(function()
		despawnPet()
	end)
end
