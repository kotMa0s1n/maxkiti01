local script = Instance.new('LocalScript')
 
 
		local currentX = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.X
		local currentY = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.Y
		local currentZ = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.Z	
 
		if workspace:FindFirstChild("GunDrop") ~= nil then
 
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = workspace:FindFirstChild("GunDrop").CFrame	
		wait(.16)	
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(currentX, currentY, currentZ)
 
		else
 
game:GetService("StarterGui"):SetCore("SendNotification",{
Title = "Нет пистолета!",
Text = "Пистолет пока не выпал, подожди немного",
Duration = 2,
Button1 = "Окей",
Callback = cb
})
 
 
		wait(3)
 
 
		end
