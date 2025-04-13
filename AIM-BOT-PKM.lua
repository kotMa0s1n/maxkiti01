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


Message
