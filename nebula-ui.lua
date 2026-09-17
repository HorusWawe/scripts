--[[
    ╔══════════════════════════════════════════════════════╗
    ║                    NEBULA UI                        ║
    ║              Pure Roblox/Luau UI                    ║
    ║                                                      ║
    ║  No external libraries                              ║
    ║  No HTTP / GitHub loaders                            ║
    ║  No executor-specific API                            ║
    ╚══════════════════════════════════════════════════════╝
]]

local Nebula = {}

--========================================================--
-- SERVICES
--========================================================--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- CONFIG
--========================================================--

Nebula.Version = "1.0.0"

Nebula.Themes = {
	Midnight = {
		Background = Color3.fromRGB(15, 16, 21),
		Sidebar = Color3.fromRGB(19, 20, 27),
		Panel = Color3.fromRGB(24, 25, 33),
		PanelHover = Color3.fromRGB(31, 32, 42),

		Accent = Color3.fromRGB(117, 92, 255),
		AccentDark = Color3.fromRGB(91, 70, 210),

		Text = Color3.fromRGB(240, 240, 245),
		SubText = Color3.fromRGB(150, 152, 165),

		Border = Color3.fromRGB(45, 46, 57),
		Off = Color3.fromRGB(60, 61, 72),

		Success = Color3.fromRGB(80, 210, 130),
		Error = Color3.fromRGB(235, 80, 90),
		Warning = Color3.fromRGB(240, 180, 70)
	},

	Ocean = {
		Background = Color3.fromRGB(13, 19, 25),
		Sidebar = Color3.fromRGB(16, 25, 33),
		Panel = Color3.fromRGB(21, 31, 41),
		PanelHover = Color3.fromRGB(28, 42, 55),

		Accent = Color3.fromRGB(55, 170, 230),
		AccentDark = Color3.fromRGB(35, 125, 180),

		Text = Color3.fromRGB(235, 242, 247),
		SubText = Color3.fromRGB(145, 160, 170),

		Border = Color3.fromRGB(42, 58, 70),
		Off = Color3.fromRGB(58, 72, 82),

		Success = Color3.fromRGB(70, 210, 140),
		Error = Color3.fromRGB(235, 85, 95),
		Warning = Color3.fromRGB(240, 180, 70)
	},

	Crimson = {
		Background = Color3.fromRGB(20, 14, 17),
		Sidebar = Color3.fromRGB(26, 17, 21),
		Panel = Color3.fromRGB(33, 21, 26),
		PanelHover = Color3.fromRGB(44, 27, 33),

		Accent = Color3.fromRGB(225, 65, 85),
		AccentDark = Color3.fromRGB(175, 45, 65),

		Text = Color3.fromRGB(245, 238, 240),
		SubText = Color3.fromRGB(165, 145, 150),

		Border = Color3.fromRGB(62, 42, 48),
		Off = Color3.fromRGB(75, 60, 65),

		Success = Color3.fromRGB(80, 210, 130),
		Error = Color3.fromRGB(240, 70, 80),
		Warning = Color3.fromRGB(240, 180, 70)
	},

	Forest = {
		Background = Color3.fromRGB(14, 20, 16),
		Sidebar = Color3.fromRGB(18, 26, 21),
		Panel = Color3.fromRGB(23, 34, 27),
		PanelHover = Color3.fromRGB(31, 45, 35),

		Accent = Color3.fromRGB(75, 190, 110),
		AccentDark = Color3.fromRGB(55, 145, 85),

		Text = Color3.fromRGB(235, 245, 237),
		SubText = Color3.fromRGB(145, 165, 150),

		Border = Color3.fromRGB(42, 60, 48),
		Off = Color3.fromRGB(60, 75, 65),

		Success = Color3.fromRGB(80, 215, 125),
		Error = Color3.fromRGB(235, 80, 90),
		Warning = Color3.fromRGB(240, 180, 70)
	}
}

Nebula.CurrentTheme = Nebula.Themes.Midnight

--========================================================--
-- UTILITIES
--========================================================--

local function New(className, properties, parent)
	local object = Instance.new(className)

	for property, value in pairs(properties or {}) do
		object[property] = value
	end

	object.Parent = parent

	return object
end

local function Corner(parent, radius)
	return New("UICorner", {
		CornerRadius = UDim.new(0, radius or 8)
	}, parent)
end

local function Stroke(parent, color, thickness, transparency)
	return New("UIStroke", {
		Color = color or Nebula.CurrentTheme.Border,
		Thickness = thickness or 1,
		Transparency = transparency or 0
	}, parent)
end

local function Tween(object, duration, properties)
	if not object or not object.Parent then
		return
	end

	return TweenService:Create(
		object,
		TweenInfo.new(
			duration or 0.15,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		properties
	)
end

local function SafeCallback(callback, ...)
	if type(callback) ~= "function" then
		return
	end

	local success, errorMessage = pcall(callback, ...)

	if not success then
		warn("[Nebula UI] Callback error:", errorMessage)
	end
end

local function Disconnect(connection)
	if connection then
		pcall(function()
			connection:Disconnect()
		end)
	end
end

--========================================================--
-- DRAGGING
--========================================================--

local function MakeDraggable(window, handle)
	local dragging = false
	local dragStart
	local startPosition
	local dragInput

	local began = handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPosition = window.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	local changed = handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

			dragInput = input
		end
	end)

	local moved = UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart

			window.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)

	return {
		began,
		changed,
		moved
	}
end

--========================================================--
-- WINDOW
--========================================================--

local Window = {}
Window.__index = Window

function Window:_ApplyTheme()
	local theme = self.Theme

	if self.Main then
		self.Main.BackgroundColor3 = theme.Background
	end

	if self.Sidebar then
		self.Sidebar.BackgroundColor3 = theme.Sidebar
	end

	if self.Content then
		self.Content.BackgroundColor3 = theme.Background
	end

	if self.Header then
		self.Header.BackgroundColor3 = theme.Sidebar
	end

	for _, tab in ipairs(self.Tabs) do
		tab.Button.BackgroundColor3 = theme.Panel
	end
end

function Window:SetTheme(theme)
	if type(theme) == "string" then
		theme = Nebula.Themes[theme]

		if not theme then
			warn("[Nebula UI] Unknown theme.")
			return
		end
	end

	if type(theme) ~= "table" then
		return
	end

	for key, value in pairs(theme) do
		if self.Theme[key] ~= nil then
			self.Theme[key] = value
		end
	end

	self:_ApplyTheme()

	return self
end

function Window:Notify(options)
	options = options or {}

	local title = options.Title or "Nebula"
	local content = options.Content or ""
	local duration = tonumber(options.Duration) or 3
	local notificationType = options.Type or "Info"

	local theme = self.Theme

	local color = theme.Accent

	if notificationType == "Success" then
		color = theme.Success
	elseif notificationType == "Error" then
		color = theme.Error
	elseif notificationType == "Warning" then
		color = theme.Warning
	end

	local notification = New("Frame", {
		Name = "Notification",
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,

		Size = UDim2.new(1, 0, 0, 72),

		ClipsDescendants = true
	}, self.NotificationContainer)

	Corner(notification, 8)
	Stroke(notification, theme.Border)

	local accent = New("Frame", {
		BackgroundColor3 = color,
		BorderSizePixel = 0,

		Size = UDim2.new(0, 4, 1, 0)
	}, notification)

	Corner(accent, 4)

	local titleLabel = New("TextLabel", {
		BackgroundTransparency = 1,

		Position = UDim2.new(0, 15, 0, 9),
		Size = UDim2.new(1, -25, 0, 20),

		Text = title,
		TextColor3 = theme.Text,
		TextSize = 14,
		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left
	}, notification)

	local contentLabel = New("TextLabel", {
		BackgroundTransparency = 1,

		Position = UDim2.new(0, 15, 0, 30),
		Size = UDim2.new(1, -25, 0, 32),

		Text = content,
		TextColor3 = theme.SubText,
		TextSize = 12,
		Font = Enum.Font.Gotham,

		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top
	}, notification)

	notification.Position = UDim2.new(
		0,
		400,
		0,
		0
	)

	Tween(notification, 0.25, {
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()

	task.delay(duration, function()
		if not notification.Parent then
			return
		end

		local tween = Tween(
			notification,
			0.2,
			{
				Position = UDim2.new(0, 400, 0, 0)
			}
		)

		tween:Play()
		tween.Completed:Wait()

		if notification then
			notification:Destroy()
		end
	end)

	return notification
end

function Window:SelectTab(tab)
	if self.Unloaded then
		return
	end

	for _, current in ipairs(self.Tabs) do
		current.Content.Visible = false

		Tween(
			current.Button,
			0.15,
			{
				BackgroundColor3 = self.Theme.Panel
			}
		):Play()

		current.Button.TextColor3 = self.Theme.SubText
	end

	tab.Content.Visible = true

	Tween(
		tab.Button,
		0.15,
		{
			BackgroundColor3 = self.Theme.AccentDark
		}
	):Play()

	tab.Button.TextColor3 = self.Theme.Text

	self.ActiveTab = tab
end

function Window:Toggle()
	if self.Unloaded then
		return
	end

	self.Main.Visible = not self.Main.Visible
end

function Window:Show()
	if not self.Unloaded then
		self.Main.Visible = true
	end
end

function Window:Hide()
	if not self.Unloaded then
		self.Main.Visible = false
	end
end

function Window:SetPosition(position)
	if self.Unloaded then
		return
	end

	self.Main.Position = position
end

function Window:SetSize(size)
	if self.Unloaded then
		return
	end

	self.Main.Size = size
end

--========================================================--
-- TAB
--========================================================--

function Window:AddTab(name, icon)
	assert(type(name) == "string", "Tab name must be a string")

	local tab = {
		Name = name,
		Elements = {},
		Sections = {},
		Window = self
	}

	setmetatable(tab, {
		__index = {}
	})

	local button = New("TextButton", {
		Name = name .. "_Tab",

		BackgroundColor3 = self.Theme.Panel,
		BorderSizePixel = 0,

		Size = UDim2.new(1, 0, 0, 40),

		AutoButtonColor = false,

		Text = icon and ("  " .. icon .. "   " .. name) or name,

		TextColor3 = self.Theme.SubText,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,

		TextXAlignment = Enum.TextXAlignment.Left
	}, self.TabList)

	Corner(button, 7)

	tab.Button = button

	local content = New("ScrollingFrame", {
		Name = name .. "_Content",

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Position = UDim2.new(0, 170, 0, 65),
		Size = UDim2.new(1, -185, 1, -80),

		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,

		ScrollBarThickness = 3,
		ScrollBarImageColor3 = self.Theme.Accent,

		Visible = false
	}, self.Main)

	tab.Content = content

	local padding = New("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 3),
		PaddingRight = UDim.new(0, 7)
	}, content)

	local layout = New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, content)

	button.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			Tween(button, 0.12, {
				BackgroundColor3 = self.Theme.PanelHover
			}):Play()
		end
	end)

	button.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			Tween(button, 0.12, {
				BackgroundColor3 = self.Theme.Panel
			}):Play()
		end
	end)

	button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	--====================================================--
	-- SECTION
	--====================================================--

	function tab:AddSection(title)
		local section = New("Frame", {
			Name = "Section",

			BackgroundTransparency = 1,

			Size = UDim2.new(1, 0, 0, 28)
		}, content)

		local label = New("TextLabel", {
			BackgroundTransparency = 1,

			Position = UDim2.new(0, 2, 0, 4),
			Size = UDim2.new(1, -4, 1, -4),

			Text = title,
			TextColor3 = self.Window.Theme.SubText,
			TextSize = 12,
			Font = Enum.Font.GothamBold,

			TextXAlignment = Enum.TextXAlignment.Left
		}, section)

		table.insert(tab.Sections, section)

		return section
	end

	--====================================================--
	-- BUTTON
	--====================================================--

	function tab:AddButton(options, callback)
		if type(options) == "string" then
			options = {
				Name = options,
				Callback = callback
			}
		end

		options = options or {}

		local name = options.Name or "Button"
		local description = options.Description
		local fn = options.Callback or function() end

		local height = description and 58 or 45

		local button = New("TextButton", {
			Name = "Button",

			BackgroundColor3 = self.Window.Theme.Panel,
			BorderSizePixel = 0,

			Size = UDim2.new(1, 0, 0, height),

			AutoButtonColor = false,
			Text = ""
		}, content)

		Corner(button, 8)
		Stroke(button, self.Window.Theme.Border)

		local titleLabel = New("TextLabel", {
			BackgroundTransparency = 1,

			Position = UDim2.new(0, 14, 0, description and 9 or 0),
			Size = UDim2.new(1, -55, 0, 22),

			Text = name,
			TextColor3 = self.Window.Theme.Text,
			TextSize = 13,
			Font = Enum.Font.GothamMedium,

			TextXAlignment = Enum.TextXAlignment.Left
		}, button)

		if description then
			New("TextLabel", {
				BackgroundTransparency = 1,

				Position = UDim2.new(0, 14, 0, 30),
				Size = UDim2.new(1, -25, 0, 18),

				Text = description,
				TextColor3 = self.Window.Theme.SubText,
				TextSize = 11,
				Font = Enum.Font.Gotham,

				TextXAlignment = Enum.TextXAlignment.Left
			}, button)
		end

		local arrow = New("TextLabel", {
			BackgroundTransparency = 1,

			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -13, 0.5, 0),

			Size = UDim2.new(0, 20, 0, 20),

			Text = "›",
			TextColor3 = self.Window.Theme.SubText,
			TextSize = 20,
			Font = Enum.Font.GothamBold
		}, button)

		button.MouseEnter:Connect(function()
			Tween(button, 0.12, {
				BackgroundColor3 = self.Window.Theme.PanelHover
			}):Play()
		end)

		button.MouseLeave:Connect(function()
			Tween(button, 0.12, {
				BackgroundColor3 = self.Window.Theme.Panel
			}):Play()
		end)

		button.MouseButton1Click:Connect(function()
			SafeCallback(fn)
		end)

		table.insert(tab.Elements, button)

		return button
	end

	--====================================================--
	-- TOGGLE
	--====================================================--

	function tab:AddToggle(options)
		options = options or {}

		local name = options.Name or "Toggle"
		local description = options.Description
		local callback = options.Callback or function() end

		local toggle = {
			Value = options.Default == true
		}

		local height = description and 60 or 48

		local holder = New("TextButton", {
			Name = "Toggle",

			BackgroundColor3 = self.Window.Theme.Panel,
			BorderSizePixel = 0,

			Size = UDim2.new(1, 0, 0, height),

			AutoButtonColor = false,
			Text = ""
		}, content)

		Corner(holder, 8)
		Stroke(holder, self.Window.Theme.Border)

		New("TextLabel", {
			BackgroundTransparency = 1,

			Position = UDim2.new(0, 14, 0, description and 9 or 0),
			Size = UDim2.new(1, -80, 0, 22),

			Text = name,
			TextColor3 = self.Window.Theme.Text,
			TextSize = 13,
			Font = Enum.Font.GothamMedium,

			TextXAlignment = Enum.TextXAlignment.Left
		}, holder)

		if description then
			New("TextLabel", {
				BackgroundTransparency = 1,

				Position = UDim2.new(0, 14, 0, 31),
				Size = UDim2.new(1, -85, 0, 18),

				Text = description,
				TextColor3 = self.Window.Theme.SubText,
				TextSize = 11,
				Font = Enum.Font.Gotham,

				TextXAlignment = Enum.TextXAlignment.Left
			}, holder)
		end

		local switch = New("Frame", {
			BackgroundColor3 = self.Window.Theme.Off,
			BorderSizePixel = 0,

			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -13, 0.5, 0),

			Size = UDim2.new(0, 42, 0, 22)
		}, holder)

		Corner(switch, 20)

		local knob = New("Frame", {
			BackgroundColor3 = Color3.fromRGB(245, 245, 245),
			BorderSizePixel = 0,

			Position = UDim2.new(0, 3, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),

			Size = UDim2.new(0, 16, 0, 16)
		}, switch)

		Corner(knob, 20)

		local function updateVisual()
			if toggle.Value then
				Tween(switch, 0.15, {
					BackgroundColor3 = self.Window.Theme.Accent
				}):Play()

				Tween(knob, 0.15, {
					Position = UDim2.new(1, -19, 0.5, 0)
				}):Play()
			else
				Tween(switch, 0.15, {
					BackgroundColor3 = self.Window.Theme.Off
				}):Play()

				Tween(knob, 0.15, {
					Position = UDim2.new(0, 3, 0.5, 0)
				}):Play()
			end
		end

		function toggle:Set(value, fire)
			toggle.Value = value == true

			updateVisual()

			if fire ~= false then
				SafeCallback(callback, toggle.Value)
			end
		end

		function toggle:Get()
			return toggle.Value
		end

		holder.MouseButton1Click:Connect(function()
			toggle:Set(not toggle.Value)
		end)

		updateVisual()

		table.insert(tab.Elements, holder)

		return toggle
	end

	--====================================================--
	-- SLIDER
	--====================================================--

	function tab:AddSlider(options)
		options = options or {}

		local name = options.Name or "Slider"
		local min = tonumber(options.Min) or 0
		local max = tonumber(options.Max) or 100
		local default = tonumber(options.Default) or min
		local rounding = tonumber(options.Rounding) or 0

		local callback = options.Callback or function() end

		if max <= min then
			max = min + 1
		end

		default = math.clamp(default, min, max)

		local slider = {
			Value = default
		}

		local holder = New("Frame", {
			Name = "Slider",

			BackgroundColor3 = self.Window.Theme.Panel,
			BorderSizePixel = 0,

			Size = UDim2.new(1, 0, 0, 70)
		}, content)

		Corner(holder, 8)
		Stroke(holder, self.Window.Theme.Border)

		local label = New("TextLabel", {
			BackgroundTransparency = 1,

			Position = UDim2.new(0, 14, 0, 8),
			Size = UDim2.new(0.65, 0, 0, 20),

			Text = name,
			TextColor3 = self.Window.Theme.Text,
			TextSize = 13,
			Font = Enum.Font.GothamMedium,

			TextXAlignment = Enum.TextXAlignment.Left
		}, holder)

		local valueLabel = New("TextLabel", {
			BackgroundTransparency = 1,

			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 8),
			Size = UDim2.new(0.3, 0, 0, 20),

			Text = tostring(default),
			TextColor3 = self.Window.Theme.Accent,
			TextSize = 13,
			Font = Enum.Font.GothamBold,

			TextXAlignment = Enum.TextXAlignment.Right
		}, holder)

		local bar = New("Frame", {
			BackgroundColor3 = self.Window.Theme.Off,
			BorderSizePixel = 0,

			Position = UDim2.new(0, 14, 0, 43),
			Size = UDim2.new(1, -28, 0, 6)
		}, holder)

		Corner(bar, 10)

		local fill = New("Frame", {
			BackgroundColor3 = self.Window.Theme.Accent,
			BorderSizePixel = 0,

			Size = UDim2.new(0, 0, 1, 0)
		}, bar)

		Corner(fill, 10)

		local knob = New("Frame", {
			BackgroundColor3 = Color3.fromRGB(245, 245, 245),
			BorderSizePixel = 0,

			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),

			Size = UDim2.new(0, 14, 0, 14)
		}, bar)

		Corner(knob, 20)

		local dragging = false

		local function round(value)
			if rounding <= 0 then
				return math.floor(value + 0.5)
			end

			local multiplier = 10 ^ rounding

			return math.floor(value * multiplier + 0.5)
				/ multiplier
		end

		local function setFromX(x, fire)
			local width = bar.AbsoluteSize.X

			if width <= 0 then
				return
			end

			local relative = math.clamp(
				x - bar.AbsolutePosition.X,
				0,
				width
			)

			local percentage = relative / width

			local value = min + ((max - min) * percentage)

			value = round(value)

			local visual =
				(value - min) / (max - min)

			slider.Value = value

			fill.Size = UDim2.new(
				visual,
				0,
				1,
				0
			)

			knob.Position = UDim2.new(
				visual,
				0,
				0.5,
				0
			)

			valueLabel.Text = tostring(value)

			if fire then
				SafeCallback(callback, value)
			end
		end

		function slider:Set(value, fire)
			value = tonumber(value) or min
			value = math.clamp(value, min, max)

			local percentage =
				(value - min) / (max - min)

			setFromX(
				bar.AbsolutePosition.X
					+ bar.AbsoluteSize.X * percentage,
				fire ~= false
			)
		end

		function slider:Get()
			return slider.Value
		end

		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then

				dragging = true
				setFromX(input.Position.X, true)
			end
		end)

		local inputChanged = UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end

			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then

				setFromX(input.Position.X, true)
			end
		end)

		local inputEnded = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then

				dragging = false
			end
		end)

		task.defer(function()
			slider:Set(default, false)
		end)

		table.insert(tab.Elements, {
			Instance = holder,
			Connections = {
				inputChanged,
				inputEnded
			}
		})

		return slider
	end

	--====================================================--
	-- DROPDOWN
	--====================================================--

	function tab:AddDropdown(options)
		options = options or {}

		local name = options.Name or "Dropdown"
		local values = options.Values or {}
		local default = options.Default
		local callback = options.Callback or function() end

		local dropdown = {
			Value = default,
			Open = false
		}

		local holder = New("Frame", {
			Name = "Dropdown",

			BackgroundColor3 = self.Window.Theme.Panel,
			BorderSizePixel = 0,

			Size = UDim2.new(1, 0, 0, 50),

			ClipsDescendants = true
		}, content)

		Corner(holder, 8)
		Stroke(holder, self.Window.Theme.Border)

		local mainButton = New("TextButton", {
			BackgroundTransparency = 1,

			Size = UDim2.new(1, 0, 0, 50),

			AutoButtonColor = false,

			Text = ""
		}, holder)

		local title = New("TextLabel", {
			BackgroundTransparency = 1,

			Position = UDim2.new(0, 14, 0, 0),
			Size = UDim2.new(0.45, 0, 0, 50),

			Text = name,
			TextColor3 = self.Window.Theme.Text,
			TextSize = 13,
			Font = Enum.Font.GothamMedium,

			TextXAlignment = Enum.TextXAlignment.Left
		}, mainButton)

		local selected = New("TextLabel", {
			BackgroundTransparency = 1,

			Position = UDim2.new(0.45, 0, 0, 0),
			Size = UDim2.new(0.5, -35, 0, 50),

			Text = tostring(default or "Select..."),
			TextColor3 = self.Window.Theme.SubText,
			TextSize = 12,
			Font = Enum.Font.Gotham,

			TextXAlignment = Enum.TextXAlignment.Right
		}, mainButton)

		local arrow = New("TextLabel", {
			BackgroundTransparency = 1,

			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),

			Size = UDim2.new(0, 20, 0, 20),

			Text = "⌄",
			TextColor3 = self.Window.Theme.SubText,
			TextSize = 16,
			Font = Enum.Font.GothamBold
		}, mainButton)

		local list = New("Frame", {
			BackgroundTransparency = 1,

			Position = UDim2.new(0, 8, 0, 52),
			Size = UDim2.new(1, -16, 0, 0),

			ClipsDescendants = true
		}, holder)

		local listLayout = New("UIListLayout", {
			Padding = UDim.new(0, 4)
		}, list)

		local function rebuild()
			for _, child in ipairs(list:GetChildren()) do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end

			for _, value in ipairs(values) do
				local optionButton = New("TextButton", {
					BackgroundColor3 = self.Window.Theme.PanelHover,
					BorderSizePixel = 0,

					Size = UDim2.new(1, 0, 0, 32),

					AutoButtonColor = false,

					Text = tostring(value),
					TextColor3 = self.Window.Theme.Text,
					TextSize = 12,
					Font = Enum.Font.Gotham,

					TextXAlignment = Enum.TextXAlignment.Left
				}, list)

				Corner(optionButton, 6)

				New("UIPadding", {
					PaddingLeft = UDim.new(0, 10)
				}, optionButton)

				optionButton.MouseEnter:Connect(function()
					optionButton.BackgroundColor3 =
						self.Window.Theme.AccentDark
				end)

				optionButton.MouseLeave:Connect(function()
					optionButton.BackgroundColor3 =
						self.Window.Theme.PanelHover
				end)

				optionButton.MouseButton1Click:Connect(function()
					dropdown.Value = value
					selected.Text = tostring(value)

					SafeCallback(callback, value)

					dropdown.Open = false

					Tween(holder, 0.18, {
						Size = UDim2.new(1, 0, 0, 50)
					}):Play()

					Tween(arrow, 0.15, {
						Rotation = 0
					}):Play()
				end)
			end
		end

		mainButton.MouseButton1Click:Connect(function()
			dropdown.Open = not dropdown.Open

			if dropdown.Open then
				rebuild()

				local count = #values
				local height = math.min(count * 36 + 8, 180)

				Tween(holder, 0.2, {
					Size = UDim2.new(1, 0, 0, 58 + height)
				}):Play()

				Tween(arrow, 0.15, {
					Rotation = 180
				}):Play()
			else
				Tween(holder, 0.2, {
					Size = UDim2.new(1, 0, 0, 50)
				}):Play()

				Tween(arrow, 0.15, {
					Rotation = 0
				}):Play()
			end
		end)

		function dropdown:Set(value, fire)
			for _, item in ipairs(values) do
				if item == value then
					dropdown.Value = value
					selected.Text = tostring(value)

					if fire ~= false then
						SafeCallback(callback, value)
					end

					return
				end
			end
		end

		function dropdown:Get()
			return dropdown.Value
		end

		table.insert(tab.Elements, holder)

		return dropdown
	end

	--====================================================--
	-- TEXTBOX
	--====================================================--

	function tab:AddTextbox(options)
		options = options or {}

		local name = options.Name or "Textbox"
		local placeholder = options.Placeholder or ""
		local default = options.Default or ""
		local callback = options.Callback or function() end

		local holder = New("Frame", {
			Name = "Textbox",

			BackgroundColor3 = self.Window.Theme.Panel,
			BorderSizePixel = 0,

			Size = UDim2.new(1, 0, 0, 58)
		}, content)

		Corner(holder, 8)
		Stroke(holder, self.Window.Theme.Border)

		New("TextLabel", {
			BackgroundTransparency = 1,

			Position = UDim2.new(0, 14, 0, 0),
			Size = UDim2.new(0.4, 0, 1, 0),

			Text = name,
			TextColor3 = self.Window.Theme.Text,
			TextSize = 13,
			Font = Enum.Font.GothamMedium,

			TextXAlignment = Enum.TextXAlignment.Left
		}, holder)

		local box = New("TextBox", {
			BackgroundColor3 = self.Window.Theme.Background,
			BorderSizePixel = 0,

			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),

			Size = UDim2.new(0.5, 0, 0, 34),

			Text = default,
			PlaceholderText = placeholder,

			TextColor3 = self.Window.Theme.Text,
			PlaceholderColor3 = self.Window.Theme.SubText,

			TextSize = 12,
			Font = Enum.Font.Gotham,

			ClearTextOnFocus = false
		}, holder)

		Corner(box, 6)

		box.FocusLost:Connect(function()
			SafeCallback(callback, box.Text)
		end)

		function holder:Get()
			return box.Text
		end

		function holder:Set(value)
			box.Text = tostring(value)
		end

		table.insert(tab.Elements, holder)

		return holder
	end

	--====================================================--
	-- LABEL
	--====================================================--

	function tab:AddLabel(text)
		local label = New("TextLabel", {
			Name = "Label",

			BackgroundTransparency = 1,

			Size = UDim2.new(1, 0, 0, 30),

			Text = tostring(text),

			TextColor3 = self.Window.Theme.SubText,
			TextSize = 12,
			Font = Enum.Font.Gotham,

			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left
		}, content)

		return label
	end

	--====================================================--
	-- KEYBIND
	--====================================================--

	function tab:AddKeybind(options)
		options = options or {}

		local name = options.Name or "Keybind"
		local default = options.Default or Enum.KeyCode.RightControl
		local callback = options.Callback or function() end

		local keybind = {
			Key = default,
			Listening = false
		}

		local holder = New("TextButton", {
			Name = "Keybind",

			BackgroundColor3 = self.Window.Theme.Panel,
			BorderSizePixel = 0,

			Size = UDim2.new(1, 0, 0, 48),

			AutoButtonColor = false,
			Text = ""
		}, content)

		Corner(holder, 8)
		Stroke(holder, self.Window.Theme.Border)

		New("TextLabel", {
			BackgroundTransparency = 1,

			Position = UDim2.new(0, 14, 0, 0),
			Size = UDim2.new(0.55, 0, 1, 0),

			Text = name,
			TextColor3 = self.Window.Theme.Text,
			TextSize = 13,
			Font = Enum.Font.GothamMedium,

			TextXAlignment = Enum.TextXAlignment.Left
		}, holder)

		local keyLabel = New("TextLabel", {
			BackgroundColor3 = self.Window.Theme.Background,
			BorderSizePixel = 0,

			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),

			Size = UDim2.new(0, 90, 0, 30),

			Text = default.Name,

			TextColor3 = self.Window.Theme.SubText,
			TextSize = 11,
			Font = Enum.Font.GothamBold
		}, holder)

		Corner(keyLabel, 6)

		holder.MouseButton1Click:Connect(function()
			keybind.Listening = true
			keyLabel.Text = "Press key..."
			keyLabel.TextColor3 = self.Window.Theme.Accent
		end)

		local inputConnection

		inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end

			if keybind.Listening then
				if input.UserInputType == Enum.UserInputType.Keyboard then
					keybind.Key = input.KeyCode
					keybind.Listening = false

					keyLabel.Text = input.KeyCode.Name
					keyLabel.TextColor3 = self.Window.Theme.SubText
				end

				return
			end

			if input.UserInputType == Enum.UserInputType.Keyboard
				and input.KeyCode == keybind.Key then

				SafeCallback(callback)
			end
		end)

		function keybind:Set(key)
			if typeof(key) == "EnumItem"
				and key.EnumType == Enum.KeyCode then

				keybind.Key = key
				keyLabel.Text = key.Name
			end
		end

		function keybind:Get()
			return keybind.Key
		end

		table.insert(tab.Elements, {
			Instance = holder,
			Connection = inputConnection
		})

		return keybind
	end

	table.insert(self.Tabs, tab)

	if #self.Tabs == 1 then
		self:SelectTab(tab)
	end

	return tab
end

--========================================================--
-- CREATE WINDOW
--========================================================--

function Nebula:CreateWindow(options)
	options = options or {}

	local window = setmetatable({}, Window)

	window.Unloaded = false
	window.Tabs = {}
	window.Theme = {}

	for key, value in pairs(self.CurrentTheme) do
		window.Theme[key] = value
	end

	local parent = options.Parent

	if not parent then
		if LocalPlayer then
			parent = LocalPlayer:WaitForChild("PlayerGui")
		end
	end

	if not parent then
		error("Nebula UI: PlayerGui is unavailable.")
	end

	local gui = New("ScreenGui", {
		Name = options.Name or "NebulaUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	}, parent)

	window.ScreenGui = gui

	--====================================================--
	-- MAIN
	--====================================================--

	local size = options.Size or UDim2.fromOffset(720, 500)
	local position = options.Position
		or UDim2.new(0.5, -360, 0.5, -250)

	local main = New("Frame", {
		Name = "Window",

		BackgroundColor3 = window.Theme.Background,
		BorderSizePixel = 0,

		Position = position,
		Size = size,

		ClipsDescendants = true
	}, gui)

	Corner(main, options.CornerRadius or 10)
	Stroke(main, window.Theme.Border)

	window.Main = main

	--====================================================--
	-- HEADER
	--====================================================--

	local header = New("Frame", {
		Name = "Header",

		BackgroundColor3 = window.Theme.Sidebar,
		BorderSizePixel = 0,

		Size = UDim2.new(1, 0, 0, 60)
	}, main)

	window.Header = header

	local title = New("TextLabel", {
		BackgroundTransparency = 1,

		Position = UDim2.new(0, 20, 0, 7),
		Size = UDim2.new(1, -100, 0, 25),

		Text = options.Title or "Nebula",

		TextColor3 = window.Theme.Text,
		TextSize = 17,
		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left
	}, header)

	local subtitle = New("TextLabel", {
		BackgroundTransparency = 1,

		Position = UDim2.new(0, 21, 0, 31),
		Size = UDim2.new(1, -100, 0, 18),

		Text = options.Subtitle or "Modern Roblox Interface",

		TextColor3 = window.Theme.SubText,
		TextSize = 10,
		Font = Enum.Font.Gotham,

		TextXAlignment = Enum.TextXAlignment.Left
	}, header)

	local close = New("TextButton", {
		BackgroundTransparency = 1,

		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),

		Size = UDim2.new(0, 32, 0, 32),

		AutoButtonColor = false,

		Text = "×",

		TextColor3 = window.Theme.SubText,
		TextSize = 24,
		Font = Enum.Font.GothamBold
	}, header)

	close.MouseEnter:Connect(function()
		Tween(close, 0.12, {
			TextColor3 = window.Theme.Error
		}):Play()
	end)

	close.MouseLeave:Connect(function()
		Tween(close, 0.12, {
			TextColor3 = window.Theme.SubText
		}):Play()
	end)

	close.MouseButton1Click:Connect(function()
		window:Unload()
	end)

	--====================================================--
	-- SIDEBAR
	--====================================================--

	local sidebar = New("Frame", {
		Name = "Sidebar",

		BackgroundColor3 = window.Theme.Sidebar,
		BorderSizePixel = 0,

		Position = UDim2.new(0, 0, 0, 60),
		Size = UDim2.new(0, 155, 1, -60)
	}, main)

	window.Sidebar = sidebar

	local sidebarPadding = New("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10)
	}, sidebar)

	local tabList = New("ScrollingFrame", {
		Name = "TabList",

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Size = UDim2.new(1, 0, 1, 0),

		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,

		ScrollBarThickness = 2,
		ScrollBarImageColor3 = window.Theme.Accent
	}, sidebar)

	window.TabList = tabList

	New("UIListLayout", {
		Padding = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, tabList)

	--====================================================--
	-- CONTENT
	--====================================================--

	local contentBackground = New("Frame", {
		Name = "Content",

		BackgroundColor3 = window.Theme.Background,
		BorderSizePixel = 0,

		Position = UDim2.new(0, 155, 0, 60),
		Size = UDim2.new(1, -155, 1, -60),

		ZIndex = 0
	}, main)

	window.Content = contentBackground

	--====================================================--
	-- NOTIFICATIONS
	--====================================================--

	local notificationContainer = New("Frame", {
		Name = "Notifications",

		BackgroundTransparency = 1,

		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -15, 0, 15),

		Size = UDim2.new(0, 300, 0, 400),

		ZIndex = 100
	}, gui)

	New("UIListLayout", {
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Top
	}, notificationContainer)

	window.NotificationContainer = notificationContainer

	--====================================================--
	-- DRAG
	--====================================================--

	window.DragConnections = MakeDraggable(main, header)

	--====================================================--
	-- MINIMIZE
	--====================================================--

	local minimize = New("TextButton", {
		BackgroundTransparency = 1,

		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -48, 0.5, 0),

		Size = UDim2.new(0, 25, 0, 25),

		AutoButtonColor = false,

		Text = "−",

		TextColor3 = window.Theme.SubText,
		TextSize = 19,
		Font = Enum.Font.GothamBold
	}, header)

	minimize.MouseButton1Click:Connect(function()
		window.Minimized = not window.Minimized

		if window.Minimized then
			Tween(main, 0.2, {
				Size = UDim2.new(
					0,
					main.AbsoluteSize.X,
					0,
					60
				)
			}):Play()

			minimize.Text = "+"
		else
			Tween(main, 0.2, {
				Size = size
			}):Play()

			minimize.Text = "−"
		end
	end)

	--====================================================--
	-- UNLOAD
	--====================================================--

	function window:Unload()
		if self.Unloaded then
			return
		end

		self.Unloaded = true

		for _, connection in ipairs(self.DragConnections or {}) do
			Disconnect(connection)
		end

		for _, tab in ipairs(self.Tabs) do
			for _, element in ipairs(tab.Elements) do
				if typeof(element) == "Instance" then
					continue
				end

				Disconnect(element.Connection)

				if element.Connections then
					for _, connection in ipairs(element.Connections) do
						Disconnect(connection)
					end
				end
			end
		end

		table.clear(self.Tabs)

		if self.ScreenGui then
			self.ScreenGui:Destroy()
		end

		self.ScreenGui = nil
		self.Main = nil
		self.Header = nil
		self.Sidebar = nil
		self.TabList = nil
		self.Content = nil
		self.NotificationContainer = nil
		self.ActiveTab = nil
	end

	--====================================================--
	-- INITIAL ANIMATION
	--====================================================--

	main.Size = UDim2.fromOffset(
		size.X.Offset * 0.92,
		size.Y.Offset * 0.92
	)

	Tween(main, 0.25, {
		Size = size
	}):Play()

	return window
end

--========================================================--
-- GLOBAL THEME
--========================================================--

function Nebula:SetTheme(theme)
	if type(theme) == "string" then
		local selected = self.Themes[theme]

		if not selected then
			warn("[Nebula UI] Unknown theme:", theme)
			return
		end

		self.CurrentTheme = selected
	elseif type(theme) == "table" then
		self.CurrentTheme = theme
	else
		return
	end
end

return Nebula
