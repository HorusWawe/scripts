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
--                  NEBULA VFX / ENVIRONMENT              --
--       ДОБАВЛЕНО ПОВЕРХ СУЩЕСТВУЮЩЕЙ АРХИТЕКТУРЫ        --
--========================================================--

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VFXRoot
local EnvironmentRoot
local VFXConnections = {}

local VFXState = {
    Aura = false,
    Orbit = false,
    Footsteps = false,
    Wings = false,
    BodyParticles = false,
    Trail = false,
    SkyParticles = false,
    Environment = false,
    Rainbow = false,

    AuraColor = Color3.fromRGB(170, 70, 255),
    WingColor = Color3.fromRGB(140, 75, 255),
    ParticleColor = Color3.fromRGB(220, 170, 255),
    TrailColor = Color3.fromRGB(155, 80, 255),

    AuraRadius = 3.4,
    OrbitRadius = 3.2,
    OrbitCount = 8,
    SkyParticleCount = 22,
}

local VFXObjects = {}

local EnvironmentBackup = {
    ClockTime = nil,
    Brightness = nil,
    Ambient = nil,
    OutdoorAmbient = nil,
    ColorShiftTop = nil,
    ColorShiftBottom = nil,
    FogColor = nil,
    FogStart = nil,
    FogEnd = nil,
    ExposureCompensation = nil,
}

local SkyParticleData = {}
local LastFootstep = 0
local LastFootPosition

local function SafeDestroy(object)
    if object then
        pcall(function()
            object:Destroy()
        end)
    end
end

local function DisconnectAll(list)
    for i = #list, 1, -1 do
        local connection = list[i]
        list[i] = nil
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function NewFolder(name, parent)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function NewPart(name, parent, size, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size or Vector3.one
    part.Color = color or Color3.new(1, 1, 1)
    part.Material = material or Enum.Material.Neon
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Locked = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function NewBall(name, parent, diameter, color)
    local part = NewPart(
        name,
        parent,
        Vector3.new(diameter, diameter, diameter),
        color,
        Enum.Material.Neon
    )
    part.Shape = Enum.PartType.Ball
    return part
end

local function RainbowColor(offset)
    local hue = ((os.clock() * 0.08) + (offset or 0)) % 1
    return Color3.fromHSV(hue, 0.85, 1)
end

local function VFXColor(base, offset)
    if VFXState.Rainbow then
        return RainbowColor(offset)
    end
    return base
end

local function EnsureVFXRoot()
    local character = GetCharacter()
    if not character then
        return nil
    end

    if VFXRoot and VFXRoot.Parent == character then
        return VFXRoot
    end

    SafeDestroy(VFXRoot)
    VFXRoot = NewFolder("NebulaVFX", character)
    return VFXRoot
end

local function EnsureEnvironmentRoot()
    if EnvironmentRoot and EnvironmentRoot.Parent then
        return EnvironmentRoot
    end

    EnvironmentRoot = NewFolder("NebulaEnvironment", workspace)
    return EnvironmentRoot
end

--========================================================--
--                         AURA                            --
--========================================================--

local function DestroyAura()
    SafeDestroy(VFXObjects.Aura)
    VFXObjects.Aura = nil
    VFXObjects.AuraData = nil
end

local function CreateAura()
    DestroyAura()

    if not VFXState.Aura then
        return
    end

    local root = GetRoot()
    local folder = EnsureVFXRoot()

    if not root or not folder then
        return
    end

    local aura = NewFolder("Aura", folder)
    local rings = {}
    local nodes = {}

    for i = 1, 3 do
        local ring = NewPart(
            "Ring_" .. i,
            aura,
            Vector3.new(0.08, 0.08, 0.08),
            VFXState.AuraColor,
            Enum.Material.Neon
        )

        ring.Shape = Enum.PartType.Cylinder

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Cylinder
        mesh.Scale = Vector3.new(
            VFXState.AuraRadius + i * 0.45,
            0.045,
            VFXState.AuraRadius + i * 0.45
        )
        mesh.Parent = ring

        rings[i] = {
            Part = ring,
            Mesh = mesh,
            Phase = i * 0.8,
        }
    end

    for i = 1, 18 do
        local node = NewBall(
            "Node_" .. i,
            aura,
            0.14,
            VFXState.AuraColor
        )

        nodes[i] = {
            Part = node,
            Phase = i * (math.pi * 2 / 18),
            Height = 0.35 + (i % 4) * 0.28,
        }
    end

    VFXObjects.Aura = aura
    VFXObjects.AuraData = {
        Rings = rings,
        Nodes = nodes,
    }
end

local function UpdateAura()
    if not VFXState.Aura then
        return
    end

    local root = GetRoot()
    local data = VFXObjects.AuraData

    if not root or not data then
        return
    end

    local now = os.clock()
    local color = VFXColor(VFXState.AuraColor)

    for index, item in ipairs(data.Rings) do
        if item.Part and item.Part.Parent then
            item.Part.CFrame =
                root.CFrame
                * CFrame.new(
                    0,
                    0.25 + math.sin(now * 2 + item.Phase) * 0.08,
                    0
                )
                * CFrame.Angles(
                    0,
                    now * (0.6 + index * 0.15),
                    0
                )

            item.Part.Color = color
        end
    end

    for index, item in ipairs(data.Nodes) do
        if item.Part and item.Part.Parent then
            local angle =
                item.Phase
                + now * (0.7 + index * 0.012)

            local radius =
                VFXState.AuraRadius
                + math.sin(now * 1.8 + index) * 0.16

            item.Part.CFrame =
                CFrame.new(root.Position)
                * CFrame.new(
                    math.cos(angle) * radius,
                    item.Height
                        + math.sin(now * 2.4 + index) * 0.3,
                    math.sin(angle) * radius
                )

            item.Part.Color =
                VFXColor(VFXState.AuraColor, index / 18)
        end
    end
end

--========================================================--
--                         ORBIT                           --
--========================================================--

local function DestroyOrbit()
    SafeDestroy(VFXObjects.Orbit)
    VFXObjects.Orbit = nil
    VFXObjects.OrbitData = nil
end

local function CreateOrbit()
    DestroyOrbit()

    if not VFXState.Orbit then
        return
    end

    local root = GetRoot()
    local folder = EnsureVFXRoot()

    if not root or not folder then
        return
    end

    local orbit = NewFolder("Orbit", folder)
    local objects = {}

    for i = 1, VFXState.OrbitCount do
        local orb = NewBall(
            "Orb_" .. i,
            orbit,
            0.17,
            VFXState.ParticleColor
        )

        objects[i] = {
            Part = orb,
            Phase = i * (math.pi * 2 / VFXState.OrbitCount),
            Height = 0.2 + (i % 4) * 0.42,
        }
    end

    VFXObjects.Orbit = orbit
    VFXObjects.OrbitData = objects
end

local function UpdateOrbit()
    if not VFXState.Orbit then
        return
    end

    local root = GetRoot()
    local objects = VFXObjects.OrbitData

    if not root or not objects then
        return
    end

    local now = os.clock()

    for index, item in ipairs(objects) do
        if item.Part and item.Part.Parent then
            local angle =
                item.Phase
                + now * (0.8 + (index % 3) * 0.12)

            local radius =
                VFXState.OrbitRadius
                + math.sin(now * 1.6 + index) * 0.2

            item.Part.CFrame =
                CFrame.new(root.Position)
                * CFrame.new(
                    math.cos(angle) * radius,
                    item.Height
                        + math.sin(now * 2.1 + index) * 0.3,
                    math.sin(angle) * radius
                )

            item.Part.Color =
                VFXColor(
                    VFXState.ParticleColor,
                    index / #objects
                )
        end
    end
end

--========================================================--
--                         WINGS                           --
--========================================================--

local function DestroyWings()
    SafeDestroy(VFXObjects.Wings)
    VFXObjects.Wings = nil
    VFXObjects.WingsData = nil
end

local function NewWingFeather(folder, side, index)
    local feather = NewPart(
        (side < 0 and "Left_" or "Right_")
            .. "Feather_" .. index,
        folder,
        Vector3.new(
            0.22,
            1.0 - index * 0.045,
            0.48
        ),
        VFXState.WingColor,
        Enum.Material.Neon
    )

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Wedge
    mesh.Scale = Vector3.new(
        0.72 + index * 0.05,
        1,
        1
    )
    mesh.Parent = feather

    return feather
end

local function CreateWings()
    DestroyWings()

    if not VFXState.Wings then
        return
    end

    local root = GetRoot()
    local folder = EnsureVFXRoot()

    if not root or not folder then
        return
    end

    local wings = NewFolder("Wings", folder)
    local left = {}
    local right = {}

    for i = 1, 8 do
        left[i] = NewWingFeather(wings, -1, i)
        right[i] = NewWingFeather(wings, 1, i)
    end

    local core = NewBall(
        "WingCore",
        wings,
        0.42,
        VFXState.WingColor
    )

    VFXObjects.Wings = wings
    VFXObjects.WingsData = {
        Left = left,
        Right = right,
        Core = core,
    }
end

local function UpdateWings()
    if not VFXState.Wings then
        return
    end

    local root = GetRoot()
    local data = VFXObjects.WingsData

    if not root or not data then
        return
    end

    local now = os.clock()
    local color = VFXColor(VFXState.WingColor)

    local function updateSide(list, side)
        for index, feather in ipairs(list) do
            if feather and feather.Parent then
                local flap =
                    math.sin(now * 3 + index * 0.22)
                    * (0.05 + index * 0.008)

                local spread =
                    0.55 + index * 0.45

                local height =
                    2.75 - index * 0.2

                feather.CFrame =
                    root.CFrame
                    * CFrame.new(
                        side * spread,
                        height,
                        0.45 + index * 0.12
                    )
                    * CFrame.Angles(
                        -0.18 + index * 0.035,
                        side * (
                            0.28
                            + index * 0.105
                            + flap
                        ),
                        side * 0.22
                    )

                feather.Color = color
            end
        end
    end

    updateSide(data.Left, -1)
    updateSide(data.Right, 1)

    if data.Core and data.Core.Parent then
        data.Core.CFrame =
            root.CFrame
            * CFrame.new(0, 2.25, 0.55)

        data.Core.Color = color
    end
end

--========================================================--
--                    BODY PARTICLES                      --
--========================================================--

local function DestroyBodyParticles()
    SafeDestroy(VFXObjects.BodyParticles)
    VFXObjects.BodyParticles = nil
    VFXObjects.BodyEmitter = nil
end

local function CreateBodyParticles()
    DestroyBodyParticles()

    if not VFXState.BodyParticles then
        return
    end

    local root = GetRoot()
    local folder = EnsureVFXRoot()

    if not root or not folder then
        return
    end

    local container = NewFolder(
        "BodyParticles",
        folder
    )

    local attachment = Instance.new("Attachment")
    attachment.Name = "ParticleAttachment"
    attachment.Position = Vector3.new(0, 0.5, 0)
    attachment.Parent = container

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "NebulaParticles"
    emitter.Color =
        ColorSequence.new(VFXState.ParticleColor)
    emitter.LightEmission = 1
    emitter.LightInfluence = 0
    emitter.Rate = 32
    emitter.Lifetime = NumberRange.new(0.7, 1.35)
    emitter.Speed = NumberRange.new(0.15, 1.5)
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-80, 80)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Acceleration = Vector3.new(0, 1.8, 0)
    emitter.Drag = 0.35
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.04),
        NumberSequenceKeypoint.new(0.25, 0.18),
        NumberSequenceKeypoint.new(0.75, 0.1),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.7, 0.35),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment

    VFXObjects.BodyParticles = container
    VFXObjects.BodyEmitter = emitter
end

--========================================================--
--                        TRAIL                           --
--========================================================--

local function DestroyTrail()
    SafeDestroy(VFXObjects.Trail)
    VFXObjects.Trail = nil
    VFXObjects.TrailObject = nil
end

local function CreateTrail()
    DestroyTrail()

    if not VFXState.Trail then
        return
    end

    local root = GetRoot()
    local folder = EnsureVFXRoot()

    if not root or not folder then
        return
    end

    local container = NewFolder("Trail", folder)

    local a0 = Instance.new("Attachment")
    a0.Name = "TrailA0"
    a0.Position = Vector3.new(-0.7, -1.8, 0)
    a0.Parent = container

    local a1 = Instance.new("Attachment")
    a1.Name = "TrailA1"
    a1.Position = Vector3.new(0.7, -1.8, 0)
    a1.Parent = container

    local trail = Instance.new("Trail")
    trail.Name = "NebulaTrail"
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Lifetime = 0.55
    trail.MinLength = 0.05
    trail.FaceCamera = true
    trail.LightEmission = 1
    trail.Color =
        ColorSequence.new(VFXState.TrailColor)
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.65, 0.35),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.Parent = container

    VFXObjects.Trail = container
    VFXObjects.TrailObject = trail
end

--========================================================--
--                       FOOTSTEPS                        --
--========================================================--

local function SpawnFootstep(position, color)
    local root = EnsureVFXRoot()
    if not root then
        return
    end

    local step = NewPart(
        "Footstep",
        root,
        Vector3.new(0.12, 0.035, 1.1),
        color,
        Enum.Material.Neon
    )

    step.Transparency = 0.1
    step.CFrame =
        CFrame.new(
            position + Vector3.new(0, 0.035, 0)
        )
        * CFrame.Angles(
            0,
            math.rad(math.random(-18, 18)),
            0
        )

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Scale = Vector3.new(1.1, 0.05, 2)
    mesh.Parent = step

    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = 3.5
    light.Brightness = 0.7
    light.Parent = step

    local tween = TweenService:Create(
        step,
        TweenInfo.new(
            0.75,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {
            Transparency = 1,
            Size = Vector3.new(
                0.8,
                0.01,
                1.7
            ),
        }
    )

    tween:Play()
    Debris:AddItem(step, 0.9)
end

local function UpdateFootsteps()
    if not VFXState.Footsteps then
        return
    end

    local root = GetRoot()
    local humanoid = GetHumanoid()

    if not root or not humanoid then
        return
    end

    if humanoid.MoveDirection.Magnitude < 0.08 then
        LastFootPosition = root.Position
        return
    end

    local now = os.clock()

    if now - LastFootstep < 0.18 then
        return
    end

    local position = root.Position

    if LastFootPosition and
        (position - LastFootPosition).Magnitude < 0.35 then
        return
    end

    local params = RaycastParams.new()
    params.FilterType =
        Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        GetCharacter(),
    }

    local result = workspace:Raycast(
        position + Vector3.new(0, 0.5, 0),
        Vector3.new(0, -6, 0),
        params
    )

    if result then
        SpawnFootstep(
            result.Position,
            VFXColor(VFXState.ParticleColor)
        )

        LastFootstep = now
        LastFootPosition = position
    end
end

--========================================================--
--                    SKY PARTICLES                       --
--========================================================--

local function DestroySkyParticles()
    for i = #SkyParticleData, 1, -1 do
        SafeDestroy(SkyParticleData[i].Part)
        SkyParticleData[i] = nil
    end
end

local function CreateSkyParticles()
    DestroySkyParticles()

    if not VFXState.SkyParticles then
        return
    end

    local folder = EnsureEnvironmentRoot()

    for i = 1, VFXState.SkyParticleCount do
        local part = NewBall(
            "SkyParticle_" .. i,
            folder,
            math.random(8, 16) / 100,
            VFXState.ParticleColor
        )

        SkyParticleData[i] = {
            Part = part,
            Phase = math.random() * math.pi * 2,
            Radius = math.random(25, 70),
            Height = math.random(12, 38),
            Speed = math.random(4, 10) / 10,
            Drift = math.random(3, 12) / 10,
        }
    end
end

local function UpdateSkyParticles()
    if not VFXState.SkyParticles then
        return
    end

    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local now = os.clock()

    for index, data in ipairs(SkyParticleData) do
        if data.Part and data.Part.Parent then
            local angle =
                data.Phase
                + now * data.Speed * 0.12

            local vertical =
                math.sin(
                    now * data.Drift * 0.16
                    + data.Phase
                ) * 5

            data.Part.Position =
                camera.CFrame.Position
                + Vector3.new(
                    math.cos(angle) * data.Radius,
                    data.Height + vertical,
                    math.sin(angle) * data.Radius
                )

            data.Part.Color =
                VFXColor(
                    VFXState.ParticleColor,
                    index / math.max(
                        1,
                        #SkyParticleData
                    )
                )
        end
    end
end

--========================================================--
--                    ENVIRONMENT                         --
--========================================================--

local function SaveEnvironment()
    if EnvironmentBackup.ClockTime ~= nil then
        return
    end

    EnvironmentBackup.ClockTime =
        Lighting.ClockTime

    EnvironmentBackup.Brightness =
        Lighting.Brightness

    EnvironmentBackup.Ambient =
        Lighting.Ambient

    EnvironmentBackup.OutdoorAmbient =
        Lighting.OutdoorAmbient

    EnvironmentBackup.ColorShiftTop =
        Lighting.ColorShift_Top

    EnvironmentBackup.ColorShiftBottom =
        Lighting.ColorShift_Bottom

    EnvironmentBackup.FogColor =
        Lighting.FogColor

    EnvironmentBackup.FogStart =
        Lighting.FogStart

    EnvironmentBackup.FogEnd =
        Lighting.FogEnd

    EnvironmentBackup.ExposureCompensation =
        Lighting.ExposureCompensation
end

local function ApplyEnvironment()
    SaveEnvironment()

    local atmosphere =
        Lighting:FindFirstChildOfClass(
            "Atmosphere"
        )

    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "NebulaAtmosphere"
        atmosphere.Parent = Lighting
    end

    atmosphere.Color =
        Color3.fromRGB(110, 80, 170)

    atmosphere.Decay =
        Color3.fromRGB(65, 35, 95)

    atmosphere.Density = 0.32
    atmosphere.Glare = 0.08
    atmosphere.Haze = 1.25
    atmosphere.Offset = 0.1

    Lighting.Ambient =
        Color3.fromRGB(46, 31, 67)

    Lighting.OutdoorAmbient =
        Color3.fromRGB(70, 45, 95)

    Lighting.ColorShift_Top =
        Color3.fromRGB(105, 65, 155)

    Lighting.ColorShift_Bottom =
        Color3.fromRGB(35, 20, 55)

    Lighting.Brightness = 2.1
    Lighting.ExposureCompensation = 0.1

    Lighting.FogColor =
        Color3.fromRGB(75, 48, 105)

    Lighting.FogStart = 35
    Lighting.FogEnd = 420
end

local function RestoreEnvironment()
    if EnvironmentBackup.ClockTime == nil then
        return
    end

    pcall(function()
        Lighting.ClockTime =
            EnvironmentBackup.ClockTime

        Lighting.Brightness =
            EnvironmentBackup.Brightness

        Lighting.Ambient =
            EnvironmentBackup.Ambient

        Lighting.OutdoorAmbient =
            EnvironmentBackup.OutdoorAmbient

        Lighting.ColorShift_Top =
            EnvironmentBackup.ColorShiftTop

        Lighting.ColorShift_Bottom =
            EnvironmentBackup.ColorShiftBottom

        Lighting.FogColor =
            EnvironmentBackup.FogColor

        Lighting.FogStart =
            EnvironmentBackup.FogStart

        Lighting.FogEnd =
            EnvironmentBackup.FogEnd

        Lighting.ExposureCompensation =
            EnvironmentBackup.ExposureCompensation
    end)

    local atmosphere =
        Lighting:FindFirstChild(
            "NebulaAtmosphere"
        )

    if atmosphere then
        SafeDestroy(atmosphere)
    end

    EnvironmentBackup.ClockTime = nil
end

--========================================================--
--                   VFX REBUILD                           --
--========================================================--

local function RebuildCharacterVFX()
    if not GetCharacter() then
        return
    end

    EnsureVFXRoot()

    CreateAura()
    CreateOrbit()
    CreateWings()
    CreateBodyParticles()
    CreateTrail()
end

local function ClearCharacterVFX()
    DestroyAura()
    DestroyOrbit()
    DestroyWings()
    DestroyBodyParticles()
    DestroyTrail()

    SafeDestroy(VFXRoot)
    VFXRoot = nil
end

local function SetAura(value)
    VFXState.Aura = value == true
    CreateAura()
end

local function SetOrbit(value)
    VFXState.Orbit = value == true
    CreateOrbit()
end

local function SetWings(value)
    VFXState.Wings = value == true
    CreateWings()
end

local function SetBodyParticles(value)
    VFXState.BodyParticles = value == true
    CreateBodyParticles()
end

local function SetTrail(value)
    VFXState.Trail = value == true
    CreateTrail()
end

local function SetFootsteps(value)
    VFXState.Footsteps = value == true
    LastFootPosition = nil
    LastFootstep = 0
end

local function SetSkyParticles(value)
    VFXState.SkyParticles = value == true

    if VFXState.SkyParticles then
        CreateSkyParticles()
    else
        DestroySkyParticles()
    end
end

local function SetEnvironment(value)
    VFXState.Environment = value == true

    if VFXState.Environment then
        ApplyEnvironment()
    else
        RestoreEnvironment()
    end
end

local function SetRainbow(value)
    VFXState.Rainbow = value == true
end

--========================================================--
--                      EFFECT UI                          --
--========================================================--

local EffectsSection = MiscTab:AddSection(
    "Nebula Visual Effects"
)

EffectsSection:AddToggle({
    Name = "Aura",
    Default = false,
    Callback = SetAura,
})

EffectsSection:AddSlider({
    Name = "Aura Radius",
    Min = 2,
    Max = 7,
    Default = 3.4,
    Callback = function(value)
        VFXState.AuraRadius = value
        if VFXState.Aura then
            CreateAura()
        end
    end,
})

EffectsSection:AddToggle({
    Name = "Orbit",
    Default = false,
    Callback = SetOrbit,
})

EffectsSection:AddSlider({
    Name = "Orbit Radius",
    Min = 2,
    Max = 7,
    Default = 3.2,
    Callback = function(value)
        VFXState.OrbitRadius = value
    end,
})

EffectsSection:AddToggle({
    Name = "Footstep FX",
    Default = false,
    Callback = SetFootsteps,
})

EffectsSection:AddToggle({
    Name = "Wings",
    Default = false,
    Callback = SetWings,
})

EffectsSection:AddToggle({
    Name = "Body Particles",
    Default = false,
    Callback = SetBodyParticles,
})

EffectsSection:AddToggle({
    Name = "Character Trail",
    Default = false,
    Callback = SetTrail,
})

EffectsSection:AddToggle({
    Name = "Rainbow VFX",
    Default = false,
    Callback = SetRainbow,
})

EffectsSection:AddToggle({
    Name = "Sky Particles",
    Default = false,
    Callback = SetSkyParticles,
})

EffectsSection:AddSlider({
    Name = "Sky Particle Count",
    Min = 8,
    Max = 45,
    Default = 22,
    Callback = function(value)
        VFXState.SkyParticleCount = value

        if VFXState.SkyParticles then
            CreateSkyParticles()
        end
    end,
})

--========================================================--
--                    ENVIRONMENT UI                       --
--========================================================--

local EnvironmentSection = MiscTab:AddSection(
    "Environment"
)

EnvironmentSection:AddToggle({
    Name = "Nebula Environment",
    Default = false,
    Callback = SetEnvironment,
})

EnvironmentSection:AddButton({
    Name = "Purple Night",
    Callback = function()
        SaveEnvironment()

        local atmosphere =
            Lighting:FindFirstChildOfClass(
                "Atmosphere"
            )

        if not atmosphere then
            atmosphere = Instance.new("Atmosphere")
            atmosphere.Name = "NebulaAtmosphere"
            atmosphere.Parent = Lighting
        end

        atmosphere.Color =
            Color3.fromRGB(95, 60, 150)

        atmosphere.Decay =
            Color3.fromRGB(45, 20, 75)

        atmosphere.Density = 0.38
        atmosphere.Haze = 1.5
        atmosphere.Glare = 0.12

        Lighting.ClockTime = 0.15
        Lighting.Brightness = 1.6

        Lighting.Ambient =
            Color3.fromRGB(38, 24, 60)

        Lighting.OutdoorAmbient =
            Color3.fromRGB(52, 34, 76)

        Lighting.FogColor =
            Color3.fromRGB(55, 30, 82)

        Lighting.FogStart = 20
        Lighting.FogEnd = 300
    end,
})

EnvironmentSection:AddButton({
    Name = "Restore Lighting",
    Callback = RestoreEnvironment,
})

--========================================================--
--                    COLOR PRESETS                        --
--========================================================--

local function SetVFXPalette(
    aura,
    wings,
    particles,
    trail
)
    VFXState.AuraColor = aura
    VFXState.WingColor = wings
    VFXState.ParticleColor = particles
    VFXState.TrailColor = trail

    if VFXState.Aura then
        CreateAura()
    end

    if VFXState.Wings then
        CreateWings()
    end

    if VFXState.BodyParticles then
        CreateBodyParticles()
    end

    if VFXState.Trail then
        CreateTrail()
    end
end

EffectsSection:AddButton({
    Name = "Violet Preset",
    Callback = function()
        SetVFXPalette(
            Color3.fromRGB(170, 70, 255),
            Color3.fromRGB(130, 65, 255),
            Color3.fromRGB(215, 150, 255),
            Color3.fromRGB(155, 80, 255)
        )
    end,
})

EffectsSection:AddButton({
    Name = "Ice Preset",
    Callback = function()
        SetVFXPalette(
            Color3.fromRGB(70, 210, 255),
            Color3.fromRGB(95, 180, 255),
            Color3.fromRGB(180, 245, 255),
            Color3.fromRGB(70, 190, 255)
        )
    end,
})

EffectsSection:AddButton({
    Name = "Crimson Preset",
    Callback = function()
        SetVFXPalette(
            Color3.fromRGB(255, 55, 95),
            Color3.fromRGB(255, 65, 70),
            Color3.fromRGB(255, 130, 150),
            Color3.fromRGB(255, 45, 75)
        )
    end,
})

--========================================================--
--                     VFX LOOPS                          --
--========================================================--

table.insert(
    VFXConnections,
    RunService.RenderStepped:Connect(function()
        UpdateAura()
        UpdateOrbit()
        UpdateWings()
        UpdateSkyParticles()
    end)
)

table.insert(
    VFXConnections,
    RunService.Heartbeat:Connect(function()
        UpdateFootsteps()

        if VFXObjects.BodyEmitter then
            VFXObjects.BodyEmitter.Color =
                ColorSequence.new(
                    VFXColor(
                        VFXState.ParticleColor
                    )
                )
        end

        if VFXObjects.TrailObject then
            VFXObjects.TrailObject.Color =
                ColorSequence.new(
                    VFXColor(
                        VFXState.TrailColor
                    )
                )
        end
    end)
)

table.insert(
    VFXConnections,
    LocalPlayer.CharacterAdded:Connect(function()
        ClearCharacterVFX()

        task.wait(0.7)

        if LocalPlayer.Character then
            RebuildCharacterVFX()
        end
    end)
)

--========================================================--
--                 VFX STABILITY LOOP                     --
--========================================================--

table.insert(
    VFXConnections,
    RunService.Heartbeat:Connect(function()
        if not GetCharacter() then
            return
        end

        if VFXState.Aura and
            not VFXObjects.Aura then
            CreateAura()
        end

        if VFXState.Orbit and
            not VFXObjects.Orbit then
            CreateOrbit()
        end

        if VFXState.Wings and
            not VFXObjects.Wings then
            CreateWings()
        end

        if VFXState.BodyParticles and
            not VFXObjects.BodyParticles then
            CreateBodyParticles()
        end

        if VFXState.Trail and
            not VFXObjects.Trail then
            CreateTrail()
        end
    end)
)

local function CleanupNebulaVFX()
    DisconnectAll(VFXConnections)
    ClearCharacterVFX()
    DestroySkyParticles()

    if VFXState.Environment then
        RestoreEnvironment()
    end

    SafeDestroy(EnvironmentRoot)
    EnvironmentRoot = nil
end

task.defer(function()
    task.wait(1)

    if VFXState.SkyParticles then
        CreateSkyParticles()
    end

    if VFXState.Environment then
        ApplyEnvironment()
    end
end)

--========================================================--
-- COMBAT NOTE
--========================================================--
-- Визуальная часть намеренно отделена от боевой логики.
-- Я не добавляю packet forging, обход серверной валидации
-- или античита/гарантированные попадания.
--========================================================--

--========================================================--
--                       NOTIFY                           --
--========================================================--

Window:Notify({
    Title = "Nebula Hub",
    Content = "MM2 Script Loaded Successfully!",
    Duration = 5
})
