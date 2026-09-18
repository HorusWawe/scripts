--[[
    Nebula UI v5.0
    Universal Roblox/Luau UI Framework
    Built on top of Nebula UI v3 - visuals unchanged, architecture layered on top.

    Changelog v4 (architecture, per the v4 plan):
    - Unified Component/Element API: every input element (Toggle, Slider, Button,
      Dropdown, MultiDropdown, ColorPicker, Textbox, Keybind, Label, Paragraph)
      now exposes the same base methods: Set/Get (where meaningful), SetVisible,
      SetDisabled, SetName, Destroy - on top of whatever custom methods it had.
    - Element IDs: options.ID = "GodMode" registers the element so it can be
      fetched later with Window:GetElement(id) / Window:SetValue(id, value).
    - State Manager: Window:SaveState() / Window:LoadState() / Window:GetState()
      / Window:SetState(data) - works over every ID'd element automatically.
    - Plugin API: Library:RegisterPlugin({Name, OnLoad, OnUnload}). Every Window
      loads all registered plugins on creation and unloads them on Window:Unload().
    - Unified Window:Track(connection): all connections (including the ones that
      used to connect directly) now flow through the same tracked table so
      Window:Unload() cleans everything up predictably.
    - Element lifecycle hooks: Element:_ApplyTheme() (extension point for custom
      elements/plugins) alongside the existing per-property theme binding.
    - Responsive layout: Window { Responsive = true } detects viewport size,
      resizes the window, collapses the sidebar into a toggle-able overlay on
      small screens, and reflows any Layout Engine groups.
    - Nebula Layout Engine: Tab:AddGroup({ Columns = 2 }) returns a Group with
      the same AddToggle/AddSlider/AddButton/... methods as a Tab. Elements are
      distributed round-robin across N columns on desktop, and automatically
      collapse to a single column on small screens - no user code changes needed.

    Nothing in v3's visuals (theming, animations, notifications, color picker,
    dropdowns, search, mobile button) was rewritten - v4 wraps and extends it.
]]

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    error("[Nebula UI] LocalPlayer is not available.")
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------
-- DUPLICATE CLEANUP
--------------------------------------------------

local GUI_NAME = "__NebulaUI_v5"
local ACTIVE_WINDOW_KEY = "__NebulaUI_v5_ACTIVE_WINDOW"

local previousWindow = rawget(_G, ACTIVE_WINDOW_KEY)
if previousWindow and type(previousWindow.Unload) == "function" then
    pcall(function()
        previousWindow:Unload(true)
    end)
end

rawset(_G, ACTIVE_WINDOW_KEY, nil)

for _, child in ipairs(PlayerGui:GetChildren()) do
    if child.Name == GUI_NAME then
        pcall(function()
            child:Destroy()
        end)
    end
end

--------------------------------------------------
-- LIBRARY
--------------------------------------------------

local Library = {}

Library.Version = "5.0.0"
Library.Name = "Nebula UI"
Library.Plugins = {}

--------------------------------------------------
-- PLUGIN API
--------------------------------------------------

-- Library:RegisterPlugin({
--     Name = "MyPlugin",
--     OnLoad = function(Window) end,
--     OnUnload = function(Window) end,
-- })
function Library:RegisterPlugin(plugin)
    if type(plugin) ~= "table" or type(plugin.Name) ~= "string" then
        warn("[Nebula UI] RegisterPlugin requires a table with a Name field.")
        return
    end

    table.insert(Library.Plugins, plugin)
    return plugin
end

--------------------------------------------------
-- THEMES
--------------------------------------------------

Library.Themes = {

    Midnight = {
        Background = Color3.fromRGB(13, 14, 19),
        Secondary = Color3.fromRGB(18, 19, 26),
        Tertiary = Color3.fromRGB(25, 26, 35),
        Hover = Color3.fromRGB(33, 35, 46),

        Accent = Color3.fromRGB(124, 92, 255),
        AccentDark = Color3.fromRGB(92, 64, 220),

        Text = Color3.fromRGB(245, 245, 248),
        SubText = Color3.fromRGB(150, 152, 166),

        Border = Color3.fromRGB(40, 42, 54),
        BorderLight = Color3.fromRGB(58, 60, 75),

        Success = Color3.fromRGB(86, 205, 128),
        Warning = Color3.fromRGB(240, 183, 75),
        Error = Color3.fromRGB(235, 87, 96),
        Info = Color3.fromRGB(96, 165, 250)
    },

    Ocean = {
        Background = Color3.fromRGB(9, 16, 23),
        Secondary = Color3.fromRGB(13, 24, 33),
        Tertiary = Color3.fromRGB(18, 33, 44),
        Hover = Color3.fromRGB(25, 45, 59),

        Accent = Color3.fromRGB(56, 189, 248),
        AccentDark = Color3.fromRGB(14, 116, 178),

        Text = Color3.fromRGB(240, 248, 255),
        SubText = Color3.fromRGB(148, 168, 184),

        Border = Color3.fromRGB(32, 53, 66),
        BorderLight = Color3.fromRGB(48, 76, 92),

        Success = Color3.fromRGB(86, 205, 130),
        Warning = Color3.fromRGB(240, 183, 75),
        Error = Color3.fromRGB(235, 87, 96),
        Info = Color3.fromRGB(96, 165, 250)
    },

    Crimson = {
        Background = Color3.fromRGB(19, 11, 14),
        Secondary = Color3.fromRGB(27, 15, 19),
        Tertiary = Color3.fromRGB(37, 20, 25),
        Hover = Color3.fromRGB(50, 26, 32),

        Accent = Color3.fromRGB(244, 63, 94),
        AccentDark = Color3.fromRGB(190, 35, 60),

        Text = Color3.fromRGB(250, 242, 244),
        SubText = Color3.fromRGB(172, 143, 150),

        Border = Color3.fromRGB(54, 31, 38),
        BorderLight = Color3.fromRGB(80, 45, 55),

        Success = Color3.fromRGB(86, 205, 128),
        Warning = Color3.fromRGB(240, 183, 75),
        Error = Color3.fromRGB(240, 80, 90),
        Info = Color3.fromRGB(96, 165, 250)
    },

    Forest = {
        Background = Color3.fromRGB(10, 17, 13),
        Secondary = Color3.fromRGB(14, 24, 18),
        Tertiary = Color3.fromRGB(20, 33, 24),
        Hover = Color3.fromRGB(26, 44, 32),

        Accent = Color3.fromRGB(74, 222, 128),
        AccentDark = Color3.fromRGB(34, 160, 84),

        Text = Color3.fromRGB(240, 248, 242),
        SubText = Color3.fromRGB(148, 168, 152),

        Border = Color3.fromRGB(32, 53, 40),
        BorderLight = Color3.fromRGB(48, 78, 58),

        Success = Color3.fromRGB(86, 205, 128),
        Warning = Color3.fromRGB(240, 183, 75),
        Error = Color3.fromRGB(235, 87, 96),
        Info = Color3.fromRGB(96, 165, 250)
    },

    Purple = {
        Background = Color3.fromRGB(16, 11, 23),
        Secondary = Color3.fromRGB(22, 16, 32),
        Tertiary = Color3.fromRGB(31, 21, 44),
        Hover = Color3.fromRGB(42, 28, 56),

        Accent = Color3.fromRGB(192, 132, 252),
        AccentDark = Color3.fromRGB(140, 70, 220),

        Text = Color3.fromRGB(247, 242, 250),
        SubText = Color3.fromRGB(164, 145, 180),

        Border = Color3.fromRGB(48, 33, 62),
        BorderLight = Color3.fromRGB(70, 48, 90),

        Success = Color3.fromRGB(86, 205, 128),
        Warning = Color3.fromRGB(240, 183, 75),
        Error = Color3.fromRGB(235, 87, 96),
        Info = Color3.fromRGB(96, 165, 250)
    },

    Nebula = {
        Background = Color3.fromRGB(14, 9, 22),
        Secondary = Color3.fromRGB(21, 13, 34),
        Tertiary = Color3.fromRGB(30, 19, 47),
        Hover = Color3.fromRGB(45, 28, 68),

        Accent = Color3.fromRGB(168, 85, 247),
        AccentDark = Color3.fromRGB(126, 34, 206),

        Text = Color3.fromRGB(249, 245, 255),
        SubText = Color3.fromRGB(171, 153, 190),

        Border = Color3.fromRGB(52, 33, 69),
        BorderLight = Color3.fromRGB(78, 49, 101),

        Success = Color3.fromRGB(86, 205, 128),
        Warning = Color3.fromRGB(240, 183, 75),
        Error = Color3.fromRGB(235, 87, 96),
        Info = Color3.fromRGB(129, 140, 248)
    },

    Light = {
        Background = Color3.fromRGB(240, 241, 245),
        Secondary = Color3.fromRGB(250, 250, 252),
        Tertiary = Color3.fromRGB(231, 232, 238),
        Hover = Color3.fromRGB(223, 224, 232),

        Accent = Color3.fromRGB(99, 102, 241),
        AccentDark = Color3.fromRGB(67, 70, 200),

        Text = Color3.fromRGB(28, 28, 36),
        SubText = Color3.fromRGB(110, 112, 124),

        Border = Color3.fromRGB(213, 214, 222),
        BorderLight = Color3.fromRGB(228, 229, 236),

        Success = Color3.fromRGB(34, 160, 90),
        Warning = Color3.fromRGB(210, 145, 40),
        Error = Color3.fromRGB(210, 60, 70),
        Info = Color3.fromRGB(59, 130, 246)
    }
}

Library.CurrentTheme = Library.Themes.Purple

--------------------------------------------------
-- STATE (low-level reactive key/value store, unchanged from v3)
--------------------------------------------------

function Library:CreateState()
    local State = {
        Values = {},
        Connections = {}
    }

    function State:Get(key)
        return self.Values[key]
    end

    function State:Set(key, value)
        self.Values[key] = value

        if self.Connections[key] then
            for _, callback in ipairs(self.Connections[key]) do
                task.spawn(callback, value)
            end
        end
    end

    function State:Bind(key, callback)
        self.Connections[key] = self.Connections[key] or {}
        table.insert(self.Connections[key], callback)

        return {
            Disconnect = function()
                local list = self.Connections[key]
                if not list then return end

                for i, fn in ipairs(list) do
                    if fn == callback then
                        table.remove(list, i)
                        break
                    end
                end
            end
        }
    end

    function State:Destroy()
        table.clear(self.Values)
        table.clear(self.Connections)
    end

    return State
end

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local CURRENT_APPEARANCE = nil

local function Tween(instance, properties, duration, style, direction)
    if not instance then return nil end
    local base = tonumber(duration) or 0.25
    if CURRENT_APPEARANCE then
        if CURRENT_APPEARANCE.ReducedMotion then base = 0 else base = base / math.max(0.05, tonumber(CURRENT_APPEARANCE.AnimationSpeed) or 1) end
    end
    if base <= 0 then
        for property, value in pairs(properties or {}) do pcall(function() instance[property] = value end) end
        return nil
    end
    local info = TweenInfo.new(base, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)

    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

local function Corner(parent, radius, keepRadius)
    local corner = Instance.new("UICorner")
    if keepRadius then corner:SetAttribute("NebulaKeepRadius", true) end
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function Stroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency or 0.55
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function Padding(parent, left, right, top, bottom)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.Parent = parent
    return p
end

local function CreateText(parent, text, size, font)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextSize = size or 14
    label.Font = font or Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Parent = parent
    return label
end

local function Ripple(button)
    local ripple = Instance.new("Frame")
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.75
    ripple.BorderSizePixel = 0
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.Position = UDim2.fromScale(0.5, 0.5)
    ripple.Size = UDim2.fromScale(0, 0)
    ripple.ZIndex = button.ZIndex + 1
    ripple.Parent = button

    Corner(ripple, 999)

    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.2

    Tween(ripple, { Size = UDim2.fromOffset(maxSize, maxSize), BackgroundTransparency = 1 }, 0.45)

    task.delay(0.5, function()
        if ripple then
            ripple:Destroy()
        end
    end)
end

--------------------------------------------------
-- WINDOW
--------------------------------------------------

function Library:CreateWindow(options)

    options = options or {}

    local Window = {}

    Window.Title = options.Title or options.Name or "Nebula UI"
    Window.Subtitle = options.Subtitle or "Universal Interface"
    Window.Size = options.Size or UDim2.fromOffset(720, 500)
    Window.ToggleKey = options.ToggleKey or Enum.KeyCode.RightControl -- default: Right Ctrl

    Window.Theme = self.CurrentTheme

    Window._connections = {}
    Window._themeBinds = {}
    Window.Elements = {}
    Window.Tabs = {}

    -- v4: unified element registry (every element created through a Tab or a
    -- Group ends up in here, whether or not it has an ID).
    Window.AllElements = {}
    Window.ElementsByID = {}
    Window._Groups = {}

    Window.Destroyed = false
    Window.Minimized = false
    Window.Appearance = {
        CornerRadius = tonumber(options.CornerRadius) or 12,
        UIScale = tonumber(options.UIScale) or 1,
        TextSize = tonumber(options.TextSize) or 1,
        Transparency = tonumber(options.Transparency) or 0,
        AnimationSpeed = tonumber(options.AnimationSpeed) or 1,
        ReducedMotion = options.ReducedMotion == true,
    }
    Window._baseTextSizes = {}
    Window._OriginalTheme = {}
    for key, value in pairs(self.Themes[self.CurrentTheme] or self.Themes.Nebula or {}) do Window._OriginalTheme[key] = value end
    Window._CustomThemeColors = {}

    Window.State = self:CreateState()
    CURRENT_APPEARANCE = Window.Appearance

    -- v4: Window.Size read before the open-animation section overwrites Main's
    -- Size, so responsive logic and the open animation share one source of truth.
    local finalSize = Window.Size

    --------------------------------------------------
    -- v4: UNIFIED TRACK (every connection in the library flows through this,
    -- so Window:Unload() cleans everything up in one place)
    --------------------------------------------------

    local function Track(connection)
        if connection == nil then
            return nil
        end

        table.insert(Window._connections, connection)
        return connection
    end

    Window.Track = function(a, b)
        local connection = b or a
        return Track(connection)
    end

    --------------------------------------------------
    -- SCREEN GUI
    --------------------------------------------------

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = GUI_NAME
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 10
    ScreenGui.Parent = PlayerGui

    Window.Gui = ScreenGui

    --------------------------------------------------
    -- THEME BINDING (declared early so everything can register)
    --------------------------------------------------

    local function BindTheme(instance, property, themeKey)
        local binding = {
            Instance = instance,
            Property = property,
            Key = themeKey
        }

        table.insert(Window._themeBinds, binding)

        pcall(function()
            instance[property] = Window.Theme[themeKey]
        end)

        return binding
    end

    Window.BindTheme = BindTheme

    --------------------------------------------------
    -- MAIN WINDOW
    --------------------------------------------------

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.Size = Window.Size
    Main.BackgroundColor3 = Window.Theme.Background
    Main.BorderSizePixel = 0
    Main.ZIndex = 2
    Main.Parent = ScreenGui

    Corner(Main, options.CornerRadius or 12)
    local mainStroke = Stroke(Main, Window.Theme.Border, 0.35)

    BindTheme(Main, "BackgroundColor3", "Background")
    BindTheme(mainStroke, "Color", "Border")

    Window.Main = Main

    --------------------------------------------------
    -- SHADOW
    --------------------------------------------------

    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.fromScale(0.5, 0.5)
    Shadow.Size = UDim2.new(1, 60, 1, 60)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6014261993"
    Shadow.ImageTransparency = 0.4
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    Shadow.Parent = Main
    Shadow.ZIndex = -1

    --------------------------------------------------
    -- HEADER
    --------------------------------------------------

    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 70)
    Header.BackgroundColor3 = Window.Theme.Secondary
    Header.BorderSizePixel = 0
    Header.Parent = Main

    local headerGradient = Instance.new("UIGradient")
    headerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 210, 220))
    })
    headerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.97),
        NumberSequenceKeypoint.new(1, 1)
    })
    headerGradient.Parent = Header

    local headerMask = Instance.new("Frame")
    headerMask.BackgroundColor3 = Window.Theme.Secondary
    headerMask.BorderSizePixel = 0
    headerMask.Position = UDim2.new(0, 0, 1, -12)
    headerMask.Size = UDim2.new(1, 0, 0, 12)
    headerMask.Parent = Header

    BindTheme(Header, "BackgroundColor3", "Secondary")
    BindTheme(headerMask, "BackgroundColor3", "Secondary")

    -- accent hairline
    local AccentLine = Instance.new("Frame")
    AccentLine.Size = UDim2.fromOffset(26, 3)
    AccentLine.Position = UDim2.fromOffset(18, 14)
    AccentLine.BackgroundColor3 = Window.Theme.Accent
    AccentLine.BorderSizePixel = 0
    AccentLine.Parent = Header

    Corner(AccentLine, 3)
    BindTheme(AccentLine, "BackgroundColor3", "Accent")

    local TitleLabel = CreateText(Header, Window.Title, 16, Enum.Font.GothamBold)
    TitleLabel.Position = UDim2.fromOffset(18, 21)
    TitleLabel.Size = UDim2.new(1, -166, 0, 24)
    BindTheme(TitleLabel, "TextColor3", "Text")

    local SubtitleLabel = CreateText(Header, Window.Subtitle, 11, Enum.Font.Gotham)
    SubtitleLabel.Position = UDim2.fromOffset(18, 46)
    SubtitleLabel.Size = UDim2.new(1, -166, 0, 16)
    BindTheme(SubtitleLabel, "TextColor3", "SubText")

    --------------------------------------------------
    -- WINDOW CONTROLS (menu / minimize / close)
    --------------------------------------------------

    local function CreateControl(text, xOffset)
        local btn = Instance.new("TextButton")
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 15
        btn.TextColor3 = Window.Theme.SubText
        btn.BackgroundColor3 = Window.Theme.Tertiary
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Size = UDim2.fromOffset(30, 30)
        btn.Position = UDim2.new(1, xOffset, 0, 20)
        btn.Parent = Header

        Corner(btn, 8)
        BindTheme(btn, "TextColor3", "SubText")
        BindTheme(btn, "BackgroundColor3", "Tertiary")

        Track(btn.MouseEnter:Connect(function()
            Tween(btn, { BackgroundTransparency = 0, TextColor3 = Window.Theme.Text }, 0.15)
        end))

        Track(btn.MouseLeave:Connect(function()
            Tween(btn, { BackgroundTransparency = 1, TextColor3 = Window.Theme.SubText }, 0.15)
        end))

        return btn
    end

    -- v4: Menu button, only shown once Responsive collapses the sidebar
    local Menu = CreateControl("=", -114)
    Menu.Visible = false

    local Minimize = CreateControl("\226\128\148", -78)
    local Close = CreateControl("\195\151", -42)

    --------------------------------------------------
    -- BODY (CanvasGroup for smooth fade)
    --------------------------------------------------

    local Body = Instance.new("CanvasGroup")
    Body.Name = "Body"
    Body.Position = UDim2.fromOffset(0, 70)
    Body.Size = UDim2.new(1, 0, 1, -70)
    Body.BackgroundTransparency = 1
    Body.GroupTransparency = 0
    Body.Parent = Main

    --------------------------------------------------
    -- SIDEBAR
    --------------------------------------------------

    local SIDEBAR_WIDTH = math.max(100, tonumber(options.SidebarWidth) or 160)

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0)
    Sidebar.BackgroundTransparency = 1
    Sidebar.ZIndex = 2
    Sidebar.Parent = Body

    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = "TabList"
    TabList.Position = UDim2.fromOffset(10, 12)
    TabList.Size = UDim2.new(1, -20, 1, -24)
    TabList.BackgroundTransparency = 1
    TabList.BorderSizePixel = 0
    TabList.ScrollBarThickness = 2
    TabList.ScrollBarImageTransparency = 0.4
    TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabList.CanvasSize = UDim2.new()
    TabList.Parent = Sidebar

    BindTheme(TabList, "ScrollBarImageColor3", "Accent")

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.Parent = TabList

    --------------------------------------------------
    -- CONTENT
    --------------------------------------------------

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Position = UDim2.fromOffset(SIDEBAR_WIDTH, 0)
    Content.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, 0)
    Content.BackgroundColor3 = Window.Theme.Background
    Content.BorderSizePixel = 0
    Content.Parent = Body

    Corner(Content, options.CornerRadius or 12)

    local contentMask = Instance.new("Frame")
    contentMask.BackgroundColor3 = Window.Theme.Background
    contentMask.BorderSizePixel = 0
    contentMask.Position = UDim2.new(0, 0, 0, -12)
    contentMask.Size = UDim2.new(1, 0, 0, 12)
    contentMask.ZIndex = 0
    contentMask.Parent = Content

    BindTheme(Content, "BackgroundColor3", "Background")
    BindTheme(contentMask, "BackgroundColor3", "Background")

    -- content header: current tab name + search
    local ContentHeader = Instance.new("Frame")
    ContentHeader.Name = "ContentHeader"
    ContentHeader.Size = UDim2.new(1, 0, 0, 48)
    ContentHeader.BackgroundTransparency = 1
    ContentHeader.Parent = Content

    local CurrentTabLabel = CreateText(ContentHeader, "", 14, Enum.Font.GothamBold)
    CurrentTabLabel.Position = UDim2.fromOffset(18, 0)
    CurrentTabLabel.Size = UDim2.new(1, -220, 1, 0)
    BindTheme(CurrentTabLabel, "TextColor3", "Text")

    -- search
    local SearchBox = Instance.new("TextBox")
    SearchBox.Name = "Search"
    SearchBox.PlaceholderText = "Search..."
    SearchBox.Text = ""
    SearchBox.ClearTextOnFocus = false
    SearchBox.TextSize = 12
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextColor3 = Window.Theme.Text
    SearchBox.PlaceholderColor3 = Window.Theme.SubText
    SearchBox.BackgroundColor3 = Window.Theme.Tertiary
    SearchBox.BorderSizePixel = 0
    SearchBox.Position = UDim2.new(1, -190, 0.5, -15)
    SearchBox.Size = UDim2.fromOffset(172, 30)
    SearchBox.Parent = ContentHeader

    Corner(SearchBox, 8)
    local searchStroke = Stroke(SearchBox, Window.Theme.Border, 0.3)

    BindTheme(SearchBox, "BackgroundColor3", "Tertiary")
    BindTheme(SearchBox, "TextColor3", "Text")
    BindTheme(SearchBox, "PlaceholderColor3", "SubText")
    BindTheme(searchStroke, "Color", "Border")

    Track(SearchBox.Focused:Connect(function()
        Tween(searchStroke, { Color = Window.Theme.Accent, Transparency = 0.1 }, 0.15)
    end))

    Track(SearchBox.FocusLost:Connect(function()
        Tween(searchStroke, { Color = Window.Theme.Border, Transparency = 0.3 }, 0.15)
    end))

    Padding(SearchBox, 0, 0, 0, 0)

    --------------------------------------------------
    -- DRAGGING
    --------------------------------------------------

    local dragging = false
    local dragStart
    local startPosition

    local function UpdateDrag(input)
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end

    Track(Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = Main.Position

            local moveConn, endConn

            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if moveConn then moveConn:Disconnect() end
                    if endConn then endConn:Disconnect() end
                end
            end)
        end
    end))

    Track(UserInputService.InputChanged:Connect(function(input)
        if dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                UpdateDrag(input)
            end
        end
    end))

    --------------------------------------------------
    -- THEME SYSTEM
    --------------------------------------------------

    function Window:SetTheme(theme)
        local selected

        if type(theme) == "string" then
            selected = Library.Themes[theme]
            if not selected then
                warn("[Nebula UI] Unknown theme:", theme)
                return
            end
        elseif type(theme) == "table" then
            selected = theme
        end

        if not selected then
            return
        end

        Window.Theme = selected
        Library.CurrentTheme = selected

        for i = #Window._themeBinds, 1, -1 do
            local item = Window._themeBinds[i]
            local instance = item and item.Instance

            if not instance or not instance.Parent then
                table.remove(Window._themeBinds, i)
            elseif selected[item.Key] then
                pcall(function()
                    Tween(instance, { [item.Property] = selected[item.Key] }, 0.22)
                end)
            end
        end

        -- v4: lifecycle hook - lets custom elements/plugins react to theme swaps
        -- beyond simple property binding.
        for _, element in ipairs(Window.AllElements) do
            if element._ApplyTheme then
                pcall(element._ApplyTheme, element, selected)
            end
        end
    end

    --------------------------------------------------
    -- NOTIFICATIONS
    --------------------------------------------------

    local NotificationHolder = Instance.new("Frame")
    NotificationHolder.Name = "Notifications"
    NotificationHolder.AnchorPoint = Vector2.new(1, 1)
    NotificationHolder.Position = UDim2.new(1, -18, 1, -18)
    NotificationHolder.Size = UDim2.fromOffset(320, 500)
    NotificationHolder.BackgroundTransparency = 1
    NotificationHolder.ZIndex = 100
    NotificationHolder.Parent = ScreenGui

    local NotificationLayout = Instance.new("UIListLayout")
    NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    NotificationLayout.Padding = UDim.new(0, 8)
    NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotificationLayout.Parent = NotificationHolder

    local NotificationTypeColors = {
        Info = "Info",
        Success = "Success",
        Warning = "Warning",
        Error = "Error"
    }

    function Window:Notify(data, content, duration)
        if type(data) == "string" then
            data = { Title = data, Content = content, Duration = duration }
        end

        data = data or {}

        local typeKey = NotificationTypeColors[data.Type] or "Accent"
        local accentColor = Window.Theme[typeKey] or Window.Theme.Accent

        local notification = Instance.new("Frame")
        notification.Size = UDim2.fromOffset(300, 64)
        notification.BackgroundColor3 = Window.Theme.Secondary
        notification.BorderSizePixel = 0
        notification.ZIndex = 101
        notification.Parent = NotificationHolder

        Corner(notification, 10)
        local notifStroke = Stroke(notification, Window.Theme.Border, 0.4)
        BindTheme(notification, "BackgroundColor3", "Secondary")
        BindTheme(notifStroke, "Color", "Border")

        -- accent bar
        local accentBar = Instance.new("Frame")
        accentBar.Size = UDim2.new(0, 3, 1, -16)
        accentBar.Position = UDim2.fromOffset(0, 8)
        accentBar.BackgroundColor3 = accentColor
        accentBar.BorderSizePixel = 0
        accentBar.ZIndex = 102
        accentBar.Parent = notification

        Corner(accentBar, 3)
        BindTheme(accentBar, "BackgroundColor3", typeKey)

        local title = CreateText(notification, data.Title or "Nebula", 13, Enum.Font.GothamBold)
        title.Position = UDim2.fromOffset(14, 8)
        title.Size = UDim2.new(1, -28, 0, 20)
        title.TextColor3 = Window.Theme.Text
        title.ZIndex = 102
        BindTheme(title, "TextColor3", "Text")

        local text = CreateText(notification, data.Content or "", 11, Enum.Font.Gotham)
        text.Position = UDim2.fromOffset(14, 30)
        text.Size = UDim2.new(1, -28, 0, 24)
        text.TextColor3 = Window.Theme.SubText
        text.TextWrapped = true
        text.ZIndex = 102
        BindTheme(text, "TextColor3", "SubText")

        -- slide-in animation
        notification.Position = UDim2.new(1, 40, 0, 0)
        notification.BackgroundTransparency = 1
        accentBar.BackgroundTransparency = 1
        title.TextTransparency = 1
        text.TextTransparency = 1

        Tween(notification, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, 0.35, Enum.EasingStyle.Quint)
        Tween(accentBar, { BackgroundTransparency = 0 }, 0.35)
        Tween(title, { TextTransparency = 0 }, 0.35)
        Tween(text, { TextTransparency = 0 }, 0.35)

        local lifetime = data.Duration or 3.5
        local alive = true

        task.delay(lifetime, function()
            if not alive or not notification.Parent then
                return
            end

            alive = false

            local exit = Tween(notification, {
                Position = UDim2.new(1, 40, 0, 0),
                BackgroundTransparency = 1
            }, 0.3, Enum.EasingStyle.Quint)

            Tween(accentBar, { BackgroundTransparency = 1 }, 0.3)
            Tween(title, { TextTransparency = 1 }, 0.3)
            Tween(text, { TextTransparency = 1 }, 0.3)

            exit.Completed:Connect(function()
                if notification then
                    notification:Destroy()
                end
            end)
        end)

        return notification
    end

    --------------------------------------------------
    -- v4: ELEMENT FINALIZER (unified Component/Element API)
    --------------------------------------------------

    -- Every Tab:AddX / Group:AddX function calls this at the very end instead
    -- of directly inserting into Tab.Elements. It:
    --   1. Registers the element under Window.AllElements (for theme/state pass)
    --   2. Registers it under Window.ElementsByID if options.ID was given
    --   3. Fills in SetVisible / SetDisabled / SetName / Destroy / _ApplyTheme
    --      for any element that didn't already define its own version
    function Window:_Finalize(Tab, Element, options, titleLabel)
        options = options or {}

        Element.ID = options.ID
        Element.Disabled = false
        Element.Destroyed = false
        Element._TitleLabel = Element._TitleLabel or titleLabel
        Element._InputObjects = Element._InputObjects or {}

        if Element.Root and Element.Root:IsA("GuiObject") then
            Element._OriginalBackgroundTransparency = Element.Root.BackgroundTransparency
        end

        if not Element.SetVisible then
            function Element:SetVisible(visible)
                if Element.Root then
                    Element.Root.Visible = visible ~= false
                end
            end
        end

        if not Element.SetDisabled then
            function Element:SetDisabled(disabled)
                Element.Disabled = disabled == true

                if Element.Root and Element.Root:IsA("GuiObject") then
                    local restoreTransparency = Element._OriginalBackgroundTransparency
                    if restoreTransparency == nil then
                        restoreTransparency = Element.Root.BackgroundTransparency
                        Element._OriginalBackgroundTransparency = restoreTransparency
                    end

                    Tween(Element.Root, {
                        BackgroundTransparency = Element.Disabled and math.max(restoreTransparency, 0.5) or restoreTransparency
                    }, 0.15)
                end

                local function DisableObject(object)
                    if object:IsA("GuiButton") then
                        object.Active = not Element.Disabled
                    end
                end

                if Element.Button and Element.Button:IsA("GuiButton") then
                    DisableObject(Element.Button)
                end

                if Element.Root then
                    for _, object in ipairs(Element.Root:GetDescendants()) do
                        DisableObject(object)
                    end
                end
            end
        end

        if not Element.SetName then
            function Element:SetName(newName)
                Element.Name = tostring(newName)
                if Element._TitleLabel then
                    Element._TitleLabel.Text = Element.Name
                end
            end
        end

        if not Element.Destroy then
            function Element:Destroy()
                if Element.Destroyed then
                    return
                end

                Element.Destroyed = true

                if Element._Cleanup then
                    local cleanup = Element._Cleanup
                    Element._Cleanup = nil
                    pcall(cleanup, Element)
                end

                local root = Element.Root
                for i = #Window._themeBinds, 1, -1 do
                    local binding = Window._themeBinds[i]
                    local instance = binding and binding.Instance
                    local belongsToElement = false

                    if root and instance then
                        if instance == root then
                            belongsToElement = true
                        else
                            pcall(function()
                                belongsToElement = instance:IsDescendantOf(root)
                            end)
                        end
                    end

                    if belongsToElement then
                        table.remove(Window._themeBinds, i)
                    end
                end

                if root then
                    Window._baseTextSizes[root] = nil
                    for _, descendant in ipairs(root:GetDescendants()) do Window._baseTextSizes[descendant] = nil end
                    root:Destroy()
                end

                for i = #Tab.Elements, 1, -1 do
                    if Tab.Elements[i] == Element then
                        table.remove(Tab.Elements, i)
                        break
                    end
                end

                for i = #Window.AllElements, 1, -1 do
                    if Window.AllElements[i] == Element then
                        table.remove(Window.AllElements, i)
                        break
                    end
                end

                if Element.ID and Window.ElementsByID[Element.ID] == Element then
                    Window.ElementsByID[Element.ID] = nil
                end
            end
        end

        if not Element._ApplyTheme then
            -- Extension point: custom elements/plugins can override this to
            -- react to Window:SetTheme() beyond simple property binding.
            Element._ApplyTheme = function() end
        end

        table.insert(Tab.Elements, Element)
        table.insert(Window.AllElements, Element)

        if Element.ID then
            if Window.ElementsByID[Element.ID] then
                warn("[Nebula UI] Duplicate element ID:", Element.ID)
            end
            Window.ElementsByID[Element.ID] = Element
        end

        -- StateKey is now supported consistently by every settable element.
        if options.StateKey and (not Element.Get or not Element.Set) then
            warn("[Nebula UI] StateKey requires both Get and Set methods:", tostring(options.StateKey), tostring(Element.Name))
        end

        if options.StateKey and Element.Get and Element.Set then
            local stateKey = tostring(options.StateKey)
            local ok, current = pcall(Element.Get, Element)
            if ok then
                Window.State:Set(stateKey, current)
            end

            Element._StateConnection = Window.State:Bind(stateKey, function(value)
                if Element.Destroyed then return end
                local okGet, currentValue = pcall(Element.Get, Element)
                if okGet and currentValue ~= value then
                    pcall(Element.Set, Element, value)
                end
            end)

            Track({
                Disconnect = function()
                    if Element._StateConnection then
                        Element._StateConnection:Disconnect()
                        Element._StateConnection = nil
                    end
                end
            })
        end

        return Element
    end

    --------------------------------------------------
    -- v4: ELEMENT LOOKUP / STATE MANAGER
    --------------------------------------------------

    function Window:GetElement(id)
        return Window.ElementsByID[id]
    end

    function Window:SetValue(id, value)
        local element = Window.ElementsByID[id]

        if not element or not element.Set then
            warn("[Nebula UI] SetValue: no settable element with ID", id)
            return nil
        end

        if element._ValueType == "MultiDropdown" and type(value) ~= "table" then
            warn("[Nebula UI] SetValue: MultiDropdown expects a table for ID", id)
            return element
        end

        local ok, err = pcall(element.Set, element, value)
        if not ok then
            warn("[Nebula UI] SetValue failed for ID", id, err)
        end

        return element
    end

    -- Collects {id -> value} for every ID'd element that exposes :Get()
    function Window:GetState()
        local data = {}

        for id, element in pairs(Window.ElementsByID) do
            if element.Get then
                local ok, value = pcall(element.Get, element)
                if ok then
                    data[id] = value
                end
            end
        end

        return data
    end

    -- Applies {id -> value} onto every matching ID'd element that exposes :Set()
    function Window:SetState(data)
        data = data or {}

        for id, value in pairs(data) do
            local element = Window.ElementsByID[id]
            if element and element.Set then
                pcall(element.Set, element, value)
            end
        end
    end

    function Window:SaveState()
        Window._SavedState = Window:GetState()
        return Window._SavedState
    end

    function Window:LoadState()
        if Window._SavedState then
            Window:SetState(Window._SavedState)
        end

        return Window._SavedState
    end

    --------------------------------------------------
    -- TABS
    --------------------------------------------------

    function Window:SelectTab(tab)
        if not tab then
            return
        end

        -- Set the active tab BEFORE clearing SearchBox.
        -- TextChanged immediately invokes the search handler, so clearing it
        -- while the previous tab is still active could leave the new tab in
        -- a stale filtered state.
        Window.ActiveTab = tab

        if SearchBox and SearchBox.Text ~= "" then
            SearchBox.Text = ""
        else
            tab:_Search("")
        end

        for _, other in ipairs(Window.Tabs) do
            if other.Content then
                other.Content.Visible = other == tab
            end

            if other.Button then
                local isActive = other == tab

                Tween(other.Button, {
                    BackgroundColor3 = isActive and Window.Theme.Tertiary or Color3.fromRGB(0, 0, 0),
                    BackgroundTransparency = isActive and 0 or 1
                }, 0.18)

                if other.ButtonText then
                    Tween(other.ButtonText, {
                        TextColor3 = isActive and Window.Theme.Text or Window.Theme.SubText
                    }, 0.18)
                end

                if other.Indicator then
                    Tween(other.Indicator, {
                        BackgroundTransparency = isActive and 0 or 1,
                        Size = isActive and UDim2.new(0, 3, 0, 18) or UDim2.new(0, 3, 0, 8)
                    }, 0.22, Enum.EasingStyle.Back)
                end
            end
        end

        CurrentTabLabel.Text = tab.Name

        -- v4: on mobile, picking a tab also closes the sidebar overlay
        if Window.IsMobile and Sidebar.Visible then
            Window:_CloseMobileSidebar()
        end
    end

    function Window:AddTab(name, icon)
        local Tab = {}
        Tab.Name = name or "Tab"
        Tab.Elements = {}
        Tab.Containers = {}

        --------------------------------------------------
        -- TAB BUTTON
        --------------------------------------------------

        local Button = Instance.new("TextButton")
        Button.Name = Tab.Name
        Button.Size = UDim2.new(1, 0, 0, 36)
        Button.BackgroundColor3 = Window.Theme.Tertiary
        Button.BackgroundTransparency = 1
        Button.BorderSizePixel = 0
        Button.AutoButtonColor = false
        Button.Text = ""
        Button.Parent = TabList

        Corner(Button, 8)

        local Indicator = Instance.new("Frame")
        Indicator.Size = UDim2.new(0, 3, 0, 8)
        Indicator.Position = UDim2.fromOffset(0, 9)
        Indicator.AnchorPoint = Vector2.new(0, 0)
        Indicator.BackgroundColor3 = Window.Theme.Accent
        Indicator.BorderSizePixel = 0
        Indicator.BackgroundTransparency = 1
        Indicator.Parent = Button

        Corner(Indicator, 3)
        BindTheme(Indicator, "BackgroundColor3", "Accent")

        local buttonText = CreateText(
            Button,
            (icon and tostring(icon) .. "  " or "") .. Tab.Name,
            12,
            Enum.Font.GothamMedium
        )
        buttonText.Position = UDim2.fromOffset(13, 0)
        buttonText.Size = UDim2.new(1, -20, 1, 0)
        buttonText.TextColor3 = Window.Theme.SubText

        Tab.Button = Button
        Tab.ButtonText = buttonText
        Tab.Indicator = Indicator

        Track(Button.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(Button, { BackgroundTransparency = 0.55 }, 0.15)
                Tween(buttonText, { TextColor3 = Window.Theme.Text }, 0.15)
            end
        end))

        Track(Button.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(Button, { BackgroundTransparency = 1 }, 0.15)
                Tween(buttonText, { TextColor3 = Window.Theme.SubText }, 0.15)
            end
        end))

        --------------------------------------------------
        -- TAB CONTENT
        --------------------------------------------------

        local Scroll = Instance.new("ScrollingFrame")
        Scroll.Name = Tab.Name .. "_Content"
        Scroll.Position = UDim2.fromOffset(12, 56)
        Scroll.Size = UDim2.new(1, -24, 1, -68)
        Scroll.BackgroundTransparency = 1
        Scroll.BorderSizePixel = 0
        Scroll.ScrollBarThickness = 3
        Scroll.ScrollBarImageTransparency = 0.3
        Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Scroll.CanvasSize = UDim2.new()
        Scroll.Visible = false
        Scroll.Parent = Content

        BindTheme(Scroll, "ScrollBarImageColor3", "Accent")

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 8)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = Scroll

        Tab.Content = Scroll

        table.insert(Window.Tabs, Tab)

        Track(Button.MouseButton1Click:Connect(function()
            Window:SelectTab(Tab)
        end))

        --------------------------------------------------
        -- SEARCH
        --------------------------------------------------

        function Tab:_Search(query)
            query = string.lower(query or "")

            for _, element in ipairs(Tab.Elements) do
                if element.Root and not element._Group then
                    local name = string.lower(tostring(element.Name or ""))
                    local match = query == "" or string.find(name, query, 1, true) ~= nil
                    element.Root.Visible = match
                end
            end

            for _, container in ipairs(Tab.Containers or {}) do
                if container.Root and not container.Destroyed then
                    local containerMatch = query == "" or string.find(string.lower(tostring(container.Name or "")), query, 1, true) ~= nil
                    local childMatch = false
                    for _, child in ipairs(container._Elements or {}) do
                        if child.Root and child.Root.Parent then
                            local match = query == "" or string.find(string.lower(child.Name), query, 1, true) ~= nil
                            child.Root.Visible = match
                            childMatch = childMatch or match
                        end
                    end
                    container.Root.Visible = query == "" or containerMatch or childMatch
                end
            end

            for _, group in ipairs(Window._Groups) do
                if group._Tab == Tab then
                    group:_Search(query)
                end
            end

            if Tab._Sections then
                for _, section in ipairs(Tab._Sections) do
                    if section.Root then
                        local name = string.lower(tostring(section.Name or ""))
                        section.Root.Visible = query == "" or string.find(name, query, 1, true) ~= nil
                    end
                end
            end
        end

        --------------------------------------------------
        -- SECTION
        --------------------------------------------------

        Tab._Sections = Tab._Sections or {}

        function Tab:AddSection(title)
            local holder = Instance.new("Frame")
            holder.Name = "Section"
            holder.Size = UDim2.new(1, 0, 0, 30)
            holder.BackgroundTransparency = 1
            holder.Parent = Scroll

            local accentDot = Instance.new("Frame")
            accentDot.Size = UDim2.fromOffset(3, 3)
            accentDot.Position = UDim2.fromOffset(2, 13)
            accentDot.BackgroundColor3 = Window.Theme.Accent
            accentDot.BorderSizePixel = 0
            accentDot.Parent = holder

            Corner(accentDot, 3)
            BindTheme(accentDot, "BackgroundColor3", "Accent")

            local label = CreateText(holder, string.upper(title or "SECTION"), 10, Enum.Font.GothamBold)
            label.Position = UDim2.fromOffset(12, 0)
            label.Size = UDim2.new(1, -12, 1, 0)
            label.TextColor3 = Window.Theme.SubText
            BindTheme(label, "TextColor3", "SubText")

            local Section = { Root = holder, Name = tostring(title or "SECTION"), Destroyed = false }

            function Section:SetVisible(visible)
                if not Section.Destroyed and holder then
                    holder.Visible = visible ~= false
                end
            end

            function Section:SetName(name)
                Section.Name = tostring(name or "SECTION")
                label.Text = string.upper(Section.Name)
            end

            function Section:Destroy()
                if Section.Destroyed then return end
                Section.Destroyed = true

                for i = #Window._themeBinds, 1, -1 do
                    local binding = Window._themeBinds[i]
                    local instance = binding and binding.Instance
                    local belongs = false
                    if instance then
                        pcall(function()
                            belongs = instance == holder or instance:IsDescendantOf(holder)
                        end)
                    end
                    if belongs then
                        table.remove(Window._themeBinds, i)
                    end
                end

                for i = #Tab._Sections, 1, -1 do
                    if Tab._Sections[i] == Section then
                        table.remove(Tab._Sections, i)
                        break
                    end
                end

                if holder then
                    holder:Destroy()
                end
            end

            table.insert(Tab._Sections, Section)

            return Section
        end

        --------------------------------------------------
        -- LABEL
        --------------------------------------------------

        function Tab:AddLabel(options)
            -- v4: kept backward compatible with v3's Tab:AddLabel(text)
            if type(options) == "string" or options == nil then
                options = { Name = options }
            end

            local holder = Instance.new("Frame")
            holder.Name = "Label"
            holder.Size = UDim2.new(1, 0, 0, 34)
            holder.BackgroundTransparency = 1
            holder.Parent = options._Parent or Scroll

            local label = CreateText(holder, options.Name, 12, Enum.Font.Gotham)
            label.Position = UDim2.fromOffset(2, 0)
            label.Size = UDim2.new(1, -4, 1, 0)
            label.TextColor3 = Window.Theme.SubText
            label.TextWrapped = true
            BindTheme(label, "TextColor3", "SubText")

            local Element = {
                Root = holder,
                Name = options.Name or "Label"
            }

            function Element:Set(value)
                label.Text = tostring(value or "")
            end

            function Element:Get()
                return label.Text
            end

            return Window:_Finalize(Tab, Element, options, label)
        end

        --------------------------------------------------
        -- PARAGRAPH
        --------------------------------------------------

        function Tab:AddParagraph(title, text)
            local options = {}

            if type(title) == "table" then
                options = title
            else
                options = { Title = title, Text = text }
            end

            local holder = Instance.new("Frame")
            holder.Name = "Paragraph"
            holder.Size = UDim2.new(1, 0, 0, 66)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = options._Parent or Scroll

            Corner(holder, 9)
            local holderStroke = Stroke(holder, Window.Theme.Border, 0.55)
            BindTheme(holder, "BackgroundColor3", "Secondary")
            BindTheme(holderStroke, "Color", "Border")

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(0, 3, 1, -14)
            bar.Position = UDim2.fromOffset(0, 7)
            bar.BackgroundColor3 = Window.Theme.Accent
            bar.BorderSizePixel = 0
            bar.Parent = holder

            Corner(bar, 3)
            BindTheme(bar, "BackgroundColor3", "Accent")

            local titleLabel = CreateText(holder, options.Title or "Information", 12, Enum.Font.GothamBold)
            titleLabel.Position = UDim2.fromOffset(14, 7)
            titleLabel.Size = UDim2.new(1, -26, 0, 20)
            titleLabel.TextColor3 = Window.Theme.Text
            BindTheme(titleLabel, "TextColor3", "Text")

            local textLabel = CreateText(holder, options.Text or "", 10, Enum.Font.Gotham)
            textLabel.Position = UDim2.fromOffset(14, 29)
            textLabel.Size = UDim2.new(1, -26, 0, 28)
            textLabel.TextColor3 = Window.Theme.SubText
            textLabel.TextWrapped = true
            BindTheme(textLabel, "TextColor3", "SubText")

            local Element = {
                Root = holder,
                Name = options.Title or "Paragraph"
            }

            function Element:Set(value)
                if type(value) == "table" then
                    if value.Title ~= nil then
                        titleLabel.Text = tostring(value.Title)
                    end
                    if value.Text ~= nil then
                        textLabel.Text = tostring(value.Text)
                    end
                else
                    titleLabel.Text = tostring(value or "")
                end
            end

            function Element:Get()
                return {
                    Title = titleLabel.Text,
                    Text = textLabel.Text
                }
            end

            return Window:_Finalize(Tab, Element, options, titleLabel)
        end

        --------------------------------------------------
        -- BUTTON
        --------------------------------------------------

        function Tab:AddButton(options)
            options = options or {}

            local Element = {}
            Element.Name = options.Name or "Button"

            local holder = Instance.new("Frame")
            holder.Name = Element.Name
            holder.Size = UDim2.new(1, 0, 0, options.Description and 62 or 46)
            holder.BackgroundTransparency = 1
            holder.Parent = options._Parent or Scroll

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, 0, 1, 0)
            button.BackgroundColor3 = Window.Theme.Secondary
            button.BorderSizePixel = 0
            button.AutoButtonColor = false
            button.Text = ""
            button.ClipsDescendants = true
            button.Parent = holder

            Corner(button, 9)
            local buttonStroke = Stroke(button, Window.Theme.Border, 0.55)
            BindTheme(button, "BackgroundColor3", "Secondary")
            BindTheme(buttonStroke, "Color", "Border")

            local label = CreateText(button, Element.Name, 12, Enum.Font.GothamMedium)
            label.Position = UDim2.fromOffset(14, options.Description and 6 or 0)
            label.Size = UDim2.new(1, -28, options.Description and 0 or 1, options.Description and 22 or 0)
            label.TextColor3 = Window.Theme.Text
            BindTheme(label, "TextColor3", "Text")

            if options.Description then
                local desc = CreateText(button, options.Description, 10, Enum.Font.Gotham)
                desc.Position = UDim2.fromOffset(14, 30)
                desc.Size = UDim2.new(1, -28, 0, 20)
                desc.TextColor3 = Window.Theme.SubText
                BindTheme(desc, "TextColor3", "SubText")
            end

            Track(button.MouseEnter:Connect(function()
                Tween(button, { BackgroundColor3 = Window.Theme.Hover }, 0.15)
                Tween(buttonStroke, { Color = Window.Theme.BorderLight, Transparency = 0.3 }, 0.15)
            end))

            Track(button.MouseLeave:Connect(function()
                Tween(button, { BackgroundColor3 = Window.Theme.Secondary }, 0.15)
                Tween(buttonStroke, { Color = Window.Theme.Border, Transparency = 0.55 }, 0.15)
            end))

            Track(button.MouseButton1Click:Connect(function()
                if Element.Disabled then return end

                Ripple(button)

                if options.Callback then
                    task.spawn(options.Callback)
                end
            end))

            Element.Root = holder
            Element.Button = button

            return Window:_Finalize(Tab, Element, options, label)
        end

        --------------------------------------------------
        -- TOGGLE
        --------------------------------------------------

        function Tab:AddToggle(options)
            options = options or {}

            local Element = {}
            Element.Name = options.Name or "Toggle"
            Element.Value = options.Default == true

            local holder = Instance.new("Frame")
            holder.Name = Element.Name
            holder.Size = UDim2.new(1, 0, 0, options.Description and 56 or 46)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = options._Parent or Scroll

            Corner(holder, 9)
            local holderStroke = Stroke(holder, Window.Theme.Border, 0.55)
            BindTheme(holder, "BackgroundColor3", "Secondary")
            BindTheme(holderStroke, "Color", "Border")

            local title = CreateText(holder, Element.Name, 12, Enum.Font.GothamMedium)
            title.Position = UDim2.fromOffset(14, options.Description and 6 or 0)
            title.Size = UDim2.new(1, -80, options.Description and 0 or 1, options.Description and 22 or 0)
            title.TextColor3 = Window.Theme.Text
            BindTheme(title, "TextColor3", "Text")

            if options.Description then
                local desc = CreateText(holder, options.Description, 10, Enum.Font.Gotham)
                desc.Position = UDim2.fromOffset(14, 28)
                desc.Size = UDim2.new(1, -80, 0, 20)
                desc.TextColor3 = Window.Theme.SubText
                BindTheme(desc, "TextColor3", "SubText")
            end

            local switch = Instance.new("Frame")
            switch.Size = UDim2.fromOffset(40, 22)
            switch.Position = UDim2.new(1, -54, 0.5, -11)
            switch.BackgroundColor3 = Element.Value and Window.Theme.Accent or Window.Theme.Tertiary
            switch.BorderSizePixel = 0
            switch.Parent = holder

            Corner(switch, 22)
            local switchStroke = Stroke(switch, Window.Theme.Border, 0.4)
            BindTheme(switchStroke, "Color", "Border")

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(16, 16)
            knob.Position = Element.Value and UDim2.new(1, -19, 0.5, -8) or UDim2.fromOffset(3, 3)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.Parent = switch

            Corner(knob, 16)

            local knobStroke = Instance.new("UIStroke")
            knobStroke.Color = Color3.fromRGB(0, 0, 0)
            knobStroke.Transparency = 0.85
            knobStroke.Thickness = 1
            knobStroke.Parent = knob

            local click = Instance.new("TextButton")
            click.Size = UDim2.fromScale(1, 1)
            click.BackgroundTransparency = 1
            click.Text = ""
            click.Parent = holder

            function Element:Set(value)
                Element.Value = value == true

                Tween(switch, {
                    BackgroundColor3 = Element.Value and Window.Theme.Accent or Window.Theme.Tertiary
                }, 0.2, Enum.EasingStyle.Quint)

                Tween(knob, {
                    Position = Element.Value and UDim2.new(1, -19, 0.5, -8) or UDim2.fromOffset(3, 3),
                    Size = UDim2.fromOffset(18, 18)
                }, 0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

                task.delay(0.12, function()
                    if knob then
                        Tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.15)
                    end
                end)

                if options.Callback then
                    task.spawn(options.Callback, Element.Value)
                end
            end

            function Element:Get()
                return Element.Value
            end

            function Element:Enable()
                Element:Set(true)
            end

            function Element:Disable()
                Element:Set(false)
            end

            Track(click.MouseButton1Click:Connect(function()
                if Element.Disabled then return end
                Element:Set(not Element.Value)
            end))

            Element.Root = holder

            return Window:_Finalize(Tab, Element, options, title)
        end

        --------------------------------------------------
        -- SLIDER
        --------------------------------------------------

        function Tab:AddSlider(options)
            options = options or {}

            local Element = {}
            Element.Name = options.Name or "Slider"

            local min = options.Min or 0
            local max = options.Max or 100

            if max <= min then
                max = min + 1
            end

            local value = math.clamp(options.Default or min, min, max)
            Element.Value = value

            local decimals = options.Decimals or options.Rounding or 0

            local function RoundNumber(n)
                local mult = 10 ^ decimals
                return math.floor(n * mult + 0.5) / mult
            end

            local holder = Instance.new("Frame")
            holder.Name = Element.Name
            holder.Size = UDim2.new(1, 0, 0, options.Description and 76 or 62)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = options._Parent or Scroll

            Corner(holder, 9)
            local holderStroke = Stroke(holder, Window.Theme.Border, 0.55)
            BindTheme(holder, "BackgroundColor3", "Secondary")
            BindTheme(holderStroke, "Color", "Border")

            local title = CreateText(holder, Element.Name, 12, Enum.Font.GothamMedium)
            title.Position = UDim2.fromOffset(14, 7)
            title.Size = UDim2.new(1, -80, 0, 20)
            title.TextColor3 = Window.Theme.Text
            BindTheme(title, "TextColor3", "Text")

            if options.Description then
                local desc = CreateText(holder, options.Description, 10, Enum.Font.Gotham)
                desc.Position = UDim2.fromOffset(14, 26)
                desc.Size = UDim2.new(1, -28, 0, 16)
                desc.TextColor3 = Window.Theme.SubText
                BindTheme(desc, "TextColor3", "SubText")
            end

            local valueLabel = CreateText(holder, tostring(RoundNumber(value)), 11, Enum.Font.GothamBold)
            valueLabel.Position = UDim2.new(1, -66, 0, 7)
            valueLabel.Size = UDim2.fromOffset(52, 20)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.TextColor3 = Window.Theme.Accent
            BindTheme(valueLabel, "TextColor3", "Accent")

            local barOffset = options.Description and 50 or 38

            local bar = Instance.new("Frame")
            bar.Position = UDim2.fromOffset(14, barOffset)
            bar.Size = UDim2.new(1, -28, 0, 6)
            bar.BackgroundColor3 = Window.Theme.Tertiary
            bar.BorderSizePixel = 0
            bar.Parent = holder

            Corner(bar, 10)
            BindTheme(bar, "BackgroundColor3", "Tertiary")

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = Window.Theme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = bar

            Corner(fill, 10)
            BindTheme(fill, "BackgroundColor3", "Accent")

            local fillGradient = Instance.new("UIGradient")
            fillGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
            })
            fillGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.35),
                NumberSequenceKeypoint.new(1, 0.65)
            })
            fillGradient.Parent = fill

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(12, 12)
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.ZIndex = 3
            knob.Parent = bar

            Corner(knob, 12)

            local knobStroke = Instance.new("UIStroke")
            knobStroke.Color = Color3.fromRGB(0, 0, 0)
            knobStroke.Transparency = 0.8
            knobStroke.Thickness = 1
            knobStroke.Parent = knob

            local draggingSlider = false

            local function SetFromPosition(x)
                local relative = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local newValue = RoundNumber(min + (max - min) * relative)

                if newValue ~= Element.Value then
                    Element:Set(newValue)
                end
            end

            local input = Instance.new("TextButton")
            input.Size = UDim2.new(1, 12, 1, 16)
            input.Position = UDim2.fromOffset(-6, -8)
            input.BackgroundTransparency = 1
            input.Text = ""
            input.ZIndex = 4
            input.Parent = bar

            function Element:Set(newValue)
                newValue = math.clamp(tonumber(newValue) or min, min, max)
                newValue = RoundNumber(newValue)

                Element.Value = newValue

                local percent = (newValue - min) / (max - min)

                Tween(fill, { Size = UDim2.new(percent, 0, 1, 0) }, 0.12)
                Tween(knob, { Position = UDim2.new(percent, 0, 0.5, 0) }, 0.12)

                valueLabel.Text = tostring(newValue)

                if options.Callback then
                    task.spawn(options.Callback, newValue)
                end
            end

            function Element:Get()
                return Element.Value
            end

            Track(input.InputBegan:Connect(function(i)
                if Element.Disabled then return end

                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    Tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.12, Enum.EasingStyle.Back)
                    SetFromPosition(i.Position.X)
                end
            end))

            Track(UserInputService.InputChanged:Connect(function(i)
                if draggingSlider then
                    if i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch then
                        SetFromPosition(i.Position.X)
                    end
                end
            end))

            local function StopSliderDrag()
                if draggingSlider then
                    draggingSlider = false
                    Tween(knob, { Size = UDim2.fromOffset(12, 12) }, 0.15)
                end
            end

            Track(UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    StopSliderDrag()
                end
            end))

            Track(input.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    StopSliderDrag()
                end
            end))

            Element.Root = holder
            return Window:_Finalize(Tab, Element, options, title)
        end

        --------------------------------------------------
        -- DROPDOWN
        --------------------------------------------------

        local function CreateOverlay(closeCallback)
            local overlay = Instance.new("TextButton")
            overlay.Size = UDim2.fromScale(1, 1)
            overlay.BackgroundTransparency = 1
            overlay.Text = ""
            overlay.ZIndex = 1
            overlay.Parent = ScreenGui

            overlay.MouseButton1Click:Connect(function()
                closeCallback()
            end)

            return overlay
        end

        function Tab:AddDropdown(options)
            options = options or {}

            local Element = {}
            Element.Name = options.Name or "Dropdown"
            Element.Values = options.Values or {}
            Element.Value = options.Default or Element.Values[1]
            Element._ValueType = "Dropdown"
            Element.IsOpen = false

            local overlay
            Element._OpenToken = 0

            local holder = Instance.new("Frame")
            holder.Name = Element.Name
            holder.Size = UDim2.new(1, 0, 0, 46)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.ClipsDescendants = true
            holder.Parent = options._Parent or Scroll

            Corner(holder, 9)
            local holderStroke = Stroke(holder, Window.Theme.Border, 0.55)
            BindTheme(holder, "BackgroundColor3", "Secondary")
            BindTheme(holderStroke, "Color", "Border")

            local title = CreateText(holder, Element.Name, 12, Enum.Font.GothamMedium)
            title.Position = UDim2.fromOffset(14, 0)
            title.Size = UDim2.new(1, -190, 1, 0)
            title.TextColor3 = Window.Theme.Text
            BindTheme(title, "TextColor3", "Text")

            local selected = Instance.new("TextButton")
            selected.Position = UDim2.new(1, -178, 0.5, -16)
            selected.Size = UDim2.fromOffset(164, 32)
            selected.BackgroundColor3 = Window.Theme.Tertiary
            selected.BorderSizePixel = 0
            selected.Text = ""
            selected.AutoButtonColor = false
            selected.Parent = holder

            Corner(selected, 8)
            local selectedStroke = Stroke(selected, Window.Theme.Border, 0.45)
            BindTheme(selected, "BackgroundColor3", "Tertiary")
            BindTheme(selectedStroke, "Color", "Border")

            local selectedText = CreateText(selected, tostring(Element.Value or "Select..."), 11, Enum.Font.Gotham)
            selectedText.Position = UDim2.fromOffset(10, 0)
            selectedText.Size = UDim2.new(1, -32, 1, 0)
            selectedText.TextColor3 = Window.Theme.Text
            BindTheme(selectedText, "TextColor3", "Text")

            local arrow = CreateText(selected, "v", 10, Enum.Font.GothamBold)
            arrow.Position = UDim2.new(1, -22, 0, 0)
            arrow.Size = UDim2.fromOffset(16, 32)
            arrow.TextColor3 = Window.Theme.SubText
            BindTheme(arrow, "TextColor3", "SubText")

            local list = Instance.new("ScrollingFrame")
            list.Position = UDim2.fromOffset(14, 50)
            list.Size = UDim2.new(1, -28, 0, 0)
            list.BackgroundTransparency = 1
            list.BorderSizePixel = 0
            list.ScrollBarThickness = 2
            list.AutomaticCanvasSize = Enum.AutomaticSize.Y
            list.CanvasSize = UDim2.new()
            list.Visible = false
            list.ZIndex = 5
            list.Parent = holder

            BindTheme(list, "ScrollBarImageColor3", "Accent")

            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 4)
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = list

            local function Rebuild()
                for _, child in ipairs(list:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                for index, option in ipairs(Element.Values) do
                    local item = Instance.new("TextButton")
                    item.Size = UDim2.new(1, 0, 0, 30)
                    item.BackgroundColor3 = option == Element.Value and Window.Theme.Accent or Window.Theme.Tertiary
                    item.BackgroundTransparency = option == Element.Value and 0.15 or 0
                    item.BorderSizePixel = 0
                    item.Text = ""
                    item.AutoButtonColor = false
                    item.LayoutOrder = index
                    item.ZIndex = 6
                    item.Parent = list

                    Corner(item, 7)

                    local itemText = CreateText(item, tostring(option), 11, Enum.Font.Gotham)
                    itemText.Position = UDim2.fromOffset(10, 0)
                    itemText.Size = UDim2.new(1, -20, 1, 0)
                    itemText.TextColor3 = option == Element.Value and Window.Theme.Text or Window.Theme.SubText
                    itemText.ZIndex = 6

                    Track(item.MouseEnter:Connect(function()
                        if option ~= Element.Value then
                            Tween(item, { BackgroundColor3 = Window.Theme.Hover }, 0.12)
                            Tween(itemText, { TextColor3 = Window.Theme.Text }, 0.12)
                        end
                    end))

                    Track(item.MouseLeave:Connect(function()
                        if option ~= Element.Value then
                            Tween(item, { BackgroundColor3 = Window.Theme.Tertiary }, 0.12)
                            Tween(itemText, { TextColor3 = Window.Theme.SubText }, 0.12)
                        end
                    end))

                    Track(item.MouseButton1Click:Connect(function()
                        Element:Set(option)
                        Element:Close()
                    end))
                end
            end

            function Element:Set(value)
                Element.Value = value
                selectedText.Text = tostring(value)
                Rebuild()

                if options.Callback then
                    task.spawn(options.Callback, value)
                end
            end

            function Element:Get()
                return Element.Value
            end

            function Element:OpenMenu()
                if Element.IsOpen or Element.Disabled or Element.Destroyed then
                    return
                end

                Element._OpenToken = Element._OpenToken + 1
                local token = Element._OpenToken
                Element.IsOpen = true
                list.Visible = true

                overlay = CreateOverlay(function()
                    Element:Close()
                end)

                local height = math.min(#Element.Values * 34 + 4, 160)

                Tween(arrow, { Rotation = 180 }, 0.2, Enum.EasingStyle.Back)
                Tween(list, { Size = UDim2.new(1, -28, 0, height) }, 0.22)
                Tween(holder, { Size = UDim2.new(1, 0, 0, 56 + height) }, 0.22)
            end

            function Element:Close()
                if not Element.IsOpen then
                    return
                end

                Element.IsOpen = false
                Element._OpenToken = Element._OpenToken + 1

                Tween(arrow, { Rotation = 0 }, 0.2, Enum.EasingStyle.Back)
                Tween(list, { Size = UDim2.new(1, -28, 0, 0) }, 0.18)

                Tween(holder, { Size = UDim2.new(1, 0, 0, 46) }, 0.18)

                if overlay then
                    local o = overlay
                    overlay = nil
                    o:Destroy()
                end

                local token = Element._OpenToken
                task.delay(0.2, function()
                    if token == Element._OpenToken and list and list.Parent then
                        list.Visible = false
                    end
                end)
            end

            Track(selected.MouseButton1Click:Connect(function()
                if Element.IsOpen then
                    Element:Close()
                else
                    Element:OpenMenu()
                end
            end))

            Rebuild()

            Element._Cleanup = function()
                if Element.IsOpen then
                    Element:Close()
                elseif overlay then
                    pcall(function() overlay:Destroy() end)
                    overlay = nil
                end
            end

            Element.Root = holder
            return Window:_Finalize(Tab, Element, options, title)
        end

        --------------------------------------------------
        -- MULTI DROPDOWN
        --------------------------------------------------

        function Tab:AddMultiDropdown(options)
            options = options or {}

            local Element = {}
            Element.Name = options.Name or "Multi Dropdown"
            Element.Values = options.Values or {}
            Element.Selected = {}
            Element._ValueType = "MultiDropdown"

            for _, value in ipairs(options.Default or {}) do
                Element.Selected[value] = true
            end

            local overlay
            local isOpen = false
            Element._OpenToken = 0

            local holder = Instance.new("Frame")
            holder.Name = Element.Name
            holder.Size = UDim2.new(1, 0, 0, 46)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.ClipsDescendants = true
            holder.Parent = options._Parent or Scroll

            Corner(holder, 9)
            local holderStroke = Stroke(holder, Window.Theme.Border, 0.55)
            BindTheme(holder, "BackgroundColor3", "Secondary")
            BindTheme(holderStroke, "Color", "Border")

            local title = CreateText(holder, Element.Name, 12, Enum.Font.GothamMedium)
            title.Position = UDim2.fromOffset(14, 0)
            title.Size = UDim2.new(1, -190, 1, 0)
            title.TextColor3 = Window.Theme.Text
            BindTheme(title, "TextColor3", "Text")

            local selected = Instance.new("TextButton")
            selected.Position = UDim2.new(1, -178, 0.5, -16)
            selected.Size = UDim2.fromOffset(164, 32)
            selected.BackgroundColor3 = Window.Theme.Tertiary
            selected.BorderSizePixel = 0
            selected.Text = ""
            selected.AutoButtonColor = false
            selected.Parent = holder

            Corner(selected, 8)
            local selectedStroke = Stroke(selected, Window.Theme.Border, 0.45)
            BindTheme(selected, "BackgroundColor3", "Tertiary")
            BindTheme(selectedStroke, "Color", "Border")

            local selectedText = CreateText(selected, "", 11, Enum.Font.Gotham)
            selectedText.Position = UDim2.fromOffset(10, 0)
            selectedText.Size = UDim2.new(1, -32, 1, 0)
            selectedText.TextColor3 = Window.Theme.Text
            BindTheme(selectedText, "TextColor3", "Text")

            local arrow = CreateText(selected, "v", 10, Enum.Font.GothamBold)
            arrow.Position = UDim2.new(1, -22, 0, 0)
            arrow.Size = UDim2.fromOffset(16, 32)
            arrow.TextColor3 = Window.Theme.SubText
            BindTheme(arrow, "TextColor3", "SubText")

            local list = Instance.new("ScrollingFrame")
            list.Position = UDim2.fromOffset(14, 50)
            list.Size = UDim2.new(1, -28, 0, 0)
            list.BackgroundTransparency = 1
            list.BorderSizePixel = 0
            list.ScrollBarThickness = 2
            list.AutomaticCanvasSize = Enum.AutomaticSize.Y
            list.CanvasSize = UDim2.new()
            list.Visible = false
            list.ZIndex = 5
            list.Parent = holder

            BindTheme(list, "ScrollBarImageColor3", "Accent")

            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 4)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Parent = list

            local function UpdateText()
                local result = {}

                for _, value in ipairs(Element.Values) do
                    if Element.Selected[value] then
                        table.insert(result, tostring(value))
                    end
                end

                selectedText.Text = #result > 0 and table.concat(result, ", ") or "Select..."
            end

            local CloseMenu

            local function Rebuild()
                for _, child in ipairs(list:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                for index, value in ipairs(Element.Values) do
                    local isSelected = Element.Selected[value] == true

                    local item = Instance.new("TextButton")
                    item.Size = UDim2.new(1, 0, 0, 30)
                    item.BackgroundColor3 = isSelected and Window.Theme.Accent or Window.Theme.Tertiary
                    item.BackgroundTransparency = isSelected and 0.15 or 0
                    item.BorderSizePixel = 0
                    item.Text = ""
                    item.AutoButtonColor = false
                    item.LayoutOrder = index
                    item.ZIndex = 6
                    item.Parent = list

                    Corner(item, 7)

                    local itemText = CreateText(item, tostring(value), 11, Enum.Font.Gotham)
                    itemText.Position = UDim2.fromOffset(10, 0)
                    itemText.Size = UDim2.new(1, -20, 1, 0)
                    itemText.TextColor3 = isSelected and Window.Theme.Text or Window.Theme.SubText
                    itemText.ZIndex = 6

                    Track(item.MouseEnter:Connect(function()
                        if not Element.Selected[value] then
                            Tween(item, { BackgroundColor3 = Window.Theme.Hover }, 0.12)
                            Tween(itemText, { TextColor3 = Window.Theme.Text }, 0.12)
                        end
                    end))

                    Track(item.MouseLeave:Connect(function()
                        if not Element.Selected[value] then
                            Tween(item, { BackgroundColor3 = Window.Theme.Tertiary }, 0.12)
                            Tween(itemText, { TextColor3 = Window.Theme.SubText }, 0.12)
                        end
                    end))

                    Track(item.MouseButton1Click:Connect(function()
                        Element.Selected[value] = not Element.Selected[value]

                        local nowSelected = Element.Selected[value]

                        Tween(item, {
                            BackgroundColor3 = nowSelected and Window.Theme.Accent or Window.Theme.Tertiary,
                            BackgroundTransparency = nowSelected and 0.15 or 0
                        }, 0.15)

                        Tween(itemText, {
                            TextColor3 = nowSelected and Window.Theme.Text or Window.Theme.SubText
                        }, 0.15)

                        UpdateText()

                        if options.Callback then
                            task.spawn(options.Callback, Element:Get())
                        end
                    end))
                end
            end

            function Element:Get()
                local result = {}

                for _, value in ipairs(Element.Values) do
                    if Element.Selected[value] then
                        table.insert(result, value)
                    end
                end

                return result
            end

            function Element:Set(values)
                if type(values) ~= "table" then
                    warn("[Nebula UI] MultiDropdown:Set expects a table, got " .. typeof(values))
                    return
                end

                table.clear(Element.Selected)

                for _, value in ipairs(values or {}) do
                    Element.Selected[value] = true
                end

                UpdateText()
                Rebuild()
            end

            local function OpenMenu()
                if isOpen or Element.Disabled or Element.Destroyed then
                    return
                end

                Element._OpenToken = Element._OpenToken + 1
                local token = Element._OpenToken
                isOpen = true
                list.Visible = true

                overlay = CreateOverlay(function()
                    CloseMenu()
                end)

                local height = math.min(#Element.Values * 34 + 4, 160)

                Tween(arrow, { Rotation = 180 }, 0.2, Enum.EasingStyle.Back)
                Tween(list, { Size = UDim2.new(1, -28, 0, height) }, 0.22)
                Tween(holder, { Size = UDim2.new(1, 0, 0, 56 + height) }, 0.22)
            end

            CloseMenu = function()
                if not isOpen then
                    return
                end

                isOpen = false
                Element._OpenToken = Element._OpenToken + 1

                Tween(arrow, { Rotation = 0 }, 0.2, Enum.EasingStyle.Back)
                Tween(list, { Size = UDim2.new(1, -28, 0, 0) }, 0.18)
                Tween(holder, { Size = UDim2.new(1, 0, 0, 46) }, 0.18)

                if overlay then
                    local o = overlay
                    overlay = nil
                    o:Destroy()
                end

                local token = Element._OpenToken
                task.delay(0.2, function()
                    if token == Element._OpenToken and list and list.Parent then
                        list.Visible = false
                    end
                end)
            end

            Track(selected.MouseButton1Click:Connect(function()
                if isOpen then
                    CloseMenu()
                else
                    OpenMenu()
                end
            end))

            UpdateText()
            Rebuild()

            Element._Cleanup = function()
                if isOpen then
                    CloseMenu()
                elseif overlay then
                    pcall(function() overlay:Destroy() end)
                    overlay = nil
                end
            end

            Element.Root = holder
            return Window:_Finalize(Tab, Element, options, title)
        end

        --------------------------------------------------
        -- TEXTBOX
        --------------------------------------------------

        function Tab:AddTextbox(options)
            options = options or {}

            local Element = {}
            Element.Name = options.Name or "Textbox"
            Element.Value = options.Default or ""

            local holder = Instance.new("Frame")
            holder.Name = Element.Name
            holder.Size = UDim2.new(1, 0, 0, 52)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = options._Parent or Scroll

            Corner(holder, 9)
            local holderStroke = Stroke(holder, Window.Theme.Border, 0.55)
            BindTheme(holder, "BackgroundColor3", "Secondary")
            BindTheme(holderStroke, "Color", "Border")

            local title = CreateText(holder, Element.Name, 12, Enum.Font.GothamMedium)
            title.Position = UDim2.fromOffset(14, 0)
            title.Size = UDim2.new(1, -210, 1, 0)
            title.TextColor3 = Window.Theme.Text
            BindTheme(title, "TextColor3", "Text")

            local box = Instance.new("TextBox")
            box.Position = UDim2.new(1, -198, 0.5, -16)
            box.Size = UDim2.fromOffset(184, 32)
            box.BackgroundColor3 = Window.Theme.Tertiary
            box.BorderSizePixel = 0
            box.Text = Element.Value
            box.PlaceholderText = options.Placeholder or "Enter text..."
            box.TextColor3 = Window.Theme.Text
            box.PlaceholderColor3 = Window.Theme.SubText
            box.TextSize = 11
            box.Font = Enum.Font.Gotham
            box.ClearTextOnFocus = false
            box.Parent = holder

            Corner(box, 8)
            local boxStroke = Stroke(box, Window.Theme.Border, 0.45)

            BindTheme(box, "BackgroundColor3", "Tertiary")
            BindTheme(box, "TextColor3", "Text")
            BindTheme(box, "PlaceholderColor3", "SubText")
            BindTheme(boxStroke, "Color", "Border")

            Track(box.Focused:Connect(function()
                Tween(boxStroke, { Color = Window.Theme.Accent, Transparency = 0.1 }, 0.15)
            end))

            Track(box.FocusLost:Connect(function(enterPressed)
                Tween(boxStroke, { Color = Window.Theme.Border, Transparency = 0.45 }, 0.15)

                Element.Value = box.Text

                if options.Callback then
                    task.spawn(options.Callback, Element.Value, enterPressed)
                end
            end))

            function Element:Set(value)
                Element.Value = tostring(value or "")
                box.Text = Element.Value
            end

            function Element:Get()
                return Element.Value
            end

            Element.Root = holder
            return Window:_Finalize(Tab, Element, options, title)
        end

        --------------------------------------------------
        -- KEYBIND
        --------------------------------------------------

        function Tab:AddKeybind(options)
            options = options or {}

            local Element = {}
            Element.Name = options.Name or "Keybind"
            Element.Value = options.Default or Enum.KeyCode.RightShift

            local holder = Instance.new("Frame")
            holder.Name = Element.Name
            holder.Size = UDim2.new(1, 0, 0, 44)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = options._Parent or Scroll

            Corner(holder, 9)
            local holderStroke = Stroke(holder, Window.Theme.Border, 0.55)
            BindTheme(holder, "BackgroundColor3", "Secondary")
            BindTheme(holderStroke, "Color", "Border")

            local title = CreateText(holder, Element.Name, 12, Enum.Font.GothamMedium)
            title.Position = UDim2.fromOffset(14, 0)
            title.Size = UDim2.new(1, -160, 1, 0)
            title.TextColor3 = Window.Theme.Text
            BindTheme(title, "TextColor3", "Text")

            local key = Instance.new("TextButton")
            key.Position = UDim2.new(1, -148, 0.5, -15)
            key.Size = UDim2.fromOffset(134, 30)
            key.BackgroundColor3 = Window.Theme.Tertiary
            key.BorderSizePixel = 0
            key.Text = ""
            key.AutoButtonColor = false
            key.Parent = holder

            Corner(key, 8)
            local keyStroke = Stroke(key, Window.Theme.Border, 0.45)
            BindTheme(key, "BackgroundColor3", "Tertiary")
            BindTheme(keyStroke, "Color", "Border")

            local keyText = CreateText(key, Element.Value.Name, 10, Enum.Font.GothamBold)
            keyText.Size = UDim2.new(1, 0, 1, 0)
            keyText.TextColor3 = Window.Theme.Text
            keyText.TextXAlignment = Enum.TextXAlignment.Center
            BindTheme(keyText, "TextColor3", "Text")

            local listening = false

            Track(key.MouseButton1Click:Connect(function()
                if Element.Disabled then return end

                listening = true
                keyText.Text = "..."

                Tween(keyStroke, { Color = Window.Theme.Accent, Transparency = 0.1 }, 0.15)
            end))

            Track(UserInputService.InputBegan:Connect(function(input, processed)
                if listening and processed then
                    listening = false
                    keyText.Text = Element.Value.Name
                    Tween(keyStroke, { Color = Window.Theme.Border, Transparency = 0.45 }, 0.15)
                    return
                end

                if processed then
                    return
                end

                if listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape then
                            listening = false
                            keyText.Text = Element.Value.Name
                            Tween(keyStroke, { Color = Window.Theme.Border, Transparency = 0.45 }, 0.15)
                            return
                        end

                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            Element.Value = input.KeyCode
                            keyText.Text = input.KeyCode.Name
                            listening = false

                            Tween(keyStroke, { Color = Window.Theme.Border, Transparency = 0.45 }, 0.15)

                            if options.ChangedCallback then
                                task.spawn(options.ChangedCallback, Element.Value)
                            end
                        end
                    end

                    return
                end

                if Element.Disabled then
                    return
                end

                if input.KeyCode == Element.Value and input.UserInputType == Enum.UserInputType.Keyboard then
                    if options.Callback then
                        task.spawn(options.Callback)
                    end
                end
            end))

            function Element:Set(value)
                if typeof(value) == "EnumItem" then
                    Element.Value = value
                    keyText.Text = value.Name
                end
            end

            function Element:Get()
                return Element.Value
            end

            Element.Root = holder
            return Window:_Finalize(Tab, Element, options, title)
        end

        --------------------------------------------------
        -- COLOR PICKER
        --------------------------------------------------

        function Tab:AddColorPicker(options)
            options = options or {}

            local Element = {}
            Element.Name = options.Name or "Color"
            Element.Value = options.Default or Color3.fromRGB(124, 92, 255)

            local overlay
            local pickerOpen = false

            local holder = Instance.new("Frame")
            holder.Name = Element.Name
            holder.Size = UDim2.new(1, 0, 0, 44)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = options._Parent or Scroll

            Corner(holder, 9)
            local holderStroke = Stroke(holder, Window.Theme.Border, 0.55)
            BindTheme(holder, "BackgroundColor3", "Secondary")
            BindTheme(holderStroke, "Color", "Border")

            local title = CreateText(holder, Element.Name, 12, Enum.Font.GothamMedium)
            title.Position = UDim2.fromOffset(14, 0)
            title.Size = UDim2.new(1, -80, 1, 0)
            title.TextColor3 = Window.Theme.Text
            BindTheme(title, "TextColor3", "Text")

            local hexLabel = CreateText(holder, "", 10, Enum.Font.Gotham)
            hexLabel.Position = UDim2.new(1, -140, 0, 0)
            hexLabel.Size = UDim2.fromOffset(80, 44)
            hexLabel.TextXAlignment = Enum.TextXAlignment.Right
            hexLabel.TextColor3 = Window.Theme.SubText
            BindTheme(hexLabel, "TextColor3", "SubText")

            local color = Instance.new("TextButton")
            color.Position = UDim2.new(1, -52, 0.5, -13)
            color.Size = UDim2.fromOffset(38, 26)
            color.BackgroundColor3 = Element.Value
            color.BorderSizePixel = 0
            color.Text = ""
            color.Parent = holder

            Corner(color, 7)

            local colorStroke = Instance.new("UIStroke")
            colorStroke.Color = Color3.fromRGB(0, 0, 0)
            colorStroke.Transparency = 0.7
            colorStroke.Thickness = 1
            colorStroke.Parent = color

            local function ToHex(c)
                return string.format("#%02X%02X%02X",
                    math.floor(c.R * 255 + 0.5),
                    math.floor(c.G * 255 + 0.5),
                    math.floor(c.B * 255 + 0.5))
            end

            local function UpdateHexLabel()
                hexLabel.Text = ToHex(Element.Value)
            end

            UpdateHexLabel()

            -- popup
            local panel
            local hue, sat, val
            local pickerConnections = {}

            local function TrackPicker(connection)
                if not connection then return nil end
                table.insert(pickerConnections, connection)
                Track(connection)
                return connection
            end

            local function DisconnectPickerConnections()
                for i = #pickerConnections, 1, -1 do
                    pcall(function()
                        pickerConnections[i]:Disconnect()
                    end)
                    pickerConnections[i] = nil
                end
            end

            local function ApplyFromHSV()
                local newColor = Color3.fromHSV(hue, sat, val)

                Element.Value = newColor
                color.BackgroundColor3 = newColor
                UpdateHexLabel()

                if options.Callback then
                    task.spawn(options.Callback, newColor)
                end
            end

            local function ClosePicker()
                if not pickerOpen and not panel and not overlay then
                    DisconnectPickerConnections()
                    return
                end

                pickerOpen = false
                DisconnectPickerConnections()

                local popupRoot = panel
                if popupRoot then
                    for i = #Window._themeBinds, 1, -1 do
                        local binding = Window._themeBinds[i]
                        local instance = binding and binding.Instance
                        local belongsToPopup = false

                        if instance then
                            if instance == popupRoot then
                                belongsToPopup = true
                            else
                                pcall(function()
                                    belongsToPopup = instance:IsDescendantOf(popupRoot)
                                end)
                            end
                        end

                        if belongsToPopup then
                            table.remove(Window._themeBinds, i)
                        end
                    end
                end

                if overlay then
                    local o = overlay
                    overlay = nil
                    o:Destroy()
                end

                if panel then
                    local p = panel
                    panel = nil

                    Tween(p, { BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0) }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.In)

                    task.delay(0.2, function()
                        if p then
                            p:Destroy()
                        end
                    end)
                end
            end

            local function BuildPicker()
                hue, sat, val = Color3.toHSV(Element.Value)

                overlay = Instance.new("TextButton")
                overlay.Size = UDim2.fromScale(1, 1)
                overlay.BackgroundTransparency = 1
                overlay.Text = ""
                overlay.ZIndex = 200
                overlay.Parent = ScreenGui

                TrackPicker(overlay.MouseButton1Click:Connect(ClosePicker))

                panel = Instance.new("CanvasGroup")
                panel.Size = UDim2.fromOffset(250, 262)
                panel.AnchorPoint = Vector2.new(0.5, 0.5)
                panel.Position = UDim2.new(0.5, 0, 0.5, 0)
                panel.BackgroundColor3 = Window.Theme.Secondary
                panel.BorderSizePixel = 0
                panel.ZIndex = 210
                panel.Parent = ScreenGui

                Corner(panel, 12)
                local panelStroke = Stroke(panel, Window.Theme.Border, 0.35)
                BindTheme(panel, "BackgroundColor3", "Secondary")
                BindTheme(panelStroke, "Color", "Border")

                local panelTitle = CreateText(panel, "Color Picker", 13, Enum.Font.GothamBold)
                panelTitle.Position = UDim2.fromOffset(14, 10)
                panelTitle.Size = UDim2.new(1, -28, 0, 20)
                panelTitle.TextColor3 = Window.Theme.Text
                panelTitle.ZIndex = 211
                BindTheme(panelTitle, "TextColor3", "Text")

                -- SV square
                local svFrame = Instance.new("Frame")
                svFrame.Size = UDim2.fromOffset(186, 150)
                svFrame.Position = UDim2.fromOffset(14, 40)
                svFrame.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                svFrame.BorderSizePixel = 0
                svFrame.ZIndex = 211
                svFrame.Parent = panel

                Corner(svFrame, 8)

                local whiteOverlay = Instance.new("Frame")
                whiteOverlay.Size = UDim2.fromScale(1, 1)
                whiteOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                whiteOverlay.BorderSizePixel = 0
                whiteOverlay.ZIndex = 212
                whiteOverlay.Parent = svFrame

                local whiteGradient = Instance.new("UIGradient")
                whiteGradient.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                })
                whiteGradient.Parent = whiteOverlay

                local blackOverlay = Instance.new("Frame")
                blackOverlay.Size = UDim2.fromScale(1, 1)
                blackOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                blackOverlay.BorderSizePixel = 0
                blackOverlay.ZIndex = 213
                blackOverlay.Parent = svFrame

                local blackGradient = Instance.new("UIGradient")
                blackGradient.Rotation = 90
                blackGradient.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                })
                blackGradient.Parent = blackOverlay

                local svKnob = Instance.new("Frame")
                svKnob.Size = UDim2.fromOffset(12, 12)
                svKnob.AnchorPoint = Vector2.new(0.5, 0.5)
                svKnob.Position = UDim2.fromScale(sat, 1 - val)
                svKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                svKnob.BorderSizePixel = 0
                svKnob.ZIndex = 215
                svKnob.Parent = svFrame

                Corner(svKnob, 12)

                local svKnobStroke = Instance.new("UIStroke")
                svKnobStroke.Color = Color3.fromRGB(0, 0, 0)
                svKnobStroke.Transparency = 0.6
                svKnobStroke.Thickness = 1.5
                svKnobStroke.Parent = svKnob

                local svInput = Instance.new("TextButton")
                svInput.Size = UDim2.fromScale(1, 1)
                svInput.BackgroundTransparency = 1
                svInput.Text = ""
                svInput.ZIndex = 216
                svInput.Parent = svFrame

                -- hue bar
                local hueBar = Instance.new("Frame")
                hueBar.Size = UDim2.fromOffset(16, 150)
                hueBar.Position = UDim2.fromOffset(210, 40)
                hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueBar.BorderSizePixel = 0
                hueBar.ZIndex = 211
                hueBar.Parent = panel

                Corner(hueBar, 8)

                local hueGradient = Instance.new("UIGradient")
                hueGradient.Rotation = 90
                hueGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
                })
                hueGradient.Parent = hueBar

                local hueKnob = Instance.new("Frame")
                hueKnob.Size = UDim2.fromOffset(22, 8)
                hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
                hueKnob.Position = UDim2.new(0.5, 0, hue, 0)
                hueKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueKnob.BorderSizePixel = 0
                hueKnob.ZIndex = 214
                hueKnob.Parent = hueBar

                Corner(hueKnob, 4)

                local hueKnobStroke = Instance.new("UIStroke")
                hueKnobStroke.Color = Color3.fromRGB(0, 0, 0)
                hueKnobStroke.Transparency = 0.6
                hueKnobStroke.Thickness = 1.5
                hueKnobStroke.Parent = hueKnob

                local hueInput = Instance.new("TextButton")
                hueInput.Size = UDim2.new(1, 12, 1, 0)
                hueInput.Position = UDim2.fromOffset(-6, 0)
                hueInput.BackgroundTransparency = 1
                hueInput.Text = ""
                hueInput.ZIndex = 216
                hueInput.Parent = hueBar

                -- preview + hex
                local preview = Instance.new("Frame")
                preview.Size = UDim2.fromOffset(44, 30)
                preview.Position = UDim2.fromOffset(14, 204)
                preview.BackgroundColor3 = Element.Value
                preview.BorderSizePixel = 0
                preview.ZIndex = 211
                preview.Parent = panel

                Corner(preview, 8)

                local previewStroke = Instance.new("UIStroke")
                previewStroke.Color = Color3.fromRGB(0, 0, 0)
                previewStroke.Transparency = 0.7
                previewStroke.Thickness = 1
                previewStroke.Parent = preview

                local hexBox = Instance.new("TextBox")
                hexBox.Size = UDim2.fromOffset(90, 30)
                hexBox.Position = UDim2.fromOffset(66, 204)
                hexBox.BackgroundColor3 = Window.Theme.Tertiary
                hexBox.BorderSizePixel = 0
                hexBox.Text = ToHex(Element.Value)
                hexBox.TextColor3 = Window.Theme.Text
                hexBox.PlaceholderColor3 = Window.Theme.SubText
                hexBox.TextSize = 11
                hexBox.Font = Enum.Font.Gotham
                hexBox.ClearTextOnFocus = false
                hexBox.ZIndex = 211
                hexBox.Parent = panel

                Corner(hexBox, 8)
                local hexStroke = Stroke(hexBox, Window.Theme.Border, 0.45)
                BindTheme(hexBox, "BackgroundColor3", "Tertiary")
                BindTheme(hexBox, "TextColor3", "Text")
                BindTheme(hexStroke, "Color", "Border")

                local doneButton = Instance.new("TextButton")
                doneButton.Size = UDim2.fromOffset(70, 30)
                doneButton.Position = UDim2.new(1, -84, 0, 204)
                doneButton.BackgroundColor3 = Window.Theme.Accent
                doneButton.BorderSizePixel = 0
                doneButton.Text = "Done"
                doneButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                doneButton.TextSize = 11
                doneButton.Font = Enum.Font.GothamBold
                doneButton.ZIndex = 211
                doneButton.Parent = panel

                Corner(doneButton, 8)
                BindTheme(doneButton, "BackgroundColor3", "Accent")

                TrackPicker(doneButton.MouseButton1Click:Connect(ClosePicker))

                -- interactions
                local draggingSV = false
                local draggingHue = false

                local function UpdateFromSV(x, y)
                    sat = math.clamp((x - svFrame.AbsolutePosition.X) / svFrame.AbsoluteSize.X, 0, 1)
                    val = 1 - math.clamp((y - svFrame.AbsolutePosition.Y) / svFrame.AbsoluteSize.Y, 0, 1)

                    svKnob.Position = UDim2.fromScale(sat, 1 - val)

                    ApplyFromHSV()
                    preview.BackgroundColor3 = Element.Value
                    hexBox.Text = ToHex(Element.Value)
                end

                local function UpdateFromHue(y)
                    hue = math.clamp((y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)

                    hueKnob.Position = UDim2.new(0.5, 0, hue, 0)
                    svFrame.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)

                    ApplyFromHSV()
                    preview.BackgroundColor3 = Element.Value
                    hexBox.Text = ToHex(Element.Value)
                end

                TrackPicker(svInput.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then
                        draggingSV = true
                        UpdateFromSV(i.Position.X, i.Position.Y)
                    end
                end))

                TrackPicker(hueInput.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then
                        draggingHue = true
                        UpdateFromHue(i.Position.Y)
                    end
                end))

                TrackPicker(UserInputService.InputChanged:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch then
                        if draggingSV then
                            UpdateFromSV(i.Position.X, i.Position.Y)
                        elseif draggingHue then
                            UpdateFromHue(i.Position.Y)
                        end
                    end
                end))

                TrackPicker(UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then
                        draggingSV = false
                        draggingHue = false
                    end
                end))

                TrackPicker(hexBox.FocusLost:Connect(function()
                    local text = string.gsub(hexBox.Text, "#", "")
                    local r = tonumber(string.sub(text, 1, 2), 16)
                    local g = tonumber(string.sub(text, 3, 4), 16)
                    local b = tonumber(string.sub(text, 5, 6), 16)

                    if r and g and b then
                        Element.Value = Color3.fromRGB(r, g, b)
                        color.BackgroundColor3 = Element.Value
                        preview.BackgroundColor3 = Element.Value
                        UpdateHexLabel()

                        hue, sat, val = Color3.toHSV(Element.Value)
                        svFrame.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                        svKnob.Position = UDim2.fromScale(sat, 1 - val)
                        hueKnob.Position = UDim2.new(0.5, 0, hue, 0)

                        if options.Callback then
                            task.spawn(options.Callback, Element.Value)
                        end
                    else
                        hexBox.Text = ToHex(Element.Value)
                    end
                end))

                panel.BackgroundTransparency = 1
                panel.Size = UDim2.fromOffset(0, 0)

                Tween(panel, { BackgroundTransparency = 0, Size = UDim2.fromOffset(250, 262) }, 0.25, Enum.EasingStyle.Back)
            end

            Element._Cleanup = function()
                ClosePicker()
            end

            function Element:Set(value)
                if typeof(value) == "Color3" then
                    Element.Value = value
                    color.BackgroundColor3 = value
                    UpdateHexLabel()

                    if options.Callback then
                        task.spawn(options.Callback, value)
                    end
                end
            end

            function Element:Get()
                return Element.Value
            end

            Track(color.MouseButton1Click:Connect(function()
                if Element.Disabled then return end

                if pickerOpen then
                    ClosePicker()
                    return
                end

                pickerOpen = true
                BuildPicker()
            end))

            Element.Root = holder
            return Window:_Finalize(Tab, Element, options, title)
        end

        --------------------------------------------------
        -- CONTAINER
        --------------------------------------------------

        function Tab:AddContainer(options)
            options = options or {}

            local Container = {}
            Container.Name = options.Name or "Container"

            local frame = Instance.new("Frame")
            frame.Name = Container.Name
            frame.Size = UDim2.new(1, 0, 0, options.Height or 100)
            frame.BackgroundColor3 = Window.Theme.Secondary
            frame.BorderSizePixel = 0
            frame.Parent = options._Parent or Scroll

            Corner(frame, 9)
            local frameStroke = Stroke(frame, Window.Theme.Border, 0.55)
            BindTheme(frame, "BackgroundColor3", "Secondary")
            BindTheme(frameStroke, "Color", "Border")

            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 6)
            layout.Parent = frame

            Padding(frame, 10, 10, 10, 10)

            Container.Root = frame
            Container.Destroyed = false
            Container._Elements = {}
            table.insert(Tab.Containers, Container)

            function Container:SetVisible(visible)
                if frame then
                    frame.Visible = visible ~= false
                end
            end

            function Container:SetDisabled(disabled)
                local value = disabled == true
                if frame then
                    frame.Active = not value
                    for _, object in ipairs(frame:GetDescendants()) do
                        if object:IsA("GuiButton") then
                            object.Active = not value
                        end
                    end
                end
            end

            function Container:AddLabel(text)
                local label = CreateText(frame, text, 11, Enum.Font.Gotham)
                label.Size = UDim2.new(1, 0, 0, 22)
                label.TextColor3 = Window.Theme.Text
                BindTheme(label, "TextColor3", "Text")
                table.insert(Container._Elements, {Name = tostring(text or ""), Root = label})
                return label
            end

            function Container:Destroy()
                if Container.Destroyed then return end
                Container.Destroyed = true

                if frame then
                    for i = #Window._themeBinds, 1, -1 do
                        local binding = Window._themeBinds[i]
                        local instance = binding and binding.Instance
                        local belongs = false
                        if instance then
                            pcall(function()
                                belongs = instance == frame or instance:IsDescendantOf(frame)
                            end)
                        end
                        if belongs then
                            table.remove(Window._themeBinds, i)
                        end
                    end

                    frame:Destroy()
                    frame = nil
                    Container.Root = nil
                end
                for i = #Tab.Containers, 1, -1 do
                    if Tab.Containers[i] == Container then table.remove(Tab.Containers, i); break end
                end
            end

            return Container
        end

        --------------------------------------------------
        -- v4: LAYOUT ENGINE - Tab:AddGroup({ Columns = N })
        --------------------------------------------------

        -- Returns a Group with the same AddX methods as a Tab. Elements added
        -- to it are distributed round-robin across N side-by-side columns and
        -- automatically collapse to a single column when Window.IsMobile is
        -- true (Responsive = true on the Window), with no changes needed in
        -- the caller's code.
        function Tab:AddGroup(options)
            options = options or {}

            local Group = {}
            Group._Tab = Tab
            Group._ManuallyHidden = false
            Group.Name = options.Name or "Group"
            Group.Columns = math.max(1, options.Columns or 2)
            Group._Elements = {}

            local holder = Instance.new("Frame")
            holder.Name = Group.Name
            holder.AutomaticSize = Enum.AutomaticSize.Y
            holder.Size = UDim2.new(1, 0, 0, 0)
            holder.BackgroundTransparency = 1
            holder.Parent = options._Parent or Scroll

            local rowLayout = Instance.new("UIListLayout")
            rowLayout.FillDirection = Enum.FillDirection.Horizontal
            rowLayout.Padding = UDim.new(0, 8)
            rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
            rowLayout.Parent = holder

            Group.Root = holder
            Group.ColumnFrames = {}

            local function BuildColumns(count)
                for _, f in ipairs(Group.ColumnFrames) do
                    f:Destroy()
                end
                table.clear(Group.ColumnFrames)

                local gap = 8

                for i = 1, count do
                    local col = Instance.new("Frame")
                    col.Name = "Column" .. i
                    col.AutomaticSize = Enum.AutomaticSize.Y
                    col.Size = UDim2.new(1 / count, -((count - 1) * gap) / count, 0, 0)
                    col.BackgroundTransparency = 1
                    col.LayoutOrder = i
                    col.Parent = holder

                    local layout = Instance.new("UIListLayout")
                    layout.Padding = UDim.new(0, 8)
                    layout.SortOrder = Enum.SortOrder.LayoutOrder
                    layout.Parent = col

                    table.insert(Group.ColumnFrames, col)
                end
            end

            Group.CurrentColumns = (Window.IsMobile and 1) or Group.Columns
            BuildColumns(Group.CurrentColumns)

            local nextColumn = 1

            local function GetTargetParent()
                local col = Group.ColumnFrames[nextColumn]
                nextColumn = nextColumn + 1
                if nextColumn > #Group.ColumnFrames then
                    nextColumn = 1
                end
                return col
            end

            local function Wrap(addFn)
                return function(_, elOptions)
                    local source = elOptions or {}
                    local copied = {}
                    for key, value in pairs(source) do
                        copied[key] = value
                    end
                    copied._Parent = GetTargetParent()

                    local element = addFn(Tab, copied)
                    element._Group = Group
                    table.insert(Group._Elements, element)
                    return element
                end
            end

            Group.AddToggle = Wrap(Tab.AddToggle)
            Group.AddSlider = Wrap(Tab.AddSlider)
            Group.AddButton = Wrap(Tab.AddButton)
            Group.AddDropdown = Wrap(Tab.AddDropdown)
            Group.AddMultiDropdown = Wrap(Tab.AddMultiDropdown)
            Group.AddTextbox = Wrap(Tab.AddTextbox)
            Group.AddKeybind = Wrap(Tab.AddKeybind)
            Group.AddColorPicker = Wrap(Tab.AddColorPicker)
            Group.AddLabel = Wrap(Tab.AddLabel)
            Group.AddParagraph = Wrap(Tab.AddParagraph)

            -- Called by the Window's responsive handler; reflows every child
            -- element into a new column count without touching user code.
            function Group:_Relayout(isMobile)
                local targetColumns = isMobile and 1 or Group.Columns

                if targetColumns == Group.CurrentColumns then
                    return
                end

                local roots = {}
                for _, col in ipairs(Group.ColumnFrames) do
                    for _, child in ipairs(col:GetChildren()) do
                        if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
                            table.insert(roots, child)
                        end
                    end
                end

                for _, root in ipairs(roots) do
                    root.Parent = nil
                end

                BuildColumns(targetColumns)
                Group.CurrentColumns = targetColumns
                nextColumn = 1

                for _, root in ipairs(roots) do
                    root.LayoutOrder = root.LayoutOrder or 0
                    root.Parent = GetTargetParent()
                end
            end

            function Group:SetVisible(visible)
                Group._ManuallyHidden = visible == false
                holder.Visible = visible ~= false
            end

            function Group:Destroy()
                if Group.Destroyed then return end
                Group.Destroyed = true
                for _, element in ipairs(Group._Elements) do
                    if element and element.Destroy then
                        pcall(element.Destroy, element)
                    end
                end
                Group._Elements = {}

                for i = #Window._themeBinds, 1, -1 do
                    local binding = Window._themeBinds[i]
                    local instance = binding and binding.Instance
                    local belongs = false
                    if instance then
                        pcall(function()
                            belongs = instance == holder or instance:IsDescendantOf(holder)
                        end)
                    end
                    if belongs then
                        table.remove(Window._themeBinds, i)
                    end
                end

                for i = #Window._Groups, 1, -1 do
                    if Window._Groups[i] == Group then
                        table.remove(Window._Groups, i)
                        break
                    end
                end
                if holder then
                    holder:Destroy()
                end
                Group.Root = nil
                Group.ColumnFrames = {}
            end

            function Group:_Search(query)
                query = string.lower(query or "")

                if Group._ManuallyHidden then
                    holder.Visible = false
                    return
                end

                local hasMatch = query == ""

                for _, element in ipairs(Group._Elements) do
                    if element and element.Root then
                        local name = string.lower(tostring(element.Name or ""))
                        local match = query == "" or string.find(name, query, 1, true) ~= nil
                        element.Root.Visible = match
                        if match then
                            hasMatch = true
                        end
                    end
                end

                holder.Visible = hasMatch
            end

            table.insert(Window._Groups, Group)

            return Group
        end

        --------------------------------------------------
        -- SELECT FIRST TAB
        --------------------------------------------------

        if #Window.Tabs == 1 then
            Window:SelectTab(Tab)
        end

        return Tab
    end

    --------------------------------------------------
    -- SEARCH HANDLER
    --------------------------------------------------

    Track(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if Window.ActiveTab then
            Window.ActiveTab:_Search(SearchBox.Text)
        end
    end))

    --------------------------------------------------
    -- MINIMIZE
    --------------------------------------------------

    local savedSize = Window.Size

    Track(Minimize.MouseButton1Click:Connect(function()
        Window.Minimized = not Window.Minimized

        if Window.Minimized then
            savedSize = Main.Size

            Tween(Body, { GroupTransparency = 1 }, 0.18)
            Tween(Shadow, { ImageTransparency = 1 }, 0.25)

            task.delay(0.12, function()
                Body.Visible = false
            end)

            Tween(Main, {
                Size = UDim2.fromOffset(savedSize.X.Offset, 70)
            }, 0.28, Enum.EasingStyle.Quint)
        else
            Body.Visible = true

            Tween(Main, {
                Size = savedSize
            }, 0.28, Enum.EasingStyle.Quint)

            Tween(Shadow, { ImageTransparency = 0.4 }, 0.3)

            task.delay(0.1, function()
                Tween(Body, { GroupTransparency = 0 }, 0.2)
            end)
        end
    end))

    --------------------------------------------------
    -- CLOSE / HIDE
    --------------------------------------------------

    local MobileButton

    local function GetToggleKeyText()
        if Window.ToggleKey == Enum.KeyCode.RightControl then
            return "Ctrl + Right"
        end
        if Window.ToggleKey == Enum.KeyCode.LeftControl then
            return "Ctrl + Left"
        end
        return Window.ToggleKey and Window.ToggleKey.Name or "your keybind"
    end

    Track(Close.MouseButton1Click:Connect(function()
        Window:Hide()
        Window:Notify({
            Title = "Nebula UI",
            Content = "Меню скрыто. Нажмите " .. GetToggleKeyText() .. ", чтобы открыть его снова.",
            Type = "Info",
            Duration = 3.5
        })
    end))

    --------------------------------------------------
    -- TOGGLE KEYBIND
    --------------------------------------------------

    if Window.ToggleKey then
        Track(UserInputService.InputBegan:Connect(function(input, processed)
            if processed then
                return
            end

            if input.KeyCode == Window.ToggleKey then
                Window:Toggle()
            end
        end))
    end

    --------------------------------------------------
    -- MOBILE BUTTON
    --------------------------------------------------

    MobileButton = Instance.new("TextButton")
    MobileButton.Name = "MobileButton"
    MobileButton.Size = UDim2.fromOffset(50, 50)
    MobileButton.Position = UDim2.new(1, -70, 1, -90)
    MobileButton.BackgroundColor3 = Window.Theme.Accent
    MobileButton.BorderSizePixel = 0
    MobileButton.Text = "N"
    MobileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MobileButton.TextSize = 20
    MobileButton.Font = Enum.Font.GothamBold
    MobileButton.Visible = UserInputService.TouchEnabled and (options.ShowMobileButton ~= false)
    MobileButton.ZIndex = 200
    MobileButton.Parent = ScreenGui

    Corner(MobileButton, 15)
    BindTheme(MobileButton, "BackgroundColor3", "Accent")

    local mobilePulseCancelled = false

    local mobileGradient = Instance.new("UIGradient")
    mobileGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 0.45)
    })
    mobileGradient.Parent = MobileButton

    Track(MobileButton.MouseButton1Click:Connect(function()
        Window:Toggle()
        Tween(MobileButton, { Size = UDim2.fromOffset(46, 46) }, 0.1, Enum.EasingStyle.Back)
        task.delay(0.1, function()
            if MobileButton and MobileButton.Parent and not Window.Destroyed then
                Tween(MobileButton, { Size = UDim2.fromOffset(50, 50) }, 0.15, Enum.EasingStyle.Back)
            end
        end)
    end))

    -- gentle pulse
    task.spawn(function()
        while not Window.Destroyed and not mobilePulseCancelled and MobileButton and MobileButton.Parent do
            task.wait(3)
            if Window.Destroyed or mobilePulseCancelled or not MobileButton or not MobileButton.Parent then
                break
            end
            if MobileButton.Visible then
                local pulse = Tween(mobileGradient, { Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 0.2)
                }) }, 0.6)
                pulse.Completed:Wait()
                if Window.Destroyed or not mobileGradient or not mobileGradient.Parent then
                    break
                end
                Tween(mobileGradient, { Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.15),
                    NumberSequenceKeypoint.new(1, 0.45)
                }) }, 0.6)
            end
        end
    end)

    --------------------------------------------------
    -- v4: RESPONSIVE LAYOUT
    --------------------------------------------------

    Window.Responsive = options.Responsive == true
    Window.IsMobile = false
    Window.Breakpoints = options.Breakpoints or {
        Mobile = 620,
        MinWidth = 260,
        MinHeight = 320,
        SidebarMax = 220,
        ViewportPadding = 24,
    }

    local function GetViewportSize()
        local camera = Workspace.CurrentCamera
        return (camera and camera.ViewportSize) or Vector2.new(1280, 720)
    end

    function Window:_CloseMobileSidebar()
        Sidebar.Visible = false
    end

    Track(Menu.MouseButton1Click:Connect(function()
        if not Window.IsMobile then return end

        Sidebar.Visible = not Sidebar.Visible
        if Sidebar.Visible then
            Sidebar.ZIndex = 50
        end
    end))

    local function ApplyDesktopLayout()
        Menu.Visible = false
        MobileButton.Visible = false
        Sidebar.Visible = true
        Sidebar.ZIndex = 2
        Sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0)
        Sidebar.BackgroundTransparency = 1

        Content.Position = UDim2.fromOffset(SIDEBAR_WIDTH, 0)
        Content.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, 0)

        if not Window.Minimized then
            Main.Size = finalSize
        end
    end

    local function ApplyMobileLayout()
        Menu.Visible = true
        MobileButton.Visible = not Main.Visible and UserInputService.TouchEnabled and (options.ShowMobileButton ~= false)
        Sidebar.Visible = false
        Sidebar.ZIndex = 50
        Sidebar.Size = UDim2.new(0, math.min(SIDEBAR_WIDTH + 30, Window.Breakpoints.SidebarMax), 1, 0)
        Sidebar.BackgroundTransparency = 0
        Sidebar.BackgroundColor3 = Window.Theme.Background

        Content.Position = UDim2.fromOffset(0, 0)
        Content.Size = UDim2.new(1, 0, 1, 0)

        if not Window.Minimized then
            local viewport = GetViewportSize()
            local width = math.min(finalSize.X.Offset, math.max(viewport.X - Window.Breakpoints.ViewportPadding, Window.Breakpoints.MinWidth))
            local height = math.min(finalSize.Y.Offset, math.max(viewport.Y - Window.Breakpoints.ViewportPadding, Window.Breakpoints.MinHeight))
            Main.Size = UDim2.fromOffset(width, height)
        end
    end

    local function UpdateResponsive()
        if not Window.Responsive then return end

        local viewport = GetViewportSize()
        local isMobile = viewport.X < Window.Breakpoints.Mobile

        if isMobile == Window.IsMobile then
            return
        end

        Window.IsMobile = isMobile

        if isMobile then
            ApplyMobileLayout()
        else
            ApplyDesktopLayout()
        end

        for _, group in ipairs(Window._Groups) do
            group:_Relayout(isMobile)
        end
    end

    if Window.Responsive then
        local cameraViewportConnection

        local function BindCamera(camera)
            if cameraViewportConnection then
                pcall(function()
                    cameraViewportConnection:Disconnect()
                end)
                cameraViewportConnection = nil
            end

            if camera then
                cameraViewportConnection = Track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateResponsive))
            end
        end

        BindCamera(Workspace.CurrentCamera)

        Track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            BindCamera(Workspace.CurrentCamera)
            UpdateResponsive()
        end))

        UpdateResponsive()
    end

    --------------------------------------------------
    -- PUBLIC WINDOW API
    --------------------------------------------------

    local function UpdateMobileButtonVisibility()
        if not MobileButton then return end
        local canShow = UserInputService.TouchEnabled and (options.ShowMobileButton ~= false)
        MobileButton.Visible = canShow and not Main.Visible
    end

    function Window:Show()
        Main.Visible = true
        UpdateMobileButtonVisibility()
    end

    function Window:Hide()
        Main.Visible = false
        UpdateMobileButtonVisibility()
    end

    function Window:Toggle()
        Main.Visible = not Main.Visible
        UpdateMobileButtonVisibility()
    end

    UpdateMobileButtonVisibility()

    function Window:SetSize(size)
        Window.Size = size
        finalSize = size

        if not Window.Minimized then
            Main.Size = size
        end
    end

    function Window:SetPosition(position)
        Main.Position = position
    end

    function Window:SetTitle(title)
        Window.Title = tostring(title)
        TitleLabel.Text = Window.Title
    end

    function Window:SetSubtitle(subtitle)
        Window.Subtitle = tostring(subtitle)
        SubtitleLabel.Text = Window.Subtitle
    end

    function Window:SetMobileButtonVisible(value)
        if MobileButton then
            MobileButton.Visible = UserInputService.TouchEnabled and value == true and not Main.Visible
        end
    end

    --------------------------------------------------
    -- v5: APPEARANCE / MOTION SYSTEM
    --------------------------------------------------

    local function CopyTheme(theme)
        local copy = {}
        for key, value in pairs(theme or {}) do
            copy[key] = value
        end
        return copy
    end

    local function ApplyCornerRadius()
        local radius = math.max(0, tonumber(Window.Appearance.CornerRadius) or 12)
        for _, instance in ipairs(ScreenGui:GetDescendants()) do
            if instance:IsA("UICorner") and not instance:GetAttribute("NebulaKeepRadius") then
                pcall(function()
                    instance.CornerRadius = UDim.new(0, radius)
                end)
            end
        end
    end

    local function ApplyUIScale()
        if not Window._UIScaleObject then
            local scale = Instance.new("UIScale")
            scale.Name = "NebulaUIScale"
            scale.Parent = Main
            Window._UIScaleObject = scale
        end
        Window._UIScaleObject.Scale = math.clamp(tonumber(Window.Appearance.UIScale) or 1, 0.75, 1.35)
    end

    local function ApplyTextSize()
        local multiplier = math.clamp(tonumber(Window.Appearance.TextSize) or 1, 0.8, 1.25)
        for _, instance in ipairs(ScreenGui:GetDescendants()) do
            if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
                local base = Window._baseTextSizes[instance]
                if type(base) ~= "number" then
                    base = instance.TextSize
                    Window._baseTextSizes[instance] = base
                end
                pcall(function() instance.TextSize = math.max(8, math.floor(base * multiplier + 0.5)) end)
            end
        end
    end

    local function ApplyTransparency()
        local amount = math.clamp(tonumber(Window.Appearance.Transparency) or 0, 0, 0.65)
        local targets = { Main, Header, Content }
        for _, instance in ipairs(targets) do
            if instance and instance.Parent then
                pcall(function() instance.BackgroundTransparency = amount end)
            end
        end
    end

    function Window:SetCornerRadius(value)
        Window.Appearance.CornerRadius = math.max(0, tonumber(value) or 12)
        ApplyCornerRadius()
        return Window
    end

    function Window:SetUIScale(value)
        Window.Appearance.UIScale = math.clamp(tonumber(value) or 1, 0.75, 1.35)
        ApplyUIScale()
        return Window
    end

    function Window:SetTextSize(value)
        Window.Appearance.TextSize = math.clamp(tonumber(value) or 1, 0.8, 1.25)
        ApplyTextSize()
        return Window
    end

    function Window:SetTransparency(value)
        Window.Appearance.Transparency = math.clamp(tonumber(value) or 0, 0, 0.65)
        ApplyTransparency()
        return Window
    end

    function Window:SetAnimationSpeed(value)
        Window.Appearance.AnimationSpeed = math.clamp(tonumber(value) or 1, 0.25, 2)
        return Window
    end

    function Window:SetReducedMotion(value)
        Window.Appearance.ReducedMotion = value == true
        return Window
    end

    function Window:SetAccentColor(color)
        return Window:SetThemeColor("Accent", color)
    end

    function Window:SetThemeColor(key, color)
        if type(key) ~= "string" or typeof(color) ~= "Color3" then return Window end
        Window._CustomThemeColors[key] = color
        local theme = CopyTheme(Window.Theme)
        theme[key] = color
        Window:SetTheme(theme)
        return Window
    end

    function Window:GetTheme()
        return CopyTheme(Window.Theme)
    end

    function Window:GetCustomThemeColors()
        return CopyTheme(Window._CustomThemeColors)
    end

    function Window:ResetAppearance()
        Window.Appearance.CornerRadius = 12
        Window.Appearance.UIScale = 1
        Window.Appearance.TextSize = 1
        Window.Appearance.Transparency = 0
        Window.Appearance.AnimationSpeed = 1
        Window.Appearance.ReducedMotion = false
        table.clear(Window._CustomThemeColors)
        Window:SetTheme(CopyTheme(Window._OriginalTheme or Library.Themes.Nebula))
        ApplyCornerRadius()
        ApplyUIScale()
        ApplyTextSize()
        ApplyTransparency()
        return Window
    end

    Window.Tween = function(a, b, c, d, e, f)
        local instance, properties, duration, style, direction
        if a == Window then instance, properties, duration, style, direction = b, c, d, e, f
        else instance, properties, duration, style, direction = a, b, c, d, e end
        return Tween(instance, properties, duration, style, direction)
    end

    --------------------------------------------------
    -- v5: DEFAULT THEME / SETTINGS TAB
    --------------------------------------------------

    Window:SetTheme(options.Theme or "Nebula")
    Library.CurrentTheme = Window.Theme

    local SettingsTab
    if options.ShowSettings ~= false then
        SettingsTab = Window:AddTab("Settings")
        SettingsTab:AddSection("Appearance")

        SettingsTab:AddDropdown({
            Name = "Theme",
            Values = {"Nebula", "Midnight", "Purple", "Ocean", "Crimson", "Forest", "Light"},
            Default = options.Theme or "Nebula",
            Callback = function(value)
                Window:SetTheme(value)
            end
        })

        SettingsTab:AddSlider({
            Name = "Corner Radius",
            Min = 0, Max = 20, Decimals = 0,
            Default = Window.Appearance.CornerRadius,
            Callback = function(value) Window:SetCornerRadius(value) end
        })

        SettingsTab:AddSlider({
            Name = "UI Scale",
            Min = 0.75, Max = 1.35, Decimals = 2,
            Default = Window.Appearance.UIScale,
            Callback = function(value) Window:SetUIScale(value) end
        })

        SettingsTab:AddSlider({
            Name = "Text Size",
            Min = 0.8, Max = 1.25, Decimals = 2,
            Default = Window.Appearance.TextSize,
            Callback = function(value) Window:SetTextSize(value) end
        })

        SettingsTab:AddSlider({
            Name = "Transparency",
            Min = 0, Max = 0.65, Decimals = 2,
            Default = Window.Appearance.Transparency,
            Callback = function(value) Window:SetTransparency(value) end
        })

        SettingsTab:AddSlider({
            Name = "Animation Speed",
            Min = 0.25, Max = 2, Decimals = 2,
            Default = Window.Appearance.AnimationSpeed,
            Callback = function(value) Window:SetAnimationSpeed(value) end
        })

        SettingsTab:AddToggle({
            Name = "Reduced Motion",
            Default = Window.Appearance.ReducedMotion,
            Description = "Minimize UI animation and transitions.",
            Callback = function(value) Window:SetReducedMotion(value) end
        })

        SettingsTab:AddSection("Custom Theme")

        SettingsTab:AddColorPicker({
            Name = "Accent Color",
            Default = Window.Theme.Accent,
            Callback = function(value) Window:SetThemeColor("Accent", value) end
        })

        SettingsTab:AddColorPicker({
            Name = "Background Color",
            Default = Window.Theme.Background,
            Callback = function(value) Window:SetThemeColor("Background", value) end
        })

        SettingsTab:AddColorPicker({
            Name = "Text Color",
            Default = Window.Theme.Text,
            Callback = function(value) Window:SetThemeColor("Text", value) end
        })

        SettingsTab:AddButton({
            Name = "Reset Appearance",
            Callback = function() Window:ResetAppearance() end
        })
    end

    ApplyCornerRadius()
    ApplyUIScale()
    ApplyTextSize()
    ApplyTransparency()

    --------------------------------------------------
    -- v5: PLUGIN LOADING
    --------------------------------------------------

    Window._LoadedPlugins = {}

    for _, plugin in ipairs(Library.Plugins) do
        table.insert(Window._LoadedPlugins, plugin)

        if plugin.OnLoad then
            local ok, err = pcall(plugin.OnLoad, Window)
            if not ok then
                warn("[Nebula UI] Plugin '" .. tostring(plugin.Name) .. "' OnLoad error: " .. tostring(err))
            end
        end
    end

    --------------------------------------------------
    -- UNLOAD
    --------------------------------------------------

    function Window:Unload(immediate)
        if Window.Destroyed then
            return
        end

        Window.Destroyed = true
        mobilePulseCancelled = true

        for _, element in ipairs(Window.AllElements) do
            if element and element._Cleanup then
                local cleanup = element._Cleanup
                element._Cleanup = nil
                pcall(cleanup, element)
            end
        end

        if rawget(_G, ACTIVE_WINDOW_KEY) == Window then
            rawset(_G, ACTIVE_WINDOW_KEY, nil)
        end

        for _, plugin in ipairs(Window._LoadedPlugins) do
            if plugin.OnUnload then
                pcall(plugin.OnUnload, Window)
            end
        end

        for _, connection in ipairs(Window._connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        if Window.State then
            Window.State:Destroy()
        end

        for _, tab in ipairs(Window.Tabs) do
            if tab and tab.Elements then
                table.clear(tab.Elements)
            end
            if tab and tab._Sections then
                table.clear(tab._Sections)
            end
        end

        table.clear(Window.AllElements)
        table.clear(Window.ElementsByID)
        table.clear(Window._themeBinds)
        table.clear(Window._Groups)
        table.clear(Window._baseTextSizes)
        if CURRENT_APPEARANCE == Window.Appearance then CURRENT_APPEARANCE = nil end

        if immediate then
            pcall(function()
                ScreenGui:Destroy()
            end)
            return
        end

        Tween(Body, { GroupTransparency = 1 }, 0.15)
        Tween(Shadow, { ImageTransparency = 1 }, 0.2)

        local shrink = Tween(Main, {
            Size = UDim2.fromOffset(0, 0)
        }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)

        shrink.Completed:Connect(function()
            if ScreenGui then
                ScreenGui:Destroy()
            end
        end)
    end

    --------------------------------------------------
    -- OPEN ANIMATION
    --------------------------------------------------

    -- Capture whatever size Responsive already settled on (mobile or
    -- desktop) before zeroing out for the scale-in animation.
    local openSize = Main.Size

    Main.Size = UDim2.fromOffset(0, 0)
    Shadow.ImageTransparency = 1
    Body.GroupTransparency = 1

    local openTween = Tween(Main, { Size = openSize }, 0.4, Enum.EasingStyle.Quint)
    Tween(Shadow, { ImageTransparency = 0.4 }, 0.5)

    openTween.Completed:Connect(function()
        Tween(Body, { GroupTransparency = 0 }, 0.25)
    end)

    task.delay(0.15, function()
        if not Window.Destroyed then
            Tween(Body, { GroupTransparency = 0 }, 0.3)
        end
    end)

    --------------------------------------------------
    -- v5: LOADING SCREEN
    --------------------------------------------------

    local function ShowLoadingScreen()
        local overlay = Instance.new("Frame")
        overlay.Name = "Loading"
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.BackgroundColor3 = Window.Theme.Background
        overlay.BorderSizePixel = 0
        overlay.ZIndex = 500
        overlay.Parent = ScreenGui

        local panel = Instance.new("Frame")
        panel.AnchorPoint = Vector2.new(0.5, 0.5)
        panel.Position = UDim2.fromScale(0.5, 0.5)
        panel.Size = UDim2.fromOffset(300, 150)
        panel.BackgroundColor3 = Window.Theme.Secondary
        panel.BorderSizePixel = 0
        panel.Parent = overlay
        Corner(panel, Window.Appearance.CornerRadius, true)
        local panelStroke = Stroke(panel, Window.Theme.Border, 0.35)
        BindTheme(panel, "BackgroundColor3", "Secondary")
        BindTheme(panelStroke, "Color", "Border")

        local title = CreateText(panel, Window.Title, 17, Enum.Font.GothamBold)
        title.Position = UDim2.fromOffset(22, 18)
        title.Size = UDim2.new(1, -44, 0, 24)
        title.TextXAlignment = Enum.TextXAlignment.Center
        BindTheme(title, "TextColor3", "Text")

        local status = CreateText(panel, "Initializing...", 10, Enum.Font.Gotham)
        status.Position = UDim2.fromOffset(22, 52)
        status.Size = UDim2.new(1, -44, 0, 18)
        status.TextXAlignment = Enum.TextXAlignment.Center
        BindTheme(status, "TextColor3", "SubText")

        local bar = Instance.new("Frame")
        bar.Position = UDim2.fromOffset(22, 91)
        bar.Size = UDim2.new(1, -44, 0, 6)
        bar.BackgroundColor3 = Window.Theme.Tertiary
        bar.BorderSizePixel = 0
        bar.Parent = panel
        Corner(bar, 6)
        BindTheme(bar, "BackgroundColor3", "Tertiary")

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Window.Theme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        Corner(fill, 6)
        BindTheme(fill, "BackgroundColor3", "Accent")

        local percent = CreateText(panel, "0%", 10, Enum.Font.GothamBold)
        percent.Position = UDim2.fromOffset(22, 105)
        percent.Size = UDim2.new(1, -44, 0, 18)
        percent.TextXAlignment = Enum.TextXAlignment.Center
        BindTheme(percent, "TextColor3", "Accent")

        local stages = {
            {"Core", 20},
            {"Theme", 45},
            {"Interface", 70},
            {"Responsive layout", 90},
            {"Ready", 100},
        }

        task.spawn(function()
            for _, stage in ipairs(stages) do
                if Window.Destroyed or not overlay.Parent then return end
                status.Text = stage[1] .. "..."
                percent.Text = tostring(stage[2]) .. "%"
                local duration = Window.Appearance.ReducedMotion and 0.01 or (0.12 / math.max(0.25, Window.Appearance.AnimationSpeed))
                Tween(fill, {Size = UDim2.new(stage[2] / 100, 0, 1, 0)}, duration)
                task.wait(duration)
            end

            if Window.Destroyed or not overlay.Parent then return end
            status.Text = "Ready"
            task.wait(Window.Appearance.ReducedMotion and 0.02 or 0.15)
            Tween(overlay, {BackgroundTransparency = 1}, Window.Appearance.ReducedMotion and 0 or 0.22)
            Tween(panel, {BackgroundTransparency = 1}, Window.Appearance.ReducedMotion and 0 or 0.18)
            task.wait(Window.Appearance.ReducedMotion and 0.02 or 0.24)
            if overlay and overlay.Parent then overlay:Destroy() end
            for i = #Window._themeBinds, 1, -1 do
                local binding = Window._themeBinds[i]
                if not binding or not binding.Instance or not binding.Instance.Parent then table.remove(Window._themeBinds, i) end
            end
        end)
    end

    if options.ShowLoading ~= false then
        ShowLoadingScreen()
    end

    -- Always start on the first user tab. Settings is a system tab and must
    -- never steal the initial selection from the script using the library.
    local firstUserTab = nil
    for _, tab in ipairs(Window.Tabs) do
        if tab ~= SettingsTab then
            firstUserTab = tab
            break
        end
    end

    if firstUserTab then
        Window:SelectTab(firstUserTab)
    elseif Window.Tabs[1] then
        Window:SelectTab(Window.Tabs[1])
    end

    --------------------------------------------------
    -- RETURN
    --------------------------------------------------

    rawset(_G, ACTIVE_WINDOW_KEY, Window)

    return Window
end

--------------------------------------------------
-- LIBRARY UNLOAD
--------------------------------------------------

function Library:Unload()
    local activeWindow = rawget(_G, ACTIVE_WINDOW_KEY)

    if activeWindow and type(activeWindow.Unload) == "function" then
        pcall(function()
            activeWindow:Unload()
        end)
    end

    for _, child in ipairs(PlayerGui:GetChildren()) do
        if child.Name == GUI_NAME then
            pcall(function()
                child:Destroy()
            end)
        end
    end
end

--------------------------------------------------
-- RETURN LIBRARY
--------------------------------------------------

return Library
 
