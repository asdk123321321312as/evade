--=========================================================================
--  SleepScript  v1.0   |   Evade   |   client-side (сервер не видит)
--  Меню: Z   |   Анимация: G   |   Полёт: F
--  Работает на любом экзекьюторе (Krnl / Solara / Wave / Delta / Real и т.д.)
--=========================================================================

--== 0. Выгрузка прошлой версии ==--
if getgenv and getgenv().SleepScript and getgenv().SleepScript.Unload then
	pcall(getgenv().SleepScript.Unload)
end

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local Lighting        = game:GetService("Lighting")
local TweenService    = game:GetService("TweenService")
local HttpService     = game:GetService("HttpService")

local LP     = Players.LocalPlayer
local API    = {}
if getgenv then getgenv().SleepScript = API end

--== 1. Конфиг ==--
local CFG = {
	MenuKey        = "Z",
	FOV            = 80,
	FOVLock        = true,
	Fullbright     = false,
	Sky            = "По умолчанию",
	Headless       = false,
	Korblox        = false,
	NoAccessories  = false,
	Invisible      = false,
	NoClip         = false,
	KeepSpeed      = false,
	Speed          = 16,
	KeepJump       = false,
	Jump           = 50,
	Fly            = false,
	FlySpeed       = 60,
	ACBypass       = true,
	AnimId         = "",
	AnimName       = "—",
	AnimLoop       = true,
	AnimSpeed      = 1,
	AnimKey        = "G",
	AnimPriority   = "Action4",
	AnimStopOnMove = false,
}

local COL = {
	bg      = Color3.fromRGB(9, 9, 11),
	panel   = Color3.fromRGB(15, 15, 18),
	panel2  = Color3.fromRGB(22, 22, 27),
	line    = Color3.fromRGB(40, 40, 48),
	text    = Color3.fromRGB(236, 236, 242),
	dim     = Color3.fromRGB(138, 138, 150),
	accent  = Color3.fromRGB(132, 112, 255),
	off     = Color3.fromRGB(42, 42, 50),
	good    = Color3.fromRGB(92, 220, 140),
	bad     = Color3.fromRGB(240, 100, 110),
}

local CONFIG_FILE = "SleepScript_Evade.json"

local function saveCFG()
	if not writefile then return end
	pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(CFG)) end)
end
local function loadCFG()
	if not readfile or not isfile then return end
	pcall(function()
		if isfile(CONFIG_FILE) then
			local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
			for k, v in pairs(data) do
				if CFG[k] ~= nil then CFG[k] = v end
			end
		end
	end)
end
loadCFG()

--== 2. Хелперы ==--
local CONNS = {}
local function conn(sig, fn)
	local c = sig:Connect(fn)
	CONNS[#CONNS + 1] = c
	return c
end

local function new(class, props, parent)
	local o = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then o[k] = v end
		end
	end
	o.Parent = parent
	return o
end

local function corner(r, obj)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = obj
	return c
end

local function stroke(obj, color, th)
	local s = Instance.new("UIStroke")
	s.Color = color or COL.line
	s.Thickness = th or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

local function fmtNum(v)
	if v % 1 == 0 then return tostring(math.floor(v)) end
	return string.format("%.2f", v)
end

--== 3. GUI ==--
local gui = Instance.new("ScreenGui")
gui.Name = "SleepScript"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999

do
	local placed = false
	if gethui then
		pcall(function()
			gui.Parent = gethui()
			placed = true
		end)
	end
	if not placed then
		pcall(function()
			gui.Parent = game:GetService("CoreGui")
			placed = true
		end)
	end
	if not placed then gui.Parent = LP:WaitForChild("PlayerGui") end
end

local main = new("Frame", {
	Name = "Main",
	Size = UDim2.new(0, 480, 0, 348),
	Position = UDim2.new(0.5, -240, 0.5, -174),
	BackgroundColor3 = COL.bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
corner(10, main)
stroke(main, COL.line, 1)

-- заголовок
local header = new("Frame", {
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = COL.panel,
	BorderSizePixel = 0,
}, main)
corner(10, header)

new("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 12, 0, 0),
	Size = UDim2.new(0, 220, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "SleepScript",
	TextColor3 = COL.text,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

new("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -62, 0.5, 0),
	Size = UDim2.new(0, 120, 1, 0),
	Font = Enum.Font.GothamMedium,
	Text = "v1.0  •  Evade",
	TextColor3 = COL.dim,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Right,
}, header)

local function headerBtn(txt, xOff, fn)
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, xOff, 0.5, 0),
		Size = UDim2.new(0, 22, 0, 22),
		BackgroundColor3 = COL.panel2,
		Font = Enum.Font.GothamBold,
		Text = txt,
		TextColor3 = COL.text,
		TextSize = 12,
		AutoButtonColor = false,
	}, header)
	corner(5, b)
	stroke(b, COL.line, 1)
	conn(b.MouseButton1Click, fn)
	return b
end

headerBtn("✕", -10, function() gui.Enabled = false end)
local minimized = false
headerBtn("–", -36, function()
	minimized = not minimized
	main.Size = minimized and UDim2.new(0, 480, 0, 34) or UDim2.new(0, 480, 0, 348)
end)

-- перетаскивание
do
	local dragging, dragStart, startPos = false, nil, nil
	conn(header.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			conn(input.Changed, function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	conn(UIS.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

-- вкладки
local TABS = { "Визуал", "Персонаж", "Анимации", "Прочее" }
local tabBar = new("Frame", {
	Position = UDim2.new(0, 8, 0, 38),
	Size = UDim2.new(1, -16, 0, 24),
	BackgroundTransparency = 1,
}, main)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 5),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabBar)

local pages, tabBtns = {}, {}
local function makePage()
	local page = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 68),
		Size = UDim2.new(1, 0, 1, -68),
		Visible = false,
	}, main)
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -20, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = COL.line,
		BorderSizePixel = 0,
	}, page)
	new("UIListLayout", {
		Padding = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scroll)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 12),
	}, scroll)
	return page, scroll
end

for i, name in ipairs(TABS) do
	local page, scroll = makePage()
	pages[i] = page
	local btn = new("TextButton", {
		Size = UDim2.new(0, 96, 1, 0),
		BackgroundColor3 = COL.panel,
		Font = Enum.Font.GothamMedium,
		Text = name,
		TextColor3 = COL.dim,
		TextSize = 12,
		AutoButtonColor = false,
	}, tabBar)
	corner(6, btn)
	stroke(btn, COL.line, 1)
	tabBtns[i] = btn
	conn(btn.MouseButton1Click, function()
		for j = 1, #TABS do
			pages[j].Visible = (j == i)
			tabBtns[j].TextColor3 = (j == i) and COL.text or COL.dim
			tabBtns[j].BackgroundColor3 = (j == i) and COL.panel2 or COL.panel
		end
	end)
	if i == 1 then
		page.Visible = true
		btn.TextColor3 = COL.text
		btn.BackgroundColor3 = COL.panel2
	end
end

-- виджеты
local activeSlider = nil
local function makeSlider(parent, label, min, max, default, step, onChange)
	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34) }, parent)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(0.65, 0, 0, 15),
		Font = Enum.Font.GothamMedium, Text = label, TextColor3 = COL.text,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	}, holder)
	local valLbl = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.new(0.65, 0, 0, 0), Size = UDim2.new(0.35, 0, 0, 15),
		Font = Enum.Font.GothamBold, Text = fmtNum(default), TextColor3 = COL.accent,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
	}, holder)
	local track = new("Frame", {
		BackgroundColor3 = COL.off, Position = UDim2.new(0, 0, 0, 23), Size = UDim2.new(1, 0, 0, 4),
	}, holder)
	corner(2, track)
	local fill = new("Frame", { BackgroundColor3 = COL.accent, Size = UDim2.new(0, 0, 1, 0) }, track)
	corner(2, fill)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
		Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 10, 0, 10), ZIndex = 2,
	}, track)
	corner(5, knob)
	local hit = new("TextButton", {
		BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0.5, -9),
		Size = UDim2.new(1, 0, 0, 18), Text = "",
	}, track)

	local value = default
	local function render()
		local a = (value - min) / (max - min)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		valLbl.Text = fmtNum(value)
	end
	local function setFromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		value = min + (max - min) * rel
		if step then value = math.floor(value / step + 0.5) * step end
		render()
		if onChange then onChange(value) end
	end
	conn(hit.InputBegan, function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
			or inp.UserInputType == Enum.UserInputType.Touch then
			activeSlider = setFromX
			setFromX(inp.Position.X)
		end
	end)
	render()
	return { Set = function(v) value = v; render(); if onChange then onChange(v) end end,
	         Get = function() return value end }
end

local function makeToggle(parent, label, default, onChange)
	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24) }, parent)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(0.75, 0, 1, 0),
		Font = Enum.Font.GothamMedium, Text = label, TextColor3 = COL.text,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local box = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 36, 0, 18), BackgroundColor3 = COL.off,
	}, row)
	corner(9, box)
	local knob = new("Frame", {
		Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 2, 0.5, -7),
		BackgroundColor3 = Color3.fromRGB(235, 235, 235),
	}, box)
	corner(7, knob)
	local btn = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" }, box)

	local state = default
	local function render()
		TweenService:Create(box, TweenInfo.new(0.14),
			{ BackgroundColor3 = state and COL.accent or COL.off }):Play()
		TweenService:Create(knob, TweenInfo.new(0.14),
			{ Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) }):Play()
	end
	render()
	conn(btn.MouseButton1Click, function()
		state = not state
		render()
		if onChange then onChange(state) end
	end)
	return { Set = function(v) state = v; render() end, Get = function() return state end }
end

local listeningKey = nil
local function makeKeybind(parent, label, default, onChange)
	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24) }, parent)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0),
		Font = Enum.Font.GothamMedium, Text = label, TextColor3 = COL.text,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 78, 0, 21), BackgroundColor3 = COL.panel2,
		Font = Enum.Font.GothamBold, Text = default, TextColor3 = COL.text,
		TextSize = 11, AutoButtonColor = false,
	}, row)
	corner(5, btn)
	stroke(btn, COL.line, 1)
	local key = default
	conn(btn.MouseButton1Click, function()
		listeningKey = function(k)
			key = k
			btn.Text = k
			if onChange then onChange(k) end
		end
		btn.Text = "..."
	end)
	return { Get = function() return key end, Set = function(v) key = v; btn.Text = v end }
end

local function makeButton(parent, label, fn, height)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, height or 26),
		BackgroundColor3 = COL.panel2,
		Font = Enum.Font.GothamMedium, Text = label, TextColor3 = COL.text,
		TextSize = 12, AutoButtonColor = false,
	}, parent)
	corner(6, b)
	stroke(b, COL.line, 1)
	conn(b.MouseButton1Click, fn)
	return b
end

local function makeSection(parent, text)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.GothamBold, Text = text, TextColor3 = COL.accent,
		TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
end

local function makeLabel(parent, text, color, height)
	return new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height or 16),
		Font = Enum.Font.Gotham, Text = text, TextColor3 = color or COL.dim,
		TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, parent)
end

local function makeTextBox(parent, placeholder, default, fn)
	local t = new("TextBox", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = COL.panel2,
		Font = Enum.Font.Gotham, PlaceholderText = placeholder,
		Text = default or "", TextColor3 = COL.text, TextSize = 12,
		PlaceholderColor3 = COL.dim, ClearTextOnFocus = false,
	}, parent)
	corner(6, t)
	stroke(t, COL.line, 1)
	if fn then
		conn(t.FocusLost, function() fn(t.Text) end)
	end
	return t
end

-- тосты
local toastHolder = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40),
	Size = UDim2.new(0, 300, 0, 100), BackgroundTransparency = 1,
}, gui)
new("UIListLayout", {
	Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
}, toastHolder)

local function toast(text, color)
	local f = new("Frame", {
		Size = UDim2.new(0, 260, 0, 24),
		BackgroundColor3 = COL.panel, BackgroundTransparency = 1,
	}, toastHolder)
	corner(6, f)
	stroke(f, color or COL.accent, 1)
	local l = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
		Font = Enum.Font.GothamMedium, Text = text, TextColor3 = COL.text, TextSize = 11,
	}, f)
	TweenService:Create(f, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(l, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()
	task.delay(2, function()
		TweenService:Create(f, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(l, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		task.wait(0.3)
		f:Destroy()
	end)
end

local pageVisual, scrollVisual       = pages[1], pages[1]:GetChildren()[1]
local pageChar, scrollChar           = pages[2], pages[2]:GetChildren()[1]
local pageAnim, scrollAnim           = pages[3], pages[3]:GetChildren()[1]
local pageMisc, scrollMisc           = pages[4], pages[4]:GetChildren()[1]

--== 4. Оригинальные значения света ==--
local ORIG = {
	ClockTime = Lighting.ClockTime,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	Brightness = Lighting.Brightness,
	FogEnd = Lighting.FogEnd,
	FogStart = Lighting.FogStart,
	FogColor = Lighting.FogColor,
	ColorShift_Top = Lighting.ColorShift_Top,
	ColorShift_Bottom = Lighting.ColorShift_Bottom,
	GlobalShadows = Lighting.GlobalShadows,
	ExposureCompensation = Lighting.ExposureCompensation,
	Outlines = Lighting.Outlines,
}

--== 5. Логика: FOV / Свет / Небо ==--
local function getCam() return workspace.CurrentCamera end

local function setFOV(v)
	local cam = getCam()
	if cam then cam.FieldOfView = v end
end

local function resetLighting()
	Lighting.ClockTime = ORIG.ClockTime
	Lighting.Ambient = ORIG.Ambient
	Lighting.OutdoorAmbient = ORIG.OutdoorAmbient
	Lighting.Brightness = ORIG.Brightness
	Lighting.FogEnd = ORIG.FogEnd
	Lighting.FogStart = ORIG.FogStart
	Lighting.FogColor = ORIG.FogColor
	Lighting.ColorShift_Top = ORIG.ColorShift_Top
	Lighting.ColorShift_Bottom = ORIG.ColorShift_Bottom
	Lighting.GlobalShadows = ORIG.GlobalShadows
	Lighting.ExposureCompensation = ORIG.ExposureCompensation
	Lighting.Outlines = ORIG.Outlines
	local s = Lighting:FindFirstChild("SleepSky")
	if s then s:Destroy() end
end

local SKYBOXES = {
	["Космос"] = {
		SkyboxBk = "rbxassetid://159454299", SkyboxDn = "rbxassetid://159454296",
		SkyboxFt = "rbxassetid://159454293", SkyboxLf = "rbxassetid://159454286",
		SkyboxRt = "rbxassetid://159454300", SkyboxUp = "rbxassetid://159454288",
	},
}

local SKY_PRESETS = {
	{ name = "По умолчанию" },
	{ name = "Ночь",      clock = 0,  ambient = Color3.fromRGB(18, 18, 26), outdoor = Color3.fromRGB(28, 28, 42),
	  bright = 1,   fogEnd = 600,  fogColor = Color3.fromRGB(12, 12, 22), stars = 3000, celestial = true },
	{ name = "Космос",    clock = 0,  ambient = Color3.fromRGB(8, 8, 14),   outdoor = Color3.fromRGB(12, 12, 20),
	  bright = 0.6, fogEnd = 3000, fogColor = Color3.fromRGB(5, 5, 12),   stars = 8000, celestial = false, box = "Космос" },
	{ name = "Кровавая луна", clock = 0, ambient = Color3.fromRGB(30, 10, 10), outdoor = Color3.fromRGB(45, 14, 14),
	  bright = 1,   fogEnd = 400,  fogColor = Color3.fromRGB(40, 8, 8),   stars = 2000, celestial = true,
	  tint = Color3.fromRGB(130, 25, 25) },
	{ name = "Туман",     clock = 6,  ambient = Color3.fromRGB(60, 62, 66), outdoor = Color3.fromRGB(70, 72, 76),
	  bright = 1.4, fogEnd = 60,   fogStart = 0, fogColor = Color3.fromRGB(120, 124, 130), stars = 0, celestial = false },
	{ name = "Пустота",   clock = 0,  ambient = Color3.new(0, 0, 0),       outdoor = Color3.new(0, 0, 0),
	  bright = 0.5, fogEnd = 1000, fogColor = Color3.new(0, 0, 0),        stars = 0, celestial = false },
	{ name = "День",      clock = 14, ambient = Color3.fromRGB(120, 120, 120), outdoor = Color3.fromRGB(130, 130, 130),
	  bright = 2,   fogEnd = 2000, stars = 0, celestial = true },
}

local function applySky(name)
	CFG.Sky = name
	resetLighting()
	if name == "По умолчанию" then return end
	for _, p in ipairs(SKY_PRESETS) do
		if p.name == name then
			if p.clock then Lighting.ClockTime = p.clock end
			if p.ambient then Lighting.Ambient = p.ambient end
			if p.outdoor then Lighting.OutdoorAmbient = p.outdoor end
			if p.bright then Lighting.Brightness = p.bright end
			if p.fogEnd then Lighting.FogEnd = p.fogEnd end
			if p.fogStart then Lighting.FogStart = p.fogStart end
			if p.fogColor then Lighting.FogColor = p.fogColor end
			if p.tint then Lighting.ColorShift_Top = p.tint; Lighting.ColorShift_Bottom = p.tint end

			local sky = Instance.new("Sky")
			sky.Name = "SleepSky"
			sky.StarCount = p.stars or 3000
			sky.CelestialBodiesShown = p.celestial ~= false
			sky.SunAngularSize = 11
			sky.MoonAngularSize = 11
			if p.box and SKYBOXES[p.box] then
				for k, v in pairs(SKYBOXES[p.box]) do sky[k] = v end
			end
			sky.Parent = Lighting
			return
		end
	end
end

local function setCustomSkybox(ids)
	local sky = Lighting:FindFirstChild("SleepSky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Name = "SleepSky"
		sky.Parent = Lighting
	end
	sky.SkyboxBk = ids.bk ~= "" and ("rbxassetid://" .. ids.bk) or ""
	sky.SkyboxDn = ids.dn ~= "" and ("rbxassetid://" .. ids.dn) or ""
	sky.SkyboxFt = ids.ft ~= "" and ("rbxassetid://" .. ids.ft) or ""
	sky.SkyboxLf = ids.lf ~= "" and ("rbxassetid://" .. ids.lf) or ""
	sky.SkyboxRt = ids.rt ~= "" and ("rbxassetid://" .. ids.rt) or ""
	sky.SkyboxUp = ids.up ~= "" and ("rbxassetid://" .. ids.up) or ""
	CFG.Sky = "Своя"
	toast("Свой скайбокс применён")
end

local function setFullbright(on)
	if on then
		Lighting.Ambient = Color3.fromRGB(178, 178, 178)
		Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 100000
	else
		applySky(CFG.Sky ~= "Своя" and CFG.Sky or "По умолчанию")
	end
end

--== 6. Логика: персонаж ==--
local KORBLOX_ID = 139607718
local origRightLeg = nil

local function getChar() return LP.Character end
local function getHum(c)
	c = c or getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function applyHeadless(on)
	local c = getChar()
	local head = c and c:FindFirstChild("Head")
	if not head then return end
	head.Transparency = on and 1 or 0
	local face = head:FindFirstChildOfClass("Decal")
	if face then face.Transparency = on and 1 or 0 end
	local hair = head:FindFirstChildOfClass("Accessory") or head:FindFirstChildOfClass("Hat")
	if hair then
		local h = hair:FindFirstChild("Handle")
		if h then h.Transparency = (on and not CFG.NoAccessories) and 1 or 0 end
	end
end

local function applyKorblox(on)
	local c = getChar()
	local hum = getHum(c)
	if not hum then return end
	if on then
		if not origRightLeg then
			pcall(function() origRightLeg = hum:GetAppliedDescription().RightLeg end)
		end
		local ok = pcall(function()
			local d = hum:GetAppliedDescription()
			d.RightLeg = KORBLOX_ID
			hum:ApplyDescription(d)
		end)
		if not ok then
			for _, n in ipairs({ "RightUpperLeg", "RightLowerLeg", "Right Leg" }) do
				local p = c:FindFirstChild(n)
				if p then p.Transparency = 1 end
			end
		end
	else
		pcall(function()
			local d = hum:GetAppliedDescription()
			d.RightLeg = origRightLeg or 0
			hum:ApplyDescription(d)
		end)
	end
end

local function applyAccessories(on)
	local c = getChar()
	if not c then return end
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("Accessory") or d:IsA("Hat") then
			local h = d:FindFirstChild("Handle")
			if h then h.Transparency = on and 1 or 0 end
		end
	end
end

local function applyInvisible(on)
	local c = getChar()
	if not c then return end
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Transparency = on and 1 or 0
		end
	end
	if on and CFG.Headless then
		local head = c:FindFirstChild("Head")
		if head then head.Transparency = 1 end
	end
end

--== 7. Логика: анимации (полностью локально) ==--
local localAnimator, currentTrack = nil, nil

local function ensureAnimator()
	local c = getChar()
	local hum = getHum(c)
	if not hum then return nil end
	local a = hum:FindFirstChild("SleepAnimator")
	if not a then
		a = Instance.new("Animator")
		a.Name = "SleepAnimator"
		a.Parent = hum
	end
	return a
end

local PRIORITY = {
	Core = Enum.AnimationPriority.Core,
	Idle = Enum.AnimationPriority.Idle,
	Movement = Enum.AnimationPriority.Movement,
	Action = Enum.AnimationPriority.Action,
	Action2 = Enum.AnimationPriority.Action2,
	Action3 = Enum.AnimationPriority.Action3,
	Action4 = Enum.AnimationPriority.Action4,
}

local function stopAnim()
	if currentTrack then
		pcall(function() currentTrack:Stop(0.15) end)
		currentTrack = nil
	end
end

local function playAnim(id)
	if not id or id == "" then
		toast("Анимация не выбрана", COL.bad)
		return
	end
	local a = ensureAnimator()
	if not a then
		toast("Нет персонажа", COL.bad)
		return
	end
	stopAnim()
	local full = id:match("^%d+$") and ("rbxassetid://" .. id) or id
	local anim = Instance.new("Animation")
	anim.AnimationId = full
	local ok, track = pcall(function() return a:LoadAnimation(anim) end)
	if not ok or not track then
		toast("Не удалось загрузить: " .. id, COL.bad)
		return
	end
	track.Priority = PRIORITY[CFG.AnimPriority] or Enum.AnimationPriority.Action4
	track.Looped = CFG.AnimLoop
	track:Play(0.1)
	track:AdjustSpeed(CFG.AnimSpeed)
	currentTrack = track
	toast("Анимация: " .. CFG.AnimName)
end

local function toggleAnim()
	if currentTrack and currentTrack.IsPlaying then
		stopAnim()
	else
		playAnim(CFG.AnimId)
	end
end

--== 8. Логика: полёт / ноклип ==--
local flyBV, flyBG, flyActive = nil, nil, false

local function setFly(on)
	flyActive = on
	local c = getChar()
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	local hum = getHum(c)
	if on and hrp and hum then
		flyBV = Instance.new("BodyVelocity")
		flyBV.Name = "SleepFly"
		flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		flyBV.Velocity = Vector3.zero
		flyBV.Parent = hrp
		flyBG = Instance.new("BodyGyro")
		flyBG.Name = "SleepGyro"
		flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
		flyBG.P = 1200
		flyBG.D = 120
		flyBG.Parent = hrp
		hum.PlatformStand = true
		toast("Полёт: ВКЛ")
	else
		if flyBV then flyBV:Destroy(); flyBV = nil end
		if flyBG then flyBG:Destroy(); flyBG = nil end
		if hum then hum.PlatformStand = false end
		toast("Полёт: ВЫКЛ")
	end
end

local function flyStep()
	if not flyActive then return end
	local c = getChar()
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	local cam = getCam()
	if not hrp or not cam then return end
	local dir = Vector3.zero
	if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
	if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
	if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
	if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
	if dir.Magnitude > 0 then dir = dir.Unit end
	if flyBV then flyBV.Velocity = dir * CFG.FlySpeed end
	if flyBG then flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector) end
end

local function applyNoClip(on)
	local c = getChar()
	if not c then return end
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BasePart") and d.CanCollide == on then
			d.CanCollide = not on
		end
	end
end

--== 9. UI: Визуал ==--
makeSection(scrollVisual, "КАМЕРА")
makeSlider(scrollVisual, "FOV", 40, 130, CFG.FOV, 1, function(v)
	CFG.FOV = v
	setFOV(v)
end)
makeToggle(scrollVisual, "Держать FOV (анти-сброс)", CFG.FOVLock, function(v) CFG.FOVLock = v end)

makeSection(scrollVisual, "НЕБО И СВЕТ")
local skyLabel = makeLabel(scrollVisual, "Пресет: " .. CFG.Sky, COL.text)
local skyIndex = 1
for i, p in ipairs(SKY_PRESETS) do
	if p.name == CFG.Sky then skyIndex = i end
end
makeButton(scrollVisual, "Сменить пресет неба →", function()
	skyIndex = skyIndex % #SKY_PRESETS + 1
	local p = SKY_PRESETS[skyIndex]
	skyLabel.Text = "Пресет: " .. p.name
	CFG.Fullbright = false
	applySky(p.name)
	toast("Небо: " .. p.name)
end)
makeToggle(scrollVisual, "Fullbright", CFG.Fullbright, function(v)
	CFG.Fullbright = v
	setFullbright(v)
end)

makeLabel(scrollVisual, "Свой скайбокс (ID лиц, можно оставить пустым):", COL.dim)
local boxBk = makeTextBox(scrollVisual, "Bk (зад)", "")
local boxDn = makeTextBox(scrollVisual, "Dn (низ)", "")
local boxFt = makeTextBox(scrollVisual, "Ft (перёд)", "")
local boxLf = makeTextBox(scrollVisual, "Lf (лево)", "")
local boxRt = makeTextBox(scrollVisual, "Rt (право)", "")
local boxUp = makeTextBox(scrollVisual, "Up (верх)", "")
makeButton(scrollVisual, "Применить свой скайбокс", function()
	setCustomSkybox({
		bk = boxBk.Text, dn = boxDn.Text, ft = boxFt.Text,
		lf = boxLf.Text, rt = boxRt.Text, up = boxUp.Text,
	})
end)

--== 10. UI: Персонаж ==--
makeSection(scrollChar, "ВНЕШКА (локально)")
makeToggle(scrollChar, "Headless", CFG.Headless, function(v)
	CFG.Headless = v
	applyHeadless(v)
	if CFG.Invisible then applyInvisible(true) end
end)
makeToggle(scrollChar, "Korblox (правая нога)", CFG.Korblox, function(v)
	CFG.Korblox = v
	applyKorblox(v)
end)
makeToggle(scrollChar, "Убрать аксессуары", CFG.NoAccessories, function(v)
	CFG.NoAccessories = v
	applyAccessories(v)
end)
makeToggle(scrollChar, "Невидимость", CFG.Invisible, function(v)
	CFG.Invisible = v
	if v then applyInvisible(true) else
		local c = getChar()
		if c then
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("BasePart") then d.Transparency = 0 end
			end
			applyHeadless(CFG.Headless)
			applyAccessories(CFG.NoAccessories)
		end
	end
end)
makeToggle(scrollChar, "Ноклип", CFG.NoClip, function(v) CFG.NoClip = v end)

makeSection(scrollChar, "МАСШТАБ ТЕЛА")
local function scaleSet(prop, v)
	local hum = getHum()
	if hum then
		pcall(function() hum[prop] = v end)
	end
end
makeSlider(scrollChar, "Рост", 0.6, 1.4, 1, 0.05, function(v) scaleSet("BodyHeightScale", v) end)
makeSlider(scrollChar, "Ширина", 0.6, 1.4, 1, 0.05, function(v) scaleSet("BodyWidthScale", v) end)
makeSlider(scrollChar, "Глубина", 0.6, 1.4, 1, 0.05, function(v) scaleSet("BodyDepthScale", v) end)
makeSlider(scrollChar, "Голова", 0.6, 1.4, 1, 0.05, function(v) scaleSet("HeadScale", v) end)

--== 11. UI: Анимации ==--
makeSection(scrollAnim, "ВЫБРАННАЯ АНИМАЦИЯ")
local animLabel = makeLabel(scrollAnim, "Сейчас: " .. CFG.AnimName, COL.text)
local animIdBox = makeTextBox(scrollAnim, "ID анимации (только цифры)", CFG.AnimId, function(txt)
	txt = txt:gsub("%s", "")
	CFG.AnimId = txt
	CFG.AnimName = "ID " .. txt
	animLabel.Text = "Сейчас: " .. CFG.AnimName
end)
makeButton(scrollAnim, "▶  Играть", function()
	playAnim(CFG.AnimId)
end)
makeButton(scrollAnim, "■  Стоп", function() stopAnim() end)
makeToggle(scrollAnim, "Зациклить", CFG.AnimLoop, function(v)
	CFG.AnimLoop = v
	if currentTrack then currentTrack.Looped = v end
end)
makeSlider(scrollAnim, "Скорость", 0.1, 4, CFG.AnimSpeed, 0.05, function(v)
	CFG.AnimSpeed = v
	if currentTrack then pcall(function() currentTrack:AdjustSpeed(v) end) end
end)
makeToggle(scrollAnim, "Останавливать при движении", CFG.AnimStopOnMove, function(v) CFG.AnimStopOnMove = v end)
makeKeybind(scrollAnim, "Кнопка анимации", CFG.AnimKey, function(k) CFG.AnimKey = k end)

makeSection(scrollAnim, "ПРИОРИТЕТ")
local prioLabel = makeLabel(scrollAnim, "Приоритет: " .. CFG.AnimPriority, COL.text)
local PRIO_LIST = { "Core", "Idle", "Movement", "Action", "Action2", "Action3", "Action4" }
local prioIndex = 7
for i, n in ipairs(PRIO_LIST) do if n == CFG.AnimPriority then prioIndex = i end end
makeButton(scrollAnim, "Сменить приоритет →", function()
	prioIndex = prioIndex % #PRIO_LIST + 1
	CFG.AnimPriority = PRIO_LIST[prioIndex]
	prioLabel.Text = "Приоритет: " .. CFG.AnimPriority
	if currentTrack then currentTrack.Priority = PRIORITY[CFG.AnimPriority] end
end)
makeLabel(scrollAnim, "Action4 перебивает ходьбу/стойку — анимация видна всегда.", COL.dim)

makeSection(scrollAnim, "ПОИСК АНИМАЦИЙ ВНУТРИ ИГРЫ")
makeLabel(scrollAnim, "Сканирует все Animation-объекты игры (включая эвентовые/старые).", COL.dim)
local searchBox = makeTextBox(scrollAnim, "фильтр по названию...", "")
local animList = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 0, 130),
	BackgroundColor3 = COL.panel,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = COL.line,
}, scrollAnim)
corner(6, animList)
stroke(animList, COL.line, 1)
new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, animList)
new("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 6),
	PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 5) }, animList)

local scanned = {}
local function renderList()
	for _, c in ipairs(animList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	local filter = searchBox.Text:lower()
	local shown = 0
	for _, item in ipairs(scanned) do
		if shown >= 200 then break end
		if filter == "" or item.name:lower():find(filter, 1, true) then
			shown += 1
			local b = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundColor3 = COL.panel2,
				Font = Enum.Font.Gotham, Text = item.name .. "  [" .. item.id:gsub("rbxassetid://", "") .. "]",
				TextColor3 = COL.text, TextSize = 10, AutoButtonColor = false,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, animList)
			corner(4, b)
			conn(b.MouseButton1Click, function()
				CFG.AnimId = item.id:gsub("rbxassetid://", "")
				CFG.AnimName = item.name
				animLabel.Text = "Сейчас: " .. CFG.AnimName
				animIdBox.Text = CFG.AnimId
				playAnim(CFG.AnimId)
			end)
		end
	end
	if shown == 0 then
		new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
			Font = Enum.Font.Gotham, Text = "Ничего не найдено",
			TextColor3 = COL.dim, TextSize = 10,
		}, animList)
	end
end
conn(searchBox:GetPropertyChangedSignal("Text"), renderList)

makeButton(scrollAnim, "🔍  Сканировать анимации игры", function()
	toast("Сканирую...")
	task.spawn(function()
		local seen, count = {}, 0
		table.clear(scanned)
		for _, obj in ipairs(game:GetDescendants()) do
			if obj:IsA("Animation") then
				local id = obj.AnimationId
				if id and id ~= "" and not seen[id] then
					seen[id] = true
					count += 1
					scanned[count] = { name = obj:GetFullName(), id = id }
				end
			end
		end
		table.sort(scanned, function(a, b) return a.name < b.name end)
		renderList()
		toast("Найдено анимаций: " .. count, COL.good)
	end)
end)

makeSection(scrollAnim, "БАЗОВЫЕ АНИМАЦИИ (R15)")
local R15 = {
	{ "R15 Idle 1", "507766666" }, { "R15 Idle 2", "782845736" },
	{ "R15 Walk", "507777826" }, { "R15 Run", "507767714" },
	{ "R15 Jump", "507765000" }, { "R15 Fall", "507767968" },
	{ "R15 Swim", "507784897" }, { "R15 Climb", "507765644" },
	{ "R15 Wave", "507770239" }, { "R15 Point", "507770453" },
	{ "R15 Dance 1", "507771019" }, { "R15 Dance 2", "507771955" },
	{ "R15 Dance 3", "507772104" }, { "R15 Dance 2A", "507776043" },
	{ "R15 Dance 3A", "507777268" }, { "R15 Laugh", "507770818" },
	{ "R15 Cheer", "507770677" }, { "R15 Sit", "507768133" },
}
for _, a in ipairs(R15) do
	makeButton(scrollAnim, a[1] .. "  •  " .. a[2], function()
		CFG.AnimId = a[2]
		CFG.AnimName = a[1]
		animLabel.Text = "Сейчас: " .. CFG.AnimName
		animIdBox.Text = a[2]
		playAnim(a[2])
	end, 22)
end

makeSection(scrollAnim, "БАЗОВЫЕ АНИМАЦИИ (R6 / классика)")
local R6 = {
	{ "R6 Idle 1", "180435571" }, { "R6 Idle 2", "180435792" },
	{ "R6 Walk", "180426354" }, { "R6 Jump", "125750702" },
	{ "R6 Fall", "180436148" }, { "R6 Climb", "180436334" },
	{ "R6 Wave", "128777973" }, { "R6 Point", "128853357" },
	{ "R6 Dance 1", "182435998" }, { "R6 Dance 2", "182436842" },
	{ "R6 Dance 3", "182436976" }, { "R6 Laugh", "129423131" },
	{ "R6 Cheer", "129423030" },
}
for _, a in ipairs(R6) do
	makeButton(scrollAnim, a[1] .. "  •  " .. a[2], function()
		CFG.AnimId = a[2]
		CFG.AnimName = a[1]
		animLabel.Text = "Сейчас: " .. CFG.AnimName
		animIdBox.Text = a[2]
		playAnim(a[2])
	end, 22)
end

--== 12. UI: Прочее (античит + утилиты) ==--
makeSection(scrollMisc, "ОБХОД АНТИЧИТА")
local acToggles = {}
makeToggle(scrollMisc, "Обход античита (все петли)", CFG.ACBypass, function(v)
	CFG.ACBypass = v
	if acToggles.speed then acToggles.speed.Set(v) end
	if acToggles.jump then acToggles.jump.Set(v) end
	if acToggles.fov then acToggles.fov.Set(v) end
	CFG.KeepSpeed, CFG.KeepJump, CFG.FOVLock = v, v, v
	toast(v and "Обход античита: ВКЛ" or "Обход античита: ВЫКЛ")
end)
acToggles.speed = makeToggle(scrollMisc, "Держать WalkSpeed", CFG.KeepSpeed, function(v) CFG.KeepSpeed = v end)
acToggles.jump  = makeToggle(scrollMisc, "Держать JumpPower", CFG.KeepJump, function(v) CFG.KeepJump = v end)
acToggles.fov   = makeToggle(scrollMisc, "Держать FOV", CFG.FOVLock, function(v) CFG.FOVLock = v end)
makeLabel(scrollMisc, "Сервер Evade перезаписывает Humanoid и внешку — петли возвращают значения каждый кадр.", COL.dim)

makeSection(scrollMisc, "ДВИЖЕНИЕ")
makeSlider(scrollMisc, "WalkSpeed", 8, 200, CFG.Speed, 1, function(v)
	CFG.Speed = v
	local hum = getHum()
	if hum then hum.WalkSpeed = v end
end)
makeSlider(scrollMisc, "JumpPower", 30, 300, CFG.Jump, 1, function(v)
	CFG.Jump = v
	local hum = getHum()
	if hum then
		hum.UseJumpPower = true
		hum.JumpPower = v
	end
end)
makeToggle(scrollMisc, "Полёт (клавиша " .. CFG.FlyKey or "F", CFG.Fly, function(v)
	CFG.Fly = v
	setFly(v)
end)
makeSlider(scrollMisc, "Скорость полёта", 10, 250, CFG.FlySpeed, 1, function(v) CFG.FlySpeed = v end)

makeSection(scrollMisc, "УТИЛИТЫ")
makeKeybind(scrollMisc, "Кнопка меню", CFG.MenuKey, function(k) CFG.MenuKey = k end)
makeButton(scrollMisc, "Переприменить всё", function()
	applyHeadless(CFG.Headless)
	applyKorblox(CFG.Korblox)
	applyAccessories(CFG.NoAccessories)
	if CFG.Invisible then applyInvisible(true) end
	setFOV(CFG.FOV)
	if CFG.Fullbright then setFullbright(true) else applySky(CFG.Sky) end
	toast("Применено", COL.good)
end)
makeButton(scrollMisc, "Сохранить конфиг", function() saveCFG(); toast("Конфиг сохранён", COL.good) end)
makeButton(scrollMisc, "Загрузить конфиг", function()
	loadCFG()
	toast("Конфиг загружен (перезайди в игру для полного применения)", COL.good)
end)
makeButton(scrollMisc, "Выгрузить SleepScript", function()
	if API.Unload then API.Unload() end
end)

makeLabel(scrollMisc, "Z — меню  •  G — анимация  •  F — полёт", COL.dim)

--== 13. Обработка ввода ==--
conn(UIS.InputBegan, function(input, gp)
	if listeningKey then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			listeningKey(input.KeyCode.Name)
			listeningKey = nil
		end
		return
	end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if UIS:GetFocusedTextBox() then return end
	local name = input.KeyCode.Name
	if name == CFG.MenuKey then
		gui.Enabled = not gui.Enabled
	elseif name == CFG.AnimKey then
		toggleAnim()
	elseif name == "F" then
		CFG.Fly = not CFG.Fly
		setFly(CFG.Fly)
	end
end)

conn(UIS.InputChanged, function(input)
	if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
		activeSlider(input.Position.X)
	end
end)
conn(UIS.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		activeSlider = nil
	end
end)

--== 14. Циклы (сердце скрипта) ==--
local acc = { korblox = 0, appearance = 0, animMove = 0 }

conn(RunService.RenderStepped, function(dt)
	local cam = getCam()
	if CFG.FOVLock and cam then cam.FieldOfView = CFG.FOV end

	local c = getChar()
	local hum = getHum(c)

	if CFG.KeepSpeed and hum and hum.WalkSpeed ~= CFG.Speed then
		hum.WalkSpeed = CFG.Speed
	end
	if CFG.KeepJump and hum and hum.JumpPower ~= CFG.Jump then
		hum.UseJumpPower = true
		hum.JumpPower = CFG.Jump
	end

	if CFG.NoClip then applyNoClip(true) end
	if CFG.Fly then flyStep() end

	acc.appearance += dt
	if acc.appearance >= 0.35 then
		acc.appearance = 0
		local head = c and c:FindFirstChild("Head")
		if CFG.Headless and head and head.Transparency ~= 1 then applyHeadless(true) end
		if CFG.NoAccessories then applyAccessories(true) end
		if CFG.Invisible then
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency ~= 1 then
					d.Transparency = 1
				end
			end
		end
		if CFG.Fullbright then setFullbright(true) end
	end

	acc.korblox += dt
	if acc.korblox >= 1.2 and CFG.Korblox and hum then
		acc.korblox = 0
		pcall(function()
			if hum:GetAppliedDescription().RightLeg ~= KORBLOX_ID then applyKorblox(true) end
		end)
	end

	if CFG.AnimStopOnMove and currentTrack and hum then
		if hum.MoveDirection.Magnitude > 0.1 and currentTrack.IsPlaying then
			stopAnim()
		end
	end
end)

--== 15. Респавн ==--
local function onCharacter(char)
	localAnimator, currentTrack = nil, nil
	origRightLeg = nil
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	task.wait(0.4)
	if CFG.KeepSpeed then hum.WalkSpeed = CFG.Speed end
	if CFG.KeepJump then hum.UseJumpPower = true; hum.JumpPower = CFG.Jump end
	if CFG.Headless then applyHeadless(true) end
	if CFG.Korblox then task.wait(0.5); applyKorblox(true) end
	if CFG.NoAccessories then applyAccessories(true) end
	if CFG.Invisible then applyInvisible(true) end
	if CFG.AnimId ~= "" then task.wait(0.5); playAnim(CFG.AnimId) end
end

conn(LP.CharacterAdded, onCharacter)
if LP.Character then task.spawn(onCharacter, LP.Character) end

--== 16. Инициализация ==--
setFOV(CFG.FOV)
if CFG.Fullbright then setFullbright(true) elseif CFG.Sky ~= "По умолчанию" then applySky(CFG.Sky) end
toast("SleepScript загружен  |  Z — меню", COL.accent)

--== 17. Выгрузка ==--
function API.Unload()
	for _, c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end
	stopAnim()
	if flyBV then flyBV:Destroy() end
	if flyBG then flyBG:Destroy() end
	resetLighting()
	local cam = getCam()
	if cam then cam.FieldOfView = 70 end
	local c = getChar()
	if c then
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Transparency = 0
				d.CanCollide = true
			end
		end
		local hum = getHum(c)
		if hum then hum.PlatformStand = false end
	end
	pcall(function() gui:Destroy() end)
	if getgenv then getgenv().SleepScript = nil end
end
