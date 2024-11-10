local _, library = pcall(loadstring(game:HttpGet("https://raw.githubusercontent.com/TrixAde/Osmium/main/OsmiumLibrary.lua")))
local window = library:CreateWindow("All script")
local tab = window:CreateTab("хз")
local tabCredits = window:CreateTab("Создатели")
local togglefarm = false
local pausedelay = 60
local farmvalue = false
task.spawn(function()
	repeat task.wait() until not mouse.Target:FindFirstChild("AttachmentHighlight")
	-- Code
end)
function delayactivate()
    pcall(function()
            task.spawn(function()
        task.wait(pausedelay)
        togglefarm = false 
        task.wait(4)
        if farmvalue == true then 
            togglefarm = true
        end
        if togglefarm == true then
            delayactivate()
        end
    end)
    end)
end
local button = tab:CreateButton("Забрать пистолет", function()
    pcall(function()
        
    end)
end)
local textbox = tab:CreateTextbox("Временный стоп авто фарма (секунды)", function(value)
    pausedelay = tonumber(value)
end, "Впишите число")
local button = tabCredits:CreateButton("maxkiti01 (Вставляется в буфер обмена)", function()
    pcall(function()
        setclipboard("https://t.me/+gyH9PbgbmdwwMTky")
    end)
end)
while true do 
    pcall(function()
            if togglefarm == true then 
        game:GetService("Workspace").Gravity = 500
        for i, v in pairs(game:GetService("Workspace").Cars:GetChildren()) do
            if tostring(v.Owner.Value) == game:GetService("Players").LocalPlayer.Name then 
                v.Main.CFrame = CFrame.new(0, 500, 0)
                wait(1)
            end
        end
    else 
        game:GetService("Workspace").Gravity = 196.2
        wait()
    end
    end)
end
