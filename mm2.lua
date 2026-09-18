--========================================================--
--              NEBULA HUB | MURDER MYSTERY 2             --
--                    v5.6 Mobile/FX                      --
--========================================================--

local Nebula = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/HorusWawe/scripts/refs/heads/main/nebula-ui.lua"
))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Window = Nebula:CreateWindow({
    Name = "Nebula Hub | Murder Mystery 2",
    Subtitle = "v5.6",
    Size = UDim2.fromOffset(580, 460),
    Theme = "Nebula"
})

--========================================================--
--                         STATE                          --
--========================================================--

local State = {
    SheriffAim = false,
    SilentAim = false,
    Wallbang = false,
    SheriffFOV = 180,
    AimPrediction = 0.12,

    KnifeAim = false,
    KnifeFOV = 120,
    KillAura = false,
    AuraDistance = 12,
    AuraTargetESP = true,
    KnifeThrowAura = false,
    ThrowDistance = 30,

    ESP = false,
    ESPNames = true,
    ESPDistance = true,
    ESPTracers = false,
    DropGunESP = false,
    ESPBoxes = false,
    ESPArrows = false,
    ESPRoleMarkers = false,
    ESPRainbow = false,
    ESPHealthBars = false,
    ESPSkeleton = false,
    ESPPulse = false,
    Crosshair = false,
    RoleHUD = false,
    ThreatRadar = false,
    RadarRange = 90,

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
    AutoFarm = false,

    Wings = false,
    AuraFX = false,
    Particles = false,
    Trail = false,
    Footsteps = false,
    OrbitParticles = false,
    Rainbow = false,
    Invisibility = false,

    JerkOff = false,
    FakeDeath = false,

    MobileShoot = true,
    MobileAura = true,
    MobileFly = true,
    MobileESP = true,
    MobileVFX = true,
    MobileEdit = false,
}

--========================================================--
--                      CLEANUP CORE                      --
--========================================================--

local Connections = {}
local Instances = {}
local Effects = {}
local MobileButtons = {}
local ESPObjects = {}

local function TrackConnection(connection)
    if connection then
        table.insert(Connections, connection)
    end
    return connection
end

local function TrackInstance(instance)
    if instance then
        table.insert(Instances, instance)
    end
    return instance
end

local function SafeDestroy(object)
    if object then
        pcall(function()
            object:Destroy()
        end)
    end
end

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local character = GetCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function GetRoot()
    local character = GetCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function GetHead(character)
    return character and character:FindFirstChild("Head")
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
            local knife = character:FindFirstChild("Knife")
                or (backpack and backpack:FindFirstChild("Knife"))

            local gun = character:FindFirstChild("Gun")
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

local function IsAlive(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function GetMurderer()
    return GetRoles().Murderer
end

local function GetSheriff()
    return GetRoles().Sheriff
end

--========================================================--
--                     TARGET HELPERS                     --
--========================================================--

local function GetTargetRoot(player)
    if not player or not player.Character then
        return nil
    end
    return player.Character:FindFirstChild("HumanoidRootPart")
end

local function GetTargetPart(player)
    if not player or not player.Character then
        return nil
    end
    return player.Character:FindFirstChild("Head")
        or player.Character:FindFirstChild("UpperTorso")
        or player.Character:FindFirstChild("Torso")
        or player.Character:FindFirstChild("HumanoidRootPart")
end

local function PredictPosition(player, amount)
    local part = GetTargetPart(player)
    if not part then
        return nil
    end

    local velocity = part.AssemblyLinearVelocity
    return part.Position + velocity * (amount or 0)
end

local function IsInFOV(player, fov)
    local part = GetTargetPart(player)
    if not part then
        return false
    end

    local viewport, visible = Camera:WorldToViewportPoint(part.Position)
    if not visible then
        return false
    end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local distance = (Vector2.new(viewport.X, viewport.Y) - center).Magnitude
    return distance <= (fov or 180)
end

--========================================================--
--                         TABS                           --
--========================================================--

local CombatTab = Window:AddTab("Combat", "rbxassetid://6034509993")
local VisualsTab = Window:AddTab("Visuals", "rbxassetid://6034509993")
local MovementTab = Window:AddTab("Movement", "rbxassetid://6034509993")
local EffectsTab = Window:AddTab("Effects", "rbxassetid://6034509993")
local PlayersTab = Window:AddTab("Players", "rbxassetid://6034509993")
local MiscTab = Window:AddTab("Misc", "rbxassetid://6034509993")

--========================================================--
--                         COMBAT                         --
--========================================================--

local SheriffSection = CombatTab:AddSection("Sheriff")

SheriffSection:AddToggle({
    Name = "Sheriff Aim (Lock)",
    Default = false,
    Callback = function(v)
        State.SheriffAim = v
    end
})

SheriffSection:AddToggle({
    Name = "Sheriff Silent Aim",
    Default = false,
    Callback = function(v)
        State.SilentAim = v
    end
})

SheriffSection:AddToggle({
    Name = "Wall Check Ignore",
    Default = false,
    Callback = function(v)
        State.Wallbang = v
    end
})

SheriffSection:AddSlider({
    Name = "Aim FOV",
    Min = 20,
    Max = 360,
    Default = 180,
    Callback = function(v)
        State.SheriffFOV = v
    end
})

SheriffSection:AddSlider({
    Name = "Prediction",
    Min = 0,
    Max = 0.5,
    Default = 0.12,
    Decimals = 2,
    Callback = function(v)
        State.AimPrediction = v
    end
})

local KnifeSection = CombatTab:AddSection("Murderer")

KnifeSection:AddToggle({
    Name = "Knife Throw Aim",
    Default = false,
    Callback = function(v)
        State.KnifeAim = v
    end
})

KnifeSection:AddSlider({
    Name = "Knife FOV",
    Min = 30,
    Max = 360,
    Default = 120,
    Callback = function(v)
        State.KnifeFOV = v
    end
})

KnifeSection:AddToggle({
    Name = "Kill Aura",
    Default = false,
    Callback = function(v)
        State.KillAura = v
    end
})

KnifeSection:AddSlider({
    Name = "Aura Distance",
    Min = 5,
    Max = 100,
    Default = 12,
    Callback = function(v)
        State.AuraDistance = v
    end
})

KnifeSection:AddToggle({
    Name = "Aura Target Highlight",
    Default = true,
    Callback = function(v)
        State.AuraTargetESP = v
    end
})

KnifeSection:AddToggle({
    Name = "Knife Throw Aura",
    Default = false,
    Callback = function(v)
        State.KnifeThrowAura = v
    end
})

KnifeSection:AddSlider({
    Name = "Throw Distance",
    Min = 10,
    Max = 150,
    Default = 30,
    Callback = function(v)
        State.ThrowDistance = v
    end
})

local RageSection = CombatTab:AddSection("Target / Rage")

RageSection:AddLabel("Targeting and prediction are client-side helpers.")
RageSection:AddLabel("Server-side hit validation cannot be bypassed universally.")

--========================================================--
--                   SHERIFF AIM / TARGET FX              --
--========================================================--

local AimTargetHighlight = Instance.new("Highlight")
AimTargetHighlight.Name = "Nebula_AimTarget"
AimTargetHighlight.FillTransparency = 0.7
AimTargetHighlight.OutlineTransparency = 0
AimTargetHighlight.FillColor = Color3.fromRGB(255, 70, 70)
AimTargetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
AimTargetHighlight.Enabled = false
TrackInstance(AimTargetHighlight)

local function UpdateAim()
    local murderer = GetMurderer()
    local localCharacter = GetCharacter()
    local gun = localCharacter and localCharacter:FindFirstChild("Gun")

    if not murderer or not gun or not IsAlive(murderer) then
        AimTargetHighlight.Enabled = false
        return
    end

    local targetPart = GetTargetPart(murderer)
    if not targetPart then
        AimTargetHighlight.Enabled = false
        return
    end

    local predicted = PredictPosition(murderer, State.AimPrediction)

    if State.SheriffAim and IsInFOV(murderer, State.SheriffFOV) then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted or targetPart.Position)
    end

    AimTargetHighlight.Adornee = murderer.Character
    AimTargetHighlight.Enabled = State.SilentAim or State.KnifeAim
end

TrackConnection(RunService.RenderStepped:Connect(UpdateAim))

--========================================================--
--                         VISUALS                        --
--========================================================--

local PlayerSection = VisualsTab:AddSection("Player ESP")

PlayerSection:AddToggle({
    Name = "Player ESP",
    Default = false,
    Callback = function(v)
        State.ESP = v
    end
})

PlayerSection:AddToggle({
    Name = "Names",
    Default = true,
    Callback = function(v)
        State.ESPNames = v
    end
})

PlayerSection:AddToggle({
    Name = "Distance",
    Default = true,
    Callback = function(v)
        State.ESPDistance = v
    end
})

PlayerSection:AddToggle({
    Name = "Tracers",
    Default = false,
    Callback = function(v)
        State.ESPTracers = v
    end
})

PlayerSection:AddToggle({
    Name = "3D Boxes",
    Default = false,
    Callback = function(v)
        State.ESPBoxes = v
    end
})

PlayerSection:AddToggle({
    Name = "Offscreen Arrows",
    Default = false,
    Callback = function(v)
        State.ESPArrows = v
    end
})

PlayerSection:AddToggle({
    Name = "Role Markers",
    Default = false,
    Callback = function(v)
        State.ESPRoleMarkers = v
    end
})

PlayerSection:AddToggle({
    Name = "Rainbow ESP",
    Default = false,
    Callback = function(v)
        State.ESPRainbow = v
    end
})

PlayerSection:AddToggle({
    Name = "Health Bars",
    Default = false,
    Callback = function(v) State.ESPHealthBars = v end
})

PlayerSection:AddToggle({
    Name = "Skeleton ESP",
    Default = false,
    Callback = function(v) State.ESPSkeleton = v end
})

PlayerSection:AddToggle({
    Name = "Pulse Highlights",
    Default = false,
    Callback = function(v) State.ESPPulse = v end
})

local DropGunSection = VisualsTab:AddSection("Drop Gun")

DropGunSection:AddToggle({
    Name = "Drop Gun ESP",
    Default = false,
    Callback = function(v)
        State.DropGunESP = v
    end
})

local function RemoveESP(player)
    local data = ESPObjects[player]
    if not data then
        return
    end

    SafeDestroy(data.Highlight)
    SafeDestroy(data.NameTag)
    SafeDestroy(data.Tracer)
    SafeDestroy(data.Box)
    SafeDestroy(data.RoleTag)
    SafeDestroy(data.HealthTag)
    if data.Skeleton then
        for _, beam in pairs(data.Skeleton.Beams or {}) do SafeDestroy(beam) end
        for _, attachment in pairs(data.Skeleton.Attachments or {}) do SafeDestroy(attachment) end
    end
    SafeDestroy(data.LocalTracerAttachment)
    SafeDestroy(data.TargetTracerAttachment)
    ESPObjects[player] = nil
end

local function CreateESP(player)
    if player == LocalPlayer or ESPObjects[player] then
        return
    end

    -- Keep the original ESP architecture: one data table per player.
    -- Objects are parented only when a character/head exists, so respawns
    -- do not leave orphaned GUI/Highlight instances behind.
    local highlight = Instance.new("Highlight")
    highlight.Name = "Nebula_ESP"
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false

    local nameTag = Instance.new("BillboardGui")
    nameTag.Name = "Nebula_Name"
    nameTag.Size = UDim2.fromOffset(230, 45)
    nameTag.StudsOffset = Vector3.new(0, 3, 0)
    nameTag.AlwaysOnTop = true
    nameTag.ResetOnSpawn = false
    nameTag.Enabled = false

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.25
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Parent = nameTag

    local tracer = Instance.new("Beam")
    tracer.Name = "Nebula_Tracer"
    tracer.Enabled = false
    tracer.FaceCamera = true
    tracer.Width0 = 0.045
    tracer.Width1 = 0.02
    tracer.LightEmission = 1
    tracer.Transparency = NumberSequence.new(0.05)

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "Nebula_ESPBox"
    box.AlwaysOnTop = true
    box.Transparency = 0.78
    box.ZIndex = 5
    box.Visible = false
    box.Size = Vector3.new(4, 6, 2)

    local roleTag = Instance.new("BillboardGui")
    roleTag.Name = "Nebula_RoleMarker"
    roleTag.Size = UDim2.fromOffset(34, 34)
    roleTag.StudsOffset = Vector3.new(0, 4.4, 0)
    roleTag.AlwaysOnTop = true
    roleTag.Enabled = false

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Size = UDim2.fromScale(1, 1)
    roleLabel.BackgroundTransparency = 1
    roleLabel.TextScaled = true
    roleLabel.Font = Enum.Font.GothamBlack
    roleLabel.TextStrokeTransparency = 0.1
    roleLabel.Text = ""
    roleLabel.Parent = roleTag

    ESPObjects[player] = {
        Highlight = highlight,
        NameTag = nameTag,
        Label = label,
        Tracer = tracer,
        Box = box,
        RoleTag = roleTag,
        RoleLabel = roleLabel,
        HealthTag = nil,
        HealthFill = nil,
        Skeleton = nil,
        LocalTracerAttachment = nil,
        TargetTracerAttachment = nil,
    }
end

for _, player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end

TrackConnection(Players.PlayerAdded:Connect(CreateESP))
TrackConnection(Players.PlayerRemoving:Connect(RemoveESP))

local function EnsureTracerAttachments(data, targetRoot)
    local localRoot = GetRoot()
    if not localRoot or not targetRoot then
        SafeDestroy(data.LocalTracerAttachment)
        SafeDestroy(data.TargetTracerAttachment)
        data.LocalTracerAttachment = nil
        data.TargetTracerAttachment = nil
        return false
    end

    if not data.LocalTracerAttachment
        or data.LocalTracerAttachment.Parent ~= localRoot then
        SafeDestroy(data.LocalTracerAttachment)
        data.LocalTracerAttachment = Instance.new("Attachment")
        data.LocalTracerAttachment.Name = "Nebula_TracerOrigin"
        data.LocalTracerAttachment.Position = Vector3.new(0, 0.15, 0)
        data.LocalTracerAttachment.Parent = localRoot
    end

    if not data.TargetTracerAttachment
        or data.TargetTracerAttachment.Parent ~= targetRoot then
        SafeDestroy(data.TargetTracerAttachment)
        data.TargetTracerAttachment = Instance.new("Attachment")
        data.TargetTracerAttachment.Name = "Nebula_TracerTarget"
        data.TargetTracerAttachment.Position = Vector3.new(0, 0.5, 0)
        data.TargetTracerAttachment.Parent = targetRoot
    end

    data.Tracer.Attachment0 = data.LocalTracerAttachment
    data.Tracer.Attachment1 = data.TargetTracerAttachment
    data.Tracer.Parent = localRoot

    return true
end

local function GetSkeletonPart(character, names)
    if not character then return nil end
    for _, name in ipairs(names) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part end
    end
    return nil
end

local SkeletonPairs = {
    Head = {"Head", "UpperTorso", "Torso"},
    Torso = {"UpperTorso", "Torso", "LowerTorso"},
    LeftArm = {"LeftUpperArm", "Left Arm", "LeftLowerArm", "LeftHand"},
    RightArm = {"RightUpperArm", "Right Arm", "RightLowerArm", "RightHand"},
    LeftLeg = {"LeftUpperLeg", "Left Leg", "LeftLowerLeg", "LeftFoot"},
    RightLeg = {"RightUpperLeg", "Right Leg", "RightLowerLeg", "RightFoot"},
}

local function EnsureSkeleton(data, character, color)
    if not character then return end
    if not data.Skeleton then data.Skeleton = {Attachments = {}, Beams = {}, Seen = {}} end
    local skeleton = data.Skeleton
    table.clear(skeleton.Seen)
    local pairsToBuild = {{"Head", "Torso"}, {"Torso", "LeftArm"}, {"Torso", "RightArm"}, {"Torso", "LeftLeg"}, {"Torso", "RightLeg"}}
    for _, pair in ipairs(pairsToBuild) do
        local aPart = GetSkeletonPart(character, SkeletonPairs[pair[1]])
        local bPart = GetSkeletonPart(character, SkeletonPairs[pair[2]])
        if aPart and bPart then
            local key = pair[1] .. "_" .. pair[2]
            local aKey, bKey = key .. "_A", key .. "_B"
            local a, b = skeleton.Attachments[aKey], skeleton.Attachments[bKey]
            if not a or a.Parent ~= aPart then
                SafeDestroy(a)
                a = Instance.new("Attachment")
                a.Name = "NebulaSkel_" .. aKey
                a.Parent = aPart
                skeleton.Attachments[aKey] = a
            end
            if not b or b.Parent ~= bPart then
                SafeDestroy(b)
                b = Instance.new("Attachment")
                b.Name = "NebulaSkel_" .. bKey
                b.Parent = bPart
                skeleton.Attachments[bKey] = b
            end
            local beam = skeleton.Beams[key]
            if not beam or not beam.Parent then
                beam = Instance.new("Beam")
                beam.Name = "Nebula_Skeleton"
                beam.Attachment0 = a
                beam.Attachment1 = b
                beam.FaceCamera = true
                beam.LightEmission = 1
                beam.Width0 = 0.035
                beam.Width1 = 0.035
                beam.Transparency = NumberSequence.new(0.15)
                beam.Parent = aPart
                skeleton.Beams[key] = beam
            end
            beam.Color = ColorSequence.new(color)
            beam.Enabled = true
            skeleton.Seen[key] = true
        end
    end
    for key, beam in pairs(skeleton.Beams) do
        beam.Enabled = skeleton.Seen[key] == true
    end
end

local function DestroySkeleton(data)
    if not data or not data.Skeleton then return end
    for _, beam in pairs(data.Skeleton.Beams or {}) do SafeDestroy(beam) end
    for _, attachment in pairs(data.Skeleton.Attachments or {}) do SafeDestroy(attachment) end
    data.Skeleton = nil
end

local function EnsureHealthBar(data, head)
    if not head then return nil, nil end
    if not data.HealthTag or not data.HealthTag.Parent then
        local gui = Instance.new("BillboardGui")
        gui.Name = "Nebula_HealthBar"
        gui.Size = UDim2.fromOffset(92, 10)
        gui.StudsOffset = Vector3.new(0, 2.35, 0)
        gui.AlwaysOnTop = true
        gui.Enabled = false
        gui.Parent = head
        local back = Instance.new("Frame")
        back.Size = UDim2.fromScale(1, 1)
        back.BackgroundColor3 = Color3.fromRGB(18, 11, 28)
        back.BackgroundTransparency = 0.12
        back.BorderSizePixel = 0
        back.Parent = gui
        local backCorner = Instance.new("UICorner")
        backCorner.CornerRadius = UDim.new(1, 0)
        backCorner.Parent = back
        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.fromScale(1, 1)
        fill.BackgroundColor3 = Color3.fromRGB(95, 235, 145)
        fill.BorderSizePixel = 0
        fill.Parent = back
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.Transparency = 0.35
        stroke.Parent = back
        data.HealthTag, data.HealthFill = gui, fill
    end
    return data.HealthTag, data.HealthFill
end

local function UpdateESP()
    local roles = GetRoles()
    local localRoot = GetRoot()

    for player, data in pairs(ESPObjects) do
        local character = player.Character
        local root = GetTargetRoot(player)
        local head = GetHead(character)

        if not State.ESP or not character or not root then
            data.Highlight.Enabled = false
            data.NameTag.Enabled = false
            data.Tracer.Enabled = false
            if data.Box then data.Box.Visible = false end
            if data.RoleTag then data.RoleTag.Enabled = false end
            if data.HealthTag then data.HealthTag.Enabled = false end
            if data.Skeleton then
                for _, beam in pairs(data.Skeleton.Beams or {}) do beam.Enabled = false end
            end
            continue
        end

        -- Highlight MUST be parented; setting Adornee alone is not enough
        -- when the instance has no parent.
        data.Highlight.Adornee = character
        if data.Highlight.Parent ~= character then
            data.Highlight.Parent = character
        end
        data.Highlight.Enabled = true

        if head and State.ESPNames then
            data.NameTag.Adornee = head
            if data.NameTag.Parent ~= head then
                data.NameTag.Parent = head
            end
            data.NameTag.Enabled = true
        else
            data.NameTag.Enabled = false
            data.NameTag.Adornee = nil
        end

        local roleText = player.DisplayName
        local color = Color3.new(1, 1, 1)

        if player == roles.Murderer then
            roleText ..= "  [MURDERER]"
            color = Color3.fromRGB(255, 70, 70)
        elseif player == roles.Sheriff then
            roleText ..= "  [SHERIFF]"
            color = Color3.fromRGB(70, 160, 255)
        end

        if State.ESPDistance and localRoot then
            local distance = (localRoot.Position - root.Position).Magnitude
            roleText ..= string.format("  [%.0f]", distance)
        end

        local espColor = color
        if State.ESPRainbow then
            espColor = Color3.fromHSV((os.clock() * 0.12 + player.UserId % 20 / 20) % 1, 0.85, 1)
        end

        data.Label.Text = roleText
        data.Label.TextColor3 = espColor
        data.Highlight.FillColor = espColor
        data.Highlight.OutlineColor = Color3.new(1, 1, 1)

        if State.ESPBoxes then
            data.Box.Adornee = character
            data.Box.Color3 = espColor
            local size = character:GetExtentsSize()
            data.Box.Size = size + Vector3.new(0.18, 0.18, 0.18)
            data.Box.Parent = character
            data.Box.Visible = true
        else
            data.Box.Visible = false
        end

        if head and State.ESPRoleMarkers and (player == roles.Murderer or player == roles.Sheriff) then
            data.RoleTag.Adornee = head
            data.RoleTag.Parent = head
            data.RoleLabel.Text = player == roles.Murderer and "M" or "S"
            data.RoleLabel.TextColor3 = player == roles.Murderer and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(70, 160, 255)
            data.RoleTag.Enabled = true
        else
            data.RoleTag.Enabled = false
            data.RoleTag.Adornee = nil
        end

        if State.ESPPulse then
            local pulse = (math.sin(os.clock() * 4 + player.UserId * 0.01) + 1) * 0.5
            data.Highlight.FillTransparency = 0.34 + pulse * 0.28
            data.Highlight.OutlineTransparency = 0.04 + pulse * 0.12
        else
            data.Highlight.FillTransparency = 0.5
            data.Highlight.OutlineTransparency = 0
        end

        if State.ESPHealthBars and head then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local tag, fill = EnsureHealthBar(data, head)
            if tag and fill and humanoid then
                local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
                fill.Size = UDim2.fromScale(ratio, 1)
                fill.BackgroundColor3 = Color3.fromHSV(ratio * 0.33, 0.8, 1)
                tag.Adornee = head
                tag.Parent = head
                tag.Enabled = true
            end
        elseif data.HealthTag then
            data.HealthTag.Enabled = false
        end

        if State.ESPSkeleton then
            EnsureSkeleton(data, character, espColor)
        elseif data.Skeleton then
            DestroySkeleton(data)
        end

        if State.ESPTracers and localRoot then
            if EnsureTracerAttachments(data, root) then
                data.Tracer.Color = ColorSequence.new(espColor)
                data.Tracer.Enabled = true
            else
                data.Tracer.Enabled = false
            end
        else
            data.Tracer.Enabled = false
        end
    end
end

TrackConnection(RunService.RenderStepped:Connect(UpdateESP))

--========================================================--
--                    ESP SCREEN LAYER                   --
--========================================================--

local ESPOverlay = Instance.new("ScreenGui")
ESPOverlay.Name = "Nebula_ESPOverlay"
ESPOverlay.ResetOnSpawn = false
ESPOverlay.IgnoreGuiInset = true
ESPOverlay.Parent = LocalPlayer:WaitForChild("PlayerGui")
TrackInstance(ESPOverlay)

local ESPCrosshair = Instance.new("TextLabel")
ESPCrosshair.BackgroundTransparency = 1
ESPCrosshair.Size = UDim2.fromOffset(32, 32)
ESPCrosshair.AnchorPoint = Vector2.new(0.5, 0.5)
ESPCrosshair.Position = UDim2.fromScale(0.5, 0.5)
ESPCrosshair.Text = "+"
ESPCrosshair.TextScaled = true
ESPCrosshair.Font = Enum.Font.GothamBlack
ESPCrosshair.TextColor3 = Color3.fromRGB(220, 170, 255)
ESPCrosshair.TextStrokeTransparency = 0.2
ESPCrosshair.Visible = false
ESPCrosshair.Parent = ESPOverlay

PlayerSection:AddToggle({
    Name = "Crosshair",
    Default = false,
    Callback = function(v)
        State.Crosshair = v
        ESPCrosshair.Visible = v
    end
})

local ESPArrowPool = {}
local function GetArrow(index)
    local arrow = ESPArrowPool[index]
    if arrow then return arrow end
    arrow = Instance.new("TextLabel")
    arrow.BackgroundTransparency = 1
    arrow.Size = UDim2.fromOffset(34, 34)
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.Text = "▲"
    arrow.TextScaled = true
    arrow.Font = Enum.Font.GothamBlack
    arrow.TextStrokeTransparency = 0.15
    arrow.Visible = false
    arrow.Parent = ESPOverlay
    ESPArrowPool[index] = arrow
    return arrow
end

TrackConnection(RunService.RenderStepped:Connect(function()
    local used = 0
    if not State.ESP or not State.ESPArrows then
        for _, arrow in ipairs(ESPArrowPool) do arrow.Visible = false end
        return
    end

    local roles = GetRoles()
    local center = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
    local radius = math.min(Camera.ViewportSize.X, Camera.ViewportSize.Y) * 0.42

    for player, data in pairs(ESPObjects) do
        local root = GetTargetRoot(player)
        if root and player ~= LocalPlayer and IsAlive(player) then
            local screen, visible = Camera:WorldToViewportPoint(root.Position)
            if not visible or screen.Z < 0 then
                used += 1
                local arrow = GetArrow(used)
                local direction = Vector2.new(screen.X, screen.Y) - center
                if direction.Magnitude < 0.01 then direction = Vector2.new(0, -1) end
                direction = direction.Unit
                local pos = center + direction * radius
                arrow.Position = UDim2.fromOffset(pos.X, pos.Y)
                arrow.Rotation = math.deg(math.atan2(direction.Y, direction.X)) + 90
                arrow.TextColor3 = player == roles.Murderer and Color3.fromRGB(255, 70, 70) or player == roles.Sheriff and Color3.fromRGB(70, 160, 255) or Color3.fromRGB(220, 220, 255)
                arrow.Visible = true
            end
        end
    end

    for i = used + 1, #ESPArrowPool do
        ESPArrowPool[i].Visible = false
    end
end))

--========================================================--
--                       DROP GUN                         --
--========================================================--

local DropGunHighlight = Instance.new("Highlight")
DropGunHighlight.Name = "Nebula_DropGun"
DropGunHighlight.FillColor = Color3.fromRGB(70, 160, 255)
DropGunHighlight.FillTransparency = 0.25
DropGunHighlight.OutlineTransparency = 0
DropGunHighlight.Enabled = false
TrackInstance(DropGunHighlight)

local DropGunTag = Instance.new("BillboardGui")
DropGunTag.Name = "Nebula_DropGunTag"
DropGunTag.Size = UDim2.fromOffset(140, 32)
DropGunTag.AlwaysOnTop = true
DropGunTag.Enabled = false
TrackInstance(DropGunTag)

local DropGunLabel = Instance.new("TextLabel")
DropGunLabel.Size = UDim2.fromScale(1, 1)
DropGunLabel.BackgroundTransparency = 1
DropGunLabel.Text = "🔫 DROP GUN"
DropGunLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
DropGunLabel.TextStrokeTransparency = 0.2
DropGunLabel.TextScaled = true
DropGunLabel.Font = Enum.Font.GothamBold
DropGunLabel.Parent = DropGunTag

local function FindDroppedGun()
    local found

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "GunDrop" or obj.Name == "Gun" then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local parent = obj.Parent
                local inCharacter = parent and Players:GetPlayerFromCharacter(parent)
                if not inCharacter then
                    found = obj
                    break
                end
            end
        end
    end

    return found
end

TrackConnection(RunService.RenderStepped:Connect(function()
    if not State.DropGunESP then
        DropGunHighlight.Enabled = false
        DropGunTag.Enabled = false
        return
    end

    local gun = FindDroppedGun()
    if not gun then
        DropGunHighlight.Enabled = false
        DropGunTag.Enabled = false
        return
    end

    local adornee = gun:IsA("Model") and gun or gun
    DropGunHighlight.Adornee = adornee
    DropGunHighlight.Enabled = true

    local part = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart", true)
    if part then
        DropGunTag.Adornee = part
        DropGunTag.Enabled = true
    end
end))

--========================================================--
--                 NEBULA HUD / RADAR                     --
--========================================================--

local HUDGui = Instance.new("ScreenGui")
HUDGui.Name = "Nebula_HUD_v56"
HUDGui.ResetOnSpawn = false
HUDGui.IgnoreGuiInset = true
HUDGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HUDGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
TrackInstance(HUDGui)

local HUDFrame = Instance.new("Frame")
HUDFrame.Size = UDim2.fromOffset(230, 92)
HUDFrame.Position = UDim2.new(1, -246, 0, 18)
HUDFrame.BackgroundColor3 = Color3.fromRGB(17, 10, 28)
HUDFrame.BackgroundTransparency = 0.16
HUDFrame.BorderSizePixel = 0
HUDFrame.Visible = false
HUDFrame.Parent = HUDGui
local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 14)
hudCorner.Parent = HUDFrame
local hudStroke = Instance.new("UIStroke")
hudStroke.Thickness = 1
hudStroke.Transparency = 0.28
hudStroke.Parent = HUDFrame

local HUDLabel = Instance.new("TextLabel")
HUDLabel.Size = UDim2.new(1, -18, 1, -12)
HUDLabel.Position = UDim2.fromOffset(9, 6)
HUDLabel.BackgroundTransparency = 1
HUDLabel.TextXAlignment = Enum.TextXAlignment.Left
HUDLabel.TextYAlignment = Enum.TextYAlignment.Top
HUDLabel.Font = Enum.Font.GothamSemibold
HUDLabel.TextSize = 13
HUDLabel.TextColor3 = Color3.fromRGB(238, 225, 255)
HUDLabel.Parent = HUDFrame

local RadarFrame = Instance.new("Frame")
RadarFrame.Size = UDim2.fromOffset(150, 150)
RadarFrame.Position = UDim2.new(0, 18, 1, -168)
RadarFrame.BackgroundColor3 = Color3.fromRGB(14, 8, 22)
RadarFrame.BackgroundTransparency = 0.24
RadarFrame.BorderSizePixel = 0
RadarFrame.Visible = false
RadarFrame.Parent = HUDGui
local radarCorner = Instance.new("UICorner")
radarCorner.CornerRadius = UDim.new(1, 0)
radarCorner.Parent = RadarFrame
local radarStroke = Instance.new("UIStroke")
radarStroke.Thickness = 1
radarStroke.Transparency = 0.2
radarStroke.Parent = RadarFrame

local RadarCenter = Instance.new("Frame")
RadarCenter.Size = UDim2.fromOffset(7, 7)
RadarCenter.AnchorPoint = Vector2.new(0.5, 0.5)
RadarCenter.Position = UDim2.fromScale(0.5, 0.5)
RadarCenter.BackgroundColor3 = Color3.fromRGB(245, 235, 255)
RadarCenter.BorderSizePixel = 0
RadarCenter.Parent = RadarFrame
local radarCenterCorner = Instance.new("UICorner")
radarCenterCorner.CornerRadius = UDim.new(1, 0)
radarCenterCorner.Parent = RadarCenter

local RadarSweep = Instance.new("Frame")
RadarSweep.Name = "Sweep"
RadarSweep.AnchorPoint = Vector2.new(0.5, 1)
RadarSweep.Position = UDim2.fromScale(0.5, 0.5)
RadarSweep.Size = UDim2.fromOffset(2, 66)
RadarSweep.BackgroundColor3 = Color3.fromRGB(185, 90, 255)
RadarSweep.BackgroundTransparency = 0.35
RadarSweep.BorderSizePixel = 0
RadarSweep.Rotation = 0
RadarSweep.Parent = RadarFrame

for i = 1, 2 do
    local ring = Instance.new("Frame")
    ring.Size = UDim2.fromScale(0.32 * i, 0.32 * i)
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.fromScale(0.5, 0.5)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0
    ring.Parent = RadarFrame
    local ringStroke = Instance.new("UIStroke")
    ringStroke.Thickness = 1
    ringStroke.Transparency = 0.72
    ringStroke.Parent = ring
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring
end

local RadarDots = {}
local function GetRadarDot(index)
    local dot = RadarDots[index]
    if dot then return dot end
    dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(8, 8)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BorderSizePixel = 0
    dot.Visible = false
    dot.Parent = RadarFrame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = dot
    RadarDots[index] = dot
    return dot
end

local HUDFrameCount = 0
local HUDFPS = 0
local HUDLastFPSUpdate = os.clock()
local function UpdateNebulaHUD()
    HUDFrameCount += 1
    local now = os.clock()
    if now - HUDLastFPSUpdate >= 0.5 then
        HUDFPS = math.floor(HUDFrameCount / math.max(0.1, now - HUDLastFPSUpdate) + 0.5)
        HUDFrameCount = 0
        HUDLastFPSUpdate = now
    end

    local roleMurderer, roleSheriff = GetMurderer(), GetSheriff()
    HUDFrame.Visible = State.RoleHUD
    RadarFrame.Visible = State.ThreatRadar

    if State.RoleHUD then
        local localRole = "INNOCENT"
        if LocalPlayer == roleMurderer then localRole = "MURDERER" elseif LocalPlayer == roleSheriff then localRole = "SHERIFF" end
        local target = State.SheriffAim and roleMurderer or nil
        local targetName = target and target.DisplayName or "—"
        local ping = "?"
        pcall(function() ping = string.format("%.0f ms", LocalPlayer:GetNetworkPing() * 1000) end)
        HUDLabel.Text = string.format("NEBULA 5.6\nROLE   %s\nTARGET %s\nFPS    %d  |  PING %s", localRole, targetName, HUDFPS, ping)
    end

    if State.ThreatRadar then
        RadarSweep.Rotation = (now * 90) % 360
        local root = GetRoot()
        local count = 0
        if root then
            local maxRange = math.max(10, State.RadarRange)
            for player in pairs(ESPObjects) do
                if player ~= LocalPlayer then
                    local targetRoot = GetTargetRoot(player)
                    if targetRoot and IsAlive(player) then
                        local offset = targetRoot.Position - root.Position
                        local flat = Vector3.new(offset.X, 0, offset.Z)
                        local distance = flat.Magnitude
                        if distance <= maxRange and distance > 0.1 then
                            count += 1
                            local dot = GetRadarDot(count)
                            local x = math.clamp(flat.X / maxRange, -1, 1)
                            local y = math.clamp(flat.Z / maxRange, -1, 1)
                            dot.Position = UDim2.fromScale(0.5 + x * 0.42, 0.5 + y * 0.42)
                            dot.BackgroundColor3 = player == roleMurderer and Color3.fromRGB(255, 70, 70) or player == roleSheriff and Color3.fromRGB(70, 160, 255) or Color3.fromRGB(196, 105, 255)
                            dot.Visible = true
                        end
                    end
                end
            end
        end
        for i = count + 1, #RadarDots do RadarDots[i].Visible = false end
    else
        RadarSweep.Rotation = 0
        for _, dot in ipairs(RadarDots) do dot.Visible = false end
    end
end

TrackConnection(RunService.Heartbeat:Connect(UpdateNebulaHUD))

local HUDSection = VisualsTab:AddSection("Nebula HUD")
HUDSection:AddToggle({
    Name = "Role / Target HUD",
    Default = false,
    Callback = function(v) State.RoleHUD = v end
})
HUDSection:AddToggle({
    Name = "Threat Radar",
    Default = false,
    Callback = function(v) State.ThreatRadar = v end
})
HUDSection:AddSlider({
    Name = "Radar Range",
    Min = 25,
    Max = 200,
    Default = 90,
    Callback = function(v) State.RadarRange = v end
})

--========================================================--
--                       MOVEMENT                         --
--========================================================--

local MoveSection = MovementTab:AddSection("Movement")

MoveSection:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 150,
    Default = 16,
    Callback = function(v)
        State.Speed = v
        local humanoid = GetHumanoid()
        if humanoid and not State.SpeedGlitch then
            humanoid.WalkSpeed = v
        end
    end
})

MoveSection:AddSlider({
    Name = "JumpPower",
    Min = 50,
    Max = 300,
    Default = 50,
    Callback = function(v)
        State.JumpPower = v
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid.JumpPower = v
        end
    end
})

MoveSection:AddToggle({
    Name = "Speedglitch",
    Default = false,
    Callback = function(v)
        State.SpeedGlitch = v
    end
})

MoveSection:AddSlider({
    Name = "Speedglitch Speed",
    Min = 16,
    Max = 200,
    Default = 50,
    Callback = function(v)
        State.SpeedGlitchSpeed = v
    end
})

MoveSection:AddToggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = function(v)
        State.InfJump = v
    end
})

MoveSection:AddToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(v)
        State.Noclip = v
    end
})

MoveSection:AddToggle({
    Name = "Fly",
    Default = false,
    Callback = function(v)
        State.Fly = v
    end
})

MoveSection:AddSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = 50,
    Callback = function(v)
        State.FlySpeed = v
    end
})

TrackConnection(RunService.Heartbeat:Connect(function()
    local humanoid = GetHumanoid()
    if not humanoid then
        return
    end

    if not State.SpeedGlitch then
        humanoid.WalkSpeed = State.Speed
        return
    end

    local state = humanoid:GetState()
    local airborne =
        state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.Freefall
        or state == Enum.HumanoidStateType.FallingDown

    humanoid.WalkSpeed = airborne and State.SpeedGlitchSpeed or State.Speed
end))

TrackConnection(UserInputService.JumpRequest:Connect(function()
    if State.InfJump then
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

local NoclipParts = {}
local NoclipOriginal = {}

local function CacheNoclipParts(character)
    table.clear(NoclipParts)
    table.clear(NoclipOriginal)
    if not character then
        return
    end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(NoclipParts, part)
            NoclipOriginal[part] = part.CanCollide
        end
    end
end

local function RestoreNoclip()
    for part, value in pairs(NoclipOriginal) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = value
            end)
        end
    end
end

CacheNoclipParts(GetCharacter())

TrackConnection(RunService.Stepped:Connect(function()
    if State.Noclip then
        for _, part in ipairs(NoclipParts) do
            if part and part.Parent then
                part.CanCollide = false
            end
        end
    end
end))

--========================================================--
--                         FLY                            --
--========================================================--

local FlyVelocity
local FlyGyro

local function StopFly()
    SafeDestroy(FlyVelocity)
    SafeDestroy(FlyGyro)
    FlyVelocity = nil
    FlyGyro = nil

    local humanoid = GetHumanoid()
    if humanoid then
        humanoid.PlatformStand = false
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
    FlyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyVelocity.Velocity = Vector3.zero
    FlyVelocity.Parent = root

    FlyGyro = Instance.new("BodyGyro")
    FlyGyro.Name = "Nebula_FlyGyro"
    FlyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    FlyGyro.P = 90000
    FlyGyro.D = 500
    FlyGyro.CFrame = Camera.CFrame
    FlyGyro.Parent = root
end

local function GetKeyboardFlyDirection()
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

    return direction
end

TrackConnection(RunService.RenderStepped:Connect(function()
    if not State.Fly then
        StopFly()
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

    local direction = GetKeyboardFlyDirection()
    if direction.Magnitude > 0 then
        direction = direction.Unit
    end

    FlyVelocity.Velocity = direction * State.FlySpeed
    FlyGyro.CFrame = Camera.CFrame
end))

--========================================================--
--                       EFFECTS                          --
--========================================================--

local EffectSection = EffectsTab:AddSection("Character Effects")

EffectSection:AddToggle({
    Name = "Wings",
    Default = false,
    Callback = function(v)
        State.Wings = v
    end
})

EffectSection:AddToggle({
    Name = "Aura",
    Default = false,
    Callback = function(v)
        State.AuraFX = v
    end
})

EffectSection:AddToggle({
    Name = "Particles",
    Default = false,
    Callback = function(v)
        State.Particles = v
    end
})

EffectSection:AddToggle({
    Name = "Trail",
    Default = false,
    Callback = function(v)
        State.Trail = v
    end
})

EffectSection:AddToggle({
    Name = "Footstep FX",
    Default = false,
    Callback = function(v)
        State.Footsteps = v
    end
})

EffectSection:AddToggle({
    Name = "Orbit Particles",
    Default = false,
    Callback = function(v)
        State.OrbitParticles = v
    end
})

EffectSection:AddToggle({
    Name = "Rainbow FX",
    Default = false,
    Callback = function(v)
        State.Rainbow = v
    end
})

local VisibilitySection = EffectsTab:AddSection("Visibility")

VisibilitySection:AddToggle({
    Name = "Local Invisibility",
    Default = false,
    Callback = function(v)
        State.Invisibility = v
    end
})

--========================================================--
--                   EFFECT MANAGER                       --
--========================================================--

local CharacterFX = {}

local function ClearCharacterEffects()
    for _, object in pairs(CharacterFX) do
        SafeDestroy(object)
    end
    table.clear(CharacterFX)
end

local function MakeAttachment(parent, name, position)
    local attachment = Instance.new("Attachment")
    attachment.Name = name
    attachment.Position = position or Vector3.zero
    attachment.Parent = parent
    table.insert(CharacterFX, attachment)
    return attachment
end

local function BuildWings(character)
    if not State.Wings then
        return
    end

    local root = GetRoot()
    if not root then
        return
    end

    local left = MakeAttachment(root, "Nebula_WingL", Vector3.new(-1.4, 0.7, 0.4))
    local right = MakeAttachment(root, "Nebula_WingR", Vector3.new(1.4, 0.7, 0.4))

    for _, attachment in ipairs({left, right}) do
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "Nebula_WingParticles"
        emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        emitter.Rate = 10
        emitter.Lifetime = NumberRange.new(0.7, 1.2)
        emitter.Speed = NumberRange.new(0.5, 1.5)
        emitter.SpreadAngle = Vector2.new(25, 25)
        emitter.Parent = attachment
        table.insert(CharacterFX, emitter)
    end
end

local function BuildAura(character)
    if not State.AuraFX then
        return
    end

    local root = GetRoot()
    if not root then
        return
    end

    local attachment = MakeAttachment(root, "Nebula_Aura")

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "Nebula_AuraParticles"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Rate = 20
    emitter.Lifetime = NumberRange.new(0.5, 1)
    emitter.Speed = NumberRange.new(1, 2)
    emitter.SpreadAngle = Vector2.new(360, 360)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.Parent = attachment
    table.insert(CharacterFX, emitter)
end

local function BuildParticles(character)
    if not State.Particles then
        return
    end

    local root = GetRoot()
    if not root then
        return
    end

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "Nebula_Particles"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Rate = 8
    emitter.Lifetime = NumberRange.new(1, 2)
    emitter.Speed = NumberRange.new(0.5, 1.5)
    emitter.SpreadAngle = Vector2.new(360, 360)
    emitter.Parent = root
    table.insert(CharacterFX, emitter)
end

local function BuildTrail(character)
    if not State.Trail then
        return
    end

    local root = GetRoot()
    if not root then
        return
    end

    local a0 = MakeAttachment(root, "Nebula_TrailA", Vector3.new(-0.7, 0, 0))
    local a1 = MakeAttachment(root, "Nebula_TrailB", Vector3.new(0.7, 0, 0))

    local trail = Instance.new("Trail")
    trail.Name = "Nebula_Trail"
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Lifetime = 0.35
    trail.MinLength = 0.1
    trail.Enabled = true
    trail.Parent = root
    table.insert(CharacterFX, trail)
end

local function BuildOrbit(character)
    if not State.OrbitParticles then
        return
    end

    local root = GetRoot()
    if not root then
        return
    end

    local attachment = MakeAttachment(root, "Nebula_Orbit")
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "Nebula_OrbitParticles"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Rate = 12
    emitter.Lifetime = NumberRange.new(1.2)
    emitter.Speed = NumberRange.new(0)
    emitter.RotSpeed = NumberRange.new(90, 150)
    emitter.SpreadAngle = Vector2.new(360, 360)
    emitter.Parent = attachment
    table.insert(CharacterFX, emitter)
end

local function BuildEffects()
    ClearCharacterEffects()

    local character = GetCharacter()
    if not character then
        return
    end

    BuildWings(character)
    BuildAura(character)
    BuildParticles(character)
    BuildTrail(character)
    BuildOrbit(character)
end

-- Rebuild toggled effects when their state changes.
for _, key in ipairs({
    "Wings",
    "AuraFX",
    "Particles",
    "Trail",
    "OrbitParticles"
}) do
    -- handled by periodic state watcher below
end

local LastFXState = ""

local function FXSignature()
    return table.concat({
        tostring(State.Wings),
        tostring(State.AuraFX),
        tostring(State.Particles),
        tostring(State.Trail),
        tostring(State.OrbitParticles)
    }, "|")
end

TrackConnection(RunService.Heartbeat:Connect(function()
    local signature = FXSignature()

    if signature ~= LastFXState then
        LastFXState = signature
        BuildEffects()
    end

    if State.Rainbow then
        local hue = (os.clock() * 0.15) % 1
        local color = Color3.fromHSV(hue, 0.8, 1)

        for _, object in ipairs(CharacterFX) do
            if object:IsA("ParticleEmitter") or object:IsA("Trail") then
                pcall(function()
                    object.Color = ColorSequence.new(color)
                end)
            end
        end
    end
end))

--========================================================--
--                 NEBULA VFX ENGINE v2                   --
--  This layer extends the existing Nebula FX architecture. --
--  It does not replace the existing combat/ESP/movement. --
--========================================================--

local VFX = {
    Aura = false,
    Orbit = false,
    Wings = false,
    BodyParticles = false,
    Trail = false,
    Footsteps = false,
    SkyParticles = false,
    Rainbow = false,
    Environment = false,
    FOVCircle = false,
    TargetPulse = false,
    Shockwaves = false,
    EnergyCore = false,
    GroundSigil = false,
    FloatingOrbs = false,
    ScreenGlow = false,

    AuraRadius = 3.5,
    OrbitRadius = 3.2,
    OrbitCount = 10,
    SkyCount = 28,
    FootstepLifetime = 1.0,
    FOVRadius = 120,
    FOVColor = Color3.fromRGB(185, 90, 255),
    AuraColor = Color3.fromRGB(175, 70, 255),
    WingColor = Color3.fromRGB(135, 70, 255),
    ParticleColor = Color3.fromRGB(225, 175, 255),
    TrailColor = Color3.fromRGB(165, 80, 255),
}

local VFXRoot = nil
local VFXObjects = {}
local VFXConnections = {}
local SkyParticles = {}
local FootstepLast = 0
local FootstepSide = 0

local function VFXDestroy(object)
    if object then
        pcall(function() object:Destroy() end)
    end
end

local function VFXDisconnectAll()
    for i = #VFXConnections, 1, -1 do
        local connection = VFXConnections[i]
        VFXConnections[i] = nil
        pcall(function() connection:Disconnect() end)
    end
end

local function VFXTrackConnection(connection)
    if connection then
        table.insert(VFXConnections, connection)
    end
    return connection
end

local function VFXColor(base, offset)
    if VFX.Rainbow then
        return Color3.fromHSV((os.clock() * 0.12 + (offset or 0)) % 1, 0.82, 1)
    end
    return base
end

local function VFXRootForCharacter()
    local character = GetCharacter()
    if not character then return nil end

    if VFXRoot and VFXRoot.Parent == character then
        return VFXRoot
    end

    VFXDestroy(VFXRoot)
    VFXRoot = Instance.new("Folder")
    VFXRoot.Name = "NebulaVFX_v2"
    VFXRoot.Parent = character
    return VFXRoot
end

local function VFXPart(parent, name, size, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size or Vector3.one
    part.Color = color or Color3.new(1, 1, 1)
    part.Material = Enum.Material.Neon
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function VFXBall(parent, name, diameter, color)
    local ball = VFXPart(parent, name, Vector3.new(diameter, diameter, diameter), color)
    ball.Shape = Enum.PartType.Ball
    return ball
end

local function BuildExtraVFX()
    local root = GetRoot()
    local folder = VFXRootForCharacter()
    if not root or not folder then return end

    if VFX.EnergyCore then
        local core = VFXBall(folder, "EnergyCore", 0.55, VFX.WingColor)
        core.Transparency = 0.1
        local light = Instance.new("PointLight")
        light.Color = VFX.WingColor
        light.Brightness = 2
        light.Range = 8
        light.Parent = core
        VFXObjects.EnergyCore = core
    end

    if VFX.Shockwaves then
        local waves = Instance.new("Folder")
        waves.Name = "Shockwaves"
        waves.Parent = folder
        VFXObjects.Shockwaves = waves
        for i = 1, 3 do
            local ring = VFXPart(waves, "Wave_" .. i, Vector3.new(0.08, 0.08, 0.08), VFX.AuraColor)
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.Cylinder
            mesh.Scale = Vector3.new(0.7, 0.035, 0.7)
            mesh.Parent = ring
            VFXObjects["Wave" .. i] = {Part = ring, Mesh = mesh, Phase = i * 0.9}
        end
    end

    if VFX.GroundSigil then
        local sigil = Instance.new("Folder")
        sigil.Name = "GroundSigil"
        sigil.Parent = folder
        local rings = {}
        for i = 1, 3 do
            local ring = VFXPart(sigil, "SigilRing_" .. i, Vector3.new(0.08, 0.08, 0.08), VFX.WingColor)
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.Cylinder
            mesh.Scale = Vector3.new(1.8 + i * 0.7, 0.02, 1.8 + i * 0.7)
            mesh.Parent = ring
            rings[i] = {Part = ring, Mesh = mesh, Phase = i * 0.65}
        end
        local core = VFXBall(sigil, "SigilCore", 0.28, VFX.ParticleColor)
        VFXObjects.GroundSigil = {Container = sigil, Rings = rings, Core = core}
    end

    if VFX.FloatingOrbs then
        local orbs = Instance.new("Folder")
        orbs.Name = "FloatingOrbs"
        orbs.Parent = folder
        local nodes = {}
        for i = 1, 8 do
            local orb = VFXBall(orbs, "FloatOrb_" .. i, 0.11 + (i % 3) * 0.035, VFX.ParticleColor)
            nodes[i] = {Part = orb, Phase = i * math.pi / 4, Height = 0.6 + (i % 4) * 0.3}
        end
        VFXObjects.FloatingOrbs = {Container = orbs, Nodes = nodes}
    end
end

local function DestroyAdvancedVFX()
    VFXDestroy(VFXRoot)
    VFXRoot = nil
    table.clear(VFXObjects)
    table.clear(SkyParticles)
end

local function BuildAuraV2()
    if not VFX.Aura then return end
    local root = GetRoot()
    local folder = VFXRootForCharacter()
    if not root or not folder then return end

    local container = Instance.new("Folder")
    container.Name = "AuraV2"
    container.Parent = folder

    local rings = {}
    for i = 1, 3 do
        local ring = VFXPart(container, "Ring_" .. i, Vector3.new(0.08, 0.08, 0.08), VFX.AuraColor)
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Cylinder
        mesh.Scale = Vector3.new(VFX.AuraRadius + i * 0.42, 0.035, VFX.AuraRadius + i * 0.42)
        mesh.Parent = ring
        rings[i] = {Part = ring, Mesh = mesh, Phase = i * 0.7}
    end

    local nodes = {}
    for i = 1, 20 do
        local node = VFXBall(container, "Node_" .. i, 0.13, VFX.AuraColor)
        nodes[i] = {Part = node, Phase = i * (math.pi * 2 / 20), Height = 0.2 + (i % 5) * 0.28}
    end

    VFXObjects.Aura = {Container = container, Rings = rings, Nodes = nodes}
end

local function BuildOrbitV2()
    if not VFX.Orbit then return end
    local root = GetRoot()
    local folder = VFXRootForCharacter()
    if not root or not folder then return end

    local container = Instance.new("Folder")
    container.Name = "OrbitV2"
    container.Parent = folder

    local nodes = {}
    for i = 1, VFX.OrbitCount do
        local node = VFXBall(container, "Orb_" .. i, 0.16, VFX.ParticleColor)
        nodes[i] = {Part = node, Phase = i * (math.pi * 2 / VFX.OrbitCount), Height = 0.25 + (i % 4) * 0.35}
    end
    VFXObjects.Orbit = {Container = container, Nodes = nodes}
end

local function MakeWingPart(parent, side, index, color)
    local part = VFXPart(parent, side .. "_Feather_" .. index, Vector3.new(0.18, 0.7, 1.45), color)
    part.Shape = Enum.PartType.Wedge
    return part
end

local function BuildWingsV2()
    if not VFX.Wings then return end
    local root = GetRoot()
    local folder = VFXRootForCharacter()
    if not root or not folder then return end

    local container = Instance.new("Folder")
    container.Name = "WingsV2"
    container.Parent = folder

    local feathers = {}
    for sideIndex, side in ipairs({"L", "R"}) do
        local sign = sideIndex == 1 and -1 or 1
        for i = 1, 7 do
            local feather = MakeWingPart(container, side, i, VFX.WingColor)
            feathers[#feathers + 1] = {Part = feather, Sign = sign, Index = i}
        end
    end

    local core = VFXBall(container, "WingCore", 0.42, VFX.WingColor)
    VFXObjects.Wings = {Container = container, Feathers = feathers, Core = core}
end

local function BuildBodyParticlesV2()
    if not VFX.BodyParticles then return end
    local root = GetRoot()
    local folder = VFXRootForCharacter()
    if not root or not folder then return end

    local attachment = Instance.new("Attachment")
    attachment.Name = "BodyParticlesV2"
    attachment.Parent = root

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "NebulaBodyParticles"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Rate = 28
    emitter.Lifetime = NumberRange.new(0.55, 1.15)
    emitter.Speed = NumberRange.new(0.4, 2.0)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.RotSpeed = NumberRange.new(-100, 100)
    emitter.LightEmission = 1
    emitter.LightInfluence = 0
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.03),
        NumberSequenceKeypoint.new(0.25, 0.16),
        NumberSequenceKeypoint.new(0.8, 0.09),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.7, 0.35),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Color = ColorSequence.new(VFX.ParticleColor)
    emitter.Parent = attachment
    VFXObjects.BodyParticles = {Attachment = attachment, Emitter = emitter}
end

local function BuildTrailV2()
    if not VFX.Trail then return end
    local root = GetRoot()
    local folder = VFXRootForCharacter()
    if not root or not folder then return end

    local a0 = Instance.new("Attachment")
    a0.Name = "TrailA0"
    a0.Position = Vector3.new(-0.65, -1.5, 0)
    a0.Parent = root

    local a1 = Instance.new("Attachment")
    a1.Name = "TrailA1"
    a1.Position = Vector3.new(0.65, -1.5, 0)
    a1.Parent = root

    local trail = Instance.new("Trail")
    trail.Name = "NebulaTrailV2"
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Lifetime = 0.5
    trail.MinLength = 0.04
    trail.FaceCamera = true
    trail.LightEmission = 1
    trail.Color = ColorSequence.new(VFX.TrailColor)
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.65, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.Parent = root
    VFXObjects.Trail = {A0 = a0, A1 = a1, Trail = trail}
end

local function BuildFootstepsV2()
    if not VFX.Footsteps then return end
    local folder = VFXRootForCharacter()
    if not folder then return end
    VFXObjects.Footsteps = {Folder = folder}
end

local function BuildAdvancedVFX()
    DestroyAdvancedVFX()
    if not (VFX.Aura or VFX.Orbit or VFX.Wings or VFX.BodyParticles or VFX.Trail or VFX.Footsteps or VFX.EnergyCore or VFX.Shockwaves or VFX.GroundSigil or VFX.FloatingOrbs) then return end
    BuildAuraV2()
    BuildOrbitV2()
    BuildWingsV2()
    BuildBodyParticlesV2()
    BuildTrailV2()
    BuildFootstepsV2()
    BuildExtraVFX()
end

local function UpdateAdvancedVFX()
    local root = GetRoot()
    if not root then return end

    if VFXObjects.EnergyCore and VFXObjects.EnergyCore.Parent then
        local core = VFXObjects.EnergyCore
        core.CFrame = root.CFrame * CFrame.new(0, 1.4, 0)
        core.Color = VFXColor(VFX.WingColor)
    end

    for i = 1, 3 do
        local wave = VFXObjects["Wave" .. i]
        if wave and wave.Part and wave.Part.Parent then
            local t = (os.clock() * 0.8 + wave.Phase) % 2
            local scale = 0.6 + t * 1.9
            wave.Part.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, os.clock() * 0.5, 0)
            wave.Mesh.Scale = Vector3.new(scale, 0.035, scale)
            wave.Part.Transparency = math.clamp(t / 2, 0.05, 1)
            wave.Part.Color = VFXColor(VFX.AuraColor, i / 3)
        end
    end
    local now = os.clock()

    local sigil = VFXObjects.GroundSigil
    if sigil and sigil.Container and sigil.Container.Parent then
        for i, item in ipairs(sigil.Rings) do
            local spin = now * (0.45 + i * 0.08) + item.Phase
            local pulse = 1 + math.sin(now * 2.5 + item.Phase) * 0.08
            local base = 1.5 + i * 0.6
            item.Part.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.45, 0)) * CFrame.Angles(0, spin, 0)
            item.Mesh.Scale = Vector3.new(base * pulse, 0.02, base * pulse)
            item.Part.Transparency = 0.12 + (math.sin(now * 3 + i) + 1) * 0.16
            item.Part.Color = VFXColor(VFX.WingColor, i / 3)
        end
        sigil.Core.CFrame = root.CFrame * CFrame.new(0, -2.2, 0)
        sigil.Core.Color = VFXColor(VFX.ParticleColor)
    end

    local floating = VFXObjects.FloatingOrbs
    if floating and floating.Container and floating.Container.Parent then
        for i, item in ipairs(floating.Nodes) do
            local angle = item.Phase + now * (0.35 + i * 0.015)
            local radius = 2.1 + math.sin(now * 1.4 + i) * 0.35
            item.Part.CFrame = CFrame.new(root.Position) * CFrame.new(math.cos(angle) * radius, item.Height + math.sin(now * 1.8 + i) * 0.4, math.sin(angle) * radius)
            item.Part.Color = VFXColor(VFX.ParticleColor, i / #floating.Nodes)
            item.Part.Transparency = 0.12 + (math.sin(now * 3 + i) + 1) * 0.1
        end
    end

    local aura = VFXObjects.Aura
    if aura and aura.Container and aura.Container.Parent then
        for i, item in ipairs(aura.Rings) do
            item.Part.CFrame = root.CFrame
                * CFrame.new(0, 0.15 + math.sin(now * 2 + item.Phase) * 0.08, 0)
                * CFrame.Angles(0, now * (0.7 + i * 0.12), 0)
            item.Part.Color = VFXColor(VFX.AuraColor)
        end
        for i, item in ipairs(aura.Nodes) do
            local angle = item.Phase + now * (0.65 + i * 0.008)
            local radius = VFX.AuraRadius + math.sin(now * 2 + i) * 0.12
            item.Part.CFrame = CFrame.new(root.Position)
                * CFrame.new(math.cos(angle) * radius, item.Height + math.sin(now * 2.5 + i) * 0.25, math.sin(angle) * radius)
            item.Part.Color = VFXColor(VFX.AuraColor, i / 20)
        end
    end

    local orbit = VFXObjects.Orbit
    if orbit and orbit.Container and orbit.Container.Parent then
        for i, item in ipairs(orbit.Nodes) do
            local angle = item.Phase + now * 0.9
            local radius = VFX.OrbitRadius + math.sin(now * 1.7 + i) * 0.12
            item.Part.CFrame = CFrame.new(root.Position)
                * CFrame.new(math.cos(angle) * radius, item.Height + math.sin(now * 2 + i) * 0.25, math.sin(angle) * radius)
            item.Part.Color = VFXColor(VFX.ParticleColor, i / math.max(1, VFX.OrbitCount))
        end
    end

    local wings = VFXObjects.Wings
    if wings and wings.Container and wings.Container.Parent then
        for _, item in ipairs(wings.Feathers) do
            local i = item.Index
            local spread = 0.55 + i * 0.38
            local y = 1.05 + (i % 3) * 0.22
            local z = 0.2 + i * 0.12
            local flap = math.sin(now * 3.0 + i * 0.35) * (0.08 + i * 0.008)
            item.Part.CFrame = root.CFrame
                * CFrame.new(item.Sign * spread, y, z)
                * CFrame.Angles(math.rad(-10 - i * 2) + flap, math.rad(item.Sign * (18 + i * 2)), math.rad(item.Sign * (12 + i)))
            item.Part.Color = VFXColor(VFX.WingColor, i / 7)
        end
        wings.Core.CFrame = root.CFrame * CFrame.new(0, 1.05, 0.45)
        wings.Core.Color = VFXColor(VFX.WingColor)
    end

    local body = VFXObjects.BodyParticles
    if body and body.Emitter then
        body.Emitter.Color = ColorSequence.new(VFXColor(VFX.ParticleColor))
    end

    local trail = VFXObjects.Trail
    if trail and trail.Trail then
        trail.Trail.Color = ColorSequence.new(VFXColor(VFX.TrailColor))
    end
end

local function UpdateFootstepsV2()
    if not VFX.Footsteps then return end
    local character = GetCharacter()
    local root = GetRoot()
    local humanoid = GetHumanoid()
    if not character or not root or not humanoid or humanoid.MoveDirection.Magnitude < 0.05 then return end

    local now = os.clock()
    if now - FootstepLast < 0.18 then return end
    FootstepLast = now
    FootstepSide = FootstepSide * -1

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character, VFXRoot}
    local origin = root.Position + root.CFrame.RightVector * (0.35 * FootstepSide) + Vector3.new(0, 1, 0)
    local result = workspace:Raycast(origin, Vector3.new(0, -5, 0), params)
    if not result then return end

    local folder = VFXRootForCharacter()
    if not folder then return end
    local step = VFXPart(folder, "Step", Vector3.new(0.16, 0.025, 0.85), VFX.ParticleColor)
    step.CFrame = CFrame.new(result.Position + Vector3.new(0, 0.035, 0))
        * CFrame.Angles(0, math.atan2(root.CFrame.LookVector.X, root.CFrame.LookVector.Z), 0)
    step.Transparency = 0.15
    step.Size = Vector3.new(0.16, 0.025, 0.2)
    TweenService:Create(step, TweenInfo.new(VFX.FootstepLifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = Vector3.new(0.45, 0.025, 1.1),
    }):Play()
    task.delay(VFX.FootstepLifetime + 0.05, function() VFXDestroy(step) end)
end

--========================================================--
--                  FOV / TARGET VISUALS                  --
--========================================================--

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "Nebula_FOV"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.Enabled = false
FOVGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
TrackInstance(FOVGui)

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "Circle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
FOVCircle.Size = UDim2.fromOffset(VFX.FOVRadius * 2, VFX.FOVRadius * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Parent = FOVGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.5
FOVStroke.Transparency = 0.15
FOVStroke.Color = VFX.FOVColor
FOVStroke.Parent = FOVCircle

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local BloomEffect = Instance.new("BloomEffect")
BloomEffect.Name = "Nebula_Bloom_v56"
BloomEffect.Intensity = 0
BloomEffect.Size = 24
BloomEffect.Threshold = 1
BloomEffect.Parent = Lighting
TrackInstance(BloomEffect)

local GlowColor = Instance.new("ColorCorrectionEffect")
GlowColor.Name = "Nebula_Glow_v56"
GlowColor.Brightness = 0
GlowColor.Contrast = 0
GlowColor.Saturation = 0
GlowColor.TintColor = Color3.new(1, 1, 1)
GlowColor.Parent = Lighting
TrackInstance(GlowColor)

local TargetPulse = Instance.new("Highlight")
TargetPulse.Name = "Nebula_TargetPulse"
TargetPulse.FillTransparency = 0.78
TargetPulse.OutlineTransparency = 0.05
TargetPulse.FillColor = Color3.fromRGB(255, 80, 100)
TargetPulse.OutlineColor = Color3.fromRGB(255, 255, 255)
TargetPulse.Enabled = false
TrackInstance(TargetPulse)

VFXTrackConnection(RunService.RenderStepped:Connect(function()
    if VFX.FOVCircle then
        FOVGui.Enabled = true
        FOVCircle.Size = UDim2.fromOffset(VFX.FOVRadius * 2, VFX.FOVRadius * 2)
        FOVStroke.Color = VFXColor(VFX.FOVColor)
    else
        FOVGui.Enabled = false
    end

    if VFX.ScreenGlow then
        local pulse = (math.sin(os.clock() * 1.5) + 1) * 0.5
        BloomEffect.Intensity = 0.8 + pulse * 0.35
        GlowColor.Brightness = 0.02 + pulse * 0.01
        GlowColor.Contrast = 0.05 + pulse * 0.03
        GlowColor.Saturation = 0.06 + pulse * 0.04
        GlowColor.TintColor = VFXColor(Color3.fromRGB(232, 216, 255))
    else
        BloomEffect.Intensity = 0
        GlowColor.Brightness = 0
        GlowColor.Contrast = 0
        GlowColor.Saturation = 0
        GlowColor.TintColor = Color3.new(1, 1, 1)
    end

    if VFX.TargetPulse then
        local target = GetMurderer()
        TargetPulse.Adornee = target and target.Character or nil
        TargetPulse.Enabled = target ~= nil and IsAlive(target)
    else
        TargetPulse.Enabled = false
    end
end))

--========================================================--
--                    ENVIRONMENT V2                      --
--========================================================--

local EnvironmentBackup = nil
local EnvironmentAtmosphere = nil

local function SaveEnvironmentV2()
    if EnvironmentBackup then return end
    EnvironmentBackup = {
        ClockTime = Lighting.ClockTime,
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ColorShiftTop = Lighting.ColorShift_Top,
        ColorShiftBottom = Lighting.ColorShift_Bottom,
        FogColor = Lighting.FogColor,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        Exposure = Lighting.ExposureCompensation,
    }
end

local function ApplyEnvironmentV2()
    SaveEnvironmentV2()
    if not EnvironmentAtmosphere or not EnvironmentAtmosphere.Parent then
        EnvironmentAtmosphere = Instance.new("Atmosphere")
        EnvironmentAtmosphere.Name = "Nebula_Atmosphere"
        EnvironmentAtmosphere.Parent = Lighting
    end

    local c = VFXColor(Color3.fromRGB(100, 55, 165))
    EnvironmentAtmosphere.Color = c
    EnvironmentAtmosphere.Decay = Color3.fromRGB(45, 20, 75)
    EnvironmentAtmosphere.Density = 0.34
    EnvironmentAtmosphere.Haze = 1.15
    EnvironmentAtmosphere.Glare = 0.15
    EnvironmentAtmosphere.Offset = 0.05

    Lighting.ClockTime = 0.2
    Lighting.Brightness = 1.6
    Lighting.Ambient = Color3.fromRGB(35, 20, 55)
    Lighting.OutdoorAmbient = Color3.fromRGB(50, 30, 75)
    Lighting.ColorShift_Top = Color3.fromRGB(65, 30, 95)
    Lighting.ColorShift_Bottom = Color3.fromRGB(25, 10, 40)
    Lighting.FogColor = Color3.fromRGB(55, 28, 80)
    Lighting.FogStart = 18
    Lighting.FogEnd = 320
    Lighting.ExposureCompensation = 0.15
end

local function RestoreEnvironmentV2()
    if EnvironmentBackup then
        pcall(function()
            Lighting.ClockTime = EnvironmentBackup.ClockTime
            Lighting.Brightness = EnvironmentBackup.Brightness
            Lighting.Ambient = EnvironmentBackup.Ambient
            Lighting.OutdoorAmbient = EnvironmentBackup.OutdoorAmbient
            Lighting.ColorShift_Top = EnvironmentBackup.ColorShiftTop
            Lighting.ColorShift_Bottom = EnvironmentBackup.ColorShiftBottom
            Lighting.FogColor = EnvironmentBackup.FogColor
            Lighting.FogStart = EnvironmentBackup.FogStart
            Lighting.FogEnd = EnvironmentBackup.FogEnd
            Lighting.ExposureCompensation = EnvironmentBackup.Exposure
        end)
    end
    VFXDestroy(EnvironmentAtmosphere)
    EnvironmentAtmosphere = nil
    EnvironmentBackup = nil
end

--========================================================--
--                       NEW UI                           --
--========================================================--

local AdvancedSection = EffectsTab:AddSection("Nebula VFX 2.0")

AdvancedSection:AddToggle({
    Name = "Aura V2",
    Default = false,
    Callback = function(v) VFX.Aura = v; BuildAdvancedVFX() end,
})
AdvancedSection:AddSlider({
    Name = "Aura Radius",
    Min = 2,
    Max = 7,
    Default = 3.5,
    Callback = function(v) VFX.AuraRadius = v; if VFX.Aura then BuildAdvancedVFX() end end,
})
AdvancedSection:AddToggle({
    Name = "Orbit V2",
    Default = false,
    Callback = function(v) VFX.Orbit = v; BuildAdvancedVFX() end,
})
AdvancedSection:AddSlider({
    Name = "Orbit Radius",
    Min = 2,
    Max = 7,
    Default = 3.2,
    Callback = function(v) VFX.OrbitRadius = v end,
})
AdvancedSection:AddToggle({
    Name = "Wings V2",
    Default = false,
    Callback = function(v) VFX.Wings = v; BuildAdvancedVFX() end,
})
AdvancedSection:AddToggle({
    Name = "Body Particles V2",
    Default = false,
    Callback = function(v) VFX.BodyParticles = v; BuildAdvancedVFX() end,
})
AdvancedSection:AddToggle({
    Name = "Character Trail V2",
    Default = false,
    Callback = function(v) VFX.Trail = v; BuildAdvancedVFX() end,
})
AdvancedSection:AddToggle({
    Name = "Footstep FX V2",
    Default = false,
    Callback = function(v) VFX.Footsteps = v end,
})
AdvancedSection:AddToggle({
    Name = "Rainbow VFX",
    Default = false,
    Callback = function(v) VFX.Rainbow = v end,
})
AdvancedSection:AddToggle({
    Name = "Target Pulse",
    Default = false,
    Callback = function(v) VFX.TargetPulse = v end,
})
AdvancedSection:AddToggle({
    Name = "Energy Core",
    Default = false,
    Callback = function(v) VFX.EnergyCore = v; BuildAdvancedVFX() end,
})
AdvancedSection:AddToggle({
    Name = "Shockwave Rings",
    Default = false,
    Callback = function(v) VFX.Shockwaves = v; BuildAdvancedVFX() end,
})
AdvancedSection:AddToggle({
    Name = "Ground Sigil",
    Default = false,
    Callback = function(v) VFX.GroundSigil = v; BuildAdvancedVFX() end,
})
AdvancedSection:AddToggle({
    Name = "Floating Orbs",
    Default = false,
    Callback = function(v) VFX.FloatingOrbs = v; BuildAdvancedVFX() end,
})
AdvancedSection:AddToggle({
    Name = "Screen Glow",
    Default = false,
    Callback = function(v) VFX.ScreenGlow = v end,
})
AdvancedSection:AddToggle({
    Name = "Aim FOV Circle",
    Default = false,
    Callback = function(v) VFX.FOVCircle = v end,
})
AdvancedSection:AddSlider({
    Name = "FOV Circle Radius",
    Min = 30,
    Max = 300,
    Default = 120,
    Callback = function(v) VFX.FOVRadius = v end,
})

AdvancedSection:AddToggle({
    Name = "Nebula Environment",
    Default = false,
    Callback = function(v)
        VFX.Environment = v
        if v then ApplyEnvironmentV2() else RestoreEnvironmentV2() end
    end,
})
AdvancedSection:AddButton({
    Name = "Purple Night Preset",
    Callback = function()
        VFX.Environment = true
        ApplyEnvironmentV2()
    end,
})
AdvancedSection:AddButton({
    Name = "Restore Lighting",
    Callback = function()
        VFX.Environment = false
        RestoreEnvironmentV2()
    end,
})

local SkySection = EffectsTab:AddSection("Sky Particles")
SkySection:AddToggle({
    Name = "Sky Particle Field",
    Default = false,
    Callback = function(v) VFX.SkyParticles = v end,
})
SkySection:AddSlider({
    Name = "Sky Particle Count",
    Min = 8,
    Max = 50,
    Default = 28,
    Callback = function(v) VFX.SkyCount = v end,
})

--========================================================--
--                    SKY PARTICLE LOOP                   --
--========================================================--

local function RebuildSkyParticles()
    for _, part in ipairs(SkyParticles) do VFXDestroy(part) end
    table.clear(SkyParticles)
    if not VFX.SkyParticles then return end

    local folder = Instance.new("Folder")
    folder.Name = "NebulaSkyParticles"
    folder.Parent = workspace
    VFXObjects.Sky = folder

    for i = 1, VFX.SkyCount do
        local p = VFXBall(folder, "SkyNode_" .. i, 0.08 + (i % 3) * 0.035, VFX.ParticleColor)
        SkyParticles[i] = p
    end
end

VFXTrackConnection(RunService.RenderStepped:Connect(function()
    if VFX.SkyParticles then
        if not VFXObjects.Sky or not VFXObjects.Sky.Parent or #SkyParticles ~= VFX.SkyCount then
            RebuildSkyParticles()
        end
        local camera = workspace.CurrentCamera
        if camera then
            local now = os.clock()
            for i, part in ipairs(SkyParticles) do
                local angle = now * (0.08 + i * 0.002) + i * 0.75
                local radius = 16 + (i % 7) * 3
                local height = math.sin(now * 0.55 + i) * 3 + ((i % 9) - 4) * 1.6
                part.CFrame = CFrame.new(camera.CFrame.Position)
                    * CFrame.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
                part.Color = VFXColor(VFX.ParticleColor, i / math.max(1, VFX.SkyCount))
            end
        end
    elseif VFXObjects.Sky then
        VFXDestroy(VFXObjects.Sky)
        VFXObjects.Sky = nil
        table.clear(SkyParticles)
    end
end))

--========================================================--
--                    ADVANCED FX LOOP                   --
--========================================================--

VFXTrackConnection(RunService.RenderStepped:Connect(function()
    UpdateAdvancedVFX()
    UpdateFootstepsV2()
end))

VFXTrackConnection(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.35)
    BuildAdvancedVFX()
    if VFX.Environment then ApplyEnvironmentV2() end
end))

--========================================================--
--                    LOCAL INVISIBILITY                  --
--========================================================--

local OriginalVisibility = {}

local function SaveVisibility(object)
    if OriginalVisibility[object] ~= nil then
        return
    end

    if object:IsA("BasePart") then
        OriginalVisibility[object] = {
            Kind = "BasePart",
            Value = object.LocalTransparencyModifier
        }
    elseif object:IsA("Decal") or object:IsA("Texture") then
        OriginalVisibility[object] = {
            Kind = "Decal",
            Value = object.Transparency
        }
    elseif object:IsA("ParticleEmitter") or object:IsA("Trail") then
        OriginalVisibility[object] = {
            Kind = "Emitter",
            Value = object.Enabled
        }
    end
end

local function ApplyInvisibility(character)
    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        SaveVisibility(object)

        local data = OriginalVisibility[object]
        if data then
            if data.Kind == "BasePart" then
                object.LocalTransparencyModifier = 1
            elseif data.Kind == "Decal" then
                object.Transparency = 1
            elseif data.Kind == "Emitter" then
                object.Enabled = false
            end
        end
    end
end

local function RestoreVisibility()
    for object, data in pairs(OriginalVisibility) do
        if object and object.Parent then
            pcall(function()
                if data.Kind == "BasePart" then
                    object.LocalTransparencyModifier = data.Value
                elseif data.Kind == "Decal" then
                    object.Transparency = data.Value
                elseif data.Kind == "Emitter" then
                    object.Enabled = data.Value
                end
            end)
        end
    end

    table.clear(OriginalVisibility)
end

TrackConnection(RunService.Heartbeat:Connect(function()
    local character = GetCharacter()

    if State.Invisibility then
        ApplyInvisibility(character)
    elseif next(OriginalVisibility) then
        RestoreVisibility()
    end
end))

--========================================================--
--                        PLAYERS                         --
--========================================================--

local PlayerSection2 = PlayersTab:AddSection("Player Utilities")

PlayerSection2:AddTextbox({
    Name = "Player Name",
    Placeholder = "DisplayName / Username",
    Callback = function(value)
        State.FlingTarget = value
    end
})

PlayerSection2:AddButton({
    Name = "Spectate Player",
    Callback = function()
        local player = Players:FindFirstChild(State.FlingTarget)
        local humanoid = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            Camera.CameraSubject = humanoid
        end
    end
})

PlayerSection2:AddButton({
    Name = "Reset Camera",
    Callback = function()
        local humanoid = GetHumanoid()
        if humanoid then
            Camera.CameraSubject = humanoid
        end
    end
})

--========================================================--
--                         MISC                           --
--========================================================--

local MiscSection = MiscTab:AddSection("Utilities")

MiscSection:AddToggle({
    Name = "Anti-Fling",
    Default = false,
    Callback = function(v)
        State.AntiFling = v
    end
})

MiscSection:AddToggle({
    Name = "Auto Farm Coins",
    Default = false,
    Callback = function(v)
        State.AutoFarm = v
    end
})

MiscSection:AddToggle({
    Name = "Jerk Off Tool",
    Default = false,
    Callback = function(v)
        State.JerkOff = v
    end
})

MiscSection:AddToggle({
    Name = "Fake Death",
    Default = false,
    Callback = function(v)
        State.FakeDeath = v
    end
})

--========================================================--
--                     JERK OFF TOOL                     --
--========================================================--

local JerkTool
local JerkTrack
local JerkConnections = {}

local function DestroyJerkTool()
    for _, c in ipairs(JerkConnections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(JerkConnections)

    if JerkTrack then
        pcall(function()
            JerkTrack:Stop()
            JerkTrack:Destroy()
        end)
        JerkTrack = nil
    end

    SafeDestroy(JerkTool)
    JerkTool = nil
end

local function CreateJerkTool()
    DestroyJerkTool()

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local humanoid = GetHumanoid()

    if not backpack or not humanoid then
        return
    end

    local tool = Instance.new("Tool")
    tool.Name = "Jerk Off"
    tool.ToolTip = "Jerk Off"
    tool.RequiresHandle = false
    tool.Parent = backpack
    JerkTool = tool

    local active = false

    table.insert(JerkConnections, tool.Equipped:Connect(function()
        active = true
    end))

    table.insert(JerkConnections, tool.Unequipped:Connect(function()
        active = false
        if JerkTrack then
            JerkTrack:Stop()
            JerkTrack = nil
        end
    end))

    task.spawn(function()
        while tool.Parent and State.JerkOff do
            task.wait()

            if not active then
                continue
            end

            local character = GetCharacter()
            local currentHumanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not currentHumanoid then
                continue
            end

            if not JerkTrack then
                local anim = Instance.new("Animation")
                anim.AnimationId =
                    currentHumanoid.RigType == Enum.HumanoidRigType.R15
                    and "rbxassetid://698251653"
                    or "rbxassetid://72042024"

                local ok, track = pcall(function()
                    return currentHumanoid:LoadAnimation(anim)
                end)

                if ok then
                    JerkTrack = track
                end
            end

            if JerkTrack then
                pcall(function()
                    JerkTrack:Play()
                    JerkTrack:AdjustSpeed(
                        currentHumanoid.RigType == Enum.HumanoidRigType.R15
                        and 0.7
                        or 0.65
                    )
                    JerkTrack.TimePosition = 0.6
                end)

                task.wait(0.05)

                if JerkTrack and not active then
                    pcall(function()
                        JerkTrack:Stop()
                    end)
                    JerkTrack = nil
                end
            end
        end
    end)
end

TrackConnection(RunService.Heartbeat:Connect(function()
    if State.JerkOff then
        if not JerkTool then
            CreateJerkTool()
        end
    elseif JerkTool then
        DestroyJerkTool()
    end
end))

--========================================================--
--                      MOBILE UI                         --
--========================================================--

local MobileSection = MiscTab:AddSection("Mobile Controls")

MobileSection:AddToggle({
    Name = "Mobile Shoot Button",
    Default = true,
    Callback = function(v)
        State.MobileShoot = v
        UpdateMobileButtons()
    end
})

MobileSection:AddToggle({
    Name = "Mobile Aura Button",
    Default = true,
    Callback = function(v)
        State.MobileAura = v
        UpdateMobileButtons()
    end
})

MobileSection:AddToggle({
    Name = "Mobile Fly Button",
    Default = true,
    Callback = function(v)
        State.MobileFly = v
        UpdateMobileButtons()
    end
})

MobileSection:AddToggle({
    Name = "Mobile ESP Button",
    Default = true,
    Callback = function(v)
        State.MobileESP = v
        UpdateMobileButtons()
    end
})

MobileSection:AddToggle({
    Name = "Mobile VFX Button",
    Default = true,
    Callback = function(v)
        State.MobileVFX = v
        UpdateMobileButtons()
    end
})

MobileSection:AddToggle({
    Name = "Edit Mobile Layout",
    Default = false,
    Callback = function(v)
        State.MobileEdit = v
        UpdateMobileButtons()
    end
})

local MobileGui = Instance.new("ScreenGui")
MobileGui.Name = "Nebula_MM2_MobileControls"
MobileGui.ResetOnSpawn = false
MobileGui.IgnoreGuiInset = true
MobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MobileGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
TrackInstance(MobileGui)

local function TryAddMobileButton(options)
    if not UserInputService.TouchEnabled then
        return nil
    end

    local button = Instance.new("TextButton")
    button.Name = tostring(options.Name or "NebulaButton")
    button.Size = options.Size or UDim2.fromOffset(82, 52)
    button.Position = options.Position or UDim2.new(1, -100, 1, -210)
    button.AnchorPoint = Vector2.new(0, 0)
    button.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    button.BackgroundTransparency = 0.12
    button.BorderSizePixel = 0
    button.Text = tostring(options.Text or options.Name or "BUTTON")
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 15
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Visible = options.Visible ~= false
    button.Parent = MobileGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Transparency = 0.35
    stroke.Parent = button

    local callback = options.Callback
    TrackConnection(button.Activated:Connect(function()
        if State.MobileEdit then
            return
        end
        if callback then
            pcall(callback)
        end
    end))

    local dragging = false
    local dragStart
    local startPos
    TrackConnection(button.InputBegan:Connect(function(input)
        if not State.MobileEdit then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = button.Position
        end
    end))
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position - dragStart
        button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end))
    TrackConnection(button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    table.insert(MobileButtons, button)
    return button
end

TryAddMobileButton({
    Name = "Shoot",
    Text = "SHOOT",
    Position = UDim2.new(1, -190, 1, -150),
    Callback = function()
        local character = GetCharacter()
        local tool = character and character:FindFirstChild("Gun")
        if tool and tool:IsA("Tool") then
            pcall(function() tool:Activate() end)
        end
    end
})

TryAddMobileButton({
    Name = "Aura",
    Text = "AURA",
    Position = UDim2.new(1, -100, 1, -150),
    Callback = function()
        State.KillAura = not State.KillAura
    end
})

TryAddMobileButton({
    Name = "Fly",
    Text = "FLY",
    Position = UDim2.new(1, -100, 1, -90),
    Callback = function()
        State.Fly = not State.Fly
    end
})

TryAddMobileButton({
    Name = "ESP",
    Text = "ESP",
    Position = UDim2.new(1, -190, 1, -90),
    Callback = function()
        State.ESP = not State.ESP
    end
})

TryAddMobileButton({
    Name = "VFX",
    Text = "VFX",
    Position = UDim2.new(1, -280, 1, -90),
    Callback = function()
        VFX.ScreenGlow = not VFX.ScreenGlow
    end
})

local function UpdateMobileButtons()
    if not MobileGui then
        return
    end

    local enabled = UserInputService.TouchEnabled
    for _, button in ipairs(MobileButtons) do
        if button and button.Parent then
            if button.Name == "Shoot" then
                button.Visible = enabled and State.MobileShoot
            elseif button.Name == "Aura" then
                button.Visible = enabled and State.MobileAura
            elseif button.Name == "Fly" then
                button.Visible = enabled and State.MobileFly
            elseif button.Name == "ESP" then
                button.Visible = enabled and State.MobileESP
            elseif button.Name == "VFX" then
                button.Visible = enabled and State.MobileVFX
            end
            button.Active = not State.MobileEdit
            button.BackgroundTransparency = State.MobileEdit and 0.35 or 0.12
        end
    end
end

TrackConnection(RunService.RenderStepped:Connect(UpdateMobileButtons))

--========================================================--
--                 MOBILE FLY TOUCH INPUT                 --
--========================================================--

local MobileFlyDirection = Vector3.zero
local MobileFlyTouch = nil
local MobileFlyStart = nil

TrackConnection(UserInputService.TouchStarted:Connect(function(touch, processed)
    if processed or not State.Fly then
        return
    end

    -- A simple virtual-stick region on the left side.
    if touch.Position.X < Camera.ViewportSize.X * 0.45
        and touch.Position.Y > Camera.ViewportSize.Y * 0.45 then

        MobileFlyTouch = touch
        MobileFlyStart = touch.Position
    end
end))

TrackConnection(UserInputService.TouchMoved:Connect(function(touch)
    if touch ~= MobileFlyTouch or not MobileFlyStart then
        return
    end

    local delta = touch.Position - MobileFlyStart
    local x = math.clamp(delta.X / 80, -1, 1)
    local y = math.clamp(delta.Y / 80, -1, 1)

    local forward = Camera.CFrame.LookVector * -y
    local right = Camera.CFrame.RightVector * x

    MobileFlyDirection = forward + right

    if MobileFlyDirection.Magnitude > 1 then
        MobileFlyDirection = MobileFlyDirection.Unit
    end
end))

TrackConnection(UserInputService.TouchEnded:Connect(function(touch)
    if touch == MobileFlyTouch then
        MobileFlyTouch = nil
        MobileFlyStart = nil
        MobileFlyDirection = Vector3.zero
    end
end))

local oldGetKeyboardFlyDirection = GetKeyboardFlyDirection

GetKeyboardFlyDirection = function()
    local direction = oldGetKeyboardFlyDirection()

    if UserInputService.TouchEnabled and MobileFlyDirection.Magnitude > 0 then
        direction += MobileFlyDirection
    end

    return direction
end

--========================================================--
--                     ANTI FLING                         --
--========================================================--

TrackConnection(RunService.Stepped:Connect(function()
    if not State.AntiFling then
        return
    end

    local character = GetCharacter()
    if not character then
        return
    end

    -- Do not rewrite other players' collision. Keep the protection local:
    -- clear excessive local velocity on our own character.
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                if part.AssemblyLinearVelocity.Magnitude > 120 then
                    part.AssemblyLinearVelocity = Vector3.zero
                end
                if part.AssemblyAngularVelocity.Magnitude > 120 then
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end)
        end
    end
end))

--========================================================--
--                     AUTO FARM                          --
--========================================================--

task.spawn(function()
    while true do
        task.wait(0.15)

        if not State.AutoFarm then
            continue
        end

        local root = GetRoot()
        if not root then
            continue
        end

        local container =
            workspace:FindFirstChild("Normal")
            or workspace:FindFirstChild("CoinContainer", true)

        if not container then
            continue
        end

        for _, coin in ipairs(container:GetDescendants()) do
            if not State.AutoFarm then
                break
            end

            if coin:IsA("BasePart")
                and (coin.Name == "Coin_Container" or coin.Name == "Coin_Server") then

                root.CFrame = coin.CFrame + Vector3.new(0, 2, 0)
                task.wait(0.25)
            end
        end
    end
end)

--========================================================--
--                    CHARACTER LIFECYCLE                 --
--========================================================--

local function ApplyCharacterState(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then
        return
    end

    task.wait(0.2)

    humanoid.WalkSpeed = State.Speed
    humanoid.JumpPower = State.JumpPower

    if State.Invisibility then
        ApplyInvisibility(character)
    end

    BuildEffects()

    if State.Fly then
        task.wait(0.25)
        StartFly()
    end
end

TrackConnection(LocalPlayer.CharacterAdded:Connect(function(character)
    CacheNoclipParts(character)
    ClearCharacterEffects()
    RestoreVisibility()
    StopFly()

    task.spawn(function()
        ApplyCharacterState(character)
    end)
end))

--========================================================--
--                    FAKE DEATH                         --
--========================================================--

local function DoFakeDeath()
    local humanoid = GetHumanoid()
    if not humanoid then
        return
    end

    -- Client-side visual fake death only; does not force server death.
    local oldCamera = Camera.CameraSubject
    humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)

    task.delay(1.2, function()
        if humanoid and humanoid.Parent and humanoid.Health > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            Camera.CameraSubject = oldCamera or humanoid
        end
    end)
end

TrackConnection(RunService.Heartbeat:Connect(function()
    if State.FakeDeath then
        State.FakeDeath = false
        DoFakeDeath()
    end
end))

--========================================================--
--                     UNLOAD CLEANUP                     --
--========================================================--

local function FullCleanup()
    VFX.FOVCircle = false
    VFX.TargetPulse = false
    VFX.Shockwaves = false
    VFX.EnergyCore = false
    VFX.GroundSigil = false
    VFX.FloatingOrbs = false
    VFX.ScreenGlow = false
    VFX.SkyParticles = false
    VFX.Environment = false
    RestoreEnvironmentV2()
    VFXDisconnectAll()
    DestroyAdvancedVFX()
    VFXDestroy(TargetPulse)
    VFXDestroy(FOVGui)

    State.Fly = false
    State.AutoFarm = false
    State.JerkOff = false

    StopFly()
    DestroyJerkTool()
    ClearCharacterEffects()
    RestoreVisibility()
    RestoreNoclip()

    for player in pairs(ESPObjects) do
        RemoveESP(player)
    end

    for _, button in ipairs(MobileButtons) do
        SafeDestroy(button)
    end
    table.clear(MobileButtons)

    SafeDestroy(AimTargetHighlight)
    SafeDestroy(ESPOverlay)
    SafeDestroy(DropGunHighlight)
    SafeDestroy(DropGunTag)

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(Connections)

    for _, instance in ipairs(Instances) do
        if instance and instance.Parent then
            pcall(function()
                instance:Destroy()
            end)
        end
    end
    table.clear(Instances)
end

-- Nebula exposes Window:Unload() without a cleanup callback.
-- Wrap the real method so ESP/VFX/mobile objects are always cleaned first.
do
    local originalUnload = Window.Unload
    if type(originalUnload) == "function" then
        function Window:Unload(...)
            pcall(FullCleanup)
            return originalUnload(self, ...)
        end
    end
end

Window:Notify({
    Title = "Nebula Hub",
    Content = "MM2 v5.6 loaded — expanded ESP, HUD and VFX.",
    Duration = 5
})
