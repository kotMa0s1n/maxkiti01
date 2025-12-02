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
    MainFrame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = MainFrame
    
    -- Заголовок
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, -120, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar
    
    -- Кнопки управления окном
    local ButtonsFrame = Instance.new("Frame")
    ButtonsFrame.Size = UDim2.new(0, 80, 0, 25)
    ButtonsFrame.Position = UDim2.new(1, -90, 0, 8)
    ButtonsFrame.BackgroundTransparency = 1
    ButtonsFrame.Parent = TitleBar
    
    local function CreateWindowButton(color, position, name)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 20, 0, 20)
        btn.Position = position
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.Parent = ButtonsFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = btn
        
        return btn
    end
    
    local GreenBtn = CreateWindowButton(Color3.fromRGB(52, 199, 89), UDim2.new(0, 0, 0, 0), "GreenBtn")
    local YellowBtn = CreateWindowButton(Color3.fromRGB(255, 204, 0), UDim2.new(0, 30, 0, 0), "YellowBtn")
    local RedBtn = CreateWindowButton(Color3.fromRGB(255, 59, 48), UDim2.new(0, 60, 0, 0), "RedBtn")
    
    -- Поиск по вкладкам
    local SearchFrame = Instance.new("Frame")
    SearchFrame.Name = "SearchFrame"
    SearchFrame.Size = UDim2.new(0, 200, 0, 35)
    SearchFrame.Position = UDim2.new(0, 10, 0, 50)
    SearchFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    SearchFrame.BorderSizePixel = 0
    SearchFrame.Parent = MainFrame
    
    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(0, 8)
    SearchCorner.Parent = SearchFrame
    
    local SearchBox = Instance.new("TextBox")
    SearchBox.Name = "SearchBox"
    SearchBox.Size = UDim2.new(1, -10, 1, 0)
    SearchBox.Position = UDim2.new(0, 5, 0, 0)
    SearchBox.BackgroundTransparency = 1
    SearchBox.PlaceholderText = "Поиск вкладок..."
    SearchBox.Text = ""
    SearchBox.TextColor3 = Color3.fromRGB(0, 0, 0)
    SearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 14
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.Parent = SearchFrame
    
    -- Список вкладок (слева)
    local TabsListFrame = Instance.new("ScrollingFrame")
    TabsListFrame.Name = "TabsListFrame"
    TabsListFrame.Size = UDim2.new(0, 200, 0, 360)
    TabsListFrame.Position = UDim2.new(0, 10, 0, 95)
    TabsListFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    TabsListFrame.BorderSizePixel = 0
    TabsListFrame.ScrollBarThickness = 4
    TabsListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabsListFrame.Parent = MainFrame
    
    local TabsCorner = Instance.new("UICorner")
    TabsCorner.CornerRadius = UDim.new(0, 8)
    TabsCorner.Parent = TabsListFrame
    
    local TabsLayout = Instance.new("UIListLayout")
    TabsLayout.Padding = UDim.new(0, 5)
    TabsLayout.Parent = TabsListFrame
    
    -- Кнопка добавления вкладки
    local AddTabBtn = Instance.new("TextButton")
    AddTabBtn.Name = "AddTabBtn"
    AddTabBtn.Size = UDim2.new(0, 200, 0, 35)
    AddTabBtn.Position = UDim2.new(0, 10, 1, -45)
    AddTabBtn.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
    AddTabBtn.BorderSizePixel = 0
    AddTabBtn.Text = "+ Добавить вкладку"
    AddTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    AddTabBtn.Font = Enum.Font.GothamBold
    AddTabBtn.TextSize = 14
    AddTabBtn.Parent = MainFrame
    
    local AddBtnCorner = Instance.new("UICorner")
    AddBtnCorner.CornerRadius = UDim.new(0, 8)
    AddBtnCorner.Parent = AddTabBtn
    
    -- Контент вкладки (справа)
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(0, 460, 0, 410)
    ContentFrame.Position = UDim2.new(0, 220, 0, 50)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 6
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.Visible = false
    ContentFrame.Parent = MainFrame
    
    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 8)
    ContentCorner.Parent = ContentFrame
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 10)
    ContentLayout.Parent = ContentFrame
    
    -- Переменные
    local tabs = {}
    local currentTab = nil
    local isDarkMode = false
    
    -- Обновление размера canvas
    TabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabsListFrame.CanvasSize = UDim2.new(0, 0, 0, TabsLayout.AbsoluteContentSize.Y + 10)
    end)
    
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ContentFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Функция смены темы
    local function ToggleTheme()
        isDarkMode = not isDarkMode
        
        if isDarkMode then
            MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            SearchFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            SearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
            TabsListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            ContentFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            AddTabBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 210)
        else
            MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TitleBar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            TitleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
            SearchFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            SearchBox.TextColor3 = Color3.fromRGB(0, 0, 0)
            SearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
            TabsListFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            ContentFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
            AddTabBtn.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
        end
        
        -- Обновление цветов вкладок
        for _, tab in pairs(tabs) do
            if isDarkMode then
                if tab == currentTab then
                    tab.Button.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
                else
                    tab.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    tab.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
            else
                if tab == currentTab then
                    tab.Button.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
                else
                    tab.Button.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    tab.Button.TextColor3 = Color3.fromRGB(50, 50, 50)
                end
            end
        end
    end
    
    -- Функция смены вкладки
    local function SwitchTab(tab)
        for _, t in pairs(tabs) do
            t.Content.Visible = false
            if isDarkMode then
                t.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                t.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
            else
                t.Button.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                t.Button.TextColor3 = Color3.fromRGB(50, 50, 50)
            end
        end
        
        tab.Content.Visible = true
        tab.Button.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
        tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    
    YellowBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)
    
    GreenBtn.MouseButton1Click:Connect(ToggleTheme)
    
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
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
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
        Tab.Name = tabName
        
        -- Кнопка вкладки
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName
        TabButton.Size = UDim2.new(1, -10, 0, 35)
        TabButton.BackgroundColor3 = isDarkMode and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(230, 230, 230)
        TabButton.BorderSizePixel = 0
        TabButton.Text = tabName
        TabButton.TextColor3 = isDarkMode and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(50, 50, 50)
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 14
        TabButton.Parent = TabsListFrame
        
        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 6)
        TabBtnCorner.Parent = TabButton
        
        -- Кнопка удаления вкладки
        local DeleteBtn = Instance.new("TextButton")
        DeleteBtn.Size = UDim2.new(0, 25, 0, 25)
        DeleteBtn.Position = UDim2.new(1, -30, 0, 5)
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
        DeleteBtn.BorderSizePixel = 0
        DeleteBtn.Text = "×"
        DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        DeleteBtn.Font = Enum.Font.GothamBold
        DeleteBtn.TextSize = 18
        DeleteBtn.Parent = TabButton
        
        local DelBtnCorner = Instance.new("UICorner")
        DelBtnCorner.CornerRadius = UDim.new(0, 4)
        DelBtnCorner.Parent = DeleteBtn
        
        -- Контент вкладки
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = tabName .. "Content"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 6
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.Visible = false
        TabContent.Parent = ContentFrame.Parent
        
        local TabLayout = Instance.new("UIListLayout")
        TabLayout.Padding = UDim.new(0, 10)
        TabLayout.Parent = TabContent
        
        TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 20)
        end)
        
        Tab.Button = TabButton
        Tab.Content = TabContent
        
        TabButton.MouseButton1Click:Connect(function()
            SwitchTab(Tab)
        end)
        
        DeleteBtn.MouseButton1Click:Connect(function()
            TabButton:Destroy()
            TabContent:Destroy()
            table.remove(tabs, table.find(tabs, Tab))
            if currentTab == Tab and #tabs > 0 then
                SwitchTab(tabs[1])
            end
        end)
        
        table.insert(tabs, Tab)
        
        if #tabs == 1 then
            SwitchTab(Tab)
        end
        
        -- Tab API
        function Tab:AddButton(text, callback)
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, -20, 0, 40)
            Button.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
            Button.BorderSizePixel = 0
            Button.Text = text
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            Button.Font = Enum.Font.GothamSemibold
            Button.TextSize = 14
            Button.Parent = TabContent
            
            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 8)
            BtnCorner.Parent = Button
            
            Button.MouseButton1Click:Connect(callback)
        end
        
        function Tab:AddToggle(text, default, callback)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, -20, 0, 40)
            ToggleFrame.BackgroundColor3 = isDarkMode and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(240, 240, 240)
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Parent = TabContent
            
            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 8)
            ToggleCorner.Parent = ToggleFrame
            
            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = text
            ToggleLabel.TextColor3 = isDarkMode and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
            ToggleLabel.Font = Enum.Font.Gotham
            ToggleLabel.TextSize = 14
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.Parent = ToggleFrame
            
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Size = UDim2.new(0, 45, 0, 25)
            ToggleButton.Position = UDim2.new(1, -55, 0.5, -12)
            ToggleButton.BackgroundColor3 = default and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(200, 200, 200)
            ToggleButton.BorderSizePixel = 0
            ToggleButton.Text = ""
            ToggleButton.Parent = ToggleFrame
            
            local ToggleBtnCorner = Instance.new("UICorner")
            ToggleBtnCorner.CornerRadius = UDim.new(1, 0)
            ToggleBtnCorner.Parent = ToggleButton
            
            local ToggleCircle = Instance.new("Frame")
            ToggleCircle.Size = UDim2.new(0, 19, 0, 19)
            ToggleCircle.Position = default and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleCircle.BorderSizePixel = 0
            ToggleCircle.Parent = ToggleButton
            
            local CircleCorner = Instance.new("UICorner")
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = ToggleCircle
            
            local toggled = default
            
            ToggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                ToggleButton.BackgroundColor3 = toggled and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(200, 200, 200)
                ToggleCircle:TweenPosition(toggled and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 3, 0.5, -9), "Out", "Quad", 0.2, true)
                callback(toggled)
            end)
        end
        
        function Tab:AddLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 0, 30)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = isDarkMode and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextWrapped = true
            Label.Parent = TabContent
        end
        
        function Tab:AddTextbox(placeholder, callback)
            local TextboxFrame = Instance.new("Frame")
            TextboxFrame.Size = UDim2.new(1, -20, 0, 40)
            TextboxFrame.BackgroundColor3 = isDarkMode and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(240, 240, 240)
            TextboxFrame.BorderSizePixel = 0
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
            Textbox.Parent = TextboxFrame
            
            Textbox.FocusLost:Connect(function()
                callback(Textbox.Text)
            end)
        end
        
        return Tab
    end
    
    AddTabBtn.MouseButton1Click:Connect(function()
        Window:CreateTab("Новая вкладка " .. (#tabs + 1))
    end)
    
    return Window
end

return Library
