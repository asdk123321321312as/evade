--=========================================================================
--  SleepScript  v1.2   |   Evade   |   client-side
--  Меню: Z   |   Анимация: G   |   Полёт: F
--=========================================================================

if getgenv and getgenv().SleepScript and getgenv().SleepScript.Unload then
	pcall(getgenv().SleepScript.Unload)
end

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Lighting     = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")

local LP  = Players.LocalPlayer
local API = {}
if getgenv then getgenv().SleepScript = API end

--== 1. Конфиг ==--
local CFG = {
	MenuKey        = "Z",
	FOV            = 85,
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
	FlyKey         = "F",
	ACBypass       = true,
	AnimId         = "",
	AnimName       = "—",
	AnimLoop       = true,
	AnimSpeed      = 1,
	AnimKey        = "G",
	AnimPriority   = "Action4",
	LocalAnimator  = false,
}

local COL = {
	bg     = Color3.fromRGB(9, 9, 11),
	panel  = Color3.fromRGB(15, 15, 18),
	panel2 = Color3.fromRGB(22, 22, 27),
	line   = Color3.fromRGB(40, 40, 48),
	text   = Color3.fromRGB(236, 236, 242),
	dim    = Color3.fromRGB(138, 138, 150),
	accent = Color3.fromRGB(132, 112, 255),
	off    = Color3.fromRGB(42, 42, 50),
	good   = Color3.fromRGB(92, 220, 140),
	bad    = Color3.fromRGB(240, 100, 110),
}

local CONFIG_FILE = "SleepScript_Evade.json"
local ANIM_CACHE  = "SleepScript_EvadeAnim.json"

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

local function makeGui(name, order)
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.DisplayOrder = order or 999
	local placed = false
	if gethui then
		pcall(function() g.Parent = gethui(); placed = true end)
	end
	if not placed then
		pcall(function() g.Parent = game:GetService("CoreGui"); placed = true end)
	end
	if not placed then g.Parent = LP:WaitForChild("PlayerGui") end
	return g
end

--== 3. GUI ==--
local gui       = makeGui("SleepScript", 999)
local guiNotify = makeGui("SleepScriptNotify", 1000)

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

local header = new("Frame", {
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = COL.panel,
	BorderSizePixel = 0,
}, main)
corner(10, header)

new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0, 220, 1, 0),
	Font = Enum.Font.GothamBold, Text = "SleepScript", TextColor3 = COL.text,
	TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
}, header)

new("TextLabel", {
	BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -62, 0.5, 0),
	Size = UDim2.new(0, 120, 1, 0), Font = Enum.Font.GothamMedium, Text = "v1.2  •  Evade",
	TextColor3 = COL.dim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right,
}, header)

local function headerBtn(txt, xOff, fn)
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0),
		Size = UDim2.new(0, 22, 0, 22), BackgroundColor3 = COL.panel2,
		Font = Enum.Font.GothamBold, Text = txt, TextColor3 = COL.text,
		TextSize = 12, AutoButtonColor = false,
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

do
	local dragging, dragStart, startPos = false, nil, nil
	conn(header.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, input.Position, main.Position
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

local TABS = { "Визуал", "Персонаж", "Анимации", "Прочее" }
local tabBar = new("Frame", {
	Position = UDim2.new(0, 8, 0, 38), Size = UDim2.new(1, -16, 0, 24), BackgroundTransparency = 1,
}, main)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabBar)

local pages, tabBtns = {}, {}

local function makePage()
	local page = new("Frame", {
		BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 68),
		Size = UDim2.new(1, 0, 1, -68), Visible = false,
	}, main)
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -20, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
		ScrollBarImageColor3 = COL.line, BorderSizePixel = 0,
	}, page)
	new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 12) }, scroll)
	return page, scroll
end

local SCROLLS = {}
for i, name in ipairs(TABS) do
	local page, scroll = makePage()
	pages[i] = page
	SCROLLS[i] = scroll
	local btn = new("TextButton", {
		Size = UDim2.new(0, 96, 1, 0), BackgroundColor3 = COL.panel,
		Font = Enum.Font.GothamMedium, Text = name, TextColor3 = COL.dim,
		TextSize = 12, AutoButtonColor = false,
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

local scrollVisual, scrollChar, scrollAnim, scrollMisc =
	SCROLLS[1], SCROLLS[2], SCROLLS[3], SCROLLS[4]

local activeSlider = nil

local function makeSlider(parent, label, min, max, default, step, onChange)
	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34) }, parent)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(0.65, 0, 0, 15), Font = Enum.Font.GothamMedium,
		Text = label, TextColor3 = COL.text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
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
		BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0.5, -9), Size = UDim2.new(1, 0, 0, 18), Text = "",
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
		BackgroundTransparency = 1, Size = UDim2.new(0.78, 0, 1, 0), Font = Enum.Font.GothamMedium,
		Text = label, TextColor3 = COL.text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
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
		BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0), Font = Enum.Font.GothamMedium,
		Text = label, TextColor3 = COL.text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 78, 0, 21), BackgroundColor3 = COL.panel2,
		Font = Enum.Font.GothamBold, Text = default or "—", TextColor3 = COL.text,
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
		Size = UDim2.new(1, 0, 0, height or 26), BackgroundColor3 = COL.panel2,
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
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold,
		Text = text, TextColor3 = COL.accent, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
end

local function makeLabel(parent, text, color, height)
	return new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height or 16), Font = Enum.Font.Gotham,
		Text = text, TextColor3 = color or COL.dim, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
	}, parent)
end

local function makeTextBox(parent, placeholder, default, fn)
	local t = new("TextBox", {
		Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = COL.panel2, Font = Enum.Font.Gotham,
		PlaceholderText = placeholder, Text = default or "", TextColor3 = COL.text,
		TextSize = 12, PlaceholderColor3 = COL.dim, ClearTextOnFocus = false,
	}, parent)
	corner(6, t)
	stroke(t, COL.line, 1)
	if fn then conn(t.FocusLost, function() fn(t.Text) end) end
	return t
end

local toastHolder = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40),
	Size = UDim2.new(0, 300, 0, 100), BackgroundTransparency = 1,
}, guiNotify)
new("UIListLayout", {
	Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
}, toastHolder)

local function toast(text, color)
	local f = new("Frame", { Size = UDim2.new(0, 280, 0, 24), BackgroundColor3 = COL.panel, BackgroundTransparency = 1 }, toastHolder)
	corner(6, f)
	stroke(f, color or COL.accent, 1)
	local l = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamMedium,
		Text = text, TextColor3 = COL.text, TextSize = 11,
	}, f)
	TweenService:Create(f, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(l, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()
	task.delay(2, function()
		TweenService:Create(f, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(l, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		task.wait(0.3)
		if f and f.Parent then f:Destroy() end
	end)
end

--== 4. Свет: оригинал ==--
local ORIG = {
	ClockTime = Lighting.ClockTime, Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness,
	FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, FogColor = Lighting.FogColor,
	ColorShift_Top = Lighting.ColorShift_Top, ColorShift_Bottom = Lighting.ColorShift_Bottom,
	GlobalShadows = Lighting.GlobalShadows, ExposureCompensation = Lighting.ExposureCompensation,
	Outlines = Lighting.Outlines,
}

--== 5. FOV (жёсткий перехват) ==--
local fovConn = nil

local function setFOV(v)
	CFG.FOV = v
	local cam = workspace.CurrentCamera
	if cam then cam.FieldOfView = v end
end

local function hookCamera()
	if fovConn then pcall(function() fovConn:Disconnect() end) end
	local cam = workspace.CurrentCamera
	if not cam then return end
	fovConn = cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
		if CFG.FOVLock and math.abs(cam.FieldOfView - CFG.FOV) > 0.01 then
			cam.FieldOfView = CFG.FOV
		end
	end)
end
conn(workspace:GetPropertyChangedSignal("CurrentCamera"), hookCamera)
hookCamera()

RunService:BindToRenderStep("SleepScript_FOV", Enum.RenderPriority.Camera.Value + 1, function()
	if CFG.FOVLock then
		local cam = workspace.CurrentCamera
		if cam and math.abs(cam.FieldOfView - CFG.FOV) > 0.01 then
			cam.FieldOfView = CFG.FOV
		end
	end
end)

--== 6. Свет / небо ==--
local function resetLighting()
	for k, v in pairs(ORIG) do
		pcall(function() Lighting[k] = v end)
	end
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
	{ name = "Ночь", clock = 0, ambient = Color3.fromRGB(18, 18, 26), outdoor = Color3.fromRGB(28, 28, 42),
	  bright = 1, fogEnd = 600, fogColor = Color3.fromRGB(12, 12, 22), stars = 3000, celestial = true },
	{ name = "Космос", clock = 0, ambient = Color3.fromRGB(8, 8, 14), outdoor = Color3.fromRGB(12, 12, 20),
	  bright = 0.6, fogEnd = 3000, fogColor = Color3.fromRGB(5, 5, 12), stars = 8000, celestial = false, box = "Космос" },
	{ name = "Кровавая луна", clock = 0, ambient = Color3.fromRGB(30, 10, 10), outdoor = Color3.fromRGB(45, 14, 14),
	  bright = 1, fogEnd = 400, fogColor = Color3.fromRGB(40, 8, 8), stars = 2000, celestial = true,
	  tint = Color3.fromRGB(130, 25, 25) },
	{ name = "Туман", clock = 6, ambient = Color3.fromRGB(60, 62, 66), outdoor = Color3.fromRGB(70, 72, 76),
	  bright = 1.4, fogEnd = 60, fogStart = 0, fogColor = Color3.fromRGB(120, 124, 130), stars = 0, celestial = false },
	{ name = "Пустота", clock = 0, ambient = Color3.new(0, 0, 0), outdoor = Color3.new(0, 0, 0),
	  bright = 0.5, fogEnd = 1000, fogColor = Color3.new(0, 0, 0), stars = 0, celestial = false },
	{ name = "День", clock = 14, ambient = Color3.fromRGB(120, 120, 120), outdoor = Color3.fromRGB(130, 130, 130),
	  bright = 2, fogEnd = 2000, stars = 0, celestial = true },
}

local function applySky(name)
	CFG.Sky = name
	resetLighting()
	if name == "По умолчанию" or name == "Своя" then return end
	for _, p in ipairs(SKY_PRESETS) do
		if p.name == name then
			if p.clock then Lighting.ClockTime = p.clock end
			if p.ambient then Lighting.Ambient = p.ambient end
			if p.outdoor then Lighting.OutdoorAmbient = p.outdoor end
			if p.bright then Lighting.Brightness = p.bright end
			if p.fogEnd then Lighting.FogEnd = p.fogEnd end
			if p.fogStart then Lighting.FogStart = p.fogStart end
			if p.fogColor then Lighting.FogColor = p.fogColor end
			if p.tint then
				Lighting.ColorShift_Top = p.tint
				Lighting.ColorShift_Bottom = p.tint
			end
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

--== 7. Персонаж ==--
local KORBLOX_ID = 139607718
local origRightLeg = nil

local function getChar() return LP.Character end
local function getHum(c)
	c = c or getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function applyHeadless(on)
	local head = getChar() and getChar():FindFirstChild("Head")
	if not head then return end
	head.Transparency = on and 1 or 0
	local face = head:FindFirstChildOfClass("Decal")
	if face then face.Transparency = on and 1 or 0 end
end

local function applyKorblox(on)
	local c = getChar()
	local hum = getHum(c)
	if not hum or not c then return end
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
end

--== 8. Анимации ==--
local PRIORITY = {
	Core = Enum.AnimationPriority.Core, Idle = Enum.AnimationPriority.Idle,
	Movement = Enum.AnimationPriority.Movement, Action = Enum.AnimationPriority.Action,
	Action2 = Enum.AnimationPriority.Action2, Action3 = Enum.AnimationPriority.Action3,
	Action4 = Enum.AnimationPriority.Action4,
}

local currentTrack = nil
local animStatus = nil

local function getDefaultAnimator()
	local hum = getHum()
	if not hum then return nil end
	return hum:FindFirstChildOfClass("Animator")
end

local function getLocalAnimator()
	local hum = getHum()
	if not hum then return nil end
	local a = hum:FindFirstChild("SleepAnimator")
	if not a then
		a = Instance.new("Animator")
		a.Name = "SleepAnimator"
		a.Parent = hum
	end
	return a
end

local function removeLocalAnimator()
	local hum = getHum()
	if not hum then return end
	local a = hum:FindFirstChild("SleepAnimator")
	if a then a:Destroy() end
end

local function stopAnim()
	if currentTrack then
		pcall(function() currentTrack:Stop(0.15) end)
		currentTrack = nil
	end
	if animStatus then animStatus.Text = "Статус: стоп" end
end

local function playAnim(id)
	if not id or id == "" then
		toast("Введи ID анимации", COL.bad)
		return
	end
	local hum = getHum()
	if not hum then
		toast("Нет персонажа", COL.bad)
		return
	end
	stopAnim()

	local animator
	if CFG.LocalAnimator then
		animator = getLocalAnimator()
	else
		animator = hum:FindFirstChildOfClass("Animator") or getLocalAnimator()
	end
	if not animator then
		toast("Animator не найден", COL.bad)
		return
	end

	local full = id:match("^%d+$") and ("rbxassetid://" .. id) or id
	local anim = Instance.new("Animation")
	anim.AnimationId = full
	pcall(function() ContentProvider:PreloadAsync({ anim }) end)

	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if not ok or not track then
		toast("Не удалось: " .. id, COL.bad)
		return
	end

	track.Priority = PRIORITY[CFG.AnimPriority] or Enum.AnimationPriority.Action4
	track.Looped = CFG.AnimLoop
	track:Play(0.1)
	track:AdjustSpeed(CFG.AnimSpeed)
	currentTrack = track
	if animStatus then animStatus.Text = "Статус: играет" end
	toast("Анимация: " .. tostring(CFG.AnimName))
end

local function toggleAnim()
	if currentTrack and currentTrack.IsPlaying then
		stopAnim()
	else
		playAnim(CFG.AnimId)
	end
end

--== 9. Полёт / ноклип ==--
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
	local cam = workspace.CurrentCamera
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
			d.Collide = not on
			d.CanCollide = not on
		end
	end
end

--== 10. UI: Визуал ==--
makeSection(scrollVisual, "КАМЕРА")
makeSlider(scrollVisual, "FOV", 40, 130, CFG.FOV, 1, function(v)
	setFOV(v)
end)
makeToggle(scrollVisual, "Держать FOV (перехват)", CFG.FOVLock, function(v) CFG.FOVLock = v end)
local fovLive = makeLabel(scrollVisual, "текущий FOV: " .. tostring(math.floor(CFG.FOV)), COL.good)

makeSection(scrollVisual, "НЕБО И СВЕТ")
local skyLabel = makeLabel(scrollVisual, "Пресет: " .. tostring(CFG.Sky), COL.text)
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
	setCustomSkybox({ bk = boxBk.Text, dn = boxDn.Text, ft = boxFt.Text,
		lf = boxLf.Text, rt = boxRt.Text, up = boxUp.Text })
end)

--== 11. UI: Персонаж ==--
makeSection(scrollChar, "ВНЕШКА (локально)")
makeToggle(scrollChar, "Headless", CFG.Headless, function(v)
	CFG.Headless = v
	applyHeadless(v)
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
	if v then
		applyInvisible(true)
	else
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
	if hum then pcall(function() hum[prop] = v end) end
end
makeSlider(scrollChar, "Рост", 0.6, 1.4, 1, 0.05, function(v) scaleSet("BodyHeightScale", v) end)
makeSlider(scrollChar, "Ширина", 0.6, 1.4, 1, 0.05, function(v) scaleSet("BodyWidthScale", v) end)
makeSlider(scrollChar, "Глубина", 0.6, 1.4, 1, 0.05, function(v) scaleSet("BodyDepthScale", v) end)
makeSlider(scrollChar, "Голова", 0.6, 1.4, 1, 0.05, function(v) scaleSet("HeadScale", v) end)

--== 12. UI: Анимации ==--
makeSection(scrollAnim, "СВОЯ АНИМАЦИЯ (по ID)")
local animLabel = makeLabel(scrollAnim, "Сейчас: " .. tostring(CFG.AnimName), COL.text)
local animIdBox = makeTextBox(scrollAnim, "ID анимации (только цифры)", CFG.AnimId, function(txt)
	txt = txt:gsub("[^%d]", "")
	CFG.AnimId = txt
	CFG.AnimName = "ID " .. txt
	animLabel.Text = "Сейчас: " .. CFG.AnimName
end)
animStatus = makeLabel(scrollAnim, "Статус: стоп", COL.dim)

makeButton(scrollAnim, "▶  Играть (по кнопке " .. CFG.AnimKey .. " тоже)", function() playAnim(CFG.AnimId) end)
makeButton(scrollAnim, "■  Стоп", function() stopAnim() end)
makeKeybind(scrollAnim, "Кнопка вкл/выкл анимации", CFG.AnimKey, function(k) CFG.AnimKey = k end)
makeToggle(scrollAnim, "Зациклить", CFG.AnimLoop, function(v)
	CFG.AnimLoop = v
	if currentTrack then currentTrack.Looped = v end
end)
makeSlider(scrollAnim, "Скорость", 0.1, 4, CFG.AnimSpeed, 0.05, function(v)
	CFG.AnimSpeed = v
	if currentTrack then pcall(function() currentTrack:AdjustSpeed(v) end) end
end)

makeSection(scrollAnim, "РЕЖИМ")
local prioLabel = makeLabel(scrollAnim, "Приоритет: " .. tostring(CFG.AnimPriority), COL.text)
local PRIO_LIST = { "Core", "Idle", "Movement", "Action", "Action2", "Action3", "Action4" }
local prioIndex = 7
for i, n in ipairs(PRIO_LIST) do
	if n == CFG.AnimPriority then prioIndex = i end
end
makeButton(scrollAnim, "Сменить приоритет →", function()
	prioIndex = prioIndex % #PRIO_LIST + 1
	CFG.AnimPriority = PRIO_LIST[prioIndex]
	prioLabel.Text = "Приоритет: " .. CFG.AnimPriority
	if currentTrack then currentTrack.Priority = PRIORITY[CFG.AnimPriority] end
end)
makeToggle(scrollAnim, "Полностью клиентская (свой Animator)", CFG.LocalAnimator, function(v)
	CFG.LocalAnimator = v
	if v then
		getLocalAnimator()
		toast("Режим: сервер не видит анимацию")
	else
		stopAnim()
		removeLocalAnimator()
		toast("Режим: обычный Animator")
	end
end)
makeLabel(scrollAnim, "Выкл — работает всегда и перебивает ходьбу (но трек уходит на сервер). Вкл — 100% локально, сервер и другие игроки не видят.", COL.dim)

makeSection(scrollAnim, "СПИСОК АНИМАЦИЙ ИГРЫ")
makeLabel(scrollAnim, "Собирает анимации, лежащие внутри Evade (в т.ч. старые/ивентовые с 2022). Кэшируется в файл.", COL.dim)
local searchBox = makeTextBox(scrollAnim, "фильтр по названию...", "")
local animList = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 0, 140), BackgroundColor3 = COL.panel, BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 3, ScrollBarImageColor3 = COL.line,
}, scrollAnim)
corner(6, animList)
stroke(animList, COL.line, 1)
new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, animList)
new("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 6),
	PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 5) }, animList)

local scanned = {}

local function renderList()
	for _, c in ipairs(animList:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
	end
	local filter = searchBox.Text:lower()
	local shown = 0
	for _, item in ipairs(scanned) do
		if shown >= 120 then break end
		if filter == "" or item.name:lower():find(filter, 1, true) then
			shown += 1
			local idShort = item.id:gsub("rbxassetid://", "")
			local b = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = COL.panel2, Font = Enum.Font.Gotham,
				Text = item.name .. "  [" .. idShort .. "]", TextColor3 = COL.text,
				TextSize = 10, AutoButtonColor = false,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, animList)
			corner(4, b)
			conn(b.MouseButton1Click, function()
				CFG.AnimId = idShort
				CFG.AnimName = item.name
				animLabel.Text = "Сейчас: " .. CFG.AnimName
				animIdBox.Text = CFG.AnimId
				playAnim(CFG.AnimId)
			end)
		end
	end
	if shown == 0 then
		new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.Gotham,
			Text = "Пусто — нажми «Собрать анимации»", TextColor3 = COL.dim, TextSize = 10,
		}, animList)
	end
end
conn(searchBox:GetPropertyChangedSignal("Text"), renderList)

local function saveCache()
	if not writefile then return end
	pcall(function() writefile(ANIM_CACHE, HttpService:JSONEncode(scanned)) end)
end

local function loadCache()
	if not readfile or not isfile then return end
	pcall(function()
		if isfile(ANIM_CACHE) then
			local data = HttpService:JSONDecode(readfile(ANIM_CACHE))
			if type(data) == "table" and #data > 0 then
				scanned = data
				renderList()
			end
		end
	end)
end

makeButton(scrollAnim, "Собрать анимации (быстро)", function()
	task.spawn(function()
		local roots = {}
		local rs = game:GetService("ReplicatedStorage")
		table.insert(roots, rs)
		for _, n in ipairs({ "Animations", "Emotes", "Anim", "Shared", "Assets", "Modules" }) do
			local f = rs:FindFirstChild(n)
			if f then table.insert(roots, f) end
		end
		table.insert(roots, workspace)

		local seen, out = {}, {}
		for _, root in ipairs(roots) do
			for _, obj in ipairs(root:GetDescendants()) do
				if obj:IsA("Animation") then
					local id = obj.AnimationId
					if id and id ~= "" and not seen[id] then
						seen[id] = true
						table.insert(out, { name = obj:GetFullName(), id = id })
					end
				end
			end
		end
		table.sort(out, function(a, b) return a.name < b.name end)
		scanned = out
		renderList()
		saveCache()
		toast("Найдено анимаций: " .. #out, #out > 0 and COL.good or COL.bad)
	end)
end)
loadCache()

makeSection(scrollAnim, "ГОТОВЫЕ (R15 — актуальный риг Evade)")
local R15 = {
	{ "Idle 1", "507766666" }, { "Idle 2", "782845736" }, { "Walk", "507777826" },
	{ "Run", "507767714" }, { "Jump", "507765000" }, { "Fall", "507767968" },
	{ "Swim", "507784897" }, { "Climb", "507765644" }, { "Wave", "507770239" },
	{ "Point", "507770453" }, { "Dance 1", "507771019" }, { "Dance 2", "507771955" },
	{ "Dance 3", "507772104" }, { "Dance 2A", "507776043" }, { "Dance 3A", "507777268" },
	{ "Laugh", "507770818" }, { "Cheer", "507770677" }, { "Sit", "507768133" },
}
for _, a in ipairs(R15) do
	makeButton(scrollAnim, a[1] .. "  •  " .. a[2], function()
		CFG.AnimId, CFG.AnimName = a[2], "R15 " .. a[1]
		animLabel.Text = "Сейчас: " .. CFG.AnimName
		animIdBox.Text = a[2]
		playAnim(a[2])
	end, 22)
end

makeSection(scrollAnim, "ГОТОВЫЕ (R6 — классика)")
local R6 = {
	{ "Idle 1", "180435571" }, { "Idle 2", "180435792" }, { "Walk", "180426354" },
	{ "Jump", "125750702" }, { "Fall", "180436148" }, { "Climb", "180436334" },
	{ "Wave", "128777973" }, { "Point", "128853357" }, { "Dance 1", "182435998" },
	{ "Dance 2", "182436842" }, { "Dance 3", "182436976" }, { "Laugh", "129423131" },
	{ "Cheer", "129423030" },
}
for _, a in ipairs(R6) do
	makeButton(scrollAnim, a[1] .. "  •  " .. a[2], function()
		CFG.AnimId, CFG.AnimName = a[2], "R6 " .. a[1]
		animLabel.Text = "Сейчас: " .. CFG.AnimName
		animIdBox.Text = a[2]
		playAnim(a[2])
	end, 22)
end

--== 13. UI: Прочее ==--
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
acToggles.jump = makeToggle(scrollMisc, "Держать JumpPower", CFG.KeepJump, function(v) CFG.KeepJump = v end)
acToggles.fov = makeToggle(scrollMisc, "Держать FOV", CFG.FOVLock, function(v) CFG.FOVLock = v end)
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
makeToggle(scrollMisc, "Полёт", CFG.Fly, function(v)
	CFG.Fly = v
	setFly(v)
end)
makeKeybind(scrollMisc, "Кнопка полёта", CFG.FlyKey, function(k) CFG.FlyKey = k end)
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
makeButton(scrollMisc, "Сохранить конфиг", function()
	saveCFG()
	toast("Конфиг сохранён", COL.good)
end)
makeButton(scrollMisc, "Загрузить конфиг", function()
	loadCFG()
	toast("Конфиг загружен", COL.good)
end)
makeButton(scrollMisc, "Выгрузить SleepScript", function()
	if API.Unload then API.Unload() end
end)

makeLabel(scrollMisc, CFG.MenuKey .. " — меню  •  " .. CFG.AnimKey .. " — анимация  •  " .. CFG.FlyKey .. " — полёт", COL.dim)

--== 14. Ввод ==--
conn(UIS.InputBegan, function(input)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	local name = input.KeyCode.Name
	if listeningKey then
		listeningKey(name)
		listeningKey = nil
		return
	end
	if UIS:GetFocusedTextBox() then return end
	if name == CFG.MenuKey then
		gui.Enabled = not gui.Enabled
	elseif name == CFG.AnimKey then
		toggleAnim()
	elseif name == CFG.FlyKey then
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

--== 15. Главный цикл ==--
local acc = { korblox = 0, appearance = 0, suppress = 0, fov = 0 }

conn(RunService.RenderStepped, function(dt)
	local c = getChar()
	local hum = getHum(c)

	if hum then
		if CFG.KeepSpeed and hum.WalkSpeed ~= CFG.Speed then hum.WalkSpeed = CFG.Speed end
		if CFG.KeepJump and hum.JumpPower ~= CFG.Jump then
			hum.UseJumpPower = true
			hum.JumpPower = CFG.Jump
		end
	end

	if CFG.NoClip then applyNoClip(true) end
	if CFG.Fly then flyStep() end

	-- в локальном режиме глушим дефолтные треки, чтобы не было смешивания
	if CFG.LocalAnimator and currentTrack and currentTrack.IsPlaying then
		acc.suppress += dt
		if acc.suppress >= 0.08 then
			acc.suppress = 0
			local da = getDefaultAnimator()
			if da then
				for _, t in ipairs(da:GetPlayingAnimationTracks()) do
					pcall(function() t:Stop(0.08) end)
				end
			end
		end
	end

	acc.appearance += dt
	if acc.appearance >= 0.35 then
		acc.appearance = 0
		if c then
			local head = c:FindFirstChild("Head")
			if CFG.Headless and head and head.Transparency ~= 1 then applyHeadless(true) end
			if CFG.NoAccessories then applyAccessories(true) end
			if CFG.Invisible then
				for _, d in ipairs(c:GetDescendants()) do
					if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency ~= 1 then
						d.Transparency = 1
					end
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

	acc.fov += dt
	if acc.fov >= 0.25 and fovLive then
		acc.fov = 0
		local cam = workspace.CurrentCamera
		if cam then fovLive.Text = "текущий FOV: " .. tostring(math.floor(cam.FieldOfView + 0.5)) end
	end
end)

--== 16. Респавн ==--
local function onCharacter(char)
	currentTrack = nil
	origRightLeg = nil
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	task.wait(0.4)
	if CFG.KeepSpeed then hum.WalkSpeed = CFG.Speed end
	if CFG.KeepJump then
		hum.UseJumpPower = true
		hum.JumpPower = CFG.Jump
	end
	if CFG.Headless then applyHeadless(true) end
	if CFG.NoAccessories then applyAccessories(true) end
	if CFG.Invisible then applyInvisible(true) end
	if CFG.Korblox then task.wait(0.5); applyKorblox(true) end
	if CFG.AnimId ~= "" then task.wait(0.5); playAnim(CFG.AnimId) end
end

conn(LP.CharacterAdded, onCharacter)
if LP.Character then task.spawn(onCharacter, LP.Character) end

--== 17. Инициализация ==--
setFOV(CFG.FOV)
if CFG.Fullbright then setFullbright(true) elseif CFG.Sky ~= "По умолчанию" then applySky(CFG.Sky) end
if CFG.LocalAnimator then getLocalAnimator() end
toast("SleepScript v1.2 загружен  |  " .. CFG.MenuKey .. " — меню", COL.accent)

--== 18. Выгрузка ==--
function API.Unload()
	for _, c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end
	pcall(function() RunService:UnbindFromRenderStep("SleepScript_FOV") end)
	if fovConn then pcall(function() fovConn:Disconnect() end) end
	stopAnim()
	removeLocalAnimator()
	if flyBV then flyBV:Destroy() end
	if flyBG then flyBG:Destroy() end
	resetLighting()
	local cam = workspace.CurrentCamera
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
	pcall(function() guiNotify:Destroy() end)
	if getgenv then getgenv().SleepScript = nil end
end
