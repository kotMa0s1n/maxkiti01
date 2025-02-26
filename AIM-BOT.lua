-- Настройки
local config = {
    TeamCheck = false,            -- Проверка каманды (чтобы не убицелится на свою команду)
    FOV = 100,                    -- Изменить FOV круга работы 
    Smoothing = 1,                -- Как сильно будет магнитется камера
    KeyToToggle = Enum.KeyCode.F, -- Клавиша на которую будет включатся aimbot
}

-- Услуги
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- графический интерфейс пользователя
local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 1.5
FOVring.Radius = config.FOV
FOVring.Transparency = 1
FOVring.Color = Color3.fromRGB(255, 128, 128)
FOVring.Position = workspace.CurrentCamera.ViewportSize / 2

-- Функция для поиска ближайшего видимого игрока
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

-- Функция для переключения aimbot
local aimbotEnabled = false

local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    FOVring.Visible = aimbotEnabled
end

-- Функция для обновления aimbot
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

-- Подключите функцию переключения Aimbot к кнопке переключения
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == config.KeyToToggle then
        toggleAimbot()
    end
end)

-- Подключите функцию обновления Aimbot к событию RenderStepped
local aimbotConnection

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == config.KeyToToggle then
        if aimbotEnabled then
            FOVring:Remove()
            aimbotConnection:Disconnect()
        else
            FOVring.Position = workspace.CurrentCamera.ViewportSize / 2
            FOVring.Radius = config.FOV
            aimbotConnection = RunService.RenderStepped:Connect(updateAimbot)
        end
    end
end)
