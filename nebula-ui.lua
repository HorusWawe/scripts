--[[
    Nebula UI v2
    Universal Roblox/Luau UI Framework

    Features:
    - Automatic duplicate-instance cleanup
    - Full Unload()
    - Responsive desktop/mobile layout
    - Mobile floating button
    - Window dragging
    - Tabs
    - Sections
    - Button
    - Toggle
    - Slider
    - Dropdown
    - MultiDropdown
    - Textbox
    - Keybind
    - ColorPicker
    - Label / Paragraph
    - Notifications
    - Search
    - Theme system
    - State system
    - Get / Set API
    - Enable / Disable
    - Show / Hide
    - Smooth animations
]]

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    error("[Nebula UI] LocalPlayer is not available.")
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------
-- DUPLICATE CLEANUP
--------------------------------------------------

local GUI_NAME = "__NebulaUI_v2"

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

Library.Version = "2.0.0"
Library.Name = "Nebula UI"

--------------------------------------------------
-- THEMES
--------------------------------------------------

Library.Themes = {

    Midnight = {
        Background = Color3.fromRGB(14, 15, 20),
        Secondary = Color3.fromRGB(19, 20, 27),
        Tertiary = Color3.fromRGB(25, 26, 34),

        Accent = Color3.fromRGB(116, 82, 255),
        AccentDark = Color3.fromRGB(87, 58, 210),

        Text = Color3.fromRGB(245, 245, 248),
        SubText = Color3.fromRGB(155, 157, 170),

        Border = Color3.fromRGB(45, 46, 57),
        Hover = Color3.fromRGB(31, 32, 42),

        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(240, 180, 70),
        Error = Color3.fromRGB(230, 80, 90)
    },

    Ocean = {
        Background = Color3.fromRGB(10, 17, 24),
        Secondary = Color3.fromRGB(14, 25, 34),
        Tertiary = Color3.fromRGB(19, 35, 46),

        Accent = Color3.fromRGB(45, 165, 235),
        AccentDark = Color3.fromRGB(25, 120, 185),

        Text = Color3.fromRGB(240, 248, 255),
        SubText = Color3.fromRGB(145, 165, 180),

        Border = Color3.fromRGB(35, 57, 70),
        Hover = Color3.fromRGB(24, 43, 55),

        Success = Color3.fromRGB(80, 200, 130),
        Warning = Color3.fromRGB(240, 180, 70),
        Error = Color3.fromRGB(230, 80, 90)
    },

    Crimson = {
        Background = Color3.fromRGB(20, 12, 15),
        Secondary = Color3.fromRGB(29, 16, 20),
        Tertiary = Color3.fromRGB(39, 21, 26),

        Accent = Color3.fromRGB(225, 65, 85),
        AccentDark = Color3.fromRGB(180, 40, 60),

        Text = Color3.fromRGB(250, 242, 244),
        SubText = Color3.fromRGB(175, 145, 152),

        Border = Color3.fromRGB(58, 34, 40),
        Hover = Color3.fromRGB(47, 25, 31),

        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(240, 180, 70),
        Error = Color3.fromRGB(240, 70, 80)
    },

    Forest = {
        Background = Color3.fromRGB(11, 18, 14),
        Secondary = Color3.fromRGB(15, 25, 19),
        Tertiary = Color3.fromRGB(21, 34, 25),

        Accent = Color3.fromRGB(75, 190, 115),
        AccentDark = Color3.fromRGB(45, 145, 80),

        Text = Color3.fromRGB(240, 248, 242),
        SubText = Color3.fromRGB(145, 165, 150),

        Border = Color3.fromRGB(35, 57, 42),
        Hover = Color3.fromRGB(24, 42, 30),

        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(240, 180, 70),
        Error = Color3.fromRGB(230, 80, 90)
    },

    Purple = {
        Background = Color3.fromRGB(17, 12, 24),
        Secondary = Color3.fromRGB(24, 17, 34),
        Tertiary = Color3.fromRGB(34, 23, 47),

        Accent = Color3.fromRGB(170, 90, 245),
        AccentDark = Color3.fromRGB(125, 55, 200),

        Text = Color3.fromRGB(247, 242, 250),
        SubText = Color3.fromRGB(165, 145, 180),

        Border = Color3.fromRGB(51, 36, 65),
        Hover = Color3.fromRGB(40, 27, 52),

        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(240, 180, 70),
        Error = Color3.fromRGB(230, 80, 90)
    },

    Light = {
        Background = Color3.fromRGB(242, 243, 247),
        Secondary = Color3.fromRGB(250, 250, 252),
        Tertiary = Color3.fromRGB(232, 233, 239),

        Accent = Color3.fromRGB(105, 75, 230),
        AccentDark = Color3.fromRGB(80, 55, 190),

        Text = Color3.fromRGB(25, 25, 32),
        SubText = Color3.fromRGB(105, 107, 118),

        Border = Color3.fromRGB(215, 216, 224),
        Hover = Color3.fromRGB(225, 226, 234),

        Success = Color3.fromRGB(50, 165, 90),
        Warning = Color3.fromRGB(210, 145, 40),
        Error = Color3.fromRGB(205, 55, 65)
    }
}

Library.CurrentTheme = Library.Themes.Midnight

--------------------------------------------------
-- STATE
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

                if not list then
                    return
                end

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

local function Tween(instance, properties, duration)
    local info = TweenInfo.new(
        duration or 0.2,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(instance, info, properties)
    tween:Play()

    return tween
end

local function Corner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent

    return corner
end

local function Stroke(parent, color, transparency)
    local stroke = Instance.new("UIStroke")

    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Thickness = 1
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
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Parent = parent

    return label
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

    Window.Theme = self.CurrentTheme

    Window.Connections = {}
    Window.Elements = {}
    Window.Tabs = {}

    Window.Destroyed = false
    Window.Minimized = false

    Window.State = self:CreateState()

    --------------------------------------------------
    -- SCREEN GUI
    --------------------------------------------------

    local ScreenGui = Instance.new("ScreenGui")

    ScreenGui.Name = GUI_NAME
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = PlayerGui

    Window.Gui = ScreenGui

    --------------------------------------------------
    -- MAIN WINDOW
    --------------------------------------------------

    local Main = Instance.new("Frame")

    Main.Name = "Main"
    Main.Size = Window.Size
    Main.Position = UDim2.new(0.5, -Window.Size.X.Offset / 2, 0.5, -Window.Size.Y.Offset / 2)

    Main.BackgroundColor3 = Window.Theme.Background
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui

    Corner(Main, options.CornerRadius or 10)
    Stroke(Main, Window.Theme.Border)

    Window.Main = Main

    --------------------------------------------------
    -- SHADOW
    --------------------------------------------------

    local Shadow = Instance.new("ImageLabel")

    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.fromScale(0.5, 0.5)
    Shadow.Size = UDim2.new(1, 45, 1, 45)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6014261993"
    Shadow.ImageTransparency = 0.45
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    Shadow.ZIndex = 0
    Shadow.Parent = Main

    --------------------------------------------------
    -- HEADER
    --------------------------------------------------

    local Header = Instance.new("Frame")

    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 68)
    Header.BackgroundColor3 = Window.Theme.Secondary
    Header.BorderSizePixel = 0
    Header.ZIndex = 2
    Header.Parent = Main

    Corner(Header, options.CornerRadius or 10)

    local HeaderMask = Instance.new("Frame")
    HeaderMask.BackgroundColor3 = Window.Theme.Secondary
    HeaderMask.BorderSizePixel = 0
    HeaderMask.Position = UDim2.new(0, 0, 0.5, 0)
    HeaderMask.Size = UDim2.new(1, 0, 0.5, 0)
    HeaderMask.ZIndex = 2
    HeaderMask.Parent = Header

    local TitleLabel = CreateText(Header, Window.Title, 16, Enum.Font.GothamBold)
    TitleLabel.Position = UDim2.fromOffset(18, 8)
    TitleLabel.Size = UDim2.new(1, -100, 0, 25)
    TitleLabel.TextColor3 = Window.Theme.Text
    TitleLabel.ZIndex = 3

    local SubtitleLabel = CreateText(Header, Window.Subtitle, 11, Enum.Font.Gotham)
    SubtitleLabel.Position = UDim2.fromOffset(18, 34)
    SubtitleLabel.Size = UDim2.new(1, -100, 0, 20)
    SubtitleLabel.TextColor3 = Window.Theme.SubText
    SubtitleLabel.ZIndex = 3

    --------------------------------------------------
    -- MINIMIZE
    --------------------------------------------------

    local Minimize = Instance.new("TextButton")

    Minimize.Name = "Minimize"
    Minimize.Text = "−"
    Minimize.Font = Enum.Font.GothamBold
    Minimize.TextSize = 18
    Minimize.TextColor3 = Window.Theme.Text
    Minimize.BackgroundTransparency = 1
    Minimize.Size = UDim2.fromOffset(35, 35)
    Minimize.Position = UDim2.new(1, -75, 0, 16)
    Minimize.ZIndex = 5
    Minimize.Parent = Header

    --------------------------------------------------
    -- CLOSE
    --------------------------------------------------

    local Close = Instance.new("TextButton")

    Close.Name = "Close"
    Close.Text = "×"
    Close.Font = Enum.Font.GothamBold
    Close.TextSize = 18
    Close.TextColor3 = Window.Theme.Text
    Close.BackgroundTransparency = 1
    Close.Size = UDim2.fromOffset(35, 35)
    Close.Position = UDim2.new(1, -38, 0, 16)
    Close.ZIndex = 5
    Close.Parent = Header

    --------------------------------------------------
    -- BODY
    --------------------------------------------------

    local Body = Instance.new("Frame")

    Body.Name = "Body"
    Body.Position = UDim2.fromOffset(0, 68)
    Body.Size = UDim2.new(1, 0, 1, -68)
    Body.BackgroundTransparency = 1
    Body.Parent = Main

    --------------------------------------------------
    -- SIDEBAR
    --------------------------------------------------

    local Sidebar = Instance.new("Frame")

    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.fromOffset(155, 0)
    Sidebar.BackgroundColor3 = Window.Theme.Secondary
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Body

    local TabList = Instance.new("ScrollingFrame")

    TabList.Name = "TabList"
    TabList.Position = UDim2.fromOffset(8, 8)
    TabList.Size = UDim2.new(1, -16, 1, -16)
    TabList.BackgroundTransparency = 1
    TabList.BorderSizePixel = 0
    TabList.ScrollBarThickness = 2
    TabList.ScrollBarImageColor3 = Window.Theme.Accent
    TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabList.CanvasSize = UDim2.new()
    TabList.Parent = Sidebar

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.Parent = TabList

    --------------------------------------------------
    -- CONTENT
    --------------------------------------------------

    local Content = Instance.new("Frame")

    Content.Name = "Content"
    Content.Position = UDim2.fromOffset(155, 0)
    Content.Size = UDim2.new(1, -155, 1, 0)
    Content.BackgroundColor3 = Window.Theme.Background
    Content.BorderSizePixel = 0
    Content.Parent = Body

    Corner(Content, options.CornerRadius or 10)

    --------------------------------------------------
    -- SEARCH
    --------------------------------------------------

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
    SearchBox.Position = UDim2.new(1, -175, 0, 10)
    SearchBox.Size = UDim2.fromOffset(160, 32)
    SearchBox.Parent = Body

    Corner(SearchBox, 7)
    Stroke(SearchBox, Window.Theme.Border)

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

    Window.Connections.DragBegin = Header.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = Main.Position

            local connection

            connection = input.Changed:Connect(function()

                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false

                    if connection then
                        connection:Disconnect()
                    end
                end

            end)
        end

    end)

    Window.Connections.DragUpdate = UserInputService.InputChanged:Connect(function(input)

        if dragging then

            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

                UpdateDrag(input)

            end

        end

    end)

    --------------------------------------------------
    -- THEME SYSTEM
    --------------------------------------------------

    local ThemeObjects = {}

    local function BindTheme(instance, property, themeKey)
        table.insert(ThemeObjects, {
            Instance = instance,
            Property = property,
            Key = themeKey
        })

        pcall(function()
            instance[property] = Window.Theme[themeKey]
        end)
    end

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

        for _, item in ipairs(ThemeObjects) do

            if item.Instance
            and item.Instance.Parent
            and selected[item.Key] then

                pcall(function()
                    Tween(
                        item.Instance,
                        {
                            [item.Property] = selected[item.Key]
                        },
                        0.18
                    )
                end)

            end

        end

    end

    BindTheme(Main, "BackgroundColor3", "Background")
    BindTheme(Header, "BackgroundColor3", "Secondary")
    BindTheme(HeaderMask, "BackgroundColor3", "Secondary")
    BindTheme(Sidebar, "BackgroundColor3", "Secondary")
    BindTheme(Content, "BackgroundColor3", "Background")

    BindTheme(TitleLabel, "TextColor3", "Text")
    BindTheme(SubtitleLabel, "TextColor3", "SubText")

    BindTheme(SearchBox, "BackgroundColor3", "Tertiary")
    BindTheme(SearchBox, "TextColor3", "Text")
    BindTheme(SearchBox, "PlaceholderColor3", "SubText")

    --------------------------------------------------
    -- NOTIFICATIONS
    --------------------------------------------------

    local NotificationHolder = Instance.new("Frame")

    NotificationHolder.Name = "Notifications"
    NotificationHolder.AnchorPoint = Vector2.new(1, 1)
    NotificationHolder.Position = UDim2.new(1, -20, 1, -20)
    NotificationHolder.Size = UDim2.fromOffset(320, 400)
    NotificationHolder.BackgroundTransparency = 1
    NotificationHolder.ZIndex = 100
    NotificationHolder.Parent = ScreenGui

    local NotificationLayout = Instance.new("UIListLayout")
    NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    NotificationLayout.Padding = UDim.new(0, 8)
    NotificationLayout.Parent = NotificationHolder

    function Window:Notify(data, content, duration)

        if type(data) == "string" then

            data = {
                Title = data,
                Content = content,
                Duration = duration
            }

        end

        data = data or {}

        local notification = Instance.new("Frame")

        notification.Size = UDim2.fromOffset(300, 65)
        notification.BackgroundColor3 = Window.Theme.Secondary
        notification.BorderSizePixel = 0
        notification.ZIndex = 101
        notification.Parent = NotificationHolder

        Corner(notification, 9)
        Stroke(notification, Window.Theme.Border)

        local title = CreateText(
            notification,
            data.Title or "Nebula",
            13,
            Enum.Font.GothamBold
        )

        title.Position = UDim2.fromOffset(13, 8)
        title.Size = UDim2.new(1, -26, 0, 20)
        title.TextColor3 = Window.Theme.Text
        title.ZIndex = 102

        local text = CreateText(
            notification,
            data.Content or "",
            11,
            Enum.Font.Gotham
        )

        text.Position = UDim2.fromOffset(13, 30)
        text.Size = UDim2.new(1, -26, 0, 25)
        text.TextColor3 = Window.Theme.SubText
        text.ZIndex = 102

        notification.Position = UDim2.new(1, 30, 0, 0)

        Tween(
            notification,
            {
                Position = UDim2.new(0, 0, 0, 0)
            },
            0.3
        )

        task.delay(data.Duration or 3, function()

            if notification.Parent then

                Tween(
                    notification,
                    {
                        Position = UDim2.new(1, 30, 0, 0)
                    },
                    0.25
                )

                task.wait(0.3)

                if notification then
                    notification:Destroy()
                end

            end

        end)

        return notification
    end

    --------------------------------------------------
    -- TABS
    --------------------------------------------------

    function Window:SelectTab(tab)

        for _, other in ipairs(Window.Tabs) do

            if other.Content then
                other.Content.Visible = other == tab
            end

            if other.Button then

                Tween(
                    other.Button,
                    {
                        BackgroundColor3 =
                            other == tab
                            and Window.Theme.Accent
                            or Window.Theme.Tertiary
                    },
                    0.15
                )

            end

        end

        Window.ActiveTab = tab
    end

    function Window:AddTab(name, icon)

        local Tab = {}

        Tab.Name = name or "Tab"
        Tab.Elements = {}
        Tab.Content = nil
        Tab.Button = nil

        --------------------------------------------------
        -- TAB BUTTON
        --------------------------------------------------

        local Button = Instance.new("TextButton")

        Button.Name = Tab.Name
        Button.Size = UDim2.new(1, 0, 0, 38)
        Button.BackgroundColor3 = Window.Theme.Tertiary
        Button.BorderSizePixel = 0
        Button.AutoButtonColor = false
        Button.Text = ""
        Button.Parent = TabList

        Corner(Button, 7)

        local buttonText = CreateText(
            Button,
            (icon and tostring(icon) .. "   " or "") .. Tab.Name,
            12,
            Enum.Font.GothamMedium
        )

        buttonText.Position = UDim2.fromOffset(12, 0)
        buttonText.Size = UDim2.new(1, -24, 1, 0)
        buttonText.TextColor3 = Window.Theme.SubText

        Tab.Button = Button

        --------------------------------------------------
        -- TAB CONTENT
        --------------------------------------------------

        local Scroll = Instance.new("ScrollingFrame")

        Scroll.Name = Tab.Name .. "_Content"
        Scroll.Position = UDim2.fromOffset(12, 48)
        Scroll.Size = UDim2.new(1, -24, 1, -60)
        Scroll.BackgroundTransparency = 1
        Scroll.BorderSizePixel = 0
        Scroll.ScrollBarThickness = 2
        Scroll.ScrollBarImageColor3 = Window.Theme.Accent
        Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Scroll.CanvasSize = UDim2.new()
        Scroll.Visible = false
        Scroll.Parent = Content

        local Layout = Instance.new("UIListLayout")

        Layout.Padding = UDim.new(0, 8)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = Scroll

        Tab.Content = Scroll

        table.insert(Window.Tabs, Tab)

        --------------------------------------------------
        -- TAB SELECT
        --------------------------------------------------

        Button.MouseButton1Click:Connect(function()
            Window:SelectTab(Tab)
        end)

        --------------------------------------------------
        -- SEARCH
        --------------------------------------------------

        function Tab:_Search(query)

            query = string.lower(query or "")

            for _, element in ipairs(Tab.Elements) do

                if element.Root then

                    local name = string.lower(element.Name or "")

                    local visible =
                        query == ""
                        or string.find(name, query, 1, true) ~= nil

                    element.Root.Visible = visible

                end

            end

        end

        --------------------------------------------------
        -- SECTION
        --------------------------------------------------

        function Tab:AddSection(title)

            local section = Instance.new("TextLabel")

            section.Name = "Section"
            section.Size = UDim2.new(1, 0, 0, 26)
            section.BackgroundTransparency = 1
            section.Text = string.upper(title or "SECTION")
            section.TextColor3 = Window.Theme.SubText
            section.TextSize = 10
            section.Font = Enum.Font.GothamBold
            section.TextXAlignment = Enum.TextXAlignment.Left
            section.Parent = Scroll

            return section
        end

        --------------------------------------------------
        -- LABEL
        --------------------------------------------------

        function Tab:AddLabel(text)

            local holder = Instance.new("Frame")

            holder.Name = "Label"
            holder.Size = UDim2.new(1, 0, 0, 35)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = Scroll

            Corner(holder, 7)

            local label = CreateText(
                holder,
                text,
                12,
                Enum.Font.Gotham
            )

            label.Position = UDim2.fromOffset(12, 0)
            label.Size = UDim2.new(1, -24, 1, 0)
            label.TextColor3 = Window.Theme.Text

            return {
                Root = holder,
                Set = function(_, value)
                    label.Text = tostring(value)
                end
            }
        end

        --------------------------------------------------
        -- PARAGRAPH
        --------------------------------------------------

        function Tab:AddParagraph(title, text)

            local holder = Instance.new("Frame")

            holder.Name = "Paragraph"
            holder.Size = UDim2.new(1, 0, 0, 65)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = Scroll

            Corner(holder, 8)

            local titleLabel = CreateText(
                holder,
                title or "Information",
                12,
                Enum.Font.GothamBold
            )

            titleLabel.Position = UDim2.fromOffset(12, 7)
            titleLabel.Size = UDim2.new(1, -24, 0, 20)
            titleLabel.TextColor3 = Window.Theme.Text

            local textLabel = CreateText(
                holder,
                text or "",
                10,
                Enum.Font.Gotham
            )

            textLabel.Position = UDim2.fromOffset(12, 29)
            textLabel.Size = UDim2.new(1, -24, 0, 28)
            textLabel.TextColor3 = Window.Theme.SubText
            textLabel.TextWrapped = true

            return {
                Root = holder,

                Set = function(_, newTitle, newText)
                    titleLabel.Text = tostring(newTitle)
                    textLabel.Text = tostring(newText)
                end
            }
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
            holder.Size = UDim2.new(1, 0, 0, options.Description and 62 or 48)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = Scroll

            Corner(holder, 8)
            Stroke(holder, Window.Theme.Border)

            local button = Instance.new("TextButton")

            button.Size = UDim2.new(1, -12, 1, -12)
            button.Position = UDim2.fromOffset(6, 6)
            button.BackgroundColor3 = Window.Theme.Tertiary
            button.BorderSizePixel = 0
            button.AutoButtonColor = false
            button.Text = ""
            button.Parent = holder

            Corner(button, 7)

            local label = CreateText(
                button,
                Element.Name,
                12,
                Enum.Font.GothamMedium
            )

            label.Position = UDim2.fromOffset(12, 0)
            label.Size = UDim2.new(1, -24, 1, 0)
            label.TextColor3 = Window.Theme.Text

            if options.Description then

                local desc = CreateText(
                    holder,
                    options.Description,
                    10,
                    Enum.Font.Gotham
                )

                desc.Position = UDim2.fromOffset(12, 31)
                desc.Size = UDim2.new(1, -24, 0, 20)
                desc.TextColor3 = Window.Theme.SubText

            end

            button.MouseEnter:Connect(function()
                Tween(button, {
                    BackgroundColor3 = Window.Theme.Hover
                }, 0.12)
            end)

            button.MouseLeave:Connect(function()
                Tween(button, {
                    BackgroundColor3 = Window.Theme.Tertiary
                }, 0.12)
            end)

            button.MouseButton1Click:Connect(function()

                Tween(button, {
                    BackgroundColor3 = Window.Theme.Accent
                }, 0.08)

                task.delay(0.1, function()

                    if button.Parent then
                        Tween(button, {
                            BackgroundColor3 = Window.Theme.Tertiary
                        }, 0.12)
                    end

                end)

                if options.Callback then
                    task.spawn(options.Callback)
                end

            end)

            Element.Root = holder

            table.insert(Tab.Elements, Element)

            return Element
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
            holder.Size = UDim2.new(1, 0, 0, 52)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = Scroll

            Corner(holder, 8)
            Stroke(holder, Window.Theme.Border)

            local title = CreateText(
                holder,
                Element.Name,
                12,
                Enum.Font.GothamMedium
            )

            title.Position = UDim2.fromOffset(12, 5)
            title.Size = UDim2.new(1, -75, 0, 22)
            title.TextColor3 = Window.Theme.Text

            if options.Description then

                local desc = CreateText(
                    holder,
                    options.Description,
                    9,
                    Enum.Font.Gotham
                )

                desc.Position = UDim2.fromOffset(12, 27)
                desc.Size = UDim2.new(1, -75, 0, 18)
                desc.TextColor3 = Window.Theme.SubText

            end

            local switch = Instance.new("Frame")

            switch.Size = UDim2.fromOffset(42, 22)
            switch.Position = UDim2.new(1, -54, 0.5, -11)
            switch.BackgroundColor3 =
                Element.Value
                and Window.Theme.Accent
                or Window.Theme.Tertiary

            switch.BorderSizePixel = 0
            switch.Parent = holder

            Corner(switch, 20)

            local knob = Instance.new("Frame")

            knob.Size = UDim2.fromOffset(16, 16)
            knob.Position =
                Element.Value
                and UDim2.new(1, -19, 0.5, -8)
                or UDim2.fromOffset(3, 3)

            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.Parent = switch

            Corner(knob, 20)

            local click = Instance.new("TextButton")

            click.Size = UDim2.fromScale(1, 1)
            click.BackgroundTransparency = 1
            click.Text = ""
            click.Parent = holder

            function Element:Set(value)

                Element.Value = value == true

                Tween(
                    switch,
                    {
                        BackgroundColor3 =
                            Element.Value
                            and Window.Theme.Accent
                            or Window.Theme.Tertiary
                    },
                    0.18
                )

                Tween(
                    knob,
                    {
                        Position =
                            Element.Value
                            and UDim2.new(1, -19, 0.5, -8)
                            or UDim2.fromOffset(3, 3)
                    },
                    0.18
                )

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

            click.MouseButton1Click:Connect(function()
                Element:Set(not Element.Value)
            end)

            Element.Root = holder

            table.insert(Tab.Elements, Element)

            if options.StateKey then
                Window.State:Set(options.StateKey, Element.Value)

                Element._StateConnection =
                    Window.State:Bind(options.StateKey, function(value)
                        if Element.Value ~= value then
                            Element:Set(value)
                        end
                    end)
            end

            return Element
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

            local value = options.Default or min

            value = math.clamp(value, min, max)

            Element.Value = value

            local holder = Instance.new("Frame")

            holder.Name = Element.Name
            holder.Size = UDim2.new(1, 0, 0, 62)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = Scroll

            Corner(holder, 8)
            Stroke(holder, Window.Theme.Border)

            local title = CreateText(
                holder,
                Element.Name,
                12,
                Enum.Font.GothamMedium
            )

            title.Position = UDim2.fromOffset(12, 6)
            title.Size = UDim2.new(1, -70, 0, 20)
            title.TextColor3 = Window.Theme.Text

            local valueLabel = CreateText(
                holder,
                tostring(value),
                11,
                Enum.Font.GothamMedium
            )

            valueLabel.Position = UDim2.new(1, -65, 0, 6)
            valueLabel.Size = UDim2.fromOffset(53, 20)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.TextColor3 = Window.Theme.Accent

            local bar = Instance.new("Frame")

            bar.Position = UDim2.fromOffset(12, 38)
            bar.Size = UDim2.new(1, -24, 0, 6)
            bar.BackgroundColor3 = Window.Theme.Tertiary
            bar.BorderSizePixel = 0
            bar.Parent = holder

            Corner(bar, 10)

            local fill = Instance.new("Frame")

            fill.Size = UDim2.new(
                (value - min) / (max - min),
                0,
                1,
                0
            )

            fill.BackgroundColor3 = Window.Theme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = bar

            Corner(fill, 10)

            local draggingSlider = false

            local function SetFromPosition(x)

                local relative =
                    math.clamp(
                        (x - bar.AbsolutePosition.X)
                        / bar.AbsoluteSize.X,
                        0,
                        1
                    )

                local newValue =
                    min + (max - min) * relative

                local rounding = options.Rounding

                if rounding ~= nil then

                    local multiplier = 10 ^ rounding
                    newValue =
                        math.floor(newValue * multiplier + 0.5)
                        / multiplier

                end

                Element:Set(newValue)
            end

            local input = Instance.new("TextButton")

            input.Size = UDim2.fromScale(1, 1)
            input.BackgroundTransparency = 1
            input.Text = ""
            input.Parent = bar

            function Element:Set(newValue)

                newValue = math.clamp(
                    tonumber(newValue) or min,
                    min,
                    max
                )

                Element.Value = newValue

                local percent =
                    (newValue - min) / (max - min)

                Tween(
                    fill,
                    {
                        Size = UDim2.new(percent, 0, 1, 0)
                    },
                    0.12
                )

                valueLabel.Text = tostring(newValue)

                if options.Callback then
                    task.spawn(options.Callback, newValue)
                end

            end

            function Element:Get()
                return Element.Value
            end

            input.InputBegan:Connect(function(i)

                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then

                    draggingSlider = true
                    SetFromPosition(i.Position.X)

                end

            end)

            UserInputService.InputChanged:Connect(function(i)

                if draggingSlider then

                    if i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch then

                        SetFromPosition(i.Position.X)

                    end

                end

            end)

            UserInputService.InputEnded:Connect(function(i)

                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then

                    draggingSlider = false

                end

            end)

            Element.Root = holder

            table.insert(Tab.Elements, Element)

            return Element
        end

        --------------------------------------------------
        -- DROPDOWN
        --------------------------------------------------

        function Tab:AddDropdown(options)

            options = options or {}

            local Element = {}

            Element.Name = options.Name or "Dropdown"
            Element.Values = options.Values or {}
            Element.Value = options.Default or Element.Values[1]
            Element.Open = false

            local holder = Instance.new("Frame")

            holder.Name = Element.Name
            holder.Size = UDim2.new(1, 0, 0, 52)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.ClipsDescendants = true
            holder.Parent = Scroll

            Corner(holder, 8)
            Stroke(holder, Window.Theme.Border)

            local title = CreateText(
                holder,
                Element.Name,
                12,
                Enum.Font.GothamMedium
            )

            title.Position = UDim2.fromOffset(12, 6)
            title.Size = UDim2.new(1, -180, 0, 20)
            title.TextColor3 = Window.Theme.Text

            local selected = Instance.new("TextButton")

            selected.Position = UDim2.new(1, -165, 0, 7)
            selected.Size = UDim2.fromOffset(153, 38)
            selected.BackgroundColor3 = Window.Theme.Tertiary
            selected.BorderSizePixel = 0
            selected.Text = tostring(Element.Value or "Select...")
            selected.TextColor3 = Window.Theme.Text
            selected.TextSize = 11
            selected.Font = Enum.Font.Gotham
            selected.AutoButtonColor = false
            selected.Parent = holder

            Corner(selected, 6)

            local list = Instance.new("Frame")

            list.Position = UDim2.fromOffset(12, 54)
            list.Size = UDim2.new(1, -24, 0, 0)
            list.BackgroundTransparency = 1
            list.Parent = holder

            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 4)
            listLayout.Parent = list

            local function Rebuild()

                for _, child in ipairs(list:GetChildren()) do

                    if child:IsA("TextButton") then
                        child:Destroy()
                    end

                end

                for _, option in ipairs(Element.Values) do

                    local item = Instance.new("TextButton")

                    item.Size = UDim2.new(1, 0, 0, 30)
                    item.BackgroundColor3 = Window.Theme.Tertiary
                    item.BorderSizePixel = 0
                    item.Text = tostring(option)
                    item.TextColor3 = Window.Theme.Text
                    item.TextSize = 11
                    item.Font = Enum.Font.Gotham
                    item.AutoButtonColor = false
                    item.Parent = list

                    Corner(item, 5)

                    item.MouseButton1Click:Connect(function()

                        Element:Set(option)
                        Element:Close()

                    end)

                end

            end

            function Element:Set(value)

                Element.Value = value
                selected.Text = tostring(value)

                if options.Callback then
                    task.spawn(options.Callback, value)
                end

            end

            function Element:Get()
                return Element.Value
            end

            function Element:OpenDropdown()

                if Element.Open then
                    return
                end

                Element.Open = true

                local height =
                    #Element.Values * 34 + 4

                Tween(
                    list,
                    {
                        Size = UDim2.new(1, -24, 0, height)
                    },
                    0.2
                )

                Tween(
                    holder,
                    {
                        Size = UDim2.new(1, 0, 0, 58 + height)
                    },
                    0.2
                )

            end

            function Element:Close()

                Element.Open = false

                Tween(
                    list,
                    {
                        Size = UDim2.new(1, -24, 0, 0)
                    },
                    0.18
                )

                Tween(
                    holder,
                    {
                        Size = UDim2.new(1, 0, 0, 52)
                    },
                    0.18
                )

            end

            selected.MouseButton1Click:Connect(function()

                if Element.Open then
                    Element:Close()
                else
                    Element:OpenDropdown()
                end

            end)

            Rebuild()

            Element.Root = holder

            table.insert(Tab.Elements, Element)

            return Element
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

            for _, value in ipairs(options.Default or {}) do
                Element.Selected[value] = true
            end

            local holder = Instance.new("Frame")

            holder.Name = Element.Name
            holder.Size = UDim2.new(1, 0, 0, 52)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.ClipsDescendants = true
            holder.Parent = Scroll

            Corner(holder, 8)
            Stroke(holder, Window.Theme.Border)

            local title = CreateText(
                holder,
                Element.Name,
                12,
                Enum.Font.GothamMedium
            )

            title.Position = UDim2.fromOffset(12, 6)
            title.Size = UDim2.new(1, -180, 0, 20)
            title.TextColor3 = Window.Theme.Text

            local selected = Instance.new("TextButton")

            selected.Position = UDim2.new(1, -165, 0, 7)
            selected.Size = UDim2.fromOffset(153, 38)
            selected.BackgroundColor3 = Window.Theme.Tertiary
            selected.BorderSizePixel = 0
            selected.TextColor3 = Window.Theme.Text
            selected.TextSize = 10
            selected.Font = Enum.Font.Gotham
            selected.AutoButtonColor = false
            selected.Text = "Select..."
            selected.Parent = holder

            Corner(selected, 6)

            local list = Instance.new("Frame")

            list.Position = UDim2.fromOffset(12, 54)
            list.Size = UDim2.new(1, -24, 0, 0)
            list.BackgroundTransparency = 1
            list.Parent = holder

            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 4)
            layout.Parent = list

            local function UpdateText()

                local result = {}

                for _, value in ipairs(Element.Values) do

                    if Element.Selected[value] then
                        table.insert(result, tostring(value))
                    end

                end

                selected.Text =
                    #result > 0
                    and table.concat(result, ", ")
                    or "Select..."

            end

            for _, value in ipairs(Element.Values) do

                local item = Instance.new("TextButton")

                item.Size = UDim2.new(1, 0, 0, 30)
                item.BackgroundColor3 = Window.Theme.Tertiary
                item.BorderSizePixel = 0
                item.Text = tostring(value)
                item.TextSize = 11
                item.Font = Enum.Font.Gotham
                item.TextColor3 = Window.Theme.Text
                item.AutoButtonColor = false
                item.Parent = list

                Corner(item, 5)

                item.MouseButton1Click:Connect(function()

                    Element.Selected[value] =
                        not Element.Selected[value]

                    UpdateText()

                    if options.Callback then
                        task.spawn(
                            options.Callback,
                            Element:Get()
                        )
                    end

                end)

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

                table.clear(Element.Selected)

                for _, value in ipairs(values or {}) do
                    Element.Selected[value] = true
                end

                UpdateText()

            end

            local open = false

            selected.MouseButton1Click:Connect(function()

                open = not open

                local height =
                    open
                    and (#Element.Values * 34 + 4)
                    or 0

                Tween(
                    list,
                    {
                        Size = UDim2.new(1, -24, 0, height)
                    },
                    0.2
                )

                Tween(
                    holder,
                    {
                        Size =
                            UDim2.new(
                                1,
                                0,
                                0,
                                open and (58 + height) or 52
                            )
                    },
                    0.2
                )

            end)

            UpdateText()

            Element.Root = holder

            table.insert(Tab.Elements, Element)

            return Element
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
            holder.Size = UDim2.new(1, 0, 0, 58)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = Scroll

            Corner(holder, 8)
            Stroke(holder, Window.Theme.Border)

            local title = CreateText(
                holder,
                Element.Name,
                11,
                Enum.Font.GothamMedium
            )

            title.Position = UDim2.fromOffset(12, 5)
            title.Size = UDim2.new(1, -210, 0, 20)
            title.TextColor3 = Window.Theme.Text

            local box = Instance.new("TextBox")

            box.Position = UDim2.new(1, -200, 0, 8)
            box.Size = UDim2.fromOffset(188, 38)
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

            Corner(box, 6)

            box.FocusLost:Connect(function()

                Element.Value = box.Text

                if options.Callback then
                    task.spawn(options.Callback, Element.Value)
                end

            end)

            function Element:Set(value)

                Element.Value = tostring(value or "")
                box.Text = Element.Value

            end

            function Element:Get()
                return Element.Value
            end

            Element.Root = holder

            table.insert(Tab.Elements, Element)

            return Element
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
            holder.Size = UDim2.new(1, 0, 0, 48)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = Scroll

            Corner(holder, 8)
            Stroke(holder, Window.Theme.Border)

            local title = CreateText(
                holder,
                Element.Name,
                12,
                Enum.Font.GothamMedium
            )

            title.Position = UDim2.fromOffset(12, 0)
            title.Size = UDim2.new(1, -150, 1, 0)
            title.TextColor3 = Window.Theme.Text

            local key = Instance.new("TextButton")

            key.Position = UDim2.new(1, -130, 0, 7)
            key.Size = UDim2.fromOffset(118, 34)
            key.BackgroundColor3 = Window.Theme.Tertiary
            key.BorderSizePixel = 0
            key.Text = Element.Value.Name
            key.TextColor3 = Window.Theme.Text
            key.TextSize = 10
            key.Font = Enum.Font.Gotham
            key.Parent = holder

            Corner(key, 6)

            local listening = false

            key.MouseButton1Click:Connect(function()

                listening = true
                key.Text = "Press key..."

            end)

            UserInputService.InputBegan:Connect(function(input, processed)

                if processed then
                    return
                end

                if listening then

                    if input.KeyCode ~= Enum.KeyCode.Unknown then

                        Element.Value = input.KeyCode
                        key.Text = input.KeyCode.Name
                        listening = false

                    end

                    return
                end

                if input.KeyCode == Element.Value then

                    if options.Callback then
                        task.spawn(options.Callback)
                    end

                end

            end)

            function Element:Set(value)

                if typeof(value) == "EnumItem" then
                    Element.Value = value
                    key.Text = value.Name
                end

            end

            function Element:Get()
                return Element.Value
            end

            Element.Root = holder

            table.insert(Tab.Elements, Element)

            return Element
        end

        --------------------------------------------------
        -- COLOR PICKER
        --------------------------------------------------

        function Tab:AddColorPicker(options)

            options = options or {}

            local Element = {}

            Element.Name = options.Name or "Color"
            Element.Value =
                options.Default
                or Color3.fromRGB(116, 82, 255)

            local holder = Instance.new("Frame")

            holder.Name = Element.Name
            holder.Size = UDim2.new(1, 0, 0, 48)
            holder.BackgroundColor3 = Window.Theme.Secondary
            holder.BorderSizePixel = 0
            holder.Parent = Scroll

            Corner(holder, 8)
            Stroke(holder, Window.Theme.Border)

            local title = CreateText(
                holder,
                Element.Name,
                12,
                Enum.Font.GothamMedium
            )

            title.Position = UDim2.fromOffset(12, 0)
            title.Size = UDim2.new(1, -70, 1, 0)
            title.TextColor3 = Window.Theme.Text

            local color = Instance.new("TextButton")

            color.Position = UDim2.new(1, -52, 0, 10)
            color.Size = UDim2.fromOffset(40, 28)
            color.BackgroundColor3 = Element.Value
            color.BorderSizePixel = 0
            color.Text = ""
            color.Parent = holder

            Corner(color, 6)

            function Element:Set(value)

                if typeof(value) == "Color3" then

                    Element.Value = value
                    color.BackgroundColor3 = value

                    if options.Callback then
                        task.spawn(options.Callback, value)
                    end

                end

            end

            function Element:Get()
                return Element.Value
            end

            -- Intentionally simple color API.
            -- A full HSV picker can be attached as an extension.

            color.MouseButton1Click:Connect(function()

                Window:Notify({
                    Title = "ColorPicker",
                    Content = "Current color: "
                        .. tostring(Element.Value),
                    Duration = 2
                })

            end)

            Element.Root = holder

            table.insert(Tab.Elements, Element)

            return Element
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
            frame.Parent = Scroll

            Corner(frame, 8)
            Stroke(frame, Window.Theme.Border)

            local layout = Instance.new("UIListLayout")

            layout.Padding = UDim.new(0, 6)
            layout.Parent = frame

            Padding(frame, 8, 8, 8, 8)

            Container.Root = frame

            function Container:AddLabel(text)

                local label = CreateText(
                    frame,
                    text,
                    11,
                    Enum.Font.Gotham
                )

                label.Size = UDim2.new(1, 0, 0, 25)
                label.TextColor3 = Window.Theme.Text

                return label
            end

            function Container:Destroy()

                if frame then
                    frame:Destroy()
                end

            end

            return Container
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

    Window.Connections.Search =
        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()

            local query = string.lower(SearchBox.Text)

            for _, tab in ipairs(Window.Tabs) do

                tab:_Search(query)

            end

        end)

    --------------------------------------------------
    -- MINIMIZE
    --------------------------------------------------

    local savedSize = Window.Size

    Minimize.MouseButton1Click:Connect(function()

        Window.Minimized = not Window.Minimized

        if Window.Minimized then

            savedSize = Main.Size

            Tween(
                Main,
                {
                    Size = UDim2.fromOffset(savedSize.X.Offset, 68)
                },
                0.25
            )

            Body.Visible = false
            SearchBox.Visible = false

        else

            Body.Visible = true
            SearchBox.Visible = true

            Tween(
                Main,
                {
                    Size = savedSize
                },
                0.25
            )

        end

    end)

    --------------------------------------------------
    -- CLOSE
    --------------------------------------------------

    Close.MouseButton1Click:Connect(function()
        Window:Unload()
    end)

    --------------------------------------------------
    -- MOBILE BUTTON
    --------------------------------------------------

    local MobileButton = Instance.new("TextButton")

    MobileButton.Name = "MobileButton"
    MobileButton.Size = UDim2.fromOffset(52, 52)
    MobileButton.Position = UDim2.new(1, -70, 1, -90)
    MobileButton.BackgroundColor3 = Window.Theme.Accent
    MobileButton.BorderSizePixel = 0
    MobileButton.Text = "N"
    MobileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MobileButton.TextSize = 20
    MobileButton.Font = Enum.Font.GothamBold
    MobileButton.Visible = UserInputService.TouchEnabled
    MobileButton.ZIndex = 200
    MobileButton.Parent = ScreenGui

    Corner(MobileButton, 16)

    MobileButton.MouseButton1Click:Connect(function()

        Main.Visible = not Main.Visible

    end)

    --------------------------------------------------
    -- PUBLIC WINDOW API
    --------------------------------------------------

    function Window:Show()
        Main.Visible = true
    end

    function Window:Hide()
        Main.Visible = false
    end

    function Window:Toggle()
        Main.Visible = not Main.Visible
    end

    function Window:SetSize(size)
        Window.Size = size

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
        MobileButton.Visible =
            UserInputService.TouchEnabled
            and value == true
    end

    --------------------------------------------------
    -- UNLOAD
    --------------------------------------------------

    function Window:Unload()

        if Window.Destroyed then
            return
        end

        Window.Destroyed = true

        for _, connection in pairs(Window.Connections) do

            pcall(function()
                connection:Disconnect()
            end)

        end

        Window.State:Destroy()

        Tween(
            Main,
            {
                Size = UDim2.fromOffset(0, 0)
            },
            0.2
        )

        task.wait(0.2)

        if ScreenGui then
            ScreenGui:Destroy()
        end

    end

    --------------------------------------------------
    -- OPEN ANIMATION
    --------------------------------------------------

    local finalSize = Window.Size

    Main.Size = UDim2.fromOffset(0, 0)

    Tween(
        Main,
        {
            Size = finalSize
        },
        0.35
    )

    --------------------------------------------------
    -- DEFAULT THEME
    --------------------------------------------------

    Window:SetTheme(
        options.Theme
        or "Midnight"
    )

    --------------------------------------------------
    -- RETURN
    --------------------------------------------------

    return Window
end

--------------------------------------------------
-- LIBRARY UNLOAD
--------------------------------------------------

function Library:Unload()

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
