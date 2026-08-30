local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local rs = ReplicatedStorage
local menuToysFolder = rs:FindFirstChild("MenuToys")
local spawnToyRemote = menuToysFolder and menuToysFolder:FindFirstChild("SpawnToyRemoteFunction")

selectedColor = nil
currentTransparency = nil
selectedMaterial = nil
isStudsSelected = false
currentKey = Enum.KeyCode.B
triggerKey = Enum.KeyCode.T
teleportKey = Enum.KeyCode.Z
noclipKey = Enum.KeyCode.X
speedHackKey = Enum.KeyCode.V
flyKey = Enum.KeyCode.C
infJumpKey = Enum.KeyCode.J
breakCollisionKey = Enum.KeyCode.G

speedHackSpeed = 0
flySpeed = 0

noclip = false
isSpeedHackEnabled = false
inf_fly = false
isInfJumpEnabled = false
isClickTpEnabled = false
isAntiKickEnabled = false
isAntiKickItemEnabled = false
isAntiGrabEnabled = false
isAntiInputEnabled = false

bg, bv = nil, nil
currentTarget = nil
isVehicle = false

activeTabIsVisuals = true
activeTabIsPlayer = false
activeTabIsDefense = false
activeTabIsTarget = false
activeTabIsGrabs = false
activeTabIsMisc = false
activeTabIsUISettings = false

keys = {W = false, A = false, S = false, D = false, Space = false, LeftControl = false}

local WALL_HEIGHT = 7
local WALL_THICKNESS = 0.1
local ROOF_THICKNESS = 0.1

local GROUP_BARRIERS = "BarrierNoCollide"
local GROUP_PLAYER = "OwnerPlayerGroup"

pcall(function()
	PhysicsService:RegisterCollisionGroup(GROUP_BARRIERS)
	PhysicsService:RegisterCollisionGroup(GROUP_PLAYER)
	PhysicsService:CollisionGroupSetCollidable(GROUP_BARRIERS, GROUP_BARRIERS, false)
	PhysicsService:CollisionGroupSetCollidable(GROUP_BARRIERS, GROUP_PLAYER, false)
end)

barriers = {}
containmentEnabled = false
activePallet = nil
leaveTime = nil
local AUTO_CLOSE_DELAY = 0.2

root, character, humanoid = nil, nil, nil

local function updateCharacterRef(char)
	character = char
	root = char:WaitForChild("HumanoidRootPart", 5)
	humanoid = char:WaitForChild("Humanoid", 5)
	
	pcall(function()
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(part, GROUP_PLAYER)
			end
		end
	end)
end

player.CharacterAdded:Connect(updateCharacterRef)
if player.Character then
	updateCharacterRef(player.Character)
end

RunService.Stepped:Connect(function()
	if noclip and character then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
			end
		end
	end
end)

local SelectedToy = "FoodHamburger"

task.spawn(function()
	while true do
		if isAntiInputEnabled then
			local plr = Players.LocalPlayer
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and spawnToyRemote then
				local toysFolder = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
				local item = toysFolder and toysFolder:FindFirstChild(SelectedToy)

				for _, obj in pairs(Workspace:GetChildren()) do
					if obj.Name == "Shuriken" and obj:IsA("Model") then
						for _, part in pairs(obj:GetDescendants()) do
							if part:IsA("BasePart") then 
								part.CanCollide = false 
								part.Massless = true 
							end
						end
					end
				end

				if not item or not item.Parent then
					task.spawn(function()
						pcall(function()
							spawnToyRemote:InvokeServer(SelectedToy, hrp.CFrame * CFrame.new(0, -12, 0), Vector3.zero)
						end)
					end)
					task.wait(0.1)
				else
					local holdPart = item:FindFirstChild("HoldPart")
					if holdPart then
						for _, v in pairs(item:GetDescendants()) do
							if v:IsA("BasePart") then 
								v.CanCollide = false 
								v.Massless = true 
							end
						end

						task.spawn(function()
							pcall(function()
								holdPart.HoldItemRemoteFunction:InvokeServer(item, char)
							end)
						end)

						task.wait(0.02) 

						task.spawn(function()
							pcall(function()
								holdPart.DropItemRemoteFunction:InvokeServer(
									item, 
									CFrame.new(0, 5000, 0), 
									Vector3.zero
								)
							end)
						end)
					end
				end
			end
		end
		task.wait(0.02)
	end
end)

local function isPartVisibleVisual(part)
	if not part:IsA("BasePart") then return false end
	if part:GetAttribute("IsVisualPart") ~= nil then
		return part:GetAttribute("IsVisualPart")
	end

	if part.Name == "HumanoidRootPart" or part.Name == "Hitbox" or part.Name == "Control" or part.Transparency == 1 then
		part:SetAttribute("IsVisualPart", false)
		return false
	end
	
	local isVisual = (part.Transparency < 1)
	part:SetAttribute("IsVisualPart", isVisual)
	return isVisual
end

local function applySettingsToPart(part)
	if not isPartVisibleVisual(part) then return end
	
	if selectedMaterial then
		part.Material = selectedMaterial
		if isStudsSelected then
			part.TopSurface = Enum.SurfaceType.Studs
			part.BottomSurface = Enum.SurfaceType.Studs
			part.FrontSurface = Enum.SurfaceType.Studs
			part.BackSurface = Enum.SurfaceType.Studs
			part.LeftSurface = Enum.SurfaceType.Studs
			part.RightSurface = Enum.SurfaceType.Studs
		else
			part.TopSurface = Enum.SurfaceType.Smooth
			part.BottomSurface = Enum.SurfaceType.Smooth
			part.FrontSurface = Enum.SurfaceType.Smooth
			part.BackSurface = Enum.SurfaceType.Smooth
			part.LeftSurface = Enum.SurfaceType.Smooth
			part.RightSurface = Enum.SurfaceType.Smooth
		end
	end
	
	if selectedColor then
		part.Color = selectedColor
	end
	
	if currentTransparency ~= nil then
		part.Transparency = currentTransparency
	end
end

-- ============================================================
-- СПАВН ПАЛЕТКИ (С БИНДОМ)
-- ============================================================
local function spawnPalletKeyMatches(input, boundKey)
    if boundKey == nil then return false end
    if input.KeyCode.Name == boundKey or input.UserInputType.Name == boundKey then
        return true
    end
    if (boundKey == "MB2" or boundKey == "MouseButton2" or boundKey == "RightClick")
        and input.UserInputType == Enum.UserInputType.MouseButton2 then
        return true
    end
    if (boundKey == "MB1" or boundKey == "MouseButton1" or boundKey == "LeftClick")
        and input.UserInputType == Enum.UserInputType.MouseButton1 then
        return true
    end
    return false
end

lastPalletSpawn = 0
local function doSpawnPallet()
    if tick() - lastPalletSpawn < 0.2 then return end
    lastPalletSpawn = tick()

    local char = player.Character
    if not char then return end
    local camPart = char:FindFirstChild("CamPart")
    if not camPart then return end
    local RS = game:GetService("ReplicatedStorage")
    local menuToys = RS:FindFirstChild("MenuToys")
    if not menuToys then return end
    local spawnRemote = menuToys:FindFirstChild("SpawnToyRemoteFunction")
    if not spawnRemote then return end
    local canSpawn = player:FindFirstChild("CanSpawnToy")
    if canSpawn and not canSpawn.Value then
        local t0 = tick()
        while canSpawn and not canSpawn.Value do
            if tick() - t0 > 3 then return end
            task.wait(0.1)
        end
    end
    -- Спавним куда смотрит камера
    task.spawn(function()
        pcall(function()
            spawnRemote:InvokeServer("PalletLightBrown", camPart.CFrame, Vector3.new(0, camPart.Orientation.Y, 0))
        end)
    end)
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == currentKey then
        doSpawnPallet()
    end
end)

local function cleanup()
	for _, part in ipairs(barriers) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	barriers = {}
	if activePallet then
		activePallet:SetAttribute("HasCage", false)
	end
	activePallet = nil
	containmentEnabled = false
	leaveTime = nil
end

local function isStandingOnActivePallet()
	if not root or not activePallet or not activePallet.Parent then return false end
	
	local primary = activePallet:IsA("Model") and (activePallet.PrimaryPart or activePallet:FindFirstChildWhichIsA("BasePart")) or activePallet
	if not primary then return false end

	if primary.CFrame.UpVector.Y < 0.2 then
		return false
	end

	local rp = root.Position
	local cf, size = activePallet:GetBoundingBox()
	local localPos = cf:PointToObjectSpace(rp)

	return math.abs(localPos.X) <= size.X / 2
		and math.abs(localPos.Z) <= size.Z / 2
		and localPos.Y >= -size.Y / 2
		and localPos.Y <= size.Y / 2 + WALL_HEIGHT
end

local function makeBarrier(size, cframe, pallet)
	local part = Instance.new("Part")
	part.Size = size
	part.CFrame = cframe
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(255, 255, 255)
	part.Transparency = 1
	part.Anchored = false
	part.Massless = true
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = false
	part.CastShadow = false
	
	pcall(function()
		PhysicsService:SetPartCollisionGroup(part, GROUP_BARRIERS)
	end)
	
	part.Parent = character or player.Character

	local primary = pallet:IsA("Model") and (pallet.PrimaryPart or pallet:FindFirstChildWhichIsA("BasePart")) or pallet
	if primary then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = primary
		weld.Part1 = part
		weld.Parent = part
	end

	RunService.RenderStepped:Connect(function()
		if not part or not part.Parent then return end
		local camDist = (camera.CFrame.Position - camera.Focus.Position).Magnitude
		if camDist > 2 then
			part.LocalTransparencyModifier = 0
		else
			part.LocalTransparencyModifier = 1
		end
	end)

	table.insert(barriers, part)
end

local function spawnBarriers(pallet)
	if containmentEnabled then 
		cleanup()
		return 
	end

	local cf, size = pallet:GetBoundingBox()
	local wallY = size.Y / 2 + WALL_HEIGHT / 2
	local t = WALL_THICKNESS
	local w = size.X
	local d = size.Z
	local h = WALL_HEIGHT

	makeBarrier(Vector3.new(t, h, d), cf * CFrame.new((w - t)/2, wallY, 0), pallet)
	makeBarrier(Vector3.new(t, h, d), cf * CFrame.new(-(w - t)/2, wallY, 0), pallet)
	makeBarrier(Vector3.new(w, h, t), cf * CFrame.new(0, wallY, (d - t)/2), pallet)
	makeBarrier(Vector3.new(w, h, t), cf * CFrame.new(0, wallY, -(d - t)/2), pallet)

	makeBarrier(
		Vector3.new(w, ROOF_THICKNESS, d),
		cf * CFrame.new(0, size.Y/2 + WALL_HEIGHT + ROOF_THICKNESS/2, 0),
		pallet
	)

	containmentEnabled = true
	activePallet = pallet
	pallet:SetAttribute("HasCage", true)
end

RunService.RenderStepped:Connect(function()
	if not containmentEnabled then return end

	if isStandingOnActivePallet() then
		leaveTime = nil
	else
		leaveTime = leaveTime or tick()
		if tick() - leaveTime >= AUTO_CLOSE_DELAY then
			cleanup()
		end
	end
end)

local function applySmoothlyToPallet(pallet)
    if not pallet or not pallet:IsA("Model") then return end
    
    local parts = {}
    for _, part in ipairs(pallet:GetDescendants()) do
        if part:IsA("BasePart") and isPartVisibleVisual(part) then
            table.insert(parts, part)
        end
    end
    
    if #parts == 0 then return end
    
    local targetColor = selectedColor or Color3.fromRGB(255, 255, 255)
    local targetMaterial = selectedMaterial or Enum.Material.SmoothPlastic
    local targetTransparency = currentTransparency or 0
    
    for i, part in ipairs(parts) do
        task.spawn(function()
            local delayTime = (i / #parts) * 0.3
            task.wait(delayTime)
            
            local startColor = part.Color
            local startMaterial = part.Material
            local startTransparency = part.Transparency
            
            local duration = 0.08
            local startTime = tick()
            
            while tick() - startTime < duration do
                local alpha = (tick() - startTime) / duration
                local easedAlpha = 1 - (1 - alpha) * (1 - alpha)
                
                if selectedColor then
                    local newColor = startColor:Lerp(targetColor, easedAlpha)
                    part.Color = newColor
                end
                
                if currentTransparency ~= nil then
                    local newTransparency = startTransparency + (targetTransparency - startTransparency) * easedAlpha
                    part.Transparency = newTransparency
                end
                
                if selectedMaterial and easedAlpha > 0.5 then
                    part.Material = targetMaterial
                    if isStudsSelected then
                        part.TopSurface = Enum.SurfaceType.Studs
                        part.BottomSurface = Enum.SurfaceType.Studs
                        part.FrontSurface = Enum.SurfaceType.Studs
                        part.BackSurface = Enum.SurfaceType.Studs
                        part.LeftSurface = Enum.SurfaceType.Studs
                        part.RightSurface = Enum.SurfaceType.Studs
                    else
                        part.TopSurface = Enum.SurfaceType.Smooth
                        part.BottomSurface = Enum.SurfaceType.Smooth
                        part.FrontSurface = Enum.SurfaceType.Smooth
                        part.BackSurface = Enum.SurfaceType.Smooth
                        part.LeftSurface = Enum.SurfaceType.Smooth
                        part.RightSurface = Enum.SurfaceType.Smooth
                    end
                end
                
                RunService.RenderStepped:Wait()
            end
            
            if selectedColor then
                part.Color = targetColor
            end
            if currentTransparency ~= nil then
                part.Transparency = targetTransparency
            end
            if selectedMaterial then
                part.Material = targetMaterial
                if isStudsSelected then
                    part.TopSurface = Enum.SurfaceType.Studs
                    part.BottomSurface = Enum.SurfaceType.Studs
                    part.FrontSurface = Enum.SurfaceType.Studs
                    part.BackSurface = Enum.SurfaceType.Studs
                    part.LeftSurface = Enum.SurfaceType.Studs
                    part.RightSurface = Enum.SurfaceType.Studs
                else
                    part.TopSurface = Enum.SurfaceType.Smooth
                    part.BottomSurface = Enum.SurfaceType.Smooth
                    part.FrontSurface = Enum.SurfaceType.Smooth
                    part.BackSurface = Enum.SurfaceType.Smooth
                    part.LeftSurface = Enum.SurfaceType.Smooth
                    part.RightSurface = Enum.SurfaceType.Smooth
                end
            end
        end)
    end
end

local function applyToModel(model)
    task.delay(0.2, function()
        if model and model.Parent then
            if model.Name == "PalletLightBrown" then
                applySmoothlyToPallet(model)
                
                model.DescendantAdded:Connect(function(desc)
                    if desc:IsA("BasePart") and isPartVisibleVisual(desc) then
                        applySmoothlyToPallet(model)
                    end
                end)
            end
        end
    end)
end

Workspace.ChildAdded:Connect(function(child)
	if child.Name == player.Name .. "SpawnedInToys" and child:IsA("Folder") then
		child.ChildChildAdded = child.ChildAdded:Connect(applyToModel)
		for _, m in ipairs(child:GetChildren()) do applyToModel(m) end
	end
end)

local existingFolder = Workspace:FindFirstChild(player.Name .. "SpawnedInToys")
if existingFolder then
	existingFolder.ChildAdded:Connect(applyToModel)
	for _, m in ipairs(existingFolder:GetChildren()) do applyToModel(m) end
end

local function applyAllToExisting()
    task.spawn(function()
        local toyFolder = Workspace:FindFirstChild(player.Name .. "SpawnedInToys")
        if toyFolder then
            for _, child in ipairs(toyFolder:GetChildren()) do
                if child.Name == "PalletLightBrown" and child:IsA("Model") then
                    applySmoothlyToPallet(child)
                end
            end
        end
    end)
end

local subMenuBgIcon

local function applyColorToExisting()
	if not selectedColor then return end
	if subMenuBgIcon then
		subMenuBgIcon.ImageColor3 = selectedColor
	end
	applyAllToExisting()
end

local function applyMaterialToExisting()
	applyAllToExisting()
end

local function applyTransparencyToExisting()
	applyAllToExisting()
end

-- ============================================================================
-- FUN TAB
-- ============================================================================
local function setupFunTab(funContentArea)
    funContentArea.ClipsDescendants = true
    funContentArea.CanvasSize = UDim2.new(0, 0, 0, 950)

    local gap = 10

    -- ГРУППА INTIM
    local intimGroupBox = Instance.new("Frame")
    intimGroupBox.Size = UDim2.new(0, 300, 0, 0)
    intimGroupBox.Position = UDim2.new(0, 20, 0, 20)
    intimGroupBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    intimGroupBox.BackgroundTransparency = 0.25
    intimGroupBox.ClipsDescendants = true
    intimGroupBox.Parent = funContentArea

    local igBoxCorner = Instance.new("UICorner")
    igBoxCorner.CornerRadius = UDim.new(0, 18)
    igBoxCorner.Parent = intimGroupBox

    local igBoxStroke = Instance.new("UIStroke")
    igBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    igBoxStroke.Transparency = 0.2
    igBoxStroke.Thickness = 1.0
    igBoxStroke.Parent = intimGroupBox

    local igTitle = Instance.new("TextLabel")
    igTitle.Size = UDim2.new(1, -30, 0, 30)
    igTitle.Position = UDim2.new(0, 15, 0, 8)
    igTitle.BackgroundTransparency = 1
    igTitle.TextXAlignment = Enum.TextXAlignment.Left
    igTitle.Text = "Intim"
    igTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    igTitle.TextTransparency = 0.05
    igTitle.TextSize = 16
    igTitle.Font = Enum.Font.GothamBold
    igTitle.Parent = intimGroupBox

    local igLine = Instance.new("Frame")
    igLine.Size = UDim2.new(1, -30, 0, 1.5)
    igLine.Position = UDim2.new(0, 15, 0, 42)
    igLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    igLine.BackgroundTransparency = 0.3
    igLine.BorderSizePixel = 0
    igLine.Parent = intimGroupBox

    -- ФУНКЦИЯ СОЗДАНИЯ ЭЛЕМЕНТА (БЕЗ ПОЛЗУНКА)
    local igStartY = 52
    local itemHeight = 48

    local function createIntimItem(parent, title, posY)
        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, -gap * 2, 0, itemHeight)
        box.Position = UDim2.new(0, gap, 0, posY)
        box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        box.BackgroundTransparency = 0.25
        box.ClipsDescendants = true
        box.Parent = parent

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 18)
        boxCorner.Parent = box

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Color3.fromRGB(180, 180, 180)
        boxStroke.Transparency = 0.2
        boxStroke.Thickness = 1.0
        boxStroke.Parent = box

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(1, -24, 1, -12)
        toggleBtn.Position = UDim2.new(0, 12, 0, 6)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        toggleBtn.BackgroundTransparency = 0.2
        toggleBtn.Text = ""
        toggleBtn.AutoButtonColor = false
        toggleBtn.Parent = box

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 14)
        toggleCorner.Parent = toggleBtn

        local toggleStroke = Instance.new("UIStroke")
        toggleStroke.Color = Color3.fromRGB(180, 180, 180)
        toggleStroke.Transparency = 0.2
        toggleStroke.Thickness = 0.8
        toggleStroke.Parent = toggleBtn

        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Size = UDim2.new(1, -40, 1, 0)
        toggleLabel.Position = UDim2.new(0, 12, 0, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Text = title
        toggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        toggleLabel.TextSize = 12
        toggleLabel.Font = Enum.Font.GothamBold
        toggleLabel.Parent = toggleBtn

        local checkboxBox = Instance.new("Frame")
        checkboxBox.Size = UDim2.new(0, 20, 0, 20)
        checkboxBox.AnchorPoint = Vector2.new(1, 0.5)
        checkboxBox.Position = UDim2.new(1, -12, 0.5, 0)
        checkboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        checkboxBox.BackgroundTransparency = 0.2
        checkboxBox.BorderSizePixel = 0
        checkboxBox.Parent = toggleBtn

        local cbCorner = Instance.new("UICorner")
        cbCorner.CornerRadius = UDim.new(0, 6)
        cbCorner.Parent = checkboxBox

        local cbStroke = Instance.new("UIStroke")
        cbStroke.Color = Color3.fromRGB(150, 150, 150)
        cbStroke.Transparency = 0.2
        cbStroke.Thickness = 1
        cbStroke.Parent = checkboxBox

        local checkmark = Instance.new("TextLabel")
        checkmark.Size = UDim2.new(1, 0, 1, 0)
        checkmark.BackgroundTransparency = 1
        checkmark.Text = "✓"
        checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
        checkmark.TextSize = 14
        checkmark.Font = Enum.Font.GothamBold
        checkmark.Visible = false
        checkmark.Parent = checkboxBox

        return box, toggleBtn, checkmark
    end

    -- ФУНКЦИЯ СОЗДАНИЯ ЭЛЕМЕНТА С ПОЛЗУНКОМ
    local itemHeightWithSlider = 68

    local function createIntimItemWithSlider(parent, title, posY, sliderMin, sliderMax, sliderDefault, sliderLabelText)
        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, -gap * 2, 0, itemHeightWithSlider)
        box.Position = UDim2.new(0, gap, 0, posY)
        box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        box.BackgroundTransparency = 0.25
        box.ClipsDescendants = true
        box.Parent = parent

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 18)
        boxCorner.Parent = box

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Color3.fromRGB(180, 180, 180)
        boxStroke.Transparency = 0.2
        boxStroke.Thickness = 1.0
        boxStroke.Parent = box

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(1, -24, 0, 28)
        toggleBtn.Position = UDim2.new(0, 12, 0, 4)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        toggleBtn.BackgroundTransparency = 0.2
        toggleBtn.Text = ""
        toggleBtn.AutoButtonColor = false
        toggleBtn.Parent = box

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 14)
        toggleCorner.Parent = toggleBtn

        local toggleStroke = Instance.new("UIStroke")
        toggleStroke.Color = Color3.fromRGB(180, 180, 180)
        toggleStroke.Transparency = 0.2
        toggleStroke.Thickness = 0.8
        toggleStroke.Parent = toggleBtn

        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Size = UDim2.new(1, -40, 1, 0)
        toggleLabel.Position = UDim2.new(0, 12, 0, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Text = title
        toggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        toggleLabel.TextSize = 12
        toggleLabel.Font = Enum.Font.GothamBold
        toggleLabel.Parent = toggleBtn

        local checkboxBox = Instance.new("Frame")
        checkboxBox.Size = UDim2.new(0, 20, 0, 20)
        checkboxBox.AnchorPoint = Vector2.new(1, 0.5)
        checkboxBox.Position = UDim2.new(1, -12, 0.5, 0)
        checkboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        checkboxBox.BackgroundTransparency = 0.2
        checkboxBox.BorderSizePixel = 0
        checkboxBox.Parent = toggleBtn

        local cbCorner = Instance.new("UICorner")
        cbCorner.CornerRadius = UDim.new(0, 6)
        cbCorner.Parent = checkboxBox

        local cbStroke = Instance.new("UIStroke")
        cbStroke.Color = Color3.fromRGB(150, 150, 150)
        cbStroke.Transparency = 0.2
        cbStroke.Thickness = 1
        cbStroke.Parent = checkboxBox

        local checkmark = Instance.new("TextLabel")
        checkmark.Size = UDim2.new(1, 0, 1, 0)
        checkmark.BackgroundTransparency = 1
        checkmark.Text = "✓"
        checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
        checkmark.TextSize = 14
        checkmark.Font = Enum.Font.GothamBold
        checkmark.Visible = false
        checkmark.Parent = checkboxBox

        -- ПОЛЗУНОК
        local sliderFrame = Instance.new("Frame")
        sliderFrame.Size = UDim2.new(1, -24, 0, 20)
        sliderFrame.Position = UDim2.new(0, 12, 0, 38)
        sliderFrame.BackgroundTransparency = 1
        sliderFrame.Parent = box

        local sliderLabel = Instance.new("TextLabel")
        sliderLabel.Size = UDim2.new(0.5, 0, 1, 0)
        sliderLabel.Position = UDim2.new(0, 0, 0, 0)
        sliderLabel.BackgroundTransparency = 1
        sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
        sliderLabel.Text = sliderLabelText .. ": " .. tostring(sliderDefault)
        sliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        sliderLabel.TextSize = 11
        sliderLabel.Font = Enum.Font.Gotham
        sliderLabel.Parent = sliderFrame

        local sliderBar = Instance.new("Frame")
        sliderBar.Size = UDim2.new(0.45, 0, 0.6, 0)
        sliderBar.Position = UDim2.new(0.5, 5, 0.5, -4)
        sliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        sliderBar.BackgroundTransparency = 0.2
        sliderBar.BorderSizePixel = 0
        sliderBar.Parent = sliderFrame

        local sliderBarCorner = Instance.new("UICorner")
        sliderBarCorner.CornerRadius = UDim.new(1, 0)
        sliderBarCorner.Parent = sliderBar

        local sliderFill = Instance.new("Frame")
        local initialScale = (sliderDefault - sliderMin) / (sliderMax - sliderMin)
        sliderFill.Size = UDim2.new(initialScale, 0, 1, 0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sliderFill.BackgroundTransparency = 0.05
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBar

        local sliderFillCorner = Instance.new("UICorner")
        sliderFillCorner.CornerRadius = UDim.new(1, 0)
        sliderFillCorner.Parent = sliderFill

        local sliderButton = Instance.new("TextButton")
        sliderButton.Size = UDim2.new(0, 16, 0, 16)
        sliderButton.Position = UDim2.new(initialScale, -8, 0.5, -8)
        sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sliderButton.BackgroundTransparency = 0
        sliderButton.Text = ""
        sliderButton.Parent = sliderBar

        local sliderButtonCorner = Instance.new("UICorner")
        sliderButtonCorner.CornerRadius = UDim.new(1, 0)
        sliderButtonCorner.Parent = sliderButton

        local sliderButtonStroke = Instance.new("UIStroke")
        sliderButtonStroke.Color = Color3.fromRGB(140, 140, 140)
        sliderButtonStroke.Thickness = 1
        sliderButtonStroke.Parent = sliderButton

        local itemData = {
            box = box,
            toggleBtn = toggleBtn,
            checkmark = checkmark,
            slider = {
                bar = sliderBar,
                fill = sliderFill,
                button = sliderButton,
                label = sliderLabel,
                min = sliderMin,
                max = sliderMax,
                currentValue = sliderDefault,
                labelText = sliderLabelText
            }
        }

        -- ЛОГИКА ПОЛЗУНКА
        local sliding = false
        local function updateSlider(input)
            local mousePos = input.Position.X
            local barAbsolutePos = sliderBar.AbsolutePosition.X
            local barAbsoluteSize = sliderBar.AbsoluteSize.X

            local relativeX = math.clamp(mousePos - barAbsolutePos, 0, barAbsoluteSize)
            local scale = math.clamp(relativeX / barAbsoluteSize, 0, 1)

            sliderButton.Position = UDim2.new(scale, -8, 0.5, -8)
            sliderFill.Size = UDim2.new(scale, 0, 1, 0)

            local value = math.floor(sliderMin + (scale * (sliderMax - sliderMin)) + 0.5)
            itemData.slider.currentValue = value
            sliderLabel.Text = sliderLabelText .. ": " .. tostring(value)
        end

        sliderButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                updateSlider(input)
            end
        end)

        sliderBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                updateSlider(input)
            end
        end)

        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end)

        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateSlider(input)
            end
        end)

        return itemData
    end

    -- ============================================================
    -- 1. COCONUT PENIS
    -- ============================================================
    local coconutItem = createIntimItemWithSlider(intimGroupBox, "Coconut Penis", igStartY, 1, 15, 1, "Coconuts")

    local coconutEnabled = false
    local coconutTask = nil

    coconutItem.toggleBtn.MouseButton1Click:Connect(function()
        coconutEnabled = not coconutEnabled
        coconutItem.checkmark.Visible = coconutEnabled

        if coconutEnabled then
            coconutTask = task.spawn(function()
                local Me = game.Players.LocalPlayer
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
                local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

                local Offsets = {
                    [1] = CFrame.new(-0.45, -1.2, -0.7),
                    [2] = CFrame.new(0.45, -1.2, -0.7),
                    [3] = CFrame.new(0, -1, 0.8)
                }

                while coconutEnabled do
                    local Char = Me.Character
                    local Root = Char and Char:FindFirstChild("HumanoidRootPart")

                    if not Root then
                        task.wait(0.1)
                        continue
                    end

                    local Length = coconutItem.slider.currentValue

                    local Coconuts = {}
                    local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                    if toysFolder then
                        for _, toy in pairs(toysFolder:GetChildren()) do
                            if toy.Name == "FoodCoconut" then
                                table.insert(Coconuts, toy)
                            end
                        end
                    end

                    if #Coconuts < (Length + 2) then
                        task.spawn(function()
                            pcall(function()
                                SpawnToy:InvokeServer("FoodCoconut", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                            end)
                        end)
                    end

                    for i, Coco in ipairs(Coconuts) do
                        local Part = Coco:FindFirstChild("SoundPart")
                        local HoldPart = Coco:FindFirstChild("HoldPart")
                        local Rigid = HoldPart and HoldPart:FindFirstChild("RigidConstraint")
                        local PartOwner = Part and Part:FindFirstChild("PartOwner")

                        if Part and HoldPart and Rigid then
                            if PartOwner and PartOwner.Value == Me.Name then
                                if i <= 2 then
                                    Part.CFrame = Root.CFrame * Offsets[i] * CFrame.new(Root.Velocity / 100)
                                else
                                    Part.CFrame = Root.CFrame * Offsets[3] * CFrame.new(Root.Velocity / 100) * CFrame.new(0, 0, Offsets[3].Z - (i + 0.2))
                                end
                                Part.Velocity = Vector3.zero
                            end

                            if not PartOwner or PartOwner.Value ~= Me.Name then
                                pcall(function()
                                    SetNetworkOwner:FireServer(Part, Part.CFrame)
                                end)
                            end

                            if Rigid.Attachment1 then
                                pcall(function()
                                    DestroyToy:FireServer(Coco)
                                end)
                            end

                            for _, part in pairs(Coco:GetChildren()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                    part.CanQuery = false
                                    if part.Transparency ~= 1 then
                                        part.Transparency = 0
                                    end
                                end
                            end
                        end
                    end

                    task.wait(0.01)
                end
            end)
        else
            if coconutTask then
                task.cancel(coconutTask)
                coconutTask = nil
            end
        end
    end)

    -- ============================================================
    -- 2. COCONUT BOBS, ASS
    -- ============================================================
    local assBox, assToggleBtn, assCheckmark = createIntimItem(intimGroupBox, "Coconut Bobs, Ass", igStartY + (itemHeightWithSlider + gap) * 2 + itemHeightWithSlider + gap)

    local assEnabled = false
    local assTask = nil

    assToggleBtn.MouseButton1Click:Connect(function()
        assEnabled = not assEnabled
        assCheckmark.Visible = assEnabled

        if assEnabled then
            assTask = task.spawn(function()
                local Me = game.Players.LocalPlayer
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
                local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

                local Offsets = {
                    [1] = CFrame.new(0.45, -1.4, 0.7),
                    [2] = CFrame.new(-0.45, -1.4, 0.7),
                    [3] = CFrame.new(0.45, 0.4, -0.8),
                    [4] = CFrame.new(-0.45, 0.4, -0.8),
                }

                while assEnabled do
                    local Char = Me.Character
                    local Root = Char and Char:FindFirstChild("HumanoidRootPart")

                    if not Root then
                        task.wait(0.1)
                        continue
                    end

                    local Coconuts = {}
                    local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                    if toysFolder then
                        for _, toy in pairs(toysFolder:GetChildren()) do
                            if toy.Name == "FoodCoconut" then
                                table.insert(Coconuts, toy)
                            end
                        end
                    end

                    if #Coconuts < 4 then
                        task.spawn(function()
                            pcall(function()
                                SpawnToy:InvokeServer("FoodCoconut", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                            end)
                        end)
                    end

                    for i, Coco in ipairs(Coconuts) do
                        local Part = Coco:FindFirstChild("SoundPart")
                        local HoldPart = Coco:FindFirstChild("HoldPart")
                        local Rigid = HoldPart and HoldPart:FindFirstChild("RigidConstraint")
                        local PartOwner = Part and Part:FindFirstChild("PartOwner")

                        if Part and HoldPart and Rigid then
                            if PartOwner and PartOwner.Value == Me.Name then
                                if i <= 4 then
                                    Part.CFrame = Root.CFrame * Offsets[i] * CFrame.new(Root.Velocity / 100)
                                else
                                    Part.CFrame = Root.CFrame * CFrame.new(0, -10, 10)
                                end
                                Part.Velocity = Vector3.zero
                            end

                            if not PartOwner or PartOwner.Value ~= Me.Name then
                                pcall(function()
                                    SetNetworkOwner:FireServer(Part, Part.CFrame)
                                end)
                            end

                            if Rigid.Attachment1 then
                                pcall(function()
                                    DestroyToy:FireServer(Coco)
                                end)
                            end

                            for _, part in pairs(Coco:GetChildren()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                    part.CanQuery = false
                                    if part.Transparency ~= 1 then
                                        part.Transparency = 0
                                    end
                                end
                            end
                        end
                    end

                    task.wait(0.01)
                end
            end)
        else
            if assTask then
                task.cancel(assTask)
                assTask = nil
            end
        end
    end) 
    
    -- ============================================================
    -- 3. COCONUT TAIL (5 КОКОСОВ ПО НОВОЙ СХЕМЕ)
    -- ============================================================
    local tailBox, tailToggleBtn, tailCheckmark = createIntimItem(intimGroupBox, "Coconut Tail", igStartY + (itemHeightWithSlider + gap) * 2 + itemHeightWithSlider + gap + itemHeight + gap)

    local tailEnabled = false
    local tailTask = nil

    tailToggleBtn.MouseButton1Click:Connect(function()
        tailEnabled = not tailEnabled
        tailCheckmark.Visible = tailEnabled

        if tailEnabled then
            tailTask = task.spawn(function()
                local Me = game.Players.LocalPlayer
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
                local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

                -- 5 кокосов по схеме:
                -- 1: старт (-0.9, 0.7)
                -- 2: назад на 1 (Z +1) и вниз на 0.5 (Y -0.5) -> (-1.4, 1.7)
                -- 3: от 2 назад на 1 (Z +1), Y как у 2 -> (-1.4, 2.7)
                -- 4: от 3 назад на 1 (Z +1) и ВВЕРХ на 1 (Y -1) -> (-2.4, 3.7)
                -- 5: от 4 выше на 0.5 (Y -0.5) и ближе на 0.5 (Z -0.5) -> (-1.9, 3.2)
                local Offsets = {
                    [1] = CFrame.new(0, -0.9, 0.7),                                     -- 1: старт
                    [2] = CFrame.new(0, -1.4, 1.7),                                     -- 2: назад на 1, вниз на 0.5
                    [3] = CFrame.new(0, -0.9, 2.7),                                     -- 3: назад на 1, Y как у 2
                    [4] = CFrame.new(0, -0.2, 3.4),                                     -- 4: назад на 1, ВВЕРХ на 1 (Y -1)
                    [5] = CFrame.new(0, 0.7, 3),                                      -- 5: выше на 0.5, ближе на 0.5
                }

                while tailEnabled do
                    local Char = Me.Character
                    local Root = Char and Char:FindFirstChild("HumanoidRootPart")

                    if not Root then
                        task.wait(0.1)
                        continue
                    end

                    local Coconuts = {}
                    local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                    if toysFolder then
                        for _, toy in pairs(toysFolder:GetChildren()) do
                            if toy.Name == "FoodCoconut" then
                                table.insert(Coconuts, toy)
                            end
                        end
                    end

                    if #Coconuts < 5 then
                        task.spawn(function()
                            pcall(function()
                                SpawnToy:InvokeServer("FoodCoconut", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                            end)
                        end)
                    end

                    for i, Coco in ipairs(Coconuts) do
                        local Part = Coco:FindFirstChild("SoundPart")
                        local HoldPart = Coco:FindFirstChild("HoldPart")
                        local Rigid = HoldPart and HoldPart:FindFirstChild("RigidConstraint")
                        local PartOwner = Part and Part:FindFirstChild("PartOwner")

                        if Part and HoldPart and Rigid then
                            if PartOwner and PartOwner.Value == Me.Name then
                                if i <= 5 then
                                    Part.CFrame = Root.CFrame * Offsets[i] * CFrame.new(Root.Velocity / 100)
                                else
                                    Part.CFrame = Root.CFrame * CFrame.new(0, -10, 10)
                                end
                                Part.Velocity = Vector3.zero
                            end

                            if not PartOwner or PartOwner.Value ~= Me.Name then
                                pcall(function()
                                    SetNetworkOwner:FireServer(Part, Part.CFrame)
                                end)
                            end

                            if Rigid.Attachment1 then
                                pcall(function()
                                    DestroyToy:FireServer(Coco)
                                end)
                            end

                            for _, part in pairs(Coco:GetChildren()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                    part.CanQuery = false
                                    if part.Transparency ~= 1 then
                                        part.Transparency = 0
                                    end
                                end
                            end
                        end
                    end

                    task.wait(0.01)
                end
            end)
        else
            if tailTask then
                task.cancel(tailTask)
                tailTask = nil
            end
        end
    end)

    -- ============================================================
    -- DONUT ASS (1 ПОНЧИК СЗАДИ ПО ЦЕНТРУ, ПОВЕРНУТ НА 90°)
    -- ============================================================
    local donutBox, donutToggleBtn, donutCheckmark = createIntimItem(intimGroupBox, "Donut Ass", igStartY + (itemHeightWithSlider + gap) * 2 + itemHeightWithSlider + gap + (itemHeight + gap) * 2)

    local donutEnabled = false
    local donutTask = nil

    donutToggleBtn.MouseButton1Click:Connect(function()
        donutEnabled = not donutEnabled
        donutCheckmark.Visible = donutEnabled

        if donutEnabled then
            donutTask = task.spawn(function()
                local Me = game.Players.LocalPlayer
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
                local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

                local Offsets = {
                    [1] = CFrame.new(0, -0.9, 0.7) * CFrame.Angles(0, math.rad(90), 0),
                }

                while donutEnabled do
                    local Char = Me.Character
                    local Root = Char and Char:FindFirstChild("HumanoidRootPart")

                    if not Root then
                        task.wait(0.1)
                        continue
                    end

                    local Donuts = {}
                    local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                    if toysFolder then
                        for _, toy in pairs(toysFolder:GetChildren()) do
                            if toy.Name == "FoodDonut" then
                                table.insert(Donuts, toy)
                            end
                        end
                    end

                    if #Donuts < 1 then
                        task.spawn(function()
                            pcall(function()
                                SpawnToy:InvokeServer("FoodDonut", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                            end)
                        end)
                    end

                    for i, Donut in ipairs(Donuts) do
                        local Part = Donut:FindFirstChild("SoundPart")
                        local HoldPart = Donut:FindFirstChild("HoldPart")
                        local Rigid = HoldPart and HoldPart:FindFirstChild("RigidConstraint")
                        local PartOwner = Part and Part:FindFirstChild("PartOwner")

                        if Part and HoldPart and Rigid then
                            if PartOwner and PartOwner.Value == Me.Name then
                                if i <= 1 then
                                    Part.CFrame = Root.CFrame * Offsets[i] * CFrame.new(Root.Velocity / 100)
                                else
                                    Part.CFrame = Root.CFrame * CFrame.new(0, -10, 10)
                                end
                                Part.Velocity = Vector3.zero
                            end

                            if not PartOwner or PartOwner.Value ~= Me.Name then
                                pcall(function()
                                    SetNetworkOwner:FireServer(Part, Part.CFrame)
                                end)
                            end

                            if Rigid.Attachment1 then
                                pcall(function()
                                    DestroyToy:FireServer(Donut)
                                end)
                            end

                            for _, part in pairs(Donut:GetChildren()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                    part.CanQuery = false
                                    if part.Transparency ~= 1 then
                                        part.Transparency = 0
                                    end
                                end
                            end
                        end
                    end

                    task.wait(0.01)
                end
            end)
        else
            if donutTask then
                task.cancel(donutTask)
                donutTask = nil
            end
        end
    end)

    -- ============================================================
    -- DONUT BOBS (2 ПОНЧИКА НА ГРУДЬ, ПОВЕРНУТЫ НА 180°)
    -- ============================================================
    local donutBobsBox, donutBobsToggleBtn, donutBobsCheckmark = createIntimItem(intimGroupBox, "Donut Bobs", igStartY + (itemHeightWithSlider + gap) * 2 + itemHeightWithSlider + gap + (itemHeight + gap) * 3)

    local donutBobsEnabled = false
    local donutBobsTask = nil

    donutBobsToggleBtn.MouseButton1Click:Connect(function()
        donutBobsEnabled = not donutBobsEnabled
        donutBobsCheckmark.Visible = donutBobsEnabled

        if donutBobsEnabled then
            donutBobsTask = task.spawn(function()
                local Me = game.Players.LocalPlayer
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
                local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

                -- 2 пончика на грудь, повернуты на 90°
                local Offsets = {
                    [1] = CFrame.new(0.45, 0.4, -0.8) * CFrame.Angles(0, math.rad(-90), 0),
                    [2] = CFrame.new(-0.45, 0.4, -0.8) * CFrame.Angles(0, math.rad(-90), 0),
                }

                while donutBobsEnabled do
                    local Char = Me.Character
                    local Root = Char and Char:FindFirstChild("HumanoidRootPart")

                    if not Root then
                        task.wait(0.1)
                        continue
                    end

                    local Donuts = {}
                    local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                    if toysFolder then
                        for _, toy in pairs(toysFolder:GetChildren()) do
                            if toy.Name == "FoodDonut" then
                                table.insert(Donuts, toy)
                            end
                        end
                    end

                    if #Donuts < 2 then
                        task.spawn(function()
                            pcall(function()
                                SpawnToy:InvokeServer("FoodDonut", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                            end)
                        end)
                    end

                    for i, Donut in ipairs(Donuts) do
                        local Part = Donut:FindFirstChild("SoundPart")
                        local HoldPart = Donut:FindFirstChild("HoldPart")
                        local Rigid = HoldPart and HoldPart:FindFirstChild("RigidConstraint")
                        local PartOwner = Part and Part:FindFirstChild("PartOwner")

                        if Part and HoldPart and Rigid then
                            if PartOwner and PartOwner.Value == Me.Name then
                                if i <= 2 then
                                    Part.CFrame = Root.CFrame * Offsets[i] * CFrame.new(Root.Velocity / 100)
                                else
                                    Part.CFrame = Root.CFrame * CFrame.new(0, -10, 10)
                                end
                                Part.Velocity = Vector3.zero
                            end

                            if not PartOwner or PartOwner.Value ~= Me.Name then
                                pcall(function()
                                    SetNetworkOwner:FireServer(Part, Part.CFrame)
                                end)
                            end

                            if Rigid.Attachment1 then
                                pcall(function()
                                    DestroyToy:FireServer(Donut)
                                end)
                            end

                            for _, part in pairs(Donut:GetChildren()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                    part.CanQuery = false
                                    if part.Transparency ~= 1 then
                                        part.Transparency = 0
                                    end
                                end
                            end
                        end
                    end

                    task.wait(0.01)
                end
            end)
        else
            if donutBobsTask then
                task.cancel(donutBobsTask)
                donutBobsTask = nil
            end
        end
    end)

    -- ============================================================
    -- KUNAI PENIS (С ПОЛЗУНКОМ ОТ 1 ДО 10, ПООЧЕРЕДНО)
    -- ============================================================
    local kunaiItem = createIntimItemWithSlider(intimGroupBox, "Kunai Penis", igStartY + itemHeightWithSlider + gap, 1, 10, 1, "Kunais")

    local kunaiEnabled = false
    local kunaiTask = nil

    -- ФУНКЦИЯ УДАЛЕНИЯ КУНАЕВ
    local function clearAttachedKunais()
        local inv = workspace:FindFirstChild(game.Players.LocalPlayer.Name .. "SpawnedInToys")
        local destroyRem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
        if inv and destroyRem then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == "NinjaKunai" then
                    pcall(function()
                        destroyRem:FireServer(v)
                    end)
                end
            end
        end
    end

    kunaiItem.toggleBtn.MouseButton1Click:Connect(function()
        kunaiEnabled = not kunaiEnabled
        kunaiItem.checkmark.Visible = kunaiEnabled

        if kunaiEnabled then
            kunaiTask = task.spawn(function()
                local Me = game.Players.LocalPlayer
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
                local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy
                local StickyPartEvent = ReplicatedStorage.PlayerEvents.StickyPartEvent

                while kunaiEnabled do
                    local Char = Me.Character
                    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
                    if not Root then
                        task.wait(0.1)
                    else
                        local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                        if toysFolder then
                            local Kunais = {}
                            for _, toy in pairs(toysFolder:GetChildren()) do
                                if toy.Name == "NinjaKunai" then
                                    table.insert(Kunais, toy)
                                end
                            end

                            local targetCount = kunaiItem.slider.currentValue

                            -- СПАВНИМ КУНАИ ПО ОЧЕРЕДИ
                            if #Kunais < targetCount then
                                -- Спавним 1 кунай за раз
                                task.spawn(function()
                                    pcall(function()
                                        SpawnToy:InvokeServer("NinjaKunai", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                                    end)
                                end)
                                task.wait(0.2)
                            else
                                -- УДАЛЯЕМ ЛИШНИЕ КУНАИ
                                for i = #Kunais, targetCount + 1, -1 do
                                    pcall(function()
                                        DestroyToy:FireServer(Kunais[i])
                                    end)
                                end

                                -- КРЕПИМ КУНАИ ПО ПОРЯДКУ
                                for i, Kunai in ipairs(Kunais) do
                                    if i > targetCount then break end

                                    local StickyPart = Kunai:FindFirstChild("StickyPart")
                                    if StickyPart then
                                        local SoundPart = Kunai:FindFirstChild("SoundPart") or Kunai:FindFirstChildWhichIsA("BasePart")
                                        if SoundPart then
                                            if not SoundPart:FindFirstChild("PartOwner") or SoundPart.PartOwner.Value ~= Me.Name then
                                                pcall(function()
                                                    SetNetworkOwner:FireServer(SoundPart, SoundPart.CFrame)
                                                end)
                                                task.wait(0.05)
                                            end
                                        end

                                        local firePart = Root:FindFirstChild("FirePlayerPart")
                                        if not firePart then
                                            firePart = Root
                                        end

                                        -- ПОЗИЦИЯ: интервал -2 по Z
                                        local offset = CFrame.new(0, -1, -1 + (i - 1) * -2) * CFrame.Angles(0, math.rad(90), 0)
                                        
                                        pcall(function()
                                            StickyPartEvent:FireServer(
                                                StickyPart,
                                                firePart,
                                                offset
                                            )
                                        end)

                                        for _, part in pairs(Kunai:GetDescendants()) do
                                            if part:IsA("BasePart") then
                                                part.CanCollide = false
                                                part.CanQuery = false
                                                if part.Transparency ~= 1 then
                                                    part.Transparency = 0
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else
            if kunaiTask then
                task.cancel(kunaiTask)
                kunaiTask = nil
            end
            clearAttachedKunais()
        end
    end)

    -- ============================================================
    -- PENCIL PENIS (TOOLPENCIL, ПОЛЗУНОК 1-10, ИНТЕРВАЛ -4)
    -- ============================================================
    local pencilItem = createIntimItemWithSlider(intimGroupBox, "Pencil Penis", igStartY + (itemHeightWithSlider + gap) * 2, 1, 10, 1, "Pencils")

    local pencilEnabled = false
    local pencilTask = nil

    -- ФУНКЦИЯ УДАЛЕНИЯ КАРАНДАШЕЙ (КАК У КУНАЯ)
    local function clearAttachedPencils()
        local inv = workspace:FindFirstChild(game.Players.LocalPlayer.Name .. "SpawnedInToys")
        local destroyRem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
        if inv and destroyRem then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == "ToolPencil" then
                    pcall(function()
                        destroyRem:FireServer(v)
                    end)
                end
            end
        end
    end

    pencilItem.toggleBtn.MouseButton1Click:Connect(function()
        pencilEnabled = not pencilEnabled
        pencilItem.checkmark.Visible = pencilEnabled

        if pencilEnabled then
            pencilTask = task.spawn(function()
                local Me = game.Players.LocalPlayer
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
                local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy
                local StickyPartEvent = ReplicatedStorage.PlayerEvents.StickyPartEvent

                while pencilEnabled do
                    local Char = Me.Character
                    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
                    if not Root then
                        task.wait(0.1)
                    else
                        local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                        if toysFolder then
                            local Pencils = {}
                            for _, toy in pairs(toysFolder:GetChildren()) do
                                if toy.Name == "ToolPencil" then
                                    table.insert(Pencils, toy)
                                end
                            end

                            local targetCount = pencilItem.slider.currentValue

                            if #Pencils < targetCount then
                                task.spawn(function()
                                    pcall(function()
                                        SpawnToy:InvokeServer("ToolPencil", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                                    end)
                                end)
                                task.wait(0.2)
                            else
                                for i = #Pencils, targetCount + 1, -1 do
                                    pcall(function()
                                        DestroyToy:FireServer(Pencils[i])
                                    end)
                                end

                                for i, Pencil in ipairs(Pencils) do
                                    if i > targetCount then break end

                                    local StickyPart = Pencil:FindFirstChild("StickyPart")
                                    if StickyPart then
                                        local SoundPart = Pencil:FindFirstChild("SoundPart") or Pencil:FindFirstChildWhichIsA("BasePart")
                                        if SoundPart then
                                            if not SoundPart:FindFirstChild("PartOwner") or SoundPart.PartOwner.Value ~= Me.Name then
                                                pcall(function()
                                                    SetNetworkOwner:FireServer(SoundPart, SoundPart.CFrame)
                                                end)
                                                task.wait(0.05)
                                            end
                                        end

                                        local firePart = Root:FindFirstChild("FirePlayerPart")
                                        if not firePart then
                                            firePart = Root
                                        end

                                        -- НИЖЕ НА 0.1 СМ (Y = -1.1) И ПОВОРОТ 90°
                                        local offset = CFrame.new(0, -1.1, -1 + (i - 1) * -4) * CFrame.Angles(0, math.rad(180), 0)
                                        
                                        pcall(function()
                                            StickyPartEvent:FireServer(
                                                StickyPart,
                                                firePart,
                                                offset
                                            )
                                        end)

                                        -- КАК У КУНАЯ — БЕЗ ИЗМЕНЕНИЯ МАТЕРИАЛА/ЦВЕТА
                                        for _, part in pairs(Pencil:GetDescendants()) do
                                            if part:IsA("BasePart") then
                                                part.CanCollide = false
                                                part.CanQuery = false
                                                if part.Transparency ~= 1 then
                                                    part.Transparency = 0
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else
            if pencilTask then
                task.cancel(pencilTask)
                pencilTask = nil
            end
            clearAttachedPencils()
        end
    end)
    
    -- ВЫСОТА (добавили Kunai Penis)
    local igHeight = igStartY + (2.15 * (itemHeightWithSlider + gap)) + gap + itemHeight + gap + itemHeight + gap + itemHeight + gap + itemHeight + gap + itemHeight + gap
    intimGroupBox.Size = UDim2.new(0, 300, 0, igHeight)

    -- ============================================================
    -- ВТОРОЙ ФРЕЙМ: STANDS (СПРАВА ОТ INTIM)
    -- ============================================================
    local standGroupBox = Instance.new("Frame")
    standGroupBox.Size = UDim2.new(0, 300, 0, 0)
    standGroupBox.Position = UDim2.new(0, 300 + 20 + gap, 0, 20)
    standGroupBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    standGroupBox.BackgroundTransparency = 0.25
    standGroupBox.ClipsDescendants = true
    standGroupBox.Parent = funContentArea

    local sgBoxCorner = Instance.new("UICorner")
    sgBoxCorner.CornerRadius = UDim.new(0, 18)
    sgBoxCorner.Parent = standGroupBox

    local sgBoxStroke = Instance.new("UIStroke")
    sgBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    sgBoxStroke.Transparency = 0.2
    sgBoxStroke.Thickness = 1.0
    sgBoxStroke.Parent = standGroupBox

    -- ЗАГОЛОВОК
    local sgTitle = Instance.new("TextLabel")
    sgTitle.Size = UDim2.new(1, -30, 0, 30)
    sgTitle.Position = UDim2.new(0, 15, 0, 8)
    sgTitle.BackgroundTransparency = 1
    sgTitle.TextXAlignment = Enum.TextXAlignment.Left
    sgTitle.Text = "Stands"
    sgTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    sgTitle.TextTransparency = 0.05
    sgTitle.TextSize = 16
    sgTitle.Font = Enum.Font.GothamBold
    sgTitle.Parent = standGroupBox

    -- ЧЕРТА
    local sgLine = Instance.new("Frame")
    sgLine.Size = UDim2.new(1, -30, 0, 1.5)
    sgLine.Position = UDim2.new(0, 15, 0, 42)
    sgLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    sgLine.BackgroundTransparency = 0.3
    sgLine.BorderSizePixel = 0
    sgLine.Parent = standGroupBox

    local sgStartY = 52
    local itemHeight = 48

    -- ============================================================
    -- 1. STAND 67 (10 КОКОСОВ ДЛЯ 6 + 8 КОКОСОВ ДЛЯ 7 = 18 КОКОСОВ)
    -- ============================================================
    local stand67Box, stand67ToggleBtn, stand67Checkmark = createIntimItem(standGroupBox, "Stand 67", sgStartY)

    local stand67Enabled = false
    local stand67Task = nil

    stand67ToggleBtn.MouseButton1Click:Connect(function()
        stand67Enabled = not stand67Enabled
        stand67Checkmark.Visible = stand67Enabled

        if stand67Enabled then
            stand67Task = task.spawn(function()
                local Me = game.Players.LocalPlayer
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
                local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

                local Offsets = {
                    -- === ЦИФРА 6 (1-10) ===
                    [1] = CFrame.new(-2.0, -2.0, 0.7),
                    [2] = CFrame.new(-0.8, -1.4, 0.7),
                    [3] = CFrame.new(-0.8, -0.2, 0.7),
                    [4] = CFrame.new(-2.0, 0.2, 0.7),
                    [5] = CFrame.new(-3.2, -0.2, 0.7),
                    [6] = CFrame.new(-3.2, -1.4, 0.7),
                    [7] = CFrame.new(-3.2, 0.9, 0.7),
                    [8] = CFrame.new(-3.2, 1.7, 0.7),
                    [9] = CFrame.new(-2.8, 2.3, 0.7),
                    [10] = CFrame.new(-2.2, 2.7, 0.7),

                    -- === ЦИФРА 7 (11-18) ===
                    [11] = CFrame.new(1.5, -2.0, 0.7),
                    [12] = CFrame.new(2.2, -1.0, 0.7),
                    [13] = CFrame.new(2.9, 0.0, 0.7),
                    [14] = CFrame.new(3.6, 1.0, 0.7),
                    [15] = CFrame.new(4.3, 2.0, 0.7),
                    [16] = CFrame.new(2.0, 2.5, 0.7),
                    [17] = CFrame.new(3.0, 2.5, 0.7),
                    [18] = CFrame.new(4.0, 2.5, 0.7),
                }

                while stand67Enabled do
                    local Char = Me.Character
                    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
                    if not Root then task.wait(0.1) continue end

                    local Coconuts = {}
                    local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                    if toysFolder then
                        for _, toy in pairs(toysFolder:GetChildren()) do
                            if toy.Name == "FoodCoconut" then table.insert(Coconuts, toy) end
                        end
                    end

                    if #Coconuts < 18 then
                        task.spawn(function()
                            pcall(function()
                                SpawnToy:InvokeServer("FoodCoconut", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                            end)
                        end)
                    end

                    for i, Coco in ipairs(Coconuts) do
                        local Part = Coco:FindFirstChild("SoundPart")
                        local HoldPart = Coco:FindFirstChild("HoldPart")
                        local Rigid = HoldPart and HoldPart:FindFirstChild("RigidConstraint")
                        local PartOwner = Part and Part:FindFirstChild("PartOwner")

                        if Part and HoldPart and Rigid then
                            if PartOwner and PartOwner.Value == Me.Name then
                                if i <= 18 then
                                    Part.CFrame = Root.CFrame * Offsets[i] * CFrame.new(Root.Velocity / 100)
                                else
                                    Part.CFrame = Root.CFrame * CFrame.new(0, -10, 10)
                                end
                                Part.Velocity = Vector3.zero
                            end

                            if not PartOwner or PartOwner.Value ~= Me.Name then
                                pcall(function() SetNetworkOwner:FireServer(Part, Part.CFrame) end)
                            end

                            if Rigid.Attachment1 then
                                pcall(function() DestroyToy:FireServer(Coco) end)
                            end

                            for _, part in pairs(Coco:GetChildren()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                    part.CanQuery = false
                                    if part.Transparency ~= 1 then part.Transparency = 0 end
                                end
                            end
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else
            if stand67Task then task.cancel(stand67Task); stand67Task = nil end
        end
    end)

    -- ============================================================
    -- 2. PICKAXE (SHAHTER) — КИРКА НА СПИНЕ (STICKYPARTEVENT)
    -- ============================================================
    local pickaxeBox, pickaxeToggleBtn, pickaxeCheckmark = createIntimItem(standGroupBox, "Pickaxe (Shahter)", sgStartY + itemHeight + gap)

    local pickaxeEnabled = false
    local pickaxeTask = nil

    -- ФУНКЦИЯ УДАЛЕНИЯ КИРКИ
    local function clearPickaxe()
        local inv = workspace:FindFirstChild(game.Players.LocalPlayer.Name .. "SpawnedInToys")
        local destroyRem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
        if inv and destroyRem then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == "ToolPickaxe" then
                    pcall(function()
                        destroyRem:FireServer(v)
                    end)
                end
            end
        end
        -- Удаляем FirePlayerPart
        local char = game.Players.LocalPlayer.Character
        if char then
            local fp = char:FindFirstChild("FirePlayerPart")
            if fp then
                fp:Destroy()
            end
        end
    end

    pickaxeToggleBtn.MouseButton1Click:Connect(function()
        pickaxeEnabled = not pickaxeEnabled
        pickaxeCheckmark.Visible = pickaxeEnabled

        if pickaxeEnabled then
            pickaxeTask = task.spawn(function()
                local Me = game.Players.LocalPlayer
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
                local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy
                local StickyPartEvent = ReplicatedStorage.PlayerEvents.StickyPartEvent

                local isAttached = false
                local attachedPick = nil

                while pickaxeEnabled do
                    local Char = Me.Character
                    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
                    if not Root then
                        task.wait(0.5)
                        isAttached = false
                        attachedPick = nil
                    else
                        local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                        if toysFolder then
                            local Pick = nil
                            for _, toy in pairs(toysFolder:GetChildren()) do
                                if toy.Name == "ToolPickaxe" then
                                    Pick = toy
                                    break
                                end
                            end

                            if not Pick then
                                task.spawn(function()
                                    pcall(function()
                                        SpawnToy:InvokeServer("ToolPickaxe", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                                    end)
                                end)
                                task.wait(0.3)
                                isAttached = false
                                attachedPick = nil
                            else
                                -- ПРОВЕРЯЕМ УЖЕ ПРИКРЕПЛЕНА ЛИ КИРКА
                                local StickyPart = Pick:FindFirstChild("StickyPart")
                                if StickyPart then
                                    local SoundPart = Pick:FindFirstChild("SoundPart") or Pick:FindFirstChildWhichIsA("BasePart")
                                    
                                    -- ПРОВЕРЯЕМ ЕСТЬ ЛИ WELD НА STICKYPART
                                    local isStuck = false
                                    local stickyWeld = StickyPart:FindFirstChild("StickyWeld")
                                    if stickyWeld and stickyWeld.Part1 then
                                        local firePart = Root:FindFirstChild("FirePlayerPart")
                                        if firePart and stickyWeld.Part1 == firePart then
                                            isStuck = true
                                        end
                                    end

                                    -- ЕСЛИ НЕ ПРИКРЕПЛЕНА - КРЕПИМ
                                    if not isAttached or not isStuck then
                                        if SoundPart then
                                            if not SoundPart:FindFirstChild("PartOwner") or SoundPart.PartOwner.Value ~= Me.Name then
                                                pcall(function()
                                                    SetNetworkOwner:FireServer(SoundPart, SoundPart.CFrame)
                                                end)
                                                task.wait(0.1)
                                            end
                                        end

                                        local firePart = Root:FindFirstChild("FirePlayerPart")
                                        if not firePart then
                                            firePart = Root
                                        end
                                        
                                        pcall(function()
                                            StickyPartEvent:FireServer(
                                                StickyPart,
                                                firePart,
                                                CFrame.new(0.4, 0.5, 0.8) * CFrame.Angles(math.rad(270), math.rad(45), 0)
                                            )
                                        end)
                                        isAttached = true
                                        attachedPick = Pick
                                    end

                                    -- ОТКЛЮЧАЕМ КОЛЛИЗИЮ
                                    for _, part in pairs(Pick:GetDescendants()) do
                                        if part:IsA("BasePart") then
                                            part.CanCollide = false
                                            part.CanQuery = false
                                            if part.Transparency ~= 1 then
                                                part.Transparency = 0
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.1) -- МЕНЬШАЯ НАГРУЗКА
                end
            end)
        else
            if pickaxeTask then
                task.cancel(pickaxeTask)
                pickaxeTask = nil
            end
            clearPickaxe()
        end
    end)

    -- ============================================================
    -- 3. GUITAR (GITARIST) — НА СПИНЕ
    -- ============================================================
    local guitarBox, guitarToggleBtn, guitarCheckmark = createIntimItem(standGroupBox, "Guitar (Gitarist)", sgStartY + itemHeight + gap + itemHeight + gap)

    local guitarEnabled = false
    local guitarTask = nil

    local function clearGuitar()
        local inv = workspace:FindFirstChild(game.Players.LocalPlayer.Name .. "SpawnedInToys")
        local destroyRem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
        if inv and destroyRem then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == "InstrumentGuitarAcoustic" then
                    pcall(function()
                        destroyRem:FireServer(v)
                    end)
                end
            end
        end
    end

    guitarToggleBtn.MouseButton1Click:Connect(function()
        guitarEnabled = not guitarEnabled
        guitarCheckmark.Visible = guitarEnabled

        if guitarEnabled then
            guitarTask = task.spawn(function()
                local Me = game.Players.LocalPlayer
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
                local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

                while guitarEnabled do
                    local Char = Me.Character
                    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
                    if not Root then
                        task.wait(0.5)
                    else
                        local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                        if toysFolder then
                            local Guitar = nil
                            for _, toy in pairs(toysFolder:GetChildren()) do
                                if toy.Name == "InstrumentGuitarAcoustic" then
                                    Guitar = toy
                                    break
                                end
                            end

                            if not Guitar then
                                task.spawn(function()
                                    pcall(function()
                                        SpawnToy:InvokeServer("InstrumentGuitarAcoustic", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                                    end)
                                end)
                                task.wait(0.3)
                            else
                                local SoundPart = Guitar:FindFirstChild("SoundPart")
                                local HoldPart = Guitar:FindFirstChild("HoldPart")
                                local Rigid = HoldPart and HoldPart:FindFirstChild("RigidConstraint")
                                local PartOwner = SoundPart and SoundPart:FindFirstChild("PartOwner")

                                if SoundPart and HoldPart and Rigid then
                                    if PartOwner and PartOwner.Value == Me.Name then
                                        SoundPart.CFrame = Root.CFrame * CFrame.new(0.5, -0.5, 0.7) * CFrame.Angles(math.rad(270), math.rad(325), math.rad(90))
                                        SoundPart.Velocity = Vector3.zero
                                    end

                                    if not PartOwner or PartOwner.Value ~= Me.Name then
                                        pcall(function()
                                            SetNetworkOwner:FireServer(SoundPart, SoundPart.CFrame)
                                        end)
                                    end

                                    if Rigid.Attachment1 then
                                        pcall(function()
                                            DestroyToy:FireServer(Guitar)
                                        end)
                                    end

                                    for _, part in pairs(Guitar:GetChildren()) do
                                        if part:IsA("BasePart") then
                                            part.CanCollide = false
                                            part.CanQuery = false
                                            if part.Transparency ~= 1 then
                                                part.Transparency = 0
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else
            if guitarTask then
                task.cancel(guitarTask)
                guitarTask = nil
            end
            clearGuitar()
        end
    end)

    -- ============================================================
    -- 4. COCONUT WINGS (ПОД GUITAR) С МАХАНИЕМ
    -- ============================================================
    local wingsBox = Instance.new("Frame")
    wingsBox.Size = UDim2.new(1, -gap * 2, 0, itemHeight)
    wingsBox.Position = UDim2.new(0, gap, 0, sgStartY + (itemHeight + gap) * 3)
    wingsBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    wingsBox.BackgroundTransparency = 0.25
    wingsBox.ClipsDescendants = true
    wingsBox.Parent = standGroupBox

    local wBoxCorner = Instance.new("UICorner")
    wBoxCorner.CornerRadius = UDim.new(0, 18)
    wBoxCorner.Parent = wingsBox

    local wBoxStroke = Instance.new("UIStroke")
    wBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    wBoxStroke.Transparency = 0.2
    wBoxStroke.Thickness = 1.0
    wBoxStroke.Parent = wingsBox

    local wToggleBtn = Instance.new("TextButton")
    wToggleBtn.Size = UDim2.new(1, -24, 1, -12)
    wToggleBtn.Position = UDim2.new(0, 12, 0, 6)
    wToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    wToggleBtn.BackgroundTransparency = 0.2
    wToggleBtn.Text = ""
    wToggleBtn.AutoButtonColor = false
    wToggleBtn.Parent = wingsBox

    local wToggleCorner = Instance.new("UICorner")
    wToggleCorner.CornerRadius = UDim.new(0, 14)
    wToggleCorner.Parent = wToggleBtn

    local wToggleStroke = Instance.new("UIStroke")
    wToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    wToggleStroke.Transparency = 0.2
    wToggleStroke.Thickness = 0.8
    wToggleStroke.Parent = wToggleBtn

    local wToggleLabel = Instance.new("TextLabel")
    wToggleLabel.Size = UDim2.new(1, -40, 1, 0)
    wToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    wToggleLabel.BackgroundTransparency = 1
    wToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    wToggleLabel.Text = "Coconut Wings"
    wToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    wToggleLabel.TextSize = 12
    wToggleLabel.Font = Enum.Font.GothamBold
    wToggleLabel.Parent = wToggleBtn

    local wCheckboxBox = Instance.new("Frame")
    wCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
    wCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
    wCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
    wCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    wCheckboxBox.BackgroundTransparency = 0.2
    wCheckboxBox.BorderSizePixel = 0
    wCheckboxBox.Parent = wToggleBtn

    local wCbCorner = Instance.new("UICorner")
    wCbCorner.CornerRadius = UDim.new(0, 6)
    wCbCorner.Parent = wCheckboxBox

    local wCbStroke = Instance.new("UIStroke")
    wCbStroke.Color = Color3.fromRGB(150, 150, 150)
    wCbStroke.Transparency = 0.2
    wCbStroke.Thickness = 1
    wCbStroke.Parent = wCheckboxBox

    local wCheckmark = Instance.new("TextLabel")
    wCheckmark.Size = UDim2.new(1, 0, 1, 0)
    wCheckmark.BackgroundTransparency = 1
    wCheckmark.Text = "✓"
    wCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    wCheckmark.TextSize = 14
    wCheckmark.Font = Enum.Font.GothamBold
    wCheckmark.Visible = false
    wCheckmark.Parent = wCheckboxBox

    local wingsEnabled = false
    local wingsTask = nil

    wToggleBtn.MouseButton1Click:Connect(function()
        wingsEnabled = not wingsEnabled
        wCheckmark.Visible = wingsEnabled

        if wingsEnabled then
            wingsTask = task.spawn(function()
                local Me = game.Players.LocalPlayer
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
                local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

                local time = 0

                while wingsEnabled do
                    time = time + 0.02
                    local wingAngle = math.sin(time * 2) * 0.5 -- махание вверх-вниз
                    local wingSpread = math.sin(time * 1.5) * 0.3 -- размах

                    -- ЛЕВОЕ КРЫЛО
                    local leftOffset = CFrame.Angles(wingAngle, wingSpread, 0)
                    -- ПРАВОЕ КРЫЛО
                    local rightOffset = CFrame.Angles(-wingAngle, -wingSpread, 0)

                    local Offsets = {
                        -- ЛЕВОЕ КРЫЛО (8 кокосов)
                        [1] = CFrame.new(1, 0, 1) * leftOffset,
                        [2] = CFrame.new(2.2, 0.5, 1.3) * leftOffset,
                        [3] = CFrame.new(3.4, 1, 1.6) * leftOffset,
                        [4] = CFrame.new(4.6, 0.5, 1.3) * leftOffset,
                        [5] = CFrame.new(5.8, 0, 1) * leftOffset,
                        [6] = CFrame.new(2.4, -0.5, 1.6) * leftOffset,
                        [7] = CFrame.new(4.6, -0.5, 1.6) * leftOffset,
                        [8] = CFrame.new(4.2, -1.5, 1.3) * leftOffset,

                        -- ПРАВОЕ КРЫЛО (8 кокосов) - ЗЕРКАЛЬНО
                        [9] = CFrame.new(-1, 0, 1) * rightOffset,
                        [10] = CFrame.new(-2.2, 0.5, 1.3) * rightOffset,
                        [11] = CFrame.new(-3.4, 1, 1.6) * rightOffset,
                        [12] = CFrame.new(-4.6, 0.5, 1.3) * rightOffset,
                        [13] = CFrame.new(-5.8, 0, 1) * rightOffset,
                        [14] = CFrame.new(-2.4, -0.5, 1.6) * rightOffset,
                        [15] = CFrame.new(-4.6, -0.5, 1.6) * rightOffset,
                        [16] = CFrame.new(-4.2, -1.5, 1.3) * rightOffset,
                    }

                    local Char = Me.Character
                    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
                    if not Root then
                        task.wait(0.1)
                    else
                        local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                        if toysFolder then
                            local Coconuts = {}
                            for _, toy in pairs(toysFolder:GetChildren()) do
                                if toy.Name == "FoodCoconut" then
                                    table.insert(Coconuts, toy)
                                end
                            end

                            if #Coconuts < 16 then
                                task.spawn(function()
                                    pcall(function()
                                        SpawnToy:InvokeServer("FoodCoconut", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                                    end)
                                end)
                            end

                            for i, Coco in ipairs(Coconuts) do
                                if i > 16 then break end
                                local Part = Coco:FindFirstChild("SoundPart")
                                local HoldPart = Coco:FindFirstChild("HoldPart")
                                local Rigid = HoldPart and HoldPart:FindFirstChild("RigidConstraint")
                                local PartOwner = Part and Part:FindFirstChild("PartOwner")

                                if Part and HoldPart and Rigid then
                                    if PartOwner and PartOwner.Value == Me.Name then
                                        Part.CFrame = Root.CFrame * Offsets[i]
                                        Part.Velocity = Vector3.zero
                                    end

                                    if not PartOwner or PartOwner.Value ~= Me.Name then
                                        pcall(function()
                                            SetNetworkOwner:FireServer(Part, Part.CFrame)
                                        end)
                                    end

                                    if Rigid.Attachment1 then
                                        pcall(function()
                                            DestroyToy:FireServer(Coco)
                                        end)
                                    end

                                    for _, part in pairs(Coco:GetChildren()) do
                                        if part:IsA("BasePart") then
                                            part.CanCollide = false
                                            part.CanQuery = false
                                            if part.Transparency ~= 1 then
                                                part.Transparency = 0
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else
            if wingsTask then
                task.cancel(wingsTask)
                wingsTask = nil
            end
            local Me = game.Players.LocalPlayer
            local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
            if toysFolder then
                for _, toy in pairs(toysFolder:GetChildren()) do
                    if toy.Name == "FoodCoconut" then
                        pcall(function()
                            DestroyToy:FireServer(toy)
                        end)
                    end
                end
            end
        end
    end)

    -- ============================================================
    -- COCONUT RING (КОЛЬЦО ИЗ КОКОСОВ ВОКРУГ ИГРОКА)
    -- ============================================================
    local ringBox = Instance.new("Frame")
    ringBox.Size = UDim2.new(1, -gap * 2, 0, itemHeight)
    ringBox.Position = UDim2.new(0, gap, 0, sgStartY + (itemHeight + gap) * 4)
    ringBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    ringBox.BackgroundTransparency = 0.25
    ringBox.ClipsDescendants = true
    ringBox.Parent = standGroupBox

    local rBoxCorner = Instance.new("UICorner")
    rBoxCorner.CornerRadius = UDim.new(0, 18)
    rBoxCorner.Parent = ringBox

    local rBoxStroke = Instance.new("UIStroke")
    rBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    rBoxStroke.Transparency = 0.2
    rBoxStroke.Thickness = 1.0
    rBoxStroke.Parent = ringBox

    local rToggleBtn = Instance.new("TextButton")
    rToggleBtn.Size = UDim2.new(1, -24, 1, -12)
    rToggleBtn.Position = UDim2.new(0, 12, 0, 6)
    rToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    rToggleBtn.BackgroundTransparency = 0.2
    rToggleBtn.Text = ""
    rToggleBtn.AutoButtonColor = false
    rToggleBtn.Parent = ringBox

    local rToggleCorner = Instance.new("UICorner")
    rToggleCorner.CornerRadius = UDim.new(0, 14)
    rToggleCorner.Parent = rToggleBtn

    local rToggleStroke = Instance.new("UIStroke")
    rToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    rToggleStroke.Transparency = 0.2
    rToggleStroke.Thickness = 0.8
    rToggleStroke.Parent = rToggleBtn

    local rToggleLabel = Instance.new("TextLabel")
    rToggleLabel.Size = UDim2.new(1, -40, 1, 0)
    rToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    rToggleLabel.BackgroundTransparency = 1
    rToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    rToggleLabel.Text = "Coconut Ring"
    rToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    rToggleLabel.TextSize = 12
    rToggleLabel.Font = Enum.Font.GothamBold
    rToggleLabel.Parent = rToggleBtn

    local rCheckboxBox = Instance.new("Frame")
    rCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
    rCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
    rCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
    rCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    rCheckboxBox.BackgroundTransparency = 0.2
    rCheckboxBox.BorderSizePixel = 0
    rCheckboxBox.Parent = rToggleBtn

    local rCbCorner = Instance.new("UICorner")
    rCbCorner.CornerRadius = UDim.new(0, 6)
    rCbCorner.Parent = rCheckboxBox

    local rCbStroke = Instance.new("UIStroke")
    rCbStroke.Color = Color3.fromRGB(150, 150, 150)
    rCbStroke.Transparency = 0.2
    rCbStroke.Thickness = 1
    rCbStroke.Parent = rCheckboxBox

    local rCheckmark = Instance.new("TextLabel")
    rCheckmark.Size = UDim2.new(1, 0, 1, 0)
    rCheckmark.BackgroundTransparency = 1
    rCheckmark.Text = "✓"
    rCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    rCheckmark.TextSize = 14
    rCheckmark.Font = Enum.Font.GothamBold
    rCheckmark.Visible = false
    rCheckmark.Parent = rCheckboxBox

    local ringEnabled = false
    local ringTask = nil

    rToggleBtn.MouseButton1Click:Connect(function()
        ringEnabled = not ringEnabled
        rCheckmark.Visible = ringEnabled

        if ringEnabled then
            ringTask = task.spawn(function()
                local Me = game.Players.LocalPlayer
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
                local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

                local angle = 0
                local time = 0
                local ringRadius = 20 -- РАДИУС 10 СТУДОВ
                local coconutCount = 16 -- 16 КОКОСОВ

                -- БАЗОВЫЕ ПОЗИЦИИ КОКОСОВ (БЕЗ ВРАЩЕНИЯ)
                local baseOffsets = {}
                for i = 1, coconutCount do
                    local angleOffset = (i / coconutCount) * math.pi * 2
                    local x = math.cos(angleOffset) * ringRadius
                    local z = math.sin(angleOffset) * ringRadius
                    baseOffsets[i] = CFrame.new(x, 0, z)
                end

                while ringEnabled do
                    local Char = Me.Character
                    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
                    if not Root then
                        task.wait(0.1)
                    else
                        local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                        if toysFolder then
                            local Coconuts = {}
                            for _, toy in pairs(toysFolder:GetChildren()) do
                                if toy.Name == "FoodCoconut" then
                                    table.insert(Coconuts, toy)
                                end
                            end

                            -- КАК В WINGS - СПАВНИМ ПО 1 КОКОСУ
                            if #Coconuts < coconutCount then
                                task.spawn(function()
                                    pcall(function()
                                        SpawnToy:InvokeServer("FoodCoconut", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                                    end)
                                end)
                            end

                            -- КАК В WINGS - КРЕПИМ ВСЕ КОКОСЫ В ЭТОМ ЖЕ ЦИКЛЕ
                            angle = angle + 0.025
                            time = time + 0.03
                            if angle > math.pi * 2 then angle = 0 end

                            for i, Coco in ipairs(Coconuts) do
                                if i > coconutCount then break end
                                local Part = Coco:FindFirstChild("SoundPart")
                                local HoldPart = Coco:FindFirstChild("HoldPart")
                                local Rigid = HoldPart and HoldPart:FindFirstChild("RigidConstraint")
                                local PartOwner = Part and Part:FindFirstChild("PartOwner")

                                if Part and HoldPart and Rigid then
                                    -- ВРАЩАЕМ ВЕСЬ КРУГ
                                    local rotCF = CFrame.Angles(0, angle, 0)
                                    
                                    -- ПОДЪЕМ/ОПУСКАНИЕ: четные вверх, нечетные вниз
                                    local yOffset = 0
                                    if i % 2 == 0 then
                                        yOffset = math.sin(time * 2) * 1 -- четные вверх
                                    else
                                        yOffset = -math.sin(time * 2) * 1 -- нечетные вниз
                                    end
                                    
                                    local finalPos = rotCF * baseOffsets[i]
                                    local posWithY = CFrame.new(finalPos.X, yOffset, finalPos.Z)
                                    local lookAtCenter = CFrame.lookAt(Vector3.new(0, 0, 0), Vector3.new(finalPos.X, 0, finalPos.Z))
                                    local finalCF = posWithY * lookAtCenter

                                    if PartOwner and PartOwner.Value == Me.Name then
                                        Part.CFrame = Root.CFrame * finalCF
                                        Part.Velocity = Vector3.zero
                                    end

                                    if not PartOwner or PartOwner.Value ~= Me.Name then
                                        pcall(function()
                                            SetNetworkOwner:FireServer(Part, Part.CFrame)
                                        end)
                                    end

                                    if Rigid.Attachment1 then
                                        pcall(function()
                                            DestroyToy:FireServer(Coco)
                                        end)
                                    end

                                    for _, part in pairs(Coco:GetChildren()) do
                                        if part:IsA("BasePart") then
                                            part.CanCollide = false
                                            part.CanQuery = false
                                            if part.Transparency ~= 1 then
                                                part.Transparency = 0
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else
            if ringTask then
                task.cancel(ringTask)
                ringTask = nil
            end
            local Me = game.Players.LocalPlayer
            local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
            if toysFolder then
                for _, toy in pairs(toysFolder:GetChildren()) do
                    if toy.Name == "FoodCoconut" then
                        pcall(function()
                            DestroyToy:FireServer(toy)
                        end)
                    end
                end
            end
        end
    end)

    -- ВЫСОТА ФРЕЙМА STAND
    local sgHeight = sgStartY + (itemHeight + gap) + (itemHeight + gap) + (itemHeight + gap) + (itemHeight + gap) + itemHeight + gap
    standGroupBox.Size = UDim2.new(0, 300, 0, sgHeight)
	
-- ============================================================
-- SPOT RINGS (ПОД STANDS) - С ОТКЛЮЧЕНИЕМ КОЛЛИЗИИ
-- ============================================================
local spotRingsGroupBox = Instance.new("Frame")
spotRingsGroupBox.Size = UDim2.new(0, 300, 0, 0)
spotRingsGroupBox.Position = UDim2.new(0, 330, 0, 20 + sgHeight + gap)
spotRingsGroupBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
spotRingsGroupBox.BackgroundTransparency = 0.25
spotRingsGroupBox.ClipsDescendants = true
spotRingsGroupBox.Parent = funContentArea

local srBoxCorner = Instance.new("UICorner")
srBoxCorner.CornerRadius = UDim.new(0, 18)
srBoxCorner.Parent = spotRingsGroupBox

local srBoxStroke = Instance.new("UIStroke")
srBoxStroke.Color = Color3.fromRGB(180, 180, 180)
srBoxStroke.Transparency = 0.2
srBoxStroke.Thickness = 1.0
srBoxStroke.Parent = spotRingsGroupBox

local srTitle = Instance.new("TextLabel")
srTitle.Size = UDim2.new(1, -30, 0, 30)
srTitle.Position = UDim2.new(0, 15, 0, 8)
srTitle.BackgroundTransparency = 1
srTitle.TextXAlignment = Enum.TextXAlignment.Left
srTitle.Text = "Spot Rings"
srTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
srTitle.TextTransparency = 0.05
srTitle.TextSize = 16
srTitle.Font = Enum.Font.GothamBold
srTitle.Parent = spotRingsGroupBox

local srLine = Instance.new("Frame")
srLine.Size = UDim2.new(1, -30, 0, 1.5)
srLine.Position = UDim2.new(0, 15, 0, 42)
srLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
srLine.BackgroundTransparency = 0.3
srLine.BorderSizePixel = 0
srLine.Parent = spotRingsGroupBox

local srStartY = 52
local srItemHeight = 48

-- ============================================================
-- ВЫБОР РИНГА (ДРОПДАУН)
-- ============================================================
local selectRingBox = Instance.new("Frame")
selectRingBox.Size = UDim2.new(1, -gap * 2, 0, srItemHeight)
selectRingBox.Position = UDim2.new(0, gap, 0, srStartY)
selectRingBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
selectRingBox.BackgroundTransparency = 0.25
selectRingBox.ClipsDescendants = true
selectRingBox.Parent = spotRingsGroupBox

local srBoxCorner2 = Instance.new("UICorner")
srBoxCorner2.CornerRadius = UDim.new(0, 18)
srBoxCorner2.Parent = selectRingBox

local srBoxStroke2 = Instance.new("UIStroke")
srBoxStroke2.Color = Color3.fromRGB(180, 180, 180)
srBoxStroke2.Transparency = 0.2
srBoxStroke2.Thickness = 1.0
srBoxStroke2.Parent = selectRingBox

local selectRingBtn = Instance.new("TextButton")
selectRingBtn.Size = UDim2.new(1, -24, 0, 36)
selectRingBtn.Position = UDim2.new(0, 12, 0, 6)
selectRingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
selectRingBtn.BackgroundTransparency = 0.2
selectRingBtn.Text = ""
selectRingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
selectRingBtn.TextTransparency = 0.05
selectRingBtn.TextSize = 13
selectRingBtn.Font = Enum.Font.GothamBold
selectRingBtn.TextXAlignment = Enum.TextXAlignment.Left
selectRingBtn.Parent = selectRingBox

local srBtnCorner = Instance.new("UICorner")
srBtnCorner.CornerRadius = UDim.new(0, 14)
srBtnCorner.Parent = selectRingBtn

local srBtnStroke = Instance.new("UIStroke")
srBtnStroke.Color = Color3.fromRGB(180, 180, 180)
srBtnStroke.Transparency = 0.2
srBtnStroke.Thickness = 0.8
srBtnStroke.Parent = selectRingBtn

local selectRingLabel = Instance.new("TextLabel")
selectRingLabel.Size = UDim2.new(1, -40, 1, 0)
selectRingLabel.Position = UDim2.new(0, 17, 0, 0)
selectRingLabel.BackgroundTransparency = 1
selectRingLabel.TextXAlignment = Enum.TextXAlignment.Left
selectRingLabel.Text = "Select Ring"
selectRingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
selectRingLabel.TextTransparency = 0.05
selectRingLabel.TextSize = 13
selectRingLabel.Font = Enum.Font.GothamBold
selectRingLabel.Parent = selectRingBtn

local selectRingArrow = Instance.new("TextButton")
selectRingArrow.Size = UDim2.new(0, 30, 1, 0)
selectRingArrow.AnchorPoint = Vector2.new(1, 0.5)
selectRingArrow.Position = UDim2.new(1, -12, 0.5, 0)
selectRingArrow.BackgroundTransparency = 1
selectRingArrow.Text = "▸"
selectRingArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
selectRingArrow.TextTransparency = 0.3
selectRingArrow.TextSize = 16
selectRingArrow.Font = Enum.Font.GothamBold
selectRingArrow.Parent = selectRingBtn

-- ============================================================
-- ОПЦИИ РИНГОВ
-- ============================================================
local ringOptions = {
    {Name = "Ring 1 (Spiral)", Id = 1},
    {Name = "Ring 2 (Jumping)", Id = 2},
    {Name = "Ring 3 (Rain)", Id = 3},
    {Name = "Ring 4 (Snake)", Id = 4},
    {Name = "Ring 5 (Circle)", Id = 5},
}

local dropdownOpen = false
local listContainer = nil
local friendsScrollFrame = nil
local isAnimating = false
local activeRing = 0
local ring1Task = nil
local ring2Task = nil
local ring3Task = nil
local ring4Task = nil
local ring5Task = nil

-- ============================================================
-- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ УДАЛЕНИЯ ВСЕХ SPOTLIGHTBLUE
-- ============================================================
local function destroyAllSpotlights()
    local Me = game.Players.LocalPlayer
    local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
    if toysFolder then
        local destroyRem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
        if destroyRem then
            for _, toy in pairs(toysFolder:GetChildren()) do
                if toy.Name == "SpotlightBlue" then
                    pcall(function()
                        destroyRem:FireServer(toy)
                    end)
                end
            end
        end
    end
end

-- ============================================================
-- ФУНКЦИЯ ОТКЛЮЧЕНИЯ КОЛЛИЗИИ У ВСЕХ ЧАСТЕЙ
-- ============================================================
local function disableCollisionOnItem(item)
    if not item then return end
    for _, part in pairs(item:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            if part.Transparency ~= 1 then
                part.Transparency = 0
            end
        end
    end
end

-- ============================================================
-- RING 1 (SPIRAL)
-- ============================================================
local function stopRing1()
    if ring1Task then
        task.cancel(ring1Task)
        ring1Task = nil
    end
    destroyAllSpotlights()
end

local function startRing1()
    if ring1Task then
        task.cancel(ring1Task)
        ring1Task = nil
    end
    
    ring1Task = task.spawn(function()
        local Me = game.Players.LocalPlayer
        local RunService = game:GetService("RunService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
        local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

        destroyAllSpotlights()

        local angle = 0
        local ringRadius = 10
        local itemCount = 10
        local circleHeight = 19
        local spiralTop = 22
        local spiralBottom = 0
        
        local spiralHeights = {}
        for i = 1, itemCount do
            spiralHeights[i] = spiralTop - (i - 1) * ((spiralTop - spiralBottom) / (itemCount - 1))
        end

        local allSpawned = false
        local lastTime = tick()
        local transitionProgress = 0
        local inTransition = false
        local fixedItems = {}

        while activeRing == 1 do
            local Char = Me.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if not Root then
                task.wait(0.1)
            else
                local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                if toysFolder then
                    if not allSpawned then
                        fixedItems = {}
                        for _, toy in pairs(toysFolder:GetChildren()) do
                            if toy.Name == "SpotlightBlue" then
                                table.insert(fixedItems, toy)
                                disableCollisionOnItem(toy)
                            end
                        end
                        
                        if #fixedItems < itemCount then
                            task.spawn(function()
                                pcall(function()
                                    SpawnToy:InvokeServer("SpotlightBlue", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                                end)
                            end)
                            task.wait(0.05)
                        else
                            allSpawned = true
                            inTransition = true
                            transitionProgress = 0
                        end
                    end

                    local currentTime = tick()
                    local dt = math.min(currentTime - lastTime, 0.05)
                    lastTime = currentTime
                    
                    if inTransition then
                        transitionProgress = math.min(transitionProgress + dt * 1.5, 1)
                        if transitionProgress >= 1 then
                            inTransition = false
                        end
                    end
                    
                    angle = angle + dt * 3.6
                    if angle > math.pi * 2 then angle = angle - math.pi * 2 end

                    for i, Item in ipairs(fixedItems) do
                        if i > itemCount then break end
                        if not Item or not Item.Parent then continue end
                        
                        disableCollisionOnItem(Item)
                        
                        local angleOffset = (i / itemCount) * math.pi * 2
                        local currentAngle = angle + angleOffset
                        
                        local x = math.cos(currentAngle) * ringRadius
                        local z = math.sin(currentAngle) * ringRadius
                        
                        local yPos
                        if not allSpawned then
                            yPos = circleHeight
                        elseif inTransition then
                            local targetY = spiralHeights[i]
                            yPos = circleHeight + (targetY - circleHeight) * transitionProgress
                        else
                            yPos = spiralHeights[i]
                        end
                        
                        local pos = CFrame.new(x, yPos, z)
                        
                        local Part = Item:FindFirstChild("SoundPart") or Item:FindFirstChildWhichIsA("BasePart")
                        if Part then
                            pcall(function()
                                Part.CFrame = Root.CFrame * pos
                                Part.Velocity = Vector3.zero
                            end)
                        end
                    end
                end
            end
            task.wait(0.004)
        end
    end)
end

-- ============================================================
-- RING 2 (JUMPING)
-- ============================================================
local function stopRing2()
    if ring2Task then
        task.cancel(ring2Task)
        ring2Task = nil
    end
    destroyAllSpotlights()
end

local function startRing2()
    if ring2Task then
        task.cancel(ring2Task)
        ring2Task = nil
    end
    
    ring2Task = task.spawn(function()
        local Me = game.Players.LocalPlayer
        local RunService = game:GetService("RunService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
        local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

        destroyAllSpotlights()

        local angle = 0
        local ringRadius = 10
        local itemCount = 10
        local circleHeight = 19
        local ringRadiusSmall = 10
        local jumpDistance = 16
        local time = 0

        local allSpawned = false
        local lastTime = tick()
        local fixedItems = {}
        local phase = 0

        while activeRing == 2 do
            local Char = Me.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if not Root then
                task.wait(0.1)
            else
                local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                if toysFolder then
                    fixedItems = {}
                    for _, toy in pairs(toysFolder:GetChildren()) do
                        if toy.Name == "SpotlightBlue" then
                            table.insert(fixedItems, toy)
                            disableCollisionOnItem(toy)
                        end
                    end
                    
                    if #fixedItems < itemCount then
                        task.spawn(function()
                            pcall(function()
                                SpawnToy:InvokeServer("SpotlightBlue", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                            end)
                        end)
                    else
                        if not allSpawned then
                            allSpawned = true
                            phase = 1
                            time = 0
                        end
                    end

                    local currentTime = tick()
                    local dt = math.min(currentTime - lastTime, 0.05)
                    lastTime = currentTime
                    
                    time = time + dt

                    if phase == 0 then
                        angle = angle + dt * 3.6
                        if angle > math.pi * 2 then angle = angle - math.pi * 2 end

                        for i, Item in ipairs(fixedItems) do
                            if i > itemCount then break end
                            if not Item or not Item.Parent then continue end
                            
                            disableCollisionOnItem(Item)
                            
                            local angleOffset = (i / itemCount) * math.pi * 2
                            local currentAngle = angle + angleOffset
                            
                            local x = math.cos(currentAngle) * ringRadius
                            local z = math.sin(currentAngle) * ringRadius
                            
                            local pos = CFrame.new(x, circleHeight, z)
                            
                            local Part = Item:FindFirstChild("SoundPart") or Item:FindFirstChildWhichIsA("BasePart")
                            if Part then
                                pcall(function()
                                    Part.CFrame = Root.CFrame * pos
                                    Part.Velocity = Vector3.zero
                                end)
                            end
                        end
                    else
                        angle = angle + dt * 5.0
                        if angle > math.pi * 2 then angle = angle - math.pi * 2 end

                        local jumpPhase = math.sin(time * 8)
                        local isFirstGroup = jumpPhase > 0

                        for i, Item in ipairs(fixedItems) do
                            if i > itemCount then break end
                            if not Item or not Item.Parent then continue end
                            
                            disableCollisionOnItem(Item)
                            
                            local angleOffset = (i / itemCount) * math.pi * 2
                            local currentAngle = angle + angleOffset
                            
                            local x = math.cos(currentAngle) * ringRadiusSmall
                            local z = math.sin(currentAngle) * ringRadiusSmall
                            
                            local moveX = 0
                            local moveZ = 0
                            local jumpPower = math.abs(jumpPhase) * jumpDistance
                            
                            if isFirstGroup then
                                if i % 2 == 1 then
                                    local dirX = x / ringRadiusSmall
                                    local dirZ = z / ringRadiusSmall
                                    moveX = dirX * jumpPower
                                    moveZ = dirZ * jumpPower
                                end
                            else
                                if i % 2 == 0 then
                                    local dirX = x / ringRadiusSmall
                                    local dirZ = z / ringRadiusSmall
                                    moveX = dirX * jumpPower
                                    moveZ = dirZ * jumpPower
                                end
                            end
                            
                            local pos = CFrame.new(x + moveX, 0, z + moveZ)
                            
                            local Part = Item:FindFirstChild("SoundPart") or Item:FindFirstChildWhichIsA("BasePart")
                            if Part then
                                pcall(function()
                                    Part.CFrame = Root.CFrame * pos
                                    Part.Velocity = Vector3.zero
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(0.004)
        end
    end)
end

-- ============================================================
-- RING 3 (RAIN)
-- ============================================================
local function stopRing3()
    if ring3Task then
        task.cancel(ring3Task)
        ring3Task = nil
    end
    destroyAllSpotlights()
end

local function startRing3()
    if ring3Task then
        task.cancel(ring3Task)
        ring3Task = nil
    end
    
    ring3Task = task.spawn(function()
        local Me = game.Players.LocalPlayer
        local RunService = game:GetService("RunService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
        local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

        destroyAllSpotlights()

        local itemCount = 10
        local circleHeight = 19
        local allSpawned = false
        local lastTime = tick()
        local fixedItems = {}
        local phase = 0

        local rainPositions = {}
        for i = 1, itemCount do
            local x = math.random(-7, 7)
            local z = math.random(-7, 7)
            rainPositions[i] = {x = x, z = z}
        end

        local itemHeights = {}
        for i = 1, itemCount do
            itemHeights[i] = math.random(5, 20)
        end

        local fallSpeeds = {}
        for i = 1, itemCount do
            fallSpeeds[i] = math.random(20, 40) / 10
        end

        local angle = 0

        while activeRing == 3 do
            local Char = Me.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if not Root then
                task.wait(0.1)
            else
                local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                if toysFolder then
                    fixedItems = {}
                    for _, toy in pairs(toysFolder:GetChildren()) do
                        if toy.Name == "SpotlightBlue" then
                            table.insert(fixedItems, toy)
                            disableCollisionOnItem(toy)
                        end
                    end
                    
                    if #fixedItems < itemCount then
                        task.spawn(function()
                            pcall(function()
                                SpawnToy:InvokeServer("SpotlightBlue", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                            end)
                        end)
                    else
                        if not allSpawned then
                            allSpawned = true
                            phase = 1
                        end
                    end

                    local currentTime = tick()
                    local dt = math.min(currentTime - lastTime, 0.05)
                    lastTime = currentTime

                    if phase == 0 then
                        angle = angle + dt * 3.6
                        if angle > math.pi * 2 then angle = angle - math.pi * 2 end

                        for i, Item in ipairs(fixedItems) do
                            if i > itemCount then break end
                            if not Item or not Item.Parent then continue end
                            
                            disableCollisionOnItem(Item)
                            
                            local angleOffset = (i / itemCount) * math.pi * 2
                            local currentAngle = angle + angleOffset
                            
                            local x = math.cos(currentAngle) * 10
                            local z = math.sin(currentAngle) * 10
                            
                            local pos = CFrame.new(x, circleHeight, z)
                            
                            local Part = Item:FindFirstChild("SoundPart") or Item:FindFirstChildWhichIsA("BasePart")
                            if Part then
                                pcall(function()
                                    Part.CFrame = Root.CFrame * pos
                                    Part.Velocity = Vector3.zero
                                end)
                            end
                        end
                    else
                        for i, Item in ipairs(fixedItems) do
                            if i > itemCount then break end
                            if not Item or not Item.Parent then continue end
                            
                            disableCollisionOnItem(Item)
                            
                            local posData = rainPositions[i]
                            local x = posData.x
                            local z = posData.z
                            local y = itemHeights[i]
                            
                            local pos = CFrame.new(x, y, z)
                            
                            local Part = Item:FindFirstChild("SoundPart") or Item:FindFirstChildWhichIsA("BasePart")
                            if Part then
                                pcall(function()
                                    Part.CFrame = Root.CFrame * pos
                                    Part.Velocity = Vector3.zero
                                end)
                            end
                            
                            itemHeights[i] = itemHeights[i] - fallSpeeds[i] * dt * 8
                            
                            if itemHeights[i] < -5 then
                                itemHeights[i] = 20 + math.random(0, 5)
                                rainPositions[i] = {
                                    x = math.random(-7, 7),
                                    z = math.random(-7, 7)
                                }
                                fallSpeeds[i] = math.random(20, 40) / 10
                            end
                        end
                    end
                end
            end
            task.wait(0.004)
        end
    end)
end

-- ============================================================
-- RING 4 (SNAKE)
-- ============================================================
local function stopRing4()
    if ring4Task then
        task.cancel(ring4Task)
        ring4Task = nil
    end
    destroyAllSpotlights()
end

local function startRing4()
    if ring4Task then
        task.cancel(ring4Task)
        ring4Task = nil
    end
    
    ring4Task = task.spawn(function()
        local Me = game.Players.LocalPlayer
        local RunService = game:GetService("RunService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
        local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

        destroyAllSpotlights()

        local itemCount = 10
        local circleHeight = 19
        local allSpawned = false
        local lastTime = tick()
        local fixedItems = {}
        local phase = 0
        local angle = 0

        local snakeScale = 8

        while activeRing == 4 do
            local Char = Me.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if not Root then
                task.wait(0.1)
            else
                local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                if toysFolder then
                    fixedItems = {}
                    for _, toy in pairs(toysFolder:GetChildren()) do
                        if toy.Name == "SpotlightBlue" then
                            table.insert(fixedItems, toy)
                            disableCollisionOnItem(toy)
                        end
                    end
                    
                    if #fixedItems < itemCount then
                        task.spawn(function()
                            pcall(function()
                                SpawnToy:InvokeServer("SpotlightBlue", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                            end)
                        end)
                    else
                        if not allSpawned then
                            allSpawned = true
                            phase = 1
                        end
                    end

                    local currentTime = tick()
                    local dt = math.min(currentTime - lastTime, 0.05)
                    lastTime = currentTime

                    if phase == 0 then
                        angle = angle + dt * 3.6
                        if angle > math.pi * 2 then angle = angle - math.pi * 2 end

                        for i, Item in ipairs(fixedItems) do
                            if i > itemCount then break end
                            if not Item or not Item.Parent then continue end
                            
                            disableCollisionOnItem(Item)
                            
                            local angleOffset = (i / itemCount) * math.pi * 2
                            local currentAngle = angle + angleOffset
                            
                            local x = math.cos(currentAngle) * 10
                            local z = math.sin(currentAngle) * 10
                            
                            local pos = CFrame.new(x, circleHeight, z)
                            
                            local Part = Item:FindFirstChild("SoundPart") or Item:FindFirstChildWhichIsA("BasePart")
                            if Part then
                                pcall(function()
                                    Part.CFrame = Root.CFrame * pos
                                    Part.Velocity = Vector3.zero
                                end)
                            end
                        end
                    else
                        angle = angle + dt * 2.5

                        for i, Item in ipairs(fixedItems) do
                            if i > itemCount then break end
                            if not Item or not Item.Parent then continue end
                            
                            disableCollisionOnItem(Item)
                            
                            local offset = (i / itemCount) * math.pi * 2
                            local t = angle + offset
                            
                            local scale = snakeScale + 5
                            
                            local x = scale * math.sin(t)
                            local y = scale * math.sin(t) * math.cos(t) * 0.8
                            local z = scale * math.cos(t) * 0.5
                            
                            local rotAngle = t * 0.15
                            local rotX = x * math.cos(rotAngle) - z * math.sin(rotAngle)
                            local rotZ = x * math.sin(rotAngle) + z * math.cos(rotAngle)
                            
                            local pos = CFrame.new(rotX, y, rotZ)
                            
                            local Part = Item:FindFirstChild("SoundPart") or Item:FindFirstChildWhichIsA("BasePart")
                            if Part then
                                pcall(function()
                                    Part.CFrame = Root.CFrame * pos
                                    Part.Velocity = Vector3.zero
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(0.004)
        end
    end)
end

-- ============================================================
-- RING 5 (CIRCLE)
-- ============================================================
local function stopRing5()
    if ring5Task then
        task.cancel(ring5Task)
        ring5Task = nil
    end
    destroyAllSpotlights()
end

local function startRing5()
    if ring5Task then
        task.cancel(ring5Task)
        ring5Task = nil
    end
    
    ring5Task = task.spawn(function()
        local Me = game.Players.LocalPlayer
        local RunService = game:GetService("RunService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
        local DestroyToy = ReplicatedStorage.MenuToys.DestroyToy

        destroyAllSpotlights()

        local itemCount = 10
        local circleHeight = 19
        local allSpawned = false
        local lastTime = tick()
        local fixedItems = {}
        local phase = 0
        local angle = 0

        local circleRadius = 15

        while activeRing == 5 do
            local Char = Me.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if not Root then
                task.wait(0.1)
            else
                local toysFolder = workspace:FindFirstChild(Me.Name .. "SpawnedInToys")
                if toysFolder then
                    fixedItems = {}
                    for _, toy in pairs(toysFolder:GetChildren()) do
                        if toy.Name == "SpotlightBlue" then
                            table.insert(fixedItems, toy)
                            disableCollisionOnItem(toy)
                        end
                    end
                    
                    if #fixedItems < itemCount then
                        task.spawn(function()
                            pcall(function()
                                SpawnToy:InvokeServer("SpotlightBlue", Root.CFrame * CFrame.new(-5, 0, 10), Vector3.zero)
                            end)
                        end)
                    else
                        if not allSpawned then
                            allSpawned = true
                            phase = 1
                        end
                    end

                    local currentTime = tick()
                    local dt = math.min(currentTime - lastTime, 0.05)
                    lastTime = currentTime

                    if phase == 0 then
                        angle = angle + dt * 3.6
                        if angle > math.pi * 2 then angle = angle - math.pi * 2 end

                        for i, Item in ipairs(fixedItems) do
                            if i > itemCount then break end
                            if not Item or not Item.Parent then continue end
                            
                            disableCollisionOnItem(Item)
                            
                            local angleOffset = (i / itemCount) * math.pi * 2
                            local currentAngle = angle + angleOffset
                            
                            local x = math.cos(currentAngle) * 10
                            local z = math.sin(currentAngle) * 10
                            
                            local pos = CFrame.new(x, circleHeight, z)
                            
                            local Part = Item:FindFirstChild("SoundPart") or Item:FindFirstChildWhichIsA("BasePart")
                            if Part then
                                pcall(function()
                                    Part.CFrame = Root.CFrame * pos
                                    Part.Velocity = Vector3.zero
                                end)
                            end
                        end
                    else
                        angle = angle + dt * 3.75
                        
                        local wave = math.sin(tick() * 3)

                        for i, Item in ipairs(fixedItems) do
                            if i > itemCount then break end
                            if not Item or not Item.Parent then continue end
                            
                            disableCollisionOnItem(Item)
                            
                            local angleOffset = (i / itemCount) * math.pi * 2
                            local currentAngle = angle + angleOffset
                            
                            local x = math.cos(currentAngle) * circleRadius
                            local z = math.sin(currentAngle) * circleRadius
                            
                            local yOffset = 0
                            if i % 2 == 0 then
                                yOffset = wave * 2
                            else
                                yOffset = -wave * 2
                            end
                            
                            local rot = 0
                            if yOffset > 0.3 then
                                rot = math.rad(180)
                            elseif yOffset < -0.3 then
                                rot = 0
                            else
                                local t = (yOffset + 2) / 4
                                rot = math.rad(180) * (1 - t)
                            end
                            
                            local pos = CFrame.new(x, yOffset, z) * CFrame.Angles(rot, 0, 0)
                            
                            local Part = Item:FindFirstChild("SoundPart") or Item:FindFirstChildWhichIsA("BasePart")
                            if Part then
                                pcall(function()
                                    Part.CFrame = Root.CFrame * pos
                                    Part.Velocity = Vector3.zero
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(0.004)
        end
    end)
end

-- ============================================================
-- ФУНКЦИЯ ОТКРЫТИЯ/ЗАКРЫТИЯ ДРОПДАУНА
-- ============================================================
local function toggleDropdown()
    if isAnimating then return end
    
    if dropdownOpen then
        isAnimating = true
        
        local targetHeight = srItemHeight
        local targetDffHeight = srStartY + srItemHeight + gap
        
        local tween1 = TweenService:Create(selectRingBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -gap * 2, 0, targetHeight)
        })
        tween1:Play()
        
        local tween2 = TweenService:Create(spotRingsGroupBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 300, 0, targetDffHeight)
        })
        tween2:Play()
        tween1.Completed:Wait()
        
        if listContainer then
            listContainer:Destroy()
            listContainer = nil
            friendsScrollFrame = nil
        end
        
        dropdownOpen = false
        selectRingArrow.Text = "▸"
        isAnimating = false
    else
        isAnimating = true
        dropdownOpen = true
        selectRingArrow.Text = "▾"
        
        listContainer = Instance.new("Frame")
        listContainer.Size = UDim2.new(1, 0, 0, 0)
        listContainer.Position = UDim2.new(0, 0, 0, srItemHeight)
        listContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        listContainer.BackgroundTransparency = 1
        listContainer.ClipsDescendants = true
        listContainer.ZIndex = 10
        listContainer.Parent = selectRingBox

        friendsScrollFrame = Instance.new("ScrollingFrame")
        friendsScrollFrame.Size = UDim2.new(1, -10, 1, -10)
        friendsScrollFrame.Position = UDim2.new(0, 5, 0, 5)
        friendsScrollFrame.BackgroundTransparency = 1
        friendsScrollFrame.BorderSizePixel = 0
        friendsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        friendsScrollFrame.ScrollBarThickness = 4
        friendsScrollFrame.ClipsDescendants = true
        friendsScrollFrame.Parent = listContainer

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 4)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.Parent = friendsScrollFrame

        for i, opt in ipairs(ringOptions) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 36)
            btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            btn.BackgroundTransparency = 0.2
            btn.Text = opt.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 13
            btn.Font = Enum.Font.GothamBold
            btn.TextXAlignment = Enum.TextXAlignment.Center
            btn.Parent = friendsScrollFrame

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 14)
            btnCorner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                local id = opt.Id
                
                if activeRing == id then
                    activeRing = 0
                    selectRingLabel.Text = "Select Ring"
                    stopRing1()
                    stopRing2()
                    stopRing3()
                    stopRing4()
                    stopRing5()
                    
                    if listContainer then
                        listContainer:Destroy()
                        listContainer = nil
                        friendsScrollFrame = nil
                    end
                    dropdownOpen = false
                    selectRingArrow.Text = "▸"
                    selectRingBox.Size = UDim2.new(1, -gap * 2, 0, srItemHeight)
                    
                    local targetDffHeight = srStartY + srItemHeight + gap
                    local tween2 = TweenService:Create(spotRingsGroupBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 300, 0, targetDffHeight)
                    })
                    tween2:Play()
                    
                    isAnimating = false
                    return
                end
                
                activeRing = id
                selectRingLabel.Text = "Select Ring → " .. opt.Name
                
                if id == 1 then
                    startRing1()
                    stopRing2(); stopRing3(); stopRing4(); stopRing5()
                elseif id == 2 then
                    startRing2()
                    stopRing1(); stopRing3(); stopRing4(); stopRing5()
                elseif id == 3 then
                    startRing3()
                    stopRing1(); stopRing2(); stopRing4(); stopRing5()
                elseif id == 4 then
                    startRing4()
                    stopRing1(); stopRing2(); stopRing3(); stopRing5()
                elseif id == 5 then
                    startRing5()
                    stopRing1(); stopRing2(); stopRing3(); stopRing4()
                else
                    stopRing1(); stopRing2(); stopRing3(); stopRing4(); stopRing5()
                end
                
                if listContainer then
                    listContainer:Destroy()
                    listContainer = nil
                    friendsScrollFrame = nil
                end
                dropdownOpen = false
                selectRingArrow.Text = "▸"
                selectRingBox.Size = UDim2.new(1, -gap * 2, 0, srItemHeight)
                
                local targetDffHeight = srStartY + srItemHeight + gap
                local tween2 = TweenService:Create(spotRingsGroupBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 300, 0, targetDffHeight)
                })
                tween2:Play()
                
                isAnimating = false
            end)
        end

        local children = friendsScrollFrame:GetChildren()
        local totalHeight = #children * 31 + 10
        local listHeight = math.min(math.max(totalHeight, 50), 58)
        friendsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(totalHeight, friendsScrollFrame.Size.Y.Offset))
        
        listContainer.Size = UDim2.new(1, 0, 0, listHeight)
        
        local targetHeight = srItemHeight + listHeight
        local targetDffHeight = srStartY + targetHeight + gap
        
        local tween1 = TweenService:Create(selectRingBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -gap * 2, 0, targetHeight)
        })
        local tween2 = TweenService:Create(spotRingsGroupBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 300, 0, targetDffHeight)
        })
        tween1:Play()
        tween2:Play()
        tween1.Completed:Wait()
        isAnimating = false
    end
end

selectRingArrow.MouseButton1Click:Connect(toggleDropdown)
selectRingBtn.MouseButton1Click:Connect(function()
    if not dropdownOpen then
        toggleDropdown()
    end
end)

-- ВЫСОТА ФРЕЙМА
local srHeight = srStartY + srItemHeight + gap
spotRingsGroupBox.Size = UDim2.new(0, 300, 0, srHeight)
end

-- ============================================================================
-- DEFENSE TAB (ВЕРТИКАЛЬНО, КАК В PLAYER)
-- ============================================================================
local function setupDefenseTab(defenseContentArea)
	defenseContentArea.ClipsDescendants = true
	defenseContentArea.CanvasSize = UDim2.new(0, 0, 0, 950)

	local gap = 10
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local Workspace = game:GetService("Workspace")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	-- ============================================================
	-- ГРУППА 1: DEFENSE
	-- ============================================================
	local defenseGroupBox = Instance.new("Frame")
	defenseGroupBox.Size = UDim2.new(0, 300, 0, 0)
	defenseGroupBox.Position = UDim2.new(0, 20, 0, 20)
	defenseGroupBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	defenseGroupBox.BackgroundTransparency = 0.25
	defenseGroupBox.ClipsDescendants = true
	defenseGroupBox.Parent = defenseContentArea

	local dgBoxCorner = Instance.new("UICorner")
	dgBoxCorner.CornerRadius = UDim.new(0, 18)
	dgBoxCorner.Parent = defenseGroupBox

	local dgBoxStroke = Instance.new("UIStroke")
	dgBoxStroke.Color = Color3.fromRGB(180, 180, 180)
	dgBoxStroke.Transparency = 0.2
	dgBoxStroke.Thickness = 1.0
	dgBoxStroke.Parent = defenseGroupBox

	local dgTitle = Instance.new("TextLabel")
	dgTitle.Size = UDim2.new(1, -30, 0, 30)
	dgTitle.Position = UDim2.new(0, 15, 0, 8)
	dgTitle.BackgroundTransparency = 1
	dgTitle.TextXAlignment = Enum.TextXAlignment.Left
	dgTitle.Text = "Defense"
	dgTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	dgTitle.TextTransparency = 0.05
	dgTitle.TextSize = 16
	dgTitle.Font = Enum.Font.GothamBold
	dgTitle.Parent = defenseGroupBox

	local dgLine = Instance.new("Frame")
	dgLine.Size = UDim2.new(1, -30, 0, 1.5)
	dgLine.Position = UDim2.new(0, 15, 0, 42)
	dgLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
	dgLine.BackgroundTransparency = 0.3
	dgLine.BorderSizePixel = 0
	dgLine.Parent = defenseGroupBox

	local dgStartY = 52
	local itemHeight = 48

	local function createDefenseItem(parent, title, posY)
		local box = Instance.new("Frame")
		box.Size = UDim2.new(1, -gap * 2, 0, itemHeight)
		box.Position = UDim2.new(0, gap, 0, posY)
		box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
		box.BackgroundTransparency = 0.25
		box.ClipsDescendants = true
		box.Parent = parent

		local boxCorner = Instance.new("UICorner")
		boxCorner.CornerRadius = UDim.new(0, 18)
		boxCorner.Parent = box

		local boxStroke = Instance.new("UIStroke")
		boxStroke.Color = Color3.fromRGB(180, 180, 180)
		boxStroke.Transparency = 0.2
		boxStroke.Thickness = 1.0
		boxStroke.Parent = box

		local toggleBtn = Instance.new("TextButton")
		toggleBtn.Size = UDim2.new(1, -24, 1, -12)
		toggleBtn.Position = UDim2.new(0, 12, 0, 6)
		toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		toggleBtn.BackgroundTransparency = 0.2
		toggleBtn.Text = ""
		toggleBtn.AutoButtonColor = false
		toggleBtn.Parent = box

		local toggleCorner = Instance.new("UICorner")
		toggleCorner.CornerRadius = UDim.new(0, 14)
		toggleCorner.Parent = toggleBtn

		local toggleStroke = Instance.new("UIStroke")
		toggleStroke.Color = Color3.fromRGB(180, 180, 180)
		toggleStroke.Transparency = 0.2
		toggleStroke.Thickness = 0.8
		toggleStroke.Parent = toggleBtn

		local toggleLabel = Instance.new("TextLabel")
		toggleLabel.Size = UDim2.new(1, -40, 1, 0)
		toggleLabel.Position = UDim2.new(0, 12, 0, 0)
		toggleLabel.BackgroundTransparency = 1
		toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
		toggleLabel.Text = title
		toggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		toggleLabel.TextSize = 12
		toggleLabel.Font = Enum.Font.GothamBold
		toggleLabel.Parent = toggleBtn

		local checkboxBox = Instance.new("Frame")
		checkboxBox.Size = UDim2.new(0, 20, 0, 20)
		checkboxBox.AnchorPoint = Vector2.new(1, 0.5)
		checkboxBox.Position = UDim2.new(1, -12, 0.5, 0)
		checkboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
		checkboxBox.BackgroundTransparency = 0.2
		checkboxBox.BorderSizePixel = 0
		checkboxBox.Parent = toggleBtn

		local cbCorner = Instance.new("UICorner")
		cbCorner.CornerRadius = UDim.new(0, 6)
		cbCorner.Parent = checkboxBox

		local cbStroke = Instance.new("UIStroke")
		cbStroke.Color = Color3.fromRGB(150, 150, 150)
		cbStroke.Transparency = 0.2
		cbStroke.Thickness = 1
		cbStroke.Parent = checkboxBox

		local checkmark = Instance.new("TextLabel")
		checkmark.Size = UDim2.new(1, 0, 1, 0)
		checkmark.BackgroundTransparency = 1
		checkmark.Text = "✓"
		checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
		checkmark.TextSize = 14
		checkmark.Font = Enum.Font.GothamBold
		checkmark.Visible = false
		checkmark.Parent = checkboxBox

		return box, toggleBtn, checkmark
	end

	local defenseItems = {
		"Anti Grab",
		"Anti Kick",
		"AntiKick ITEM",
		"Anti Input",
		"Anti Snowball",
		"Auto Reset",
		"Auto Leave",
		"Anti Explosion",
		"Anti Burn",
		"Anti Sticky",
		"Anti Lag"
	}

	local defenseBoxes = {}
	local dgCurrentY = dgStartY

	for _, title in ipairs(defenseItems) do
		local box, btn, chk = createDefenseItem(defenseGroupBox, title, dgCurrentY)
		defenseBoxes[title] = {box = box, btn = btn, chk = chk}
		dgCurrentY = dgCurrentY + itemHeight + gap
	end

	local dgHeight = 32 + gap + (#defenseItems * (itemHeight + gap)) + gap
	defenseGroupBox.Size = UDim2.new(0, 300, 0, dgHeight)

	-- ============================================================
	-- ГРУППА 2: ADVANCED DEFENSE
	-- ============================================================
	local advDefenseGroupBox = Instance.new("Frame")
	advDefenseGroupBox.Size = UDim2.new(0, 300, 0, 0)
	advDefenseGroupBox.Position = UDim2.new(0, 300 + 20 + gap, 0, 20)
	advDefenseGroupBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	advDefenseGroupBox.BackgroundTransparency = 0.25
	advDefenseGroupBox.ClipsDescendants = true
	advDefenseGroupBox.Parent = defenseContentArea

	local adgBoxCorner = Instance.new("UICorner")
	adgBoxCorner.CornerRadius = UDim.new(0, 18)
	adgBoxCorner.Parent = advDefenseGroupBox

	local adgBoxStroke = Instance.new("UIStroke")
	adgBoxStroke.Color = Color3.fromRGB(180, 180, 180)
	adgBoxStroke.Transparency = 0.2
	adgBoxStroke.Thickness = 1.0
	adgBoxStroke.Parent = advDefenseGroupBox

	local adgTitle = Instance.new("TextLabel")
	adgTitle.Size = UDim2.new(1, -30, 0, 30)
	adgTitle.Position = UDim2.new(0, 15, 0, 8)
	adgTitle.BackgroundTransparency = 1
	adgTitle.TextXAlignment = Enum.TextXAlignment.Left
	adgTitle.Text = "Advanced Defense"
	adgTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	adgTitle.TextTransparency = 0.05
	adgTitle.TextSize = 16
	adgTitle.Font = Enum.Font.GothamBold
	adgTitle.Parent = advDefenseGroupBox

	local adgLine = Instance.new("Frame")
	adgLine.Size = UDim2.new(1, -30, 0, 1.5)
	adgLine.Position = UDim2.new(0, 15, 0, 42)
	adgLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
	adgLine.BackgroundTransparency = 0.3
	adgLine.BorderSizePixel = 0
	adgLine.Parent = advDefenseGroupBox

	local adgStartY = 52

	local advDefenseItems = {
		"Anti Grab V2",
		"Anti Banana",
		"Anti Void",
		"Anti Blobman",
		"Anti Blobman Aura",
		"Anti Loop Kill"
	}

	local advDefenseBoxes = {}
	local adgCurrentY = adgStartY

	for _, title in ipairs(advDefenseItems) do
		local box, btn, chk = createDefenseItem(advDefenseGroupBox, title, adgCurrentY)
		advDefenseBoxes[title] = {box = box, btn = btn, chk = chk}
		adgCurrentY = adgCurrentY + itemHeight + gap
	end

	local adgHeight = 32 + gap + (#advDefenseItems * (itemHeight + gap)) + gap
	advDefenseGroupBox.Size = UDim2.new(0, 300, 0, adgHeight)

	-- ============================================================
	-- === ANTI GRAB (НОВАЯ ВЕРСИЯ ИЗ ПЕРВОГО ФАЙЛА) ===
	-- ============================================================
	do
		local antiGrabConns = {}
		local antiGrabProc = false
		local antiGrabEnabled = false
		local boxData = defenseBoxes["Anti Grab"]
		
		local function antiGrabStruggleEvent()
			local ce = ReplicatedStorage:FindFirstChild("CharacterEvents")
			return ce and ce:FindFirstChild("Struggle")
		end

		local function antiGrabRagdollRemote()
			local ce = ReplicatedStorage:FindFirstChild("CharacterEvents")
			return ce and (ce:FindFirstChild("RagdollRemote") or ce:WaitForChild("RagdollRemote", 5))
		end

		local function antiGrabDisableRagdoll(char)
			for _, v in pairs(char:GetChildren()) do
				if v:IsA("BasePart") and v:FindFirstChild("BallSocketConstraint") and v.Name ~= "Head" then
					v.BallSocketConstraint.Enabled = false
					if v:FindFirstChild("RagdollLimbPart") then
						v.RagdollLimbPart.WeldConstraint.Enabled = false
					end
				end
			end
		end

		local function antiGrabEnableRagdoll(char)
			for _, v in pairs(char:GetChildren()) do
				if v:IsA("BasePart") and v:FindFirstChild("BallSocketConstraint") and v.Name ~= "Head" then
					v.BallSocketConstraint.Enabled = true
					if v:FindFirstChild("RagdollLimbPart") then
						v.RagdollLimbPart.WeldConstraint.Enabled = true
					end
				end
			end
		end

		local function antiGrabCleanup()
			for k, conn in pairs(antiGrabConns) do
				if conn then conn:Disconnect() end
			end
			antiGrabConns = {}
			antiGrabProc = false
		end

		local function antiGrabApply(char)
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChild("Humanoid")
			local head = char:FindFirstChild("Head")
			if not (hrp and hum and head) then return end
			
			antiGrabDisableRagdoll(char)
			
			if antiGrabConns["Head"] then antiGrabConns["Head"]:Disconnect() end
			antiGrabConns["Head"] = head.ChildAdded:Connect(function(partOwner)
				if partOwner.Name ~= "PartOwner" or antiGrabProc then return end
				antiGrabProc = true
				hum.Sit = false
				
				local struggle = antiGrabStruggleEvent()
				local ragdollRemote = antiGrabRagdollRemote()
				
				hrp.Anchored = true
				task.spawn(function()
					while (head and head:FindFirstChild("PartOwner")) or (LocalPlayer:FindFirstChild("IsHeld") and LocalPlayer.IsHeld.Value) do
						if struggle then pcall(function() struggle:FireServer(LocalPlayer) end) end
						if ragdollRemote then pcall(function() ragdollRemote:FireServer(hrp, 0) end) end
						pcall(function()
							hrp.CFrame = hrp.CFrame + hum.MoveDirection * (hum.WalkSpeed / 60)
							hum.PlatformStand = false
							hum.Sit = false
							hum.AutoRotate = true
						end)
						if hrp:FindFirstChild("WeldHRP") and hrp.WeldHRP.Enabled then
							pcall(function() head.CFrame = hrp.CFrame + Vector3.new(0, 1.35, 0) end)
						end
						task.wait()
					end
					pcall(function() hrp.Anchored = false end)
					
					task.spawn(function()
						task.wait(0.3)
						local ge = ReplicatedStorage:FindFirstChild("GrabEvents")
						local dgl = ge and ge:FindFirstChild("DestroyGrabLine")
						if dgl then
							for _, plr in ipairs(Players:GetPlayers()) do
								if plr ~= LocalPlayer and plr.Character then
									local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
									local tHead = plr.Character:FindFirstChild("Head")
									if tRoot then
										for _ = 1, 3 do
											pcall(function() dgl:FireServer(tRoot) end)
										end
									end
									if tHead then
										pcall(function() dgl:FireServer(tHead) end)
									end
									for _, v in ipairs(plr.Character:GetDescendants()) do
										if v.Name == "PartOwner" then
											pcall(function() dgl:FireServer(v.Parent) end)
										end
									end
								end
							end
						end
					end)
					antiGrabProc = false
				end)
			end)
			
			if antiGrabConns["Hum"] then antiGrabConns["Hum"]:Disconnect() end
			antiGrabConns["Hum"] = hum.Changed:Connect(function(prop)
				if prop == "Sit" and hum.Sit then
					if not (hum.SeatPart and hum.SeatPart.Parent and hum.SeatPart.Parent.Name == "CreatureBlobman") then
						hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
						hum.Sit = false
					end
				end
			end)
			
			local weldHRP = hrp:FindFirstChild("WeldHRP")
			if weldHRP then
				if antiGrabConns["Weld"] then antiGrabConns["Weld"]:Disconnect() end
				antiGrabConns["Weld"] = weldHRP.Changed:Connect(function()
					if not hrp.WeldHRP.Enabled then return end
					task.spawn(function()
						while not hum.Sit do task.wait() end
						hum.Sit = false
						hum.AutoRotate = true
						while hrp.WeldHRP.Enabled do
							pcall(function() head.CFrame = hrp.CFrame + Vector3.new(0, 1.35, 0) end)
							task.wait()
						end
					end)
				end)
			end
			
			local ragdolled = hum:FindFirstChild("Ragdolled")
			if ragdolled then
				if antiGrabConns["Ragdoll"] then antiGrabConns["Ragdoll"]:Disconnect() end
				antiGrabConns["Ragdoll"] = ragdolled.Changed:Connect(function()
					if hum.Ragdolled.Value then
						antiGrabDisableRagdoll(char)
						pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
					end
				end)
			end
		end

		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				antiGrabEnabled = not antiGrabEnabled
				boxData.chk.Visible = antiGrabEnabled
				antiGrabCleanup()
				
				if antiGrabEnabled then
					antiGrabApply(LocalPlayer.Character)
					antiGrabConns["CharAdded"] = LocalPlayer.CharacterAdded:Connect(function(newChar)
						task.wait(0.5)
						antiGrabApply(newChar)
					end)
				else
					local char = LocalPlayer.Character
					if char then
						antiGrabEnableRagdoll(char)
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp then hrp.Anchored = false end
					end
				end
			end)
		end
	end

	-- === ANTI GRAB V2 ===
	do
		local AntiGrabV2Enabled = false
		local HeldConnectionV2 = nil
		local isHeld = LocalPlayer:WaitForChild("IsHeld", 10)
		local StruggleEvent = ReplicatedStorage:WaitForChild("CharacterEvents", 10):WaitForChild("Struggle", 10)
		local boxData = advDefenseBoxes["Anti Grab V2"]

		local function StopAntiGrabV2()
			AntiGrabV2Enabled = false
			if HeldConnectionV2 then HeldConnectionV2:Disconnect(); HeldConnectionV2 = nil end
			local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if Root then Root.Anchored = false end
			if LocalPlayer.Character then
				for _, part in pairs(LocalPlayer.Character:GetDescendants()) do 
					if part:IsA("BasePart") then part.CanCollide = true end 
				end
			end
		end

		local function StartAntiGrabV2()
			if HeldConnectionV2 then HeldConnectionV2:Disconnect() end
			HeldConnectionV2 = isHeld:GetPropertyChangedSignal("Value"):Connect(function()
				if not AntiGrabV2Enabled or not isHeld.Value then return end
				local Char = LocalPlayer.Character
				if not Char then return end
				
				local Root = Char:FindFirstChild("HumanoidRootPart")
				local Hum = Char:FindFirstChildOfClass("Humanoid")
				if not Root or not Hum then return end

				for _, part in pairs(Char:GetDescendants()) do 
					if part:IsA("BasePart") then part.CanCollide = false end 
				end

				task.spawn(function()
					while AntiGrabV2Enabled and isHeld.Value do
						pcall(function()
							StruggleEvent:FireServer()
							ReplicatedStorage.CharacterEvents.RagdollRemote:FireServer(Root, 0)
							ReplicatedStorage.GameCorrectionEvents.StopAllVelocity:FireServer()
						end)
						task.wait()
					end
				end)

				task.spawn(function()
					while AntiGrabV2Enabled and isHeld.Value do
						pcall(function()
							Hum.Sit = false
							Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
							Hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
							if Root then
								Root.Anchored = true
								Root.AssemblyLinearVelocity = Vector3.zero
								Root.AssemblyAngularVelocity = Vector3.zero
							end
						end)
						task.wait()
					end
					if Root then Root.Anchored = false end
				end)
			end)
		end

		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				AntiGrabV2Enabled = not AntiGrabV2Enabled
				boxData.chk.Visible = AntiGrabV2Enabled
				if AntiGrabV2Enabled then StartAntiGrabV2() else StopAntiGrabV2() end
			end)

			LocalPlayer.CharacterAdded:Connect(function(char)
				task.wait(1)
				if AntiGrabV2Enabled and isHeld.Value then StartAntiGrabV2() end
			end)
		end
	end

	-- === ANTI BANANA ===
	do
		local antibananaSit = false
		local boxData = advDefenseBoxes["Anti Banana"]
		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				antibananaSit = not antibananaSit
				boxData.chk.Visible = antibananaSit
				
				task.spawn(function()
					while antibananaSit do
						local char = LocalPlayer.Character
						if char then
							local hum = char:FindFirstChildOfClass("Humanoid")
							local hrp = char:FindFirstChild("HumanoidRootPart")
							local camera = Workspace.CurrentCamera
							if hum and hrp and hum.Health > 0 then 
								hum.Sit = true
								hum:ChangeState(Enum.HumanoidStateType.Running)
								local Vec = camera.CFrame.LookVector
								hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(Vec.X, 0, Vec.Z))
							end
						end
						task.wait()
					end
				end)
			end)
		end
	end

	-- === ANTI VOID ===
	do
		local antiVoid = false
		local boxData = advDefenseBoxes["Anti Void"]
		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				antiVoid = not antiVoid
				boxData.chk.Visible = antiVoid
				if antiVoid then
					Workspace.FallenPartsDestroyHeight = 0/0
				else
					Workspace.FallenPartsDestroyHeight = -100
				end
			end)
		end
	end

	-- === ANTI BLOBMAN ===
	do
		local antiblob = false
		local truePosPart = nil
		local boxData = advDefenseBoxes["Anti Blobman"]
		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				antiblob = not antiblob
				boxData.chk.Visible = antiblob

				task.spawn(function()
					while antiblob do
						local char = LocalPlayer.Character
						if not char then task.wait(0.5) continue end
						
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if not hrp then task.wait(0.5) continue end
						
						if not char:FindFirstChild("TruePositionPart") then
							truePosPart = Instance.new("Part")
							truePosPart.Parent = char
							truePosPart.Name = "TruePositionPart"
							truePosPart.Anchored = true
							truePosPart.Transparency = 0.8
							truePosPart.CanCollide = false
							truePosPart.Size = Vector3.new(0.1, 0.1, 0.1)
							truePosPart.CFrame = CFrame.new(0, -10000000, 0)
						end
						
						truePosPart = char:FindFirstChild("TruePositionPart")
						if hrp and truePosPart then
							local rootAttachment = hrp:FindFirstChild("RootAttachment")
							if rootAttachment and rootAttachment.Parent == hrp then 
								rootAttachment.Parent = truePosPart 
							end
							
							local isGrabbed = false
							for _, part in pairs(char:GetChildren()) do
								if part:IsA("Part") and part.Massless then
									part.Massless = false
									isGrabbed = true
								end
							end

							if isGrabbed then
								hrp.AssemblyLinearVelocity = Vector3.new(0, 15000000, 0)
								local destroyrem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
								if destroyrem then
									for _, plot in pairs(Workspace.PlotItems:GetChildren()) do
										if plot.Name ~= "PlayersInPlots" then
											for _, item in pairs(plot:GetChildren()) do
												if item.Name == "CreatureBlobman" then
													pcall(function() destroyrem:FireServer(item) end)
												end
											end
										end
									end
								end
							end
						end
						task.wait()
					end
				end)
			end)
		end
	end

	-- === ANTI BLOBMAN AURA ===
	do
		local antiBlobAura = false
		local auraConnection = nil
		local boxData = advDefenseBoxes["Anti Blobman Aura"]

		local function OAA_getCharacter(plr)
			return plr.Character
		end

		local function OAA_getHumanoidRootPart(char)
			return char and char:FindFirstChild("HumanoidRootPart")
		end

		local function OAA_getHumanoid(char)
			return char and char:FindFirstChild("Humanoid")
		end

		local function OAA_getDistance(part1, part2)
			return (part1.Position - part2.Position).Magnitude
		end

		local function OAA_setNetworkOwner(part, cframe)
			task.spawn(function()
				local grabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
				if grabEvents then
					local setNetworkOwnerRemote = grabEvents:FindFirstChild("SetNetworkOwner")
					if setNetworkOwnerRemote then
						setNetworkOwnerRemote:FireServer(part, cframe)
					end
				end
			end)
		end

		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				antiBlobAura = not antiBlobAura
				boxData.chk.Visible = antiBlobAura
				if auraConnection then
					auraConnection:Disconnect()
					auraConnection = nil
				end
				if antiBlobAura then
					auraConnection = RunService.Heartbeat:Connect(function()
						local myCharacter = OAA_getCharacter(LocalPlayer)
						local myRootPart = OAA_getHumanoidRootPart(myCharacter)
						if not myRootPart then return end

						for _, plr in pairs(Players:GetPlayers()) do
							if plr ~= LocalPlayer then
								local playerCharacter = OAA_getCharacter(plr)
								local playerRootPart = OAA_getHumanoidRootPart(playerCharacter)
								local playerHumanoid = OAA_getHumanoid(playerCharacter)

								if playerRootPart and playerHumanoid and playerHumanoid.SeatPart then
									local seatParent = playerHumanoid.SeatPart.Parent
									if seatParent and seatParent.Name == "CreatureBlobman" then
										if OAA_getDistance(playerRootPart, myRootPart) <= 19 then
											OAA_setNetworkOwner(playerRootPart, playerRootPart.CFrame)
										end
									end
								end
							end
						end
					end)
				end
			end)
		end
	end

	-- === ANTI LOOP KILL ===
	do
		local antiLoopKill = false
		local loopConnection = nil
		local boxData = advDefenseBoxes["Anti Loop Kill"]
		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				antiLoopKill = not antiLoopKill
				boxData.chk.Visible = antiLoopKill
				if loopConnection then
					loopConnection:Disconnect()
					loopConnection = nil
				end
				if antiLoopKill then
					loopConnection = LocalPlayer.CharacterAdded:Connect(function(char)
						local hrp = char:WaitForChild("HumanoidRootPart", 5)
						if hrp then
							RunService.RenderStepped:Wait()
							local target = CFrame.new(524.703979, 93.7120056, -375.040985)
							hrp.CFrame = target
							for i = 1, 2 do
								RunService.RenderStepped:Wait()
								hrp.CFrame = target
							end
						end
					end)
				end
			end)
		end
	end

	-- === ANTI KICK ===
	do
		local boxData = defenseBoxes["Anti Kick"]
		local function ClearKunai()
			local plr = LocalPlayer
			local inv = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
			local destroyrem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
			if inv and destroyrem then
				for _, v in pairs(inv:GetChildren()) do
					if v.Name == "AntiKick" or v.Name == "NinjaShuriken" then
						pcall(function()
							destroyrem:FireServer(v)
						end)
					end
				end
			end
		end

		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				isAntiKickEnabled = not isAntiKickEnabled
				boxData.chk.Visible = isAntiKickEnabled
				
				_G.ShurikenAntiKick = isAntiKickEnabled
				
				if isAntiKickEnabled then
					task.spawn(function()
						local plr = LocalPlayer
						local setOwner = ReplicatedStorage:WaitForChild("GrabEvents"):WaitForChild("SetNetworkOwner")
						local stickyEvent = ReplicatedStorage:WaitForChild("PlayerEvents"):WaitForChild("StickyPartEvent")
						local spawnRemote = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
						local destroyrem = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("DestroyToy")
						local canSpawn = plr:WaitForChild("CanSpawnToy")
						local function getHRP()
							if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
								return plr.Character.HumanoidRootPart
							else
								local character = plr.CharacterAdded:Wait()
								return character:WaitForChild("HumanoidRootPart")
							end
						end
						local function CheckForHome()
							if not Workspace.PlotItems.PlayersInPlots:FindFirstChild(plr.Name) then
								return false
							end
							for _, v in pairs(Workspace.Plots:GetChildren()) do
								local sign = v:FindFirstChild("PlotSign")
								local owners = sign and sign:FindFirstChild("ThisPlotsOwners")
								if owners then
									for _, b in pairs(owners:GetChildren()) do
										if b.Value == plr.Name then
											local folder = Workspace.PlotItems:FindFirstChild(v.Name)
											if folder then
												return true, folder
											end
										end
									end
								end
							end
							return false
						end
						local function StickKunai(kunai)
							if not kunai or not kunai:FindFirstChild("StickyPart") then
								return
							end
							local currentHRP = getHRP()
							if not currentHRP then
								return
							end
							if kunai:FindFirstChild("SoundPart") then
								if not kunai.SoundPart:FindFirstChild("PartOwner") or kunai.SoundPart.PartOwner.Value ~= plr.Name then
									setOwner:FireServer(kunai.SoundPart, kunai.SoundPart.CFrame)
								end
							end
							local firePart = currentHRP:FindFirstChild("FirePlayerPart") or currentHRP:WaitForChild("FirePlayerPart", 5)
							if firePart then
								stickyEvent:FireServer(
									kunai.StickyPart,
									firePart,
									CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), math.rad(90))
								)
							end
							for _, obj in pairs(kunai:GetChildren()) do
								if obj.Name == "Pyramid" then
									obj.CanTouch = false
									obj.CanCollide = false
									obj.CanQuery = false
									obj.Transparency = 0
									if not obj:FindFirstChild("Highlight") then
										local high = Instance.new("Highlight", obj)
										high.FillColor = Color3.fromRGB(0, 0, 0)
									end
								elseif obj.Name == "Main" then
									obj.CanTouch = false
									obj.CanCollide = false
									obj.CanQuery = false
									obj.Transparency = 0
									if not obj:FindFirstChild("Highlight") then
										local high = Instance.new("Highlight", obj)
										high.FillColor = Color3.fromRGB(255, 255, 255)
									end
								elseif obj:IsA("BasePart") then
									obj.CanTouch = false
									obj.CanCollide = false
									obj.CanQuery = false
									obj.Transparency = 1
								end
							end
						end
						local function EnsureStuck(kunai)
							local StickyPart = kunai:FindFirstChild("StickyPart")
							if not StickyPart then return false end
							local currentHRP = getHRP()
							local FirePlayerPart = currentHRP and currentHRP:FindFirstChild("FirePlayerPart")
							if not FirePlayerPart then return false end
							local StickyWeld = StickyPart:FindFirstChild("StickyWeld")

							if StickyWeld and StickyWeld.Part1 == FirePlayerPart then
								return true
							end
							StickKunai(kunai)
							return false
						end
						local function SpawnToy(name)
							local t = tick()
							while not canSpawn.Value do
								if not _G.ShurikenAntiKick or tick() - t > 5 then
									return nil
								end
								task.wait(0.1)
							end
							local currentHRP = getHRP()
							if currentHRP then
								task.spawn(function()
									pcall(function()
										spawnRemote:InvokeServer(name, currentHRP.CFrame * CFrame.new(0, 12, 20), Vector3.new(0, 0, 0))
									end)
								end)
							end
							local boolik, house = CheckForHome()
							local inv = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
							if boolik and house then
								return house:WaitForChild(name, 2)
							elseif not Workspace.PlotItems.PlayersInPlots:FindFirstChild(plr.Name) and inv then
								return inv:WaitForChild(name, 2)
							end
							return nil
						end
						while _G.ShurikenAntiKick do
							RunService.Heartbeat:Wait()
							if not plr.Character or not plr.Character:FindFirstChild("Humanoid") or plr.Character.Humanoid.Health <= 0 then
								continue
							end
							local hrp = getHRP()
							local hum = plr.Character:FindFirstChild("Humanoid")
							if not hrp or not hum or hum.Health <= 0 then continue end  
							local kunai
							local InOwnedPlot, house = CheckForHome()
							local inv = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
							local InPlot = Workspace.PlotItems.PlayersInPlots:FindFirstChild(plr.Name)
							if InOwnedPlot then 
								local House = house
								kunai = House and House:FindFirstChild("AntiKick")
							elseif not InPlot then
								kunai = inv and inv:FindFirstChild("AntiKick")
							else 
								continue
							end
							if kunai then 
								local StickyPart = kunai:FindFirstChild("StickyPart")
								if StickyPart and (StickyPart.Position - hrp.Position).Magnitude > 30 then
									task.spawn(ClearKunai)
									SpawnToy("NinjaShuriken")
								else
									EnsureStuck(kunai)
								end
							else 
								task.spawn(ClearKunai)
								local newKunai = SpawnToy("NinjaShuriken")
								if newKunai then 
									newKunai.Name = "AntiKick"
									EnsureStuck(newKunai) 
								end
							end 
						end
						task.spawn(ClearKunai)
					end)
				else
					_G.ShurikenAntiKick = false
					ClearKunai()
				end
			end)
		end
	end

	-- === ANTI KICK ITEM ===
	do
		local boxData = defenseBoxes["AntiKick ITEM"]
		local function ClearAntiKickItem()
			local inv = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
			local destroyRem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
			if inv and destroyRem then
				for _, v in pairs(inv:GetChildren()) do
					if v.Name == "AntiKickItem" or v.Name == "SpookyCandle1" then
						pcall(function()
							destroyRem:FireServer(v)
						end)
					end
				end
			end
		end

		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				isAntiKickItemEnabled = not isAntiKickItemEnabled
				boxData.chk.Visible = isAntiKickItemEnabled

				_G.AntiKickItemActive = isAntiKickItemEnabled
				
				if not isAntiKickItemEnabled then
					ClearAntiKickItem()
				else
					task.spawn(function()
						while _G.AntiKickItemActive do
							RunService.Heartbeat:Wait()
							local char = LocalPlayer.Character
							local hrp = char and char:FindFirstChild("HumanoidRootPart")
							local hum = char and char:FindFirstChildOfClass("Humanoid")
							local inv = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
							local InPlot = Workspace:FindFirstChild("PlotItems") and Workspace.PlotItems:FindFirstChild("PlayersInPlots") and Workspace.PlotItems.PlayersInPlots:FindFirstChild(LocalPlayer.Name)
							local DestroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
							local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")

							if not hrp or not hum or hum.Health == 0 then continue end
							if InPlot and InPlot.Value then continue end
							
							local item = inv and inv:FindFirstChild("AntiKickItem")
							local hitbox = item and item:FindFirstChild("Hitbox")
							
							if not item or not item.Parent or not hitbox or not hitbox.Parent then
								if inv and DestroyToy then
									for _, v in pairs(inv:GetChildren()) do
										if v.Name == "AntiKickItem" or v.Name == "SpookyCandle1" then
											pcall(function() DestroyToy:FireServer(v) end)
										end
									end
								end
								
								local canSpawn = LocalPlayer:FindFirstChild("CanSpawnToy")
								local t = tick()
								while canSpawn and not canSpawn.Value do
									if not _G.AntiKickItemActive or tick() - t > 5 then break end
									task.wait(0.1)
								end

								local targetFirePart = hrp:FindFirstChild("FirePlayerPart") or hrp

								if spawnRemote and hrp then
									pcall(function()
										spawnRemote:InvokeServer("SpookyCandle1", targetFirePart.CFrame, Vector3.zero)
									end)
								end

								local startTime = tick()
								while tick() - startTime < 2 do
									if inv then
										for _, v in ipairs(inv:GetChildren()) do
											if v.Name == "SpookyCandle1" then
												item = v
												break
											end
										end
									end
									if item then break end
									RunService.Heartbeat:Wait()
								end

								if item then
									item.Name = "AntiKickItem"
									hitbox = item:FindFirstChild("Hitbox") or item:FindFirstChildWhichIsA("BasePart")
									
									if hitbox then
										hitbox.AssemblyLinearVelocity = Vector3.zero
										hitbox.AssemblyAngularVelocity = Vector3.zero
										hitbox.CFrame = targetFirePart.CFrame

										local setOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
										if setOwner then
											pcall(function()
												setOwner:FireServer(hitbox, targetFirePart.CFrame)
											end)
										end

										for _, v in pairs(item:GetDescendants()) do
											if v:IsA("BasePart") then
												v.CanCollide = false
												v.CanQuery = false
												v.Transparency = 0.8
												v.Color = Color3.fromRGB(200, 200, 200)
											end
										end

										local weld = Instance.new("WeldConstraint")
										weld.Name = "WeldBlabla"
										weld.Part0 = hitbox
										weld.Part1 = targetFirePart
										weld.Parent = hitbox
									end
								end
							else
								local targetFirePart = hrp:FindFirstChild("FirePlayerPart") or hrp
								local weld = hitbox:FindFirstChild("WeldBlabla")

								if not weld or weld.Part1 ~= targetFirePart then
									if weld then weld:Destroy() end
									hitbox.AssemblyLinearVelocity = Vector3.zero
									hitbox.AssemblyAngularVelocity = Vector3.zero
									hitbox.CFrame = targetFirePart.CFrame
									
									weld = Instance.new("WeldConstraint")
									weld.Name = "WeldBlabla"
									weld.Part0 = hitbox
									weld.Part1 = targetFirePart
									weld.Parent = hitbox
								end

								local success, owner = pcall(function() return hitbox:GetNetworkOwner() end)
								if not success or owner ~= LocalPlayer then
									local setOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
									if setOwner then
										pcall(function() setOwner:FireServer(hitbox, hitbox.CFrame) end)
									end
								end
							end
						end
					end)
				end
			end)
		end
	end

	-- === ANTI INPUT ===
	do
		local boxData = defenseBoxes["Anti Input"]
		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				isAntiInputEnabled = not isAntiInputEnabled
				boxData.chk.Visible = isAntiInputEnabled
			end)
		end
	end

	-- === ANTI SNOWBALL ===
	do
		local loopRagdoll = false
		local boxData = defenseBoxes["Anti Snowball"]
		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				loopRagdoll = not loopRagdoll
				boxData.chk.Visible = loopRagdoll
				
				if loopRagdoll then
					task.spawn(function()
						while loopRagdoll and task.wait(0.05) do
							pcall(function()
								local char = LocalPlayer.Character
								local hrp = char and char:FindFirstChild("HumanoidRootPart")
								if hrp then
									ReplicatedStorage.CharacterEvents.RagdollRemote:FireServer(hrp, 0.5)
								end
							end)
						end
					end)
				end
			end)
		end
	end

	-- === AUTO RESET ===
	do
		local autoResetEnabled = false
		local boxData = defenseBoxes["Auto Reset"]
		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				autoResetEnabled = not autoResetEnabled
				boxData.chk.Visible = autoResetEnabled

				if autoResetEnabled then
					if _G.AutoResetCon then _G.AutoResetCon:Disconnect() end
					_G.AutoResetCon = ReplicatedStorage.GameCorrectionEvents.GameCorrectionsNotify.OnClientEvent:Connect(function(r)
						if autoResetEnabled and r == "Flying" then
							local char = LocalPlayer.Character
							local hum = char and char:FindFirstChildOfClass("Humanoid")
							if hum then
								char:BreakJoints() 
								hum.Health = 0
							end
						end
					end)
				else
					if _G.AutoResetCon then
						_G.AutoResetCon:Disconnect()
						_G.AutoResetCon = nil
					end
				end
			end)
		end
	end

	-- === AUTO LEAVE ===
	do
		local autoLeaveEnabled = false
		local boxData = defenseBoxes["Auto Leave"]
		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				autoLeaveEnabled = not autoLeaveEnabled
				boxData.chk.Visible = autoLeaveEnabled

				if autoLeaveEnabled then
					if _G.AutoLeaveCon then _G.AutoLeaveCon:Disconnect() end
					local warnTimestamps = {}
					_G.AutoLeaveCon = ReplicatedStorage.GameCorrectionEvents.GameCorrectionsNotify.OnClientEvent:Connect(function(r)
						if autoLeaveEnabled and r == "Flying" then
							local currentTime = os.clock()
							table.insert(warnTimestamps, currentTime)
							for i = #warnTimestamps, 1, -1 do
								if currentTime - warnTimestamps[i] > 1 then
									table.remove(warnTimestamps, i)
								end
							end
							if #warnTimestamps >= 3 then
								LocalPlayer:Kick("XOCU Safety: Disconnected to prevent ban.")
							end
						end
					end)
				else
					if _G.AutoLeaveCon then
						_G.AutoLeaveCon:Disconnect()
						_G.AutoLeaveCon = nil
					end
				end
			end)
		end
	end

	-- === ANTI EXPLOSION ===
	do
		local antiExplodeActive = false
		local antiExplodeConn = nil
		local boxData = defenseBoxes["Anti Explosion"]
		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				antiExplodeActive = not antiExplodeActive
				boxData.chk.Visible = antiExplodeActive

				if antiExplodeActive then
					if antiExplodeConn then antiExplodeConn:Disconnect() end
					antiExplodeConn = Workspace.ChildAdded:Connect(function(model)
						if antiExplodeActive and model.Name == "Part" then
							local char = LocalPlayer.Character
							if not char then return end
							local hrp = char:FindFirstChild("HumanoidRootPart")
							if not hrp then return end
							local mag = (model.Position - hrp.Position).Magnitude
							if mag <= 20 then
								hrp.Anchored = true
								task.wait(0.01)
								while char:FindFirstChild("Right Arm") and char["Right Arm"]:FindFirstChild("RagdollLimbPart") and char["Right Arm"].RagdollLimbPart.CanCollide do
									task.wait(0.001)
								end
								hrp.Anchored = false
							end
						end
					end)
				else
					if antiExplodeConn then
						antiExplodeConn:Disconnect()
						antiExplodeConn = nil
					end
				end
			end)
		end
	end

	-- === ANTI BURN (НОВАЯ ВЕРСИЯ ИЗ ПЕРВОГО ФАЙЛА) ===
	do
		local antiBurnActive = false
		local antiBurnConnections = {}
		local boxData = defenseBoxes["Anti Burn"]

		local function getExtinguishPart()
			local p1 = Workspace:FindFirstChild("Map") and 
					   Workspace.Map:FindFirstChild("Hole") and 
					   Workspace.Map.Hole:FindFirstChild("PoisonBigHole") and 
					   Workspace.Map.Hole.PoisonBigHole:FindFirstChild("ExtinguishPart")
			if p1 and p1:IsA("BasePart") then return p1 end
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("BasePart") and obj.Name == "ExtinguishPart" then
					return obj
				end
			end
			return nil
		end

		local function cleanupAntiBurn()
			for _, conn in ipairs(antiBurnConnections) do
				pcall(function() conn:Disconnect() end)
			end
			antiBurnConnections = {}
		end

		local function setupAntiBurn(char)
			local hum = char:FindFirstChildOfClass("Humanoid")
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hum or not hrp then return end

			local apagarfogo = getExtinguishPart()
			if apagarfogo and apagarfogo:IsA("BasePart") then
				apagarfogo.Size = Vector3.new(0.5, 0.5, 0.5)
				apagarfogo.Transparency = 1
				local tex = apagarfogo:FindFirstChild("Tex")
				if tex and tex:IsA("Decal") then tex.Transparency = 1 end
			end

			local function doExtinguishLoop()
				local firePart = char:FindFirstChild("FirePlayerPart", true)
				if not firePart or not apagarfogo then return end
				local oldCF = apagarfogo.CFrame
				local oldSize = apagarfogo.Size
				task.spawn(function()
					while firePart and firePart.Parent do
						local fd = hum:FindFirstChild("FireDebounce")
						local cb = firePart:FindFirstChild("CanBurn")
						if (not fd or not fd.Value) and (not cb or not cb.Value) then break end
						if cb then cb.Value = false end
						if fd then fd.Value = false end
						apagarfogo.CFrame = firePart.CFrame * CFrame.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1))
						if firetouchinterest then
							firetouchinterest(firePart, apagarfogo, 0)
							task.wait()
							firetouchinterest(firePart, apagarfogo, 1)
						else
							task.wait(0.05)
						end
					end
					pcall(function()
						apagarfogo.CFrame = oldCF
						apagarfogo.Size = oldSize
					end)
				end)
			end

			local fireDebounce = hum:FindFirstChild("FireDebounce")
			if fireDebounce then
				table.insert(antiBurnConnections, fireDebounce:GetPropertyChangedSignal("Value"):Connect(function()
					if fireDebounce.Value then doExtinguishLoop() end
				end))
				if fireDebounce.Value then doExtinguishLoop() end
			end

			local firePart = char:FindFirstChild("FirePlayerPart", true)
			if firePart and firePart:FindFirstChild("CanBurn") then
				table.insert(antiBurnConnections, firePart.CanBurn:GetPropertyChangedSignal("Value"):Connect(function()
					if firePart.CanBurn.Value then doExtinguishLoop() end
				end))
				if firePart.CanBurn.Value then doExtinguishLoop() end
			end

			table.insert(antiBurnConnections, char.DescendantAdded:Connect(function(desc)
				if desc.Name == "FirePlayerPart" then
					local cb = desc:FindFirstChild("CanBurn")
					if cb then
						table.insert(antiBurnConnections, cb:GetPropertyChangedSignal("Value"):Connect(function()
							if cb.Value then doExtinguishLoop() end
						end))
						if cb.Value then doExtinguishLoop() end
					end
					local fd = hum:FindFirstChild("FireDebounce")
					if fd and fd.Value then doExtinguishLoop() end
				end
			end))
		end

		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				antiBurnActive = not antiBurnActive
				boxData.chk.Visible = antiBurnActive

				if antiBurnActive then
					cleanupAntiBurn()
					if LocalPlayer.Character then
						setupAntiBurn(LocalPlayer.Character)
					end
					table.insert(antiBurnConnections, LocalPlayer.CharacterAdded:Connect(setupAntiBurn))
				else
					cleanupAntiBurn()
				end
			end)
		end
	end

	-- === ANTI STICKY ===
	do
		local antiStickyActive = false
		local boxData = defenseBoxes["Anti Sticky"]
		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				antiStickyActive = not antiStickyActive
				boxData.chk.Visible = antiStickyActive

				local stickyDetection = LocalPlayer.PlayerScripts:FindFirstChild("StickyPartsTouchDetection")
				if stickyDetection then
					stickyDetection.Disabled = antiStickyActive
				end
			end)
		end
	end

	-- === ANTI LAG (НОВАЯ ВЕРСИЯ ИЗ ПЕРВОГО ФАЙЛА) ===
	do
		local antiLagActive = false
		local antiLagConn = nil
		local antiLagBeamScript = nil
		local boxData = defenseBoxes["Anti Lag"]

		local function antiLagIsLine(obj)
			if obj:IsA("Beam") then return true end
			local n = string.lower(obj.Name)
			return n:find("grabbeam") ~= nil or n:find("grabline") ~= nil
		end

		local function antiLagSweep()
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if antiLagIsLine(obj) then
					pcall(function() obj:Destroy() end)
				end
			end
		end

		if boxData then
			boxData.btn.MouseButton1Click:Connect(function()
				antiLagActive = not antiLagActive
				boxData.chk.Visible = antiLagActive

				if antiLagActive then
					local ps = LocalPlayer:FindFirstChild("PlayerScripts")
					local beamScript = ps and ps:FindFirstChild("CharacterAndBeamMove")
					if beamScript then
						antiLagBeamScript = beamScript
						pcall(function() beamScript.Disabled = true end)
					end
					antiLagSweep()
					if antiLagConn then antiLagConn:Disconnect() end
					antiLagConn = Workspace.DescendantAdded:Connect(function(obj)
						if antiLagActive and antiLagIsLine(obj) then
							pcall(function() obj:Destroy() end)
						end
					end)
				else
					if antiLagConn then
						antiLagConn:Disconnect()
						antiLagConn = nil
					end
					if antiLagBeamScript then
						pcall(function() antiLagBeamScript.Disabled = false end)
						antiLagBeamScript = nil
					end
				end
			end)
		end
	end

end

-- ============================================================================
-- PLAYER TAB (С ПРАВИЛЬНЫМИ РАССТОЯНИЯМИ 0.1 СМ = 10 ПИКСЕЛЕЙ)
-- ============================================================================
local function setupPlayerTab(playerContentArea)
    playerContentArea.ClipsDescendants = true
    playerContentArea.CanvasSize = UDim2.new(0, 0, 0, 750)

    local gap = 10 -- 0.1 см = 10 пикселей

    -- ============================================================
    -- ЛЕВАЯ КОЛОНКА: LOCAL PLAYER
    -- ============================================================
    local leftColumn = Instance.new("Frame")
    leftColumn.Size = UDim2.new(0, 300, 0, 0)
    leftColumn.Position = UDim2.new(0, 20, 0, 20)
    leftColumn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    leftColumn.BackgroundTransparency = 0.25
    leftColumn.ClipsDescendants = true
    leftColumn.Parent = playerContentArea

    local leftCorner = Instance.new("UICorner")
    leftCorner.CornerRadius = UDim.new(0, 18)
    leftCorner.Parent = leftColumn

    local leftStroke = Instance.new("UIStroke")
    leftStroke.Color = Color3.fromRGB(180, 180, 180)
    leftStroke.Transparency = 0.2
    leftStroke.Thickness = 1.0
    leftStroke.Parent = leftColumn

    -- Заголовок
    local leftTitle = Instance.new("TextLabel")
    leftTitle.Size = UDim2.new(1, -30, 0, 30)
    leftTitle.Position = UDim2.new(0, 15, 0, 8)
    leftTitle.BackgroundTransparency = 1
    leftTitle.TextXAlignment = Enum.TextXAlignment.Left
    leftTitle.Text = "Local Player"
    leftTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    leftTitle.TextTransparency = 0.05
    leftTitle.TextSize = 16
    leftTitle.Font = Enum.Font.GothamBold
    leftTitle.Parent = leftColumn

    -- Черта
    local leftLine = Instance.new("Frame")
    leftLine.Size = UDim2.new(1, -30, 0, 1.5)
    leftLine.Position = UDim2.new(0, 15, 0, 42)
    leftLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    leftLine.BackgroundTransparency = 0.3
    leftLine.BorderSizePixel = 0
    leftLine.Parent = leftColumn

    -- ============================================================
    -- THIRD PERSON (отступ от стенок 0.1 см)
    -- ============================================================
    local thirdPersonBox = Instance.new("Frame")
    thirdPersonBox.Size = UDim2.new(1, -gap * 2, 0, 70)
    thirdPersonBox.Position = UDim2.new(0, gap, 0, 52)
    thirdPersonBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    thirdPersonBox.BackgroundTransparency = 0.25
    thirdPersonBox.ClipsDescendants = true
    thirdPersonBox.Parent = leftColumn

    local tpBoxCorner = Instance.new("UICorner")
    tpBoxCorner.CornerRadius = UDim.new(0, 18)
    tpBoxCorner.Parent = thirdPersonBox

    local tpBoxStroke = Instance.new("UIStroke")
    tpBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    tpBoxStroke.Transparency = 0.2
    tpBoxStroke.Thickness = 1.0
    tpBoxStroke.Parent = thirdPersonBox

    local tpTitle = Instance.new("TextLabel")
    tpTitle.Size = UDim2.new(1, -40, 0, 20)
    tpTitle.Position = UDim2.new(0, 12, 0, 4)
    tpTitle.BackgroundTransparency = 1
    tpTitle.TextXAlignment = Enum.TextXAlignment.Left
    tpTitle.Text = "Third Person"
    tpTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpTitle.TextTransparency = 0.05
    tpTitle.TextSize = 13
    tpTitle.Font = Enum.Font.GothamBold
    tpTitle.Parent = thirdPersonBox

    local tpToggleBtn = Instance.new("TextButton")
    tpToggleBtn.Size = UDim2.new(1, -24, 0, 28)
    tpToggleBtn.Position = UDim2.new(0, 12, 0, 26)
    tpToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    tpToggleBtn.BackgroundTransparency = 0.2
    tpToggleBtn.Text = ""
    tpToggleBtn.AutoButtonColor = false
    tpToggleBtn.Parent = thirdPersonBox

    local tpToggleCorner = Instance.new("UICorner")
    tpToggleCorner.CornerRadius = UDim.new(0, 14)
    tpToggleCorner.Parent = tpToggleBtn

    local tpToggleStroke = Instance.new("UIStroke")
    tpToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    tpToggleStroke.Transparency = 0.2
    tpToggleStroke.Thickness = 0.8
    tpToggleStroke.Parent = tpToggleBtn

    local tpToggleLabel = Instance.new("TextLabel")
    tpToggleLabel.Size = UDim2.new(1, -40, 1, 0)
    tpToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    tpToggleLabel.BackgroundTransparency = 1
    tpToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    tpToggleLabel.Text = "Enable View"
    tpToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    tpToggleLabel.TextSize = 12
    tpToggleLabel.Font = Enum.Font.Gotham
    tpToggleLabel.Parent = tpToggleBtn

    local tpCheckboxBox = Instance.new("Frame")
    tpCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
    tpCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
    tpCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
    tpCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    tpCheckboxBox.BackgroundTransparency = 0.2
    tpCheckboxBox.BorderSizePixel = 0
    tpCheckboxBox.Parent = tpToggleBtn

    local tpCbCorner = Instance.new("UICorner")
    tpCbCorner.CornerRadius = UDim.new(0, 6)
    tpCbCorner.Parent = tpCheckboxBox

    local tpCbStroke = Instance.new("UIStroke")
    tpCbStroke.Color = Color3.fromRGB(150, 150, 150)
    tpCbStroke.Transparency = 0.2
    tpCbStroke.Thickness = 1
    tpCbStroke.Parent = tpCheckboxBox

    local tpCheckmark = Instance.new("TextLabel")
    tpCheckmark.Size = UDim2.new(1, 0, 1, 0)
    tpCheckmark.BackgroundTransparency = 1
    tpCheckmark.Text = "✓"
    tpCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpCheckmark.TextSize = 14
    tpCheckmark.Font = Enum.Font.GothamBold
    tpCheckmark.Visible = false
    tpCheckmark.Parent = tpCheckboxBox

    isThirdPersonEnabled = false

    tpToggleBtn.MouseButton1Click:Connect(function()
        isThirdPersonEnabled = not isThirdPersonEnabled
        tpCheckmark.Visible = isThirdPersonEnabled
        
        if isThirdPersonEnabled then
            player.CameraMode = Enum.CameraMode.Classic
            player.CameraMaxZoomDistance = 100
            player.CameraMinZoomDistance = 0.5
        else
            player.CameraMode = Enum.CameraMode.LockFirstPerson
            player.CameraMaxZoomDistance = 0.5
            player.CameraMinZoomDistance = 0.5
        end
    end)

    RunService.RenderStepped:Connect(function()
        if isThirdPersonEnabled then
            if player.CameraMode ~= Enum.CameraMode.Classic then
                player.CameraMode = Enum.CameraMode.Classic
            end
            player.CameraMaxZoomDistance = 100
            player.CameraMinZoomDistance = 0.5
        end
    end)

    -- ============================================================
    -- FIELD OF VIEW (расстояние 0.1 см между фреймами)
    -- ============================================================
    local fovBox = Instance.new("Frame")
    fovBox.Size = UDim2.new(1, -gap * 2, 0, 70)
    fovBox.Position = UDim2.new(0, gap, 0, 52 + 70 + gap)
    fovBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    fovBox.BackgroundTransparency = 0.25
    fovBox.ClipsDescendants = true
    fovBox.Parent = leftColumn

    local fovBoxCorner = Instance.new("UICorner")
    fovBoxCorner.CornerRadius = UDim.new(0, 18)
    fovBoxCorner.Parent = fovBox

    local fovBoxStroke = Instance.new("UIStroke")
    fovBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    fovBoxStroke.Transparency = 0.2
    fovBoxStroke.Thickness = 1.0
    fovBoxStroke.Parent = fovBox

    local fovTitle = Instance.new("TextLabel")
    fovTitle.Size = UDim2.new(1, 0, 0, 20)
    fovTitle.Position = UDim2.new(0, 12, 0, 4)
    fovTitle.BackgroundTransparency = 1
    fovTitle.TextXAlignment = Enum.TextXAlignment.Left
    fovTitle.Text = "Field Of View: 70"
    fovTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    fovTitle.TextTransparency = 0.05
    fovTitle.TextSize = 13
    fovTitle.Font = Enum.Font.GothamBold
    fovTitle.Parent = fovBox

    local fovSliderBar = Instance.new("Frame")
    fovSliderBar.Size = UDim2.new(1, -45, 0, 10)
    fovSliderBar.Position = UDim2.new(0, 25, 0, 40)
    fovSliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    fovSliderBar.BackgroundTransparency = 0.2
    fovSliderBar.BorderSizePixel = 0
    fovSliderBar.Parent = fovBox

    local fovBarCorner = Instance.new("UICorner")
    fovBarCorner.CornerRadius = UDim.new(1, 0)
    fovBarCorner.Parent = fovSliderBar

    local fovSliderFill = Instance.new("Frame")
    fovSliderFill.Size = UDim2.new(0, 0, 1, 0)
    fovSliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fovSliderFill.BackgroundTransparency = 0.05
    fovSliderFill.BorderSizePixel = 0
    fovSliderFill.Parent = fovSliderBar

    local fovFillCorner = Instance.new("UICorner")
    fovFillCorner.CornerRadius = UDim.new(1, 0)
    fovFillCorner.Parent = fovSliderFill

    local fovSliderButton = Instance.new("TextButton")
    fovSliderButton.Size = UDim2.new(0, 18, 0, 18)
    fovSliderButton.Position = UDim2.new(0, -9, 0.5, -9)
    fovSliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fovSliderButton.BackgroundTransparency = 0
    fovSliderButton.Text = ""
    fovSliderButton.Parent = fovSliderBar

    local fovButtonCorner = Instance.new("UICorner")
    fovButtonCorner.CornerRadius = UDim.new(1, 0)
    fovButtonCorner.Parent = fovSliderButton

    local fovButtonStroke = Instance.new("UIStroke")
    fovButtonStroke.Color = Color3.fromRGB(140, 140, 140)
    fovButtonStroke.Thickness = 1
    fovButtonStroke.Parent = fovSliderButton

    fovSliding = false

    local function updateFovSlider(input)
        local mousePos = input.Position.X
        local barAbsolutePos = fovSliderBar.AbsolutePosition.X
        local barAbsoluteSize = fovSliderBar.AbsoluteSize.X
        
        local relativeX = math.clamp(mousePos - barAbsolutePos, 0, barAbsoluteSize)
        local scale = math.clamp(relativeX / barAbsoluteSize, 0, 1)
        
        fovSliderButton.Position = UDim2.new(scale, -9, 0.5, -9)
        fovSliderFill.Size = UDim2.new(scale, 0, 1, 0)
        
        local currentFov = math.floor(70 + (scale * 50) + 0.5)
        fovTitle.Text = string.format("Field Of View: %d", currentFov)
        camera.FieldOfView = currentFov
    end

    fovSliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            fovSliding = true
            updateFovSlider(input)
        end
    end)

    fovSliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            fovSliding = true
            updateFovSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            fovSliding = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if fovSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFovSlider(input)
        end
    end)

    -- Высота левой колонки: черта 42 + 0.1см + ThirdPerson 70 + 0.1см + FOV 70 + 0.1см снизу
    leftColumn.Size = UDim2.new(0, 300, 0, 42 + gap + 70 + gap + 70 + gap)

    -- ============================================================
    -- ПРАВАЯ КОЛОНКА: FEATURE KEYBINDS (ТАКАЯ ЖЕ ШИРИНА КАК LOCAL PLAYER)
    -- ============================================================
    local rightColumn = Instance.new("Frame")
    rightColumn.Size = UDim2.new(0, 300, 0, 0) -- ТЕПЕРЬ 300, КАК У LOCAL PLAYER
    rightColumn.Position = UDim2.new(0, 300 + 20 + gap, 0, 20)
    rightColumn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    rightColumn.BackgroundTransparency = 0.25
    rightColumn.ClipsDescendants = true
    rightColumn.Parent = playerContentArea

    local rightCorner = Instance.new("UICorner")
    rightCorner.CornerRadius = UDim.new(0, 18)
    rightCorner.Parent = rightColumn

    local rightStroke = Instance.new("UIStroke")
    rightStroke.Color = Color3.fromRGB(180, 180, 180)
    rightStroke.Transparency = 0.2
    rightStroke.Thickness = 1.0
    rightStroke.Parent = rightColumn

    -- Заголовок
    local rightTitle = Instance.new("TextLabel")
    rightTitle.Size = UDim2.new(1, -30, 0, 30)
    rightTitle.Position = UDim2.new(0, 15, 0, 8)
    rightTitle.BackgroundTransparency = 1
    rightTitle.TextXAlignment = Enum.TextXAlignment.Left
    rightTitle.Text = "Feature Keybinds"
    rightTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    rightTitle.TextTransparency = 0.05
    rightTitle.TextSize = 16
    rightTitle.Font = Enum.Font.GothamBold
    rightTitle.Parent = rightColumn

    -- Черта
    local rightLine = Instance.new("Frame")
    rightLine.Size = UDim2.new(1, -30, 0, 1.5)
    rightLine.Position = UDim2.new(0, 15, 0, 42)
    rightLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    rightLine.BackgroundTransparency = 0.3
    rightLine.BorderSizePixel = 0
    rightLine.Parent = rightColumn

    local rightStartY = 62
    local itemHeight = 70

    -- ============================================================
    -- ВСЕ ЭЛЕМЕНТЫ (с отступом 0.1 см от стенок и между собой)
    -- ============================================================
    local function createItem(parent, title, posY)
        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, -gap * 2, 0, itemHeight)
        box.Position = UDim2.new(0, gap, 0, posY)
        box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        box.BackgroundTransparency = 0.25
        box.ClipsDescendants = true
        box.Parent = parent

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 18)
        boxCorner.Parent = box

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Color3.fromRGB(180, 180, 180)
        boxStroke.Transparency = 0.2
        boxStroke.Thickness = 1.0
        boxStroke.Parent = box

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 12, 0, 4)
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = title
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextTransparency = 0.05
        label.TextSize = 13
        label.Font = Enum.Font.GothamBold
        label.Parent = box

        return box
    end

    -- 1. TELEPORT KEYBIND
    local teleportBox = createItem(rightColumn, "Teleport Keybind", rightStartY)
    local teleportKeyBtn = Instance.new("TextButton")
    teleportKeyBtn.Size = UDim2.new(1, -24, 0, 28)
    teleportKeyBtn.Position = UDim2.new(0, 12, 0, 26)
    teleportKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    teleportKeyBtn.BackgroundTransparency = 0.2
    teleportKeyBtn.Text = "Z"
    teleportKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportKeyBtn.TextTransparency = 0.05
    teleportKeyBtn.TextSize = 14
    teleportKeyBtn.Font = Enum.Font.GothamBold
    teleportKeyBtn.Parent = teleportBox

    local teleportKeyCorner = Instance.new("UICorner")
    teleportKeyCorner.CornerRadius = UDim.new(0, 14)
    teleportKeyCorner.Parent = teleportKeyBtn

    local teleportKeyStroke = Instance.new("UIStroke")
    teleportKeyStroke.Color = Color3.fromRGB(180, 180, 180)
    teleportKeyStroke.Transparency = 0.2
    teleportKeyStroke.Thickness = 0.8
    teleportKeyStroke.Parent = teleportKeyBtn

    local listeningForTpKey = false
    teleportKeyBtn.MouseButton1Click:Connect(function()
        if listeningForTpKey then return end
        listeningForTpKey = true
        teleportKeyBtn.Text = "..."
        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gp)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                teleportKey = input.KeyCode
                teleportKeyBtn.Text = input.KeyCode.Name
                listeningForTpKey = false
                connection:Disconnect()
            end
        end)
    end)

    rightStartY = rightStartY + itemHeight + gap

    -- 2. CLICK TP
    local clickTpBox = createItem(rightColumn, "Click TP", rightStartY)
    local ctpToggleBtn = Instance.new("TextButton")
    ctpToggleBtn.Size = UDim2.new(1, -24, 0, 28)
    ctpToggleBtn.Position = UDim2.new(0, 12, 0, 26)
    ctpToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    ctpToggleBtn.BackgroundTransparency = 0.2
    ctpToggleBtn.Text = ""
    ctpToggleBtn.AutoButtonColor = false
    ctpToggleBtn.Parent = clickTpBox

    local ctpToggleCorner = Instance.new("UICorner")
    ctpToggleCorner.CornerRadius = UDim.new(0, 14)
    ctpToggleCorner.Parent = ctpToggleBtn

    local ctpToggleStroke = Instance.new("UIStroke")
    ctpToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    ctpToggleStroke.Transparency = 0.2
    ctpToggleStroke.Thickness = 0.8
    ctpToggleStroke.Parent = ctpToggleBtn

    local ctpToggleLabel = Instance.new("TextLabel")
    ctpToggleLabel.Size = UDim2.new(1, -40, 1, 0)
    ctpToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    ctpToggleLabel.BackgroundTransparency = 1
    ctpToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ctpToggleLabel.Text = "Enable Click TP"
    ctpToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    ctpToggleLabel.TextSize = 12
    ctpToggleLabel.Font = Enum.Font.Gotham
    ctpToggleLabel.Parent = ctpToggleBtn

    local ctpCheckboxBox = Instance.new("Frame")
    ctpCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
    ctpCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
    ctpCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
    ctpCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    ctpCheckboxBox.BackgroundTransparency = 0.2
    ctpCheckboxBox.BorderSizePixel = 0
    ctpCheckboxBox.Parent = ctpToggleBtn

    local ctpCbCorner = Instance.new("UICorner")
    ctpCbCorner.CornerRadius = UDim.new(0, 6)
    ctpCbCorner.Parent = ctpCheckboxBox

    local ctpCbStroke = Instance.new("UIStroke")
    ctpCbStroke.Color = Color3.fromRGB(150, 150, 150)
    ctpCbStroke.Transparency = 0.2
    ctpCbStroke.Thickness = 1
    ctpCbStroke.Parent = ctpCheckboxBox

    local ctpCheckmark = Instance.new("TextLabel")
    ctpCheckmark.Size = UDim2.new(1, 0, 1, 0)
    ctpCheckmark.BackgroundTransparency = 1
    ctpCheckmark.Text = "✓"
    ctpCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    ctpCheckmark.TextSize = 14
    ctpCheckmark.Font = Enum.Font.GothamBold
    ctpCheckmark.Visible = false
    ctpCheckmark.Parent = ctpCheckboxBox

    ctpToggleBtn.MouseButton1Click:Connect(function()
        isClickTpEnabled = not isClickTpEnabled
        ctpCheckmark.Visible = isClickTpEnabled
    end)

    rightStartY = rightStartY + itemHeight + gap

    -- 3. NOCLIP KEYBIND
    local noclipBox = createItem(rightColumn, "Noclip Keybind", rightStartY)
    local ncToggleBtn = Instance.new("TextButton")
    ncToggleBtn.Size = UDim2.new(0, 32, 0, 28)
    ncToggleBtn.Position = UDim2.new(0, 12, 0, 26)
    ncToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    ncToggleBtn.BackgroundTransparency = 0.2
    ncToggleBtn.Text = ""
    ncToggleBtn.AutoButtonColor = false
    ncToggleBtn.Parent = noclipBox

    local ncToggleCorner = Instance.new("UICorner")
    ncToggleCorner.CornerRadius = UDim.new(0, 8)
    ncToggleCorner.Parent = ncToggleBtn

    local ncToggleStroke = Instance.new("UIStroke")
    ncToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    ncToggleStroke.Transparency = 0.2
    ncToggleStroke.Thickness = 0.8
    ncToggleStroke.Parent = ncToggleBtn

    local ncCheckmark = Instance.new("TextLabel")
    ncCheckmark.Size = UDim2.new(1, 0, 1, 0)
    ncCheckmark.BackgroundTransparency = 1
    ncCheckmark.Text = "✓"
    ncCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    ncCheckmark.TextSize = 14
    ncCheckmark.Font = Enum.Font.GothamBold
    ncCheckmark.Visible = false
    ncCheckmark.Parent = ncToggleBtn

    local ncKeyBtn = Instance.new("TextButton")
    ncKeyBtn.Size = UDim2.new(0, 130, 0, 28) -- Уменьшил ширину под новую ширину колонки
    ncKeyBtn.Position = UDim2.new(0, 50, 0, 26)
    ncKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    ncKeyBtn.BackgroundTransparency = 0.2
    ncKeyBtn.Text = "X"
    ncKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ncKeyBtn.TextTransparency = 0.05
    ncKeyBtn.TextSize = 14
    ncKeyBtn.Font = Enum.Font.GothamBold
    ncKeyBtn.Parent = noclipBox

    local ncKeyCorner = Instance.new("UICorner")
    ncKeyCorner.CornerRadius = UDim.new(0, 10)
    ncKeyCorner.Parent = ncKeyBtn

    local ncKeyStroke = Instance.new("UIStroke")
    ncKeyStroke.Color = Color3.fromRGB(180, 180, 180)
    ncKeyStroke.Transparency = 0.2
    ncKeyStroke.Thickness = 0.8
    ncKeyStroke.Parent = ncKeyBtn

    local listeningForNcKey = false
    ncKeyBtn.MouseButton1Click:Connect(function()
        if listeningForNcKey then return end
        listeningForNcKey = true
        ncKeyBtn.Text = "..."
        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gp)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                noclipKey = input.KeyCode
                ncKeyBtn.Text = input.KeyCode.Name
                listeningForNcKey = false
                connection:Disconnect()
            end
        end)
    end)

    ncToggleBtn.MouseButton1Click:Connect(function()
        noclip = not noclip
        ncCheckmark.Visible = noclip
    end)

    rightStartY = rightStartY + itemHeight + gap

    -- 4. SPEED HACK
    local speedHackBox = createItem(rightColumn, "Speed Hack", rightStartY)
    local shToggleBtn = Instance.new("TextButton")
    shToggleBtn.Size = UDim2.new(0, 32, 0, 28)
    shToggleBtn.Position = UDim2.new(0, 12, 0, 26)
    shToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    shToggleBtn.BackgroundTransparency = 0.2
    shToggleBtn.Text = ""
    shToggleBtn.AutoButtonColor = false
    shToggleBtn.Parent = speedHackBox

    local shToggleCorner = Instance.new("UICorner")
    shToggleCorner.CornerRadius = UDim.new(0, 8)
    shToggleCorner.Parent = shToggleBtn

    local shToggleStroke = Instance.new("UIStroke")
    shToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    shToggleStroke.Transparency = 0.2
    shToggleStroke.Thickness = 0.8
    shToggleStroke.Parent = shToggleBtn

    local shCheckmark = Instance.new("TextLabel")
    shCheckmark.Size = UDim2.new(1, 0, 1, 0)
    shCheckmark.BackgroundTransparency = 1
    shCheckmark.Text = "✓"
    shCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    shCheckmark.TextSize = 14
    shCheckmark.Font = Enum.Font.GothamBold
    shCheckmark.Visible = false
    shCheckmark.Parent = shToggleBtn

    local shKeyBtn = Instance.new("TextButton")
    shKeyBtn.Size = UDim2.new(0, 45, 0, 28)
    shKeyBtn.Position = UDim2.new(0, 50, 0, 26)
    shKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    shKeyBtn.BackgroundTransparency = 0.2
    shKeyBtn.Text = "V"
    shKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    shKeyBtn.TextTransparency = 0.05
    shKeyBtn.TextSize = 14
    shKeyBtn.Font = Enum.Font.GothamBold
    shKeyBtn.Parent = speedHackBox

    local shKeyCorner = Instance.new("UICorner")
    shKeyCorner.CornerRadius = UDim.new(0, 10)
    shKeyCorner.Parent = shKeyBtn

    local shKeyStroke = Instance.new("UIStroke")
    shKeyStroke.Color = Color3.fromRGB(180, 180, 180)
    shKeyStroke.Transparency = 0.2
    shKeyStroke.Thickness = 0.8
    shKeyStroke.Parent = shKeyBtn

    local listeningForShKey = false
    shKeyBtn.MouseButton1Click:Connect(function()
        if listeningForShKey then return end
        listeningForShKey = true
        shKeyBtn.Text = "..."
        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gp)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                speedHackKey = input.KeyCode
                shKeyBtn.Text = input.KeyCode.Name
                listeningForShKey = false
                connection:Disconnect()
            end
        end)
    end)

    local shSpeedBox = Instance.new("TextBox")
    shSpeedBox.Size = UDim2.new(0, 65, 0, 28)
    shSpeedBox.Position = UDim2.new(0, 101, 0, 26)
    shSpeedBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    shSpeedBox.BackgroundTransparency = 0.2
    shSpeedBox.Text = tostring(speedHackSpeed)
    shSpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    shSpeedBox.TextTransparency = 0.05
    shSpeedBox.TextSize = 14
    shSpeedBox.Font = Enum.Font.GothamBold
    shSpeedBox.ClearTextOnFocus = false
    shSpeedBox.Parent = speedHackBox

    local shSpeedCorner = Instance.new("UICorner")
    shSpeedCorner.CornerRadius = UDim.new(0, 10)
    shSpeedCorner.Parent = shSpeedBox

    local shSpeedStroke = Instance.new("UIStroke")
    shSpeedStroke.Color = Color3.fromRGB(180, 180, 180)
    shSpeedStroke.Transparency = 0.2
    shSpeedStroke.Thickness = 0.8
    shSpeedStroke.Parent = shSpeedBox

    shToggleBtn.MouseButton1Click:Connect(function()
        isSpeedHackEnabled = not isSpeedHackEnabled
        shCheckmark.Visible = isSpeedHackEnabled
        if not isSpeedHackEnabled and humanoid then
            humanoid.WalkSpeed = 16
            if root then
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
            end
        end
    end)

    shSpeedBox:GetPropertyChangedSignal("Text"):Connect(function()
        local cleaned = shSpeedBox.Text:gsub("%D", "")
        local num = tonumber(cleaned)
        if num and num > 100 then
            cleaned = "100"
        end
        if cleaned ~= shSpeedBox.Text then
            shSpeedBox.Text = cleaned
        end
    end)

    shSpeedBox.FocusLost:Connect(function()
        local num = tonumber(shSpeedBox.Text)
        if num then
            speedHackSpeed = math.clamp(num, 0, 100)
            shSpeedBox.Text = tostring(speedHackSpeed)
        else
            shSpeedBox.Text = tostring(speedHackSpeed)
        end
    end)

    rightStartY = rightStartY + itemHeight + gap

    -- 5. VEHICLE FLY
    local flyBox = createItem(rightColumn, "Vehicle Fly", rightStartY)
    local flyToggleBtn = Instance.new("TextButton")
    flyToggleBtn.Size = UDim2.new(0, 32, 0, 28)
    flyToggleBtn.Position = UDim2.new(0, 12, 0, 26)
    flyToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    flyToggleBtn.BackgroundTransparency = 0.2
    flyToggleBtn.Text = ""
    flyToggleBtn.AutoButtonColor = false
    flyToggleBtn.Parent = flyBox

    local flyToggleCorner = Instance.new("UICorner")
    flyToggleCorner.CornerRadius = UDim.new(0, 8)
    flyToggleCorner.Parent = flyToggleBtn

    local flyToggleStroke = Instance.new("UIStroke")
    flyToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    flyToggleStroke.Transparency = 0.2
    flyToggleStroke.Thickness = 0.8
    flyToggleStroke.Parent = flyToggleBtn

    local flyCheckmark = Instance.new("TextLabel")
    flyCheckmark.Size = UDim2.new(1, 0, 1, 0)
    flyCheckmark.BackgroundTransparency = 1
    flyCheckmark.Text = "✓"
    flyCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    flyCheckmark.TextSize = 14
    flyCheckmark.Font = Enum.Font.GothamBold
    flyCheckmark.Visible = false
    flyCheckmark.Parent = flyToggleBtn

    local flyKeyBtn = Instance.new("TextButton")
    flyKeyBtn.Size = UDim2.new(0, 45, 0, 28)
    flyKeyBtn.Position = UDim2.new(0, 50, 0, 26)
    flyKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    flyKeyBtn.BackgroundTransparency = 0.2
    flyKeyBtn.Text = "C"
    flyKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    flyKeyBtn.TextTransparency = 0.05
    flyKeyBtn.TextSize = 14
    flyKeyBtn.Font = Enum.Font.GothamBold
    flyKeyBtn.Parent = flyBox

    local flyKeyCorner = Instance.new("UICorner")
    flyKeyCorner.CornerRadius = UDim.new(0, 10)
    flyKeyCorner.Parent = flyKeyBtn

    local flyKeyStroke = Instance.new("UIStroke")
    flyKeyStroke.Color = Color3.fromRGB(180, 180, 180)
    flyKeyStroke.Transparency = 0.2
    flyKeyStroke.Thickness = 0.8
    flyKeyStroke.Parent = flyKeyBtn

    local listeningForFlyKey = false
    flyKeyBtn.MouseButton1Click:Connect(function()
        if listeningForFlyKey then return end
        listeningForFlyKey = true
        flyKeyBtn.Text = "..."
        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gp)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                flyKey = input.KeyCode
                flyKeyBtn.Text = input.KeyCode.Name
                listeningForFlyKey = false
                connection:Disconnect()
            end
        end)
    end)

    local flySpeedBox = Instance.new("TextBox")
    flySpeedBox.Size = UDim2.new(0, 65, 0, 28)
    flySpeedBox.Position = UDim2.new(0, 101, 0, 26)
    flySpeedBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    flySpeedBox.BackgroundTransparency = 0.2
    flySpeedBox.Text = tostring(flySpeed)
    flySpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    flySpeedBox.TextTransparency = 0.05
    flySpeedBox.TextSize = 14
    flySpeedBox.Font = Enum.Font.GothamBold
    flySpeedBox.ClearTextOnFocus = false
    flySpeedBox.Parent = flyBox

    local flySpeedCorner = Instance.new("UICorner")
    flySpeedCorner.CornerRadius = UDim.new(0, 10)
    flySpeedCorner.Parent = flySpeedBox

    local flySpeedStroke = Instance.new("UIStroke")
    flySpeedStroke.Color = Color3.fromRGB(180, 180, 180)
    flySpeedStroke.Transparency = 0.2
    flySpeedStroke.Thickness = 0.8
    flySpeedStroke.Parent = flySpeedBox

    flySpeedBox:GetPropertyChangedSignal("Text"):Connect(function()
        local cleaned = flySpeedBox.Text:gsub("%D", "")
        local num = tonumber(cleaned)
        if num and num > 100 then
            cleaned = "100"
        end
        if cleaned ~= flySpeedBox.Text then
            flySpeedBox.Text = cleaned
        end
    end)

    flySpeedBox.FocusLost:Connect(function()
        local num = tonumber(flySpeedBox.Text)
        if num then
            flySpeed = math.clamp(num, 0, 100)
            flySpeedBox.Text = tostring(flySpeed)
        else
            flySpeedBox.Text = tostring(flySpeed)
        end
    end)

    local function getTarget(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart then
            local seat = hum.SeatPart
            local model = seat.Parent
            if model and model:IsA("Model") then
                local rootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                if rootPart then return rootPart, true end
            end
            return seat, true
        end
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"), false
    end

    toggleVFly = function()
        inf_fly = not inf_fly
        flyCheckmark.Visible = inf_fly
        local char = player.Character
        if not char then return end
        
        if inf_fly then
            local target, vehicleCheck = getTarget(char)
            if not target then
                inf_fly = false
                flyCheckmark.Visible = false
                return
            end
            
            currentTarget = target
            isVehicle = vehicleCheck

            bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.CFrame = currentTarget.CFrame
            bg.Parent = currentTarget

            bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = currentTarget

            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and not isVehicle then
                hum.PlatformStand = true
            end
        else
            if currentTarget then
                currentTarget.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                currentTarget.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end

            if bg then bg:Destroy() end
            if bv then bv:Destroy() end
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = false
            end
            currentTarget = nil
            isVehicle = false
        end
    end

    flyToggleBtn.MouseButton1Click:Connect(function()
        toggleVFly()
    end)

    RunService.RenderStepped:Connect(function()
        if inf_fly and currentTarget and currentTarget.Parent then
            local moveDir = Vector3.new(0, 0, 0)
            
            if keys.W then moveDir = moveDir + camera.CFrame.LookVector end
            if keys.S then moveDir = moveDir - camera.CFrame.LookVector end
            if keys.A then moveDir = moveDir - camera.CFrame.RightVector end
            if keys.D then moveDir = moveDir + camera.CFrame.RightVector end
            if keys.Space then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if keys.LeftControl then moveDir = moveDir - Vector3.new(0, 1, 0) end
            
            bv.Velocity = moveDir * (flySpeed * 5)
            
            if isVehicle then
                bg.CFrame = CFrame.new(currentTarget.Position, currentTarget.Position + camera.CFrame.LookVector) * CFrame.Angles(0, math.pi, 0)
            else
                bg.CFrame = camera.CFrame
            end
        elseif inf_fly and not currentTarget then
            toggleVFly()
        end
    end)

    rightStartY = rightStartY + itemHeight + gap

    -- 6. INFINITE JUMP
    local infJumpBox = createItem(rightColumn, "Infinite Jump", rightStartY)
    local ijToggleBtn = Instance.new("TextButton")
    ijToggleBtn.Size = UDim2.new(0, 32, 0, 28)
    ijToggleBtn.Position = UDim2.new(0, 12, 0, 26)
    ijToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    ijToggleBtn.BackgroundTransparency = 0.2
    ijToggleBtn.Text = ""
    ijToggleBtn.AutoButtonColor = false
    ijToggleBtn.Parent = infJumpBox

    local ijToggleCorner = Instance.new("UICorner")
    ijToggleCorner.CornerRadius = UDim.new(0, 8)
    ijToggleCorner.Parent = ijToggleBtn

    local ijToggleStroke = Instance.new("UIStroke")
    ijToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    ijToggleStroke.Transparency = 0.2
    ijToggleStroke.Thickness = 0.8
    ijToggleStroke.Parent = ijToggleBtn

    local ijCheckmark = Instance.new("TextLabel")
    ijCheckmark.Size = UDim2.new(1, 0, 1, 0)
    ijCheckmark.BackgroundTransparency = 1
    ijCheckmark.Text = "✓"
    ijCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    ijCheckmark.TextSize = 14
    ijCheckmark.Font = Enum.Font.GothamBold
    ijCheckmark.Visible = false
    ijCheckmark.Parent = ijToggleBtn

    local ijKeyBtn = Instance.new("TextButton")
    ijKeyBtn.Size = UDim2.new(0, 130, 0, 28)
    ijKeyBtn.Position = UDim2.new(0, 50, 0, 26)
    ijKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    ijKeyBtn.BackgroundTransparency = 0.2
    ijKeyBtn.Text = "J"
    ijKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ijKeyBtn.TextTransparency = 0.05
    ijKeyBtn.TextSize = 14
    ijKeyBtn.Font = Enum.Font.GothamBold
    ijKeyBtn.Parent = infJumpBox

    local ijKeyCorner = Instance.new("UICorner")
    ijKeyCorner.CornerRadius = UDim.new(0, 10)
    ijKeyCorner.Parent = ijKeyBtn

    local ijKeyStroke = Instance.new("UIStroke")
    ijKeyStroke.Color = Color3.fromRGB(180, 180, 180)
    ijKeyStroke.Transparency = 0.2
    ijKeyStroke.Thickness = 0.8
    ijKeyStroke.Parent = ijKeyBtn

    local listeningForIjKey = false
    ijKeyBtn.MouseButton1Click:Connect(function()
        if listeningForIjKey then return end
        listeningForIjKey = true
        ijKeyBtn.Text = "..."
        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gp)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                infJumpKey = input.KeyCode
                ijKeyBtn.Text = input.KeyCode.Name
                listeningForIjKey = false
                connection:Disconnect()
            end
        end)
    end)

    local function toggleInfJump()
        isInfJumpEnabled = not isInfJumpEnabled
        ijCheckmark.Visible = isInfJumpEnabled
    end

    ijToggleBtn.MouseButton1Click:Connect(function()
        toggleInfJump()
    end)

    rightStartY = rightStartY + itemHeight + gap

    -- Высота правой колонки: черта 42 + 0.1см + 6*70 + 6*0.1см + 0.1см снизу
    rightColumn.Size = UDim2.new(0, 300, 0, 42 + gap + (6 * itemHeight) + (6 * gap) + gap)

    -- ============================================================
    -- SPEED HACK ЛОГИКА
    -- ============================================================
    RunService.RenderStepped:Connect(function(dt)
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if isSpeedHackEnabled and hrp and hum then
            hum.WalkSpeed = 16
            if hum.MoveDirection.Magnitude > 0 then
                local targetVel = hum.MoveDirection * (speedHackSpeed * 10)
                hrp.AssemblyLinearVelocity = Vector3.new(targetVel.X, hrp.AssemblyLinearVelocity.Y, targetVel.Z)
            else
                hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
            end
            
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                local animFactor = math.clamp(1 - (speedHackSpeed / 100) * 0.5, 0.5, 1)
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:AdjustSpeed(animFactor)
                end
            end
        end
    end)

    -- ============================================================
    -- INFINITE JUMP ЛОГИКА
    -- ============================================================
    RunService.RenderStepped:Connect(function()
        if isInfJumpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- ============================================================================
-- MISC TAB (С ГРУППАМИ TRAIN FEATURES, SERVER, RAGDOLL ALL, DEFENSE FOR FRIENDS)
-- ============================================================================
local function setupMiscTab(miscContentArea)
    miscContentArea.ClipsDescendants = true
    miscContentArea.CanvasSize = UDim2.new(0, 0, 0, 950)

    local gap = 10 -- 0.1 см
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")

    -- ============================================================
    -- TRAIN FEATURES (СЛЕВА)
    -- ============================================================
    local trainFeaturesBox = Instance.new("Frame")
    trainFeaturesBox.Size = UDim2.new(0, 300, 0, 0)
    trainFeaturesBox.Position = UDim2.new(0, 20, 0, 20)
    trainFeaturesBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    trainFeaturesBox.BackgroundTransparency = 0.25
    trainFeaturesBox.ClipsDescendants = true
    trainFeaturesBox.Parent = miscContentArea

    local tfBoxCorner = Instance.new("UICorner")
    tfBoxCorner.CornerRadius = UDim.new(0, 18)
    tfBoxCorner.Parent = trainFeaturesBox

    local tfBoxStroke = Instance.new("UIStroke")
    tfBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    tfBoxStroke.Transparency = 0.2
    tfBoxStroke.Thickness = 1.0
    tfBoxStroke.Parent = trainFeaturesBox

    -- Заголовок "Train Features"
    local tfTitle = Instance.new("TextLabel")
    tfTitle.Size = UDim2.new(1, -30, 0, 30)
    tfTitle.Position = UDim2.new(0, 15, 0, 8)
    tfTitle.BackgroundTransparency = 1
    tfTitle.TextXAlignment = Enum.TextXAlignment.Left
    tfTitle.Text = "Train Features"
    tfTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    tfTitle.TextTransparency = 0.05
    tfTitle.TextSize = 16
    tfTitle.Font = Enum.Font.GothamBold
    tfTitle.Parent = trainFeaturesBox

    -- Черта
    local tfLine = Instance.new("Frame")
    tfLine.Size = UDim2.new(1, -30, 0, 1.5)
    tfLine.Position = UDim2.new(0, 15, 0, 42)
    tfLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    tfLine.BackgroundTransparency = 0.3
    tfLine.BorderSizePixel = 0
    tfLine.Parent = trainFeaturesBox

    local tfStartY = 52
    local itemHeight = 80

    -- Функция создания элемента
    local function createMiscItem(parent, title, posY)
        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, -gap * 2, 0, itemHeight)
        box.Position = UDim2.new(0, gap, 0, posY)
        box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        box.BackgroundTransparency = 0.25
        box.ClipsDescendants = true
        box.Parent = parent

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 18)
        boxCorner.Parent = box

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Color3.fromRGB(180, 180, 180)
        boxStroke.Transparency = 0.2
        boxStroke.Thickness = 1.0
        boxStroke.Parent = box

        return box
    end

    -- ============================================================
    -- ATTACH 10 SHURIKENS
    -- ============================================================
    local attachBox = createMiscItem(trainFeaturesBox, "Attach 10 Shurikens", tfStartY)

    local asTitle = Instance.new("TextLabel")
    asTitle.Size = UDim2.new(1, -40, 0, 25)
    asTitle.Position = UDim2.new(0, 12, 0, 4)
    asTitle.BackgroundTransparency = 1
    asTitle.TextXAlignment = Enum.TextXAlignment.Left
    asTitle.Text = "Attach 10 Shurikens [Break Train]"
    asTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    asTitle.TextTransparency = 0.05
    asTitle.TextSize = 13
    asTitle.Font = Enum.Font.GothamBold
    asTitle.Parent = attachBox

    local asToggleBtn = Instance.new("TextButton")
    asToggleBtn.Size = UDim2.new(1, -24, 0, 28)
    asToggleBtn.Position = UDim2.new(0, 12, 0, 32)
    asToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    asToggleBtn.BackgroundTransparency = 0.2
    asToggleBtn.Text = ""
    asToggleBtn.AutoButtonColor = false
    asToggleBtn.Parent = attachBox

    local asToggleCorner = Instance.new("UICorner")
    asToggleCorner.CornerRadius = UDim.new(0, 14)
    asToggleCorner.Parent = asToggleBtn

    local asToggleStroke = Instance.new("UIStroke")
    asToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    asToggleStroke.Transparency = 0.2
    asToggleStroke.Thickness = 0.8
    asToggleStroke.Parent = asToggleBtn

    local asToggleLabel = Instance.new("TextLabel")
    asToggleLabel.Size = UDim2.new(1, -40, 1, 0)
    asToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    asToggleLabel.BackgroundTransparency = 1
    asToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    asToggleLabel.Text = "Enable Attach"
    asToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    asToggleLabel.TextSize = 12
    asToggleLabel.Font = Enum.Font.Gotham
    asToggleLabel.Parent = asToggleBtn

    local asCheckboxBox = Instance.new("Frame")
    asCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
    asCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
    asCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
    asCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    asCheckboxBox.BackgroundTransparency = 0.2
    asCheckboxBox.BorderSizePixel = 0
    asCheckboxBox.Parent = asToggleBtn

    local asCbCorner = Instance.new("UICorner")
    asCbCorner.CornerRadius = UDim.new(0, 6)
    asCbCorner.Parent = asCheckboxBox

    local asCbStroke = Instance.new("UIStroke")
    asCbStroke.Color = Color3.fromRGB(150, 150, 150)
    asCbStroke.Transparency = 0.2
    asCbStroke.Thickness = 1
    asCbStroke.Parent = asCheckboxBox

    local asCheckmark = Instance.new("TextLabel")
    asCheckmark.Size = UDim2.new(1, 0, 1, 0)
    asCheckmark.BackgroundTransparency = 1
    asCheckmark.Text = "✓"
    asCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    asCheckmark.TextSize = 14
    asCheckmark.Font = Enum.Font.GothamBold
    asCheckmark.Visible = false
    asCheckmark.Parent = asCheckboxBox

    _G.AttachShurikensEnabled = false

    local function clearAttachedShurikens()
        local inv = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        local destroyRem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
        if inv and destroyRem then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == "MassiveShurikenAttach" or v.Name == "NinjaShuriken" then
                    pcall(function()
                        destroyRem:FireServer(v)
                    end)
                end
            end
        end
    end

    local function spawnShurikensInHead()
        task.spawn(function()
            if not _G.AttachShurikensEnabled then return end
            
            local StickyPartEvent = ReplicatedStorage:FindFirstChild("PlayerEvents") and ReplicatedStorage.PlayerEvents:FindFirstChild("StickyPartEvent")
            local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
            local setOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")

            if not spawnRemote or not StickyPartEvent then return end

            local char = LocalPlayer.Character
            if not char then return end
            
            local head = char:FindFirstChild("Head")
            if not head then return end

            -- СПАВНИМ 10 ШУРИКЕНОВ
            for i = 1, 10 do
                if not _G.AttachShurikensEnabled then break end
                pcall(function()
                    spawnRemote:InvokeServer("NinjaShuriken", head.CFrame * CFrame.new(0, 4, 0), Vector3.zero)
                end)
                task.wait(0.05)
            end

            task.wait(0.1)

            if not _G.AttachShurikensEnabled then 
                clearAttachedShurikens()
                return 
            end

            local inv = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
            if not inv then return end

            local attachedCount = 0
            
            -- ПРИКРЕПЛЯЕМ ШУРИКЕНЫ К ГОЛОВЕ
            for _, Toy in pairs(inv:GetChildren()) do
                if attachedCount >= 10 then break end
                if not _G.AttachShurikensEnabled then 
                    clearAttachedShurikens()
                    return 
                end
                
                if Toy:IsA("Model") and Toy.Name:find("Shuriken") and not Toy:GetAttribute("AttachedProcessed") then
                    Toy:SetAttribute("AttachedProcessed", true)
                    Toy.Name = "MassiveShurikenAttach"

                    local stickyPart = Toy:FindFirstChild("StickyPart")
                    if stickyPart then
                        if Toy:FindFirstChild("SoundPart") then
                            pcall(function()
                                if setOwner then
                                    setOwner:FireServer(Toy.SoundPart, Toy.SoundPart.CFrame)
                                end
                            end)
                        end
                        
                        pcall(function()
                            StickyPartEvent:FireServer(stickyPart, head, CFrame.new(0, 0, 0))
                        end)

                        for _, part in pairs(Toy:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                                part.CanTouch = false
                            end
                        end
                        
                        attachedCount = attachedCount + 1
                    end
                end
            end
            
            -- Если прикрепили меньше 10, пробуем ещё раз
            if attachedCount < 10 and _G.AttachShurikensEnabled then
                task.wait(0.2)
                spawnShurikensInHead()
            end
        end)
    end

    asToggleBtn.MouseButton1Click:Connect(function()
        _G.AttachShurikensEnabled = not _G.AttachShurikensEnabled
        asCheckmark.Visible = _G.AttachShurikensEnabled

        if _G.AttachShurikensEnabled then
            spawnShurikensInHead()
        else
            clearAttachedShurikens()
        end
    end)

    -- ============================================================
    -- SEAT TRAIN (ОРИГИНАЛЬНЫЙ ИЗ ТВОЕГО СКРИПТА)
    -- ============================================================
    local seatBox = createMiscItem(trainFeaturesBox, "Seat Train", tfStartY + itemHeight + gap)

    local stTitle = Instance.new("TextLabel")
    stTitle.Size = UDim2.new(1, -40, 0, 25)
    stTitle.Position = UDim2.new(0, 12, 0, 4)
    stTitle.BackgroundTransparency = 1
    stTitle.TextXAlignment = Enum.TextXAlignment.Left
    stTitle.Text = "Seat Train"
    stTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    stTitle.TextTransparency = 0.05
    stTitle.TextSize = 13
    stTitle.Font = Enum.Font.GothamBold
    stTitle.Parent = seatBox

    local stToggleBtn = Instance.new("TextButton")
    stToggleBtn.Size = UDim2.new(1, -24, 0, 28)
    stToggleBtn.Position = UDim2.new(0, 12, 0, 32)
    stToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    stToggleBtn.BackgroundTransparency = 0.2
    stToggleBtn.Text = ""
    stToggleBtn.AutoButtonColor = false
    stToggleBtn.Parent = seatBox

    local stToggleCorner = Instance.new("UICorner")
    stToggleCorner.CornerRadius = UDim.new(0, 14)
    stToggleCorner.Parent = stToggleBtn

    local stToggleStroke = Instance.new("UIStroke")
    stToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    stToggleStroke.Transparency = 0.2
    stToggleStroke.Thickness = 0.8
    stToggleStroke.Parent = stToggleBtn

    local stToggleLabel = Instance.new("TextLabel")
    stToggleLabel.Size = UDim2.new(1, -40, 1, 0)
    stToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    stToggleLabel.BackgroundTransparency = 1
    stToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    stToggleLabel.Text = "Instant Sit"
    stToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    stToggleLabel.TextSize = 12
    stToggleLabel.Font = Enum.Font.Gotham
    stToggleLabel.Parent = stToggleBtn

    local stCheckboxBox = Instance.new("Frame")
    stCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
    stCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
    stCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
    stCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    stCheckboxBox.BackgroundTransparency = 0.2
    stCheckboxBox.BorderSizePixel = 0
    stCheckboxBox.Parent = stToggleBtn

    local stCbCorner = Instance.new("UICorner")
    stCbCorner.CornerRadius = UDim.new(0, 6)
    stCbCorner.Parent = stCheckboxBox

    local stCbStroke = Instance.new("UIStroke")
    stCbStroke.Color = Color3.fromRGB(150, 150, 150)
    stCbStroke.Transparency = 0.2
    stCbStroke.Thickness = 1
    stCbStroke.Parent = stCheckboxBox

    local stCheckmark = Instance.new("TextLabel")
    stCheckmark.Size = UDim2.new(1, 0, 1, 0)
    stCheckmark.BackgroundTransparency = 1
    stCheckmark.Text = "✓"
    stCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    stCheckmark.TextSize = 14
    stCheckmark.Font = Enum.Font.GothamBold
    stCheckmark.Visible = false
    stCheckmark.Parent = stCheckboxBox

    _G.InstantSitEnabled = false

    -- ОРИГИНАЛЬНАЯ ФУНКЦИЯ ИЗ ТВОЕГО СКРИПТА
    local function findHighestTrainSeat()
        local highestSeat = nil
        local highestY = -math.huge

        local function checkObject(obj)
            if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
                local nameLower = obj.Name:lower()
                local parentName = (obj.Parent and obj.Parent.Name:lower()) or ""
                if nameLower:find("train") or parentName:find("train") or obj.Name:find("Seat") then
                    if obj.Position.Y > highestY then
                        highestY = obj.Position.Y
                        highestSeat = obj
                    end
                end
            end
            for _, child in ipairs(obj:GetChildren()) do
                checkObject(child)
            end
        end

        local directTrain = Workspace:FindFirstChild("Train")
        if directTrain then
            checkObject(directTrain)
        end

        if not highestSeat then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Model") or obj:IsA("Folder") then
                    if obj.Name:lower():find("train") then
                        checkObject(obj)
                    end
                end
            end
        end

        if not highestSeat then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
                    if obj.Position.Y > highestY then
                        highestY = obj.Position.Y
                        highestSeat = obj
                    end
                end
            end
        end

        return highestSeat
    end

    stToggleBtn.MouseButton1Click:Connect(function()
        _G.InstantSitEnabled = not _G.InstantSitEnabled
        stCheckmark.Visible = _G.InstantSitEnabled

        local char = LocalPlayer.Character
        local trainSeat = findHighestTrainSeat()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if trainSeat and hum and hrp then
            pcall(function()
                trainSeat:Sit(hum)
            end)
        end
    end)

    -- Высота группы Train Features
    local tfHeight = tfStartY + (1.9 * (itemHeight + gap)) + gap
    trainFeaturesBox.Size = UDim2.new(0, 300, 0, tfHeight)

    -- ============================================================
    -- ГРУППА 2: SERVER (СПРАВА)
    -- ============================================================
    local serverBox = Instance.new("Frame")
    serverBox.Size = UDim2.new(0, 300, 0, 0)
    serverBox.Position = UDim2.new(0, 300 + 20 + gap, 0, 20)
    serverBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    serverBox.BackgroundTransparency = 0.25
    serverBox.ClipsDescendants = true
    serverBox.Parent = miscContentArea

    local sBoxCorner = Instance.new("UICorner")
    sBoxCorner.CornerRadius = UDim.new(0, 18)
    sBoxCorner.Parent = serverBox

    local sBoxStroke = Instance.new("UIStroke")
    sBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    sBoxStroke.Transparency = 0.2
    sBoxStroke.Thickness = 1.0
    sBoxStroke.Parent = serverBox

    -- Заголовок "Server"
    local sTitle = Instance.new("TextLabel")
    sTitle.Size = UDim2.new(1, -30, 0, 30)
    sTitle.Position = UDim2.new(0, 15, 0, 8)
    sTitle.BackgroundTransparency = 1
    sTitle.TextXAlignment = Enum.TextXAlignment.Left
    sTitle.Text = "Server"
    sTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    sTitle.TextTransparency = 0.05
    sTitle.TextSize = 16
    sTitle.Font = Enum.Font.GothamBold
    sTitle.Parent = serverBox

    -- Черта
    local sLine = Instance.new("Frame")
    sLine.Size = UDim2.new(1, -30, 0, 1.5)
    sLine.Position = UDim2.new(0, 15, 0, 42)
    sLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    sLine.BackgroundTransparency = 0.3
    sLine.BorderSizePixel = 0
    sLine.Parent = serverBox

    local sStartY = 52
    local sItemHeight = 80

    -- ============================================================
    -- 1. TSUNAMI
    -- ============================================================
    local tsunamiBox = createMiscItem(serverBox, "Tsunami", sStartY)

    local tsTitle = Instance.new("TextLabel")
    tsTitle.Size = UDim2.new(1, -40, 0, 25)
    tsTitle.Position = UDim2.new(0, 12, 0, 4)
    tsTitle.BackgroundTransparency = 1
    tsTitle.TextXAlignment = Enum.TextXAlignment.Left
    tsTitle.Text = "Tsunami [WIP, Visual]"
    tsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    tsTitle.TextTransparency = 0.05
    tsTitle.TextSize = 13
    tsTitle.Font = Enum.Font.GothamBold
    tsTitle.Parent = tsunamiBox

    local tsToggleBtn = Instance.new("TextButton")
    tsToggleBtn.Size = UDim2.new(1, -24, 0, 28)
    tsToggleBtn.Position = UDim2.new(0, 12, 0, 32)
    tsToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    tsToggleBtn.BackgroundTransparency = 0.2
    tsToggleBtn.Text = ""
    tsToggleBtn.AutoButtonColor = false
    tsToggleBtn.Parent = tsunamiBox

    local tsToggleCorner = Instance.new("UICorner")
    tsToggleCorner.CornerRadius = UDim.new(0, 14)
    tsToggleCorner.Parent = tsToggleBtn

    local tsToggleStroke = Instance.new("UIStroke")
    tsToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    tsToggleStroke.Transparency = 0.2
    tsToggleStroke.Thickness = 0.8
    tsToggleStroke.Parent = tsToggleBtn

    local tsToggleLabel = Instance.new("TextLabel")
    tsToggleLabel.Size = UDim2.new(1, -40, 1, 0)
    tsToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    tsToggleLabel.BackgroundTransparency = 1
    tsToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    tsToggleLabel.Text = "Enable Tsunami"
    tsToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    tsToggleLabel.TextSize = 12
    tsToggleLabel.Font = Enum.Font.Gotham
    tsToggleLabel.Parent = tsToggleBtn

    local tsCheckboxBox = Instance.new("Frame")
    tsCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
    tsCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
    tsCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
    tsCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    tsCheckboxBox.BackgroundTransparency = 0.2
    tsCheckboxBox.BorderSizePixel = 0
    tsCheckboxBox.Parent = tsToggleBtn

    local tsCbCorner = Instance.new("UICorner")
    tsCbCorner.CornerRadius = UDim.new(0, 6)
    tsCbCorner.Parent = tsCheckboxBox

    local tsCbStroke = Instance.new("UIStroke")
    tsCbStroke.Color = Color3.fromRGB(150, 150, 150)
    tsCbStroke.Transparency = 0.2
    tsCbStroke.Thickness = 1
    tsCbStroke.Parent = tsCheckboxBox

    local tsCheckmark = Instance.new("TextLabel")
    tsCheckmark.Size = UDim2.new(1, 0, 1, 0)
    tsCheckmark.AnchorPoint = Vector2.new(0.5, 0.5)
    tsCheckmark.Position = UDim2.new(0.5, 0, 0.5, 0)
    tsCheckmark.BackgroundTransparency = 1
    tsCheckmark.Text = "✓"
    tsCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    tsCheckmark.TextSize = 14
    tsCheckmark.Font = Enum.Font.GothamBold
    tsCheckmark.Visible = false
    tsCheckmark.Parent = tsCheckboxBox

    _G.TsunamiEnabled = false

    tsToggleBtn.MouseButton1Click:Connect(function()
        _G.TsunamiEnabled = not _G.TsunamiEnabled
        tsCheckmark.Visible = _G.TsunamiEnabled

        if not _G.TsunamiEnabled then
            if getgenv().OceanConnection then
                getgenv().OceanConnection:Disconnect()
                getgenv().OceanConnection = nil
            end
        else
            -- ТУТ ЛОГИКА TSUNAMI
            task.spawn(function()
                local stickyEvent = ReplicatedStorage:FindFirstChild("PlayerEvents") and ReplicatedStorage.PlayerEvents:FindFirstChild("StickyPartEvent")
                local setOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
                local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")

                if not spawnRemote or not stickyEvent then return end

                getgenv().OceanHitbox = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Map") and Workspace.Map.Map:FindFirstChild("Ocean") and Workspace.Map.Map.Ocean:FindFirstChild("Hitbox")
                if not getgenv().OceanHitbox then
                    getgenv().OceanHitbox = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ocean") and Workspace.Map.Ocean:FindFirstChild("Hitbox")
                end
                if not getgenv().OceanHitbox then
                    getgenv().OceanHitbox = Workspace:FindFirstChild("Ocean") and Workspace.Ocean:FindFirstChild("Hitbox")
                end
                if not getgenv().OceanHitbox then
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if obj.Name == "Ocean" and obj:IsA("BasePart") then
                            getgenv().OceanHitbox = obj
                            break
                        end
                    end
                end

                local targetOceanPos = Vector3.new(0, -20, 0)
                if getgenv().OceanHitbox and getgenv().OceanHitbox:IsA("BasePart") then
                    targetOceanPos = Vector3.new(getgenv().OceanHitbox.Position.X, -20, getgenv().OceanHitbox.Position.Z)
                end

                local spawnedCount = 0

                for i = 1, 10 do
                    if not _G.TsunamiEnabled then break end

                    local char = LocalPlayer.Character
                    local head = char and char:FindFirstChild("Head")
                    if not head then break end

                    pcall(function()
                        spawnRemote:InvokeServer("NinjaShuriken", head.CFrame * CFrame.new(0, 4, 0), Vector3.zero)
                    end)

                    local inv = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                    local targetToy = nil
                    local startTick = tick()

                    while tick() - startTick < 0.3 do
                        if not _G.TsunamiEnabled then break end
                        if inv then
                            for _, toy in pairs(inv:GetChildren()) do
                                if toy.Name == "NinjaShuriken" and not toy:GetAttribute("AttachedProcessed") then
                                    targetToy = toy
                                    break
                                end
                            end
                        end
                        if targetToy then break end
                        RunService.Heartbeat:Wait()
                    end

                    if targetToy and targetToy.Parent then
                        targetToy:SetAttribute("AttachedProcessed", true)
                        targetToy.Name = "TsunamiShurikenAttach"

                        local stickyPart = targetToy:FindFirstChild("StickyPart")
                        if stickyPart then
                            if targetToy:FindFirstChild("SoundPart") then
                                pcall(function()
                                    setOwner:FireServer(targetToy.SoundPart, targetToy.SoundPart.CFrame)
                                end)
                            end
                            
                            stickyEvent:FireServer(stickyPart, head, CFrame.new(0, 0, 0))
                            task.wait(0.05)

                            for _, desc in ipairs(stickyPart:GetDescendants()) do
                                if desc:IsA("Weld") or desc:IsA("WeldConstraint") or desc:IsA("Motor6D") then
                                    desc:Destroy()
                                end
                            end

                            if targetToy:FindFirstChild("SoundPart") then
                                pcall(function()
                                    setOwner:FireServer(targetToy.SoundPart, CFrame.new(targetOceanPos))
                                end)
                            end

                            for _, part in pairs(targetToy:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.CFrame = CFrame.new(targetOceanPos)
                                    part.AssemblyLinearVelocity = Vector3.zero
                                    part.AssemblyAngularVelocity = Vector3.zero
                                end
                            end

                            spawnedCount = spawnedCount + 1
                        end
                    end
                    task.wait(0.1)
                end

                if spawnedCount >= 10 and _G.TsunamiEnabled then
                    task.wait(0.5)

                    if getgenv().OceanHitbox and getgenv().OceanHitbox:IsA("BasePart") then
                        pcall(function()
                            setOwner:FireServer(getgenv().OceanHitbox, getgenv().OceanHitbox.CFrame)
                        end)
                        getgenv().OceanHitbox.Anchored = false

                        pcall(function()
                            getgenv().OceanHitbox:SetNetworkOwner(LocalPlayer)
                        end)

                        if getgenv().OceanConnection then
                            getgenv().OceanConnection:Disconnect()
                        end
                        
                        local fixedBasePos = Vector3.new(getgenv().OceanHitbox.Position.X, -20, getgenv().OceanHitbox.Position.Z)
                        local startTime = tick()
                        getgenv().OceanConnection = RunService.Heartbeat:Connect(function()
                            if not _G.TsunamiEnabled or not getgenv().OceanHitbox or not getgenv().OceanHitbox.Parent then
                                if getgenv().OceanConnection then
                                    getgenv().OceanConnection:Disconnect()
                                    getgenv().OceanConnection = nil
                                end
                                return
                            end
                            
                            local waveOffset = math.sin((tick() - startTime) * 4) * 20
                            local currentPos = fixedBasePos + Vector3.new(0, waveOffset, 0)
                            
                            getgenv().OceanHitbox.CFrame = CFrame.new(currentPos)
                            getgenv().OceanHitbox.AssemblyLinearVelocity = Vector3.zero
                            getgenv().OceanHitbox.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end
                end
            end)
        end
    end)

    -- ============================================================
    -- 2. BREAK COLLISION
    -- ============================================================
    local breakBox = createMiscItem(serverBox, "Break Collision", sStartY + sItemHeight + gap)

    local bcTitle = Instance.new("TextLabel")
    bcTitle.Size = UDim2.new(1, -40, 0, 25)
    bcTitle.Position = UDim2.new(0, 12, 0, 4)
    bcTitle.BackgroundTransparency = 1
    bcTitle.TextXAlignment = Enum.TextXAlignment.Left
    bcTitle.Text = "Break Collision Keybind"
    bcTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    bcTitle.TextTransparency = 0.05
    bcTitle.TextSize = 13
    bcTitle.Font = Enum.Font.GothamBold
    bcTitle.Parent = breakBox

    local bcKeyBtn = Instance.new("TextButton")
    bcKeyBtn.Size = UDim2.new(1, -24, 0, 28)
    bcKeyBtn.Position = UDim2.new(0, 12, 0, 32)
    bcKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    bcKeyBtn.BackgroundTransparency = 0.2
    bcKeyBtn.Text = "G"
    bcKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bcKeyBtn.TextTransparency = 0.05
    bcKeyBtn.TextSize = 14
    bcKeyBtn.Font = Enum.Font.GothamBold
    bcKeyBtn.Parent = breakBox

    local bcKeyCorner = Instance.new("UICorner")
    bcKeyCorner.CornerRadius = UDim.new(0, 14)
    bcKeyCorner.Parent = bcKeyBtn

    local bcKeyStroke = Instance.new("UIStroke")
    bcKeyStroke.Color = Color3.fromRGB(180, 180, 180)
    bcKeyStroke.Transparency = 0.2
    bcKeyStroke.Thickness = 0.8
    bcKeyStroke.Parent = bcKeyBtn

    local listeningForBcKey = false
    bcKeyBtn.MouseButton1Click:Connect(function()
        if listeningForBcKey then return end
        listeningForBcKey = true
        bcKeyBtn.Text = "..."
        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gp)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                breakCollisionKey = input.KeyCode
                bcKeyBtn.Text = input.KeyCode.Name
                listeningForBcKey = false
                connection:Disconnect()
            end
        end)
    end)

    local function executeBreakCollision()
        task.spawn(function()
            local StickyPartEvent = ReplicatedStorage:FindFirstChild("PlayerEvents") and ReplicatedStorage.PlayerEvents:FindFirstChild("StickyPartEvent")
            local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
            
            if not StickyPartEvent or not spawnRemote then return end

            local char = LocalPlayer.Character
            if not char then return end
            
            local head = char:FindFirstChild("Head")
            if not head then return end

            local camCF = workspace.CurrentCamera.CFrame
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {character}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            local rayResult = Workspace:Raycast(camCF.Position, camCF.LookVector * 2000, rayParams)

            if not rayResult or not rayResult.Instance then return end

            local Target = rayResult.Instance

            pcall(function()
                spawnRemote:InvokeServer("NinjaShuriken", head.CFrame * CFrame.new(0, 4, 0), Vector3.zero)
            end)

            task.wait(0.15)

            local playerToys = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
            if not playerToys then return end

            for _, Toy in pairs(playerToys:GetChildren()) do
                if Toy:IsA("Model") and Toy.Name:find("Shuriken") then
                    local StickyPart = Toy:FindFirstChild("StickyPart")
                    if StickyPart and StickyPart:IsA("BasePart") then
                        pcall(function()
                            StickyPartEvent:FireServer(
                                StickyPart,
                                Target,
                                CFrame.new(5.3e+09, 5.3e+09, 5.3e+09)
                            )
                        end)
                    end
                end
            end
        end)
    end

    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == breakCollisionKey then
                executeBreakCollision()
            end
        end
    end)

    -- ============================================================
    -- ВЫСОТА ГРУППЫ SERVER
    -- ============================================================
    local sHeight = sStartY + (sItemHeight + gap) * 2 - gap + gap
    serverBox.Size = UDim2.new(0, 300, 0, sHeight)

-- ============================================================
-- BREAK BARRIER (В MISC TAB, ВМЕСТО RAGDOLL ALL)
-- ============================================================
local breakBarrierBox = Instance.new("Frame")
breakBarrierBox.Size = UDim2.new(0, 300, 0, 0)
breakBarrierBox.Position = UDim2.new(0, 300 + 20 + gap, 0, sHeight + gap + 20)
breakBarrierBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
breakBarrierBox.BackgroundTransparency = 0.25
breakBarrierBox.ClipsDescendants = true
breakBarrierBox.Parent = miscContentArea

local bbBoxCorner = Instance.new("UICorner")
bbBoxCorner.CornerRadius = UDim.new(0, 18)
bbBoxCorner.Parent = breakBarrierBox

local bbBoxStroke = Instance.new("UIStroke")
bbBoxStroke.Color = Color3.fromRGB(180, 180, 180)
bbBoxStroke.Transparency = 0.2
bbBoxStroke.Thickness = 1.0
bbBoxStroke.Parent = breakBarrierBox

local bbTitle = Instance.new("TextLabel")
bbTitle.Size = UDim2.new(1, -30, 0, 30)
bbTitle.Position = UDim2.new(0, 15, 0, 8)
bbTitle.BackgroundTransparency = 1
bbTitle.TextXAlignment = Enum.TextXAlignment.Left
bbTitle.Text = "Break Barrier"
bbTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
bbTitle.TextTransparency = 0.05
bbTitle.TextSize = 16
bbTitle.Font = Enum.Font.GothamBold
bbTitle.Parent = breakBarrierBox

local bbLine = Instance.new("Frame")
bbLine.Size = UDim2.new(1, -30, 0, 1.5)
bbLine.Position = UDim2.new(0, 15, 0, 42)
bbLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
bbLine.BackgroundTransparency = 0.3
bbLine.BorderSizePixel = 0
bbLine.Parent = breakBarrierBox

local bbStartY = 52
local bbItemHeight = 48

-- ============================================================
-- ДРОПДАУН ДЛЯ ВЫБОРА ПЛОТА
-- ============================================================
local selectPlotBox = Instance.new("Frame")
selectPlotBox.Size = UDim2.new(1, -gap * 2, 0, bbItemHeight)
selectPlotBox.Position = UDim2.new(0, gap, 0, bbStartY)
selectPlotBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
selectPlotBox.BackgroundTransparency = 0.25
selectPlotBox.ClipsDescendants = true
selectPlotBox.Parent = breakBarrierBox

local spBoxCorner = Instance.new("UICorner")
spBoxCorner.CornerRadius = UDim.new(0, 18)
spBoxCorner.Parent = selectPlotBox

local spBoxStroke = Instance.new("UIStroke")
spBoxStroke.Color = Color3.fromRGB(180, 180, 180)
spBoxStroke.Transparency = 0.2
spBoxStroke.Thickness = 1.0
spBoxStroke.Parent = selectPlotBox

local spBtn = Instance.new("TextButton")
spBtn.Size = UDim2.new(1, -24, 0, 36)
spBtn.Position = UDim2.new(0, 12, 0, 6)
spBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
spBtn.BackgroundTransparency = 0.2
spBtn.Text = ""
spBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spBtn.TextTransparency = 0.05
spBtn.TextSize = 13
spBtn.Font = Enum.Font.GothamBold
spBtn.TextXAlignment = Enum.TextXAlignment.Left
spBtn.Parent = selectPlotBox

local spBtnCorner = Instance.new("UICorner")
spBtnCorner.CornerRadius = UDim.new(0, 14)
spBtnCorner.Parent = spBtn

local spBtnStroke = Instance.new("UIStroke")
spBtnStroke.Color = Color3.fromRGB(180, 180, 180)
spBtnStroke.Transparency = 0.2
spBtnStroke.Thickness = 0.8
spBtnStroke.Parent = spBtn

local spLabel = Instance.new("TextLabel")
spLabel.Size = UDim2.new(1, -40, 1, 0)
spLabel.Position = UDim2.new(0, 17, 0, 0)
spLabel.BackgroundTransparency = 1
spLabel.TextXAlignment = Enum.TextXAlignment.Left
spLabel.Text = "Select Plot"
spLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
spLabel.TextTransparency = 0.05
spLabel.TextSize = 13
spLabel.Font = Enum.Font.GothamBold
spLabel.Parent = spBtn

local spArrow = Instance.new("TextButton")
spArrow.Size = UDim2.new(0, 30, 1, 0)
spArrow.AnchorPoint = Vector2.new(1, 0.5)
spArrow.Position = UDim2.new(1, -12, 0.5, 0)
spArrow.BackgroundTransparency = 1
spArrow.Text = "▸"
spArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
spArrow.TextTransparency = 0.3
spArrow.TextSize = 16
spArrow.Font = Enum.Font.GothamBold
spArrow.Parent = spBtn

-- ============================================================
-- ОПЦИИ ДЛЯ ДРОПДАУНА
-- ============================================================
local plotOptions = {
    {Name = "Plot 1 (Green)", Id = "1"},
    {Name = "Plot 2 (Pink)", Id = "2"},
    {Name = "Plot 3 (Purple)", Id = "3"},
    {Name = "Plot 4 (Blue)", Id = "4"},
    {Name = "Plot 5 (Yellow)", Id = "5"},
}

local selectedPlotId = "1"
local dropdownOpen = false
local listContainer = nil
local scrollFrame = nil
local isAnimating = false

-- ============================================================
-- КНОПКА BREAK BARRIER
-- ============================================================
local breakBtnBox = Instance.new("Frame")
breakBtnBox.Size = UDim2.new(1, -gap * 2, 0, bbItemHeight)
breakBtnBox.Position = UDim2.new(0, gap, 0, bbStartY + bbItemHeight + gap)
breakBtnBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
breakBtnBox.BackgroundTransparency = 0.25
breakBtnBox.ClipsDescendants = true
breakBtnBox.Parent = breakBarrierBox

local brBoxCorner = Instance.new("UICorner")
brBoxCorner.CornerRadius = UDim.new(0, 18)
brBoxCorner.Parent = breakBtnBox

local brBoxStroke = Instance.new("UIStroke")
brBoxStroke.Color = Color3.fromRGB(180, 180, 180)
brBoxStroke.Transparency = 0.2
brBoxStroke.Thickness = 1.0
brBoxStroke.Parent = breakBtnBox

local brToggleBtn = Instance.new("TextButton")
brToggleBtn.Size = UDim2.new(1, -24, 1, -12)
brToggleBtn.Position = UDim2.new(0, 12, 0, 6)
brToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
brToggleBtn.BackgroundTransparency = 0.2
brToggleBtn.Text = ""
brToggleBtn.AutoButtonColor = false
brToggleBtn.Parent = breakBtnBox

local brToggleCorner = Instance.new("UICorner")
brToggleCorner.CornerRadius = UDim.new(0, 14)
brToggleCorner.Parent = brToggleBtn

local brToggleStroke = Instance.new("UIStroke")
brToggleStroke.Color = Color3.fromRGB(180, 180, 180)
brToggleStroke.Transparency = 0.2
brToggleStroke.Thickness = 0.8
brToggleStroke.Parent = brToggleBtn

local brToggleLabel = Instance.new("TextLabel")
brToggleLabel.Size = UDim2.new(1, -40, 1, 0)
brToggleLabel.Position = UDim2.new(0, 12, 0, 0)
brToggleLabel.BackgroundTransparency = 1
brToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
brToggleLabel.Text = "Enable Break"
brToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
brToggleLabel.TextSize = 12
brToggleLabel.Font = Enum.Font.GothamBold
brToggleLabel.Parent = brToggleBtn

local brCheckboxBox = Instance.new("Frame")
brCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
brCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
brCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
brCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
brCheckboxBox.BackgroundTransparency = 0.2
brCheckboxBox.BorderSizePixel = 0
brCheckboxBox.Parent = brToggleBtn

local brCbCorner = Instance.new("UICorner")
brCbCorner.CornerRadius = UDim.new(0, 6)
brCbCorner.Parent = brCheckboxBox

local brCbStroke = Instance.new("UIStroke")
brCbStroke.Color = Color3.fromRGB(150, 150, 150)
brCbStroke.Transparency = 0.2
brCbStroke.Thickness = 1
brCbStroke.Parent = brCheckboxBox

local brCheckmark = Instance.new("TextLabel")
brCheckmark.Size = UDim2.new(1, 0, 1, 0)
brCheckmark.BackgroundTransparency = 1
brCheckmark.Text = "✓"
brCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
brCheckmark.TextSize = 14
brCheckmark.Font = Enum.Font.GothamBold
brCheckmark.Visible = false
brCheckmark.Parent = brCheckboxBox

-- ============================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================
local function getHRP()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart
    else
        local character = LocalPlayer.CharacterAdded:Wait()
        return character:WaitForChild("HumanoidRootPart")
    end
end

local function getOrCreateShuriken()
    local playersInPlots = Workspace:FindFirstChild("PlotItems") and Workspace.PlotItems:FindFirstChild("PlayersInPlots")
    if playersInPlots and playersInPlots:FindFirstChild(LocalPlayer.Name) then
        return nil
    end
    
    local inv = Workspace:FindFirstChild(LocalPlayer.Name.."SpawnedInToys")
    if not inv then return nil end
    
    local myHRP = getHRP()
    for _, obj in pairs(inv:GetChildren()) do
        if (obj.Name == "NinjaShuriken" or obj.Name == "Noclipped") and obj:FindFirstChild("StickyPart") and obj:FindFirstChild("SoundPart") then
            if myHRP and (obj.StickyPart.Position - myHRP.Position).Magnitude <= 12 then
                return obj
            end
        end
    end
    
    local currentHRP = getHRP()
    if not currentHRP then return nil end
    
    local toyAdded
    local shur = nil
    toyAdded = inv.ChildAdded:Connect(function(child)
        if child.Name == "NinjaShuriken" then
            shur = child
            toyAdded:Disconnect()
        end
    end)
    
    local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
    if spawnRemote then
        pcall(function()
            spawnRemote:InvokeServer("NinjaShuriken", currentHRP.CFrame * CFrame.new(5, 8, 20), Vector3.new(0, 0, 0))
        end)
    end
    
    local startTime = tick()
    repeat
        if shur and shur:FindFirstChild("StickyPart") and shur:FindFirstChild("SoundPart") then
            return shur
        end
        task.wait(0.01)
    until tick() - startTime > 0.1
    
    return inv:FindFirstChild("NinjaShuriken")
end

local function BreakBarrier(plotId)
    local shur = getOrCreateShuriken()
    if not shur then return end
    
    local soundPart = shur:FindFirstChild("SoundPart")
    local stickyPart = shur:FindFirstChild("StickyPart")
    if not stickyPart then return end
    
    if soundPart then
        local setOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
        if setOwner then
            for i = 1, 20 do
                setOwner:FireServer(soundPart, soundPart.CFrame)
                if soundPart:FindFirstChild("PartOwner") and soundPart.PartOwner.Value == LocalPlayer.Name then break end
            end
        end
    end
    
    for _, obj in pairs(shur:GetChildren()) do
        if obj:IsA("BasePart") then
            obj.CanTouch = false
            obj.CanCollide = false
            obj.CanQuery = false
            if obj.Transparency == 0 then obj.Transparency = 1 end
        end
    end
    shur.Name = "Noclipped"
    
    local plot = Workspace.Plots:FindFirstChild("Plot"..plotId)
    if not plot then 
        return 
    end
    local plotArea = plot:FindFirstChild("PlotArea")
    if not plotArea then 
        return 
    end
    
    local stickyEvent = ReplicatedStorage:FindFirstChild("PlayerEvents") and ReplicatedStorage.PlayerEvents:FindFirstChild("StickyPartEvent")
    if stickyEvent then
        pcall(function()
            stickyEvent:FireServer(stickyPart, plotArea, CFrame.new(1099511627776, 1099511627776, 1099511627776, 1, 0, 0, 0, 1, 0, 0, 0, 1))
        end)
    end
end

-- ============================================================
-- ТОГГЛ BREAK BARRIER
-- ============================================================
local breakBarrierEnabled = false

brToggleBtn.MouseButton1Click:Connect(function()
    breakBarrierEnabled = not breakBarrierEnabled
    brCheckmark.Visible = breakBarrierEnabled
    
    if breakBarrierEnabled then
        BreakBarrier(selectedPlotId)
    end
end)

-- ============================================================
-- ФУНКЦИЯ ОТКРЫТИЯ/ЗАКРЫТИЯ ДРОПДАУНА
-- ============================================================
local function togglePlotDropdown()
    if isAnimating then return end
    
    if dropdownOpen then
        isAnimating = true
        
        local targetHeight = bbItemHeight
        
        local tween1 = TweenService:Create(selectPlotBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -gap * 2, 0, targetHeight)
        })
        tween1:Play()
        
        local tween2 = TweenService:Create(breakBtnBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, gap, 0, bbStartY + targetHeight + gap)
        })
        tween2:Play()
        
        local newHeight = bbStartY + targetHeight + gap + bbItemHeight + gap
        local tween3 = TweenService:Create(breakBarrierBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 300, 0, newHeight)
        })
        tween3:Play()
        
        tween1.Completed:Wait()
        
        if listContainer then
            listContainer:Destroy()
            listContainer = nil
            scrollFrame = nil
        end
        
        dropdownOpen = false
        spArrow.Text = "▸"
        isAnimating = false
    else
        isAnimating = true
        dropdownOpen = true
        spArrow.Text = "▾"
        
        listContainer = Instance.new("Frame")
        listContainer.Size = UDim2.new(1, 0, 0, 0)
        listContainer.Position = UDim2.new(0, 0, 0, bbItemHeight)
        listContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        listContainer.BackgroundTransparency = 1
        listContainer.ClipsDescendants = true
        listContainer.ZIndex = 10
        listContainer.Parent = selectPlotBox

        scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, -10, 1, -10)
        scrollFrame.Position = UDim2.new(0, 5, 0, 5)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.BorderSizePixel = 0
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.ScrollBarThickness = 4
        scrollFrame.ClipsDescendants = true
        scrollFrame.Parent = listContainer

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 4)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.Parent = scrollFrame

        for _, opt in ipairs(plotOptions) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 36)
            btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            btn.BackgroundTransparency = 0.2
            btn.Text = opt.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 13
            btn.Font = Enum.Font.GothamBold
            btn.TextXAlignment = Enum.TextXAlignment.Center
            btn.Parent = scrollFrame

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 14)
            btnCorner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                selectedPlotId = opt.Id
                spLabel.Text = "Select Plot → " .. opt.Name
                
                if breakBarrierEnabled then
                    BreakBarrier(selectedPlotId)
                end
                
                -- ЗАКРЫВАЕМ ДРОПДАУН ПОСЛЕ ВЫБОРА
                local targetHeight = bbItemHeight
                
                local tween1 = TweenService:Create(selectPlotBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, -gap * 2, 0, targetHeight)
                })
                tween1:Play()
                
                local tween2 = TweenService:Create(breakBtnBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, gap, 0, bbStartY + targetHeight + gap)
                })
                tween2:Play()
                
                local newHeight = bbStartY + targetHeight + gap + bbItemHeight + gap
                local tween3 = TweenService:Create(breakBarrierBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 300, 0, newHeight)
                })
                tween3:Play()
                
                tween1.Completed:Wait()
                
                if listContainer then
                    listContainer:Destroy()
                    listContainer = nil
                    scrollFrame = nil
                end
                
                dropdownOpen = false
                spArrow.Text = "▸"
                isAnimating = false
            end)
        end

        local children = scrollFrame:GetChildren()
        local totalHeight = #children * 40 + 10
        local listHeight = math.min(math.max(totalHeight, 50), 150)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(totalHeight, scrollFrame.Size.Y.Offset))
        
        listContainer.Size = UDim2.new(1, 0, 0, listHeight)
        
        local targetHeight = bbItemHeight + listHeight
        
        local tween1 = TweenService:Create(selectPlotBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -gap * 2, 0, targetHeight)
        })
        tween1:Play()
        
        local tween2 = TweenService:Create(breakBtnBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, gap, 0, bbStartY + targetHeight + gap)
        })
        tween2:Play()
        
        local newHeight = bbStartY + targetHeight + gap + bbItemHeight + gap
        local tween3 = TweenService:Create(breakBarrierBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 300, 0, newHeight)
        })
        tween3:Play()
        
        tween1.Completed:Wait()
        isAnimating = false
    end
end

spArrow.MouseButton1Click:Connect(togglePlotDropdown)
spBtn.MouseButton1Click:Connect(function()
    if not dropdownOpen then
        togglePlotDropdown()
    end
end)

-- ============================================================
-- ВЫСОТА ФРЕЙМА
-- ============================================================
local bbHeight = bbStartY + bbItemHeight + gap + bbItemHeight + gap
breakBarrierBox.Size = UDim2.new(0, 300, 0, bbHeight)

-- ============================================================
-- ОБНОВЛЯЕМ CANVAS
-- ============================================================
local currentCanvas = miscContentArea.CanvasSize.Y.Offset
miscContentArea.CanvasSize = UDim2.new(0, 0, 0, currentCanvas + bbHeight + gap + 20)
    -- ============================================================
    -- ГРУППА 4: DEFENSE FOR FRIENDS (СЛЕВА ВНИЗУ)
    -- ============================================================
    local defenseForFriendsBox = Instance.new("Frame")
    defenseForFriendsBox.Size = UDim2.new(0, 300, 0, 0)
    defenseForFriendsBox.Position = UDim2.new(0, 20, 0, tfHeight + gap + 20)
    defenseForFriendsBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    defenseForFriendsBox.BackgroundTransparency = 0.25
    defenseForFriendsBox.ClipsDescendants = true
    defenseForFriendsBox.Parent = miscContentArea

    local dffBoxCorner = Instance.new("UICorner")
    dffBoxCorner.CornerRadius = UDim.new(0, 18)
    dffBoxCorner.Parent = defenseForFriendsBox

    local dffBoxStroke = Instance.new("UIStroke")
    dffBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    dffBoxStroke.Transparency = 0.2
    dffBoxStroke.Thickness = 1.0
    dffBoxStroke.Parent = defenseForFriendsBox

    local dffTitle = Instance.new("TextLabel")
    dffTitle.Size = UDim2.new(1, -30, 0, 30)
    dffTitle.Position = UDim2.new(0, 15, 0, 8)
    dffTitle.BackgroundTransparency = 1
    dffTitle.TextXAlignment = Enum.TextXAlignment.Left
    dffTitle.Text = "Defense For Friends"
    dffTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    dffTitle.TextTransparency = 0.05
    dffTitle.TextSize = 16
    dffTitle.Font = Enum.Font.GothamBold
    dffTitle.Parent = defenseForFriendsBox

    local dffLine = Instance.new("Frame")
    dffLine.Size = UDim2.new(1, -30, 0, 1.5)
    dffLine.Position = UDim2.new(0, 15, 0, 42)
    dffLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    dffLine.BackgroundTransparency = 0.3
    dffLine.BorderSizePixel = 0
    dffLine.Parent = defenseForFriendsBox

    -- ============================================================
    -- SELECT FRIEND (UI)
    -- ============================================================
    local selectFriendBox = Instance.new("Frame")
    selectFriendBox.Size = UDim2.new(1, -gap * 2, 0, 48)
    selectFriendBox.Position = UDim2.new(0, gap, 0, 52)
    selectFriendBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    selectFriendBox.BackgroundTransparency = 0.25
    selectFriendBox.ClipsDescendants = true
    selectFriendBox.Parent = defenseForFriendsBox

    local sfBoxCorner = Instance.new("UICorner")
    sfBoxCorner.CornerRadius = UDim.new(0, 18)
    sfBoxCorner.Parent = selectFriendBox

    local sfBoxStroke = Instance.new("UIStroke")
    sfBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    sfBoxStroke.Transparency = 0.2
    sfBoxStroke.Thickness = 1.0
    sfBoxStroke.Parent = selectFriendBox

    local sfBtn = Instance.new("TextButton")
    sfBtn.Size = UDim2.new(1, -24, 0, 36)
    sfBtn.Position = UDim2.new(0, 12, 0, 6)
    sfBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    sfBtn.BackgroundTransparency = 0.2
    sfBtn.Text = ""
    sfBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sfBtn.TextTransparency = 0.05
    sfBtn.TextSize = 13
    sfBtn.Font = Enum.Font.GothamBold
    sfBtn.TextXAlignment = Enum.TextXAlignment.Left
    sfBtn.Parent = selectFriendBox

    local sfBtnCorner = Instance.new("UICorner")
    sfBtnCorner.CornerRadius = UDim.new(0, 14)
    sfBtnCorner.Parent = sfBtn

    local sfBtnStroke = Instance.new("UIStroke")
    sfBtnStroke.Color = Color3.fromRGB(180, 180, 180)
    sfBtnStroke.Transparency = 0.2
    sfBtnStroke.Thickness = 0.8
    sfBtnStroke.Parent = sfBtn

    local sfLabel = Instance.new("TextLabel")
    sfLabel.Size = UDim2.new(1, -40, 1, 0)
    sfLabel.Position = UDim2.new(0, 17, 0, 0)
    sfLabel.BackgroundTransparency = 1
    sfLabel.TextXAlignment = Enum.TextXAlignment.Left
    sfLabel.Text = "Select Friend"
    sfLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sfLabel.TextTransparency = 0.05
    sfLabel.TextSize = 13
    sfLabel.Font = Enum.Font.GothamBold
    sfLabel.Parent = sfBtn

    local sfArrow = Instance.new("TextButton")
    sfArrow.Size = UDim2.new(0, 30, 1, 0)
    sfArrow.AnchorPoint = Vector2.new(1, 0.5)
    sfArrow.Position = UDim2.new(1, -12, 0.5, 0)
    sfArrow.BackgroundTransparency = 1
    sfArrow.Text = "▸"
    sfArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
    sfArrow.TextTransparency = 0.3
    sfArrow.TextSize = 16
    sfArrow.Font = Enum.Font.GothamBold
    sfArrow.Parent = sfBtn

    -- ============================================================
    -- ПЕРЕМЕННЫЕ ДЛЯ DEFENSE FOR FRIENDS
    -- ============================================================
    local selectedFriend = nil
    local dropdownOpen = false
    local friendsContainer = nil
    local friendsScrollFrame = nil
    local isAnimating = false
    local protectToggleBox = nil
    local antiGrabToggleBox = nil

    local antiKickActive = false
    local antiGrabActive = false
    local antiKickTask = nil
    local antiGrabTask = nil
    local protectedTarget = nil

    -- ============================================================
    -- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
    -- ============================================================
    local function GetOnlinePlayers()
        local list = {}
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                table.insert(list, {
                    Name = plr.Name,
                    DisplayName = plr.DisplayName,
                    UserId = plr.UserId
                })
            end
        end
        table.sort(list, function(a, b)
            return a.Name < b.Name
        end)
        return list
    end

    local function sno(part)
        local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
        if GE then
            local SetNetworkOwner = GE:FindFirstChild("SetNetworkOwner")
            if SetNetworkOwner then
                SetNetworkOwner:FireServer(part, part.CFrame)
            end
        end
    end

    local function unsno(part)
        local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
        if GE then
            local DestroyGrabLine = GE:FindFirstChild("DestroyGrabLine")
            if DestroyGrabLine then
                DestroyGrabLine:FireServer(part)
            end
        end
    end

    local function CheckForPartOwner(Head)
        if not Head then return false end
        local PartOwner = Head:FindFirstChild("PartOwner")
        return PartOwner and PartOwner.Value == LocalPlayer.Name
    end

    local function SpawnToy(ToyName)
        local SpawnToyRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
        local inv = Workspace:FindFirstChild(LocalPlayer.Name.."SpawnedInToys")
        local InPlot = LocalPlayer.InPlot
        local InOwnedPlot = LocalPlayer.InOwnedPlot
        local CanSpawnToy = LocalPlayer.CanSpawnToy
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if InPlot and InPlot.Value and not InOwnedPlot.Value then 
            InPlot:GetPropertyChangedSignal("Value"):Wait()
        end 
        if CanSpawnToy and not CanSpawnToy.Value then 
            CanSpawnToy:GetPropertyChangedSignal("Value"):Wait()
        end

        local SpawnCF = hrp and hrp.CFrame * CFrame.new(0, 14, 20) or CFrame.new(0, 10, 0)
        local Container = InOwnedPlot and InOwnedPlot.Value and Workspace.PlotItems:FindFirstChild("Plot1") or inv
        if not Container then return nil end

        local spawnedObject = nil
        local connection
        connection = Container.ChildAdded:Connect(function(child)
            if child.Name == ToyName then
                spawnedObject = child
            end
        end)

        task.spawn(function()
            pcall(function()
                SpawnToyRemote:InvokeServer(ToyName, SpawnCF, Vector3.zero)
            end)
        end)

        local start = tick()
        repeat task.wait() until spawnedObject or (tick() - start) > 2.5
        connection:Disconnect()
        return spawnedObject
    end

    local function getBlob()
        local inv = Workspace:FindFirstChild(LocalPlayer.Name.."SpawnedInToys")
        if inv then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == "CreatureBlobman" then
                    return v
                end
            end
        end
        for _, plot in pairs(Workspace.PlotItems:GetChildren()) do
            if plot.Name ~= "PlayersInPlots" then
                for _, v in pairs(plot:GetChildren()) do
                    if v.Name == "CreatureBlobman" then
                        return v
                    end
                end
            end
        end
        return nil
    end

    -- ============================================================
    -- ЛОГИКА: ANTI KICK PROTECTION
    -- ============================================================
    local function startAntiKickProtection(targetName)
        if antiKickTask then
            task.cancel(antiKickTask)
            antiKickTask = nil
        end

        antiKickActive = true
        local shurikens = {}
        local setupDone = {}

        antiKickTask = task.spawn(function()
            while antiKickActive do
                RunService.RenderStepped:Wait()

                local target = Players:FindFirstChild(targetName)
                if not target or not target.Character then
                    task.wait(0.5)
                    continue
                end

                pcall(function()
                    local targetChar = target.Character
                    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                    local targetFirePart = targetHRP and targetHRP:FindFirstChild("FirePlayerPart")

                    if not targetHRP or not targetFirePart then
                        return
                    end

                    local myChar = LocalPlayer.Character
                    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

                    if myHRP then
                        local dist = (targetHRP.Position - myHRP.Position).Magnitude
                        if dist > 30 then
                            setupDone[targetName] = false
                            return
                        end
                    end

                    local targetInv = Workspace:FindFirstChild(target.Name .. "SpawnedInToys")
                    if not targetInv then
                        return
                    end

                    local shuName = "AntiKickShuriken_" .. targetName
                    local shuData = shurikens[targetName]
                    local shu = shuData and shuData.toy
                    local part = shuData and shuData.part
                    local shuExists = shu and shu.Parent ~= nil
                    local partExists = part and part.Parent ~= nil

                    if setupDone[targetName] and (not shuExists or not partExists) then
                        setupDone[targetName] = false
                        shurikens[targetName] = nil
                    end

                    if not setupDone[targetName] then
                        if not target.CanSpawnToy or not target.CanSpawnToy.Value then
                            return
                        end

                        local SetNetworkOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
                        local DestroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
                        local SpawnToyRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
                        local StickyEvent = ReplicatedStorage:FindFirstChild("PlayerEvents") and ReplicatedStorage.PlayerEvents:FindFirstChild("StickyPartEvent")

                        if not SetNetworkOwner or not DestroyToy or not SpawnToyRemote or not StickyEvent then return end

                        -- СПАВНИМ СЮРИКЕН
                        local function spawnShuriken(toy, cf)
                            local t
                            local inv2 = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                            local toyadded = inv2.ChildAdded:Connect(function(c)
                                if c.Name == toy then
                                    t = c
                                    toyadded:Disconnect()
                                end
                            end)
                            task.spawn(function()
                                SpawnToyRemote:InvokeServer(toy, cf, Vector3.new(0, 0, 0))
                            end)
                            local time = tick() + 1
                            repeat task.wait() until t or tick() > time
                            if t then
                                return t
                            else
                                return nil
                            end
                        end

                        shu = spawnShuriken("NinjaShuriken", targetHRP.CFrame * CFrame.new(5, 10, 20))
                        if not shu then
                            return
                        end

                        shu.Name = shuName
                        part = shu:WaitForChild("StickyPart", 0.5)
                        if not part then
                            return
                        end

                        SetNetworkOwner:FireServer(part, part.CFrame)
                        task.wait(0.1)
                        StickyEvent:FireServer(part, targetFirePart, CFrame.new(0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 1, 0))

                        shurikens[targetName] = {
                            toy = shu,
                            part = part,
                        }
                        setupDone[targetName] = true
                    end

                    if part and part:FindFirstChild("PartOwner") and part.PartOwner.Value ~= LocalPlayer.Name then
                        local SetNetworkOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
                        if SetNetworkOwner then
                            SetNetworkOwner:FireServer(part, part.CFrame)
                        end
                    end

                    -- Очистка чужих предметов у цели
                    local DestroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
                    local SetNetworkOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
                    
                    for _, toy in ipairs(targetInv:GetChildren()) do
                        if toy:FindFirstChild("StickyPart") then
                            local sp = toy.StickyPart
                            local po = sp:FindFirstChild("PartOwner")
                            local sw = sp:FindFirstChild("StickyWeld")

                            if po and po.Value ~= "" and po.Value ~= target.Name then
                                if SetNetworkOwner then
                                    SetNetworkOwner:FireServer(sp, sp.CFrame)
                                end
                                task.wait()
                                if po.Value == LocalPlayer.Name then
                                    sp.CFrame = CFrame.new(0, 0/0, 0)
                                end
                            end
                            if sw and sw.Part1 then
                                local weldParent = sw.Part1.Parent
                                if weldParent and weldParent ~= targetChar then
                                    if SetNetworkOwner then
                                        SetNetworkOwner:FireServer(sp, sp.CFrame)
                                    end
                                    task.wait()
                                    if po and po.Value == LocalPlayer.Name then
                                        sp.CFrame = CFrame.new(0, 0/0, 0)
                                    end
                                end
                            end
                        end
                    end
                end)

                task.wait(0.1)
            end

            -- Очистка при выключении
            local DestroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
            for _, data in pairs(shurikens) do
                pcall(function()
                    if data.toy and DestroyToy then
                        DestroyToy:FireServer(data.toy)
                    end
                end)
            end
        end)
    end

    local function stopAntiKickProtection()
        antiKickActive = false
        if antiKickTask then
            task.cancel(antiKickTask)
            antiKickTask = nil
        end
        local DestroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
        local inv = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        if inv and DestroyToy then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name:find("AntiKickShuriken_") then
                    pcall(function()
                        DestroyToy:FireServer(v)
                    end)
                end
            end
        end
    end

    -- ============================================================
    -- ЛОГИКА: ANTI GRAB PROTECTION
    -- ============================================================
    local function startAntiGrabProtection(targetName)
        if antiGrabTask then
            task.cancel(antiGrabTask)
            antiGrabTask = nil
        end

        antiGrabActive = true

        antiGrabTask = task.spawn(function()
            local SetNetworkOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
            local DestroyGrabLine = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("DestroyGrabLine")
            local CreateGrabLine = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("CreateGrabLine")
            local Struggle = ReplicatedStorage:FindFirstChild("CharacterEvents") and ReplicatedStorage.CharacterEvents:FindFirstChild("Struggle")
            
            while antiGrabActive do
                task.wait(0.1)

                local target = Players:FindFirstChild(targetName)
                if not target or not target.Character then
                    task.wait(0.5)
                    continue
                end

                pcall(function()
                    local targetChar = target.Character
                    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                    local targetHead = targetChar:FindFirstChild("Head")

                    if not targetHRP or not targetHead then
                        return
                    end

                    local partOwner = targetHead:FindFirstChild("PartOwner")
                    if not partOwner or partOwner.Value == "" or partOwner.Value == target.Name then
                        return
                    end

                    local myChar = LocalPlayer.Character
                    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not myHRP then
                        return
                    end

                    local distance = (targetHRP.Position - myHRP.Position).Magnitude

                    if distance <= 30 then
                        if SetNetworkOwner then
                            SetNetworkOwner:FireServer(targetHRP, targetHRP.CFrame)
                        end
                        if CreateGrabLine then
                            CreateGrabLine:FireServer(targetHRP, Vector3.zero, targetHRP.Position, false)
                        end
                        if Struggle then
                            Struggle:FireServer(target)
                        end

                        if targetHead:FindFirstChild("PartOwner") and targetHead.PartOwner.Value == LocalPlayer.Name then
                            if DestroyGrabLine then
                                DestroyGrabLine:FireServer(targetHRP)
                            end
                        end
                    end
                end)
            end
        end)
    end

    local function stopAntiGrabProtection()
        antiGrabActive = false
        if antiGrabTask then
            task.cancel(antiGrabTask)
            antiGrabTask = nil
        end
    end

    -- ============================================================
    -- ДРОПДАУН (UI + ЛОГИКА)
    -- ============================================================
    local function toggleDropdown()
        if isAnimating then return end
        
        if dropdownOpen then
            isAnimating = true
            
            local targetHeight = 48
            local targetDffHeight = 52 + 48 + gap + 48 + gap + 48 + gap
            
            local tween1 = TweenService:Create(selectFriendBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, -gap * 2, 0, targetHeight)
            })
            
            if protectToggleBox then
                local tween2 = TweenService:Create(protectToggleBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, gap, 0, 52 + targetHeight + gap)
                })
                tween2:Play()
            end
            
            if antiGrabToggleBox then
                local tween3 = TweenService:Create(antiGrabToggleBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, gap, 0, 52 + targetHeight + gap + 48 + gap)
                })
                tween3:Play()
            end
            
            local tween4 = TweenService:Create(defenseForFriendsBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 300, 0, targetDffHeight)
            })
            tween4:Play()
            tween1:Play()
            tween1.Completed:Wait()
            
            if friendsContainer then
                friendsContainer:Destroy()
                friendsContainer = nil
                friendsScrollFrame = nil
            end
            
            dropdownOpen = false
            sfArrow.Text = "▸"
            isAnimating = false
        else
            isAnimating = true
            dropdownOpen = true
            sfArrow.Text = "▾"
            
            friendsContainer = Instance.new("Frame")
            friendsContainer.Size = UDim2.new(1, 0, 0, 0)
            friendsContainer.Position = UDim2.new(0, 0, 0, 48)
            friendsContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
            friendsContainer.BackgroundTransparency = 1
            friendsContainer.ClipsDescendants = true
            friendsContainer.ZIndex = 10
            friendsContainer.Parent = selectFriendBox

            friendsScrollFrame = Instance.new("ScrollingFrame")
            friendsScrollFrame.Size = UDim2.new(1, -10, 1, -10)
            friendsScrollFrame.Position = UDim2.new(0, 5, 0, 5)
            friendsScrollFrame.BackgroundTransparency = 1
            friendsScrollFrame.BorderSizePixel = 0
            friendsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
            friendsScrollFrame.ScrollBarThickness = 4
            friendsScrollFrame.ClipsDescendants = true
            friendsScrollFrame.Parent = friendsContainer

            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 4)
            listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            listLayout.Parent = friendsScrollFrame

            task.spawn(function()
                local onlinePlayers = GetOnlinePlayers()
                
                if #onlinePlayers == 0 then
                    local noPlayer = Instance.new("TextButton")
                    noPlayer.Size = UDim2.new(1, -20, 0, 40)
                    noPlayer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                    noPlayer.BackgroundTransparency = 0.2
                    noPlayer.Text = "No players online"
                    noPlayer.TextColor3 = Color3.fromRGB(150, 150, 150)
                    noPlayer.TextSize = 13
                    noPlayer.Font = Enum.Font.GothamBold
                    noPlayer.Parent = friendsScrollFrame
                    
                    local btnCorner = Instance.new("UICorner")
                    btnCorner.CornerRadius = UDim.new(0, 14)
                    btnCorner.Parent = noPlayer
                    
                    friendsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 50)
                    local listHeight = 50
                    friendsContainer.Size = UDim2.new(1, 0, 0, listHeight)
                    local targetHeight = 48 + listHeight
                    local targetDffHeight = 52 + targetHeight + gap + 48 + gap + 48 + gap
                    
                    local tween1 = TweenService:Create(selectFriendBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, -gap * 2, 0, targetHeight)
                    })
                    if protectToggleBox then
                        local tween2 = TweenService:Create(protectToggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Position = UDim2.new(0, gap, 0, 52 + targetHeight + gap)
                        })
                        tween2:Play()
                    end
                    if antiGrabToggleBox then
                        local tween3 = TweenService:Create(antiGrabToggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Position = UDim2.new(0, gap, 0, 52 + targetHeight + gap + 48 + gap)
                        })
                        tween3:Play()
                    end
                    local tween4 = TweenService:Create(defenseForFriendsBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 300, 0, targetDffHeight)
                    })
                    tween4:Play()
                    tween1:Play()
                    tween1.Completed:Wait()
                    isAnimating = false
                else
                    for _, playerData in ipairs(onlinePlayers) do
                        local playerBtn = Instance.new("TextButton")
                        playerBtn.Size = UDim2.new(1, -10, 0, 36)
                        playerBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                        playerBtn.BackgroundTransparency = 0.2
                        playerBtn.Text = playerData.DisplayName .. " (" .. playerData.Name .. ")"
                        playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        playerBtn.TextSize = 13
                        playerBtn.Font = Enum.Font.GothamBold
                        playerBtn.Parent = friendsScrollFrame

                        local btnCorner = Instance.new("UICorner")
                        btnCorner.CornerRadius = UDim.new(0, 14)
                        btnCorner.Parent = playerBtn

                        playerBtn.MouseButton1Click:Connect(function()
                            selectedFriend = playerData.Name
                            sfLabel.Text = "Select Friend → " .. playerData.DisplayName .. " (" .. playerData.Name .. ")"
                            protectedTarget = selectedFriend
                            
                            stopAntiKickProtection()
                            stopAntiGrabProtection()
                            
                            ptCheckmark.Visible = false
                            agCheckmark.Visible = false
                            
                            if friendsContainer then
                                friendsContainer:Destroy()
                                friendsContainer = nil
                                friendsScrollFrame = nil
                            end
                            dropdownOpen = false
                            sfArrow.Text = "▸"
                            selectFriendBox.Size = UDim2.new(1, -gap * 2, 0, 48)
                            
                            if protectToggleBox then
                                local tween2 = TweenService:Create(protectToggleBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                    Position = UDim2.new(0, gap, 0, 52 + 48 + gap)
                                })
                                tween2:Play()
                            end
                            if antiGrabToggleBox then
                                local tween3 = TweenService:Create(antiGrabToggleBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                    Position = UDim2.new(0, gap, 0, 52 + 48 + gap + 48 + gap)
                                })
                                tween3:Play()
                            end
                            
                            local targetDffHeight = 52 + 48 + gap + 48 + gap + 48 + gap
                            local tween4 = TweenService:Create(defenseForFriendsBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                Size = UDim2.new(0, 300, 0, targetDffHeight)
                            })
                            tween4:Play()
                        end)
                    end

                    local children = friendsScrollFrame:GetChildren()
                    local totalHeight = #children * 40 + 10
                    local listHeight = math.min(math.max(totalHeight, 50), 150)
                    friendsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(totalHeight, friendsScrollFrame.Size.Y.Offset))
                    
                    friendsContainer.Size = UDim2.new(1, 0, 0, listHeight)
                    
                    local targetHeight = 48 + listHeight
                    local targetDffHeight = 52 + targetHeight + gap + 48 + gap + 48 + gap
                    
                    local tween1 = TweenService:Create(selectFriendBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, -gap * 2, 0, targetHeight)
                    })
                    if protectToggleBox then
                        local tween2 = TweenService:Create(protectToggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Position = UDim2.new(0, gap, 0, 52 + targetHeight + gap)
                        })
                        tween2:Play()
                    end
                    if antiGrabToggleBox then
                        local tween3 = TweenService:Create(antiGrabToggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Position = UDim2.new(0, gap, 0, 52 + targetHeight + gap + 48 + gap)
                        })
                        tween3:Play()
                    end
                    local tween4 = TweenService:Create(defenseForFriendsBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 300, 0, targetDffHeight)
                    })
                    tween4:Play()
                    tween1:Play()
                    tween1.Completed:Wait()
                    isAnimating = false
                end
            end)
        end
    end

    sfArrow.MouseButton1Click:Connect(function()
        toggleDropdown()
    end)

    sfBtn.MouseButton1Click:Connect(function()
        if not dropdownOpen then
            toggleDropdown()
        end
    end)

    -- ============================================================
    -- UI: ANTI KICK PROTECTION
    -- ============================================================
    protectToggleBox = Instance.new("Frame")
    protectToggleBox.Size = UDim2.new(1, -gap * 2, 0, 48)
    protectToggleBox.Position = UDim2.new(0, gap, 0, 52 + 48 + gap)
    protectToggleBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    protectToggleBox.BackgroundTransparency = 0.25
    protectToggleBox.ClipsDescendants = true
    protectToggleBox.Parent = defenseForFriendsBox

    local ptBoxCorner = Instance.new("UICorner")
    ptBoxCorner.CornerRadius = UDim.new(0, 18)
    ptBoxCorner.Parent = protectToggleBox

    local ptBoxStroke = Instance.new("UIStroke")
    ptBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    ptBoxStroke.Transparency = 0.2
    ptBoxStroke.Thickness = 1.0
    ptBoxStroke.Parent = protectToggleBox

    local ptToggleBtn = Instance.new("TextButton")
    ptToggleBtn.Size = UDim2.new(1, -24, 1, -12)
    ptToggleBtn.Position = UDim2.new(0, 12, 0, 6)
    ptToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    ptToggleBtn.BackgroundTransparency = 0.2
    ptToggleBtn.Text = ""
    ptToggleBtn.AutoButtonColor = false
    ptToggleBtn.Parent = protectToggleBox

    local ptToggleCorner = Instance.new("UICorner")
    ptToggleCorner.CornerRadius = UDim.new(0, 14)
    ptToggleCorner.Parent = ptToggleBtn

    local ptToggleStroke = Instance.new("UIStroke")
    ptToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    ptToggleStroke.Transparency = 0.2
    ptToggleStroke.Thickness = 0.8
    ptToggleStroke.Parent = ptToggleBtn

    local ptToggleLabel = Instance.new("TextLabel")
    ptToggleLabel.Size = UDim2.new(1, -40, 1, 0)
    ptToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    ptToggleLabel.BackgroundTransparency = 1
    ptToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ptToggleLabel.Text = "Anti Kick Protection"
    ptToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    ptToggleLabel.TextSize = 13
    ptToggleLabel.Font = Enum.Font.GothamBold
    ptToggleLabel.Parent = ptToggleBtn

    local ptCheckboxBox = Instance.new("Frame")
    ptCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
    ptCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
    ptCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
    ptCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    ptCheckboxBox.BackgroundTransparency = 0.2
    ptCheckboxBox.BorderSizePixel = 0
    ptCheckboxBox.Parent = ptToggleBtn

    local ptCbCorner = Instance.new("UICorner")
    ptCbCorner.CornerRadius = UDim.new(0, 6)
    ptCbCorner.Parent = ptCheckboxBox

    local ptCbStroke = Instance.new("UIStroke")
    ptCbStroke.Color = Color3.fromRGB(150, 150, 150)
    ptCbStroke.Transparency = 0.2
    ptCbStroke.Thickness = 1
    ptCbStroke.Parent = ptCheckboxBox

    local ptCheckmark = Instance.new("TextLabel")
    ptCheckmark.Size = UDim2.new(1, 0, 1, 0)
    ptCheckmark.BackgroundTransparency = 1
    ptCheckmark.Text = "✓"
    ptCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    ptCheckmark.TextSize = 14
    ptCheckmark.Font = Enum.Font.GothamBold
    ptCheckmark.Visible = false
    ptCheckmark.Parent = ptCheckboxBox

    ptToggleBtn.MouseButton1Click:Connect(function()
        if not protectedTarget then
            return
        end

        if antiKickActive then
            stopAntiKickProtection()
            ptCheckmark.Visible = false
            ptToggleLabel.Text = "Anti Kick Protection"
        else
            startAntiKickProtection(protectedTarget)
            ptCheckmark.Visible = true
            ptToggleLabel.Text = "Anti Kick Protection [ACTIVE]"
        end
    end)

    -- ============================================================
    -- UI: ANTI GRAB PROTECTION
    -- ============================================================
    antiGrabToggleBox = Instance.new("Frame")
    antiGrabToggleBox.Size = UDim2.new(1, -gap * 2, 0, 48)
    antiGrabToggleBox.Position = UDim2.new(0, gap, 0, 52 + 48 + gap + 48 + gap)
    antiGrabToggleBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    antiGrabToggleBox.BackgroundTransparency = 0.25
    antiGrabToggleBox.ClipsDescendants = true
    antiGrabToggleBox.Parent = defenseForFriendsBox

    local agBoxCorner = Instance.new("UICorner")
    agBoxCorner.CornerRadius = UDim.new(0, 18)
    agBoxCorner.Parent = antiGrabToggleBox

    local agBoxStroke = Instance.new("UIStroke")
    agBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    agBoxStroke.Transparency = 0.2
    agBoxStroke.Thickness = 1.0
    agBoxStroke.Parent = antiGrabToggleBox

    local agToggleBtn = Instance.new("TextButton")
    agToggleBtn.Size = UDim2.new(1, -24, 1, -12)
    agToggleBtn.Position = UDim2.new(0, 12, 0, 6)
    agToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    agToggleBtn.BackgroundTransparency = 0.2
    agToggleBtn.Text = ""
    agToggleBtn.AutoButtonColor = false
    agToggleBtn.Parent = antiGrabToggleBox

    local agToggleCorner = Instance.new("UICorner")
    agToggleCorner.CornerRadius = UDim.new(0, 14)
    agToggleCorner.Parent = agToggleBtn

    local agToggleStroke = Instance.new("UIStroke")
    agToggleStroke.Color = Color3.fromRGB(180, 180, 180)
    agToggleStroke.Transparency = 0.2
    agToggleStroke.Thickness = 0.8
    agToggleStroke.Parent = agToggleBtn

    local agToggleLabel = Instance.new("TextLabel")
    agToggleLabel.Size = UDim2.new(1, -40, 1, 0)
    agToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    agToggleLabel.BackgroundTransparency = 1
    agToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    agToggleLabel.Text = "Anti Grab Protection"
    agToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    agToggleLabel.TextSize = 13
    agToggleLabel.Font = Enum.Font.GothamBold
    agToggleLabel.Parent = agToggleBtn

    local agCheckboxBox = Instance.new("Frame")
    agCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
    agCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
    agCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
    agCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    agCheckboxBox.BackgroundTransparency = 0.2
    agCheckboxBox.BorderSizePixel = 0
    agCheckboxBox.Parent = agToggleBtn

    local agCbCorner = Instance.new("UICorner")
    agCbCorner.CornerRadius = UDim.new(0, 6)
    agCbCorner.Parent = agCheckboxBox

    local agCbStroke = Instance.new("UIStroke")
    agCbStroke.Color = Color3.fromRGB(150, 150, 150)
    agCbStroke.Transparency = 0.2
    agCbStroke.Thickness = 1
    agCbStroke.Parent = agCheckboxBox

    local agCheckmark = Instance.new("TextLabel")
    agCheckmark.Size = UDim2.new(1, 0, 1, 0)
    agCheckmark.BackgroundTransparency = 1
    agCheckmark.Text = "✓"
    agCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    agCheckmark.TextSize = 14
    agCheckmark.Font = Enum.Font.GothamBold
    agCheckmark.Visible = false
    agCheckmark.Parent = agCheckboxBox

    agToggleBtn.MouseButton1Click:Connect(function()
        if not protectedTarget then
            return
        end

        if antiGrabActive then
            stopAntiGrabProtection()
            agCheckmark.Visible = false
            agToggleLabel.Text = "Anti Grab Protection"
        else
            startAntiGrabProtection(protectedTarget)
            agCheckmark.Visible = true
            agToggleLabel.Text = "Anti Grab Protection [ACTIVE]"
        end
    end)

    -- ============================================================
    -- ФИНАЛЬНЫЙ РАЗМЕР DEFENSE FOR FRIENDS
    -- ============================================================
    local dffHeight = 52 + 48 + gap + 48 + gap + 48 + gap
    defenseForFriendsBox.Size = UDim2.new(0, 300, 0, dffHeight)

    -- ============================================================
    -- ОБНОВЛЯЕМ CANVAS
    -- ============================================================
    local currentCanvas = miscContentArea.CanvasSize.Y.Offset
    miscContentArea.CanvasSize = UDim2.new(0, 0, 0, currentCanvas + dffHeight + gap + 20)

-- ============================================================
-- ГРУППА 5: SERVER LAG (ПОД DEFENSE FOR FRIENDS)
-- ============================================================
local dffPosY = defenseForFriendsBox.Position.Y.Offset
local dffHeight = defenseForFriendsBox.Size.Y.Offset

local serverLagBox = Instance.new("Frame")
serverLagBox.Size = UDim2.new(0, 300, 0, 150)
serverLagBox.Position = UDim2.new(0, 20, 0, dffPosY + dffHeight + gap)
serverLagBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
serverLagBox.BackgroundTransparency = 0.25
serverLagBox.ClipsDescendants = true
serverLagBox.Parent = miscContentArea

local slBoxCorner = Instance.new("UICorner")
slBoxCorner.CornerRadius = UDim.new(0, 18)
slBoxCorner.Parent = serverLagBox

local slBoxStroke = Instance.new("UIStroke")
slBoxStroke.Color = Color3.fromRGB(180, 180, 180)
slBoxStroke.Transparency = 0.2
slBoxStroke.Thickness = 1.0
slBoxStroke.Parent = serverLagBox

local slTitle = Instance.new("TextLabel")
slTitle.Size = UDim2.new(1, -30, 0, 30)
slTitle.Position = UDim2.new(0, 15, 0, 8)
slTitle.BackgroundTransparency = 1
slTitle.TextXAlignment = Enum.TextXAlignment.Left
slTitle.Text = "Server Lag"
slTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
slTitle.TextTransparency = 0.05
slTitle.TextSize = 16
slTitle.Font = Enum.Font.GothamBold
slTitle.Parent = serverLagBox

local slLine = Instance.new("Frame")
slLine.Size = UDim2.new(1, -30, 0, 1.5)
slLine.Position = UDim2.new(0, 15, 0, 42)
slLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
slLine.BackgroundTransparency = 0.3
slLine.BorderSizePixel = 0
slLine.Parent = serverLagBox

local slStartY = 52
local slItemHeight = 48

-- ============================================================
-- 1. SHURIKEN LAG
-- ============================================================
local slBox1 = Instance.new("Frame")
slBox1.Size = UDim2.new(1, -gap * 2, 0, slItemHeight)
slBox1.Position = UDim2.new(0, gap, 0, slStartY)
slBox1.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
slBox1.BackgroundTransparency = 0.25
slBox1.ClipsDescendants = true
slBox1.Parent = serverLagBox

local slBoxCorner1 = Instance.new("UICorner")
slBoxCorner1.CornerRadius = UDim.new(0, 18)
slBoxCorner1.Parent = slBox1

local slBoxStroke1 = Instance.new("UIStroke")
slBoxStroke1.Color = Color3.fromRGB(180, 180, 180)
slBoxStroke1.Transparency = 0.2
slBoxStroke1.Thickness = 1.0
slBoxStroke1.Parent = slBox1

local slToggleBtn1 = Instance.new("TextButton")
slToggleBtn1.Size = UDim2.new(1, -24, 1, -12)
slToggleBtn1.Position = UDim2.new(0, 12, 0, 6)
slToggleBtn1.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
slToggleBtn1.BackgroundTransparency = 0.2
slToggleBtn1.Text = ""
slToggleBtn1.AutoButtonColor = false
slToggleBtn1.Parent = slBox1

local slToggleCorner1 = Instance.new("UICorner")
slToggleCorner1.CornerRadius = UDim.new(0, 14)
slToggleCorner1.Parent = slToggleBtn1

local slToggleStroke1 = Instance.new("UIStroke")
slToggleStroke1.Color = Color3.fromRGB(180, 180, 180)
slToggleStroke1.Transparency = 0.2
slToggleStroke1.Thickness = 0.8
slToggleStroke1.Parent = slToggleBtn1

local slToggleLabel1 = Instance.new("TextLabel")
slToggleLabel1.Size = UDim2.new(1, -40, 1, 0)
slToggleLabel1.Position = UDim2.new(0, 12, 0, 0)
slToggleLabel1.BackgroundTransparency = 1
slToggleLabel1.TextXAlignment = Enum.TextXAlignment.Left
slToggleLabel1.Text = "Shuriken Lag"
slToggleLabel1.TextColor3 = Color3.fromRGB(200, 200, 200)
slToggleLabel1.TextSize = 12
slToggleLabel1.Font = Enum.Font.GothamBold
slToggleLabel1.Parent = slToggleBtn1

local slCheckboxBox1 = Instance.new("Frame")
slCheckboxBox1.Size = UDim2.new(0, 20, 0, 20)
slCheckboxBox1.AnchorPoint = Vector2.new(1, 0.5)
slCheckboxBox1.Position = UDim2.new(1, -12, 0.5, 0)
slCheckboxBox1.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
slCheckboxBox1.BackgroundTransparency = 0.2
slCheckboxBox1.BorderSizePixel = 0
slCheckboxBox1.Parent = slToggleBtn1

local slCbCorner1 = Instance.new("UICorner")
slCbCorner1.CornerRadius = UDim.new(0, 6)
slCbCorner1.Parent = slCheckboxBox1

local slCbStroke1 = Instance.new("UIStroke")
slCbStroke1.Color = Color3.fromRGB(150, 150, 150)
slCbStroke1.Transparency = 0.2
slCbStroke1.Thickness = 1
slCbStroke1.Parent = slCheckboxBox1

local slCheckmark1 = Instance.new("TextLabel")
slCheckmark1.Size = UDim2.new(1, 0, 1, 0)
slCheckmark1.BackgroundTransparency = 1
slCheckmark1.Text = "✓"
slCheckmark1.TextColor3 = Color3.fromRGB(255, 255, 255)
slCheckmark1.TextSize = 14
slCheckmark1.Font = Enum.Font.GothamBold
slCheckmark1.Visible = false
slCheckmark1.Parent = slCheckboxBox1

-- ============================================================
-- 2. LINE LAG [MONSTER] (30000 ЛИНИЙ)
-- ============================================================
local slBox2 = Instance.new("Frame")
slBox2.Size = UDim2.new(1, -gap * 2, 0, slItemHeight)
slBox2.Position = UDim2.new(0, gap, 0, slStartY + slItemHeight + gap)
slBox2.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
slBox2.BackgroundTransparency = 0.25
slBox2.ClipsDescendants = true
slBox2.Parent = serverLagBox

local slBoxCorner2 = Instance.new("UICorner")
slBoxCorner2.CornerRadius = UDim.new(0, 18)
slBoxCorner2.Parent = slBox2

local slBoxStroke2 = Instance.new("UIStroke")
slBoxStroke2.Color = Color3.fromRGB(180, 180, 180)
slBoxStroke2.Transparency = 0.2
slBoxStroke2.Thickness = 1.0
slBoxStroke2.Parent = slBox2

local slToggleBtn2 = Instance.new("TextButton")
slToggleBtn2.Size = UDim2.new(1, -24, 1, -12)
slToggleBtn2.Position = UDim2.new(0, 12, 0, 6)
slToggleBtn2.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
slToggleBtn2.BackgroundTransparency = 0.2
slToggleBtn2.Text = ""
slToggleBtn2.AutoButtonColor = false
slToggleBtn2.Parent = slBox2

local slToggleCorner2 = Instance.new("UICorner")
slToggleCorner2.CornerRadius = UDim.new(0, 14)
slToggleCorner2.Parent = slToggleBtn2

local slToggleStroke2 = Instance.new("UIStroke")
slToggleStroke2.Color = Color3.fromRGB(180, 180, 180)
slToggleStroke2.Transparency = 0.2
slToggleStroke2.Thickness = 0.8
slToggleStroke2.Parent = slToggleBtn2

local slToggleLabel2 = Instance.new("TextLabel")
slToggleLabel2.Size = UDim2.new(1, -40, 1, 0)
slToggleLabel2.Position = UDim2.new(0, 12, 0, 0)
slToggleLabel2.BackgroundTransparency = 1
slToggleLabel2.TextXAlignment = Enum.TextXAlignment.Left
slToggleLabel2.Text = "Line Lag [Monster]"
slToggleLabel2.TextColor3 = Color3.fromRGB(200, 200, 200)
slToggleLabel2.TextSize = 12
slToggleLabel2.Font = Enum.Font.GothamBold
slToggleLabel2.Parent = slToggleBtn2

local slCheckboxBox2 = Instance.new("Frame")
slCheckboxBox2.Size = UDim2.new(0, 20, 0, 20)
slCheckboxBox2.AnchorPoint = Vector2.new(1, 0.5)
slCheckboxBox2.Position = UDim2.new(1, -12, 0.5, 0)
slCheckboxBox2.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
slCheckboxBox2.BackgroundTransparency = 0.2
slCheckboxBox2.BorderSizePixel = 0
slCheckboxBox2.Parent = slToggleBtn2

local slCbCorner2 = Instance.new("UICorner")
slCbCorner2.CornerRadius = UDim.new(0, 6)
slCbCorner2.Parent = slCheckboxBox2

local slCbStroke2 = Instance.new("UIStroke")
slCbStroke2.Color = Color3.fromRGB(150, 150, 150)
slCbStroke2.Transparency = 0.2
slCbStroke2.Thickness = 1
slCbStroke2.Parent = slCheckboxBox2

local slCheckmark2 = Instance.new("TextLabel")
slCheckmark2.Size = UDim2.new(1, 0, 1, 0)
slCheckmark2.BackgroundTransparency = 1
slCheckmark2.Text = "✓"
slCheckmark2.TextColor3 = Color3.fromRGB(255, 255, 255)
slCheckmark2.TextSize = 14
slCheckmark2.Font = Enum.Font.GothamBold
slCheckmark2.Visible = false
slCheckmark2.Parent = slCheckboxBox2

-- ============================================================
-- ЛОГИКА SHURIKEN LAG (1 ДЕКОЙ + 9 ШИРИКЕНОВ)
-- ============================================================
local shurikenLagRunning = false
local shurikenLagTask = nil

local function getHRP2()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart
    end
    return nil
end

local function getInv2()
    return Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
end

local function sno2(part)
    local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
    if GE then
        local SetNetworkOwner = GE:FindFirstChild("SetNetworkOwner")
        if SetNetworkOwner then
            SetNetworkOwner:FireServer(part, part.CFrame)
        end
    end
end

local function CheckForHome2()
    local playersInPlots = Workspace:FindFirstChild("PlotItems") and Workspace.PlotItems:FindFirstChild("PlayersInPlots")
    if playersInPlots and playersInPlots:FindFirstChild(LocalPlayer.Name) then
        for _, plot in pairs(Workspace.Plots:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            local owners = sign and sign:FindFirstChild("ThisPlotsOwners")
            if owners then
                for _, owner in pairs(owners:GetChildren()) do
                    if owner.Value == LocalPlayer.Name then
                        local folder = Workspace.PlotItems:FindFirstChild(plot.Name)
                        if folder then
                            return true, folder
                        end
                    end
                end
            end
        end
    end
    return false, nil
end

local function SpawnToy2(ToyName)
    local SpawnToyRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
    local inv = getInv2()
    local InPlot = LocalPlayer:FindFirstChild("InPlot")
    local InOwnedPlot = LocalPlayer:FindFirstChild("InOwnedPlot")
    local CanSpawnToy = LocalPlayer:FindFirstChild("CanSpawnToy")
    local hrp = getHRP2()
    
    if InPlot and InPlot.Value and not (InOwnedPlot and InOwnedPlot.Value) then 
        InPlot:GetPropertyChangedSignal("Value"):Wait()
    end 
    if CanSpawnToy and not CanSpawnToy.Value then 
        local t = tick()
        while CanSpawnToy and not CanSpawnToy.Value and (tick() - t < 3) do
            task.wait(0.1)
        end
    end

    local SpawnCF = hrp and hrp.CFrame * CFrame.new(0, 14, 20) or CFrame.new(0, 10, 0)
    
    local inOwned, house = CheckForHome2()
    local Container = inOwned and house or inv
    if not Container then return nil end

    local spawnedObject = nil
    local connection
    connection = Container.ChildAdded:Connect(function(child)
        if child.Name == ToyName then
            spawnedObject = child
        end
    end)

    task.spawn(function()
        pcall(function()
            SpawnToyRemote:InvokeServer(ToyName, SpawnCF, Vector3.zero)
        end)
    end)

    local start = tick()
    repeat task.wait() until spawnedObject or (tick() - start) > 2.5
    connection:Disconnect()
    return spawnedObject
end

local function ClearLagToys2()
    local inv = getInv2()
    local DestroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
    if inv and DestroyToy then
        for _, v in pairs(inv:GetChildren()) do
            if v.Name == "LagDecoy" or v.Name == "LagShuriken" or v.Name == "NinjaShuriken" or v.Name == "YouDecoy" then
                pcall(function()
                    DestroyToy:FireServer(v)
                end)
            end
        end
    end
    local inOwned, house = CheckForHome2()
    if inOwned and house and DestroyToy then
        for _, v in pairs(house:GetChildren()) do
            if v.Name == "LagDecoy" or v.Name == "LagShuriken" or v.Name == "NinjaShuriken" or v.Name == "YouDecoy" then
                pcall(function()
                    DestroyToy:FireServer(v)
                end)
            end
        end
    end
end

local function startShurikenLag()
    if shurikenLagRunning then return end
    shurikenLagRunning = true
    slCheckmark1.Visible = true

    ClearLagToys2()
    task.wait(0.3)

    shurikenLagTask = task.spawn(function()
        local oldCF = getHRP2() and getHRP2().CFrame
        local charCF = oldCF
        
        -- 1. СОЗДАЁМ 1 ДЕКОЙ И 9 ШИРИКЕНОВ
        local decoys = {}
        local shurikens = {}
        
        local decoy = SpawnToy2("YouDecoy")
        if decoy then
            decoy.Name = "LagDecoy"
            table.insert(decoys, decoy)
        end
        task.wait(0.3)
        
        for i = 1, 9 do
            local shur = SpawnToy2("NinjaShuriken")
            if shur then
                shur.Name = "LagShuriken"
                table.insert(shurikens, shur)
            end
            task.wait(0.1)
        end

        if #decoys == 0 or #shurikens == 0 then
            shurikenLagRunning = false
            slCheckmark1.Visible = false
            return
        end

        -- 2. ЗАХВАТЫВАЕМ ВЛАДЕЛЬЦА ДЕКОЯ
        for _, decoyObj in pairs(decoys) do
            local decoyHRP = decoyObj:FindFirstChild("HumanoidRootPart")
            if decoyHRP then
                for _, part in pairs(decoyObj:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.CanQuery = false
                    end
                end
                
                repeat
                    decoyHRP.Anchored = true
                    sno2(decoyHRP)
                    task.wait(0.01)
                until decoyObj:FindFirstChild("Head") and decoyObj.Head:FindFirstChild("PartOwner") or not shurikenLagRunning
            end
        end

        -- 3. ЗАХВАТЫВАЕМ ВЛАДЕЛЬЦА ШИРИКЕНОВ И КРЕПИМ ИХ К ДЕКОЮ
        for _, shuriken in pairs(shurikens) do
            if not shurikenLagRunning then break end
            
            local StickyPart = shuriken:FindFirstChild("StickyPart")
            if StickyPart then
                for _, part in pairs(shuriken:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.CanQuery = false
                        if part.Transparency ~= 1 then
                            part.Transparency = 0
                        end
                    end
                end
                
                repeat
                    sno2(StickyPart)
                    task.wait(0.01)
                until StickyPart:FindFirstChild("PartOwner") or not shurikenLagRunning
                
                if #decoys > 0 then
                    local decoyHRP = decoys[1]:FindFirstChild("HumanoidRootPart")
                    if decoyHRP then
                        pcall(function()
                            ReplicatedStorage.PlayerEvents.StickyPartEvent:FireServer(
                                StickyPart,
                                decoyHRP,
                                CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), math.rad(90))
                            )
                        end)
                    end
                end
            end
            task.wait(0.03)
        end

        -- 4. ГЛАВНЫЙ ЦИКЛ ЛАГА
        for decoyindex, decoyObj in ipairs(decoys) do
            if not shurikenLagRunning then break end
            
            local decoyHRP = decoyObj:FindFirstChild("HumanoidRootPart")
            if decoyHRP then
                decoyHRP.Anchored = true
                
                local startindex = (decoyindex - 1) * 9 + 1
                local endindex = math.min(startindex + 8, #shurikens)
                
                for shurikenindex = startindex, endindex do
                    if not shurikenLagRunning then break end
                    
                    local shuriken = shurikens[shurikenindex]
                    if not shuriken then break end
                    
                    local StickyPart = shuriken:FindFirstChild("StickyPart")
                    if StickyPart then
                        local BodyPosition1 = Instance.new("BodyPosition")
                        BodyPosition1.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        BodyPosition1.P = 100000
                        BodyPosition1.D = 1000
                        BodyPosition1.Parent = StickyPart
                        
                        local BodyPosition2 = Instance.new("BodyPosition")
                        BodyPosition2.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        BodyPosition2.P = 100000
                        BodyPosition2.D = 1000
                        BodyPosition2.Parent = StickyPart
                        
                        StickyPart.AssemblyAngularVelocity = Vector3.new(
                            math.random(-1000, 1000) * 100,
                            math.random(-1000, 1000) * 100,
                            math.random(-1000, 1000) * 100
                        )
                        
                        task.defer(function()
                            local posOffset = 0
                            local direction = 1
                            local angle = 0
                            
                            while shurikenLagRunning and shuriken.Parent and decoyObj.Parent do
                                posOffset = posOffset + (1 * direction)
                                if posOffset > 15 then
                                    posOffset = 15
                                    direction = -1
                                elseif posOffset < -15 then
                                    posOffset = -15
                                    direction = 1
                                end
                                
                                angle = angle + 0.5
                                if angle > math.pi * 2 then angle = 0 end
                                
                                BodyPosition1.Position = Vector3.new(
                                    decoyHRP.Position.X + math.cos(angle) * 5 + math.random(-2, 2),
                                    decoyHRP.Position.Y + posOffset + math.random(-2, 2),
                                    decoyHRP.Position.Z + math.sin(angle) * 5 + math.random(-2, 2)
                                )
                                
                                BodyPosition2.Position = Vector3.new(
                                    decoyHRP.Position.X + math.cos(angle + math.pi) * 5 + math.random(-2, 2),
                                    decoyHRP.Position.Y - posOffset + math.random(-2, 2),
                                    decoyHRP.Position.Z + math.sin(angle + math.pi) * 5 + math.random(-2, 2)
                                )
                                
                                StickyPart.AssemblyAngularVelocity = Vector3.new(
                                    math.random(-9999, 9999) * 10,
                                    math.random(-9999, 9999) * 10,
                                    math.random(-9999, 9999) * 10
                                )
                                
                                sno2(StickyPart)
                                
                                RunService.RenderStepped:Wait()
                            end
                            
                            if BodyPosition1 and BodyPosition1.Parent then BodyPosition1:Destroy() end
                            if BodyPosition2 and BodyPosition2.Parent then BodyPosition2:Destroy() end
                        end)
                    end
                end
                task.wait(0.05)
            end
        end
        
        -- 5. ПОДДЕРЖИВАЕМ ЛАГ
        while shurikenLagRunning do
            for _, shuriken in pairs(shurikens) do
                if shuriken and shuriken.Parent then
                    local StickyPart = shuriken:FindFirstChild("StickyPart")
                    if StickyPart then
                        sno2(StickyPart)
                        StickyPart.AssemblyAngularVelocity = Vector3.new(
                            math.random(-9999, 9999) * 10,
                            math.random(-9999, 9999) * 10,
                            math.random(-9999, 9999) * 10
                        )
                    end
                end
            end
            RunService.RenderStepped:Wait()
        end
        
        -- 6. ОЧИСТКА
        ClearLagToys2()
        
        local hrp = getHRP2()
        if hrp and charCF then
            pcall(function()
                hrp.CFrame = charCF
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        end
        
        shurikenLagRunning = false
        slCheckmark1.Visible = false
    end)
end

local function stopShurikenLag()
    shurikenLagRunning = false
    if shurikenLagTask then
        task.cancel(shurikenLagTask)
        shurikenLagTask = nil
    end
    slCheckmark1.Visible = false
    ClearLagToys2()
end

slToggleBtn1.MouseButton1Click:Connect(function()
    if shurikenLagRunning then
        stopShurikenLag()
    else
        startShurikenLag()
    end
end)

-- ============================================================
-- ЛОГИКА LINE LAG [MONSTER] (30000 ЛИНИЙ)
-- ============================================================
local monsterLagRunning = false
local monsterLagTask = nil
local CreateGrabLine = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("CreateGrabLine")

local function startMonsterLag()
    if monsterLagRunning then return end
    if not CreateGrabLine then return end
    
    monsterLagRunning = true
    slCheckmark2.Visible = true
    
    monsterLagTask = task.spawn(function()
        local LINE_COUNT = 30000
        local spawnedLines = 0
        local totalSpawned = 0
        
        local spawnLocation = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn")

        while monsterLagRunning do
            if not CreateGrabLine then break end
            
            local batchSize = 100
            local batches = math.ceil(LINE_COUNT / batchSize)
            
            for batch = 1, batches do
                if not monsterLagRunning then break end
                
                local startIdx = (batch - 1) * batchSize + 1
                local endIdx = math.min(batch * batchSize, LINE_COUNT)
                
                for i = startIdx, endIdx do
                    if not monsterLagRunning then break end
                    
                    local randomPos = Vector3.new(
                        math.random(-999999, 999999),
                        math.random(-999999, 999999),
                        math.random(-999999, 999999)
                    )
                    
                    local randomAngle = CFrame.Angles(
                        math.rad(math.random(0, 360)),
                        math.rad(math.random(0, 360)),
                        math.rad(math.random(0, 360))
                    )
                    
                    local targetCF = CFrame.new(randomPos) * randomAngle
                    
                    pcall(function()
                        CreateGrabLine:FireServer(
                            spawnLocation or Workspace.Terrain,
                            targetCF
                        )
                    end)
                    
                    spawnedLines = spawnedLines + 1
                    totalSpawned = totalSpawned + 1
                end
                
                task.wait(0.01)
            end
            
            task.wait(0.1)
        end
        
        monsterLagRunning = false
        slCheckmark2.Visible = false
    end)
end

local function stopMonsterLag()
    monsterLagRunning = false
    if monsterLagTask then
        task.cancel(monsterLagTask)
        monsterLagTask = nil
    end
    slCheckmark2.Visible = false
end

slToggleBtn2.MouseButton1Click:Connect(function()
    if monsterLagRunning then
        stopMonsterLag()
    else
        startMonsterLag()
    end
end)

-- ============================================================
-- ВЫСОТА ГРУППЫ SERVER LAG
-- ============================================================
local slHeight = slStartY + (slItemHeight + gap) * 2 + gap
serverLagBox.Size = UDim2.new(0, 300, 0, slHeight)

-- ОБНОВЛЯЕМ CANVAS
local finalCanvas2 = miscContentArea.CanvasSize.Y.Offset
miscContentArea.CanvasSize = UDim2.new(0, 0, 0, finalCanvas2 + slHeight + gap + 20)
end

-- ============================================================================
-- VISUALS TAB
-- ============================================================================
local function setupVisualsTab(mainContentArea)
	mainContentArea.ClipsDescendants = true
	mainContentArea.CanvasSize = UDim2.new(0, 0, 0, 950)

	local gap = 10
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local player = LocalPlayer
	local Workspace = game:GetService("Workspace")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local camera = Workspace.CurrentCamera

	-- === ГРУППА 1: PALLET VISUALS ===
	local palletVisualsBox = Instance.new("Frame")
	palletVisualsBox.Size = UDim2.new(0, 300, 0, 490)
	palletVisualsBox.Position = UDim2.new(0, 20, 0, 20)
	palletVisualsBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	palletVisualsBox.BackgroundTransparency = 0.25
	palletVisualsBox.ClipsDescendants = true
	palletVisualsBox.Parent = mainContentArea

	local pvBoxCorner = Instance.new("UICorner")
	pvBoxCorner.CornerRadius = UDim.new(0, 18)
	pvBoxCorner.Parent = palletVisualsBox

	local pvBoxStroke = Instance.new("UIStroke")
	pvBoxStroke.Color = Color3.fromRGB(180, 180, 180)
	pvBoxStroke.Transparency = 0.2
	pvBoxStroke.Thickness = 1.0
	pvBoxStroke.Parent = palletVisualsBox

	-- Заголовок "Pallet Visuals"
	local pvTitle = Instance.new("TextLabel")
	pvTitle.Size = UDim2.new(1, -30, 0, 30)
	pvTitle.Position = UDim2.new(0, 15, 0, 8)
	pvTitle.BackgroundTransparency = 1
	pvTitle.TextXAlignment = Enum.TextXAlignment.Left
	pvTitle.Text = "Pallet Visuals"
	pvTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	pvTitle.TextTransparency = 0.05
	pvTitle.TextSize = 16
	pvTitle.Font = Enum.Font.GothamBold
	pvTitle.Parent = palletVisualsBox

	-- Разделительная черта
	local pvLine = Instance.new("Frame")
	pvLine.Size = UDim2.new(1, -30, 0, 1.5)
	pvLine.Position = UDim2.new(0, 15, 0, 42)
	pvLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
	pvLine.BackgroundTransparency = 0.3
	pvLine.BorderSizePixel = 0
	pvLine.Parent = palletVisualsBox

	-- === Фрейм с цветами ===
	local subMenuBox = Instance.new("Frame")
	subMenuBox.Size = UDim2.new(0, 280, 0, 210)
	subMenuBox.Position = UDim2.new(0, 10, 0, 52)
	subMenuBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	subMenuBox.BackgroundTransparency = 0.25
	subMenuBox.ClipsDescendants = true
	subMenuBox.Parent = palletVisualsBox

	local subMenuCorner = Instance.new("UICorner")
	subMenuCorner.CornerRadius = UDim.new(0, 18)
	subMenuCorner.Parent = subMenuBox

	local subMenuStroke = Instance.new("UIStroke")
	subMenuStroke.Color = Color3.fromRGB(180, 180, 180)
	subMenuStroke.Transparency = 0.2
	subMenuStroke.Thickness = 1.0
	subMenuStroke.Parent = subMenuBox

	subMenuBgIcon = Instance.new("ImageLabel")
	subMenuBgIcon.Name = "BgIcon"
	subMenuBgIcon.Size = UDim2.new(1, 0, 1, 0)
	subMenuBgIcon.Position = UDim2.new(0, 0, 0, 0)
	subMenuBgIcon.BackgroundTransparency = 1
	subMenuBgIcon.Image = "rbxassetid://126156963981838"
	subMenuBgIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	subMenuBgIcon.ImageTransparency = 0.2
	subMenuBgIcon.ScaleType = Enum.ScaleType.Stretch
	subMenuBgIcon.ZIndex = 1
	subMenuBgIcon.Parent = subMenuBox

	local subMenuImageCorner = Instance.new("UICorner")
	subMenuImageCorner.CornerRadius = UDim.new(0, 18)
	subMenuImageCorner.Parent = subMenuBgIcon

	local colorsContainer = Instance.new("Frame")
	colorsContainer.Size = UDim2.new(0, 250, 0, 180)
	colorsContainer.Position = UDim2.new(0, 15, 0, 15)
	colorsContainer.BackgroundTransparency = 1
	colorsContainer.ZIndex = 2
	colorsContainer.Parent = subMenuBox

	local function createColumnContainer(posX, posY)
		local colFrame = Instance.new("Frame")
		colFrame.Size = UDim2.new(0, 120, 0, 180)
		colFrame.Position = UDim2.new(0, posX, 0, posY)
		colFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
		colFrame.BackgroundTransparency = 0.25
		colFrame.ClipsDescendants = true
		colFrame.ZIndex = 3
		colFrame.Parent = colorsContainer

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 16)
		corner.Parent = colFrame

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(180, 180, 180)
		stroke.Transparency = 0.2
		stroke.Thickness = 1.0
		stroke.Parent = colFrame
		
		return colFrame
	end

	local col1 = createColumnContainer(0, 0)
	local col2 = createColumnContainer(130, 0)

	local function createColorButton(name, color, index)
		local isCol2 = index > 5
		local localIndex = isCol2 and (index - 5) or index
		local parentCol = isCol2 and col2 or col1
		local row = localIndex - 1
		
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.Position = UDim2.new(0, 0, 0, row * 35)
		btn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
		btn.BackgroundTransparency = 1
		btn.Text = name
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextTransparency = 0
		btn.TextSize = 14
		btn.Font = Enum.Font.GothamBold
		btn.ZIndex = 4
		btn.Parent = parentCol

		btn.MouseButton1Click:Connect(function()
			selectedColor = color
			applyColorToExisting()
		end)
	end

	createColorButton("Black", Color3.fromRGB(25, 25, 25), 1)
	createColorButton("Gray", Color3.fromRGB(128, 128, 128), 2)
	createColorButton("White", Color3.fromRGB(230, 230, 230), 3)
	createColorButton("Brown", Color3.fromRGB(139, 69, 19), 4)
	createColorButton("Red", Color3.fromRGB(220, 20, 60), 5)

	createColorButton("Blue", Color3.fromRGB(30, 144, 255), 6)
	createColorButton("Green", Color3.fromRGB(46, 139, 87), 7)
	createColorButton("Purple", Color3.fromRGB(138, 43, 226), 8)
	createColorButton("Pink", Color3.fromRGB(255, 105, 180), 9)
	createColorButton("Yellow", Color3.fromRGB(255, 215, 0), 10)

	-- === Фрейм с материалами ===
	local materialBox = Instance.new("Frame")
	materialBox.Size = UDim2.new(0, 280, 0, 210)
	materialBox.Position = UDim2.new(0, 10, 0, 52 + 210 + 10)
	materialBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	materialBox.BackgroundTransparency = 0.25
	materialBox.ClipsDescendants = true
	materialBox.Parent = palletVisualsBox

	local materialCorner = Instance.new("UICorner")
	materialCorner.CornerRadius = UDim.new(0, 18)
	materialCorner.Parent = materialBox

	local materialStroke = Instance.new("UIStroke")
	materialStroke.Color = Color3.fromRGB(180, 180, 180)
	materialStroke.Transparency = 0.2
	materialStroke.Thickness = 1.0
	materialStroke.Parent = materialBox

	local materialBgIcon = Instance.new("ImageLabel")
	materialBgIcon.Name = "BgIcon"
	materialBgIcon.Size = UDim2.new(1, 0, 1, 0)
	materialBgIcon.Position = UDim2.new(0, 0, 0, 0)
	materialBgIcon.BackgroundTransparency = 1
	materialBgIcon.Image = "rbxassetid://126156963981838"
	materialBgIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	materialBgIcon.ImageTransparency = 0.2
	materialBgIcon.ScaleType = Enum.ScaleType.Stretch
	materialBgIcon.ZIndex = 1
	materialBgIcon.Parent = materialBox

	local materialImageCorner = Instance.new("UICorner")
	materialImageCorner.CornerRadius = UDim.new(0, 18)
	materialImageCorner.Parent = materialBgIcon

	local materialsContainer = Instance.new("Frame")
	materialsContainer.Size = UDim2.new(0, 250, 0, 180)
	materialsContainer.Position = UDim2.new(0, 15, 0, 15)
	materialsContainer.BackgroundTransparency = 1
	materialsContainer.ZIndex = 2
	materialsContainer.Parent = materialBox

	local matSingleCol = Instance.new("Frame")
	matSingleCol.Size = UDim2.new(0, 120, 0, 180)
	matSingleCol.Position = UDim2.new(0.5, -60, 0, 0)
	matSingleCol.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	matSingleCol.BackgroundTransparency = 0.25
	matSingleCol.ClipsDescendants = true
	matSingleCol.ZIndex = 3
	matSingleCol.Parent = materialsContainer

	local matCorner = Instance.new("UICorner")
	matCorner.CornerRadius = UDim.new(0, 16)
	matCorner.Parent = matSingleCol

	local matStroke = Instance.new("UIStroke")
	matStroke.Color = Color3.fromRGB(180, 180, 180)
	matStroke.Transparency = 0.2
	matStroke.Thickness = 1.0
	matStroke.Parent = matSingleCol

	local materialsList = {
		{Name = "Wood", Enum = Enum.Material.Wood, IsStuds = false, Index = 1, AssetId = "rbxassetid://89596050525647"},
		{Name = "Rock", Enum = Enum.Material.Slate, IsStuds = false, Index = 2, AssetId = "rbxassetid://86372548060397"},
		{Name = "Studs", Enum = Enum.Material.Plastic, IsStuds = true, Index = 3, AssetId = "rbxassetid://138427306040063"}, 
		{Name = "Cobble", Enum = Enum.Material.Cobblestone, IsStuds = false, Index = 4, AssetId = "rbxassetid://106536099515330"}, 
		{Name = "Sand", Enum = Enum.Material.Sand, IsStuds = false, Index = 5, AssetId = "rbxassetid://88267168523040"}
	}

	for i = 1, #materialsList do
		local matData = materialsList[i]
		local row = matData.Index - 1

		local matBtn = Instance.new("TextButton")
		matBtn.Size = UDim2.new(1, 0, 0, 30)
		matBtn.Position = UDim2.new(0, 0, 0, row * 35)
		matBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
		matBtn.BackgroundTransparency = 1
		matBtn.Text = matData.Name
		matBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		matBtn.TextTransparency = 0
		matBtn.TextSize = 14
		matBtn.Font = Enum.Font.GothamBold
		matBtn.ZIndex = 4
		matBtn.Parent = matSingleCol

		matBtn.MouseButton1Click:Connect(function()
			selectedMaterial = matData.Enum
			isStudsSelected = matData.IsStuds
			materialBgIcon.Image = matData.AssetId
			materialBgIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			applyMaterialToExisting()
		end)
	end

	-- === ГРУППА 2: PALLET MISC ===
	local palletMiscBox = Instance.new("Frame")
	palletMiscBox.Size = UDim2.new(0, 280, 0, 292)
	palletMiscBox.Position = UDim2.new(0, 330, 0, 20)
	palletMiscBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	palletMiscBox.BackgroundTransparency = 0.25
	palletMiscBox.ClipsDescendants = true
	palletMiscBox.Parent = mainContentArea

	local pmBoxCorner = Instance.new("UICorner")
	pmBoxCorner.CornerRadius = UDim.new(0, 18)
	pmBoxCorner.Parent = palletMiscBox

	local pmBoxStroke = Instance.new("UIStroke")
	pmBoxStroke.Color = Color3.fromRGB(180, 180, 180)
	pmBoxStroke.Transparency = 0.2
	pmBoxStroke.Thickness = 1.0
	pmBoxStroke.Parent = palletMiscBox

	-- Заголовок "Pallet Misc"
	local pmTitle = Instance.new("TextLabel")
	pmTitle.Size = UDim2.new(1, -30, 0, 30)
	pmTitle.Position = UDim2.new(0, 15, 0, 8)
	pmTitle.BackgroundTransparency = 1
	pmTitle.TextXAlignment = Enum.TextXAlignment.Left
	pmTitle.Text = "Pallet Misc"
	pmTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	pmTitle.TextTransparency = 0.05
	pmTitle.TextSize = 16
	pmTitle.Font = Enum.Font.GothamBold
	pmTitle.Parent = palletMiscBox

	-- Разделительная черта
	local pmLine = Instance.new("Frame")
	pmLine.Size = UDim2.new(1, -30, 0, 1.5)
	pmLine.Position = UDim2.new(0, 15, 0, 42)
	pmLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
	pmLine.BackgroundTransparency = 0.3
	pmLine.BorderSizePixel = 0
	pmLine.Parent = palletMiscBox

	-- === Фрейм прозрачности ===
	local transparencyBox = Instance.new("Frame")
	transparencyBox.Size = UDim2.new(0, 250, 0, 70)
	transparencyBox.Position = UDim2.new(0, 15, 0, 52)
	transparencyBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	transparencyBox.BackgroundTransparency = 0.25
	transparencyBox.ClipsDescendants = true
	transparencyBox.Parent = palletMiscBox

	local transparencyBoxCorner = Instance.new("UICorner")
	transparencyBoxCorner.CornerRadius = UDim.new(0, 18)
	transparencyBoxCorner.Parent = transparencyBox

	local transparencyBoxStroke = Instance.new("UIStroke")
	transparencyBoxStroke.Color = Color3.fromRGB(180, 180, 180)
	transparencyBoxStroke.Transparency = 0.2
	transparencyBoxStroke.Thickness = 1.0
	transparencyBoxStroke.Parent = transparencyBox

	local transTitle = Instance.new("TextLabel")
	transTitle.Size = UDim2.new(1, 0, 0, 20)
	transTitle.Position = UDim2.new(0, 15, 0, 8)
	transTitle.BackgroundTransparency = 1
	transTitle.TextXAlignment = Enum.TextXAlignment.Left
	transTitle.Text = "Transparency: 0.00"
	transTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	transTitle.TextTransparency = 0.05
	transTitle.TextSize = 13
	transTitle.Font = Enum.Font.GothamBold
	transTitle.Parent = transparencyBox

	local sliderBar = Instance.new("Frame")
	sliderBar.Size = UDim2.new(0, 220, 0, 8)
	sliderBar.Position = UDim2.new(0, 15, 0, 34)
	sliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	sliderBar.BackgroundTransparency = 0.2
	sliderBar.BorderSizePixel = 0
	sliderBar.Parent = transparencyBox

	local sliderBarCorner = Instance.new("UICorner")
	sliderBarCorner.CornerRadius = UDim.new(1, 0)
	sliderBarCorner.Parent = sliderBar

	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new(0, 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderFill.BackgroundTransparency = 0.05
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBar

	local sliderFillCorner = Instance.new("UICorner")
	sliderFillCorner.CornerRadius = UDim.new(1, 0)
	sliderFillCorner.Parent = sliderFill

	local sliderButton = Instance.new("TextButton")
	sliderButton.Size = UDim2.new(0, 18, 0, 18)
	sliderButton.Position = UDim2.new(0, -9, 0.5, -9)
	sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderButton.BackgroundTransparency = 0
	sliderButton.Text = ""
	sliderButton.Parent = sliderBar

	local sliderButtonCorner = Instance.new("UICorner")
	sliderButtonCorner.CornerRadius = UDim.new(1, 0)
	sliderButtonCorner.Parent = sliderButton

	local sliderButtonStroke = Instance.new("UIStroke")
	sliderButtonStroke.Color = Color3.fromRGB(140, 140, 140)
	sliderButtonStroke.Thickness = 1
	sliderButtonStroke.Parent = sliderButton

	sliding = false

	local function updateSlider(input)
		local mousePos = input.Position.X
		local barAbsolutePos = sliderBar.AbsolutePosition.X
		local barAbsoluteSize = sliderBar.AbsoluteSize.X
		
		local relativeX = math.clamp(mousePos - barAbsolutePos, 0, barAbsoluteSize)
		local scale = math.clamp(relativeX / barAbsoluteSize, 0, 1)
		
		sliderButton.Position = UDim2.new(scale, -9, 0.5, -9)
		sliderFill.Size = UDim2.new(scale, 0, 1, 0)
		
		currentTransparency = math.floor(scale * 100 + 0.5) / 100
		transTitle.Text = string.format("Transparency: %.2f", currentTransparency)
		applyTransparencyToExisting()
	end

	sliderButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			updateSlider(input)
		end
	end)

	sliderBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			updateSlider(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(input)
		end
	end)

	-- === Keybind Spawn Pallet ===
	local keybindBox = Instance.new("Frame")
	keybindBox.Size = UDim2.new(0, 250, 0, 70)
	keybindBox.Position = UDim2.new(0, 15, 0, 132)
	keybindBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	keybindBox.BackgroundTransparency = 0.25
	keybindBox.ClipsDescendants = true
	keybindBox.Parent = palletMiscBox

	local keybindBoxCorner = Instance.new("UICorner")
	keybindBoxCorner.CornerRadius = UDim.new(0, 18)
	keybindBoxCorner.Parent = keybindBox

	local keybindBoxStroke = Instance.new("UIStroke")
	keybindBoxStroke.Color = Color3.fromRGB(180, 180, 180)
	keybindBoxStroke.Transparency = 0.2
	keybindBoxStroke.Thickness = 1.0
	keybindBoxStroke.Parent = keybindBox

	local keybindTitle = Instance.new("TextLabel")
	keybindTitle.Size = UDim2.new(1, 0, 0, 20)
	keybindTitle.Position = UDim2.new(0, 15, 0, 8)
	keybindTitle.BackgroundTransparency = 1
	keybindTitle.TextXAlignment = Enum.TextXAlignment.Left
	keybindTitle.Text = "Keybind Spawn Pallet"
	keybindTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	keybindTitle.TextTransparency = 0.05
	keybindTitle.TextSize = 13
	keybindTitle.Font = Enum.Font.GothamBold
	keybindTitle.Parent = keybindBox

	local keyInputBox = Instance.new("TextButton")
	keyInputBox.Size = UDim2.new(0, 220, 0, 28)
	keyInputBox.Position = UDim2.new(0, 15, 0, 34)
	keyInputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	keyInputBox.BackgroundTransparency = 0.2
	keyInputBox.Text = "B"
	keyInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyInputBox.TextTransparency = 0.05
	keyInputBox.TextSize = 14
	keyInputBox.Font = Enum.Font.GothamBold
	keyInputBox.Parent = keybindBox

	local keyInputBoxCorner = Instance.new("UICorner")
	keyInputBoxCorner.CornerRadius = UDim.new(0, 14)
	keyInputBoxCorner.Parent = keyInputBox

	local keyingStroke = Instance.new("UIStroke")
	keyingStroke.Color = Color3.fromRGB(180, 180, 180)
	keyingStroke.Transparency = 0.2
	keyingStroke.Thickness = 0.8
	keyingStroke.Parent = keyInputBox

	local listeningForKeyInput = false
	keyInputBox.MouseButton1Click:Connect(function()
		if listeningForKeyInput then return end
		listeningForKeyInput = true
		keyInputBox.Text = "..."
		local connection
		connection = UserInputService.InputBegan:Connect(function(input, gp)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				currentKey = input.KeyCode
				keyInputBox.Text = input.KeyCode.Name
				listeningForKeyInput = false
				connection:Disconnect()
			end
		end)
	end)

	-- === Trigger Pallet Move ===
	local triggerBox = Instance.new("Frame")
	triggerBox.Size = UDim2.new(0, 250, 0, 70)
	triggerBox.Position = UDim2.new(0, 15, 0, 212)
	triggerBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	triggerBox.BackgroundTransparency = 0.25
	triggerBox.ClipsDescendants = true
	triggerBox.Parent = palletMiscBox

	local triggerBoxCorner = Instance.new("UICorner")
	triggerBoxCorner.CornerRadius = UDim.new(0, 18)
	triggerBoxCorner.Parent = triggerBox

	local triggerBoxStroke = Instance.new("UIStroke")
	triggerBoxStroke.Color = Color3.fromRGB(180, 180, 180)
	triggerBoxStroke.Transparency = 0.2
	triggerBoxStroke.Thickness = 1.0
	triggerBoxStroke.Parent = triggerBox

	local triggerTitle = Instance.new("TextLabel")
	triggerTitle.Size = UDim2.new(1, 0, 0, 20)
	triggerTitle.Position = UDim2.new(0, 15, 0, 8)
	triggerTitle.BackgroundTransparency = 1
	triggerTitle.TextXAlignment = Enum.TextXAlignment.Left
	triggerTitle.Text = "Trigger Pallet Move [Beta]"
	triggerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	triggerTitle.TextTransparency = 0.05
	triggerTitle.TextSize = 13
	triggerTitle.Font = Enum.Font.GothamBold
	triggerTitle.Parent = triggerBox

	local triggerKeyBtn = Instance.new("TextButton")
	triggerKeyBtn.Size = UDim2.new(0, 220, 0, 28)
	triggerKeyBtn.Position = UDim2.new(0, 15, 0, 34)
	triggerKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	triggerKeyBtn.BackgroundTransparency = 0.2
	triggerKeyBtn.Text = "T"
	triggerKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	triggerKeyBtn.TextTransparency = 0.05
	triggerKeyBtn.TextSize = 14
	triggerKeyBtn.Font = Enum.Font.GothamBold
	triggerKeyBtn.Parent = triggerBox

	local triggerKeyCorner = Instance.new("UICorner")
	triggerKeyCorner.CornerRadius = UDim.new(0, 14)
	triggerKeyCorner.Parent = triggerKeyBtn

	local triggerKeyStroke = Instance.new("UIStroke")
	triggerKeyStroke.Color = Color3.fromRGB(180, 180, 180)
	triggerKeyStroke.Transparency = 0.2
	triggerKeyStroke.Thickness = 0.8
	triggerKeyStroke.Parent = triggerKeyBtn

	local listeningForTriggerKey = false
	triggerKeyBtn.MouseButton1Click:Connect(function()
		if listeningForTriggerKey then return end
		listeningForTriggerKey = true
		triggerKeyBtn.Text = "..."
		local connection
		connection = UserInputService.InputBegan:Connect(function(input, gp)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				triggerKey = input.KeyCode
				triggerKeyBtn.Text = input.KeyCode.Name
				listeningForTriggerKey = false
				connection:Disconnect()
			end
		end)
	end)

-- ============================================================
-- ГРУППА: PLAYER FEATURES (В ВИЗУАЛС ТАБ)
-- ============================================================
local playerVisualsBox = Instance.new("Frame")
playerVisualsBox.Size = UDim2.new(0, 300, 0, 0)
playerVisualsBox.Position = UDim2.new(0, 20, 0, 520)
playerVisualsBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
playerVisualsBox.BackgroundTransparency = 0.25
playerVisualsBox.ClipsDescendants = true
playerVisualsBox.Parent = mainContentArea

local pvBoxCorner2 = Instance.new("UICorner")
pvBoxCorner2.CornerRadius = UDim.new(0, 18)
pvBoxCorner2.Parent = playerVisualsBox

local pvBoxStroke2 = Instance.new("UIStroke")
pvBoxStroke2.Color = Color3.fromRGB(180, 180, 180)
pvBoxStroke2.Transparency = 0.2
pvBoxStroke2.Thickness = 1.0
pvBoxStroke2.Parent = playerVisualsBox

-- Заголовок "Player Features"
local pvTitle2 = Instance.new("TextLabel")
pvTitle2.Size = UDim2.new(1, -30, 0, 30)
pvTitle2.Position = UDim2.new(0, 15, 0, 8)
pvTitle2.BackgroundTransparency = 1
pvTitle2.TextXAlignment = Enum.TextXAlignment.Left
pvTitle2.Text = "Player Features"
pvTitle2.TextColor3 = Color3.fromRGB(255, 255, 255)
pvTitle2.TextTransparency = 0.05
pvTitle2.TextSize = 16
pvTitle2.Font = Enum.Font.GothamBold
pvTitle2.Parent = playerVisualsBox

-- Разделительная черта
local pvLine2 = Instance.new("Frame")
pvLine2.Size = UDim2.new(1, -30, 0, 1.5)
pvLine2.Position = UDim2.new(0, 15, 0, 42)
pvLine2.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
pvLine2.BackgroundTransparency = 0.3
pvLine2.BorderSizePixel = 0
pvLine2.Parent = playerVisualsBox

local gap = 10
local pvStartY = 52
local itemHeight = 48

-- ============================================================
-- 1. PCLD ESP
-- ============================================================
local pclDespBox = Instance.new("Frame")
pclDespBox.Size = UDim2.new(0, 270, 0, itemHeight)
pclDespBox.Position = UDim2.new(0, 15, 0, pvStartY)
pclDespBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
pclDespBox.BackgroundTransparency = 0.25
pclDespBox.ClipsDescendants = true
pclDespBox.Parent = playerVisualsBox

local pclBoxCorner = Instance.new("UICorner")
pclBoxCorner.CornerRadius = UDim.new(0, 18)
pclBoxCorner.Parent = pclDespBox

local pclBoxStroke = Instance.new("UIStroke")
pclBoxStroke.Color = Color3.fromRGB(180, 180, 180)
pclBoxStroke.Transparency = 0.2
pclBoxStroke.Thickness = 1.0
pclBoxStroke.Parent = pclDespBox

local pclToggleBtn = Instance.new("TextButton")
pclToggleBtn.Size = UDim2.new(1, -24, 1, -12)
pclToggleBtn.Position = UDim2.new(0, 12, 0, 6)
pclToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
pclToggleBtn.BackgroundTransparency = 0.2
pclToggleBtn.Text = ""
pclToggleBtn.AutoButtonColor = false
pclToggleBtn.Parent = pclDespBox

local pclToggleCorner = Instance.new("UICorner")
pclToggleCorner.CornerRadius = UDim.new(0, 14)
pclToggleCorner.Parent = pclToggleBtn

local pclToggleStroke = Instance.new("UIStroke")
pclToggleStroke.Color = Color3.fromRGB(180, 180, 180)
pclToggleStroke.Transparency = 0.2
pclToggleStroke.Thickness = 0.8
pclToggleStroke.Parent = pclToggleBtn

local pclToggleLabel = Instance.new("TextLabel")
pclToggleLabel.Size = UDim2.new(1, -40, 1, 0)
pclToggleLabel.Position = UDim2.new(0, 12, 0, 0)
pclToggleLabel.BackgroundTransparency = 1
pclToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
pclToggleLabel.Text = "PCLD ESP"
pclToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
pclToggleLabel.TextSize = 12
pclToggleLabel.Font = Enum.Font.GothamBold
pclToggleLabel.Parent = pclToggleBtn

local pclCheckboxBox = Instance.new("Frame")
pclCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
pclCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
pclCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
pclCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
pclCheckboxBox.BackgroundTransparency = 0.2
pclCheckboxBox.BorderSizePixel = 0
pclCheckboxBox.Parent = pclToggleBtn

local pclCbCorner = Instance.new("UICorner")
pclCbCorner.CornerRadius = UDim.new(0, 6)
pclCbCorner.Parent = pclCheckboxBox

local pclCbStroke = Instance.new("UIStroke")
pclCbStroke.Color = Color3.fromRGB(150, 150, 150)
pclCbStroke.Transparency = 0.2
pclCbStroke.Thickness = 1
pclCbStroke.Parent = pclCheckboxBox

local pclCheckmark = Instance.new("TextLabel")
pclCheckmark.Size = UDim2.new(1, 0, 1, 0)
pclCheckmark.BackgroundTransparency = 1
pclCheckmark.Text = "✓"
pclCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
pclCheckmark.TextSize = 14
pclCheckmark.Font = Enum.Font.GothamBold
pclCheckmark.Visible = false
pclCheckmark.Parent = pclCheckboxBox

-- PCLD ESP логика
do
    local pclEspEnabled = false
    local espBoxes = {}
    local espCache = {}
    local targetNames = {"partesp", "playercharacterlocationdetector"}

    local function IsTarget(obj)
        if not obj:IsA("BasePart") then return false end
        for _, name in ipairs(targetNames) do
            if string.lower(obj.Name) == string.lower(name) then
                return true
            end
        end
        return false
    end

    local function AddBoxESP(obj)
        if espBoxes[obj] then return end
        local box = Instance.new("BoxHandleAdornment")
        box.Adornee = obj
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Color3 = Color3.fromRGB(255, 255, 255)
        box.Transparency = 0.7
        box.Size = obj.Size
        box.Parent = player.PlayerGui
        espBoxes[obj] = box
        obj.AncestryChanged:Connect(function(_, parent)
            if not parent and espBoxes[obj] then
                espBoxes[obj]:Destroy()
                espBoxes[obj] = nil
            end
        end)
    end

    local function RemoveAllBoxes()
        for obj, box in pairs(espBoxes) do
            if box then box:Destroy() end
        end
        espBoxes = {}
    end

    local function createNickESP(plr)
        local char = plr.Character
        if not char then char = plr.CharacterAdded:Wait() end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end
        
        local old = hrp:FindFirstChild("PCLD_NickESP")
        if old then old:Destroy() end
        
        local bill = Instance.new("BillboardGui")
        bill.Name = "PCLD_NickESP"
        bill.Adornee = hrp
        bill.Size = UDim2.new(0, 180, 0, 30)
        bill.StudsOffset = Vector3.new(0, 3, 0)
        bill.AlwaysOnTop = true
        bill.Enabled = pclEspEnabled
        bill.Parent = hrp
        
        local txt = Instance.new("TextLabel")
        txt.Name = "EspText"
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.fromRGB(255, 255, 255)
        txt.TextStrokeTransparency = 0.3
        txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        txt.TextSize = 12
        txt.Font = Enum.Font.GothamBold
        txt.TextScaled = false
        txt.Parent = bill
        
        local displayName = plr.DisplayName
        local username = plr.Name
        if displayName ~= username then
            txt.Text = string.format("%s (%s)", displayName, username)
        else
            txt.Text = username
        end
        
        espCache[plr] = bill
        
        plr.CharacterAdded:Connect(function()
            task.wait(0.5)
            if pclEspEnabled then createNickESP(plr) end
        end)
    end

    local function removeNickESP(plr)
        if espCache[plr] then
            espCache[plr]:Destroy()
            espCache[plr] = nil
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        task.spawn(function() createNickESP(p) end)
    end

    Players.PlayerAdded:Connect(function(plr)
        task.spawn(function() createNickESP(plr) end)
    end)

    Players.PlayerRemoving:Connect(removeNickESP)

    Workspace.DescendantAdded:Connect(function(obj)
        if pclEspEnabled and IsTarget(obj) then AddBoxESP(obj) end
    end)

    pclToggleBtn.MouseButton1Click:Connect(function()
        pclEspEnabled = not pclEspEnabled
        pclCheckmark.Visible = pclEspEnabled
        
        if pclEspEnabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if IsTarget(obj) then AddBoxESP(obj) end
            end
            for _, bill in pairs(espCache) do
                if bill and bill.Parent then bill.Enabled = true end
            end
        else
            RemoveAllBoxes()
            for _, bill in pairs(espCache) do
                if bill and bill.Parent then bill.Enabled = false end
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not pclEspEnabled then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            local bill = espCache[plr]
            if not bill or not bill.Parent then
                task.spawn(function() createNickESP(plr) end)
                continue
            end
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if bill and hrp and hum and hum.Health > 0 then
                bill.Adornee = hrp
                bill.Enabled = true
            else
                if bill then bill.Enabled = false end
            end
        end
    end)
end

-- ============================================================
-- 2. ANTI KICK ESP
-- ============================================================
local pvY = pvStartY + itemHeight + gap

local antiKickEspBox = Instance.new("Frame")
antiKickEspBox.Size = UDim2.new(0, 270, 0, itemHeight)
antiKickEspBox.Position = UDim2.new(0, 15, 0, pvY)
antiKickEspBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
antiKickEspBox.BackgroundTransparency = 0.25
antiKickEspBox.ClipsDescendants = true
antiKickEspBox.Parent = playerVisualsBox

local akEspBoxCorner = Instance.new("UICorner")
akEspBoxCorner.CornerRadius = UDim.new(0, 18)
akEspBoxCorner.Parent = antiKickEspBox

local akEspBoxStroke = Instance.new("UIStroke")
akEspBoxStroke.Color = Color3.fromRGB(180, 180, 180)
akEspBoxStroke.Transparency = 0.2
akEspBoxStroke.Thickness = 1.0
akEspBoxStroke.Parent = antiKickEspBox

local akEspToggleBtn = Instance.new("TextButton")
akEspToggleBtn.Size = UDim2.new(1, -24, 1, -12)
akEspToggleBtn.Position = UDim2.new(0, 12, 0, 6)
akEspToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
akEspToggleBtn.BackgroundTransparency = 0.2
akEspToggleBtn.Text = ""
akEspToggleBtn.AutoButtonColor = false
akEspToggleBtn.Parent = antiKickEspBox

local akEspToggleCorner = Instance.new("UICorner")
akEspToggleCorner.CornerRadius = UDim.new(0, 14)
akEspToggleCorner.Parent = akEspToggleBtn

local akEspToggleStroke = Instance.new("UIStroke")
akEspToggleStroke.Color = Color3.fromRGB(180, 180, 180)
akEspToggleStroke.Transparency = 0.2
akEspToggleStroke.Thickness = 0.8
akEspToggleStroke.Parent = akEspToggleBtn

local akEspToggleLabel = Instance.new("TextLabel")
akEspToggleLabel.Size = UDim2.new(1, -40, 1, 0)
akEspToggleLabel.Position = UDim2.new(0, 12, 0, 0)
akEspToggleLabel.BackgroundTransparency = 1
akEspToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
akEspToggleLabel.Text = "Anti Kick ESP"
akEspToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
akEspToggleLabel.TextSize = 12
akEspToggleLabel.Font = Enum.Font.GothamBold
akEspToggleLabel.Parent = akEspToggleBtn

local akEspCheckboxBox = Instance.new("Frame")
akEspCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
akEspCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
akEspCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
akEspCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
akEspCheckboxBox.BackgroundTransparency = 0.2
akEspCheckboxBox.BorderSizePixel = 0
akEspCheckboxBox.Parent = akEspToggleBtn

local akEspCbCorner = Instance.new("UICorner")
akEspCbCorner.CornerRadius = UDim.new(0, 6)
akEspCbCorner.Parent = akEspCheckboxBox

local akEspCbStroke = Instance.new("UIStroke")
akEspCbStroke.Color = Color3.fromRGB(150, 150, 150)
akEspCbStroke.Transparency = 0.2
akEspCbStroke.Thickness = 1
akEspCbStroke.Parent = akEspCheckboxBox

local akEspCheckmark = Instance.new("TextLabel")
akEspCheckmark.Size = UDim2.new(1, 0, 1, 0)
akEspCheckmark.BackgroundTransparency = 1
akEspCheckmark.Text = "✓"
akEspCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
akEspCheckmark.TextSize = 14
akEspCheckmark.Font = Enum.Font.GothamBold
akEspCheckmark.Visible = false
akEspCheckmark.Parent = akEspCheckboxBox

-- Anti Kick ESP логика
do
    local akEspEnabled = false
    local highlights = {}
    local watchConn = nil

    local function addHighlight(toy)
        if not toy or not toy.Parent then return end
        if highlights[toy] then return end
        
        local hl = Instance.new("Highlight")
        hl.Adornee = toy
        hl.FillColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.3
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineTransparency = 0.2
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = toy
        highlights[toy] = hl
    end

    local function removeAllHighlights()
        for toy, hl in pairs(highlights) do
            if hl then hl:Destroy() end
        end
        table.clear(highlights)
    end

    local function findAllShurikens()
        local result = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "NinjaShuriken" and obj:IsA("Model") then
                table.insert(result, obj)
            end
        end
        return result
    end

    local function applyToAll()
        removeAllHighlights()
        local shurikens = findAllShurikens()
        for _, toy in ipairs(shurikens) do
            addHighlight(toy)
        end
    end

    local function enableESP()
        applyToAll()
        
        if watchConn then watchConn:Disconnect() end
        watchConn = Workspace.DescendantAdded:Connect(function(obj)
            if akEspEnabled and obj.Name == "NinjaShuriken" and obj:IsA("Model") then
                task.wait(0.05)
                addHighlight(obj)
            end
        end)
    end

    local function disableESP()
        removeAllHighlights()
        if watchConn then
            watchConn:Disconnect()
            watchConn = nil
        end
    end

    akEspToggleBtn.MouseButton1Click:Connect(function()
        akEspEnabled = not akEspEnabled
        akEspCheckmark.Visible = akEspEnabled
        if akEspEnabled then
            enableESP()
        else
            disableESP()
        end
    end)

    player.CharacterAdded:Connect(function()
        if akEspEnabled then
            task.wait(0.5)
            applyToAll()
        end
    end)
end

-- ============================================================
-- 3. SPAWN SAVE POSITION (РАБОТАЕТ КАЖДЫЙ РАЗ)
-- ============================================================
pvY = pvY + itemHeight + gap

local spawnSaveBox = Instance.new("Frame")
spawnSaveBox.Size = UDim2.new(0, 270, 0, itemHeight)
spawnSaveBox.Position = UDim2.new(0, 15, 0, pvY)
spawnSaveBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
spawnSaveBox.BackgroundTransparency = 0.25
spawnSaveBox.ClipsDescendants = true
spawnSaveBox.Parent = playerVisualsBox

local ssBoxCorner = Instance.new("UICorner")
ssBoxCorner.CornerRadius = UDim.new(0, 18)
ssBoxCorner.Parent = spawnSaveBox

local ssBoxStroke = Instance.new("UIStroke")
ssBoxStroke.Color = Color3.fromRGB(180, 180, 180)
ssBoxStroke.Transparency = 0.2
ssBoxStroke.Thickness = 1.0
ssBoxStroke.Parent = spawnSaveBox

local ssToggleBtn = Instance.new("TextButton")
ssToggleBtn.Size = UDim2.new(1, -24, 1, -12)
ssToggleBtn.Position = UDim2.new(0, 12, 0, 6)
ssToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
ssToggleBtn.BackgroundTransparency = 0.2
ssToggleBtn.Text = ""
ssToggleBtn.AutoButtonColor = false
ssToggleBtn.Parent = spawnSaveBox

local ssToggleCorner = Instance.new("UICorner")
ssToggleCorner.CornerRadius = UDim.new(0, 14)
ssToggleCorner.Parent = ssToggleBtn

local ssToggleStroke = Instance.new("UIStroke")
ssToggleStroke.Color = Color3.fromRGB(180, 180, 180)
ssToggleStroke.Transparency = 0.2
ssToggleStroke.Thickness = 0.8
ssToggleStroke.Parent = ssToggleBtn

local ssToggleLabel = Instance.new("TextLabel")
ssToggleLabel.Size = UDim2.new(1, -40, 1, 0)
ssToggleLabel.Position = UDim2.new(0, 12, 0, 0)
ssToggleLabel.BackgroundTransparency = 1
ssToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ssToggleLabel.Text = "Respawn Save Position"
ssToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ssToggleLabel.TextSize = 12
ssToggleLabel.Font = Enum.Font.GothamBold
ssToggleLabel.Parent = ssToggleBtn

local ssCheckboxBox = Instance.new("Frame")
ssCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
ssCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
ssCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
ssCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
ssCheckboxBox.BackgroundTransparency = 0.2
ssCheckboxBox.BorderSizePixel = 0
ssCheckboxBox.Parent = ssToggleBtn

local ssCbCorner = Instance.new("UICorner")
ssCbCorner.CornerRadius = UDim.new(0, 6)
ssCbCorner.Parent = ssCheckboxBox

local ssCbStroke = Instance.new("UIStroke")
ssCbStroke.Color = Color3.fromRGB(150, 150, 150)
ssCbStroke.Transparency = 0.2
ssCbStroke.Thickness = 1
ssCbStroke.Parent = ssCheckboxBox

local ssCheckmark = Instance.new("TextLabel")
ssCheckmark.Size = UDim2.new(1, 0, 1, 0)
ssCheckmark.BackgroundTransparency = 1
ssCheckmark.Text = "✓"
ssCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
ssCheckmark.TextSize = 14
ssCheckmark.Font = Enum.Font.GothamBold
ssCheckmark.Visible = false
ssCheckmark.Parent = ssCheckboxBox

-- ЛОГИКА
do
    local spawnSaveEnabled = false
    local savedPos = nil
    local deathConn = nil
    local respawnConn = nil

    local function savePosition()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            savedPos = hrp.CFrame
        end
    end

    local function teleportToSavedPosition(newChar)
        if not spawnSaveEnabled or not savedPos then return end
        
        task.wait(0.5)
        local newHrp = newChar:FindFirstChild("HumanoidRootPart")
        if newHrp and savedPos then
            newHrp.CFrame = savedPos
            newHrp.AssemblyLinearVelocity = Vector3.zero
            newHrp.AssemblyAngularVelocity = Vector3.zero
            
            task.wait(0.1)
            savePosition()
        end
    end

    local function setupTracking()
        if respawnConn then respawnConn:Disconnect() end
        
        respawnConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            if spawnSaveEnabled then
                teleportToSavedPosition(newChar)
                
                local hum = newChar:WaitForChild("Humanoid", 5)
                if hum then
                    if deathConn then deathConn:Disconnect() end
                    deathConn = hum.Died:Connect(function()
                        if spawnSaveEnabled then
                            savePosition()
                        end
                    end)
                end
            end
        end)
        
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if deathConn then deathConn:Disconnect() end
            deathConn = hum.Died:Connect(function()
                if spawnSaveEnabled then
                    savePosition()
                end
            end)
        end
    end

    ssToggleBtn.MouseButton1Click:Connect(function()
        spawnSaveEnabled = not spawnSaveEnabled
        ssCheckmark.Visible = spawnSaveEnabled
        
        if spawnSaveEnabled then
            savePosition()
            setupTracking()
        else
            if deathConn then
                deathConn:Disconnect()
                deathConn = nil
            end
            if respawnConn then
                respawnConn:Disconnect()
                respawnConn = nil
            end
            savedPos = nil
        end
    end)
end
-- ВЫСОТА ФРЕЙМА (3 айтема + 3 гапа)
local pvHeight = pvStartY + (3 * itemHeight) + (3 * gap)
playerVisualsBox.Size = UDim2.new(0, 300, 0, pvHeight)
-- ============================================================
-- ГРУППА: SHADERS (ВСЕ ЭФФЕКТЫ РАБОТАЮТ)
-- ============================================================
local shadersBox = Instance.new("Frame")
shadersBox.Size = UDim2.new(0, 280, 0, 0)
shadersBox.Position = UDim2.new(0, 330, 0, 20 + 292 + 10)
shadersBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
shadersBox.BackgroundTransparency = 0.25
shadersBox.ClipsDescendants = true
shadersBox.Parent = mainContentArea

local shBoxCorner = Instance.new("UICorner")
shBoxCorner.CornerRadius = UDim.new(0, 18)
shBoxCorner.Parent = shadersBox

local shBoxStroke = Instance.new("UIStroke")
shBoxStroke.Color = Color3.fromRGB(180, 180, 180)
shBoxStroke.Transparency = 0.2
shBoxStroke.Thickness = 1.0
shBoxStroke.Parent = shadersBox

local shTitle = Instance.new("TextLabel")
shTitle.Size = UDim2.new(1, -30, 0, 30)
shTitle.Position = UDim2.new(0, 15, 0, 8)
shTitle.BackgroundTransparency = 1
shTitle.TextXAlignment = Enum.TextXAlignment.Left
shTitle.Text = "Shaders"
shTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shTitle.TextTransparency = 0.05
shTitle.TextSize = 16
shTitle.Font = Enum.Font.GothamBold
shTitle.Parent = shadersBox

local shLine = Instance.new("Frame")
shLine.Size = UDim2.new(1, -30, 0, 1.5)
shLine.Position = UDim2.new(0, 15, 0, 42)
shLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
shLine.BackgroundTransparency = 0.3
shLine.BorderSizePixel = 0
shLine.Parent = shadersBox

local gap = 10
local shStartY = 52
local itemHeight = 48

-- ============================================================
-- ПОЛУЧАЕМ ССЫЛКУ НА LIGHTING
-- ============================================================
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local mouse = game:GetService("Players").LocalPlayer:GetMouse()

-- ============================================================
-- СОЗДАЁМ СВОИ ЭФФЕКТЫ
-- ============================================================
local DepthOfField = Instance.new("DepthOfFieldEffect")
DepthOfField.Parent = Lighting
DepthOfField.FocusDistance = 0.1
DepthOfField.FarIntensity = 0
DepthOfField.Enabled = true

local ColorCorrection = Instance.new("ColorCorrectionEffect")
ColorCorrection.Parent = Lighting
ColorCorrection.Enabled = true
ColorCorrection.Brightness = 0
ColorCorrection.Contrast = 0
ColorCorrection.Saturation = 0

local BloomEffect = Instance.new("BloomEffect")
BloomEffect.Parent = Lighting
BloomEffect.Threshold = 0.9
BloomEffect.Intensity = 0
BloomEffect.Enabled = true

-- ============================================================
-- ХРАНИЛИЩЕ ТЕКУЩИХ НАСТРОЕК
-- ============================================================
local currentSettings = {
    clockTime = 14,
    dofIntensity = 0,
    fogEnd = 10000,
    brightness = 0,
    contrast = 0,
    saturation = 0,
    bloom = 0
}

-- ============================================================
-- ФУНКЦИЯ СОЗДАНИЯ ПОЛЗУНКА
-- ============================================================
local function createSlider(parent, name, posY, minVal, maxVal, defaultVal, callback)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -gap * 2, 0, itemHeight)
    box.Position = UDim2.new(0, gap, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    box.BackgroundTransparency = 0.25
    box.ClipsDescendants = true
    box.Parent = parent

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 18)
    boxCorner.Parent = box

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(180, 180, 180)
    boxStroke.Transparency = 0.2
    boxStroke.Thickness = 1.0
    boxStroke.Parent = box

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 0, 18)
    label.Position = UDim2.new(0, 12, 0, 2)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name .. ": " .. tostring(defaultVal)
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.Parent = box

    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(0, 220, 0, 8)
    sliderBar.Position = UDim2.new(0, 15, 0, 28)
    sliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    sliderBar.BackgroundTransparency = 0.2
    sliderBar.BorderSizePixel = 0
    sliderBar.Parent = box

    local sliderBarCorner = Instance.new("UICorner")
    sliderBarCorner.CornerRadius = UDim.new(1, 0)
    sliderBarCorner.Parent = sliderBar

    local initialScale = (defaultVal - minVal) / (maxVal - minVal)
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(initialScale, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderFill.BackgroundTransparency = 0.05
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBar

    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(1, 0)
    sliderFillCorner.Parent = sliderFill

    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 18, 0, 18)
    sliderButton.Position = UDim2.new(initialScale, -9, 0.5, -9)
    sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderButton.BackgroundTransparency = 0
    sliderButton.Text = ""
    sliderButton.Parent = sliderBar

    local sliderButtonCorner = Instance.new("UICorner")
    sliderButtonCorner.CornerRadius = UDim.new(1, 0)
    sliderButtonCorner.Parent = sliderButton

    local sliderButtonStroke = Instance.new("UIStroke")
    sliderButtonStroke.Color = Color3.fromRGB(140, 140, 140)
    sliderButtonStroke.Thickness = 1
    sliderButtonStroke.Parent = sliderButton

    local dragging = false
    
    local function updateSlider(input)
        local mousePos = input.Position.X
        local barAbsolutePos = sliderBar.AbsolutePosition.X
        local barAbsoluteSize = sliderBar.AbsoluteSize.X
        
        local relativeX = math.clamp(mousePos - barAbsolutePos, 0, barAbsoluteSize)
        local scale = math.clamp(relativeX / barAbsoluteSize, 0, 1)
        
        sliderButton.Position = UDim2.new(scale, -9, 0.5, -9)
        sliderFill.Size = UDim2.new(scale, 0, 1, 0)
        
        local value = minVal + (scale * (maxVal - minVal))
        value = math.floor(value + 0.5)
        label.Text = name .. ": " .. tostring(value)
        callback(value)
    end

    sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)

    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    return box
end

-- ============================================================
-- ТОГГЛ GRAY SKY
-- ============================================================
local skyBox = Instance.new("Frame")
skyBox.Size = UDim2.new(1, -gap * 2, 0, 48)
skyBox.Position = UDim2.new(0, gap, 0, shStartY)
skyBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
skyBox.BackgroundTransparency = 0.25
skyBox.ClipsDescendants = true
skyBox.Parent = shadersBox

local skyBoxCorner = Instance.new("UICorner")
skyBoxCorner.CornerRadius = UDim.new(0, 18)
skyBoxCorner.Parent = skyBox

local skyBoxStroke = Instance.new("UIStroke")
skyBoxStroke.Color = Color3.fromRGB(180, 180, 180)
skyBoxStroke.Transparency = 0.2
skyBoxStroke.Thickness = 1.0
skyBoxStroke.Parent = skyBox

local skyToggleBtn = Instance.new("TextButton")
skyToggleBtn.Size = UDim2.new(1, -24, 1, -12)
skyToggleBtn.Position = UDim2.new(0, 12, 0, 6)
skyToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
skyToggleBtn.BackgroundTransparency = 0.2
skyToggleBtn.Text = ""
skyToggleBtn.AutoButtonColor = false
skyToggleBtn.Parent = skyBox

local skyToggleCorner = Instance.new("UICorner")
skyToggleCorner.CornerRadius = UDim.new(0, 14)
skyToggleCorner.Parent = skyToggleBtn

local skyToggleStroke = Instance.new("UIStroke")
skyToggleStroke.Color = Color3.fromRGB(180, 180, 180)
skyToggleStroke.Transparency = 0.2
skyToggleStroke.Thickness = 0.8
skyToggleStroke.Parent = skyToggleBtn

local skyToggleLabel = Instance.new("TextLabel")
skyToggleLabel.Size = UDim2.new(1, -40, 1, 0)
skyToggleLabel.Position = UDim2.new(0, 12, 0, 0)
skyToggleLabel.BackgroundTransparency = 1
skyToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
skyToggleLabel.Text = "Gray Sky"
skyToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
skyToggleLabel.TextSize = 11
skyToggleLabel.Font = Enum.Font.GothamBold
skyToggleLabel.Parent = skyToggleBtn

local skyCheckboxBox = Instance.new("Frame")
skyCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
skyCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
skyCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
skyCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
skyCheckboxBox.BackgroundTransparency = 0.2
skyCheckboxBox.BorderSizePixel = 0
skyCheckboxBox.Parent = skyToggleBtn

local skyCbCorner = Instance.new("UICorner")
skyCbCorner.CornerRadius = UDim.new(0, 6)
skyCbCorner.Parent = skyCheckboxBox

local skyCbStroke = Instance.new("UIStroke")
skyCbStroke.Color = Color3.fromRGB(150, 150, 150)
skyCbStroke.Transparency = 0.2
skyCbStroke.Thickness = 1
skyCbStroke.Parent = skyCheckboxBox

local skyCheckmark = Instance.new("TextLabel")
skyCheckmark.Size = UDim2.new(1, 0, 1, 0)
skyCheckmark.BackgroundTransparency = 1
skyCheckmark.Text = "✓"
skyCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
skyCheckmark.TextSize = 14
skyCheckmark.Font = Enum.Font.GothamBold
skyCheckmark.Visible = false
skyCheckmark.Parent = skyCheckboxBox

-- ============================================================
-- ТОГГЛ SUNSHINE
-- ============================================================
local sunshineBox = Instance.new("Frame")
sunshineBox.Size = UDim2.new(1, -gap * 2, 0, 48)
sunshineBox.Position = UDim2.new(0, gap, 0, shStartY + 48 + gap)
sunshineBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
sunshineBox.BackgroundTransparency = 0.25
sunshineBox.ClipsDescendants = true
sunshineBox.Parent = shadersBox

local sunshineBoxCorner = Instance.new("UICorner")
sunshineBoxCorner.CornerRadius = UDim.new(0, 18)
sunshineBoxCorner.Parent = sunshineBox

local sunshineBoxStroke = Instance.new("UIStroke")
sunshineBoxStroke.Color = Color3.fromRGB(180, 180, 180)
sunshineBoxStroke.Transparency = 0.2
sunshineBoxStroke.Thickness = 1.0
sunshineBoxStroke.Parent = sunshineBox

local sunshineToggleBtn = Instance.new("TextButton")
sunshineToggleBtn.Size = UDim2.new(1, -24, 1, -12)
sunshineToggleBtn.Position = UDim2.new(0, 12, 0, 6)
sunshineToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
sunshineToggleBtn.BackgroundTransparency = 0.2
sunshineToggleBtn.Text = ""
sunshineToggleBtn.AutoButtonColor = false
sunshineToggleBtn.Parent = sunshineBox

local sunshineToggleCorner = Instance.new("UICorner")
sunshineToggleCorner.CornerRadius = UDim.new(0, 14)
sunshineToggleCorner.Parent = sunshineToggleBtn

local sunshineToggleStroke = Instance.new("UIStroke")
sunshineToggleStroke.Color = Color3.fromRGB(180, 180, 180)
sunshineToggleStroke.Transparency = 0.2
sunshineToggleStroke.Thickness = 0.8
sunshineToggleStroke.Parent = sunshineToggleBtn

local sunshineToggleLabel = Instance.new("TextLabel")
sunshineToggleLabel.Size = UDim2.new(1, -40, 1, 0)
sunshineToggleLabel.Position = UDim2.new(0, 12, 0, 0)
sunshineToggleLabel.BackgroundTransparency = 1
sunshineToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
sunshineToggleLabel.Text = "Sunshine"
sunshineToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
sunshineToggleLabel.TextSize = 11
sunshineToggleLabel.Font = Enum.Font.GothamBold
sunshineToggleLabel.Parent = sunshineToggleBtn

local sunshineCheckboxBox = Instance.new("Frame")
sunshineCheckboxBox.Size = UDim2.new(0, 20, 0, 20)
sunshineCheckboxBox.AnchorPoint = Vector2.new(1, 0.5)
sunshineCheckboxBox.Position = UDim2.new(1, -12, 0.5, 0)
sunshineCheckboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
sunshineCheckboxBox.BackgroundTransparency = 0.2
sunshineCheckboxBox.BorderSizePixel = 0
sunshineCheckboxBox.Parent = sunshineToggleBtn

local sunshineCbCorner = Instance.new("UICorner")
sunshineCbCorner.CornerRadius = UDim.new(0, 6)
sunshineCbCorner.Parent = sunshineCheckboxBox

local sunshineCbStroke = Instance.new("UIStroke")
sunshineCbStroke.Color = Color3.fromRGB(150, 150, 150)
sunshineCbStroke.Transparency = 0.2
sunshineCbStroke.Thickness = 1
sunshineCbStroke.Parent = sunshineCheckboxBox

local sunshineCheckmark = Instance.new("TextLabel")
sunshineCheckmark.Size = UDim2.new(1, 0, 1, 0)
sunshineCheckmark.BackgroundTransparency = 1
sunshineCheckmark.Text = "✓"
sunshineCheckmark.TextColor3 = Color3.fromRGB(255, 255, 255)
sunshineCheckmark.TextSize = 14
sunshineCheckmark.Font = Enum.Font.GothamBold
sunshineCheckmark.Visible = false
sunshineCheckmark.Parent = sunshineCheckboxBox

-- ============================================================
-- ЛОГИКА GRAY SKY
-- ============================================================
local graySkyEnabled = false
local GRAY_TEXTURE = "rbxassetid://119829605564975"

local Terrain = workspace:FindFirstChild("Terrain")
local Clouds = Terrain and Terrain:FindFirstChild("Clouds")

-- СОХРАНЯЕМ ОРИГИНАЛЬНЫЕ НАСТРОЙКИ LIGHTING
local originalFogColor = Lighting.FogColor
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalBrightness = Lighting.Brightness
local originalFogEnd = Lighting.FogEnd
local originalFogStart = Lighting.FogStart
local originalClockTime = Lighting.ClockTime
local originalExposure = Lighting.ExposureCompensation

local originalSkyBk, originalSkyDn, originalSkyFt, originalSkyLf, originalSkyRt, originalSkyUp
local sky = Lighting:FindFirstChildOfClass("Sky")
if sky then
    originalSkyBk = sky.SkyboxBk
    originalSkyDn = sky.SkyboxDn
    originalSkyFt = sky.SkyboxFt
    originalSkyLf = sky.SkyboxLf
    originalSkyRt = sky.SkyboxRt
    originalSkyUp = sky.SkyboxUp
end

local originalSunTexture = "rbxasset://sky/sun.png"
local originalMoonTexture = "rbxasset://sky/moon.png"
local originalStarCount = 3000

if sky then
    originalSunTexture = sky.SunTextureId
    originalMoonTexture = sky.MoonTextureId
    originalStarCount = sky.StarCount
end

local originalAtmDensity, originalAtmOffset, originalAtmColor, originalAtmDecay, originalAtmGlare, originalAtmHaze, originalAtmEnabled
local atm = Lighting:FindFirstChildOfClass("Atmosphere")
if atm then
    originalAtmDensity = atm.Density
    originalAtmOffset = atm.Offset
    originalAtmColor = atm.Color
    originalAtmDecay = atm.Decay
    originalAtmGlare = atm.Glare
    originalAtmHaze = atm.Haze
    originalAtmEnabled = atm.Enabled
end

local originalCloudColor = Color3.fromRGB(255, 255, 255)
local originalCloudCover = 0.5
local originalCloudDensity = 1

if Clouds then
    pcall(function()
        originalCloudColor = Clouds.Color
        originalCloudCover = Clouds.Cover
        originalCloudDensity = Clouds.Density
    end)
end

local originalBloomSize = BloomEffect.Size
local originalBloomThreshold = BloomEffect.Threshold
local originalDOFIntensity = DepthOfField.FarIntensity
local originalDOFFocus = DepthOfField.FocusDistance

-- ============================================================
-- ФУНКЦИЯ ПРИМЕНЕНИЯ ТЕКУЩИХ НАСТРОЕК
-- ============================================================
local function applyCurrentSettings()
    Lighting.ClockTime = currentSettings.clockTime
    DepthOfField.FarIntensity = currentSettings.dofIntensity
    Lighting.FogEnd = currentSettings.fogEnd
    ColorCorrection.Brightness = currentSettings.brightness
    ColorCorrection.Contrast = currentSettings.contrast
    ColorCorrection.Saturation = currentSettings.saturation
    BloomEffect.Intensity = currentSettings.bloom
end

-- ============================================================
local function applyGrayClouds()
    if not Clouds then return end
    pcall(function()
        Clouds.Color = Color3.fromRGB(95, 95, 95)
        Clouds.Cover = 0.759
        Clouds.Density = 0.631
    end)
end

local function restoreClouds()
    if not Clouds then return end
    pcall(function()
        Clouds.Color = originalCloudColor
        Clouds.Cover = originalCloudCover
        Clouds.Density = originalCloudDensity
    end)
end

local function removeSunFromSky()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then
        sky.SunTextureId = ""
        sky.MoonTextureId = ""
        sky.StarCount = 0
    end
end

local function restoreSunInSky()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then
        sky.SunTextureId = originalSunTexture
        sky.MoonTextureId = originalMoonTexture
        sky.StarCount = originalStarCount
    end
end

-- ============================================================
-- СОЗДАНИЕ ЛУЧЕЙ ОТ СОЛНЦА (BEAM)
-- ============================================================
local rayParts = {}

local function createSunRays()
    -- УДАЛЯЕМ СТАРЫЕ ЛУЧИ
    for _, v in pairs(rayParts) do
        pcall(function() v:Destroy() end)
    end
    rayParts = {}
    
    local sunPos = Vector3.new(0, 500, 0)
    local rayCount = 16
    local radius = 80
    
    for i = 1, rayCount do
        local angle = (i / rayCount) * math.pi * 2
        local endPos = Vector3.new(
            math.cos(angle) * radius,
            0,
            math.sin(angle) * radius
        )
        
        local part = Instance.new("Part")
        part.Name = "SunRay"
        part.Size = Vector3.new(1, 1, 1)
        part.Anchored = true
        part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(255, 200, 150)
        part.Transparency = 0.8
        part.Parent = workspace
        
        local midPoint = (sunPos + endPos) / 2
        local direction = (endPos - sunPos).Unit
        local distance = (endPos - sunPos).Magnitude
        
        part.Size = Vector3.new(0.5, distance, 0.5)
        part.CFrame = CFrame.lookAt(midPoint, sunPos)
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Position = Vector3.new(0, distance/2, 0)
        attachment1.Parent = part
        
        local attachment2 = Instance.new("Attachment")
        attachment2.Position = Vector3.new(0, -distance/2, 0)
        attachment2.Parent = part
        
        local beam = Instance.new("Beam")
        beam.Attachment0 = attachment1
        beam.Attachment1 = attachment2
        beam.Color = ColorSequence.new(Color3.fromRGB(255, 200, 150))
        beam.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.95),
            NumberSequenceKeypoint.new(0.5, 0.7),
            NumberSequenceKeypoint.new(1, 0.95)
        })
        beam.FaceCamera = true
        beam.Parent = part
        
        table.insert(rayParts, part)
    end
end

local function removeSunRays()
    for _, v in pairs(rayParts) do
        pcall(function() v:Destroy() end)
    end
    rayParts = {}
end

-- ============================================================
-- SUNSHINE - С ЛУЧАМИ
-- ============================================================
local function applySunshine()
    -- ВРЕМЯ ЗАКАТА
    Lighting.ClockTime = 17
    
    -- ОРАНЖЕВЫЙ ТУМАН (FOG INTENSITY 80)
    Lighting.FogColor = Color3.fromRGB(210, 150, 90)
    Lighting.FogStart = 0
    Lighting.FogEnd = 2000 -- 80% от 2500
    
    -- ТЕПЛЫЙ ПРИГЛУШЕННЫЙ СВЕТ (БЕЗ BRIGHTNESS)
    Lighting.Ambient = Color3.fromRGB(180, 130, 90)
    Lighting.OutdoorAmbient = Color3.fromRGB(210, 170, 130)
    Lighting.Brightness = 1.0
    Lighting.ExposureCompensation = 0.1
    
    -- НАСЫЩЕННОСТЬ (БЕЗ BRIGHTNESS)
    ColorCorrection.Saturation = 0.15
    ColorCorrection.Brightness = 0
    ColorCorrection.Contrast = 0.08
    
    -- УБИРАЕМ BLOOM
    BloomEffect.Intensity = 0
    
    -- ТЕПЛАЯ АТМОСФЕРА
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then
        atm.Density = 0.35
        atm.Offset = 0.25
        atm.Color = Color3.fromRGB(210, 170, 130)
        atm.Decay = Color3.fromRGB(190, 140, 80)
        atm.Glare = 0.4
        atm.Haze = 2.5
        atm.Enabled = true
    end
    
    -- СОЗДАЕМ ЛУЧИ
    createSunRays()
end

local function restoreSunshine()
    -- УДАЛЯЕМ ЛУЧИ
    removeSunRays()
    
    Lighting.ClockTime = currentSettings.clockTime
    
    Lighting.FogColor = originalFogColor
    Lighting.Ambient = originalAmbient
    Lighting.OutdoorAmbient = originalOutdoorAmbient
    Lighting.Brightness = originalBrightness
    Lighting.FogStart = originalFogStart
    Lighting.FogEnd = originalFogEnd
    Lighting.ExposureCompensation = originalExposure
    
    ColorCorrection.Brightness = currentSettings.brightness
    ColorCorrection.Contrast = currentSettings.contrast
    ColorCorrection.Saturation = currentSettings.saturation
    
    BloomEffect.Intensity = currentSettings.bloom
    BloomEffect.Size = originalBloomSize
    BloomEffect.Threshold = originalBloomThreshold
    
    DepthOfField.FarIntensity = currentSettings.dofIntensity
    DepthOfField.FocusDistance = originalDOFFocus
    
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then
        atm.Density = originalAtmDensity
        atm.Offset = originalAtmOffset
        atm.Color = originalAtmColor
        atm.Decay = originalAtmDecay
        atm.Glare = originalAtmGlare
        atm.Haze = originalAtmHaze
        atm.Enabled = originalAtmEnabled
    end
end

-- ============================================================
local function applyGraySky()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
    end
    
    sky.SkyboxBk = GRAY_TEXTURE
    sky.SkyboxDn = GRAY_TEXTURE
    sky.SkyboxFt = GRAY_TEXTURE
    sky.SkyboxLf = GRAY_TEXTURE
    sky.SkyboxRt = GRAY_TEXTURE
    sky.SkyboxUp = GRAY_TEXTURE
    
    removeSunFromSky()
    applyGrayClouds()
    
    Lighting.FogColor = Color3.fromRGB(180, 180, 180)
    Lighting.Ambient = Color3.fromRGB(180, 180, 180)
    Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
    Lighting.Brightness = 1.2
    Lighting.FogStart = 0
    Lighting.ExposureCompensation = 0
    
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then
        atm.Density = 0.4
        atm.Offset = 0.1
        atm.Color = Color3.fromRGB(180, 190, 255)
        atm.Decay = Color3.fromRGB(120, 130, 180)
        atm.Glare = 0.15
        atm.Haze = 3
        atm.Enabled = true
    end
    
    applyCurrentSettings()
end

local function restoreSky()
    Lighting.FogColor = originalFogColor
    Lighting.Ambient = originalAmbient
    Lighting.OutdoorAmbient = originalOutdoorAmbient
    Lighting.Brightness = originalBrightness
    Lighting.FogStart = originalFogStart
    Lighting.ExposureCompensation = originalExposure
    
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then
        sky.SkyboxBk = originalSkyBk
        sky.SkyboxDn = originalSkyDn
        sky.SkyboxFt = originalSkyFt
        sky.SkyboxLf = originalSkyLf
        sky.SkyboxRt = originalSkyRt
        sky.SkyboxUp = originalSkyUp
    end
    
    restoreSunInSky()
    
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then
        atm.Density = originalAtmDensity
        atm.Offset = originalAtmOffset
        atm.Color = originalAtmColor
        atm.Decay = originalAtmDecay
        atm.Glare = originalAtmGlare
        atm.Haze = originalAtmHaze
        atm.Enabled = originalAtmEnabled
    end
    
    restoreClouds()
    applyCurrentSettings()
end

-- ============================================================
-- ТОГГЛЫ
-- ============================================================
local sunshineEnabled = false

skyToggleBtn.MouseButton1Click:Connect(function()
    graySkyEnabled = not graySkyEnabled
    skyCheckmark.Visible = graySkyEnabled
    
    if graySkyEnabled then
        applyGraySky()
    else
        restoreSky()
    end
end)

sunshineToggleBtn.MouseButton1Click:Connect(function()
    sunshineEnabled = not sunshineEnabled
    sunshineCheckmark.Visible = sunshineEnabled
    
    if sunshineEnabled then
        applySunshine()
    else
        restoreSunshine()
    end
end)

-- ============================================================
-- ПОЛЗУНКИ
-- ============================================================
local shCurrentY = shStartY + 48 + gap + 48 + gap

createSlider(shadersBox, "Time", shCurrentY, 0, 24, 14, function(v)
    currentSettings.clockTime = v
    Lighting.ClockTime = v
end)
shCurrentY = shCurrentY + itemHeight + gap

createSlider(shadersBox, "Depth of Field", shCurrentY, 0, 100, 0, function(v)
    currentSettings.dofIntensity = v * 0.01
    DepthOfField.FarIntensity = v * 0.01
end)
shCurrentY = shCurrentY + itemHeight + gap

createSlider(shadersBox, "Fog Intensity", shCurrentY, 0, 100, 0, function(v)
    currentSettings.fogEnd = 10000 - v * 100
    Lighting.FogEnd = 10000 - v * 100
end)
shCurrentY = shCurrentY + itemHeight + gap

createSlider(shadersBox, "Brightness", shCurrentY, -100, 100, 0, function(v)
    currentSettings.brightness = v * 0.01
    ColorCorrection.Brightness = v * 0.01
end)
shCurrentY = shCurrentY + itemHeight + gap

createSlider(shadersBox, "Contrast", shCurrentY, -100, 100, 0, function(v)
    currentSettings.contrast = v * 0.01
    ColorCorrection.Contrast = v * 0.01
end)
shCurrentY = shCurrentY + itemHeight + gap

createSlider(shadersBox, "Saturation", shCurrentY, -100, 100, 0, function(v)
    currentSettings.saturation = v * 0.01
    ColorCorrection.Saturation = v * 0.01
end)
shCurrentY = shCurrentY + itemHeight + gap

createSlider(shadersBox, "Bloom Intensity", shCurrentY, 0, 100, 0, function(v)
    currentSettings.bloom = v * 0.05
    BloomEffect.Intensity = v * 0.05
end)
shCurrentY = shCurrentY + itemHeight + gap

-- ============================================================
-- ВЫСОТА
-- ============================================================
local shHeight = shCurrentY + gap
shadersBox.Size = UDim2.new(0, 280, 0, shHeight)

local currentCanvas = mainContentArea.CanvasSize.Y.Offset
mainContentArea.CanvasSize = UDim2.new(0, 0, 0, currentCanvas + shHeight + gap + 20)
end

-- ============================================================================
-- GRABS TAB (ПОЛНАЯ РАБОЧАЯ ВЕРСИЯ - БЕЗ ПОИСКА КОНТЕЙНЕРА)
-- ============================================================================
local function setupGrabsTab(grabContentArea)
    grabContentArea.ClipsDescendants = true
    grabContentArea.CanvasSize = UDim2.new(0, 0, 0, 1200)

    local gap = 10
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local player = LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Debris = game:GetService("Debris")
    local camera = Workspace.CurrentCamera

    -- ============================================================
    -- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
    -- ============================================================
    local function GetMagnitude(Part1, Part2)
        return (Part1.Position - Part2.Position).Magnitude
    end
    
    local function FWD(parent, part, time)
        return parent:FindFirstChild(part) or parent:WaitForChild(part, time or 5)
    end
    
    local function CFP(parent, part)
        return parent:FindFirstChild(part) ~= nil
    end
    
    local function CheckNetworkOwnerOnPart(Part)
        return CFP(Part, "PartOwner") and Part["PartOwner"].Value == player.Name
    end
    
    local function getMyRoot()
        local c = LocalPlayer.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end

    local function setNetOwner(part)
        pcall(function()
            ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(part, part.CFrame)
        end)
    end

    local function getAuraTargets(rootPos, radius)
        radius = radius or 20
        local targets = {}
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - rootPos).Magnitude <= radius then
                    table.insert(targets, hrp)
                end
            end
        end
        return targets
    end

    local SetNetworkOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
    local DestroyGrabLine = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("DestroyGrabLine")
    local CreateGrabLine = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("CreateGrabLine")
    local SpawnToyRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
    local DestroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")

    -- ============================================================
    -- ГРУППА: MAIN GRABS (СЛЕВА)
    -- ============================================================
    local mainGrabsBox = Instance.new("Frame")
    mainGrabsBox.Size = UDim2.new(0, 300, 0, 0)
    mainGrabsBox.Position = UDim2.new(0, 20, 0, 20)
    mainGrabsBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    mainGrabsBox.BackgroundTransparency = 0.25
    mainGrabsBox.ClipsDescendants = true
    mainGrabsBox.Parent = grabContentArea

    local mgBoxCorner = Instance.new("UICorner")
    mgBoxCorner.CornerRadius = UDim.new(0, 18)
    mgBoxCorner.Parent = mainGrabsBox

    local mgBoxStroke = Instance.new("UIStroke")
    mgBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    mgBoxStroke.Transparency = 0.2
    mgBoxStroke.Thickness = 1.0
    mgBoxStroke.Parent = mainGrabsBox

    local mgTitle = Instance.new("TextLabel")
    mgTitle.Size = UDim2.new(1, -30, 0, 30)
    mgTitle.Position = UDim2.new(0, 15, 0, 8)
    mgTitle.BackgroundTransparency = 1
    mgTitle.TextXAlignment = Enum.TextXAlignment.Left
    mgTitle.Text = "Main Grabs"
    mgTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    mgTitle.TextTransparency = 0.05
    mgTitle.TextSize = 16
    mgTitle.Font = Enum.Font.GothamBold
    mgTitle.Parent = mainGrabsBox

    local mgLine = Instance.new("Frame")
    mgLine.Size = UDim2.new(1, -30, 0, 1.5)
    mgLine.Position = UDim2.new(0, 15, 0, 42)
    mgLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    mgLine.BackgroundTransparency = 0.3
    mgLine.BorderSizePixel = 0
    mgLine.Parent = mainGrabsBox

    local mgStartY = 52
    local itemHeight = 80

    local function createGrabItem(parent, title, posY, hasSlider, sliderDefault, sliderMin, sliderMax, sliderFlag)
        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, -gap * 2, 0, itemHeight)
        box.Position = UDim2.new(0, gap, 0, posY)
        box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        box.BackgroundTransparency = 0.25
        box.ClipsDescendants = true
        box.Parent = parent

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 18)
        boxCorner.Parent = box

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Color3.fromRGB(180, 180, 180)
        boxStroke.Transparency = 0.2
        boxStroke.Thickness = 1.0
        boxStroke.Parent = box

        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Size = UDim2.new(1, -40, 0, 20)
        toggleLabel.Position = UDim2.new(0, 12, 0, 4)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Text = title
        toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleLabel.TextTransparency = 0.05
        toggleLabel.TextSize = 13
        toggleLabel.Font = Enum.Font.GothamBold
        toggleLabel.Parent = box

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(1, -24, 0, 28)
        toggleBtn.Position = UDim2.new(0, 12, 0, 26)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        toggleBtn.BackgroundTransparency = 0.2
        toggleBtn.Text = ""
        toggleBtn.AutoButtonColor = false
        toggleBtn.Parent = box

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 14)
        toggleCorner.Parent = toggleBtn

        local toggleStroke = Instance.new("UIStroke")
        toggleStroke.Color = Color3.fromRGB(180, 180, 180)
        toggleStroke.Transparency = 0.2
        toggleStroke.Thickness = 0.8
        toggleStroke.Parent = toggleBtn

        local toggleText = Instance.new("TextLabel")
        toggleText.Size = UDim2.new(1, -40, 1, 0)
        toggleText.Position = UDim2.new(0, 12, 0, 0)
        toggleText.BackgroundTransparency = 1
        toggleText.TextXAlignment = Enum.TextXAlignment.Left
        toggleText.Text = "Enable"
        toggleText.TextColor3 = Color3.fromRGB(200, 200, 200)
        toggleText.TextSize = 12
        toggleText.Font = Enum.Font.Gotham
        toggleText.Parent = toggleBtn

        local checkboxBox = Instance.new("Frame")
        checkboxBox.Size = UDim2.new(0, 20, 0, 20)
        checkboxBox.AnchorPoint = Vector2.new(1, 0.5)
        checkboxBox.Position = UDim2.new(1, -12, 0.5, 0)
        checkboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        checkboxBox.BackgroundTransparency = 0.2
        checkboxBox.BorderSizePixel = 0
        checkboxBox.Parent = toggleBtn

        local cbCorner = Instance.new("UICorner")
        cbCorner.CornerRadius = UDim.new(0, 6)
        cbCorner.Parent = checkboxBox

        local cbStroke = Instance.new("UIStroke")
        cbStroke.Color = Color3.fromRGB(150, 150, 150)
        cbStroke.Transparency = 0.2
        cbStroke.Thickness = 1
        cbStroke.Parent = checkboxBox

        local checkmark = Instance.new("TextLabel")
        checkmark.Size = UDim2.new(1, 0, 1, 0)
        checkmark.BackgroundTransparency = 1
        checkmark.Text = "✓"
        checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
        checkmark.TextSize = 14
        checkmark.Font = Enum.Font.GothamBold
        checkmark.Visible = false
        checkmark.Parent = checkboxBox

        local itemData = {
            box = box,
            toggleBtn = toggleBtn,
            checkmark = checkmark,
            slider = nil
        }

        if hasSlider then
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(1, -24, 0, 20)
            sliderFrame.Position = UDim2.new(0, 12, 0, 55)
            sliderFrame.BackgroundTransparency = 1
            sliderFrame.Parent = box

            local sliderLabel = Instance.new("TextLabel")
            sliderLabel.Size = UDim2.new(0.35, 0, 1, 0)
            sliderLabel.Position = UDim2.new(0, 0, 0, 0)
            sliderLabel.BackgroundTransparency = 1
            sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            sliderLabel.Text = sliderFlag .. ": " .. tostring(sliderDefault)
            sliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            sliderLabel.TextSize = 11
            sliderLabel.Font = Enum.Font.Gotham
            sliderLabel.Parent = sliderFrame

            local sliderBar = Instance.new("Frame")
            sliderBar.Size = UDim2.new(0.6, 0, 0.6, 0)
            sliderBar.Position = UDim2.new(0.35, 5, 0.5, -4)
            sliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            sliderBar.BackgroundTransparency = 0.2
            sliderBar.BorderSizePixel = 0
            sliderBar.Parent = sliderFrame

            local sliderBarCorner = Instance.new("UICorner")
            sliderBarCorner.CornerRadius = UDim.new(1, 0)
            sliderBarCorner.Parent = sliderBar

            local sliderFill = Instance.new("Frame")
            sliderFill.Size = UDim2.new(0, 0, 1, 0)
            sliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            sliderFill.BackgroundTransparency = 0.05
            sliderFill.BorderSizePixel = 0
            sliderFill.Parent = sliderBar

            local sliderFillCorner = Instance.new("UICorner")
            sliderFillCorner.CornerRadius = UDim.new(1, 0)
            sliderFillCorner.Parent = sliderFill

            local sliderButton = Instance.new("TextButton")
            sliderButton.Size = UDim2.new(0, 16, 0, 16)
            sliderButton.Position = UDim2.new(0, -8, 0.5, -8)
            sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            sliderButton.BackgroundTransparency = 0
            sliderButton.Text = ""
            sliderButton.Parent = sliderBar

            local sliderButtonCorner = Instance.new("UICorner")
            sliderButtonCorner.CornerRadius = UDim.new(1, 0)
            sliderButtonCorner.Parent = sliderButton

            local sliderButtonStroke = Instance.new("UIStroke")
            sliderButtonStroke.Color = Color3.fromRGB(140, 140, 140)
            sliderButtonStroke.Thickness = 1
            sliderButtonStroke.Parent = sliderButton

            itemData.slider = {
                bar = sliderBar,
                fill = sliderFill,
                button = sliderButton,
                label = sliderLabel,
                currentValue = sliderDefault,
                min = sliderMin,
                max = sliderMax,
                flag = sliderFlag
            }

            local sliding = false
            local function updateSlider(input)
                local mousePos = input.Position.X
                local barAbsolutePos = sliderBar.AbsolutePosition.X
                local barAbsoluteSize = sliderBar.AbsoluteSize.X
                
                local relativeX = math.clamp(mousePos - barAbsolutePos, 0, barAbsoluteSize)
                local scale = math.clamp(relativeX / barAbsoluteSize, 0, 1)
                
                sliderButton.Position = UDim2.new(scale, -8, 0.5, -8)
                sliderFill.Size = UDim2.new(scale, 0, 1, 0)
                
                local value = math.floor(sliderMin + (scale * (sliderMax - sliderMin)) + 0.5)
                itemData.slider.currentValue = value
                sliderLabel.Text = sliderFlag .. ": " .. tostring(value)
            end

            sliderButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    updateSlider(input)
                end
            end)

            sliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    updateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
        end

        return itemData
    end

    -- ============================================================
    -- ЭЛЕМЕНТЫ MAIN GRABS
    -- ============================================================
    local superStrengthItem = createGrabItem(mainGrabsBox, "Super Strength", mgStartY, true, 600, 0, 10000, "Strength")
    local infLineItem = createGrabItem(mainGrabsBox, "Infinity Line Extend", mgStartY + itemHeight + gap, true, 7, 1, 10, "Extend Speed")
    local massLessItem = createGrabItem(mainGrabsBox, "MassLess Grab", mgStartY + 2*(itemHeight + gap), true, 30, 0, 200, "Strength")
    local kickGrabItem = createGrabItem(mainGrabsBox, "Kick Grab", mgStartY + 3*(itemHeight + gap), false)
    local spinGrabItem = createGrabItem(mainGrabsBox, "Spin Grab", mgStartY + 4*(itemHeight + gap), false)
    local ragdollGrabItem = createGrabItem(mainGrabsBox, "Ragdoll Grab", mgStartY + 5*(itemHeight + gap), false)
    local deathGrabItem = createGrabItem(mainGrabsBox, "Death Grab", mgStartY + 6*(itemHeight + gap), false)
    local crazyGrabItem = createGrabItem(mainGrabsBox, "Crazy Grab", mgStartY + 7*(itemHeight + gap), false)

    local mgHeight = mgStartY + 7.9 * (itemHeight + gap) + gap
    mainGrabsBox.Size = UDim2.new(0, 300, 0, mgHeight)

    -- ============================================================
    -- ЛОГИКА MAIN GRABS (ВСЁ РАБОТАЕТ!)
    -- ============================================================
    
    -- SUPER STRENGTH
    local superStrengthToggle = false
    local ssCons = {}
    superStrengthItem.toggleBtn.MouseButton1Click:Connect(function()
        superStrengthToggle = not superStrengthToggle
        superStrengthItem.checkmark.Visible = superStrengthToggle
        for _, v in pairs(ssCons) do if v then v:Disconnect() end end
        ssCons = {}
        
        if superStrengthToggle then
            local obj = nil
            local strengthValue = 600
            local function updateStrength()
                if superStrengthItem.slider then strengthValue = superStrengthItem.slider.currentValue end
            end
            ssCons["SuperGrab"] = Workspace.ChildAdded:Connect(function(c)
                if c.Name == "GrabParts" then
                    local part = c:FindFirstChild("GrabPart") or c:WaitForChild("GrabPart", 1)
                    if part then
                        local weld = part:FindFirstChild("WeldConstraint") or part:WaitForChild("WeldConstraint", 1)
                        if weld then obj = weld.Part1 end
                    end
                end
            end)
            ssCons["WaitUIS"] = UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton2 then
                    if obj then
                        updateStrength()
                        local bv = Instance.new("BodyVelocity", obj)
                        local Camera = Workspace.CurrentCamera
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Velocity = Camera.CFrame.LookVector * strengthValue
                        Debris:AddItem(bv, 4)
                        obj = nil
                    end
                end
            end)
            ssCons["DeleteObj"] = Workspace.ChildRemoved:Connect(function(desc)
                if desc.Name == "GrabParts" then task.delay(1, function() obj = nil end) end
            end)
        end
    end)

    -- INFINITY LINE EXTEND
    local infLineToggle = false
    local ilCons = {}
    local lineDistanceV = 0
    local increaseLineExtendV = 7
    infLineItem.toggleBtn.MouseButton1Click:Connect(function()
        infLineToggle = not infLineToggle
        infLineItem.checkmark.Visible = infLineToggle
        for _, v in pairs(ilCons) do if v then v:Disconnect() end end
        ilCons = {}
        
        if infLineToggle then
            ilCons["INFLINEHELPER"] = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseWheel then
                    if infLineItem.slider then increaseLineExtendV = infLineItem.slider.currentValue end
                    if lineDistanceV <= 3 then lineDistanceV = 3 end
                    if input.Position.Z > 0 then lineDistanceV = lineDistanceV + increaseLineExtendV
                    elseif input.Position.Z < 0 then lineDistanceV = lineDistanceV - increaseLineExtendV end
                end
            end)
            ilCons["INFLINE"] = Workspace.ChildAdded:Connect(function(child)
                if child.Name == "GrabParts" and child:IsA("Model") then
                    if UserInputService.MouseEnabled then
                        local grabPartsModel = child
                        grabPartsModel:WaitForChild("GrabPart")
                        grabPartsModel:WaitForChild("DragPart")
                        local clonedDragPart = grabPartsModel.DragPart:Clone()
                        clonedDragPart.Name = "DragPart1"
                        clonedDragPart.AlignPosition.Attachment1 = clonedDragPart.DragAttach
                        clonedDragPart.Parent = grabPartsModel
                        lineDistanceV = GetMagnitude(clonedDragPart, Workspace.CurrentCamera.CFrame)
                        clonedDragPart.AlignOrientation.Enabled = false
                        grabPartsModel.DragPart.AlignPosition.Enabled = false
                        task.spawn(function()
                            while grabPartsModel.Parent do
                                clonedDragPart.Position = Workspace.CurrentCamera.CFrame.Position + Workspace.CurrentCamera.CFrame.LookVector * lineDistanceV
                                task.wait()
                            end
                            lineDistanceV = 0
                        end)
                    end
                end
            end)
        end
    end)

-- MASSLESS GRAB (ИСПРАВЛЕННАЯ)
local massLessToggle = false
local massLessConn = nil
massLessItem.toggleBtn.MouseButton1Click:Connect(function()
    massLessToggle = not massLessToggle
    massLessItem.checkmark.Visible = massLessToggle
    
    -- ОТКЛЮЧАЕМ СТАРЫЙ КОННЕКТ
    if massLessConn then
        massLessConn:Disconnect()
        massLessConn = nil
    end
    
    if massLessToggle then
        -- ФУНКЦИЯ ПРИМЕНЕНИЯ MASSLESS
        local function applyMassLess(child)
            if child.Name ~= "GrabParts" then return end
            task.spawn(function()
                local sense = massLessItem.slider and massLessItem.slider.currentValue or 30
                local dragPart = child:FindFirstChild("DragPart")
                local dragPart1 = child:FindFirstChild("DragPart1")
                
                while massLessToggle and child and child.Parent do
                    if dragPart1 then
                        local ap1 = dragPart1:FindFirstChild("AlignPosition")
                        if ap1 then
                            ap1.Responsiveness = sense
                            ap1.MaxForce = math.huge
                            ap1.MaxVelocity = math.huge
                        end
                    end
                    
                    if dragPart then
                        local ap = dragPart:FindFirstChild("AlignPosition")
                        local ao = dragPart:FindFirstChild("AlignOrientation")
                        if ap then
                            ap.Responsiveness = sense
                            ap.MaxForce = math.huge
                            ap.MaxVelocity = math.huge
                        end
                        if ao then
                            ao.Responsiveness = sense
                            ao.MaxTorque = math.huge
                        end
                    end
                    task.wait()
                end
            end)
        end
        
        -- ПРОВЕРЯЕМ УЖЕ СУЩЕСТВУЮЩИЕ GrabParts
        local existing = Workspace:FindFirstChild("GrabParts")
        if existing then
            applyMassLess(existing)
        end
        
        -- СЛЕДИМ ЗА НОВЫМИ
        massLessConn = Workspace.ChildAdded:Connect(applyMassLess)
    end
end)

    -- KICK GRAB
    local kickGrabToggle = false
    local kgCons = {}
    kickGrabItem.toggleBtn.MouseButton1Click:Connect(function()
        kickGrabToggle = not kickGrabToggle
        kickGrabItem.checkmark.Visible = kickGrabToggle
        for _, v in pairs(kgCons) do if v then v:Disconnect() end end
        kgCons = {}
        
        if kickGrabToggle then
            kgCons["KickGrab"] = Workspace.ChildAdded:Connect(function(c)
                if c.Name ~= "GrabParts" then return end
                local GrabPart = c:WaitForChild("GrabPart", 0.1)
                task.wait(0.1)
                local part = GrabPart.WeldConstraint.Part1
                if Players:FindFirstChild(part.Parent.Name) then
                    while GrabPart and GrabPart.Parent do
                        if DestroyGrabLine then DestroyGrabLine:FireServer(part) end
                        RunService.RenderStepped:Wait()
                        if SetNetworkOwner then SetNetworkOwner:FireServer(part, part.CFrame) end
                        if DestroyGrabLine then DestroyGrabLine:FireServer(part) end
                        RunService.RenderStepped:Wait()
                        if SetNetworkOwner then SetNetworkOwner:FireServer(part, part.CFrame) end
                    end
                end
            end)
        end
    end)

    -- SPIN GRAB
    local spinGrabToggle = false
    spinGrabItem.toggleBtn.MouseButton1Click:Connect(function()
        spinGrabToggle = not spinGrabToggle
        spinGrabItem.checkmark.Visible = spinGrabToggle
    end)
    Workspace.ChildAdded:Connect(function(child)
        if child.Name == "GrabParts" and spinGrabToggle then
            local Part1 = child.GrabPart.WeldConstraint.Part1
            local Parent = Part1.Parent
            local PrimaryPart = Parent.PrimaryPart or Parent:FindFirstChild("HumanoidRootPart")
            if PrimaryPart then
                local b = Instance.new("BodyAngularVelocity", PrimaryPart)
                b.AngularVelocity = Vector3.new(0, 10, 0)
                b.MaxTorque = Vector3.new(0, math.huge, 0)
            end
        end
    end)

    -- RAGDOLL GRAB
    local ragdollGrabToggle = false
    local rgCons = {}
    ragdollGrabItem.toggleBtn.MouseButton1Click:Connect(function()
        ragdollGrabToggle = not ragdollGrabToggle
        ragdollGrabItem.checkmark.Visible = ragdollGrabToggle
        for _, v in pairs(rgCons) do if v then v:Disconnect() end end
        rgCons = {}
        
        if ragdollGrabToggle then
            local palete = Workspace:FindFirstChild(player.Name .. "SpawnedInToys"):FindFirstChild("RagdollPalete")
            if not palete then
                if SpawnToyRemote then
                    pcall(function()
                        SpawnToyRemote:InvokeServer("PalletLightBrown", player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0), Vector3.zero)
                    end)
                end
                task.wait(0.5)
                palete = Workspace:FindFirstChild(player.Name .. "SpawnedInToys"):FindFirstChild("PalletLightBrown")
                if not palete then return end
                local soundPart = FWD(palete, "SoundPart")
                if soundPart then
                    while not CheckNetworkOwnerOnPart(soundPart) and task.wait(0.05) do
                        if SetNetworkOwner then SetNetworkOwner:FireServer(soundPart, soundPart.CFrame) end
                    end
                    for _, v in pairs(palete:GetChildren()) do
                        if v:IsA("BasePart") then
                            v.Transparency = 0.8
                            v.CanCollide = false
                            v.CanQuery = false
                        end
                    end
                    palete.Name = "RagdollPalete"
                    local bv = Instance.new("BodyVelocity")
                    bv.MaxForce = Vector3.new(0, math.huge, 0)
                    bv.Velocity = Vector3.new(0, 900, 0)
                    bv.Parent = soundPart
                end
            end
        end
    end)
    Workspace.ChildAdded:Connect(function(child)
        if child.Name == "GrabParts" and ragdollGrabToggle then
            local Part1 = child.GrabPart.WeldConstraint.Part1
            local Parent = Part1.Parent
            local Root = Parent:FindFirstChild("HumanoidRootPart")
            if Root then
                task.spawn(function()
                    local palete = Workspace:FindFirstChild(player.Name .. "SpawnedInToys"):FindFirstChild("RagdollPalete")
                    if not palete then
                        if SpawnToyRemote then
                            pcall(function()
                                SpawnToyRemote:InvokeServer("PalletLightBrown", player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0), Vector3.zero)
                            end)
                        end
                        task.wait(0.5)
                        palete = Workspace:FindFirstChild(player.Name .. "SpawnedInToys"):FindFirstChild("PalletLightBrown")
                        if not palete then return end
                        local soundPart = FWD(palete, "SoundPart")
                        if soundPart then
                            while not CheckNetworkOwnerOnPart(soundPart) and task.wait(0.05) do
                                if SetNetworkOwner then SetNetworkOwner:FireServer(soundPart, soundPart.CFrame) end
                            end
                            for _, v in pairs(palete:GetChildren()) do
                                if v:IsA("BasePart") then
                                    v.Transparency = 0.8
                                    v.CanCollide = false
                                    v.CanQuery = false
                                end
                            end
                            palete.Name = "RagdollPalete"
                            local bv = Instance.new("BodyVelocity")
                            bv.MaxForce = Vector3.new(0, math.huge, 0)
                            bv.Velocity = Vector3.new(0, 900, 0)
                            bv.Parent = soundPart
                        end
                    end
                    while true do
                        local Ragdolled = CFP(Parent, "Humanoid") and Parent.Humanoid:FindFirstChild("Ragdolled")
                        if not Root or not Ragdolled or not CFP(Workspace, "GrabParts") or Ragdolled.Value then break end
                        local soundPart = palete:FindFirstChild("SoundPart")
                        if soundPart then soundPart.Position = Root.Position end
                        task.wait(0.1)
                    end
                end)
            end
        end
    end)

    -- DEATH GRAB
    local deathGrabToggle = false
    local dgCons = {}
    deathGrabItem.toggleBtn.MouseButton1Click:Connect(function()
        deathGrabToggle = not deathGrabToggle
        deathGrabItem.checkmark.Visible = deathGrabToggle
        for _, v in pairs(dgCons) do if v then v:Disconnect() end end
        dgCons = {}
        
        if deathGrabToggle then
            dgCons["KillGrab"] = Workspace.ChildAdded:Connect(function(child)
                if child.Name == "GrabParts" then
                    task.spawn(function()
                        local GrabPart = child:WaitForChild("GrabPart", 0.5)
                        if not GrabPart then return end
                        local WeldConstraint = GrabPart:FindFirstChild("WeldConstraint")
                        if not WeldConstraint then return end
                        local Part1 = WeldConstraint.Part1
                        if not Part1 then return end
                        local Parent = Part1.Parent
                        if not Parent then return end
                        local Root = Parent:FindFirstChild("HumanoidRootPart")
                        local Hum = Parent:FindFirstChildOfClass("Humanoid")
                        if not Root or not Hum then return end
                        
                        local startTime = tick()
                        while not CheckNetworkOwnerOnPart(Root) and CFP(Workspace, "GrabParts") and (tick() - startTime < 5) do
                            if SetNetworkOwner then
                                pcall(function()
                                    SetNetworkOwner:FireServer(Root, Root.CFrame)
                                end)
                            end
                            task.wait(0.1)
                        end
                        
                        if Root and Hum and Hum.Health > 0 then
                            pcall(function()
                                Hum.BreakJointsOnDeath = false
                                Hum.Health = 0
                                Hum:ChangeState(Enum.HumanoidStateType.Dead)
                                Hum.Sit = false
                                Hum.Jump = true
                                if DestroyGrabLine then
                                    DestroyGrabLine:FireServer(Root)
                                end
                            end)
                        end
                    end)
                end
            end)
        end
    end)

    -- CRAZY GRAB
    local crazyGrabToggle = false
    crazyGrabItem.toggleBtn.MouseButton1Click:Connect(function()
        crazyGrabToggle = not crazyGrabToggle
        crazyGrabItem.checkmark.Visible = crazyGrabToggle
    end)
    Workspace.ChildAdded:Connect(function(child)
        if child.Name == "GrabParts" and crazyGrabToggle then
            local Part1 = child.GrabPart.WeldConstraint.Part1
            local Parent = Part1.Parent
            local Root = Parent:FindFirstChild("HumanoidRootPart")
            if Root then
                task.spawn(function()
                    while CFP(Workspace, "GrabParts") do
                        Root.CFrame = CFrame.new(0, -20, 0)
                        task.wait(0.05)
                        Root.CFrame = CFrame.new(1e9, -20, 0)
                        task.wait(0.05)
                        Root.CFrame = CFrame.new(-1e9, -20, 0)
                        task.wait(0.05)
                        Root.CFrame = CFrame.new(1e9, -20, 1e9)
                        task.wait(0.05)
                        Root.CFrame = CFrame.new(1e9, -20, -1e9)
                        task.wait(0.05)
                        Root.CFrame = CFrame.new(0, -20, 1e9)
                        task.wait(0.05)
                        Root.CFrame = CFrame.new(1e9, 1e9, 1e9)
                        task.wait(0.05)
                    end
                end)
            end
        end
    end)

    -- ============================================================
    -- ГРУППА: AURAS (СПРАВА) - ВСЁ РАБОТАЕТ
    -- ============================================================
    local aurasBox = Instance.new("Frame")
    aurasBox.Size = UDim2.new(0, 300, 0, 0)
    aurasBox.Position = UDim2.new(0, 300 + 20 + gap, 0, 20)
    aurasBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    aurasBox.BackgroundTransparency = 0.25
    aurasBox.ClipsDescendants = true
    aurasBox.Parent = grabContentArea

    local aBoxCorner = Instance.new("UICorner")
    aBoxCorner.CornerRadius = UDim.new(0, 18)
    aBoxCorner.Parent = aurasBox

    local aBoxStroke = Instance.new("UIStroke")
    aBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    aBoxStroke.Transparency = 0.2
    aBoxStroke.Thickness = 1.0
    aBoxStroke.Parent = aurasBox

    local aTitle = Instance.new("TextLabel")
    aTitle.Size = UDim2.new(1, -30, 0, 30)
    aTitle.Position = UDim2.new(0, 15, 0, 8)
    aTitle.BackgroundTransparency = 1
    aTitle.TextXAlignment = Enum.TextXAlignment.Left
    aTitle.Text = "Auras"
    aTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    aTitle.TextTransparency = 0.05
    aTitle.TextSize = 16
    aTitle.Font = Enum.Font.GothamBold
    aTitle.Parent = aurasBox

    local aLine = Instance.new("Frame")
    aLine.Size = UDim2.new(1, -30, 0, 1.5)
    aLine.Position = UDim2.new(0, 15, 0, 42)
    aLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    aLine.BackgroundTransparency = 0.3
    aLine.BorderSizePixel = 0
    aLine.Parent = aurasBox

    local aStartY = 52
    local auraItemHeight = 48

    local function createAuraToggle(parent, title, posY)
        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, -gap * 2, 0, auraItemHeight)
        box.Position = UDim2.new(0, gap, 0, posY)
        box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        box.BackgroundTransparency = 0.25
        box.ClipsDescendants = true
        box.Parent = parent

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 18)
        boxCorner.Parent = box

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Color3.fromRGB(180, 180, 180)
        boxStroke.Transparency = 0.2
        boxStroke.Thickness = 1.0
        boxStroke.Parent = box

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(1, -24, 1, -12)
        toggleBtn.Position = UDim2.new(0, 12, 0, 6)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        toggleBtn.BackgroundTransparency = 0.2
        toggleBtn.Text = ""
        toggleBtn.AutoButtonColor = false
        toggleBtn.Parent = box

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 14)
        toggleCorner.Parent = toggleBtn

        local toggleStroke = Instance.new("UIStroke")
        toggleStroke.Color = Color3.fromRGB(180, 180, 180)
        toggleStroke.Transparency = 0.2
        toggleStroke.Thickness = 0.8
        toggleStroke.Parent = toggleBtn

        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Size = UDim2.new(1, -40, 1, 0)
        toggleLabel.Position = UDim2.new(0, 12, 0, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Text = title
        toggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        toggleLabel.TextSize = 12
        toggleLabel.Font = Enum.Font.GothamBold
        toggleLabel.Parent = toggleBtn

        local checkboxBox = Instance.new("Frame")
        checkboxBox.Size = UDim2.new(0, 20, 0, 20)
        checkboxBox.AnchorPoint = Vector2.new(1, 0.5)
        checkboxBox.Position = UDim2.new(1, -12, 0.5, 0)
        checkboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        checkboxBox.BackgroundTransparency = 0.2
        checkboxBox.BorderSizePixel = 0
        checkboxBox.Parent = toggleBtn

        local cbCorner = Instance.new("UICorner")
        cbCorner.CornerRadius = UDim.new(0, 6)
        cbCorner.Parent = checkboxBox

        local cbStroke = Instance.new("UIStroke")
        cbStroke.Color = Color3.fromRGB(150, 150, 150)
        cbStroke.Transparency = 0.2
        cbStroke.Thickness = 1
        cbStroke.Parent = checkboxBox

        local checkmark = Instance.new("TextLabel")
        checkmark.Size = UDim2.new(1, 0, 1, 0)
        checkmark.BackgroundTransparency = 1
        checkmark.Text = "✓"
        checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
        checkmark.TextSize = 14
        checkmark.Font = Enum.Font.GothamBold
        checkmark.Visible = false
        checkmark.Parent = checkboxBox

        return box, toggleBtn, checkmark
    end

    -- ============================================================
    -- СОЗДАНИЕ ВСЕХ АУР
    -- ============================================================
    local auraToggles = {}
    local aCurrentY = aStartY

    local auraItems = {
        "Fling Aura",
        "Click Aura",
        "Anti-AntiKick Aura",
        "Void Aura",
        "Kill Aura",
        "Spin Aura",
        "Telekinesis Aura",
        "Anti Banana Aura",
        "Freeze Aura",
        "Ragdoll Aura",
        "Anti Grab Aura",
        "Crazy Aura"
    }

    for _, title in ipairs(auraItems) do
        local box, btn, chk = createAuraToggle(aurasBox, title, aCurrentY)
        auraToggles[title] = {box = box, btn = btn, chk = chk, state = false}
        aCurrentY = aCurrentY + auraItemHeight + gap
    end

    -- ВСЕ АУРЫ (КОРОТКИЕ ВЕРСИИ ДЛЯ КОМПАКТНОСТИ)
    -- FLING AURA
    local flingRunning = false
    auraToggles["Fling Aura"].btn.MouseButton1Click:Connect(function()
        auraToggles["Fling Aura"].state = not auraToggles["Fling Aura"].state
        auraToggles["Fling Aura"].chk.Visible = auraToggles["Fling Aura"].state
        flingRunning = auraToggles["Fling Aura"].state
        task.spawn(function()
            while flingRunning do
                local root = getMyRoot()
                if root then
                    for _, target in ipairs(getAuraTargets(root.Position)) do
                        pcall(function()
                            setNetOwner(target)
                            local bv = Instance.new("BodyVelocity")
                            bv.MaxForce = Vector3.one * math.huge
                            bv.Velocity = Vector3.new(math.random(-1,1)*30, 100, math.random(-1,1)*30)
                            bv.Parent = target
                            Debris:AddItem(bv, 0.2)
                        end)
                    end
                end
                task.wait(0.05)
            end
        end)
    end)

    -- CLICK AURA
    local clickRunning = false
    auraToggles["Click Aura"].btn.MouseButton1Click:Connect(function()
        auraToggles["Click Aura"].state = not auraToggles["Click Aura"].state
        auraToggles["Click Aura"].chk.Visible = auraToggles["Click Aura"].state
        clickRunning = auraToggles["Click Aura"].state
        task.spawn(function()
            while clickRunning do
                pcall(function()
                    local root = getMyRoot()
                    if not root then return end
                    for _, target in ipairs(getAuraTargets(root.Position)) do
                        pcall(function()
                            setNetOwner(target)
                            if not target:FindFirstChild("ClickAuraBV") then
                                local bv = Instance.new("BodyVelocity")
                                bv.Name = "ClickAuraBV"
                                bv.Velocity = Vector3.zero
                                bv.MaxForce = Vector3.one * math.huge
                                bv.Parent = target
                                local bg = Instance.new("BodyGyro")
                                bg.Name = "ClickAuraBG"
                                bg.MaxTorque = Vector3.one * math.huge
                                bg.CFrame = CFrame.new(target.Position, target.Position + Vector3.new(0,0,1))
                                bg.Parent = target
                            end
                        end)
                    end
                end)
                task.wait(0.05)
            end
        end)
    end)

    -- ANTI-ANTIKICK AURA
    local antiKickRunning = false
    auraToggles["Anti-AntiKick Aura"].btn.MouseButton1Click:Connect(function()
        auraToggles["Anti-AntiKick Aura"].state = not auraToggles["Anti-AntiKick Aura"].state
        auraToggles["Anti-AntiKick Aura"].chk.Visible = auraToggles["Anti-AntiKick Aura"].state
        antiKickRunning = auraToggles["Anti-AntiKick Aura"].state
        task.spawn(function()
            local GE = ReplicatedStorage:WaitForChild("GrabEvents")
            local setNE = GE:WaitForChild("SetNetworkOwner")
            local createGL = GE:WaitForChild("CreateGrabLine")
            local destroyGL = GE:WaitForChild("DestroyGrabLine")
            local auraFrame = 0
            while antiKickRunning do
                local root = getMyRoot()
                if root then
                    for _, obj in ipairs(Workspace:GetPartBoundsInRadius(root.Position, 20)) do
                        if obj:IsA("BasePart") and obj.Name == "StickyPart" then
                            local plr = Players:GetPlayerFromCharacter(obj.Parent)
                            if plr and plr ~= LocalPlayer then
                                if auraFrame % 3 == 0 then pcall(function() setNE:FireServer(obj, obj.CFrame) end)
                                elseif auraFrame % 3 == 1 then pcall(function() createGL:FireServer(obj, Vector3.zero, obj.Position, false) end)
                                else pcall(function() destroyGL:FireServer(obj) end) end
                            end
                        end
                    end
                    auraFrame = auraFrame + 1
                end
                task.wait()
            end
        end)
    end)

    -- VOID AURA
    local voidRunning = false
    auraToggles["Void Aura"].btn.MouseButton1Click:Connect(function()
        auraToggles["Void Aura"].state = not auraToggles["Void Aura"].state
        auraToggles["Void Aura"].chk.Visible = auraToggles["Void Aura"].state
        voidRunning = auraToggles["Void Aura"].state
        task.spawn(function()
            while voidRunning do
                local root = getMyRoot()
                if root then
                    for _, target in ipairs(getAuraTargets(root.Position)) do
                        pcall(function()
                            setNetOwner(target)
                            target.CFrame = target.CFrame - Vector3.new(0, 1500, 0)
                            local bv = Instance.new("BodyVelocity")
                            bv.MaxForce = Vector3.one * math.huge
                            bv.Velocity = Vector3.new(0, -9e9, 0)
                            bv.Parent = target
                            Debris:AddItem(bv, 0.2)
                        end)
                    end
                end
                task.wait(0.05)
            end
        end)
    end)

    -- KILL AURA
    local killRunning = false
    auraToggles["Kill Aura"].btn.MouseButton1Click:Connect(function()
        auraToggles["Kill Aura"].state = not auraToggles["Kill Aura"].state
        auraToggles["Kill Aura"].chk.Visible = auraToggles["Kill Aura"].state
        killRunning = auraToggles["Kill Aura"].state
        task.spawn(function()
            local GE = ReplicatedStorage:WaitForChild("GrabEvents")
            local SetNetworkOwner = GE:WaitForChild("SetNetworkOwner")
            local DestroyGrabLine = GE:WaitForChild("DestroyGrabLine")
            while killRunning do
                local root = getMyRoot()
                if root then
                    for _, target in ipairs(getAuraTargets(root.Position)) do
                        pcall(function()
                            local targetModel = target.Parent
                            local head = targetModel:FindFirstChild("Head")
                            local hum = targetModel:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 and head then
                                SetNetworkOwner:FireServer(target, target.CFrame)
                                task.wait(0.1)
                                DestroyGrabLine:FireServer(target)
                                if head:FindFirstChild("PartOwner") and head.PartOwner.Value == LocalPlayer.Name then
                                    for _, part in pairs(targetModel:GetChildren()) do
                                        if part:IsA("BasePart") then
                                            part.CFrame = CFrame.new(-1000000000, 1000000000, -1000000000)
                                        end
                                    end
                                    task.wait()
                                    for _, part in pairs(targetModel:GetChildren()) do
                                        if part:IsA("BasePart") then
                                            part.CFrame = CFrame.new(-1000000000, 1000000000, -1000000000)
                                        end
                                    end
                                    local bv = Instance.new("BodyVelocity")
                                    bv.Velocity = Vector3.new(0, -9999999, 0)
                                    bv.MaxForce = Vector3.new(9000000000, 9000000000, 9000000000)
                                    bv.P = 100000075
                                    bv.Parent = target
                                    hum.Sit = false
                                    hum.Jump = true
                                    hum.BreakJointsOnDeath = false
                                    hum:ChangeState(Enum.HumanoidStateType.Dead)
                                    task.delay(2, function()
                                        if bv and bv.Parent then bv:Destroy() end
                                    end)
                                end
                            end
                        end)
                    end
                end
                task.wait(0.1)
            end
        end)
    end)

    -- SPIN AURA
    local spinRunning = false
    auraToggles["Spin Aura"].btn.MouseButton1Click:Connect(function()
        auraToggles["Spin Aura"].state = not auraToggles["Spin Aura"].state
        auraToggles["Spin Aura"].chk.Visible = auraToggles["Spin Aura"].state
        spinRunning = auraToggles["Spin Aura"].state
        task.spawn(function()
            local spinAngle = 0
            while spinRunning do
                pcall(function()
                    local root = getMyRoot()
                    if not root then return end
                    local spd = 5
                    local heightVal = 5
                    spinAngle = spinAngle + (spd / 100)
                    if spinAngle >= 6.28 then spinAngle = 0 end
                    local radius = 10
                    local yOffset = heightVal
                    for _, target in ipairs(getAuraTargets(root.Position)) do
                        local targetPosition = root.Position + Vector3.new(math.cos(spinAngle)*radius, yOffset, math.sin(spinAngle)*radius)
                        pcall(function()
                            setNetOwner(target)
                            local p = target.Parent
                            local hum = p and p:FindFirstChildOfClass("Humanoid")
                            if hum then hum.PlatformStand = true end
                            local bv = target:FindFirstChild("SpinAuraBV") or Instance.new("BodyVelocity")
                            bv.Name = "SpinAuraBV"
                            bv.Velocity = (targetPosition - target.Position) * 25
                            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                            bv.P = 10000
                            bv.Parent = target
                            local bg = target:FindFirstChild("SpinAuraBG") or Instance.new("BodyGyro")
                            bg.Name = "SpinAuraBG"
                            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                            bg.P = 10000
                            bg.D = 500
                            bg.CFrame = CFrame.new(target.Position, root.Position)
                            bg.Parent = target
                        end)
                    end
                end)
                task.wait(0.02)
            end
        end)
    end)

    -- TELEKINESIS AURA
    local tkRunning = false
    auraToggles["Telekinesis Aura"].btn.MouseButton1Click:Connect(function()
        auraToggles["Telekinesis Aura"].state = not auraToggles["Telekinesis Aura"].state
        auraToggles["Telekinesis Aura"].chk.Visible = auraToggles["Telekinesis Aura"].state
        tkRunning = auraToggles["Telekinesis Aura"].state
        task.spawn(function()
            local GE = ReplicatedStorage:WaitForChild("GrabEvents")
            local SetNetworkOwner = GE:WaitForChild("SetNetworkOwner")
            while tkRunning do
                pcall(function()
                    local root = getMyRoot()
                    if not root then return end
                    local lookDir = camera.CFrame.LookVector
                    for _, target in ipairs(getAuraTargets(root.Position)) do
                        pcall(function()
                            local targetModel = target.Parent
                            for _, desc in pairs(targetModel:GetDescendants()) do
                                if desc:IsA("BasePart") then desc.CanCollide = false end
                            end
                            SetNetworkOwner:FireServer(target, root.CFrame)
                            local pos = target:FindFirstChild("HellAuraPos") or Instance.new("BodyPosition")
                            pos.Name = "HellAuraPos"
                            pos.MaxForce = Vector3.new(100000, 100000, 100000)
                            pos.D = 500
                            pos.P = 50000
                            pos.Position = root.Position + lookDir * 15 + Vector3.new(0, 5, 0)
                            pos.Parent = target
                            local gyro = target:FindFirstChild("HellAuraGyro") or Instance.new("BodyGyro")
                            gyro.Name = "HellAuraGyro"
                            gyro.MaxTorque = Vector3.new(100000, 100000, 100000)
                            gyro.D = 500
                            gyro.P = 50000
                            gyro.CFrame = CFrame.new(target.Position, root.Position)
                            gyro.Parent = target
                        end)
                    end
                end)
                task.wait(0.05)
            end
        end)
    end)

    -- ANTI BANANA AURA
    local bananaRunning = false
    auraToggles["Anti Banana Aura"].btn.MouseButton1Click:Connect(function()
        auraToggles["Anti Banana Aura"].state = not auraToggles["Anti Banana Aura"].state
        auraToggles["Anti Banana Aura"].chk.Visible = auraToggles["Anti Banana Aura"].state
        bananaRunning = auraToggles["Anti Banana Aura"].state
        task.spawn(function()
            local GE = ReplicatedStorage:WaitForChild("GrabEvents")
            local setNE = GE:WaitForChild("SetNetworkOwner")
            local createGL = GE:WaitForChild("CreateGrabLine")
            local destroyGL = GE:WaitForChild("DestroyGrabLine")
            local auraFrame = 0
            while bananaRunning do
                local root = getMyRoot()
                if root then
                    for _, obj in ipairs(Workspace:GetPartBoundsInRadius(root.Position, 20)) do
                        if obj:IsA("BasePart") and obj.Name == "HitboxPart" then
                            local plr = Players:GetPlayerFromCharacter(obj.Parent)
                            if plr and plr ~= LocalPlayer then
                                if auraFrame % 3 == 0 then pcall(function() setNE:FireServer(obj, obj.CFrame) end)
                                elseif auraFrame % 3 == 1 then pcall(function() createGL:FireServer(obj, Vector3.zero, obj.Position, false) end)
                                else pcall(function() destroyGL:FireServer(obj) end) end
                                pcall(function()
                                    local direction = (obj.Position - root.Position).Unit
                                    local bv = Instance.new("BodyVelocity")
                                    bv.Velocity = direction * 5000 + Vector3.new(0, 2000, 0)
                                    bv.MaxForce = Vector3.one * math.huge
                                    bv.Parent = obj
                                    Debris:AddItem(bv, 0.3)
                                end)
                            end
                        end
                    end
                    auraFrame = auraFrame + 1
                end
                task.wait()
            end
        end)
    end)

    -- FREEZE AURA
    local freezeRunning = false
    auraToggles["Freeze Aura"].btn.MouseButton1Click:Connect(function()
        auraToggles["Freeze Aura"].state = not auraToggles["Freeze Aura"].state
        auraToggles["Freeze Aura"].chk.Visible = auraToggles["Freeze Aura"].state
        freezeRunning = auraToggles["Freeze Aura"].state
        task.spawn(function()
            while freezeRunning do
                pcall(function()
                    local root = getMyRoot()
                    if not root then return end
                    for _, target in ipairs(getAuraTargets(root.Position)) do
                        pcall(function()
                            setNetOwner(target)
                            if not target:FindFirstChild("FreezeAuraBV") then
                                local bv = Instance.new("BodyVelocity")
                                bv.Name = "FreezeAuraBV"
                                bv.Velocity = Vector3.zero
                                bv.MaxForce = Vector3.one * math.huge
                                bv.P = 100000
                                bv.Parent = target
                                local bg = Instance.new("BodyGyro")
                                bg.Name = "FreezeAuraBG"
                                bg.MaxTorque = Vector3.one * math.huge
                                bg.P = 100000
                                bg.CFrame = target.CFrame
                                bg.Parent = target
                                local bp = Instance.new("BodyPosition")
                                bp.Name = "FreezeAuraBP"
                                bp.MaxForce = Vector3.one * math.huge
                                bp.P = 100000
                                bp.D = 1000
                                bp.Position = target.Position
                                bp.Parent = target
                            else
                                local bp = target:FindFirstChild("FreezeAuraBP")
                                if bp then bp.Position = target.Position end
                                local bg = target:FindFirstChild("FreezeAuraBG")
                                if bg then bg.CFrame = target.CFrame end
                            end
                        end)
                    end
                end)
                task.wait(0.05)
            end
        end)
    end)

    -- RAGDOLL AURA
    local ragdollRunning = false
    auraToggles["Ragdoll Aura"].btn.MouseButton1Click:Connect(function()
        auraToggles["Ragdoll Aura"].state = not auraToggles["Ragdoll Aura"].state
        auraToggles["Ragdoll Aura"].chk.Visible = auraToggles["Ragdoll Aura"].state
        ragdollRunning = auraToggles["Ragdoll Aura"].state
        task.spawn(function()
            local function prepareRagdollPallet()
                local inv = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
                if not inv then return nil, nil end
                local pallete = inv:FindFirstChild("RagdollPalete")
                if not pallete then
                    pcall(function()
                        SpawnToyRemote:InvokeServer("PalletLightBrown", player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 10, 20), Vector3.zero)
                    end)
                    task.wait(0.5)
                    pallete = inv:FindFirstChild("PalletLightBrown")
                    if not pallete then return nil, nil end
                    local soundPart = FWD(pallete, "SoundPart")
                    if soundPart then
                        while not CheckNetworkOwnerOnPart(soundPart) do
                            if SetNetworkOwner then SetNetworkOwner:FireServer(soundPart, soundPart.CFrame) end
                            task.wait(0.05)
                        end
                        for _, v in pairs(pallete:GetChildren()) do
                            if v:IsA("BasePart") then
                                v.Transparency = 0.8
                                v.CanCollide = false
                                v.CanQuery = false
                            end
                        end
                        pallete.Name = "RagdollPalete"
                        local bv = Instance.new("BodyVelocity")
                        bv.MaxForce = Vector3.new(0, math.huge, 0)
                        bv.Velocity = Vector3.new(0, 900, 0)
                        bv.Parent = soundPart
                        return pallete, soundPart
                    end
                end
                local soundPart = pallete:FindFirstChild("SoundPart")
                return pallete, soundPart
            end
            local pallete, soundPart = prepareRagdollPallet()
            while ragdollRunning do
                pcall(function()
                    local root = getMyRoot()
                    if not root then return end
                    if not pallete or not pallete.Parent then
                        pallete, soundPart = prepareRagdollPallet()
                    end
                    for _, target in ipairs(getAuraTargets(root.Position)) do
                        pcall(function()
                            setNetOwner(target)
                            local targetModel = target.Parent
                            local hum = targetModel:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 and soundPart and soundPart.Parent then
                                local ragdolled = hum:FindFirstChild("Ragdolled")
                                if ragdolled and ragdolled.Value then return end
                                soundPart.Position = target.Position + Vector3.new(0, 2, 0)
                                soundPart.AssemblyLinearVelocity = Vector3.new(0, -500, 0)
                                CreateGrabLine:FireServer(target, Vector3.zero, target.Position, false)
                                task.wait(0.05)
                                DestroyGrabLine:FireServer(target)
                                task.wait(0.05)
                                soundPart.Position = target.Position + Vector3.new(0, 5, 0)
                                soundPart.AssemblyLinearVelocity = Vector3.new(0, -800, 0)
                                target.AssemblyLinearVelocity = Vector3.zero
                                target.AssemblyAngularVelocity = Vector3.zero
                                if hum.PlatformStand then hum.PlatformStand = false end
                            end
                        end)
                    end
                end)
                task.wait(0.1)
            end
        end)
    end)

    -- ANTI GRAB AURA
    local antiGrabAuraRunning = false
    auraToggles["Anti Grab Aura"].btn.MouseButton1Click:Connect(function()
        auraToggles["Anti Grab Aura"].state = not auraToggles["Anti Grab Aura"].state
        auraToggles["Anti Grab Aura"].chk.Visible = auraToggles["Anti Grab Aura"].state
        antiGrabAuraRunning = auraToggles["Anti Grab Aura"].state
        task.spawn(function()
            local GE = ReplicatedStorage:WaitForChild("GrabEvents")
            local SetNetworkOwner = GE:WaitForChild("SetNetworkOwner")
            local DestroyGrabLine = GE:WaitForChild("DestroyGrabLine")
            local CreateGrabLine = GE:WaitForChild("CreateGrabLine")
            local Struggle = ReplicatedStorage:FindFirstChild("CharacterEvents") and ReplicatedStorage.CharacterEvents:FindFirstChild("Struggle")
            while antiGrabAuraRunning do
                RunService.RenderStepped:Wait()
                local root = getMyRoot()
                if not root then task.wait(0.1) continue end
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        pcall(function()
                            local char = plr.Character
                            if not char then return end
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            local head = char:FindFirstChild("Head")
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            if not hrp or not head or not hum then return end
                            if hum.Health <= 0 then return end
                            if (hrp.Position - root.Position).Magnitude > 30 then return end
                            local partOwner = head:FindFirstChild("PartOwner")
                            local isHeld = partOwner and partOwner.Value ~= "" and partOwner.Value ~= plr.Name
                            if isHeld then
                                if SetNetworkOwner then SetNetworkOwner:FireServer(hrp, hrp.CFrame) end
                                if DestroyGrabLine then DestroyGrabLine:FireServer(hrp)
                                    if head then DestroyGrabLine:FireServer(head) end
                                end
                                if CreateGrabLine then CreateGrabLine:FireServer(hrp, Vector3.zero, hrp.Position, false) end
                                if hum then
                                    hum.Sit = false
                                    hum.PlatformStand = false
                                    if hum:FindFirstChild("Ragdolled") then hum.Ragdolled.Value = false end
                                    hum:ChangeState(Enum.HumanoidStateType.Running)
                                end
                                if Struggle then Struggle:FireServer(plr) end
                                for _, part in pairs(char:GetDescendants()) do
                                    if part:IsA("BasePart") and part:FindFirstChild("PartOwner") then
                                        pcall(function()
                                            if DestroyGrabLine then DestroyGrabLine:FireServer(part) end
                                        end)
                                    end
                                end
                            end
                        end)
                    end
                end
                task.wait(0.05)
            end
        end)
    end)

    -- CRAZY AURA
    local crazyRunning = false
    auraToggles["Crazy Aura"].btn.MouseButton1Click:Connect(function()
        auraToggles["Crazy Aura"].state = not auraToggles["Crazy Aura"].state
        auraToggles["Crazy Aura"].chk.Visible = auraToggles["Crazy Aura"].state
        crazyRunning = auraToggles["Crazy Aura"].state
        task.spawn(function()
            while crazyRunning do
                local root = getMyRoot()
                if root then
                    for _, target in ipairs(getAuraTargets(root.Position)) do
                        pcall(function()
                            setNetOwner(target)
                            local targetModel = target.Parent
                            local hum = targetModel:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                local positions = {
                                    CFrame.new(0, -20, 0),
                                    CFrame.new(1e9, -20, 0),
                                    CFrame.new(-1e9, -20, 0),
                                    CFrame.new(1e9, -20, 1e9),
                                    CFrame.new(1e9, -20, -1e9),
                                    CFrame.new(0, -20, 1e9),
                                    CFrame.new(1e9, 1e9, 1e9)
                                }
                                local randomPos = positions[math.random(1, #positions)]
                                target.CFrame = randomPos
                                target.AssemblyLinearVelocity = Vector3.zero
                                target.AssemblyAngularVelocity = Vector3.zero
                                local hl = Instance.new("Highlight", targetModel)
                                hl.FillColor = Color3.fromRGB(255, 0, 255)
                                hl.FillTransparency = 0.5
                                Debris:AddItem(hl, 0.2)
                            end
                        end)
                    end
                end
                task.wait(0.05)
            end
        end)
    end)

    -- ============================================================
    -- ФИНАЛЬНАЯ ВЫСОТА
    -- ============================================================
    local aHeight = 32 + gap + (#auraItems * (auraItemHeight + gap)) + gap
    aurasBox.Size = UDim2.new(0, 300, 0, aHeight)
    
    local currentCanvas = grabContentArea.CanvasSize.Y.Offset
    grabContentArea.CanvasSize = UDim2.new(0, 0, 0, currentCanvas + mgHeight + aHeight + gap + 20)
end 

-- ============================================================================
-- TARGET TAB (ПОЛНАЯ РАБОЧАЯ ВЕРСИЯ)
-- ============================================================================
local function setupTargetTab(targetContentArea)
    targetContentArea.ClipsDescendants = true
    targetContentArea.CanvasSize = UDim2.new(0, 0, 0, 1100)

    local gap = 10
    local EXTRA_BOTTOM = 15
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local player = LocalPlayer
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    local statusWords = {"Pidoras", "Dolbaeb", "Eblan", "Govnoed", "Gandon"}

    -- ============================================================
    -- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
    -- ============================================================
    local function FWD(parent, part, time)
        return parent:FindFirstChild(part) or parent:WaitForChild(part, time or 5)
    end

    local function CFP(parent, part)
        return parent:FindFirstChild(part) ~= nil
    end

    local function CheckForPartOwner(Head)
        local PartOwner = Head:FindFirstChild("PartOwner")
        return PartOwner and PartOwner.Value == LocalPlayer.Name
    end

    local function sno(part)
        local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
        if GE then
            local SetNetworkOwner = GE:FindFirstChild("SetNetworkOwner")
            if SetNetworkOwner then
                SetNetworkOwner:FireServer(part, part.CFrame)
            end
        end
    end

    local function unsno(part)
        local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
        if GE then
            local DestroyGrabLine = GE:FindFirstChild("DestroyGrabLine")
            if DestroyGrabLine then
                DestroyGrabLine:FireServer(part)
            end
        end
    end

    local function SpawnToy(ToyName)
        local SpawnToyRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
        local inv = Workspace:FindFirstChild(LocalPlayer.Name.."SpawnedInToys")
        local InPlot = LocalPlayer.InPlot
        local InOwnedPlot = LocalPlayer.InOwnedPlot
        local CanSpawnToy = LocalPlayer.CanSpawnToy
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if InPlot and InPlot.Value and not InOwnedPlot.Value then 
            InPlot:GetPropertyChangedSignal("Value"):Wait()
        end 
        if CanSpawnToy and not CanSpawnToy.Value then 
            CanSpawnToy:GetPropertyChangedSignal("Value"):Wait()
        end

        local SpawnCF = hrp and hrp.CFrame * CFrame.new(0, 14, 20) or CFrame.new(0, 10, 0)
        local Container = InOwnedPlot and InOwnedPlot.Value and Workspace.PlotItems:FindFirstChild("Plot1") or inv
        if not Container then return nil end

        local spawnedObject = nil
        local connection
        connection = Container.ChildAdded:Connect(function(child)
            if child.Name == ToyName then
                spawnedObject = child
            end
        end)

        task.spawn(function()
            pcall(function()
                SpawnToyRemote:InvokeServer(ToyName, SpawnCF, Vector3.zero)
            end)
        end)

        local start = tick()
        repeat task.wait() until spawnedObject or (tick() - start) > 2.5
        connection:Disconnect()
        return spawnedObject
    end

    local function FindBlob()
        local inv = Workspace:FindFirstChild(LocalPlayer.Name.."SpawnedInToys")
        if not inv then return nil end
        for _, v in pairs(inv:GetChildren()) do
            if v.Name == "CreatureBlobman" then
                return v
            end
        end
        return nil
    end

    -- ============================================================
    -- ВСПОМОГАТЕЛЬНЫЕ UI ФУНКЦИИ
    -- ============================================================
    local function createToggle(parent, title, posY)
        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, -gap * 2, 0, 48)
        box.Position = UDim2.new(0, gap, 0, posY)
        box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        box.BackgroundTransparency = 0.25
        box.ClipsDescendants = true
        box.Parent = parent

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 18)
        boxCorner.Parent = box

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Color3.fromRGB(180, 180, 180)
        boxStroke.Transparency = 0.2
        boxStroke.Thickness = 1.0
        boxStroke.Parent = box

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(1, -24, 1, -12)
        toggleBtn.Position = UDim2.new(0, 12, 0, 6)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        toggleBtn.BackgroundTransparency = 0.2
        toggleBtn.Text = ""
        toggleBtn.AutoButtonColor = false
        toggleBtn.Parent = box

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 14)
        toggleCorner.Parent = toggleBtn

        local toggleStroke = Instance.new("UIStroke")
        toggleStroke.Color = Color3.fromRGB(180, 180, 180)
        toggleStroke.Transparency = 0.2
        toggleStroke.Thickness = 0.8
        toggleStroke.Parent = toggleBtn

        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Size = UDim2.new(1, -40, 1, 0)
        toggleLabel.Position = UDim2.new(0, 12, 0, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Text = title
        toggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        toggleLabel.TextSize = 13
        toggleLabel.Font = Enum.Font.GothamBold
        toggleLabel.Parent = toggleBtn

        local checkboxBox = Instance.new("Frame")
        checkboxBox.Size = UDim2.new(0, 20, 0, 20)
        checkboxBox.AnchorPoint = Vector2.new(1, 0.5)
        checkboxBox.Position = UDim2.new(1, -12, 0.5, 0)
        checkboxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        checkboxBox.BackgroundTransparency = 0.2
        checkboxBox.BorderSizePixel = 0
        checkboxBox.Parent = toggleBtn

        local cbCorner = Instance.new("UICorner")
        cbCorner.CornerRadius = UDim.new(0, 6)
        cbCorner.Parent = checkboxBox

        local cbStroke = Instance.new("UIStroke")
        cbStroke.Color = Color3.fromRGB(150, 150, 150)
        cbStroke.Transparency = 0.2
        cbStroke.Thickness = 1
        cbStroke.Parent = checkboxBox

        local checkmark = Instance.new("TextLabel")
        checkmark.Size = UDim2.new(1, 0, 1, 0)
        checkmark.BackgroundTransparency = 1
        checkmark.Text = "✓"
        checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
        checkmark.TextSize = 14
        checkmark.Font = Enum.Font.GothamBold
        checkmark.Visible = false
        checkmark.Parent = checkboxBox

        return box, toggleBtn, checkmark
    end

    -- ============================================================
    -- ГРУППА 1: TARGET SELECT
    -- ============================================================
    local targetSelectBox = Instance.new("Frame")
    targetSelectBox.Size = UDim2.new(0, 300, 0, 0)
    targetSelectBox.Position = UDim2.new(0, 20, 0, 20)
    targetSelectBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    targetSelectBox.BackgroundTransparency = 0.25
    targetSelectBox.ClipsDescendants = true
    targetSelectBox.Parent = targetContentArea

    local tsBoxCorner = Instance.new("UICorner")
    tsBoxCorner.CornerRadius = UDim.new(0, 18)
    tsBoxCorner.Parent = targetSelectBox

    local tsBoxStroke = Instance.new("UIStroke")
    tsBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    tsBoxStroke.Transparency = 0.2
    tsBoxStroke.Thickness = 1.0
    tsBoxStroke.Parent = targetSelectBox

    local tsTitle = Instance.new("TextLabel")
    tsTitle.Size = UDim2.new(1, -30, 0, 30)
    tsTitle.Position = UDim2.new(0, 15, 0, 8)
    tsTitle.BackgroundTransparency = 1
    tsTitle.TextXAlignment = Enum.TextXAlignment.Left
    tsTitle.Text = "Target Select"
    tsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    tsTitle.TextTransparency = 0.05
    tsTitle.TextSize = 16
    tsTitle.Font = Enum.Font.GothamBold
    tsTitle.Parent = targetSelectBox

    local tsLine = Instance.new("Frame")
    tsLine.Size = UDim2.new(1, -30, 0, 1.5)
    tsLine.Position = UDim2.new(0, 15, 0, 42)
    tsLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    tsLine.BackgroundTransparency = 0.3
    tsLine.BorderSizePixel = 0
    tsLine.Parent = targetSelectBox

    -- ============================================================
    -- SELECT TARGET (ДРОПДАУН)
    -- ============================================================
    local selectedTarget = nil
    local tsDropdownOpen = false
    local tsContainer = nil
    local tsScrollFrame = nil
    local tsAnimating = false
    local DROPDOWN_HEIGHT = 48
    local INFO_HEIGHT = 210

    local selectFriendBox = Instance.new("Frame")
    selectFriendBox.Size = UDim2.new(1, -gap * 2, 0, DROPDOWN_HEIGHT)
    selectFriendBox.Position = UDim2.new(0, gap, 0, 52)
    selectFriendBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    selectFriendBox.BackgroundTransparency = 0.25
    selectFriendBox.ClipsDescendants = true
    selectFriendBox.Parent = targetSelectBox

    local sfBoxCorner = Instance.new("UICorner")
    sfBoxCorner.CornerRadius = UDim.new(0, 18)
    sfBoxCorner.Parent = selectFriendBox

    local sfBoxStroke = Instance.new("UIStroke")
    sfBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    sfBoxStroke.Transparency = 0.2
    sfBoxStroke.Thickness = 1.0
    sfBoxStroke.Parent = selectFriendBox

    local sfBtn = Instance.new("TextButton")
    sfBtn.Size = UDim2.new(1, -24, 0, 36)
    sfBtn.Position = UDim2.new(0, 12, 0, 6)
    sfBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    sfBtn.BackgroundTransparency = 0.2
    sfBtn.Text = ""
    sfBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sfBtn.TextTransparency = 0.05
    sfBtn.TextSize = 13
    sfBtn.Font = Enum.Font.GothamBold
    sfBtn.TextXAlignment = Enum.TextXAlignment.Left
    sfBtn.Parent = selectFriendBox

    local sfBtnCorner = Instance.new("UICorner")
    sfBtnCorner.CornerRadius = UDim.new(0, 14)
    sfBtnCorner.Parent = sfBtn

    local sfBtnStroke = Instance.new("UIStroke")
    sfBtnStroke.Color = Color3.fromRGB(180, 180, 180)
    sfBtnStroke.Transparency = 0.2
    sfBtnStroke.Thickness = 0.8
    sfBtnStroke.Parent = sfBtn

    local sfLabel = Instance.new("TextLabel")
    sfLabel.Size = UDim2.new(1, -40, 1, 0)
    sfLabel.Position = UDim2.new(0, 17, 0, 0)
    sfLabel.BackgroundTransparency = 1
    sfLabel.TextXAlignment = Enum.TextXAlignment.Left
    sfLabel.Text = "Select Target"
    sfLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sfLabel.TextTransparency = 0.05
    sfLabel.TextSize = 13
    sfLabel.Font = Enum.Font.GothamBold
    sfLabel.Parent = sfBtn

    local sfArrow = Instance.new("TextButton")
    sfArrow.Size = UDim2.new(0, 30, 1, 0)
    sfArrow.AnchorPoint = Vector2.new(1, 0.5)
    sfArrow.Position = UDim2.new(1, -12, 0.5, 0)
    sfArrow.BackgroundTransparency = 1
    sfArrow.Text = "▸"
    sfArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
    sfArrow.TextTransparency = 0.3
    sfArrow.TextSize = 16
    sfArrow.Font = Enum.Font.GothamBold
    sfArrow.Parent = sfBtn

    -- ============================================================
    -- ФРЕЙМ С ИНФОРМАЦИЕЙ
    -- ============================================================
    local targetInfoBox = Instance.new("Frame")
    targetInfoBox.Size = UDim2.new(1, -gap * 2, 0, INFO_HEIGHT + EXTRA_BOTTOM)
    targetInfoBox.Position = UDim2.new(0, gap, 0, 52 + DROPDOWN_HEIGHT + gap)
    targetInfoBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    targetInfoBox.BackgroundTransparency = 0.25
    targetInfoBox.ClipsDescendants = true
    targetInfoBox.Parent = targetSelectBox

    local tiBoxCorner = Instance.new("UICorner")
    tiBoxCorner.CornerRadius = UDim.new(0, 18)
    tiBoxCorner.Parent = targetInfoBox

    local tiBoxStroke = Instance.new("UIStroke")
    tiBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    tiBoxStroke.Transparency = 0.2
    tiBoxStroke.Thickness = 1.0
    tiBoxStroke.Parent = targetInfoBox

    -- АВАТАР
    local tiAvatarFrame = Instance.new("Frame")
    tiAvatarFrame.Size = UDim2.new(1, 0, 0, 100)
    tiAvatarFrame.Position = UDim2.new(0, 0, 0, 0)
    tiAvatarFrame.BackgroundTransparency = 1
    tiAvatarFrame.Parent = targetInfoBox

    local targetAvatar = Instance.new("ImageLabel")
    targetAvatar.Size = UDim2.new(0, 64, 0, 64)
    targetAvatar.Position = UDim2.new(0, 10, 0, 18)
    targetAvatar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    targetAvatar.BackgroundTransparency = 0.3
    targetAvatar.ScaleType = Enum.ScaleType.Fit
    targetAvatar.Parent = tiAvatarFrame

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0)
    avatarCorner.Parent = targetAvatar

    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = Color3.fromRGB(180, 180, 180)
    avatarStroke.Transparency = 0.2
    avatarStroke.Thickness = 1.0
    avatarStroke.Parent = targetAvatar

    local targetNameLabel = Instance.new("TextLabel")
    targetNameLabel.Size = UDim2.new(1, -90, 0, 30)
    targetNameLabel.Position = UDim2.new(0, 85, 0, 18)
    targetNameLabel.BackgroundTransparency = 1
    targetNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetNameLabel.Text = "No Target Selected"
    targetNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetNameLabel.TextTransparency = 0.05
    targetNameLabel.TextSize = 16
    targetNameLabel.Font = Enum.Font.GothamBold
    targetNameLabel.Parent = tiAvatarFrame

    local targetStatusLabel = Instance.new("TextLabel")
    targetStatusLabel.Size = UDim2.new(1, -90, 0, 20)
    targetStatusLabel.Position = UDim2.new(0, 85, 0, 50)
    targetStatusLabel.BackgroundTransparency = 1
    targetStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetStatusLabel.Text = "Status: Unknown"
    targetStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetStatusLabel.TextSize = 12
    targetStatusLabel.Font = Enum.Font.Gotham
    targetStatusLabel.Parent = tiAvatarFrame

    -- СТАТИСТИКА
    local tiStatsFrame = Instance.new("Frame")
    tiStatsFrame.Size = UDim2.new(1, 0, 0, 110)
    tiStatsFrame.Position = UDim2.new(0, 0, 0, 100)
    tiStatsFrame.BackgroundTransparency = 1
    tiStatsFrame.Parent = targetInfoBox

    local tiDivider = Instance.new("Frame")
    tiDivider.Size = UDim2.new(1, -20, 0, 1.5)
    tiDivider.Position = UDim2.new(0, 10, 0, 0)
    tiDivider.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    tiDivider.BackgroundTransparency = 0.3
    tiDivider.BorderSizePixel = 0
    tiDivider.Parent = tiStatsFrame

    local function createStatRow(parent, label, posY, iconId)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -20, 0, 30)
        row.Position = UDim2.new(0, 10, 0, posY)
        row.BackgroundTransparency = 1
        row.Parent = parent

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 18, 0, 18)
        icon.Position = UDim2.new(0, 0, 0.5, -9)
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://" .. iconId
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Parent = row

        local labelText = Instance.new("TextLabel")
        labelText.Size = UDim2.new(0.4, -25, 1, 0)
        labelText.Position = UDim2.new(0, 22, 0, 0)
        labelText.BackgroundTransparency = 1
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Text = label
        labelText.TextColor3 = Color3.fromRGB(150, 150, 150)
        labelText.TextSize = 12
        labelText.Font = Enum.Font.Gotham
        labelText.Parent = row

        local valueText = Instance.new("TextLabel")
        valueText.Size = UDim2.new(0.6, -10, 1, 0)
        valueText.Position = UDim2.new(0.4, 0, 0, 0)
        valueText.BackgroundTransparency = 1
        valueText.TextXAlignment = Enum.TextXAlignment.Right
        valueText.Text = "0/0"
        valueText.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueText.TextTransparency = 0.05
        valueText.TextSize = 12
        valueText.Font = Enum.Font.GothamBold
        valueText.Parent = row

        return valueText
    end

    local hpStat = createStatRow(tiStatsFrame, "Health", 15, "77996445841705")
    local rangeStat = createStatRow(tiStatsFrame, "Range", 47, "119730292668688")
    local pcldStat = createStatRow(tiStatsFrame, "PCLD", 79, "100043025293354")

    -- ============================================================
    -- ФУНКЦИЯ ОБНОВЛЕНИЯ ВЫСОТЫ
    -- ============================================================
    local function updateHeight()
        local dropdownH = DROPDOWN_HEIGHT
        if tsDropdownOpen then
            dropdownH = selectFriendBox.Size.Y.Offset or DROPDOWN_HEIGHT
        end
        
        local totalHeight = 52 + dropdownH + gap + INFO_HEIGHT + EXTRA_BOTTOM + gap
        targetSelectBox.Size = UDim2.new(0, 300, 0, totalHeight)
        targetInfoBox.Position = UDim2.new(0, gap, 0, 52 + dropdownH + gap)
        
        local kfH = kickFeaturesBox and kickFeaturesBox.Size.Y.Offset or 200
        local aeH = autoExplodeBox and autoExplodeBox.Size.Y.Offset or 200
        local canvasH = math.max(totalHeight, kfH + 20 + gap + aeH) + 40
        targetContentArea.CanvasSize = UDim2.new(0, 0, 0, canvasH + 20)
    end

    -- ============================================================
    -- ФУНКЦИЯ ОБНОВЛЕНИЯ ИНФОРМАЦИИ
    -- ============================================================
    local infoTask = nil

    local function updateTargetInfo()
        if not selectedTarget then
            targetNameLabel.Text = "No Target Selected"
            targetStatusLabel.Text = "Status: Unknown"
            targetAvatar.Image = ""
            hpStat.Text = "0/0"
            rangeStat.Text = "0.00 Studs"
            pcldStat.Text = "Not Broken"
            return
        end

        local targetPlr = Players:FindFirstChild(selectedTarget)
        if not targetPlr then
            targetNameLabel.Text = selectedTarget .. " (Offline)"
            targetStatusLabel.Text = "Status: Offline"
            targetAvatar.Image = ""
            hpStat.Text = "0/0"
            rangeStat.Text = "0.00 Studs"
            pcldStat.Text = "Not Broken"
            return
        end

        pcall(function()
            local content, isReady = Players:GetUserThumbnailAsync(targetPlr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
            if isReady then
                targetAvatar.Image = content
            end
        end)

        targetNameLabel.Text = targetPlr.DisplayName .. " (" .. targetPlr.Name .. ")"
        
        local randomWord = statusWords[math.random(1, #statusWords)]
        targetStatusLabel.Text = "Status: " .. randomWord
        targetStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

        if infoTask then task.cancel(infoTask) end

        infoTask = task.spawn(function()
            while task.wait(0.3) do
                local char = targetPlr.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                    if hum then
                        hpStat.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                    else
                        hpStat.Text = "0/0"
                    end

                    if hrp and myHrp then
                        local dist = (hrp.Position - myHrp.Position).Magnitude
                        rangeStat.Text = string.format("%.2f Studs", dist)
                    else
                        rangeStat.Text = "0.00 Studs"
                    end

                    local head = char:FindFirstChild("Head")
                    local pcldStatus = "Not Broken"
                    if head then
                        local partOwner = head:FindFirstChild("PartOwner")
                        if partOwner and partOwner.Value ~= "" and partOwner.Value ~= targetPlr.Name then
                            pcldStatus = "Broken"
                        end
                    end
                    pcldStat.Text = pcldStatus
                else
                    hpStat.Text = "0/0"
                    rangeStat.Text = "0.00 Studs"
                    pcldStat.Text = "Not Broken"
                end
            end
        end)

        targetPlr.CharacterAdded:Connect(function()
            task.wait(0.5)
            updateTargetInfo()
        end)
    end

    -- ============================================================
    -- ТОГГЛ ДРОПДАУНА (ИСПРАВЛЕННЫЙ)
    -- ============================================================
    local function GetOnlinePlayers()
        local list = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                table.insert(list, {
                    Name = plr.Name,
                    DisplayName = plr.DisplayName,
                    UserId = plr.UserId
                })
            end
        end
        table.sort(list, function(a, b) return a.Name < b.Name end)
        return list
    end

    local function toggleTargetDropdown()
        if tsAnimating then return end
        
        if tsDropdownOpen then
            -- ЗАКРЫТИЕ: уменьшаем обратно
            tsAnimating = true
            local targetHeight = DROPDOWN_HEIGHT
            
            -- Сначала скрываем контейнер
            if tsContainer then
                tsContainer:Destroy()
                tsContainer = nil
                tsScrollFrame = nil
            end
            
            -- Анимируем уменьшение
            local tween1 = TweenService:Create(selectFriendBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, -gap * 2, 0, targetHeight)
            })
            tween1:Play()
            
            local tween2 = TweenService:Create(targetInfoBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, gap, 0, 52 + targetHeight + gap)
            })
            tween2:Play()
            
            -- Обновляем размер основного фрейма
            local totalHeight = 52 + targetHeight + gap + INFO_HEIGHT + EXTRA_BOTTOM + gap
            local tween3 = TweenService:Create(targetSelectBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 300, 0, totalHeight)
            })
            tween3:Play()
            
            tsDropdownOpen = false
            sfArrow.Text = "▸"
            
            tween1.Completed:Wait()
            tsAnimating = false
            updateHeight()
        else
            -- ОТКРЫТИЕ: увеличиваем вниз
            tsAnimating = true
            tsDropdownOpen = true
            sfArrow.Text = "▾"
            
            -- Создаём контейнер для списка игроков
            tsContainer = Instance.new("Frame")
            tsContainer.Size = UDim2.new(1, 0, 0, 0)
            tsContainer.Position = UDim2.new(0, 0, 0, DROPDOWN_HEIGHT)
            tsContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
            tsContainer.BackgroundTransparency = 1
            tsContainer.ClipsDescendants = true
            tsContainer.ZIndex = 10
            tsContainer.Parent = selectFriendBox

            tsScrollFrame = Instance.new("ScrollingFrame")
            tsScrollFrame.Size = UDim2.new(1, -10, 1, -10)
            tsScrollFrame.Position = UDim2.new(0, 5, 0, 5)
            tsScrollFrame.BackgroundTransparency = 1
            tsScrollFrame.BorderSizePixel = 0
            tsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
            tsScrollFrame.ScrollBarThickness = 4
            tsScrollFrame.ClipsDescendants = true
            tsScrollFrame.Parent = tsContainer

            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 4)
            listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            listLayout.Parent = tsScrollFrame

            task.spawn(function()
                local onlinePlayers = GetOnlinePlayers()
                
                if #onlinePlayers == 0 then
                    local noPlayer = Instance.new("TextButton")
                    noPlayer.Size = UDim2.new(1, -20, 0, 40)
                    noPlayer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                    noPlayer.BackgroundTransparency = 0.2
                    noPlayer.Text = "No players online"
                    noPlayer.TextColor3 = Color3.fromRGB(150, 150, 150)
                    noPlayer.TextSize = 13
                    noPlayer.Font = Enum.Font.GothamBold
                    noPlayer.Parent = tsScrollFrame
                    
                    local btnCorner = Instance.new("UICorner")
                    btnCorner.CornerRadius = UDim.new(0, 14)
                    btnCorner.Parent = noPlayer
                    
                    tsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 50)
                    local listHeight = 50
                    tsContainer.Size = UDim2.new(1, 0, 0, listHeight)
                    local newDropdownHeight = DROPDOWN_HEIGHT + listHeight
                    
                    -- Анимируем увеличение вниз
                    local tween1 = TweenService:Create(selectFriendBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, -gap * 2, 0, newDropdownHeight)
                    })
                    tween1:Play()
                    
                    local tween2 = TweenService:Create(targetInfoBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, gap, 0, 52 + newDropdownHeight + gap)
                    })
                    tween2:Play()
                    
                    local totalHeight = 52 + newDropdownHeight + gap + INFO_HEIGHT + EXTRA_BOTTOM + gap
                    local tween3 = TweenService:Create(targetSelectBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 300, 0, totalHeight)
                    })
                    tween3:Play()
                    
                    updateHeight()
                    tween1.Completed:Wait()
                    tsAnimating = false
                else
                    for _, playerData in ipairs(onlinePlayers) do
                        local playerBtn = Instance.new("TextButton")
                        playerBtn.Size = UDim2.new(1, -10, 0, 36)
                        playerBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                        playerBtn.BackgroundTransparency = 0.2
                        playerBtn.Text = playerData.DisplayName .. " (" .. playerData.Name .. ")"
                        playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        playerBtn.TextSize = 13
                        playerBtn.Font = Enum.Font.GothamBold
                        playerBtn.Parent = tsScrollFrame

                        local btnCorner = Instance.new("UICorner")
                        btnCorner.CornerRadius = UDim.new(0, 14)
                        btnCorner.Parent = playerBtn

                        playerBtn.MouseButton1Click:Connect(function()
                            selectedTarget = playerData.Name
                            sfLabel.Text = "Select Target → " .. playerData.DisplayName .. " (" .. playerData.Name .. ")"
                            updateTargetInfo()
                        end)
                    end

                    local children = tsScrollFrame:GetChildren()
                    local totalHeight = #children * 40 + 10
                    local listHeight = math.min(math.max(totalHeight, 50), 150)
                    tsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(totalHeight, tsScrollFrame.Size.Y.Offset))
                    
                    tsContainer.Size = UDim2.new(1, 0, 0, listHeight)
                    local newDropdownHeight = DROPDOWN_HEIGHT + listHeight
                    
                    -- Анимируем увеличение вниз
                    local tween1 = TweenService:Create(selectFriendBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, -gap * 2, 0, newDropdownHeight)
                    })
                    tween1:Play()
                    
                    local tween2 = TweenService:Create(targetInfoBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, gap, 0, 52 + newDropdownHeight + gap)
                    })
                    tween2:Play()
                    
                    local totalHeight = 52 + newDropdownHeight + gap + INFO_HEIGHT + EXTRA_BOTTOM + gap
                    local tween3 = TweenService:Create(targetSelectBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 300, 0, totalHeight)
                    })
                    tween3:Play()
                    
                    updateHeight()
                    tween1.Completed:Wait()
                    tsAnimating = false
                end
            end)
        end
    end

    sfArrow.MouseButton1Click:Connect(toggleTargetDropdown)
    sfBtn.MouseButton1Click:Connect(function()
        toggleTargetDropdown()
    end)

    updateHeight()

    -- ============================================================
    -- ГРУППА 2: KICK FEATURES
    -- ============================================================
    local kickFeaturesBox = Instance.new("Frame")
    kickFeaturesBox.Size = UDim2.new(0, 300, 0, 0)
    kickFeaturesBox.Position = UDim2.new(0, 300 + 20 + gap, 0, 20)
    kickFeaturesBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    kickFeaturesBox.BackgroundTransparency = 0.25
    kickFeaturesBox.ClipsDescendants = true
    kickFeaturesBox.Parent = targetContentArea

    local kfBoxCorner = Instance.new("UICorner")
    kfBoxCorner.CornerRadius = UDim.new(0, 18)
    kfBoxCorner.Parent = kickFeaturesBox

    local kfBoxStroke = Instance.new("UIStroke")
    kfBoxStroke.Color = Color3.fromRGB(180, 180, 180)
    kfBoxStroke.Transparency = 0.2
    kfBoxStroke.Thickness = 1.0
    kfBoxStroke.Parent = kickFeaturesBox

    local kfTitle = Instance.new("TextLabel")
    kfTitle.Size = UDim2.new(1, -30, 0, 30)
    kfTitle.Position = UDim2.new(0, 15, 0, 8)
    kfTitle.BackgroundTransparency = 1
    kfTitle.TextXAlignment = Enum.TextXAlignment.Left
    kfTitle.Text = "Kick Features"
    kfTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    kfTitle.TextTransparency = 0.05
    kfTitle.TextSize = 16
    kfTitle.Font = Enum.Font.GothamBold
    kfTitle.Parent = kickFeaturesBox

    local kfLine = Instance.new("Frame")
    kfLine.Size = UDim2.new(1, -30, 0, 1.5)
    kfLine.Position = UDim2.new(0, 15, 0, 42)
    kfLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    kfLine.BackgroundTransparency = 0.3
    kfLine.BorderSizePixel = 0
    kfLine.Parent = kickFeaturesBox

    local kfStartY = 52

    -- AUTOSIT BLOBMAN
    local asBox, asBtn, asChk = createToggle(kickFeaturesBox, "AutoSit Blobman", kfStartY)

    local autoSitEnabled = false
    local autoSitTask = nil

    asBtn.MouseButton1Click:Connect(function()
        autoSitEnabled = not autoSitEnabled
        asChk.Visible = autoSitEnabled

        if autoSitEnabled then
            if autoSitTask then task.cancel(autoSitTask) end
            autoSitTask = task.spawn(function()
                while autoSitEnabled do
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    if not hum then
                        task.wait(0.5)
                        continue
                    end

                    local blob = FindBlob()
                    if not blob then
                        blob = SpawnToy("CreatureBlobman")
                        task.wait(0.5)
                        blob = FindBlob()
                    end

                    if blob then
                        local seat = blob:FindFirstChild("VehicleSeat")
                        if seat and not hum.SeatPart then
                            pcall(function()
                                seat:Sit(hum)
                            end)
                        end
                    end

                    task.wait(0.5)
                end
            end)
        else
            if autoSitTask then
                task.cancel(autoSitTask)
                autoSitTask = nil
            end
        end
    end)

    -- LOOPKICK
    local kfStartY2 = kfStartY + 48 + gap
    local kickBox, kickBtn, kickChk = createToggle(kickFeaturesBox, "LoopKick [INIT + PINGY]", kfStartY2)

    local loopRunning = false
    local loopThread = nil
    local loopCounter = 0
    local targetBodyPos = nil
    local FIXED_HEIGHT = 15
    local isPreparing = false
    local targetPlr = nil

    local function getBlob()
        local plr = LocalPlayer
        local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys")
        if inv then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == "CreatureBlobman" then
                    return v
                end
            end
        end
        for _, plot in pairs(Workspace.PlotItems:GetChildren()) do
            if plot.Name ~= "PlayersInPlots" then
                for _, v in pairs(plot:GetChildren()) do
                    if v.Name == "CreatureBlobman" then
                        return v
                    end
                end
            end
        end
        return nil
    end

    local function spawnBlob()
        local SpawnToyRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
        if not SpawnToyRemote then return nil end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local success, result = pcall(function()
            return SpawnToyRemote:InvokeServer("CreatureBlobman", hrp.CFrame * CFrame.new(0, 10, 20), Vector3.zero)
        end)
        return success and result or nil
    end

    local function createHold(targetPart)
        if not targetPart then return end
        
        for _, v in pairs(targetPart:GetChildren()) do
            if v.Name == "KickAtt0" or v.Name == "KickAtt1" or v.Name == "KickAlign" or v.Name == "KickRot" or v.Name == "KickBodyPos" then
                pcall(function() v:Destroy() end)
            end
        end
        
        local att0 = Instance.new("Attachment")
        att0.Name = "KickAtt0"
        att0.Parent = targetPart
        
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        local myAtt = hrp and hrp:FindFirstChild("KickMyAtt")
        if not myAtt and hrp then
            myAtt = Instance.new("Attachment")
            myAtt.Name = "KickMyAtt"
            myAtt.Position = Vector3.new(0, FIXED_HEIGHT, 0)
            myAtt.Parent = hrp
        end
        
        local alignPos = Instance.new("AlignPosition")
        alignPos.Name = "KickAlign"
        alignPos.Attachment0 = att0
        alignPos.Attachment1 = myAtt
        alignPos.MaxForce = math.huge
        alignPos.Responsiveness = 300
        alignPos.RigidityEnabled = true
        alignPos.Parent = targetPart
        
        local alignRot = Instance.new("AlignOrientation")
        alignRot.Name = "KickRot"
        alignRot.Attachment0 = att0
        alignRot.Mode = Enum.OrientationAlignmentMode.OneAttachment
        alignRot.CFrame = CFrame.new()
        alignRot.MaxTorque = math.huge
        alignRot.Responsiveness = 300
        alignRot.RigidityEnabled = true
        alignRot.Parent = targetPart
        
        targetBodyPos = Instance.new("BodyPosition")
        targetBodyPos.Name = "KickBodyPos"
        targetBodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        targetBodyPos.P = 1000000
        targetBodyPos.D = 10000
        if hrp then
            targetBodyPos.Position = hrp.Position + Vector3.new(0, FIXED_HEIGHT, 0)
        else
            targetBodyPos.Position = targetPart.Position + Vector3.new(0, FIXED_HEIGHT, 0)
        end
        targetBodyPos.Parent = targetPart
    end

    local function startLoop()
        if loopRunning then return end
        if not selectedTarget then 
            return
        end
        
        targetPlr = Players:FindFirstChild(selectedTarget)
        if not targetPlr then return end
        
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not char or not hum then return end
        
        local blob = getBlob()
        if not blob then
            blob = spawnBlob()
            if not blob then return end
        end
        
        local seat = blob:FindFirstChild("VehicleSeat")
        if seat and not hum.SeatPart then
            seat:Sit(hum)
        end
        
        local RightDetector = blob:FindFirstChild("RightDetector")
        local RightWeld = RightDetector and RightDetector:FindFirstChild("RightWeld")
        local LeftDetector = blob:FindFirstChild("LeftDetector")
        local LeftWeld = LeftDetector and LeftDetector:FindFirstChild("LeftWeld")
        local scripts = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
        local CreatureGrab = scripts and scripts:FindFirstChild("CreatureGrab")
        local CreatureDrop = scripts and scripts:FindFirstChild("CreatureDrop")
        
        if not RightDetector or not RightWeld or not CreatureGrab or not CreatureDrop then return end
        
        loopRunning = true
        loopCounter = 0
        isPreparing = false
        
        loopThread = task.spawn(function()
            while loopRunning do
                RunService.Heartbeat:Wait()
                
                targetPlr = selectedTarget and Players:FindFirstChild(selectedTarget)
                if not targetPlr then 
                    isPreparing = true
                    continue 
                end
                
                local tRoot = targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart")
                local tHead = targetPlr.Character and targetPlr.Character:FindFirstChild("Head")
                local tHum = targetPlr.Character and targetPlr.Character:FindFirstChild("Humanoid")
                
                if not tRoot or not tHum or tHum.Health == 0 then
                    isPreparing = true
                    targetPlr.CharacterAdded:Wait()
                    task.wait(0.3)
                    tRoot = targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart")
                    tHead = targetPlr.Character and targetPlr.Character:FindFirstChild("Head")
                    tHum = targetPlr.Character and targetPlr.Character:FindFirstChild("Humanoid")
                    
                    if tRoot then
                        if tRoot:FindFirstChild("KickBodyPos1") then
                            tRoot:FindFirstChild("KickBodyPos1"):Destroy()
                        end
                        createHold(tRoot)
                        isPreparing = false
                    end
                    continue
                end
                
                if targetPlr.InPlot and targetPlr.InPlot.Value then continue end 
                if not tRoot then continue end
                
                blob = getBlob()
                if not blob then continue end
                
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                
                local targetPos = hrp.CFrame * CFrame.new(0, FIXED_HEIGHT, 5)
                tRoot.CFrame = targetPos
                tRoot.AssemblyLinearVelocity = Vector3.zero
                tRoot.AssemblyAngularVelocity = Vector3.zero
                
                if not tRoot:FindFirstChild("KickAlign") then
                    createHold(tRoot)
                else
                    if targetBodyPos and targetBodyPos.Parent and hrp then
                        targetBodyPos.Position = hrp.Position + Vector3.new(0, FIXED_HEIGHT, 0)
                    end
                end
                
                CreatureGrab:FireServer(RightDetector, tRoot, RightWeld)
                if LeftWeld then
                    CreatureGrab:FireServer(LeftDetector, tRoot, LeftWeld)
                end
                
                RunService.Heartbeat:Wait()
                
                CreatureDrop:FireServer(RightWeld, tRoot)
                if LeftWeld then
                    CreatureDrop:FireServer(LeftWeld, tRoot)
                end
                
                sno(tRoot)
                RunService.Heartbeat:Wait()
                sno(tRoot)
                RunService.Heartbeat:Wait()
                unsno(tRoot)
                RunService.Heartbeat:Wait()
                sno(tRoot)
                
                loopCounter = loopCounter + 1
            end
        end)
        
        task.spawn(function()
            while loopRunning do
                task.wait(0.1)
            end
            
            if targetPlr and targetPlr.Character then
                local tRoot = targetPlr.Character:FindFirstChild("HumanoidRootPart")
                if tRoot then
                    for _, v in pairs(tRoot:GetChildren()) do
                        if v.Name == "KickAtt0" or v.Name == "KickAtt1" or v.Name == "KickAlign" or v.Name == "KickRot" or v.Name == "KickBodyPos" or v.Name == "KickBodyPos1" then
                            pcall(function() v:Destroy() end)
                        end
                    end
                end
            end
            
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local myAtt = hrp:FindFirstChild("KickMyAtt")
                    if myAtt then myAtt:Destroy() end
                end
            end
            
            if hum then hum.Sit = false end
            kickChk.Visible = false
            loopRunning = false
            loopThread = nil
            targetBodyPos = nil
        end)
    end

    local function stopLoop()
        loopRunning = false
        if loopThread then
            task.cancel(loopThread)
            loopThread = nil
        end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.Sit = false end
        kickChk.Visible = false
        targetBodyPos = nil
    end

    kickBtn.MouseButton1Click:Connect(function()
        if loopRunning then
            stopLoop()
        else
            startLoop()
            kickChk.Visible = true
        end
    end)

    local kfHeight = kfStartY2 + 48 + gap
    kickFeaturesBox.Size = UDim2.new(0, 300, 0, kfHeight)

-- ============================================================
-- ГРУППА 3: AUTO EXPLODE (ПОЛНАЯ РАБОЧАЯ ВЕРСИЯ)
-- ============================================================
local autoExplodeBox = Instance.new("Frame")
autoExplodeBox.Size = UDim2.new(0, 300, 0, 0)
autoExplodeBox.Position = UDim2.new(0, 300 + 20 + gap, 0, kfHeight + 20 + gap)
autoExplodeBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
autoExplodeBox.BackgroundTransparency = 0.25
autoExplodeBox.ClipsDescendants = true
autoExplodeBox.Parent = targetContentArea

local aeBoxCorner = Instance.new("UICorner")
aeBoxCorner.CornerRadius = UDim.new(0, 18)
aeBoxCorner.Parent = autoExplodeBox

local aeBoxStroke = Instance.new("UIStroke")
aeBoxStroke.Color = Color3.fromRGB(180, 180, 180)
aeBoxStroke.Transparency = 0.2
aeBoxStroke.Thickness = 1.0
aeBoxStroke.Parent = autoExplodeBox

local aeTitle = Instance.new("TextLabel")
aeTitle.Size = UDim2.new(1, -30, 0, 30)
aeTitle.Position = UDim2.new(0, 15, 0, 8)
aeTitle.BackgroundTransparency = 1
aeTitle.TextXAlignment = Enum.TextXAlignment.Left
aeTitle.Text = "Auto Explode"
aeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
aeTitle.TextTransparency = 0.05
aeTitle.TextSize = 16
aeTitle.Font = Enum.Font.GothamBold
aeTitle.Parent = autoExplodeBox

local aeLine = Instance.new("Frame")
aeLine.Size = UDim2.new(1, -30, 0, 1.5)
aeLine.Position = UDim2.new(0, 15, 0, 42)
aeLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
aeLine.BackgroundTransparency = 0.3
aeLine.BorderSizePixel = 0
aeLine.Parent = autoExplodeBox

-- ============================================================
-- EXPLOSION TYPE (ДРОПДАУН)
-- ============================================================
local aeStartY = 52

local explosionDisplayNames = {
    "BombMissile",
    "FireworkMissile",
    "BombDarkMatter",
    "BombBalloon",
    "PresentSmall",
    "PresentBig"
}

local TYPE_MAP = {
    ["BombMissile"] = "BombMissile",
    ["FireworkMissile"] = "FireworkMissile",
    ["BombDarkMatter"] = "BombDarkMatter",
    ["BombBalloon"] = "BombBalloon",
    ["PresentSmall"] = "PresentSmall",
    ["PresentBig"] = "PresentBig"
}

local selectedExplosionType = "BombMissile"

local aeDropdownBox = Instance.new("Frame")
aeDropdownBox.Size = UDim2.new(1, -gap * 2, 0, 48)
aeDropdownBox.Position = UDim2.new(0, gap, 0, aeStartY)
aeDropdownBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
aeDropdownBox.BackgroundTransparency = 0.25
aeDropdownBox.ClipsDescendants = true
aeDropdownBox.Parent = autoExplodeBox

local aeDBoxCorner = Instance.new("UICorner")
aeDBoxCorner.CornerRadius = UDim.new(0, 18)
aeDBoxCorner.Parent = aeDropdownBox

local aeDBoxStroke = Instance.new("UIStroke")
aeDBoxStroke.Color = Color3.fromRGB(180, 180, 180)
aeDBoxStroke.Transparency = 0.2
aeDBoxStroke.Thickness = 1.0
aeDBoxStroke.Parent = aeDropdownBox

local aeDBtn = Instance.new("TextButton")
aeDBtn.Size = UDim2.new(1, -24, 0, 36)
aeDBtn.Position = UDim2.new(0, 12, 0, 6)
aeDBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
aeDBtn.BackgroundTransparency = 0.2
aeDBtn.Text = ""
aeDBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
aeDBtn.TextTransparency = 0.05
aeDBtn.TextSize = 13
aeDBtn.Font = Enum.Font.GothamBold
aeDBtn.TextXAlignment = Enum.TextXAlignment.Left
aeDBtn.Parent = aeDropdownBox

local aeDBtnCorner = Instance.new("UICorner")
aeDBtnCorner.CornerRadius = UDim.new(0, 14)
aeDBtnCorner.Parent = aeDBtn

local aeDBtnStroke = Instance.new("UIStroke")
aeDBtnStroke.Color = Color3.fromRGB(180, 180, 180)
aeDBtnStroke.Transparency = 0.2
aeDBtnStroke.Thickness = 0.8
aeDBtnStroke.Parent = aeDBtn

local aeDLabel = Instance.new("TextLabel")
aeDLabel.Size = UDim2.new(1, -40, 1, 0)
aeDLabel.Position = UDim2.new(0, 17, 0, 0)
aeDLabel.BackgroundTransparency = 1
aeDLabel.TextXAlignment = Enum.TextXAlignment.Left
aeDLabel.Text = "Explosion Type → BombMissile"
aeDLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
aeDLabel.TextTransparency = 0.05
aeDLabel.TextSize = 13
aeDLabel.Font = Enum.Font.GothamBold
aeDLabel.Parent = aeDBtn

local aeDArrow = Instance.new("TextButton")
aeDArrow.Size = UDim2.new(0, 30, 1, 0)
aeDArrow.AnchorPoint = Vector2.new(1, 0.5)
aeDArrow.Position = UDim2.new(1, -12, 0.5, 0)
aeDArrow.BackgroundTransparency = 1
aeDArrow.Text = "▸"
aeDArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
aeDArrow.TextTransparency = 0.3
aeDArrow.TextSize = 16
aeDArrow.Font = Enum.Font.GothamBold
aeDArrow.Parent = aeDBtn

local aeToggleY = aeStartY + 48 + gap
local aeToggleBox, aeTogToggleBtn, aeTogCheckmark = createToggle(autoExplodeBox, "Enable Explosion", aeToggleY)

local aeDropdownOpen = false
local aeContainer = nil
local aeScrollFrame = nil
local aeAnimating = false

local function updateAeHeight()
    local aeHeight
    if aeDropdownOpen then
        aeHeight = aeStartY + (aeDropdownBox.Size.Y.Offset or 48) + gap + 48 + gap
    else
        aeHeight = aeStartY + 48 + gap + 48 + gap
    end
    autoExplodeBox.Size = UDim2.new(0, 300, 0, aeHeight)
    
    local tsHeight = targetSelectBox.Size.Y.Offset or 400
    local totalHeight = math.max(tsHeight, kfHeight + 20 + gap + aeHeight) + 40
    targetContentArea.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)
end

local function toggleAeDropdown()
    if aeAnimating then return end
    
    if aeDropdownOpen then
        aeAnimating = true
        
        local targetHeight = 48
        
        local tween1 = TweenService:Create(aeDropdownBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -gap * 2, 0, targetHeight)
        })
        local tween2 = TweenService:Create(aeToggleBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, gap, 0, aeStartY + targetHeight + gap)
        })
        local newHeight = aeStartY + targetHeight + gap + 48 + gap
        local tween3 = TweenService:Create(autoExplodeBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 300, 0, newHeight)
        })
        
        tween1:Play()
        tween2:Play()
        tween3:Play()
        updateAeHeight()
        tween1.Completed:Wait()
        
        if aeContainer then
            aeContainer:Destroy()
            aeContainer = nil
            aeScrollFrame = nil
        end
        
        aeDropdownOpen = false
        aeDArrow.Text = "▸"
        aeAnimating = false
    else
        aeAnimating = true
        aeDropdownOpen = true
        aeDArrow.Text = "▾"
        
        aeContainer = Instance.new("Frame")
        aeContainer.Size = UDim2.new(1, 0, 0, 0)
        aeContainer.Position = UDim2.new(0, 0, 0, 48)
        aeContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        aeContainer.BackgroundTransparency = 1
        aeContainer.ClipsDescendants = true
        aeContainer.ZIndex = 10
        aeContainer.Parent = aeDropdownBox

        aeScrollFrame = Instance.new("ScrollingFrame")
        aeScrollFrame.Size = UDim2.new(1, -10, 1, -10)
        aeScrollFrame.Position = UDim2.new(0, 5, 0, 5)
        aeScrollFrame.BackgroundTransparency = 1
        aeScrollFrame.BorderSizePixel = 0
        aeScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        aeScrollFrame.ScrollBarThickness = 4
        aeScrollFrame.ClipsDescendants = true
        aeScrollFrame.Parent = aeContainer

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 4)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.Parent = aeScrollFrame

        for _, displayName in ipairs(explosionDisplayNames) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -10, 0, 36)
            optBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            optBtn.BackgroundTransparency = 0.2
            optBtn.Text = displayName
            optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            optBtn.TextSize = 13
            optBtn.Font = Enum.Font.GothamBold
            optBtn.TextXAlignment = Enum.TextXAlignment.Center
            optBtn.Parent = aeScrollFrame

            local optCorner = Instance.new("UICorner")
            optCorner.CornerRadius = UDim.new(0, 14)
            optCorner.Parent = optBtn

            optBtn.MouseButton1Click:Connect(function()
                selectedExplosionType = TYPE_MAP[displayName] or "BombMissile"
                aeDLabel.Text = "Explosion Type → " .. displayName
            end)
        end

        local children = aeScrollFrame:GetChildren()
        local totalHeight = #children * 40 + 10
        local listHeight = math.min(math.max(totalHeight, 50), 150)
        aeScrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(totalHeight, aeScrollFrame.Size.Y.Offset))
        
        aeContainer.Size = UDim2.new(1, 0, 0, listHeight)
        
        local targetHeight = 48 + listHeight
        
        local tween1 = TweenService:Create(aeDropdownBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -gap * 2, 0, targetHeight)
        })
        local tween2 = TweenService:Create(aeToggleBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, gap, 0, aeStartY + targetHeight + gap)
        })
        local newHeight = aeStartY + targetHeight + gap + 48 + gap
        local tween3 = TweenService:Create(autoExplodeBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 300, 0, newHeight)
        })
        
        tween1:Play()
        tween2:Play()
        tween3:Play()
        updateAeHeight()
        tween1.Completed:Wait()
        aeAnimating = false
    end
end

aeDArrow.MouseButton1Click:Connect(toggleAeDropdown)
aeDBtn.MouseButton1Click:Connect(function()
    toggleAeDropdown()
end)

-- ============================================================
-- ЛОГИКА AUTO EXPLODE (РАБОЧАЯ ИЗ ТВОЕГО СКРИПТА)
-- ============================================================
local autoExplodeEnabled = false
local autoExplodeTask = nil
local _expTarget = nil

local BombEvents = ReplicatedStorage:FindFirstChild("BombEvents")
local SpawnToyRF = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
local DeleteToyRE = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
local SetNetworkOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")

local HitboxNames = {
    BombMissile = 'PartHitDetector',
    BombDarkMatter = 'PartHitDetector',
    FireworkMissile = 'PartHitDetector',
    BombBalloon = 'Balloon',
    PresentBig = 'Box',
    PresentSmall = 'Box',
}

local function GetSpawnedToys()
    return Workspace:FindFirstChild(LocalPlayer.Name .. 'SpawnedInToys')
end

local function GetAllBombs()
    local toys = GetSpawnedToys()
    if not toys then return {} end
    local bombs = {}
    for _, toy in pairs(toys:GetChildren()) do
        if toy.Name == selectedExplosionType then
            table.insert(bombs, toy)
        end
    end
    return bombs
end

local function DeleteAllBombs()
    for _, bomb in pairs(GetAllBombs()) do
        pcall(function()
            if DeleteToyRE then
                DeleteToyRE:FireServer(bomb)
            end
        end)
    end
end

local function SpawNoneBomb()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and SpawnToyRF then
        pcall(function()
            SpawnToyRF:InvokeServer(selectedExplosionType, CFrame.new(hrp.Position + Vector3.new(0, 5, 0)), Vector3.zero)
        end)
    end
end

local function ExplodeBomb(bomb, targetHRP)
    if not bomb or not targetHRP then return end
    
    local hitbox = bomb:FindFirstChild(HitboxNames[bomb.Name])
    if hitbox then
        pcall(function()
            BombEvents.BombExplode:FireServer({
                Hitbox = hitbox,
                PositionPart = targetHRP,
            }, targetHRP.Position)
        end)
    end
end

local function ExpGetTargetHRP()
    if not _expTarget then return nil, nil end
    local p = Players:FindFirstChild(_expTarget)
    if p and p.Character and p.Character:FindFirstChild('HumanoidRootPart') then
        return p.Character.HumanoidRootPart, p
    end
    return nil, nil
end

local function AutoExplosionLoop()
    while autoExplodeEnabled do
        local targetHRP, targetPlayer = ExpGetTargetHRP()
        if not targetPlayer then
            autoExplodeEnabled = false
            aeTogCheckmark.Visible = false
            break
        end
        if not targetHRP then
            task.wait(0.2)
            continue
        end
        
        DeleteAllBombs()
        task.wait(0.05)
        
        -- Спавним 1 бомбу
        SpawNoneBomb()
        task.wait(0.05)
        
        task.wait(0.1)
        
        -- Берём бомбу и взрываем
        local bombs = GetAllBombs()
        for _, bomb in pairs(bombs) do
            if not autoExplodeEnabled then break end
            ExplodeBomb(bomb, targetHRP)
            task.wait(0.01)
        end
        
        task.wait(0.1)
        DeleteAllBombs()
        task.wait(0.05)
    end
end

-- Подключаем кнопку
aeTogToggleBtn.MouseButton1Click:Connect(function()
    autoExplodeEnabled = not autoExplodeEnabled
    aeTogCheckmark.Visible = autoExplodeEnabled
    
    if autoExplodeEnabled then
        if not selectedTarget then
            _expTarget = nil
            autoExplodeEnabled = false
            aeTogCheckmark.Visible = false
            return
        end
        _expTarget = selectedTarget
        if autoExplodeTask then
            task.cancel(autoExplodeTask)
        end
        autoExplodeTask = task.spawn(AutoExplosionLoop)
    else
        if autoExplodeTask then
            task.cancel(autoExplodeTask)
            autoExplodeTask = nil
        end
        DeleteAllBombs()
    end
end)

    -- ============================================================
    -- ФИНАЛЬНЫЕ РАЗМЕРЫ
    -- ============================================================
    updateHeight()
    updateAeHeight()
    
    task.wait(0.5)
    updateTargetInfo()
end
-- ============================================================================
-- BUILD UI (С ИКОНКАМИ В INFORMATION И FUN)
-- ============================================================================
local function buildUI()
	local playerGui = player:WaitForChild("PlayerGui")
	task.wait(0.1)

	if playerGui:FindFirstChild("ColorPickerMenu") then
		playerGui.ColorPickerMenu:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ColorPickerMenu"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ClipsDescendants = true
	frame.Active = true
	frame.Parent = screenGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 22)
	uiCorner.Parent = frame

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(180, 180, 180)
	uiStroke.Transparency = 0.2
	uiStroke.Thickness = 1.0
	uiStroke.Parent = frame

	local titleIcon = Instance.new("ImageLabel")
	titleIcon.Size = UDim2.new(0, 21, 0, 21)
	titleIcon.Position = UDim2.new(0, 20, 0, 13)
	titleIcon.BackgroundTransparency = 1
	titleIcon.Image = "rbxassetid://88920743218673"
	titleIcon.ScaleType = Enum.ScaleType.Fit
	titleIcon.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 35)
	title.Position = UDim2.new(0, 50, 0, 4)
	title.BackgroundTransparency = 1
	title.Text = "Synapse"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextTransparency = 0.05
	title.TextSize = 22
	title.Font = Enum.Font.FredokaOne
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	dragging, dragInput, dragStart, startPos = false, nil, nil, nil
	resizing, resizeStart, startMousePos = false, nil, nil

	title.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not resizing then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			resizing = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	isTweening = false

	local leftSidebar = Instance.new("Frame")
	leftSidebar.Size = UDim2.new(0, 180, 1, -133)
	leftSidebar.Position = UDim2.new(0, 10, 0, 45)
	leftSidebar.BackgroundTransparency = 1
	leftSidebar.ClipsDescendants = true
	leftSidebar.Parent = frame

	local sidebarCorner = Instance.new("UICorner")
	sidebarCorner.CornerRadius = UDim.new(0, 18)
	sidebarCorner.Parent = leftSidebar

	local sidebarStroke = Instance.new("UIStroke")
	sidebarStroke.Color = Color3.fromRGB(180, 180, 180)
	sidebarStroke.Transparency = 0.2
	sidebarStroke.Thickness = 1.0
	sidebarStroke.Parent = leftSidebar

	local bottomStroke = Instance.new("Frame")
	bottomStroke.Size = UDim2.new(1, 0, 0, 1)
	bottomStroke.Position = UDim2.new(0, 0, 1, 4)
	bottomStroke.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
	bottomStroke.BackgroundTransparency = 0.2
	bottomStroke.BorderSizePixel = 0
	bottomStroke.Parent = leftSidebar

	local dividerLine = Instance.new("Frame")
	dividerLine.Size = UDim2.new(0, 1, 1, 0)
	dividerLine.Position = UDim2.new(1, 0, 0, 0)
	dividerLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
	dividerLine.BackgroundTransparency = 0.2
	dividerLine.BorderSizePixel = 0
	dividerLine.Parent = leftSidebar

	local extraBottomSidebar = Instance.new("Frame")
	extraBottomSidebar.Size = UDim2.new(0, 180, 0, 60)
	extraBottomSidebar.Position = UDim2.new(0, 10, 1, -71.5) 
	extraBottomSidebar.BackgroundTransparency = 1
	extraBottomSidebar.ClipsDescendants = false
	extraBottomSidebar.ZIndex = 5
	extraBottomSidebar.Parent = frame

	local extraCorner = Instance.new("UICorner")
	extraCorner.CornerRadius = UDim.new(0, 18)
	extraCorner.Parent = extraBottomSidebar

	local extraStroke = Instance.new("UIStroke")
	extraStroke.Color = Color3.fromRGB(180, 180, 180)
	extraStroke.Transparency = 0.2
	extraStroke.Thickness = 1.0
	extraStroke.Parent = extraBottomSidebar

	local bottomCircle = Instance.new("Frame")
	bottomCircle.Size = UDim2.new(0, 44, 0, 44)
	bottomCircle.Position = UDim2.new(0, 12, 0.5, 0)
	bottomCircle.AnchorPoint = Vector2.new(0, 0.5)
	bottomCircle.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	bottomCircle.BackgroundTransparency = 0.2
	bottomCircle.BorderSizePixel = 0
	bottomCircle.ZIndex = 6
	bottomCircle.Parent = extraBottomSidebar

	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = bottomCircle

	local circleStroke = Instance.new("UIStroke")
	circleStroke.Color = Color3.fromRGB(180, 180, 180)
	circleStroke.Transparency = 0.2
	circleStroke.Thickness = 1.0
	circleStroke.Parent = bottomCircle

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Size = UDim2.new(1, 0, 1, 0)
	avatarImage.BackgroundTransparency = 1
	avatarImage.ScaleType = Enum.ScaleType.Fit
	avatarImage.ZIndex = 7
	avatarImage.Parent = bottomCircle

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatarImage

	pcall(function()
		local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		if isReady then
			avatarImage.Image = content
		end
	end)

	local playerNameLabel = Instance.new("TextLabel")
	playerNameLabel.Size = UDim2.new(1, -66, 0, 20)
	playerNameLabel.Position = UDim2.new(0, 62, 0, 12)
	playerNameLabel.BackgroundTransparency = 1
	playerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	playerNameLabel.Text = player.DisplayName
	playerNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	playerNameLabel.TextSize = 13
	playerNameLabel.Font = Enum.Font.GothamBold
	playerNameLabel.ZIndex = 6
	playerNameLabel.Parent = extraBottomSidebar

	local playerUserLabel = Instance.new("TextLabel")
	playerUserLabel.Size = UDim2.new(1, -66, 0, 16)
	playerUserLabel.Position = UDim2.new(0, 62, 0, 31)
	playerUserLabel.BackgroundTransparency = 1
	playerUserLabel.TextXAlignment = Enum.TextXAlignment.Left
	playerUserLabel.Text = "@" .. player.Name
	playerUserLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	playerUserLabel.TextSize = 11
	playerUserLabel.Font = Enum.Font.Gotham
	playerUserLabel.ZIndex = 6
	playerUserLabel.Parent = extraBottomSidebar

	local resizeBtn = Instance.new("ImageButton")
	resizeBtn.Size = UDim2.new(0, 24, 0, 24)
	resizeBtn.AnchorPoint = Vector2.new(1, 1)
	resizeBtn.Position = UDim2.new(1, -8, 1, -8)
	resizeBtn.BackgroundTransparency = 1
	resizeBtn.Image = "rbxassetid://10871444339"
	resizeBtn.ImageTransparency = 0.05
	resizeBtn.ZIndex = 6
	resizeBtn.Parent = frame

	local MIN_WIDTH = 850
	local MAX_WIDTH = 1090
	local DEFAULT_WIDTH = 980
	local MIN_HEIGHT = 500
	local MAX_HEIGHT = 700
	local DEFAULT_HEIGHT = 590

	frame.Size = UDim2.new(0, DEFAULT_WIDTH, 0, DEFAULT_HEIGHT)

	resizeBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			dragging = false
			resizeStart = frame.AbsoluteSize
			startMousePos = input.Position
		end
	end)

	local closeMenuWrapper = Instance.new("Frame")
	closeMenuWrapper.Size = UDim2.new(0, 30, 0, 30)
	closeMenuWrapper.AnchorPoint = Vector2.new(1, 0)
	closeMenuWrapper.Position = UDim2.new(1, -15, 0, 12)
	closeMenuWrapper.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	closeMenuWrapper.BackgroundTransparency = 0.3
	closeMenuWrapper.ZIndex = 9
	closeMenuWrapper.Parent = frame

	local closeWrapperCorner = Instance.new("UICorner")
	closeWrapperCorner.CornerRadius = UDim.new(0, 8)
	closeWrapperCorner.Parent = closeMenuWrapper

	local closeWrapperStroke = Instance.new("UIStroke")
	closeWrapperStroke.Color = Color3.fromRGB(180, 180, 180)
	closeWrapperStroke.Transparency = 0.2
	closeWrapperStroke.Thickness = 0.8
	closeWrapperStroke.Parent = closeMenuWrapper

	local closeMenuBtn = Instance.new("ImageButton")
	closeMenuBtn.Size = UDim2.new(0, 17, 0, 17)
	closeMenuBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	closeMenuBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
	closeMenuBtn.BackgroundTransparency = 1
	closeMenuBtn.Image = "rbxassetid://105653924684433"
	closeMenuBtn.ImageTransparency = 0
	closeMenuBtn.ZIndex = 10
	closeMenuBtn.Parent = closeMenuWrapper

	-- ОСНОВНЫЕ ОБЛАСТИ ДЛЯ ВКЛАДОК
	local infoContentArea = Instance.new("ScrollingFrame")
	infoContentArea.Size = UDim2.new(1, -210, 1, -55)
	infoContentArea.Position = UDim2.new(0, 200, 0, 45)
	infoContentArea.BackgroundTransparency = 1
	infoContentArea.BorderSizePixel = 0
	infoContentArea.CanvasSize = UDim2.new(0, 0, 0, 690)
	infoContentArea.ScrollBarThickness = 8
	infoContentArea.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
	infoContentArea.ScrollBarImageTransparency = 1
	infoContentArea.ClipsDescendants = true
	infoContentArea.Visible = false
	infoContentArea.Parent = frame

	local infoAreaCorner = Instance.new("UICorner")
	infoAreaCorner.CornerRadius = UDim.new(0, 18)
	infoAreaCorner.Parent = infoContentArea

	local infoAreaStroke = Instance.new("UIStroke")
	infoAreaStroke.Color = Color3.fromRGB(180, 180, 180)
	infoAreaStroke.Transparency = 0.2
	infoAreaStroke.Thickness = 1.0
	infoAreaStroke.Parent = infoContentArea

	local mainContentArea = Instance.new("ScrollingFrame")
	mainContentArea.Size = UDim2.new(1, -210, 1, -55)
	mainContentArea.Position = UDim2.new(0, 200, 0, 45)
	mainContentArea.BackgroundTransparency = 1
	mainContentArea.BorderSizePixel = 0
	mainContentArea.CanvasSize = UDim2.new(0, 0, 0, 750)
	mainContentArea.ScrollBarThickness = 8
	mainContentArea.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
	mainContentArea.ScrollBarImageTransparency = 0.2
	mainContentArea.ClipsDescendants = true
	mainContentArea.Visible = true
	mainContentArea.Parent = frame

	local mainAreaCorner = Instance.new("UICorner")
	mainAreaCorner.CornerRadius = UDim.new(0, 18)
	mainAreaCorner.Parent = mainContentArea

	local mainAreaStroke = Instance.new("UIStroke")
	mainAreaStroke.Color = Color3.fromRGB(180, 180, 180)
	mainAreaStroke.Transparency = 0.2
	mainAreaStroke.Thickness = 1.0
	mainAreaStroke.Parent = mainContentArea

	local playerContentArea = Instance.new("ScrollingFrame")
	playerContentArea.Size = UDim2.new(1, -210, 1, -55)
	playerContentArea.Position = UDim2.new(0, 200, 0, 45)
	playerContentArea.BackgroundTransparency = 1
	playerContentArea.BorderSizePixel = 0
	playerContentArea.CanvasSize = UDim2.new(0, 0, 0, 690)
	playerContentArea.ScrollBarThickness = 8
	playerContentArea.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
	playerContentArea.ScrollBarImageTransparency = 1
	playerContentArea.ClipsDescendants = true
	playerContentArea.Visible = false
	playerContentArea.Parent = frame

	local playerAreaCorner = Instance.new("UICorner")
	playerAreaCorner.CornerRadius = UDim.new(0, 18)
	playerAreaCorner.Parent = playerContentArea

	local playerAreaStroke = Instance.new("UIStroke")
	playerAreaStroke.Color = Color3.fromRGB(180, 180, 180)
	playerAreaStroke.Transparency = 0.2
	playerAreaStroke.Thickness = 1.0
	playerAreaStroke.Parent = playerContentArea

	local defenseContentArea = Instance.new("ScrollingFrame")
	defenseContentArea.Size = UDim2.new(1, -210, 1, -55)
	defenseContentArea.Position = UDim2.new(0, 200, 0, 45)
	defenseContentArea.BackgroundTransparency = 1
	defenseContentArea.BorderSizePixel = 0
	defenseContentArea.CanvasSize = UDim2.new(0, 0, 0, 690)
	defenseContentArea.ScrollBarThickness = 8
	defenseContentArea.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
	defenseContentArea.ScrollBarImageTransparency = 1
	defenseContentArea.ClipsDescendants = true
	defenseContentArea.Visible = false
	defenseContentArea.Parent = frame

	local defenseAreaCorner = Instance.new("UICorner")
	defenseAreaCorner.CornerRadius = UDim.new(0, 18)
	defenseAreaCorner.Parent = defenseContentArea

	local defenseAreaStroke = Instance.new("UIStroke")
	defenseAreaStroke.Color = Color3.fromRGB(180, 180, 180)
	defenseAreaStroke.Transparency = 0.2
	defenseAreaStroke.Thickness = 1.0
	defenseAreaStroke.Parent = defenseContentArea

	local targetContentArea = Instance.new("ScrollingFrame")
	targetContentArea.Size = UDim2.new(1, -210, 1, -55)
	targetContentArea.Position = UDim2.new(0, 200, 0, 45)
	targetContentArea.BackgroundTransparency = 1
	targetContentArea.BorderSizePixel = 0
	targetContentArea.CanvasSize = UDim2.new(0, 0, 0, 690)
	targetContentArea.ScrollBarThickness = 8
	targetContentArea.ScrollBarImageTransparency = 1
	targetContentArea.ClipsDescendants = true
	targetContentArea.Visible = false
	targetContentArea.Parent = frame

	local targetAreaCorner = Instance.new("UICorner")
	targetAreaCorner.CornerRadius = UDim.new(0, 18)
	targetAreaCorner.Parent = targetContentArea

	local targetAreaStroke = Instance.new("UIStroke")
	targetAreaStroke.Color = Color3.fromRGB(180, 180, 180)
	targetAreaStroke.Transparency = 0.2
	targetAreaStroke.Thickness = 1.0
	targetAreaStroke.Parent = targetContentArea

	local grabsContentArea = Instance.new("ScrollingFrame")
	grabsContentArea.Size = UDim2.new(1, -210, 1, -55)
	grabsContentArea.Position = UDim2.new(0, 200, 0, 45)
	grabsContentArea.BackgroundTransparency = 1
	grabsContentArea.BorderSizePixel = 0
	grabsContentArea.CanvasSize = UDim2.new(0, 0, 0, 690)
	grabsContentArea.ScrollBarThickness = 8
	grabsContentArea.ScrollBarImageTransparency = 1
	grabsContentArea.ClipsDescendants = true
	grabsContentArea.Visible = false
	grabsContentArea.Parent = frame

	local grabsAreaCorner = Instance.new("UICorner")
	grabsAreaCorner.CornerRadius = UDim.new(0, 18)
	grabsAreaCorner.Parent = grabsContentArea

	local grabsAreaStroke = Instance.new("UIStroke")
	grabsAreaStroke.Color = Color3.fromRGB(180, 180, 180)
	grabsAreaStroke.Transparency = 0.2
	grabsAreaStroke.Thickness = 1.0
	grabsAreaStroke.Parent = grabsContentArea

	local funContentArea = Instance.new("ScrollingFrame")
	funContentArea.Size = UDim2.new(1, -210, 1, -55)
	funContentArea.Position = UDim2.new(0, 200, 0, 45)
	funContentArea.BackgroundTransparency = 1
	funContentArea.BorderSizePixel = 0
	funContentArea.CanvasSize = UDim2.new(0, 0, 0, 690)
	funContentArea.ScrollBarThickness = 8
	funContentArea.ScrollBarImageTransparency = 1
	funContentArea.ClipsDescendants = true
	funContentArea.Visible = false
	funContentArea.Parent = frame

	local funAreaCorner = Instance.new("UICorner")
	funAreaCorner.CornerRadius = UDim.new(0, 18)
	funAreaCorner.Parent = funContentArea

	local funAreaStroke = Instance.new("UIStroke")
	funAreaStroke.Color = Color3.fromRGB(180, 180, 180)
	funAreaStroke.Transparency = 0.2
	funAreaStroke.Thickness = 1.0
	funAreaStroke.Parent = funContentArea

	local miscContentArea = Instance.new("ScrollingFrame")
	miscContentArea.Size = UDim2.new(1, -210, 1, -55)
	miscContentArea.Position = UDim2.new(0, 200, 0, 45)
	miscContentArea.BackgroundTransparency = 1
	miscContentArea.BorderSizePixel = 0
	miscContentArea.CanvasSize = UDim2.new(0, 0, 0, 690)
	miscContentArea.ScrollBarThickness = 8
	miscContentArea.ScrollBarImageTransparency = 1
	miscContentArea.ClipsDescendants = true
	miscContentArea.Visible = false
	miscContentArea.Parent = frame

	local miscAreaCorner = Instance.new("UICorner")
	miscAreaCorner.CornerRadius = UDim.new(0, 18)
	miscAreaCorner.Parent = miscContentArea

	local miscAreaStroke = Instance.new("UIStroke")
	miscAreaStroke.Color = Color3.fromRGB(180, 180, 180)
	miscAreaStroke.Transparency = 0.2
	miscAreaStroke.Thickness = 1.0
	miscAreaStroke.Parent = miscContentArea

	local uiSettingsContentArea = Instance.new("ScrollingFrame")
	uiSettingsContentArea.Size = UDim2.new(1, -210, 1, -55)
	uiSettingsContentArea.Position = UDim2.new(0, 200, 0, 45)
	uiSettingsContentArea.BackgroundTransparency = 1
	uiSettingsContentArea.BorderSizePixel = 0
	uiSettingsContentArea.CanvasSize = UDim2.new(0, 0, 0, 690)
	uiSettingsContentArea.ScrollBarThickness = 8
	uiSettingsContentArea.ScrollBarImageTransparency = 1
	uiSettingsContentArea.ClipsDescendants = true
	uiSettingsContentArea.Visible = false
	uiSettingsContentArea.Parent = frame

	local uiSettingsAreaCorner = Instance.new("UICorner")
	uiSettingsAreaCorner.CornerRadius = UDim.new(0, 18)
	uiSettingsAreaCorner.Parent = uiSettingsContentArea

	local uiSettingsAreaStroke = Instance.new("UIStroke")
	uiSettingsAreaStroke.Color = Color3.fromRGB(180, 180, 180)
	uiSettingsAreaStroke.Transparency = 0.2
	uiSettingsAreaStroke.Thickness = 1.0
	uiSettingsAreaStroke.Parent = uiSettingsContentArea

	-- ============================================================================
-- SETUP EMPTY TAB (С ИКОНКОЙ СЛЕВА ОТ НАДПИСИ)
-- ============================================================================
local function setupEmptyTab(contentArea, titleText, imageId)
	local placeholderBox = Instance.new("Frame")
	placeholderBox.Size = UDim2.new(0, 280, 0, 80)
	placeholderBox.Position = UDim2.new(0, 20, 0, 20)
	placeholderBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	placeholderBox.BackgroundTransparency = 0.25
	placeholderBox.ClipsDescendants = true
	placeholderBox.Parent = contentArea

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 18)
	boxCorner.Parent = placeholderBox

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Color3.fromRGB(180, 180, 180)
	boxStroke.Transparency = 0.2
	boxStroke.Thickness = 1.0
	boxStroke.Parent = placeholderBox

	-- КОНТЕЙНЕР ДЛЯ ИКОНКИ И ТЕКСТА
	local titleContainer = Instance.new("Frame")
	titleContainer.Size = UDim2.new(1, -30, 0, 30)
	titleContainer.Position = UDim2.new(0, 15, 0, 12)
	titleContainer.BackgroundTransparency = 1
	titleContainer.Parent = placeholderBox

	-- ИКОНКА СЛЕВА ОТ НАДПИСИ (как в Visuals)
	if imageId then
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0, 22, 0, 22)
		icon.Position = UDim2.new(0, 0, 0.5, -11)
		icon.BackgroundTransparency = 1
		icon.Image = "rbxassetid://" .. imageId
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Parent = titleContainer

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -30, 1, 0)
		title.Position = UDim2.new(0, 28, 0, 0)
		title.BackgroundTransparency = 1
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = titleText
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextTransparency = 0.05
		title.TextSize = 16
		title.Font = Enum.Font.GothamBold
		title.Parent = titleContainer
	else
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 1, 0)
		title.Position = UDim2.new(0, 0, 0, 0)
		title.BackgroundTransparency = 1
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = titleText
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextTransparency = 0.05
		title.TextSize = 16
		title.Font = Enum.Font.GothamBold
		title.Parent = titleContainer
	end

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -40, 0, 25)
	subtitle.Position = UDim2.new(0, 15, 0, 40)
	subtitle.BackgroundTransparency = 1
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Text = "Coming Soon"
	subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
	subtitle.TextSize = 12
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = placeholderBox
end

	-- ============================================================
	-- НАСТРОЙКА ВКЛАДОК
	-- ============================================================
	setupEmptyTab(infoContentArea, "Information", "79283066206748")
	setupVisualsTab(mainContentArea)
	setupPlayerTab(playerContentArea)
	setupDefenseTab(defenseContentArea)
	setupTargetTab(targetContentArea)
	setupGrabsTab(grabsContentArea)
	setupFunTab(funContentArea)
	setupMiscTab(miscContentArea)
	setupEmptyTab(uiSettingsContentArea, "UI Settings", nil)

	-- Флаги активных вкладок
	activeTabIsInfo = false
	activeTabIsVisuals = true
	activeTabIsPlayer = false
	activeTabIsDefense = false
	activeTabIsTarget = false
	activeTabIsGrabs = false
	activeTabIsFun = false
	activeTabIsMisc = false
	activeTabIsUISettings = false

	local function updateMenuState(isOpen)
		if isTweening then return end
		isTweening = true

		if isOpen then
			frame.Visible = true
			frame.Size = UDim2.new(0, 0, 0, 0)
			leftSidebar.Visible = true
			extraBottomSidebar.Visible = true

			if activeTabIsInfo then
				infoContentArea.Visible = true
				infoContentArea.Position = UDim2.new(0, 200, 0, 45)
				infoContentArea.ScrollBarImageTransparency = 0.2
			elseif activeTabIsVisuals then
				mainContentArea.Visible = true
				mainContentArea.Position = UDim2.new(0, 200, 0, 45)
				mainContentArea.ScrollBarImageTransparency = 0.2
			elseif activeTabIsPlayer then
				playerContentArea.Visible = true
				playerContentArea.Position = UDim2.new(0, 200, 0, 45)
				playerContentArea.ScrollBarImageTransparency = 0.2
			elseif activeTabIsDefense then
				defenseContentArea.Visible = true
				defenseContentArea.Position = UDim2.new(0, 200, 0, 45)
				defenseContentArea.ScrollBarImageTransparency = 0.2
			elseif activeTabIsTarget then
				targetContentArea.Visible = true
				targetContentArea.Position = UDim2.new(0, 200, 0, 45)
				targetContentArea.ScrollBarImageTransparency = 0.2
			elseif activeTabIsGrabs then
				grabsContentArea.Visible = true
				grabsContentArea.Position = UDim2.new(0, 200, 0, 45)
				grabsContentArea.ScrollBarImageTransparency = 0.2
			elseif activeTabIsFun then
				funContentArea.Visible = true
				funContentArea.Position = UDim2.new(0, 200, 0, 45)
				funContentArea.ScrollBarImageTransparency = 0.2
			elseif activeTabIsMisc then
				miscContentArea.Visible = true
				miscContentArea.Position = UDim2.new(0, 200, 0, 45)
				miscContentArea.ScrollBarImageTransparency = 0.2
			elseif activeTabIsUISettings then
				uiSettingsContentArea.Visible = true
				uiSettingsContentArea.Position = UDim2.new(0, 200, 0, 45)
				uiSettingsContentArea.ScrollBarImageTransparency = 0.2
			end

			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true

			local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local tween = TweenService:Create(frame, tweenInfo, { Size = UDim2.new(0, DEFAULT_WIDTH, 0, DEFAULT_HEIGHT) })
			tween:Play()
			tween.Completed:Wait()

			isTweening = false
		else
			infoContentArea.Visible = false
			mainContentArea.Visible = false
			playerContentArea.Visible = false
			defenseContentArea.Visible = false
			targetContentArea.Visible = false
			grabsContentArea.Visible = false
			funContentArea.Visible = false
			miscContentArea.Visible = false
			uiSettingsContentArea.Visible = false
			leftSidebar.Visible = false
			extraBottomSidebar.Visible = false

			local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
			local tween = TweenService:Create(frame, tweenInfo, { Size = UDim2.new(0, 0, 0, 0) })
			tween:Play()
			tween.Completed:Wait()
			
			frame.Visible = false
			frame.Size = UDim2.new(0, DEFAULT_WIDTH, 0, DEFAULT_HEIGHT)
			
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false

			isTweening = false
		end
	end

	closeMenuWrapper.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			updateMenuState(false)
		end
	end)
	closeMenuBtn.MouseButton1Click:Connect(function()
		updateMenuState(false)
	end)

-- ============================================================
-- ВКЛАДКИ С ФРЕЙМАМИ (С ИКОНКАМИ)
-- ============================================================
local function createSidebarItem(name, iconId, posY, iconSizeX, iconSizeY)
	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 165, 0, 44)
	box.Position = UDim2.new(0, 7, 0, posY + 5)
	box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	box.BackgroundTransparency = 0.20
	box.Parent = leftSidebar

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 16)
	boxCorner.Parent = box

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Color3.fromRGB(180, 180, 180)
	boxStroke.Transparency = 1
	boxStroke.Thickness = 0.8
	boxStroke.Parent = box

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.Position = UDim2.new(0, 0, 0, 0)
	btn.BackgroundTransparency = 1
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextTransparency = 0.05
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBold
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = box

	local originalSize = box.Size
	local originalPos = box.Position
	
	btn.MouseEnter:Connect(function()
		TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 170, 0, 46),
			Position = UDim2.new(0, 5.5, 0, posY + 5 - 1),
			BackgroundColor3 = Color3.fromRGB(45, 45, 52),
			BackgroundTransparency = 0.20
		}):Play()
	end)
	
	btn.MouseLeave:Connect(function()
		TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = originalSize,
			Position = originalPos,
			BackgroundColor3 = Color3.fromRGB(15, 15, 18),
			BackgroundTransparency = 0.20
		}):Play()
	end)
	
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(box, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(80, 80, 90),
			BackgroundTransparency = 0.20
		}):Play()
	end)
	
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(box, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(45, 45, 52),
			BackgroundTransparency = 0.20
		}):Play()
	end)

	btn.Position = UDim2.new(0, 42, 0, 0)
	btn.Size = UDim2.new(1, -42, 1, 0)

	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.new(0, 22, 0, 22)
	iconFrame.Position = UDim2.new(0, 12, 0.5, -11)
	iconFrame.BackgroundTransparency = 1
	iconFrame.Parent = box

	local tabIcon = Instance.new("ImageLabel")
	tabIcon.Size = UDim2.new(1, 0, 1, 0)
	tabIcon.BackgroundTransparency = 1
	-- ИКОНКИ ДЛЯ ВКЛАДОК
	if name == "Information" then
		tabIcon.Image = "rbxassetid://79283066206748"
	elseif name == "Visuals" then
		tabIcon.Image = "rbxassetid://81308218400037"
	elseif name == "Player" then
		tabIcon.Image = "rbxassetid://83406828033301"
	elseif name == "Defense" then
		tabIcon.Image = "rbxassetid://135406634230412"
	elseif name == "Target" then
		tabIcon.Image = "rbxassetid://105284606045754"
	elseif name == "Grabs" then
		tabIcon.Image = "rbxassetid://84541674518389"
	elseif name == "Fun" then
		tabIcon.Image = "rbxassetid://122028401554585"
	elseif name == "Misc" then
		tabIcon.Image = "rbxassetid://117425441277630"
	elseif name == "UI Settings" then
		tabIcon.Image = "rbxassetid://83611819126328"
	end
	tabIcon.ScaleType = Enum.ScaleType.Fit
	tabIcon.Parent = iconFrame

	return btn, box
end

	local gap = 5
	local btnHeight = 44
	local infoBtn, infoBox = createSidebarItem("Information", nil, gap, 36, 35)
	local visualsBtn, visualsBox = createSidebarItem("Visuals", nil, gap + btnHeight + gap, 35, 22)
	local playerBtn, playerBox = createSidebarItem("Player", nil, gap + (btnHeight + gap) * 2, 36, 35)
	local defenseBtn, defenseBox = createSidebarItem("Defense", nil, gap + (btnHeight + gap) * 3, 35, 27.5)
	local targetBtn, targetBox = createSidebarItem("Target", nil, gap + (btnHeight + gap) * 4, 0, 0)
	local grabsBtn, grabsBox = createSidebarItem("Grabs", nil, gap + (btnHeight + gap) * 5, 0, 0)
	local funBtn, funBox = createSidebarItem("Fun", nil, gap + (btnHeight + gap) * 6, 0, 0)
	local miscBtn, miscBox = createSidebarItem("Misc", nil, gap + (btnHeight + gap) * 7, 0, 0)
	local uiSettingsBtn, uiSettingsBox = createSidebarItem("UI Settings", nil, gap + (btnHeight + gap) * 8, 0, 0)

	leftSidebar.Size = UDim2.new(0, 180, 1, -133)

	isTabSwitching = false

	local tabOrder = {"Information", "Visuals", "Player", "Defense", "Target", "Grabs", "Fun", "Misc", "UI Settings"}

	local function getTabIndex(tabName)
		for i, name in ipairs(tabOrder) do
			if name == tabName then return i end
		end
		return 1
	end

	local function switchTab(targetTab)
		if isTabSwitching then return end
		isTabSwitching = true

		local oldTab = "Information"
		if activeTabIsVisuals then oldTab = "Visuals"
		elseif activeTabIsPlayer then oldTab = "Player"
		elseif activeTabIsDefense then oldTab = "Defense"
		elseif activeTabIsTarget then oldTab = "Target"
		elseif activeTabIsGrabs then oldTab = "Grabs"
		elseif activeTabIsFun then oldTab = "Fun"
		elseif activeTabIsMisc then oldTab = "Misc"
		elseif activeTabIsUISettings then oldTab = "UI Settings"
		elseif activeTabIsInfo then oldTab = "Information" end

		activeTabIsInfo = (targetTab == "Information")
		activeTabIsVisuals = (targetTab == "Visuals")
		activeTabIsPlayer = (targetTab == "Player")
		activeTabIsDefense = (targetTab == "Defense")
		activeTabIsTarget = (targetTab == "Target")
		activeTabIsGrabs = (targetTab == "Grabs")
		activeTabIsFun = (targetTab == "Fun")
		activeTabIsMisc = (targetTab == "Misc")
		activeTabIsUISettings = (targetTab == "UI Settings")

		local oldIndex = getTabIndex(oldTab)
		local newIndex = getTabIndex(targetTab)
		local directionMultiplier = (newIndex > oldIndex) and 1 or -1

		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		local areas = {
			{area = infoContentArea, tab = "Information"},
			{area = mainContentArea, tab = "Visuals"},
			{area = playerContentArea, tab = "Player"},
			{area = defenseContentArea, tab = "Defense"},
			{area = targetContentArea, tab = "Target"},
			{area = grabsContentArea, tab = "Grabs"},
			{area = funContentArea, tab = "Fun"},
			{area = miscContentArea, tab = "Misc"},
			{area = uiSettingsContentArea, tab = "UI Settings"}
		}

		for _, item in ipairs(areas) do
			if item.tab == targetTab then
				item.area.Visible = true
				item.area.Position = UDim2.new(0, 200, 0, 45 + (600 * directionMultiplier))
				item.area.ScrollBarImageTransparency = 0.2
				local tw = TweenService:Create(item.area, tweenInfo, {Position = UDim2.new(0, 200, 0, 45)})
				tw:Play()
			else
				item.area.ScrollBarImageTransparency = 1
				local tw = TweenService:Create(item.area, tweenInfo, {Position = UDim2.new(0, 200, 0, 45 - (600 * directionMultiplier))})
				tw:Play()
				task.delay(0.55, function()
					if targetTab ~= item.tab then
						item.area.Visible = false
					end
				end)
			end
		end

		task.wait(0.6)
		isTabSwitching = false
	end

	infoBtn.MouseButton1Click:Connect(function()
		if not activeTabIsInfo and not isTabSwitching then switchTab("Information") end
	end)

	visualsBtn.MouseButton1Click:Connect(function()
		if not activeTabIsVisuals and not isTabSwitching then switchTab("Visuals") end
	end)

	playerBtn.MouseButton1Click:Connect(function()
		if not activeTabIsPlayer and not isTabSwitching then switchTab("Player") end
	end)

	defenseBtn.MouseButton1Click:Connect(function()
		if not activeTabIsDefense and not isTabSwitching then switchTab("Defense") end
	end)

	targetBtn.MouseButton1Click:Connect(function()
		if not activeTabIsTarget and not isTabSwitching then switchTab("Target") end
	end)

	grabsBtn.MouseButton1Click:Connect(function()
		if not activeTabIsGrabs and not isTabSwitching then switchTab("Grabs") end
	end)

	funBtn.MouseButton1Click:Connect(function()
		if not activeTabIsFun and not isTabSwitching then switchTab("Fun") end
	end)

	miscBtn.MouseButton1Click:Connect(function()
		if not activeTabIsMisc and not isTabSwitching then switchTab("Misc") end
	end)

	uiSettingsBtn.MouseButton1Click:Connect(function()
		if not activeTabIsUISettings and not isTabSwitching then switchTab("UI Settings") end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.W then keys.W = true
			elseif input.KeyCode == Enum.KeyCode.A then keys.A = true
			elseif input.KeyCode == Enum.KeyCode.S then keys.S = true
			elseif input.KeyCode == Enum.KeyCode.D then keys.D = true
			elseif input.KeyCode == Enum.KeyCode.Space then keys.Space = true
			elseif input.KeyCode == Enum.KeyCode.LeftControl then keys.LeftControl = true
			end
		end

		if gameProcessed then return end

		if frame.Visible then
			if input.KeyCode == Enum.KeyCode.RightShift then updateMenuState(false) end
			return
		end

		if input.KeyCode == Enum.KeyCode.RightShift then
			updateMenuState(true)
		elseif input.KeyCode == currentKey then
			spawnBoard()
		elseif input.KeyCode == triggerKey then
			if containmentEnabled then
				cleanup()
			else
				if root then
					local rayParams = RaycastParams.new()
					if character then rayParams.FilterDescendantsInstances = {character} end
					rayParams.FilterType = Enum.RaycastFilterType.Blacklist

					local result = workspace:Raycast(root.Position, Vector3.new(0, -10, 0), rayParams)
					if result and result.Instance then
						local palletModel = result.Instance:FindFirstAncestorOfClass("Model") or result.Instance
						if palletModel.Name == "PalletLightBrown" then
							spawnBarriers(palletModel)
						end
					end
				end
			end
		elseif input.KeyCode == teleportKey then
			if root and camera then
				local rayParams = RaycastParams.new()
				if character then rayParams.FilterDescendantsInstances = {character} end
				rayParams.FilterType = Enum.RaycastFilterType.Blacklist

				local camCF = camera.CFrame
				local rayResult = Workspace:Raycast(camCF.Position, camCF.LookVector * 2000, rayParams)

				if rayResult and rayResult.Instance then
					local targetPos = rayResult.Position
					local hipHeight = (humanoid and humanoid.HipHeight or 2) + (root and (root.Size.Y / 2) or 3)
					
					root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
					root.CFrame = CFrame.new(targetPos + Vector3.new(0, hipHeight, 0))
				end
			end
		elseif input.KeyCode == infJumpKey then
			isInfJumpEnabled = not isInfJumpEnabled
		elseif input.KeyCode == noclipKey then
			noclip = not noclip
		elseif input.KeyCode == speedHackKey then
			isSpeedHackEnabled = not isSpeedHackEnabled
			if not isSpeedHackEnabled and humanoid then
				humanoid.WalkSpeed = 16
				if root then
					root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
				end
			end
		elseif input.KeyCode == flyKey then
			if toggleVFly then
				toggleVFly()
			end
		elseif input.KeyCode == breakCollisionKey then
			if executeBreakCollision then
				executeBreakCollision()
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.W then keys.W = false
			elseif input.KeyCode == Enum.KeyCode.A then keys.A = false
			elseif input.KeyCode == Enum.KeyCode.S then keys.S = false
			elseif input.KeyCode == Enum.KeyCode.D then keys.D = false
			elseif input.KeyCode == Enum.KeyCode.Space then keys.Space = false
			elseif input.KeyCode == Enum.KeyCode.LeftControl then keys.LeftControl = false
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		if isInfJumpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) and humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end

		if frame.Visible and not isTweening then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end

		if dragging and dragInput then
			local delta = dragInput.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end

		if resizing and dragInput then
			local delta = dragInput.Position - startMousePos
			local newWidth = math.clamp(resizeStart.X + delta.X, MIN_WIDTH, MAX_WIDTH)
			local newHeight = math.clamp(resizeStart.Y + delta.Y, MIN_HEIGHT, MAX_HEIGHT)
			
			frame.Size = UDim2.new(0, newWidth, 0, newHeight)
			
			mainContentArea.Size = UDim2.new(1, -210, 1, -55)
			mainContentArea.Position = UDim2.new(0, 200, 0, 45)
			infoContentArea.Size = UDim2.new(1, -210, 1, -55)
			infoContentArea.Position = UDim2.new(0, 200, 0, 45)
			playerContentArea.Size = UDim2.new(1, -210, 1, -55)
			playerContentArea.Position = UDim2.new(0, 200, 0, 45)
			defenseContentArea.Size = UDim2.new(1, -210, 1, -55)
			defenseContentArea.Position = UDim2.new(0, 200, 0, 45)
			targetContentArea.Size = UDim2.new(1, -210, 1, -55)
			targetContentArea.Position = UDim2.new(0, 200, 0, 45)
			grabsContentArea.Size = UDim2.new(1, -210, 1, -55)
			grabsContentArea.Position = UDim2.new(0, 200, 0, 45)
			funContentArea.Size = UDim2.new(1, -210, 1, -55)
			funContentArea.Position = UDim2.new(0, 200, 0, 45)
			miscContentArea.Size = UDim2.new(1, -210, 1, -55)
			miscContentArea.Position = UDim2.new(0, 200, 0, 45)
			uiSettingsContentArea.Size = UDim2.new(1, -210, 1, -55)
			uiSettingsContentArea.Position = UDim2.new(0, 200, 0, 45)
		end
	end)
end

buildUI()
