-- Настройки 
local config = {
    TeamCheck = false,
    FOV = 100,
    Smoothing = 1,
    ColorLerpSpeed = 0.15  -- скорость смены цвета (0.01 - медленно, 1 - моментально)
}

-- Услуги
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Графический интерфейс пользователя
local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 1.5
FOVring.Radius = config.FOV
FOVring.Transparency = 1
FOVring.Color = Color3.fromRGB(255, 0, 0)  -- старт: красный
FOVring.Position = workspace.CurrentCamera.ViewportSize / 2

-- Цвета
local activeColor = Color3.fromRGB(0, 255, 0)
local inactiveColor = Color3.fromRGB(255, 0, 0)
local targetColor = inactiveColor  -- начальное целевое состояние

-- Обновление позиции и цвета круга каждый кадр
RunService.RenderStepped:Connect(function()
    if workspace.CurrentCamera then
        FOVring.Position = workspace.CurrentCamera.ViewportSize / 2
    end
    -- Плавная смена цвета круга
    FOVring.Color = FOVring.Color:lerp(targetColor, config.ColorLerpSpeed)
end)

-- Проверка ближайшего видимого игрока
local function getClosestVisiblePlayer(camera)
    local ray = Ray.new(camera.CFrame.Position, camera.CFrame.LookVector)
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("Head") then
                local headPosition = character.Head.Position
                local targetPosition = ray:ClosestPoint(headPosition)
                local distance = (targetPosition - headPosition).Magnitude

                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Aimbot переключение
local aimbotEnabled = false

local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    targetColor = aimbotEnabled and activeColor or inactiveColor
end

-- Обновление aimbot
local function updateAimbot()
    if aimbotEnabled then
        local currentCamera = workspace.CurrentCamera
        local crosshairPosition = currentCamera.ViewportSize / 2
        local closestPlayer = getClosestVisiblePlayer(currentCamera)

        if closestPlayer then
            local headPosition = closestPlayer.Character.Head.Position
            local headScreenPosition = currentCamera:WorldToScreenPoint(headPosition)
            local distanceToCrosshair = (Vector2.new(headScreenPosition.X, headScreenPosition.Y) - crosshairPosition).Magnitude

            if distanceToCrosshair < config.FOV then
                currentCamera.CFrame = currentCamera.CFrame:Lerp(CFrame.new(currentCamera.CFrame.Position, headPosition), config.Smoothing)
            end
        end
    end
end

-- Подключение aimbot
local aimbotConnection

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if not aimbotEnabled then
            toggleAimbot()
            FOVring.Radius = config.FOV
            aimbotConnection = RunService.RenderStepped:Connect(updateAimbot)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if aimbotEnabled then
            toggleAimbot()
            if aimbotConnection then
                aimbotConnection:Disconnect()
            end
        end
    end
end)

-- Уведомление и звук
local Sound = Instance.new("Sound", game:GetService("SoundService"))
Sound.SoundId = "rbxassetid://232127604"
Sound:Play()


local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "AimbotStartupMessage"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Контейнер Frame (со скруглением)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 70)
frame.Position = UDim2.new(0, 10, 1, -80)
frame.AnchorPoint = Vector2.new(0, 1)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0
frame.Parent = gui

-- Скруглённые углы фрейма
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

-- Пропорции
local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = 4 / 1
aspectRatio.Parent = frame

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "✅ AimBot Enabled"
title.TextColor3 = Color3.fromRGB(0, 255, 0)
title.TextTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextStrokeTransparency = 1
title.Parent = frame

-- Подзаголовок
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 30)
subtitle.Position = UDim2.new(0, 10, 0, 35)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Hold RMB to aim"
subtitle.TextColor3 = Color3.fromRGB(200, 255, 200)
subtitle.TextTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 16
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextStrokeTransparency = 1
subtitle.Parent = frame

-- Кнопка-иконка (красный крестик)
local closeButton = Instance.new("ImageButton")
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -28, 0, 4)
closeButton.BackgroundTransparency = 1
closeButton.Image = "rbxassetid://3926305904"
closeButton.ImageRectOffset = Vector2.new(284, 4)
closeButton.ImageRectSize = Vector2.new(24, 24)
closeButton.ImageColor3 = Color3.fromRGB(255, 70, 70)
closeButton.ImageTransparency = 1 -- для анимации
closeButton.Parent = frame

-- Скругление кнопки
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(1, 0)
buttonCorner.Parent = closeButton

-- Анимация появления
task.spawn(function()
    for i = 1, 20 do
        local alpha = i / 20
        frame.BackgroundTransparency = 1 - (alpha * 0.7)
        title.TextTransparency = 1 - alpha
        title.TextStrokeTransparency = 1 - alpha
        subtitle.TextTransparency = 1 - alpha
        subtitle.TextStrokeTransparency = 1 - alpha
        closeButton.ImageTransparency = 1 - alpha
        task.wait(0.02)
    end
end)

-- Закрытие при нажатии
closeButton.MouseButton1Click:Connect(function()
    task.spawn(function()
        for i = 1, 20 do
            local alpha = i / 20
            frame.BackgroundTransparency = 0.3 + (alpha * 0.7)
            title.TextTransparency += 0.05
            title.TextStrokeTransparency += 0.05
            subtitle.TextTransparency += 0.05
            subtitle.TextStrokeTransparency += 0.05
            closeButton.ImageTransparency += 0.05
            task.wait(0.02)
        end
        gui:Destroy()
    end)
end)

