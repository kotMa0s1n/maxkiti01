local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()

local Window = Library.CreateLib("War Tycoon [BETA]", "RJTheme3")

local Tab = Window:NewTab("???")

local Section = Tab:NewSection("speed")

Section:NewSlider("speed", "lol", 500, 0, function(s)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = s
end)

local Section = Tab:NewSection("jump")

Section:NewSlider("jump", "lol", 500, 0, function(s)
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = s
end)

local Section = Tab:NewSection("gravity")

Section:NewSlider("gravity", "lol", 500, 0, function(s)
    game.Workspace.Gravity = s
end)

local Section = Tab:NewSection("inf jump")

Section:NewButton("inf jump", "lol", function()

    local Player = game:GetService'Players'.LocalPlayer;
local UIS = game:GetService'UserInputService';
 
_G.JumpHeight = 50;
 
function Action(Object, Function) if Object ~= nil then Function(Object); end end
 
UIS.InputBegan:connect(function(UserInput)
if UserInput.UserInputType == Enum.UserInputType.Keyboard and UserInput.KeyCode == Enum.KeyCode.Space then
Action(Player.Character.Humanoid, function(self)
if self:GetState() == Enum.HumanoidStateType.Jumping or self:GetState() == Enum.HumanoidStateType.Freefall then
Action(self.Parent.HumanoidRootPart, function(self)
self.Velocity = Vector3.new(0, _G.JumpHeight, 0);
end)
end
end)
end
end)

end)

local Section = Tab:NewSection("reset")

Section:NewButton("reset", "lol", function()
    game.Players.LocalPlayer.Character.Humanoid.Health = 0
end)

local Section = Tab:NewSection("rejoin")

Section:NewButton("rejoin", "lol", function()
    local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
 
local Rejoin = coroutine.create(function()
    local Success, ErrorMessage = pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
 
    if ErrorMessage and not Success then
        warn(ErrorMessage)
    end
end)
 
coroutine.resume(Rejoin)
end)

local Tab = Window:NewTab("main")

local Section = Tab:NewSection("esp")

Section:NewButton("esp", "lol", function()
    -- Сервис игрока
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Настройка обновления
local RunService = game:GetService("RunService")

-- Создание ESP для одного игрока
local function createESP(player)
    if player == LocalPlayer then return end -- Пропускаем самого себя

    local BillboardGui = Instance.new("BillboardGui")
    BillboardGui.Name = "ESP"
    BillboardGui.Adornee = nil -- Будет прикрепляться к персонажу
    BillboardGui.Size = UDim2.new(4, 0, 1, 0) -- Размер GUI
    BillboardGui.StudsOffset = Vector3.new(0, 2, 0) -- Смещение по высоте
    BillboardGui.AlwaysOnTop = true

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Name = "NameLabel"
    NameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.TextStrokeTransparency = 0.5
    NameLabel.TextScaled = true
    NameLabel.Parent = BillboardGui

    local DistanceLabel = Instance.new("TextLabel")
    DistanceLabel.Name = "DistanceLabel"
    DistanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    DistanceLabel.Position = UDim2.new(0, 0, 0.3, 0)
    DistanceLabel.BackgroundTransparency = 1
    DistanceLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
    DistanceLabel.TextStrokeTransparency = 0.5
    DistanceLabel.TextScaled = true
    DistanceLabel.Parent = BillboardGui

    local HealthBar = Instance.new("Frame")
    HealthBar.Name = "HealthBar"
    HealthBar.Size = UDim2.new(0.8, 0, 0.2, 0)
    HealthBar.Position = UDim2.new(0.1, 0, 0.6, 0)
    HealthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    HealthBar.BorderSizePixel = 0
    HealthBar.Parent = BillboardGui

    local HealthBackground = Instance.new("Frame")
    HealthBackground.Name = "HealthBackground"
    HealthBackground.Size = UDim2.new(1, 0, 1, 0)
    HealthBackground.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    HealthBackground.BorderSizePixel = 0
    HealthBackground.ZIndex = -1
    HealthBackground.Parent = HealthBar

    -- Обновление ESP
    local function updateESP()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then
            BillboardGui.Adornee = nil
            return
        end

        local humanoid = player.Character.Humanoid
        local rootPart = player.Character.HumanoidRootPart
        BillboardGui.Adornee = rootPart

        -- Обновляем текстовые метки
        NameLabel.Text = player.Name
        local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and
            (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude or 0
        DistanceLabel.Text = string.format("Distance: %.0f studs", distance)

        -- Обновляем полоску здоровья
        HealthBar.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 0.2, 0)
        HealthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - humanoid.Health / humanoid.MaxHealth), 255 * (humanoid.Health / humanoid.MaxHealth), 0)
    end

    -- Подключаемся к обновлению
    RunService.RenderStepped:Connect(updateESP)

    -- Привязываем BillboardGui к персонажу
    BillboardGui.Parent = player.Character:WaitForChild("HumanoidRootPart")
end

-- Подключаем ESP ко всем игрокам
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

-- Добавляем ESP к новым игрокам
Players.PlayerAdded:Connect(createESP)
end)

local Section = Tab:NewSection("aimlock")

Section:NewButton("aimlock [keybind T]", "lol", function()
    local player = game.Players.LocalPlayer
    local Cam = workspace.CurrentCamera
    
    -- Toggles setting set to False or True to toggle rejoin if you want to re settings 
    local targetTeammates = true  -- Initially, target non-teammates or teammate
    local aimbotActive = true  -- Initial state of the aimbot
    
    -- Function to check if a player is a teammate
    local function isTeammate(targetPlayer)
        return targetPlayer.Team == player.Team
    end
    
    -- Function to look at a specific position
    local function lookAt(targetPosition)
        Cam.CFrame = CFrame.new(Cam.CFrame.Position, targetPosition)
    end
    
    -- Function to check if a target is visible (not behind walls)
    local function isTargetVisible(targetPart)
        local origin = Cam.CFrame.Position
        local direction = (targetPart.Position - origin).Unit
        local ray = Ray.new(origin, direction * 5000)
        local part, position = workspace:FindPartOnRayWithIgnoreList(ray, {player.Character, Cam})
        
        return part and part:IsDescendantOf(targetPart.Parent)
    end
    
    -- Function to get the closest player to the local player
    local function getClosestPlayer(trg_part)
        local nearest = nil
        local lastDistance = math.huge
        local localPlayerPos = player.Character.PrimaryPart.Position
        
        for _, v in pairs(game.Players:GetPlayers()) do
            if v ~= player and v.Character and v.Character:FindFirstChild(trg_part) and v.Character:FindFirstChild("Humanoid") then
                local head = v.Character[trg_part]
                local humanoid = v.Character.Humanoid
                if head and humanoid.Health > 0 then  -- Check if the target is alive
                    local distance = (localPlayerPos - head.Position).Magnitude
                    
                    -- Check visibility, distance, and teammate status
                    if distance < lastDistance and isTargetVisible(head) then
                        if (targetTeammates and isTeammate(v)) or (not targetTeammates and not isTeammate(v)) then
                            nearest = v
                            lastDistance = distance
                        end
                    end
                end
            end
        end
        
        return nearest
    end
    
    -- Toggle function to switch between targeting teammates and non-teammates
    local function toggleTargetMode()
        targetTeammates = not targetTeammates
        print("Targeting", targetTeammates and "teammates" or "non-teammates")
    end
    
    -- Function to toggle aimbot activation
    local function toggleAimbot()
        aimbotActive = not aimbotActive
        print("Aimbot", aimbotActive and "enabled" or "disabled")
    end
    
    -- RenderStepped connection to perform aiming
    game:GetService("RunService").RenderStepped:Connect(function()
        if aimbotActive then
            local closestPlayer = getClosestPlayer("Head")
            if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
                lookAt(closestPlayer.Character.Head.Position)
            end
        end
    end)
    
    -- Input binding for toggling targeting mode and aimbot (e.g., press 'T' to toggle targeting mode, press 'Y' to toggle aimbot)
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.T then
                toggleTargetMode()
            elseif input.KeyCode == Enum.KeyCode.T then
                toggleAimbot()
            end
        end
    end)
    
    -- Mobile support for toggling aimbot and targeting mode
    local UIS = game:GetService("UserInputService")
    
    UIS.TouchTap:Connect(function(touchPositions, processed)
        if not processed then
            local touch = touchPositions[1]
            if touch.Position.Y < workspace.CurrentCamera.ViewportSize.Y / 2 then
                toggleAimbot()
            else
                toggleTargetMode()
            end
        end
    end)
end)

local Section = Tab:NewSection("auto collection of all gifts")

Section:NewButton("click", "lol", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/samuraa1/Samuraa1-Hub/refs/heads/main/War-Tycoon"))()
end)

local Tab = Window:NewTab("teleport")

local Section = Tab:NewSection("teleport to the teams")

Section:NewButton("bravo", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(801.4594116210938, 67.15838623046875, -4650.7236328125) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

Section:NewButton("alpha", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(-431.98095703125, 67.15837097167969, -4481.26318359375) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

Section:NewButton("charlie", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(2055.891357421875, 67.15836334228516, -3938.7607421875) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

Section:NewButton("echo", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(3013.748779296875, 67.15839385986328, -1753.831298828125) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

Section:NewButton("foxtrot", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(3346.772216796875, 67.15839385986328, -524.0037841796875) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

Section:NewButton("golf", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(3252.150634765625, 67.15838623046875, 600.6138916015625) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

Section:NewButton("kilo", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(2525.1162109375, 67.15838623046875, 2944.583984375) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

Section:NewButton("lima", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(940.7755737304688, 67.15839385986328, 3444.97265625) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

Section:NewButton("omega", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(-361.87445068359375, 67.15836334228516, 3907.318115234375) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

Section:NewButton("romeo", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(-361.87445068359375, 67.15836334228516, 3907.318115234375) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

Section:NewButton("viktor", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(-3585.603759765625, 67.15838623046875, 588.0833129882812) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

local Section = Tab:NewSection("Teleport to the subway")

Section:NewButton("teleport", "lol", function()
        -- Укажите целевые координаты
        local targetPosition = Vector3.new(840.1897583007812, 8.918466567993164, -2908.224365234375) -- Замените на нужные координаты

        -- Получаем игрока
        local player = game.Players.LocalPlayer -- Используйте только в LocalScript
        local character = player.Character or player.CharacterAdded:Wait()
        
        -- Убедимся, что у персонажа есть HumanoidRootPart
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        
        -- Телепортируем персонажа
        humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

local Section = Tab:NewSection("teleport to the oli")

Section:NewButton("oli #1", "lol", function()
    -- Укажите целевые координаты
    local targetPosition = Vector3.new(-974.2867431640625, 69.33090209960938, -805.8330688476562) -- Замените на нужные координаты

    -- Получаем игрока
    local player = game.Players.LocalPlayer -- Используйте только в LocalScript
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- Убедимся, что у персонажа есть HumanoidRootPart
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Телепортируем персонажа
    humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

Section:NewButton("oli #2", "lol", function()
    -- Укажите целевые координаты
    local targetPosition = Vector3.new(669.90673828125, 121.25244140625, 784.5706787109375) -- Замените на нужные координаты

    -- Получаем игрока
    local player = game.Players.LocalPlayer -- Используйте только в LocalScript
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- Убедимся, что у персонажа есть HumanoidRootPart
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Телепортируем персонажа
    humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

Section:NewButton("oli #3", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(-1490.4219970703125, 121.25241088867188, -3674.835205078125) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

local Section = Tab:NewSection("teleport to the capture point")

Section:NewButton("teleport", "lol", function()
    -- Укажите целевые координаты
local targetPosition = Vector3.new(-657.6544799804688, 121.78433227539062, -1256.8726806640625) -- Замените на нужные координаты

-- Получаем игрока
local player = game.Players.LocalPlayer -- Используйте только в LocalScript
local character = player.Character or player.CharacterAdded:Wait()

-- Убедимся, что у персонажа есть HumanoidRootPart
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Телепортируем персонажа
humanoidRootPart.CFrame = CFrame.new(targetPosition)
end)

local Section = Tab:NewSection("teleport to the player")

Section:NewButton("teleport to the player", "lol", function()
    -- Получаем сервисы
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = game:GetService("Workspace").CurrentCamera
local UIS = game:GetService("UserInputService")

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.Players.LocalPlayer.PlayerGui

-- Изначальные размеры фрейма
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 150, 0, 200)  -- Исходный размер
frame.Position = UDim2.new(0.8, -160, 0.4, -120)  -- Исходная позиция
frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
frame.BackgroundTransparency = 0.5
frame.Parent = screenGui

-- Заголовок окна
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Text = "select player's"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundTransparency = 1
titleLabel.TextScaled = true
titleLabel.TextStrokeTransparency = 0.8
titleLabel.Parent = frame

-- Кнопка закрытия (крестик)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 10)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
closeButton.BackgroundTransparency = 0.7
closeButton.TextScaled = true
closeButton.Parent = frame

-- Скрываем GUI при нажатии на крестик
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()  -- Уничтожаем GUI
end)

local playerList = Instance.new("UIListLayout")
playerList.Parent = frame
playerList.SortOrder = Enum.SortOrder.Name

-- Кнопки для телепортации
local teleportButtons = {}

-- Функция для получения цвета команды игрока
local function getTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color  -- Цвет команды
    else
        return Color3.fromRGB(255, 255, 255)  -- Белый цвет, если нет команды
    end
end

-- Обновление списка игроков
local function updatePlayerList()
    -- Очищаем старые кнопки
    for _, button in pairs(teleportButtons) do
        button:Destroy()
    end
    teleportButtons = {}

    -- Добавляем кнопки для каждого игрока
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local button = Instance.new("TextButton")
            -- Исходный размер кнопок
            button.Size = UDim2.new(1, 0, 0, 25)  -- Исходная высота кнопок
            button.Text = player.Name
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            
            -- Устанавливаем цвет фона кнопки, соответствующий цвету команды
            button.BackgroundColor3 = getTeamColor(player)
            button.BackgroundTransparency = 0.3
            button.TextScaled = true
            button.Parent = frame

            -- При нажатии на кнопку телепортируемся к игроку
            button.MouseButton1Click:Connect(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                end
            end)

            -- Добавляем кнопку в список
            table.insert(teleportButtons, button)
        end
    end
end

-- Обновляем список игроков при изменении игроков в игре
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

-- Первоначальное обновление списка
updatePlayerList()

-- Клавиша для скрытия/отображения GUI
UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        frame.Visible = not frame.Visible
    end
end)

-- Перетаскивание GUI
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

-- Функция для начала перетаскивания
titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

-- Функция для продолжения перетаскивания
UIS.InputChanged:Connect(function(input)
    if dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Функция для завершения перетаскивания
titleLabel.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

end)
