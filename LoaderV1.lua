-- Infinite Loading Screen for Roblox Executor
-- Run this in any game using your executor

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InfiniteLoadingScreen"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999 -- Makes sure it's on top of everything
screenGui.Parent = playerGui

-- Create background frame
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.Position = UDim2.new(0, 0, 0, 0)
background.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
background.BorderSizePixel = 0
background.ZIndex = 10
background.Parent = screenGui

-- Create loading container
local loadingContainer = Instance.new("Frame")
loadingContainer.Name = "LoadingContainer"
loadingContainer.Size = UDim2.new(0, 400, 0, 300)
loadingContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
loadingContainer.AnchorPoint = Vector2.new(0.5, 0.5)
loadingContainer.BackgroundTransparency = 1
loadingContainer.ZIndex = 11
loadingContainer.Parent = background

-- Create spinner (circle that rotates)
local spinner = Instance.new("Frame")
spinner.Name = "Spinner"
spinner.Size = UDim2.new(0, 80, 0, 80)
spinner.Position = UDim2.new(0.5, 0, 0.3, 0)
spinner.AnchorPoint = Vector2.new(0.5, 0.5)
spinner.BackgroundTransparency = 1
spinner.ZIndex = 12
spinner.Parent = loadingContainer

-- Create the spinner arc
local spinnerImage = Instance.new("ImageLabel")
spinnerImage.Size = UDim2.new(1, 0, 1, 0)
spinnerImage.BackgroundTransparency = 1
spinnerImage.Image = "rbxassetid://4965945816" -- Loading circle
spinnerImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
spinnerImage.ZIndex = 12
spinnerImage.Parent = spinner

-- Rotate spinner infinitely
local rotationSpeed = 2
game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
    spinner.Rotation = spinner.Rotation + (360 * deltaTime * rotationSpeed)
end)

-- Create title text
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 60)
titleLabel.Position = UDim2.new(0, 0, 0.5, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Loading"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 42
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextStrokeTransparency = 0.5
titleLabel.ZIndex = 12
titleLabel.Parent = loadingContainer

-- Create status text
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 0.65, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Please wait..."
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.TextSize = 20
statusLabel.Font = Enum.Font.Gotham
statusLabel.ZIndex = 12
statusLabel.Parent = loadingContainer

-- Create percentage text (fake progress)
local percentLabel = Instance.new("TextLabel")
percentLabel.Name = "PercentLabel"
percentLabel.Size = UDim2.new(1, 0, 0, 25)
percentLabel.Position = UDim2.new(0, 0, 0.75, 0)
percentLabel.BackgroundTransparency = 1
percentLabel.Text = "0%"
percentLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
percentLabel.TextSize = 18
percentLabel.Font = Enum.Font.Gotham
percentLabel.ZIndex = 12
percentLabel.Parent = loadingContainer

-- Animate dots
spawn(function()
    while true do
        for i = 1, 3 do
            titleLabel.Text = "Loading" .. string.rep(".", i)
            wait(0.5)
        end
    end
end)

-- Fake progress that never reaches 100%
spawn(function()
    local progress = 0
    while true do
        wait(0.3)
        progress = progress + math.random(1, 3)
        if progress >= 99 then
            progress = 99 -- Never reaches 100%
        end
        percentLabel.Text = progress .. "%"
    end
end)

-- Pulse animation for status text
spawn(function()
    while true do
        for i = 0, 1, 0.05 do
            statusLabel.TextTransparency = i
            wait(0.03)
        end
        for i = 1, 0, -0.05 do
            statusLabel.TextTransparency = i
            wait(0.03)
        end
    end
end)

print("Infinite loading screen active! It will never finish loading...")
-- This loading screen will never end and blocks the entire screen!
