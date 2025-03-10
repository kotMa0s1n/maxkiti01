local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

local Window = Library.CreateLib("MAXI HUB Universal", "DarkTheme")


local Tab = Window:NewTab("Universal")
local Section = Tab:NewSection("Universal")


Section:NewSlider("WalkSpeed", "Changes WalkSpeed", 500, 16, function(v) -- 500 (MaxValue) | 0 (MinValue)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
end)

Section:NewSlider("JumpPower", "Changes JumpPower", 500, 50, function(v) -- 500 (MaxValue) | 0 (MinValue)
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = v
    game.Players.LocalPlayer.Character.Humanoid.JumpHeight = v
end)
