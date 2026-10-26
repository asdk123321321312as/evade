--=========================================================================
--  SleepScript  v1.6   |   Evade   |   client-side
--  Меню: Z
--  Осталось: FOV, небо/свет, Headless, Korblox (правая нога)
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

local LP  = Players.LocalPlayer
local API = {}
if getgenv then getgenv().SleepScript = API end

--== 1. Конфиг ==--
local CFG = {
	MenuKey    = "Z",
	FOV        = 85,
	FOVLock    = true,
	Fullbright = false,
	Sky        = "По умолчанию",
	KeepLook   = true,
	Headless   = false,
	NoRightLeg = false,
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
	Size = UDim2.new(0, 480, 0, 300),
	Position = UDim2.new(0.5, -240, 0.5, -150),
	BackgroundColor3 = COL.bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
corner(10, main)
stroke(main, COL.line, 1)

local header = new("Frame", {
	Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = COL.panel, BorderSizePixel = 0,
}, main)
corner(10, header)

new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0, 220, 1, 0),
	Font = Enum.Font.GothamBold, Text = "SleepScript", TextColor3 = COL.text,
	TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
}, header)

new("TextLabel", {
	BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -62, 0.5, 0),
	Size = UDim2.new(0, 120, 1, 0), Font = Enum.Font.GothamMedium, Text = "v1.6  •  Evade",
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
	main.Size = minimized and UDim2.new(0, 480, 0, 34) or UDim2.new(0, 480, 0, 300)
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

local TABS = { "Визуал", "Персонаж", "Прочее" }
local tabBar = new("Frame", {
	Position = UDim2.new(0, 8, 0, 38), Size = UDim2.new(1, -16, 0, 24), BackgroundTransparency = 1,
}, main)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabBar)

local pages, tabBtns, SCROLLS = {}, {}, {}

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

for i, name in ipairs(TABS) do
	local page, scroll = makePage()
	pages[i] = page
	SCROLLS[i] = scroll
	local btn = new("TextButton", {
		Size = UDim2.new(0, 110, 1, 0), BackgroundColor3 = COL.panel,
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

local scrollVisual, scrollChar, scrollMisc = SCROLLS[1], SCROLLS[2], SCROLLS[3]

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
		if onChange then pcall(onChange, state) end
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
	conn(b.MouseButton1Click, function() pcall(fn) end)
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
	local f = new("Frame", { Size = UDim2.new(0, 300, 0, 24), BackgroundColor3 = COL.panel, BackgroundTransparency = 1 }, toastHolder)
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

--== 5. FOV ==--
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

pcall(function()
	RunService:BindToRenderStep("SleepScript_FOV", Enum.RenderPriority.Camera.Value + 1, function()
		if CFG.FOVLock then
			local cam = workspace.CurrentCamera
			if cam and math.abs(cam.FieldOfView - CFG.FOV) > 0.01 then
				cam.FieldOfView = CFG.FOV
			end
		end
	end)
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

--== 7. Поиск персонажа (4 независимых способа) ==--
local function humIn(model)
	if not model then return nil end
	return model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildWhichIsA("Humanoid", true)
end

local function searchByName(root, depth)
	if depth > 3 or not root then return nil end
	for _, d in ipairs(root:GetChildren()) do
		if d:IsA("Model") and d.Name == LP.Name and humIn(d) then return d end
		if d:IsA("Model") or d:IsA("Folder") then
			local r = searchByName(d, depth + 1)
			if r then return r end
		end
	end
	return nil
end

local charSource = "?"

local function getChar()
	-- 1. стандартный путь
	local c = LP.Character
	if c and c.Parent and humIn(c) then
		charSource = "Player.Character"
		return c
	end

	-- 2. тело, которым управляет камера (самый надёжный путь в играх с нестандартным спавном)
	local cam = workspace.CurrentCamera
	local subj = cam and cam.CameraSubject
	if subj and subj:IsA("Humanoid") and subj.Parent then
		charSource = "CameraSubject"
		return subj.Parent
	end

	-- 3. поиск модели с нашим ником (включая вложенные папки)
	local byName = searchByName(workspace, 0)
	if byName then
		charSource = "поиск по нику"
		return byName
	end

	-- 4. что было
	if c and c.Parent then
		charSource = "Player.Character (без Humanoid)"
		return c
	end
	charSource = "не найден"
	return nil
end

local function getHum(c)
	c = c or getChar()
	return humIn(c)
end

--== 8. Детект ноги и головы (4 уровня, без опоры на имена) ==--
local function limbOf(hum, part)
	local ok, limb = pcall(function() return hum:GetLimb(part) end)
	if ok then return limb end
	return nil
end

local function nameHas(name, ...)
	local l = name:lower()
	for _, w in ipairs({ ... }) do
		if l:find(w, 1, true) then return true end
	end
	return false
end

local LEG_NAMES = {
	RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
	["Right Leg"] = true, RightLeg = true, RightLowerLeg = true,
}

local function isRightLeg(hum, part)
	-- уровень 1: GetLimb
	local limb = limbOf(hum, part)
	if limb == Enum.Limb.RightLeg then return true end
	if limb and limb ~= Enum.Limb.Unknown then return false end
	-- уровень 2: точное имя
	if LEG_NAMES[part.Name] then return true end
	-- уровень 3: подстрока
	if nameHas(part.Name, "right") and nameHas(part.Name, "leg", "foot", "knee", "ankle", "hip", "thigh") then
		return true
	end
	-- уровень 4: сустав правого бедра
	for _, j in ipairs(part:GetChildren()) do
		if j:IsA("Motor6D") and nameHas(j.Name, "righthip", "rightknee", "rightankle") then return true end
	end
	return false
end

local function isHeadPart(hum, part)
	local limb = limbOf(hum, part)
	if limb == Enum.Limb.Head then return true end
	if limb and limb ~= Enum.Limb.Unknown then return false end
	if part.Name == "Head" or part.Name:lower() == "head" then return true end
	if nameHas(part.Name, "head") and not nameHas(part.Name, "headphone", "headband") then return true end
	for _, d in ipairs(part:GetChildren()) do
		if d:IsA("Decal") and nameHas(d.Name, "face") then return true end
	end
	return false
end

local function isWeldedTo(acc, part)
	local handle = acc:FindFirstChild("Handle")
	if not handle then return false end
	for _, j in ipairs(handle:GetChildren()) do
		if j:IsA("Weld") or j:IsA("WeldConstraint") or j:IsA("Motor6D") or j:IsA("Snap") then
			if j.Part0 == part or j.Part1 == part then return true end
		end
	end
	return false
end

local cache = { char = nil, hum = nil, leg = {}, legAcc = {}, head = nil, face = nil }
local lastBuild = 0

local function rebuildCache(force)
	local now = os.clock()
	if not force and now - lastBuild < 0.2 then return end
	lastBuild = now

	local c = getChar()
	local hum = getHum(c)
	if not c or not hum then
		cache = { char = nil, hum = nil, leg = {}, legAcc = {}, head = nil, face = nil }
		return
	end
	if cache.char == c and cache.hum == hum and cache.leg[1] and cache.leg[1].Parent == c then return end

	local leg, legAcc, head, face = {}, {}, nil, nil

	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BasePart") then
			if isRightLeg(hum, d) then leg[#leg + 1] = d end
			if isHeadPart(hum, d) then head = d end
		end
	end

	for _, acc in ipairs(c:GetChildren()) do
		if acc:IsA("Accessory") or acc:IsA("Hat") then
			local h = acc:FindFirstChild("Handle")
			if h then
				for _, p in ipairs(leg) do
					if isWeldedTo(acc, p) then legAcc[#legAcc + 1] = h break end
				end
			end
		end
	end

	if head then
		for _, d in ipairs(head:GetChildren()) do
			if d:IsA("Decal") then face = d end
		end
	end

	cache = { char = c, hum = hum, leg = leg, legAcc = legAcc, head = head, face = face }
end

--== 9. Применение ==--
local function enforce()
	if not CFG.KeepLook then return end
	rebuildCache(false)
	if not cache.char then return end

	if CFG.NoRightLeg then
		for _, p in ipairs(cache.leg) do
			if p.Transparency ~= 1 then p.Transparency = 1 end
			if p.CanCollide then p.CanCollide = false end
		end
		for _, h in ipairs(cache.legAcc) do
			if h.Transparency ~= 1 then h.Transparency = 1 end
		end
	end

	if CFG.Headless then
		if cache.head and cache.head.Transparency ~= 1 then cache.head.Transparency = 1 end
		if cache.face and cache.face.Transparency ~= 1 then cache.face.Transparency = 1 end
	end
end

local function reapplyAll()
	rebuildCache(true)
	local c = cache.char
	if not c then return end

	local legSet = {}
	for _, p in ipairs(cache.leg) do legSet[p] = true end
	local legAccSet = {}
	for _, h in ipairs(cache.legAcc) do legAccSet[h] = true end

	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BasePart") then
			if legSet[d] then
				d.Transparency = CFG.NoRightLeg and 1 or 0
				d.CanCollide = not CFG.NoRightLeg
			end
		elseif d:IsA("Accessory") or d:IsA("Hat") then
			local h = d:FindFirstChild("Handle")
			if h and legAccSet[h] then
				h.Transparency = CFG.NoRightLeg and 1 or 0
			end
		end
	end

	if cache.face then cache.face.Transparency = CFG.Headless and 1 or 0 end
	if cache.head then cache.head.Transparency = CFG.Headless and 1 or 0 end
end

--== 10. UI: Визуал ==--
makeSection(scrollVisual, "КАМЕРА")
makeSlider(scrollVisual, "FOV", 40, 130, CFG.FOV, 1, function(v) setFOV(v) end)
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
	reapplyAll()
	if v then
		if cache.head then
			toast("Голова скрыта (" .. cache.head.Name .. ")", COL.good)
		else
			toast("Голова не найдена — смотри строку диагностики", COL.bad)
		end
	end
end)
makeToggle(scrollChar, "Убрать правую ногу (+ одежда на ней)", CFG.NoRightLeg, function(v)
	CFG.NoRightLeg = v
	reapplyAll()
	if v then
		if #cache.leg > 0 then
			toast("Скрыто частей ноги: " .. #cache.leg .. ", одежды: " .. #cache.legAcc, COL.good)
		else
			toast("Правая нога не найдена — смотри диагностику", COL.bad)
		end
	end
end)

local diag = makeLabel(scrollChar, "поиск...", COL.dim, 34)
makeButton(scrollChar, "Переприменить внешку", function()
	reapplyAll()
	toast("Нога: " .. #cache.leg .. " | голова: " .. (cache.head and "есть" or "нет"),
		#cache.leg > 0 and COL.good or COL.bad)
end)

--== 12. UI: Прочее ==--
makeSection(scrollMisc, "ОБХОД АНТИЧИТА")
makeToggle(scrollMisc, "Держать внешку (анти-сброс)", CFG.KeepLook, function(v)
	CFG.KeepLook = v
	reapplyAll()
	toast(v and "Анти-сброс: ВКЛ" or "Анти-сброс: ВЫКЛ")
end)
makeLabel(scrollMisc, "Внешка проверяется каждый кадр и возвращается — игра её не откатит.", COL.dim)

makeSection(scrollMisc, "УТИЛИТЫ")
makeKeybind(scrollMisc, "Кнопка меню", CFG.MenuKey, function(k) CFG.MenuKey = k end)
makeButton(scrollMisc, "Переприменить всё", function()
	reapplyAll()
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

makeLabel(scrollMisc, CFG.MenuKey .. " — открыть/закрыть меню", COL.dim)

--== 13. Ввод ==--
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

--== 14. Цикл ==--
local acc = { diag = 0, fov = 0 }

conn(RunService.RenderStepped, function(dt)
	pcall(enforce)

	acc.diag += dt
	if acc.diag >= 0.5 then
		acc.diag = 0
		pcall(function()
			rebuildCache(true)
			local c, hum = cache.char, cache.hum
			local parts = {}
			if c then
				for _, d in ipairs(c:GetDescendants()) do
					if d:IsA("BasePart") then parts[#parts + 1] = d.Name end
				end
			end
			local legNames = {}
			for _, p in ipairs(cache.leg) do legNames[#legNames + 1] = p.Name end

			diag.Text = string.format(
				"источник: %s | персонаж: %s | Humanoid: %s | частей: %d\nнога: %s | голова: %s\nимена: %s",
				charSource, tostring(c ~= nil), tostring(hum ~= nil), #parts,
				#legNames > 0 and table.concat(legNames, ", ") or "НЕТ",
				cache.head and cache.head.Name or "НЕТ",
				table.concat(parts, ", ", 1, math.min(#parts, 12)))
		end)
	end

	acc.fov += dt
	if acc.fov >= 0.25 and fovLive then
		acc.fov = 0
		local cam = workspace.CurrentCamera
		if cam then fovLive.Text = "текущий FOV: " .. tostring(math.floor(cam.FieldOfView + 0.5)) end
	end
end)

--== 15. Респавн ==--
local function onCharacter(char)
	cache = { char = nil, hum = nil, leg = {}, legAcc = {}, head = nil, face = nil }
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	task.wait(0.4)
	reapplyAll()
end

conn(LP.CharacterAdded, onCharacter)
if LP.Character then task.spawn(onCharacter, LP.Character) end

--== 16. Инициализация ==--
setFOV(CFG.FOV)
if CFG.Fullbright then setFullbright(true) elseif CFG.Sky ~= "По умолчанию" then applySky(CFG.Sky) end
task.spawn(function()
	task.wait(1)
	reapplyAll()
end)
toast("SleepScript v1.6 загружен  |  " .. CFG.MenuKey .. " — меню", COL.accent)

--== 17. Выгрузка ==--
function API.Unload()
	for _, c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end
	pcall(function() RunService:UnbindFromRenderStep("SleepScript_FOV") end)
	if fovConn then pcall(function() fovConn:Disconnect() end) end
	resetLighting()
	local cam = workspace.CurrentCamera
	if cam then cam.FieldOfView = 70 end
	local c = cache.char or LP.Character
	if c then
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Transparency = 0
				d.CanCollide = true
			end
			if d:IsA("Decal") then d.Transparency = 0 end
		end
	end
	pcall(function() gui:Destroy() end)
	pcall(function() guiNotify:Destroy() end)
	if getgenv then getgenv().SleepScript = nil end
end
