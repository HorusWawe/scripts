--========================================================--
--              NEBULA HUB | MURDER MYSTERY 2             --
--========================================================--

local Nebula = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/HorusWawe/scripts/refs/heads/main/nebula-ui.lua"
))()

local Window = Nebula:CreateWindow({
    Name = "Nebula Hub | Murder Mystery 2",
    Subtitle = "v5.0",
    Size = UDim2.fromOffset(580, 460),
    Theme = "Nebula"
})

--========================================================--
--                         TABS                           --
--========================================================--

local CombatTab = Window:AddTab("Combat", "rbxassetid://6034509993")
local VisualsTab = Window:AddTab("Visuals", "rbxassetid://6034509993")
local MovementTab = Window:AddTab("Movement", "rbxassetid://6034509993")
local MiscTab = Window:AddTab("Misc", "rbxassetid://6034509993")


--========================================================--
--                       SERVICES                         --
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera


--========================================================--
--                         STATE                          --
--========================================================--

local State = {
    SheriffAim = false,
    SilentAim = false,

    KnifeAim = false,
    KnifeFOV = 120,

    ESP = false,

    Speed = 16,
    JumpPower = 50,

    SpeedGlitch = false,
    SpeedGlitchSpeed = 50,

    InfJump = false,
    Noclip = false,

    Fly = false,
    FlySpeed = 50,

    AntiFling = false,
    FlingTarget = "",

    AutoFarm = false
}


--========================================================--
--                    CHARACTER HELPERS                   --
--========================================================--

local function GetCharacter()
    return LocalPlayer.Character
end


local function GetHumanoid()
    local character = GetCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end


local function GetRoot()
    local character = GetCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end


--========================================================--
--                       MM2 ROLES                        --
--========================================================--

local function GetRoles()

    local roles = {
        Murderer = nil,
        Sheriff = nil
    }

    for _, player in ipairs(Players:GetPlayers()) do

        local character = player.Character
        local backpack = player:FindFirstChild("Backpack")

        if character then

            local knife =
                character:FindFirstChild("Knife")
                or (backpack and backpack:FindFirstChild("Knife"))

            local gun =
                character:FindFirstChild("Gun")
                or (backpack and backpack:FindFirstChild("Gun"))

            if knife then
                roles.Murderer = player
            elseif gun then
                roles.Sheriff = player
            end
        end
    end

    return roles
end


--========================================================--
--                         COMBAT                         --
--========================================================--

local CombatSection = CombatTab:AddSection("Sheriff & Knife")


CombatSection:AddToggle({
    Name = "Sheriff Aim (Lock)",
    Default = false,

    Callback = function(value)
        State.SheriffAim = value
    end
})


CombatSection:AddToggle({
    Name = "Sheriff Silent Aim",
    Default = false,

    Callback = function(value)
        State.SilentAim = value
    end
})


CombatSection:AddToggle({
    Name = "Knife Throw Aim (Murderer)",
    Default = false,

    Callback = function(value)
        State.KnifeAim = value
    end
})


CombatSection:AddSlider({
    Name = "Knife FOV",
    Min = 30,
    Max = 360,
    Default = 120,

    Callback = function(value)
        State.KnifeFOV = value
    end
})


--========================================================--
--                     SHERIFF AIM                        --
--========================================================--

RunService.RenderStepped:Connect(function()

    if not State.SheriffAim then
        return
    end

    local roles = GetRoles()
    local murderer = roles.Murderer

    if not murderer then
        return
    end

    local character = murderer.Character

    if not character then
        return
    end

    local targetRoot =
        character:FindFirstChild("HumanoidRootPart")

    if not targetRoot then
        return
    end

    local localCharacter = GetCharacter()

    if not localCharacter then
        return
    end

    if not localCharacter:FindFirstChild("Gun") then
        return
    end

    Camera.CFrame = CFrame.new(
        Camera.CFrame.Position,
        targetRoot.Position
    )
end)


--========================================================--
--                         VISUALS                        --
--========================================================--

local VisualsSection = VisualsTab:AddSection("Player ESP")


VisualsSection:AddToggle({
    Name = "Enable Player ESP",
    Default = false,

    Callback = function(value)
        State.ESP = value
    end
})


--========================================================--
--                         ESP                             --
--========================================================--

local ESPObjects = {}


local function RemoveESP(player)

    local data = ESPObjects[player]

    if not data then
        return
    end

    if data.Highlight then
        data.Highlight:Destroy()
    end

    if data.NameTag then
        data.NameTag:Destroy()
    end

    ESPObjects[player] = nil
end


local function CreateESP(player)

    if player == LocalPlayer then
        return
    end

    if ESPObjects[player] then
        return
    end

    local highlight = Instance.new("Highlight")

    highlight.Name = "Nebula_ESP"
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0


    --================ NAME TAG ================--

    local nameTag = Instance.new("BillboardGui")

    nameTag.Name = "Nebula_Name"
    nameTag.Size = UDim2.fromOffset(200, 35)
    nameTag.StudsOffset = Vector3.new(0, 3, 0)
    nameTag.AlwaysOnTop = true
    nameTag.Enabled = false


    local label = Instance.new("TextLabel")

    label.Name = "Name"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = player.DisplayName
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.25
    label.TextColor3 = Color3.fromRGB(255, 255, 255)

    label.Parent = nameTag


    ESPObjects[player] = {
        Highlight = highlight,
        NameTag = nameTag,
        Label = label
    }
end


local function UpdateESP()

    local roles = GetRoles()

    for player, data in pairs(ESPObjects) do

        local character = player.Character

        if not State.ESP or not character then

            data.Highlight.Parent = nil
            data.NameTag.Parent = nil
            data.NameTag.Enabled = false

        else

            data.Highlight.Parent = character

            local head =
                character:FindFirstChild("Head")

            if head then
                data.NameTag.Parent = head
                data.NameTag.Enabled = true
            else
                data.NameTag.Parent = nil
                data.NameTag.Enabled = false
            end


            --=============== ROLE COLORS ===============--

            if player == roles.Murderer then

                data.Highlight.FillColor =
                    Color3.fromRGB(255, 50, 50)

                data.Label.TextColor3 =
                    Color3.fromRGB(255, 70, 70)

                data.Label.Text =
                    player.DisplayName .. "  [MURDERER]"

            elseif player == roles.Sheriff then

                data.Highlight.FillColor =
                    Color3.fromRGB(50, 150, 255)

                data.Label.TextColor3 =
                    Color3.fromRGB(80, 170, 255)

                data.Label.Text =
                    player.DisplayName .. "  [SHERIFF]"

            else

                data.Highlight.FillColor =
                    Color3.fromRGB(0, 255, 100)

                data.Label.TextColor3 =
                    Color3.fromRGB(255, 255, 255)

                data.Label.Text =
                    player.DisplayName
            end
        end
    end
end


Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
end)


Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)


for _, player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end


RunService.RenderStepped:Connect(UpdateESP)


--========================================================--
--                       MOVEMENT                         --
--========================================================--

local MoveSection = MovementTab:AddSection("Movement Mods")


--================ WALK SPEED ================--

MoveSection:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 150,
    Default = 16,

    Callback = function(value)

        State.Speed = value

        if not State.SpeedGlitch then

            local humanoid = GetHumanoid()

            if humanoid then
                humanoid.WalkSpeed = value
            end
        end
    end
})


--================ JUMP POWER ================--

MoveSection:AddSlider({
    Name = "JumpPower",
    Min = 50,
    Max = 300,
    Default = 50,

    Callback = function(value)

        State.JumpPower = value

        local humanoid = GetHumanoid()

        if humanoid then
            humanoid.JumpPower = value
        end
    end
})


--================ SPEEDGLITCH ================--

MoveSection:AddToggle({
    Name = "Speedglitch",
    Default = false,

    Callback = function(value)

        State.SpeedGlitch = value

        local humanoid = GetHumanoid()

        if humanoid then
            humanoid.WalkSpeed = State.Speed
        end
    end
})


MoveSection:AddSlider({
    Name = "Speedglitch Speed",
    Min = 16,
    Max = 200,
    Default = 50,

    Callback = function(value)
        State.SpeedGlitchSpeed = value
    end
})


--================ INFINITE JUMP ================--

MoveSection:AddToggle({
    Name = "Infinite Jump",
    Default = false,

    Callback = function(value)
        State.InfJump = value
    end
})


--================ NOCLIP ================--

MoveSection:AddToggle({
    Name = "Noclip",
    Default = false,

    Callback = function(value)
        State.Noclip = value
    end
})


--================ FLY ================--

MoveSection:AddToggle({
    Name = "Fly",
    Default = false,

    Callback = function(value)
        State.Fly = value
    end
})


MoveSection:AddSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = 50,

    Callback = function(value)
        State.FlySpeed = value
    end
})


--========================================================--
--                  SPEEDGLITCH LOOP                      --
--========================================================--

RunService.Heartbeat:Connect(function()

    local humanoid = GetHumanoid()

    if not humanoid then
        return
    end

    if not State.SpeedGlitch then

        if humanoid.WalkSpeed ~= State.Speed then
            humanoid.WalkSpeed = State.Speed
        end

        return
    end


    local state = humanoid:GetState()

    local airborne =
        state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.Freefall
        or state == Enum.HumanoidStateType.FallingDown


    if airborne then

        if humanoid.WalkSpeed ~= State.SpeedGlitchSpeed then
            humanoid.WalkSpeed = State.SpeedGlitchSpeed
        end

    else

        if humanoid.WalkSpeed ~= State.Speed then
            humanoid.WalkSpeed = State.Speed
        end
    end
end)


--========================================================--
--                    CHARACTER RESPAWN                   --
--========================================================--

LocalPlayer.CharacterAdded:Connect(function(character)

    local humanoid =
        character:WaitForChild("Humanoid", 10)

    if not humanoid then
        return
    end

    task.wait(0.25)

    humanoid.WalkSpeed = State.Speed
    humanoid.JumpPower = State.JumpPower

    -- Speedglitch сам переключит скорость
    -- при следующем прыжке.
end)


--========================================================--
--                    INFINITE JUMP                       --
--========================================================--

UserInputService.JumpRequest:Connect(function()

    if not State.InfJump then
        return
    end

    local humanoid = GetHumanoid()

    if humanoid then

        humanoid:ChangeState(
            Enum.HumanoidStateType.Jumping
        )
    end
end)


--========================================================--
--                         NOCLIP                         --
--========================================================--

RunService.Stepped:Connect(function()

    if not State.Noclip then
        return
    end

    local character = GetCharacter()

    if not character then
        return
    end

    for _, part in ipairs(character:GetDescendants()) do

        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)


--========================================================--
--                           FLY                          --
--========================================================--

local FlyVelocity = nil
local FlyGyro = nil


local function StopFly()

    if FlyVelocity then
        FlyVelocity:Destroy()
        FlyVelocity = nil
    end

    if FlyGyro then
        FlyGyro:Destroy()
        FlyGyro = nil
    end
end


local function StartFly()

    StopFly()

    local root = GetRoot()

    if not root then
        return
    end


    FlyVelocity = Instance.new("BodyVelocity")

    FlyVelocity.Name = "Nebula_FlyVelocity"
    FlyVelocity.MaxForce =
        Vector3.new(math.huge, math.huge, math.huge)

    FlyVelocity.Velocity =
        Vector3.zero

    FlyVelocity.Parent = root


    FlyGyro = Instance.new("BodyGyro")

    FlyGyro.Name = "Nebula_FlyGyro"
    FlyGyro.MaxTorque =
        Vector3.new(math.huge, math.huge, math.huge)

    FlyGyro.P =
        90000

    FlyGyro.D =
        500

    FlyGyro.CFrame =
        Camera.CFrame

    FlyGyro.Parent = root
end


RunService.RenderStepped:Connect(function()

    if not State.Fly then

        if FlyVelocity or FlyGyro then
            StopFly()
        end

        return
    end


    local root = GetRoot()
    local humanoid = GetHumanoid()

    if not root or not humanoid then

        StopFly()

        return
    end


    if not FlyVelocity or not FlyGyro then
        StartFly()
    end


    if not FlyVelocity or not FlyGyro then
        return
    end


    humanoid.PlatformStand = true


    local direction = Vector3.zero


    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction += Camera.CFrame.LookVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction -= Camera.CFrame.LookVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction += Camera.CFrame.RightVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction -= Camera.CFrame.RightVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction += Vector3.yAxis
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction -= Vector3.yAxis
    end


    if direction.Magnitude > 0 then
        direction = direction.Unit
    end


    FlyVelocity.Velocity =
        direction * State.FlySpeed

    FlyGyro.CFrame =
        Camera.CFrame
end)


-- Возвращаем обычное состояние после выключения Fly

RunService.Heartbeat:Connect(function()

    if not State.Fly then

        local humanoid = GetHumanoid()

        if humanoid and humanoid.PlatformStand then
            humanoid.PlatformStand = false
        end
    end
end)


--========================================================--
--                   FLY RESPAWN CLEANUP                  --
--========================================================--

LocalPlayer.CharacterAdded:Connect(function()

    StopFly()

    task.wait(0.5)

    if State.Fly then
        StartFly()
    end
end)


--========================================================--
--                         MISC                           --
--========================================================--

local MiscSection = MiscTab:AddSection("Utilities & Farm")


MiscSection:AddToggle({
    Name = "Anti-Fling",
    Default = false,

    Callback = function(value)
        State.AntiFling = value
    end
})


MiscSection:AddTextbox({
    Name = "Fling Target Name",
    Placeholder = "Player Name",

    Callback = function(value)
        State.FlingTarget = value
    end
})


--========================================================--
--                         FLING                          --
--========================================================--

MiscSection:AddButton({
    Name = "Execute Fling",

    Callback = function()

        local target =
            Players:FindFirstChild(State.FlingTarget)

        if not target then
            return
        end

        local targetCharacter = target.Character
        local localCharacter = LocalPlayer.Character

        if not targetCharacter or not localCharacter then
            return
        end

        local root =
            localCharacter:FindFirstChild(
                "HumanoidRootPart"
            )

        local targetRoot =
            targetCharacter:FindFirstChild(
                "HumanoidRootPart"
            )

        if not root or not targetRoot then
            return
        end


        local angularVelocity =
            Instance.new("BodyAngularVelocity")

        angularVelocity.MaxTorque =
            Vector3.new(1, 1, 1) * math.huge

        angularVelocity.AngularVelocity =
            Vector3.new(0, 99999, 0)

        angularVelocity.Parent = root


        for _ = 1, 50 do

            if not root.Parent or not targetRoot.Parent then
                break
            end

            root.CFrame = targetRoot.CFrame

            task.wait(0.05)
        end


        angularVelocity:Destroy()
    end
})


--========================================================--
--                       AUTO FARM                       --
--========================================================--

MiscSection:AddToggle({
    Name = "Auto Farm Coins",
    Default = false,

    Callback = function(value)

        State.AutoFarm = value

        if not value then
            return
        end


        task.spawn(function()

            while State.AutoFarm do

                task.wait(0.1)

                local coinContainer =
                    workspace:FindFirstChild("Normal")
                    or workspace:FindFirstChild(
                        "CoinContainer",
                        true
                    )

                local root = GetRoot()

                if coinContainer and root then

                    for _, coin in ipairs(
                        coinContainer:GetChildren()
                    ) do

                        if not State.AutoFarm then
                            break
                        end


                        if coin:IsA("BasePart")
                            and coin.Name == "Coin_Container" then

                            root.CFrame =
                                coin.CFrame

                            task.wait(0.5)
                        end
                    end
                end
            end
        end)
    end
})


--========================================================--
--                      ANTI FLING                        --
--========================================================--

RunService.Stepped:Connect(function()

    if not State.AntiFling then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do

        if player ~= LocalPlayer
            and player.Character then

            for _, part in ipairs(
                player.Character:GetDescendants()
            ) do

                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)


--========================================================--
--                       NOTIFY                           --
--========================================================--

Window:Notify({
    Title = "Nebula Hub",
    Content = "MM2 Script Loaded Successfully!",
    Duration = 5
})
