local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local naturalEventStarted = remotes:WaitForChild("NaturalEventStarted")
local naturalEventEnded = remotes:WaitForChild("NaturalEventEnded")
local getCurrentEvent = remotes:WaitForChild("GetCurrentEvent")

local currentEvent = nil
local eventEndTime = 0

-- Creates and returns the GUI used for natural events
local function createEventGUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NaturalEventsGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local notificationFrame = Instance.new("Frame")
	notificationFrame.Name = "NotificationFrame"
	notificationFrame.Size = UDim2.new(0, 400, 0, 120)
	notificationFrame.Position = UDim2.new(0.5, -200, 0, -130)
	notificationFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	notificationFrame.BorderSizePixel = 0
	notificationFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = notificationFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 100, 255)
	stroke.Thickness = 2
	stroke.Parent = notificationFrame

	local eventIcon = Instance.new("TextLabel")
	eventIcon.Name = "EventIcon"
	eventIcon.Size = UDim2.new(0, 60, 0, 60)
	eventIcon.Position = UDim2.new(0, 15, 0.5, -30)
	eventIcon.BackgroundTransparency = 1
	eventIcon.Text = "🌟"
	eventIcon.TextScaled = true
	eventIcon.Font = Enum.Font.SourceSansBold
	eventIcon.Parent = notificationFrame

	local eventTitle = Instance.new("TextLabel")
	eventTitle.Name = "EventTitle"
	eventTitle.Size = UDim2.new(1, -90, 0, 30)
	eventTitle.Position = UDim2.new(0, 85, 0, 15)
	eventTitle.BackgroundTransparency = 1
	eventTitle.Text = "Natural Event"
	eventTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	eventTitle.TextScaled = true
	eventTitle.Font = Enum.Font.SourceSansBold
	eventTitle.TextXAlignment = Enum.TextXAlignment.Left
	eventTitle.Parent = notificationFrame

	local eventDescription = Instance.new("TextLabel")
	eventDescription.Name = "EventDescription"
	eventDescription.Size = UDim2.new(1, -90, 0, 50)
	eventDescription.Position = UDim2.new(0, 85, 0, 45)
	eventDescription.BackgroundTransparency = 1
	eventDescription.Text = "A mystical event has begun!"
	eventDescription.TextColor3 = Color3.fromRGB(200, 200, 200)
	eventDescription.TextScaled = true
	eventDescription.Font = Enum.Font.SourceSans
	eventDescription.TextXAlignment = Enum.TextXAlignment.Left
	eventDescription.TextWrapped = true
	eventDescription.Parent = notificationFrame

	-- Small persistent display for the currently active event
	local currentEventFrame = Instance.new("Frame")
	currentEventFrame.Name = "CurrentEventFrame"
	currentEventFrame.Size = UDim2.new(0, 250, 0, 80)
	currentEventFrame.Position = UDim2.new(1, -260, 0, 10)
	currentEventFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	currentEventFrame.BorderSizePixel = 0
	currentEventFrame.Visible = false
	currentEventFrame.Parent = screenGui

	local currentCorner = Instance.new("UICorner")
	currentCorner.CornerRadius = UDim.new(0, 8)
	currentCorner.Parent = currentEventFrame

	local currentStroke = Instance.new("UIStroke")
	currentStroke.Color = Color3.fromRGB(100, 100, 255)
	currentStroke.Thickness = 1
	currentStroke.Parent = currentEventFrame

	local currentIcon = Instance.new("TextLabel")
	currentIcon.Name = "CurrentIcon"
	currentIcon.Size = UDim2.new(0, 40, 0, 40)
	currentIcon.Position = UDim2.new(0, 10, 0, 5)
	currentIcon.BackgroundTransparency = 1
	currentIcon.Text = "🌟"
	currentIcon.TextScaled = true
	currentIcon.Font = Enum.Font.SourceSansBold
	currentIcon.Parent = currentEventFrame

	local currentName = Instance.new("TextLabel")
	currentName.Name = "CurrentName"
	currentName.Size = UDim2.new(1, -60, 0, 25)
	currentName.Position = UDim2.new(0, 55, 0, 5)
	currentName.BackgroundTransparency = 1
	currentName.Text = "Active Event"
	currentName.TextColor3 = Color3.fromRGB(255, 255, 255)
	currentName.TextScaled = true
	currentName.Font = Enum.Font.SourceSansBold
	currentName.TextXAlignment = Enum.TextXAlignment.Left
	currentName.Parent = currentEventFrame

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, -60, 0, 20)
	timerLabel.Position = UDim2.new(0, 55, 0, 30)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "5:00 remaining"
	timerLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	timerLabel.TextScaled = true
	timerLabel.Font = Enum.Font.SourceSans
	timerLabel.TextXAlignment = Enum.TextXAlignment.Left
	timerLabel.Parent = currentEventFrame

	local mutationLabel = Instance.new("TextLabel")
	mutationLabel.Name = "MutationLabel"
	mutationLabel.Size = UDim2.new(1, -60, 0, 20)
	mutationLabel.Position = UDim2.new(0, 55, 0, 50)
	mutationLabel.BackgroundTransparency = 1
	mutationLabel.Text = "50% mutation chance"
	mutationLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	mutationLabel.TextScaled = true
	mutationLabel.Font = Enum.Font.SourceSans
	mutationLabel.TextXAlignment = Enum.TextXAlignment.Left
	mutationLabel.Parent = currentEventFrame

	return screenGui
end

-- Format time as MM:SS
local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", minutes, secs)
end

-- Shows a notification when an event starts or ends
local function showEventNotification(eventName, eventData, isStarting)
	local gui = playerGui:FindFirstChild("NaturalEventsGUI")
	if not gui then
		gui = createEventGUI()
	end

	local notificationFrame = gui.NotificationFrame
	local currentEventFrame = gui.CurrentEventFrame

	notificationFrame.EventIcon.Text = eventData.Icon
	notificationFrame.EventTitle.Text = eventData.Name .. (isStarting and " Started!" or " Ended!")
	notificationFrame.EventDescription.Text = eventData.Description
	notificationFrame.UIStroke.Color = eventData.Color

	-- Slide notification in
	notificationFrame.Position = UDim2.new(0.5, -200, 0, -150)
	local slideIn = TweenService:Create(
		notificationFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -200, 0, 20)}
	)
	slideIn:Play()

	if isStarting then
		currentEvent = eventName
		eventEndTime = tick() + eventData.Duration

		currentEventFrame.CurrentIcon.Text = eventData.Icon
		currentEventFrame.CurrentName.Text = eventData.Name
		currentEventFrame.UIStroke.Color = eventData.Color
		currentEventFrame.Visible = true
	else
		currentEvent = nil
		currentEventFrame.Visible = false
	end

	wait(4)

	-- Slide notification out
	local slideOut = TweenService:Create(
		notificationFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, -200, 0, -150)}
	)
	slideOut:Play()
end

-- Updates the countdown timer every second
spawn(function()
	while true do
		if currentEvent and eventEndTime > 0 then
			local gui = playerGui:FindFirstChild("NaturalEventsGUI")
			if gui and gui.CurrentEventFrame.Visible then
				local timeRemaining = math.max(0, math.ceil(eventEndTime - tick()))
				gui.CurrentEventFrame.TimerLabel.Text = formatTime(timeRemaining) .. " remaining"

				if timeRemaining <= 0 then
					currentEvent = nil
					gui.CurrentEventFrame.Visible = false
				end
			end
		end
		wait(1)
	end
end)

-- Handles event start
naturalEventStarted.OnClientEvent:Connect(function(eventName, eventData)
	spawn(function()
		showEventNotification(eventName, eventData, true)
	end)
	print("🌟 Natural Event Started:", eventName)
end)

-- Handles event end
naturalEventEnded.OnClientEvent:Connect(function(eventName)
	print("🌙 Natural Event Ended:", eventName)
end)

-- Checks if player joined during an active event
spawn(function()
	wait(2)
	local success, result = pcall(function()
		return getCurrentEvent:InvokeServer()
	end)

	if success and result then
		currentEvent = result.EventName
		eventEndTime = tick() + result.TimeRemaining

		local gui = playerGui:FindFirstChild("NaturalEventsGUI")
		if not gui then
			gui = createEventGUI()
		end

		local currentEventFrame = gui.CurrentEventFrame
		currentEventFrame.CurrentIcon.Text = result.EventData.Icon
		currentEventFrame.CurrentName.Text = result.EventData.Name
		currentEventFrame.UIStroke.Color = result.EventData.Color
		currentEventFrame.Visible = true

		print("🌍 Joined during active event:", result.EventName)
	end
end)
