local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mineRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("StartMining")

-- sound baby
local popSound = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("SFX"):WaitForChild("Pop")
local successSound = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("SFX"):WaitForChild("Success")
local slideSound = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("SFX"):WaitForChild("Slide") 
local catchSound = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("SFX"):WaitForChild("Catch")

local alertGuiPart = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("VFX"):WaitForChild("Gui")

local tagLabel = player:WaitForChild("PlayerGui"):WaitForChild("PopUps"):WaitForChild("Tag")

local minigameDotsGui = player:WaitForChild("PlayerGui"):WaitForChild("MinigameDots")
local dotsButton = minigameDotsGui:WaitForChild("Button")

local minigameBarGui = player.PlayerGui:WaitForChild("MinigameBar")
local gameFrame = minigameBarGui:WaitForChild("GameFrame")
local bar = gameFrame:WaitForChild("Bar")
local successZone = gameFrame:WaitForChild("SuccessZone")
local stopButton = gameFrame:WaitForChild("StopButton")
local amountLabel = gameFrame:WaitForChild("Amount")

local sliderGui = player:WaitForChild("PlayerGui"):WaitForChild("Slider")
local fillFrame = sliderGui:WaitForChild("FillFrame")
local barFrame = fillFrame:WaitForChild("Bar")
local fillBar = fillFrame:WaitForChild("Fill")

local currentTool = nil
local toolEquipped = false
local minigameRunning = false
local clicks = 0
local totalClicksNeeded = 0
local winPoints = 0
local movingTween = nil
local debounce = false
local clickCooldown = false
local isHolding = false
local sliderActive = false
local slideSoundInstance = nil 
local currentAlertEffect = nil
local cameraShakeThread = nil
local dotsPhaseActive = false
local missClickConnection = nil
local sliderZoomThread = nil

-- Camera manipulation functions
local function zoomCamera(zoomIn)
	local camera = Workspace.CurrentCamera
	if not camera then return end

	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local startOffset = camera.CFrame.Position - humanoidRootPart.Position
	local targetOffset = startOffset

	if zoomIn then
		targetOffset = startOffset * 0.8 -- Zoom in by 20%
	else
		targetOffset = startOffset * 1.25 -- Zoom out by 25%
	end

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(camera, tweenInfo, {
		CFrame = CFrame.new(humanoidRootPart.Position + targetOffset, humanoidRootPart.Position)
	})

	tween:Play()
end

local function stopSliderCameraZoom()
	if sliderZoomThread then
		task.cancel(sliderZoomThread)
		sliderZoomThread = nil
	end

	-- Reset camera to normal state
	local camera = Workspace.CurrentCamera
	if camera then
		-- Reset FOV if using FOV method
		camera.FieldOfView = 70 -- Default FOV

		-- For distance-based zoom, smoothly return to normal distance
		local character = player.Character
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local currentOffset = camera.CFrame.Position - humanoidRootPart.Position
				local normalOffset = currentOffset.Unit * 15 -- Normal camera distance

				local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
				local tween = TweenService:Create(camera, tweenInfo, {
					CFrame = CFrame.new(humanoidRootPart.Position + normalOffset, humanoidRootPart.Position)
				})
				tween:Play()
			end
		end
	end
end

--  FOV-based zoom function 
local function startSliderCameraZoomFOV()
	if sliderZoomThread then
		task.cancel(sliderZoomThread)
		sliderZoomThread = nil
	end

	local camera = Workspace.CurrentCamera
	if not camera then return end

	-- Store initial field of view
	local initialFOV = camera.FieldOfView
	local targetFOV = math.max(20, initialFOV * 0.4) -- Minimum FOV of 20, zoom to 40% of original
	local currentFOV = initialFOV

	sliderZoomThread = task.spawn(function()
		local zoomSpeed = 1.2 -- How fast to change FOV per frame

		while isHolding and sliderActive and currentFOV > targetFOV do
			-- Reduce the field of view gradually (smaller FOV = more zoomed in)
			currentFOV = currentFOV - zoomSpeed

			-- Clamp to minimum FOV
			if currentFOV < targetFOV then
				currentFOV = targetFOV
			end

			-- Apply the new field of view
			camera.FieldOfView = currentFOV

			task.wait() -- Wait for next frame
		end

		sliderZoomThread = nil
	end)
end

-- Enhanced distance-based zoom function 
local function startSliderCameraZoom()
	if sliderZoomThread then
		task.cancel(sliderZoomThread)
		sliderZoomThread = nil
	end

	local camera = Workspace.CurrentCamera
	if not camera then return end

	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Store initial camera distance
	local initialCameraDistance = (camera.CFrame.Position - humanoidRootPart.Position).Magnitude
	local targetDistance = math.max(8, initialCameraDistance * 0.5) -- Minimum distance of 8 studs, zoom to 50%
	local currentDistance = initialCameraDistance

	sliderZoomThread = task.spawn(function()
		local zoomSpeed = 0.3 -- How fast to zoom per frame

		while isHolding and sliderActive and currentDistance > targetDistance do
			-- Reduce the current distance gradually
			currentDistance = currentDistance - zoomSpeed

			-- Clamp to minimum distance
			if currentDistance < targetDistance then
				currentDistance = targetDistance
			end

			-- Calculate new camera position
			local direction = (camera.CFrame.Position - humanoidRootPart.Position).Unit
			local newCameraPosition = humanoidRootPart.Position + (direction * currentDistance)

			-- Smoothly move camera to new position
			camera.CFrame = CFrame.lookAt(newCameraPosition, humanoidRootPart.Position)

			task.wait() -- Wait for next frame
		end

		sliderZoomThread = nil
	end)
end

local function startCameraShake()
	if cameraShakeThread then
		task.cancel(cameraShakeThread)
		cameraShakeThread = nil
	end

	-- Only shake during the bar minigame phase
	if not minigameBarGui.Enabled then
		return
	end

	local camera = Workspace.CurrentCamera
	if not camera then return end

	cameraShakeThread = task.spawn(function()
		local intensity = 0.5 -- Increased intensity for more vigorous shaking
		local shakeSpeed = 0.03 -- Faster shake updates

		while minigameRunning and minigameBarGui.Enabled do
			local randomX = (math.random() - 0.5) * 2 * intensity
			local randomY = (math.random() - 0.5) * 2 * intensity
			local randomZ = (math.random() - 0.5) * 2 * intensity

			-- Apply shake to camera CFrame
			local shakeOffset = Vector3.new(randomX, randomY, randomZ)
			local currentCFrame = camera.CFrame
			camera.CFrame = currentCFrame + shakeOffset

			task.wait(shakeSpeed)
		end

		cameraShakeThread = nil
	end)
end

local function stopCameraShake()
	if cameraShakeThread then
		task.cancel(cameraShakeThread)
		cameraShakeThread = nil
	end
end

local function popLabel(label)
	local originalSize = label.Size
	local popSize = originalSize + UDim2.new(0, 10, 0, 10)

	local tweenUp = TweenService:Create(label, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = popSize})
	local tweenDown = TweenService:Create(label, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = originalSize})

	tweenUp.Completed:Once(function()
		tweenDown:Play()
	end)

	tweenUp:Play()
end

local function burstAnimateTag(label)
	label.Visible = true
	label.Size = UDim2.new(0, 0, 0, 0)  
	label.TextTransparency = 1
	label.Position = UDim2.new(0.5, 0, 0.3, 0)  
	label.AnchorPoint = Vector2.new(0.5, 0.5)   

	local sound = popSound:Clone()
	sound.Parent = player.PlayerGui
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	local burstTween = TweenService:Create(
		label, 
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
		{
			Size = UDim2.new(0, 200, 0, 50),
			TextTransparency = 0
		}
	)

	local bounceTween = TweenService:Create(
		label,
		TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 180, 0, 45)
		}
	)

	local settleTween = TweenService:Create(
		label,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{
			Size = UDim2.new(0, 190, 0, 48)
		}
	)

	burstTween.Completed:Connect(function()
		bounceTween:Play()
	end)

	bounceTween.Completed:Connect(function()
		settleTween:Play()
	end)

	burstTween:Play()

	task.delay(2.5, function()
		TweenService:Create(
			label, 
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
			{
				TextTransparency = 1,
				Size = UDim2.new(0, 0, 0, 0)
			}
		):Play()
	end)
end

local function removeAlertEffect()
	if currentAlertEffect then
		-- Get the BillboardGui from the part
		local billboardGui = currentAlertEffect:FindFirstChild("Thing")
		if billboardGui then
			local lineFrame = billboardGui:FindFirstChild("Line")
			local dotFrame = billboardGui:FindFirstChild("Dot")

			-- Animate the frames shrinking and fading out
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)

			if lineFrame then
				local lineTween = TweenService:Create(lineFrame, tweenInfo, {
					Size = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1
				})
				lineTween:Play()
			end

			if dotFrame then
				local dotTween = TweenService:Create(dotFrame, tweenInfo, {
					Size = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1
				})
				dotTween:Play()
			end

			-- Disable the billboard gui after animation
			task.delay(0.3, function()
				billboardGui.Enabled = false
			end)
		end

		-- Remove the part after animation completes
		task.delay(0.5, function()
			if currentAlertEffect and currentAlertEffect.Parent then
				currentAlertEffect:Destroy()
				currentAlertEffect = nil
			end
		end)
	end
end

local function createAlertEffect()
	local character = player.Character
	if not character then return end

	local head = character:FindFirstChild("Head")
	if not head then return end

	-- Remove any existing alert effect
	removeAlertEffect()

	-- Clone the Gui PART from ReplicatedStorage
	local alertPart = alertGuiPart:Clone()
	alertPart.Parent = workspace -- Parent to workspace so it exists in the world

	-- Position the part above the player's head
	local headPosition = head.Position
	alertPart.Position = headPosition + Vector3.new(0, 3, 0) -- 3 studs above head

	-- Make the part follow the player's head
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyPosition.Position = headPosition + Vector3.new(0, 3, 0)
	bodyPosition.Parent = alertPart

	-- Create a connection to update the part's position to follow the head
	local heartbeat
	heartbeat = RunService.Heartbeat:Connect(function()
		if head.Parent and alertPart.Parent then
			bodyPosition.Position = head.Position + Vector3.new(0, 3, 0)
		else
			heartbeat:Disconnect()
		end
	end)

	-- Get the BillboardGui from inside the part
	local billboardGui = alertPart:FindFirstChild("Thing")
	if not billboardGui then 
		alertPart:Destroy()
		return 
	end

	-- Enable the BillboardGui
	billboardGui.Enabled = true

	local lineFrame = billboardGui:FindFirstChild("Line")
	local dotFrame = billboardGui:FindFirstChild("Dot")

	if not lineFrame or not dotFrame then 
		alertPart:Destroy()
		return 
	end

	-- Store original properties
	local originalLineSize = lineFrame.Size
	local originalDotSize = dotFrame.Size
	local originalLineTransparency = lineFrame.BackgroundTransparency
	local originalDotTransparency = dotFrame.BackgroundTransparency

	-- Reset the frames to invisible/small for animation
	lineFrame.Size = UDim2.new(0, 0, 0, 0)
	dotFrame.Size = UDim2.new(0, 0, 0, 0)
	lineFrame.BackgroundTransparency = 1
	dotFrame.BackgroundTransparency = 1

	-- Play the catch sound
	local sound = catchSound:Clone()
	sound.Parent = alertPart
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	-- Create popup animations for both frames
	local appearTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)

	local lineAppearTween = TweenService:Create(lineFrame, appearTweenInfo, {
		Size = originalLineSize,
		BackgroundTransparency = originalLineTransparency
	})

	local dotAppearTween = TweenService:Create(dotFrame, appearTweenInfo, {
		Size = originalDotSize,
		BackgroundTransparency = originalDotTransparency
	})

	-- Create bounce effect
	local bounceTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

	local lineBounceTween = TweenService:Create(lineFrame, bounceTweenInfo, {
		Size = UDim2.new(originalLineSize.X.Scale * 1.2, originalLineSize.X.Offset, 
			originalLineSize.Y.Scale * 1.2, originalLineSize.Y.Offset)
	})

	local dotBounceTween = TweenService:Create(dotFrame, bounceTweenInfo, {
		Size = UDim2.new(originalDotSize.X.Scale * 1.2, originalDotSize.X.Offset,
			originalDotSize.Y.Scale * 1.2, originalDotSize.Y.Offset)
	})

	-- Create settle effect
	local settleTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	local lineSettleTween = TweenService:Create(lineFrame, settleTweenInfo, {
		Size = originalLineSize
	})

	local dotSettleTween = TweenService:Create(dotFrame, settleTweenInfo, {
		Size = originalDotSize
	})

	-- Chain the animations
	lineAppearTween.Completed:Connect(function()
		lineBounceTween:Play()
	end)

	dotAppearTween.Completed:Connect(function()
		dotBounceTween:Play()
	end)

	lineBounceTween.Completed:Connect(function()
		lineSettleTween:Play()
	end)

	dotBounceTween.Completed:Connect(function()
		dotSettleTween:Play()
	end)

	-- Start the animations
	lineAppearTween:Play()
	dotAppearTween:Play()

	-- Store reference to the current alert effect
	currentAlertEffect = alertPart

	-- Clean up the heartbeat connection when the effect is removed
	alertPart.AncestryChanged:Connect(function()
		if not alertPart.Parent then
			heartbeat:Disconnect()
		end
	end)
end

local function resetMinigame()
	clicks = 0
	winPoints = 0
	totalClicksNeeded = 0
	minigameRunning = false
	sliderActive = false
	dotsPhaseActive = false
	minigameDotsGui.Enabled = false
	minigameBarGui.Enabled = false
	sliderGui.Enabled = false
	debounce = false
	clickCooldown = false
	isHolding = false

	-- Disconnect miss click detection
	if missClickConnection then
		missClickConnection:Disconnect()
		missClickConnection = nil
	end

	removeAlertEffect()
	stopCameraShake()
	stopSliderCameraZoom()

	if slideSoundInstance then
		slideSoundInstance:Stop()
		slideSoundInstance:Destroy()
		slideSoundInstance = nil
	end

	fillBar.Size = UDim2.new(1, 0, 0, 0)
	fillBar.Position = UDim2.new(0, 0, 1, 0) 

	barFrame.Position = UDim2.new(0, 0, 1, 0) 

	if movingTween then movingTween:Cancel() end

	-- Reset camera zoom
	zoomCamera(false)
end

local function resetToolState()
	currentTool = nil
	toolEquipped = false
	resetMinigame()
end

local function randomizeButtonPosition()
	local parentSize = dotsButton.Parent.AbsoluteSize
	local buttonSize = dotsButton.AbsoluteSize

	local maxX = parentSize.X - buttonSize.X
	local maxY = parentSize.Y - buttonSize.Y

	dotsButton.Position = UDim2.new(0, math.random(0, maxX), 0, math.random(0, maxY))
end

local function handleMissClick()
	if dotsPhaseActive then
		-- Player missed the button, reset everything
		resetMinigame()

		-- Show failure message
		local failLabel = Instance.new("TextLabel")
		failLabel.Text = "❌ MISSED! Try Again!"
		failLabel.Size = UDim2.new(0, 300, 0, 50)
		failLabel.Position = UDim2.new(0.5, -150, 0.5, -25)
		failLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		failLabel.BackgroundTransparency = 1
		failLabel.TextScaled = true
		failLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		failLabel.Parent = player.PlayerGui

		TweenService:Create(failLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
		task.delay(2, function()
			if failLabel.Parent then
				failLabel:Destroy()
			end
		end)
	end
end

local function startDotsMinigame()
	minigameRunning = true
	dotsPhaseActive = true
	clicks = 0
	minigameDotsGui.Enabled = true
	randomizeButtonPosition()

	missClickConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 and dotsPhaseActive then
			local mouse = Players.LocalPlayer:GetMouse()
			local buttonPos = dotsButton.AbsolutePosition
			local buttonSize = dotsButton.AbsoluteSize

			local mouseX = mouse.X
			local mouseY = mouse.Y

			local withinX = mouseX >= buttonPos.X and mouseX <= (buttonPos.X + buttonSize.X)
			local withinY = mouseY >= buttonPos.Y and mouseY <= (buttonPos.Y + buttonSize.Y)

			if not (withinX and withinY) then
				handleMissClick()
			end
		end
	end)
end

local function startBarMinigame()
	dotsPhaseActive = false
	minigameDotsGui.Enabled = false

	if missClickConnection then
		missClickConnection:Disconnect()
		missClickConnection = nil
	end

	createAlertEffect()
	zoomCamera(true)

	task.delay(1, function()
		if not minigameRunning then return end

		minigameBarGui.Enabled = true
		amountLabel.Text = "0/5"
		winPoints = 0
		debounce = false

		removeAlertEffect()

		startCameraShake()

		bar.Position = UDim2.new(0, 0, 0.5, -bar.AbsoluteSize.Y / 2)

		local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
		movingTween = TweenService:Create(bar, tweenInfo, {
			Position = UDim2.new(1, -bar.AbsoluteSize.X, 0.5, -bar.AbsoluteSize.Y / 2)
		})
		movingTween:Play()
	end)
end

local function moveSuccessZone()
	local frameWidth = gameFrame.AbsoluteSize.X
	local zoneWidth = successZone.AbsoluteSize.X

	local maxX = frameWidth - zoneWidth
	local newPos = UDim2.new(0, math.random(0, maxX), successZone.Position.Y.Scale, successZone.Position.Y.Offset)
	successZone.Position = newPos
end

local function finalizeMineral()
	resetMinigame()

	local pop = Instance.new("TextLabel")
	pop.Text = "🎉 Mineral Acquired!"
	pop.Size = UDim2.new(0, 300, 0, 50)
	pop.Position = UDim2.new(0.5, -150, 0.5, -25)
	pop.AnchorPoint = Vector2.new(0.5, 0.5)
	pop.BackgroundTransparency = 1
	pop.TextScaled = true
	pop.TextColor3 = Color3.fromRGB(0, 255, 0)
	pop.Parent = player.PlayerGui

	TweenService:Create(pop, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	task.delay(2, function()
		pop:Destroy()
	end)

	mineRequest:FireServer()
end

dotsButton.MouseButton1Click:Connect(function()
	if not minigameRunning or debounce or not dotsPhaseActive then return end
	clicks += 1
	if clicks >= totalClicksNeeded then
		startBarMinigame()
	else
		randomizeButtonPosition()
	end
end)

stopButton.MouseButton1Click:Connect(function()
	if not minigameRunning or debounce then return end
	debounce = true

	local barX = bar.AbsolutePosition.X
	local zoneX = successZone.AbsolutePosition.X
	local zoneW = successZone.AbsoluteSize.X
	local barW = bar.AbsoluteSize.X

	if barX + barW > zoneX and barX < zoneX + zoneW then
		winPoints += 1
		amountLabel.Text = winPoints .. "/5"
		popLabel(amountLabel)

		local sound = successSound:Clone()
		sound.Parent = player.PlayerGui
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)

		moveSuccessZone()
		if winPoints >= 5 then
			finalizeMineral()
		else
			debounce = false
		end
	else
		resetMinigame()
	end
end)

local attemptCounter = 0
local defaultFillTime = 1 
local currentDirection = "up" 

local function startSliderMinigame()
	sliderGui.Enabled = true
	sliderActive = true
	tagLabel.Visible = false

	attemptCounter = (attemptCounter + 1) % 5

	fillBar.Size = UDim2.new(1, 0, 0, 0)
	fillBar.Position = UDim2.new(0, 0, 1, 0) 
	fillBar.AnchorPoint = Vector2.new(0, 1) 

	barFrame.Position = UDim2.new(0, 0, 1, 0) 
	barFrame.AnchorPoint = Vector2.new(0, 0) 

	local endConnection
	local currentTween

	isHolding = true
	currentDirection = "up"

	-- Start the gradual camera zoom
	startSliderCameraZoom()

	slideSoundInstance = slideSound:Clone()
	slideSoundInstance.Parent = player.PlayerGui
	slideSoundInstance:Play()
	slideSoundInstance.Looped = true

	local function animateFill()
		if not isHolding or not sliderActive then return end

		if currentDirection == "up" then
			currentTween = TweenService:Create(
				fillBar,
				TweenInfo.new(defaultFillTime, Enum.EasingStyle.Linear),
				{Size = UDim2.new(1, 0, 1, 0)} 
			)

			TweenService:Create(
				barFrame,
				TweenInfo.new(defaultFillTime, Enum.EasingStyle.Linear),
				{Position = UDim2.new(0, 0, 0, 0)}
			):Play()
		else
			currentTween = TweenService:Create(
				fillBar,
				TweenInfo.new(defaultFillTime, Enum.EasingStyle.Linear),
				{Size = UDim2.new(1, 0, 0, 0)} 
			)

			TweenService:Create(
				barFrame,
				TweenInfo.new(defaultFillTime, Enum.EasingStyle.Linear),
				{Position = UDim2.new(0, 0, 1, 0)} 
			):Play()
		end

		currentTween:Play()

		currentTween.Completed:Connect(function()
			if isHolding and sliderActive then
				currentDirection = currentDirection == "up" and "down" or "up"
				animateFill() 
			end
		end)
	end

	animateFill()

	endConnection = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and isHolding and sliderActive then
			isHolding = false
			sliderActive = false
			sliderGui.Enabled = false

			-- Stop the camera zoom when mouse is released
			stopSliderCameraZoom()

			if slideSoundInstance then
				slideSoundInstance:Stop()
				slideSoundInstance:Destroy()
				slideSoundInstance = nil
			end

			if currentTween then
				currentTween:Cancel()
			end

			endConnection:Disconnect()

			local fillPercent = fillBar.Size.Y.Scale
			local rating, color, multiplier

			if fillPercent >= 0.95 or fillPercent <= 0.05 then 
				rating = "Perfect!"
				color = Color3.fromRGB(255, 215, 0) 
				multiplier = 0.5
			elseif fillPercent >= 0.75 or fillPercent <= 0.25 then
				rating = "Awesome!"
				color = Color3.fromRGB(255, 128, 0) 
				multiplier = 0.7
			elseif fillPercent >= 0.5 or fillPercent <= 0.5 then
				rating = "Great!"
				color = Color3.fromRGB(0, 170, 255) 
				multiplier = 0.8
			else
				rating = "Nice!"
				color = Color3.fromRGB(0, 255, 0) 
				multiplier = 1.0
			end

			tagLabel.Text = rating
			tagLabel.TextColor3 = color
			burstAnimateTag(tagLabel)

			if currentTool then
				local baseClicks = currentTool:FindFirstChild("Chance") and currentTool.Chance.Value or 5
				totalClicksNeeded = math.max(1, math.floor(baseClicks * multiplier))
				task.delay(1, startDotsMinigame)
			end
		end
	end)
end

local function isMiningTool(tool)
	return tool:IsA("Tool") and tool:FindFirstChild("Chance") ~= nil
end

local function handleToolEquipped(tool)
	if isMiningTool(tool) then
		currentTool = tool
		toolEquipped = true

		tool.Unequipped:Connect(function()
			resetToolState()
		end)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and toolEquipped and not minigameRunning and not sliderActive then
		if currentTool then
			startSliderMinigame()
		end
	end
end)

local function monitorCharacter(character)
	resetToolState()

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(function()
				handleToolEquipped(child)
			end)
		end
	end)

	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Tool") then
			handleToolEquipped(item)
		end
	end
end

if player.Character then
	monitorCharacter(player.Character)
end

player.CharacterAdded:Connect(monitorCharacter)
