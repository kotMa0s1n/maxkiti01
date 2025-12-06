-- Roblox GUI Library
local Library = {}

-- Создание главного GUI
function Library:CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CustomGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game.CoreGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 700, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MainFrame.BorderSizePixel = 0
    MainFrame.ZIndex = 1
    MainFrame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = MainFrame
    
    -- Заголовок
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 50)
    TitleBar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    TitleBar.BorderSizePixel = 0
    TitleBar.ZIndex = 10
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar
    
    -- Нижняя часть заголовка чтобы скрыть скругление
    local TitleBarBottom = Instance.new("Frame")
    TitleBarBottom.Size = UDim2.new(1, 0, 0, 10)
    TitleBarBottom.Position = UDim2.new(0, 0, 1, -10)
    TitleBarBottom.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    TitleBarBottom.BorderSizePixel = 0
    TitleBarBottom.ZIndex = 10
    TitleBarBottom.Parent = TitleBar
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, -120, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 18
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 10
    TitleLabel.Parent = TitleBar
    
    -- Кнопки управления окном
    local ButtonsFrame = Instance.new("Frame")
    ButtonsFrame.Size = UDim2.new(0, 90, 0, 28)
    ButtonsFrame.Position = UDim2.new(1, -105, 0, 11)
    ButtonsFrame.BackgroundTransparency = 1
    ButtonsFrame.ZIndex = 10
    ButtonsFrame.Parent = TitleBar
    
    local function CreateWindowButton(color, position, name)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 24, 0, 24)
        btn.Position = position
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.ZIndex = 10
        btn.Parent = ButtonsFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = btn
        
        return btn
    end
    
    local GreenBtn = CreateWindowButton(Color3.fromRGB(52, 199, 89), UDim2.new(0, 0, 0, 0), "GreenBtn")
    local YellowBtn = CreateWindowButton(Color3.fromRGB(255, 204, 0), UDim2.new(0, 33, 0, 0), "YellowBtn")
    local RedBtn = CreateWindowButton(Color3.fromRGB(255, 59, 48), UDim2.new(0, 66, 0, 0), "RedBtn")
    
    -- Уведомление о хоткее
    local NotificationFrame = Instance.new("Frame")
    NotificationFrame.Name = "NotificationFrame"
    NotificationFrame.Size = UDim2.new(0, 280, 0, 60)
    NotificationFrame.Position = UDim2.new(0, 20, 1, -80)
    NotificationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    NotificationFrame.BorderSizePixel = 0
    NotificationFrame.Visible = false
    NotificationFrame.Parent = ScreenGui
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 10)
    NotifCorner.Parent = NotificationFrame
    
    local NotifText = Instance.new("TextLabel")
    NotifText.Size = UDim2.new(1, -20, 1, -20)
    NotifText.Position = UDim2.new(0, 10, 0, 10)
    NotifText.BackgroundTransparency = 1
    NotifText.Text = "Нажмите RightShift\nчтобы открыть/закрыть хаб"
    NotifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    NotifText.Font = Enum.Font.GothamSemibold
    NotifText.TextSize = 14
    NotifText.TextXAlignment = Enum.TextXAlignment.Left
    NotifText.TextYAlignment = Enum.TextYAlignment.Top
    NotifText.TextWrapped = true
    NotifText.Parent = NotificationFrame
    
    -- Поиск по вкладкам
    local SearchFrame = Instance.new("Frame")
    SearchFrame.Name = "SearchFrame"
    SearchFrame.Size = UDim2.new(0, 210, 0, 40)
    SearchFrame.Position = UDim2.new(0, 8, 0, 58)
    SearchFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    SearchFrame.BorderSizePixel = 0
    SearchFrame.ZIndex = 5
    SearchFrame.Parent = MainFrame
    
    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(0, 8)
    SearchCorner.Parent = SearchFrame
    
    local SearchBox = Instance.new("TextBox")
    SearchBox.Name = "SearchBox"
    SearchBox.Size = UDim2.new(1, -20, 1, 0)
    SearchBox.Position = UDim2.new(0, 10, 0, 0)
    SearchBox.BackgroundTransparency = 1
    SearchBox.PlaceholderText = "Поиск вкладок..."
    SearchBox.Text = ""
    SearchBox.TextColor3 = Color3.fromRGB(0, 0, 0)
    SearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 14
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ZIndex = 5
    SearchBox.Parent = SearchFrame
    
    -- Список вкладок (слева)
    local TabsListFrame = Instance.new("ScrollingFrame")
    TabsListFrame.Name = "TabsListFrame"
    TabsListFrame.Size = UDim2.new(0, 210, 0, 386)
    TabsListFrame.Position = UDim2.new(0, 8, 0, 106)
    TabsListFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    TabsListFrame.BorderSizePixel = 0
    TabsListFrame.ScrollBarThickness = 5
    TabsListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabsListFrame.ZIndex = 5
    TabsListFrame.Parent = MainFrame
    
    local TabsCorner = Instance.new("UICorner")
    TabsCorner.CornerRadius = UDim.new(0, 8)
    TabsCorner.Parent = TabsListFrame
    
    local TabsLayout = Instance.new("UIListLayout")
    TabsLayout.Padding = UDim.new(0, 6)
    TabsLayout.Parent = TabsListFrame
    
    local TabsPadding = Instance.new("UIPadding")
    TabsPadding.PaddingTop = UDim.new(0, 8)
    TabsPadding.PaddingBottom = UDim.new(0, 8)
    TabsPadding.PaddingLeft = UDim.new(0, 8)
    TabsPadding.PaddingRight = UDim.new(0, 8)
    TabsPadding.Parent = TabsListFrame
    
    -- Контент вкладки (справа)
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(0, 466, 0, 434)
    ContentFrame.Position = UDim2.new(0, 226, 0, 58)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 6
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.Visible = false
    ContentFrame.Parent = MainFrame
    
    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 8)
    ContentCorner.Parent = ContentFrame
    
    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingTop = UDim.new(0, 15)
    ContentPadding.PaddingBottom = UDim.new(0, 15)
    ContentPadding.PaddingLeft = UDim.new(0, 15)
    ContentPadding.PaddingRight = UDim.new(0, 21)
    ContentPadding.Parent = ContentFrame
    
    -- Переменные
    local tabs = {}
    local currentTab = nil
    local isDarkMode = false
    local isHubVisible = true
    
    -- Обновление размера canvas
    TabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabsListFrame.CanvasSize = UDim2.new(0, 0, 0, TabsLayout.AbsoluteContentSize.Y + 16)
    end)
    
    -- Функция показа уведомления
    local function ShowNotification()
        NotificationFrame.Visible = true
        NotificationFrame.Position = UDim2.new(0, 20, 1, 0)
        NotificationFrame:TweenPosition(UDim2.new(0, 20, 1, -80), "Out", "Quad", 0.3, true)
        
        task.wait(3)
        
        NotificationFrame:TweenPosition(UDim2.new(0, 20, 1, 0), "In", "Quad", 0.3, true, function()
            NotificationFrame.Visible = false
        end)
    end
    
    -- Функция смены темы
    local function ToggleTheme()
        isDarkMode = not isDarkMode
        
        if isDarkMode then
            MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            TitleBarBottom.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            SearchFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            SearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
            TabsListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            ContentFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        else
            MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TitleBar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            TitleBarBottom.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            TitleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
            SearchFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            SearchBox.TextColor3 = Color3.fromRGB(0, 0, 0)
            SearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
            TabsListFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            ContentFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
        end
        
        -- Обновление цветов вкладок и элементов
        for _, tab in pairs(tabs) do
            if isDarkMode then
                if tab == currentTab then
                    tab.Button.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
                else
                    tab.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    tab.Label.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
            else
                if tab == currentTab then
                    tab.Button.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
                else
                    tab.Button.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    tab.Label.TextColor3 = Color3.fromRGB(50, 50, 50)
                end
            end
            
            -- Обновление элементов внутри вкладки
            for _, element in pairs(tab.Content:GetChildren()) do
                if element:IsA("Frame") and element.Name:find("Toggle") then
                    element.BackgroundColor3 = isDarkMode and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(240, 240, 240)
                    for _, child in pairs(element:GetChildren()) do
                        if child:IsA("TextLabel") then
                            child.TextColor3 = isDarkMode and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
                        end
                    end
                elseif element:IsA("Frame") and element.Name:find("Textbox") then
                    element.BackgroundColor3 = isDarkMode and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(240, 240, 240)
                    for _, child in pairs(element:GetChildren()) do
                        if child:IsA("TextBox") then
                            child.TextColor3 = isDarkMode and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
                        end
                    end
                elseif element:IsA("TextLabel") then
                    element.TextColor3 = isDarkMode and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
                end
            end
        end
    end
    
    -- Функция переключения видимости хаба
    local function ToggleHub()
        isHubVisible = not isHubVisible
        MainFrame.Visible = isHubVisible
        
        if not isHubVisible then
            ShowNotification()
        end
    end
    
    -- Функция смены вкладки
    local function SwitchTab(tab)
        for _, t in pairs(tabs) do
            t.Content.Visible = false
            if isDarkMode then
                t.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                t.Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            else
                t.Button.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                t.Label.TextColor3 = Color3.fromRGB(50, 50, 50)
            end
        end
        
        tab.Content.Visible = true
        tab.Button.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
        tab.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        currentTab = tab
    end
    
    -- Поиск по вкладкам
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = SearchBox.Text:lower()
        for _, tab in pairs(tabs) do
            if searchText == "" or tab.Name:lower():find(searchText) then
                tab.Button.Visible = true
            else
                tab.Button.Visible = false
            end
        end
    end)
    
    -- Кнопки управления
    RedBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    YellowBtn.MouseButton1Click:Connect(ToggleHub)
    
    GreenBtn.MouseButton1Click:Connect(ToggleTheme)
    
    -- Хоткей RightShift для открытия/закрытия хаба
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.RightShift then
            ToggleHub()
        end
    end)
    
    -- Перетаскивание окна
    local dragging, dragInput, dragStart, startPos
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Window API
    local Window = {}
    
    function Window:SetTitle(newTitle)
        TitleLabel.Text = newTitle
    end
    
    function Window:CreateTab(tabName)
        local Tab = {}
        Tab.Name = tabName or "Вкладка"
        
        -- Кнопка вкладки
        local TabButton = Instance.new("TextButton")
        TabButton.Name = Tab.Name
        TabButton.Size = UDim2.new(1, 0, 0, 45)
        TabButton.BackgroundColor3 = isDarkMode and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(230, 230, 230)
        TabButton.BorderSizePixel = 0
        TabButton.Text = ""
        TabButton.ZIndex = 5
        TabButton.Parent = TabsListFrame
        
        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 8)
        TabBtnCorner.Parent = TabButton
        
        -- Текст вкладки
        local TabLabel = Instance.new("TextLabel")
        TabLabel.Size = UDim2.new(1, -24, 1, 0)
        TabLabel.Position = UDim2.new(0, 12, 0, 0)
        TabLabel.BackgroundTransparency = 1
        TabLabel.Text = Tab.Name
        TabLabel.TextColor3 = isDarkMode and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(50, 50, 50)
        TabLabel.Font = Enum.Font.GothamSemibold
        TabLabel.TextSize = 15
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.TextTruncate = Enum.TextTruncate.AtEnd
        TabLabel.ZIndex = 5
        TabLabel.Parent = TabButton
        
        -- Контент вкладки
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = Tab.Name .. "Content"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 6
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.Visible = false
        TabContent.Parent = ContentFrame.Parent
        
        local TabLayout = Instance.new("UIListLayout")
        TabLayout.Padding = UDim.new(0, 12)
        TabLayout.Parent = TabContent
        
        local TabContentPadding = Instance.new("UIPadding")
        TabContentPadding.PaddingTop = UDim.new(0, 15)
        TabContentPadding.PaddingBottom = UDim.new(0, 15)
        TabContentPadding.PaddingLeft = UDim.new(0, 15)
        TabContentPadding.PaddingRight = UDim.new(0, 15)
        TabContentPadding.Parent = TabContent
        
        TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 30)
        end)
        
        Tab.Button = TabButton
        Tab.Content = TabContent
        Tab.Label = TabLabel
        
        TabButton.MouseButton1Click:Connect(function()
            SwitchTab(Tab)
        end)
        
        table.insert(tabs, Tab)
        
        if #tabs == 1 then
            SwitchTab(Tab)
        end
        
        -- Tab API
        function Tab:AddButton(text, callback)
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(0, 220, 0, 40)
            Button.Position = UDim2.new(1, -235, 0, 0)
            Button.AnchorPoint = Vector2.new(0, 0)
            Button.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
            Button.BorderSizePixel = 0
            Button.Text = text
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            Button.Font = Enum.Font.GothamSemibold
            Button.TextSize = 14
            Button.ZIndex = 2
            Button.Parent = TabContent
            
            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 8)
            BtnCorner.Parent = Button
            
            Button.MouseButton1Click:Connect(callback)
        end
        
        function Tab:AddToggle(text, default, callback)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Name = "ToggleFrame"
            ToggleFrame.Size = UDim2.new(0, 220, 0, 45)
            ToggleFrame.Position = UDim2.new(1, -235, 0, 0)
            ToggleFrame.AnchorPoint = Vector2.new(0, 0)
            ToggleFrame.BackgroundColor3 = isDarkMode and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(240, 240, 240)
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.ZIndex = 2
            ToggleFrame.Parent = TabContent
            
            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 8)
            ToggleCorner.Parent = ToggleFrame
            
            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Size = UDim2.new(1, -65, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 12, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = text
            ToggleLabel.TextColor3 = isDarkMode and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
            ToggleLabel.Font = Enum.Font.Gotham
            ToggleLabel.TextSize = 14
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.TextWrapped = true
            ToggleLabel.ZIndex = 2
            ToggleLabel.Parent = ToggleFrame
            
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Size = UDim2.new(0, 45, 0, 24)
            ToggleButton.Position = UDim2.new(1, -52, 0.5, -12)
            ToggleButton.BackgroundColor3 = default and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(200, 200, 200)
            ToggleButton.BorderSizePixel = 0
            ToggleButton.Text = ""
            ToggleButton.ZIndex = 2
            ToggleButton.Parent = ToggleFrame
            
            local ToggleBtnCorner = Instance.new("UICorner")
            ToggleBtnCorner.CornerRadius = UDim.new(1, 0)
            ToggleBtnCorner.Parent = ToggleButton
            
            local ToggleCircle = Instance.new("Frame")
            ToggleCircle.Size = UDim2.new(0, 18, 0, 18)
            ToggleCircle.Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleCircle.BorderSizePixel = 0
            ToggleCircle.ZIndex = 2
            ToggleCircle.Parent = ToggleButton
            
            local CircleCorner = Instance.new("UICorner")
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = ToggleCircle
            
            local toggled = default
            
            ToggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                ToggleButton.BackgroundColor3 = toggled and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(200, 200, 200)
                ToggleCircle:TweenPosition(toggled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9), "Out", "Quad", 0.2, true)
                callback(toggled)
            end)
        end
        
        function Tab:AddLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(0, 220, 0, 30)
            Label.Position = UDim2.new(1, -235, 0, 0)
            Label.AnchorPoint = Vector2.new(0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = isDarkMode and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextWrapped = true
            Label.ZIndex = 2
            Label.Parent = TabContent
            
            return Label
        end
        
        function Tab:AddTextbox(placeholder, callback)
            local TextboxFrame = Instance.new("Frame")
            TextboxFrame.Name = "TextboxFrame"
            TextboxFrame.Size = UDim2.new(0, 220, 0, 40)
            TextboxFrame.Position = UDim2.new(1, -235, 0, 0)
            TextboxFrame.AnchorPoint = Vector2.new(0, 0)
            TextboxFrame.BackgroundColor3 = isDarkMode and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(240, 240, 240)
            TextboxFrame.BorderSizePixel = 0
            TextboxFrame.ZIndex = 2
            TextboxFrame.Parent = TabContent
            
            local TextboxCorner = Instance.new("UICorner")
            TextboxCorner.CornerRadius = UDim.new(0, 8)
            TextboxCorner.Parent = TextboxFrame
            
            local Textbox = Instance.new("TextBox")
            Textbox.Size = UDim2.new(1, -20, 1, 0)
            Textbox.Position = UDim2.new(0, 10, 0, 0)
            Textbox.BackgroundTransparency = 1
            Textbox.PlaceholderText = placeholder
            Textbox.Text = ""
            Textbox.TextColor3 = isDarkMode and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
            Textbox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
            Textbox.Font = Enum.Font.Gotham
            Textbox.TextSize = 14
            Textbox.TextXAlignment = Enum.TextXAlignment.Left
            Textbox.ZIndex = 2
            Textbox.Parent = TextboxFrame
            
            Textbox.FocusLost:Connect(function()
                callback(Textbox.Text)
            end)
        end
        
        return Tab
    end
    
    return Window
end

return Library
