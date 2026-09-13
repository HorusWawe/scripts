local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Tower of Hell | Zero",
   LoadingTitle = "Zero TOH Загружен",
   LoadingSubtitle = "от Zero",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "ZeroTOH",
      FileName = "Конфиг"
   },
   Discord = {
      Enabled = false
   },
   KeySystem = false
})

local TabTower = Window:CreateTab("Башня", 4483362458)
local TabPlayer = Window:CreateTab("Игрок", 4483362458)
local TabInfo = Window:CreateTab("Информация", 4483362458)

local plr = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Переменные для функций полёта и бесконечного прыжка
local flying = false
local flySpeed = 50
local bodyGyro, bodyVelocity

-- ==================== ВКЛАДКА: БАШНЯ ====================

TabTower:CreateToggle({
   Name = "Полный обход античита",
   CurrentValue = false,
   Flag = "BypassAC",
   Callback = function(Value)
      if Value then
         pcall(function()
            if plr.PlayerScripts:FindFirstChild("LocalScript") then
               hookfunction(getsenv(plr.PlayerScripts.LocalScript).kick, function() return nil end)
               hookfunction(getsenv(plr.PlayerScripts.LocalScript).isAllowedToSit, function() return nil end)
            end

            local rawTable = getrawmetatable(plr)
            local oldNamecall = rawTable.__namecall

            setreadonly(rawTable, false)
            rawTable.__namecall = function(self, ...)
               if getnamecallmethod() == "Kick" then
                  return nil
               end
               return oldNamecall(self, ...)
            end
            setreadonly(rawTable, true)
         end)
      end
   end,
})

TabTower:CreateButton({
   Name = "Запустить Infinite Yield",
   Callback = function()
      loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
   end,
})

TabTower:CreateButton({
   Name = "Авто-победа (Пройти башню)",
   Callback = function()
      local i = 0
      local finishPart = workspace:FindFirstChild("tower") and workspace.tower.sections.finish.exit.carpet
      if not finishPart or not plr.Character or not plr.Character:FindFirstChild("PrimaryPart") then return end

      while (finishPart.Position - plr.Character.PrimaryPart.Position).Magnitude > 3.5 do
         i += 1
         plr.Character.PrimaryPart.Anchored = true
         plr.Character.PrimaryPart.CFrame = CFrame.new(finishPart.Position.X, i, finishPart.Position.Z)
         task.wait(0.0145)
         plr.Character.PrimaryPart.Anchored = false
         
         if (finishPart.Position - plr.Character.PrimaryPart.Position).Magnitude < 3.5 then
            plr.Character.PrimaryPart.Anchored = false
            plr.Character.PrimaryPart.CFrame = CFrame.new(finishPart.Position + Vector3.new(0, 3, 0))
            break
         end
      end
   end,
})

-- ==================== ВКЛАДКА: ИГРОК ====================

-- Бессмертие (Удаление триггеров урона у лазеров)
TabPlayer:CreateToggle({
   Name = "Бессмертие (Игнорировать лазеры)",
   CurrentValue = false,
   Flag = "GodMode",
   Callback = function(Value)
      getgenv().GodMode = Value
      task.spawn(function()
         while getgenv().GodMode do
            for _, v in pairs(workspace:GetDescendants()) do
               if v:IsA("TouchTransmitter") and v.Parent and (v.Parent.Name == "kill" or v.Parent.Name == "Kill" or v.Parent.Parent.Name == "Killers") then
                  v:Destroy()
               end
            end
            task.wait(1)
         end
      end)
   end,
})

-- Полёт
TabPlayer:CreateToggle({
   Name = "Режим полёта (Fly)",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      flying = Value
      local char = plr.Character
      if not char or not char:FindFirstChild("HumanoidRootPart") then return end

      if flying then
         bodyGyro = Instance.new("BodyGyro")
         bodyVelocity = Instance.new("BodyVelocity")
         
         bodyGyro.P = 9e4
         bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
         bodyGyro.cframe = char.HumanoidRootPart.CFrame
         bodyGyro.Parent = char.HumanoidRootPart

         bodyVelocity.velocity = Vector3.new(0, 0, 0)
         bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
         bodyVelocity.Parent = char.HumanoidRootPart

         task.spawn(function()
            while flying and task.wait() do
               local camera = workspace.CurrentCamera
               bodyGyro.cframe = camera.CFrame
               local moveDir = char.Humanoid.MoveDirection
               if moveDir.Magnitude > 0 then
                  bodyVelocity.velocity = camera.CFrame.LookVector * (moveDir.Magnitude * flySpeed)
               else
                  bodyVelocity.velocity = Vector3.new(0, 0, 0)
               end
            end
         end)
      else
         if bodyGyro then bodyGyro:Destroy() end
         if bodyVelocity then bodyVelocity:Destroy() end
      end
   end,
})

-- Бесконечный прыжок
local infJumpConnection
TabPlayer:CreateToggle({
   Name = "Бесконечный прыжок",
   CurrentValue = false,
   Flag = "InfJump",
   Callback = function(Value)
      getgenv().InfJump = Value
      if Value then
         infJumpConnection = UserInputService.JumpRequest:Connect(function()
            if getgenv().InfJump and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
               plr.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
            end
         end)
      else
         if infJumpConnection then infJumpConnection:Disconnect() end
      end
   end,
})

-- Скорость
TabPlayer:CreateSlider({
   Name = "Скорость бега",
   Range = {0, 500},
   Increment = 1,
   Suffix = " Скорость",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
   Callback = function(Value)
      if plr.Character and plr.Character:FindFirstChild("Humanoid") then
         plr.Character.Humanoid.WalkSpeed = Value
      end
   end,
})

-- Сила прыжка
TabPlayer:CreateSlider({
   Name = "Сила прыжка",
   Range = {0, 500},
   Increment = 1,
   Suffix = " Сила",
   CurrentValue = 50,
   Flag = "JumpPowerSlider",
   Callback = function(Value)
      if plr.Character and plr.Character:FindFirstChild("Humanoid") then
         plr.Character.Humanoid.UseJumpPower = true
         plr.Character.Humanoid.JumpPower = Value
      end
   end,
})

-- Гравитация
TabPlayer:CreateSlider({
   Name = "Гравитация",
   Range = {0, 196.2},
   Increment = 1,
   Suffix = " Гравитация",
   CurrentValue = 196.2,
   Flag = "GravitySlider",
   Callback = function(Value)
      workspace.Gravity = Value
   end,
})

-- Получить все предметы
TabPlayer:CreateButton({
   Name = "Выдать себе все предметы",
   Callback = function()
      local gear = game:GetService("ReplicatedStorage"):FindFirstChild("Assets") and game:GetService("ReplicatedStorage").Assets:FindFirstChild("Gear")
      if gear then
         for _, i in pairs(gear:GetChildren()) do
            if i:IsA("Tool") then
               local cloned = i:Clone()
               cloned.Parent = plr.Backpack
               cloned.Enabled = true
            end
         end
      end
   end,
})

-- ==================== ВКЛАДКА: ИНФОРМАЦИЯ ====================

TabInfo:CreateLabel("Скрипт: Zero TOH")
TabInfo:CreateLabel("Автор: Zero")
TabInfo:CreateLabel("Версия: Релиз")
