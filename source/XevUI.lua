local XevUI = {}
XevUI.Flags = {}
XevUI.Debug = false

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")

local function log(...) if XevUI.Debug then print("[XevUI]", ...) end end

XevUI.Theme = {
    Background   = Color3.fromRGB(15, 13, 13),
    BgGrad       = Color3.fromRGB(25, 22, 22),
    Panel        = Color3.fromRGB(22, 20, 20),
    PanelLight   = Color3.fromRGB(32, 29, 29),
    Element      = Color3.fromRGB(38, 35, 35),
    ElementHover = Color3.fromRGB(52, 47, 47),
    Accent       = Color3.fromRGB(224, 44, 52),
    AccentHover  = Color3.fromRGB(255, 72, 80),
    AccentDark   = Color3.fromRGB(140, 20, 30),
    Stroke       = Color3.fromRGB(45, 40, 40),
    Text         = Color3.fromRGB(238, 235, 235),
    TextDim      = Color3.fromRGB(145, 140, 140),
    TextMuted    = Color3.fromRGB(105, 100, 100),
    Font         = Enum.Font.GothamMedium,
    FontBold     = Enum.Font.GothamBold,
    FontMono     = Enum.Font.Code,
}

local function new(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            local ok, err = pcall(function() inst[k] = v end)
            if not ok then warn("[XevUI] Prop fail:", class, k, err) end
        end
    end
    if props and props.Parent then inst.Parent = props.Parent end
    if children then for _, c in ipairs(children) do c.Parent = inst end end
    return inst
end

local function tween(inst, props, dur, style, dir)
    local t = TweenService:Create(inst,
        TweenInfo.new(dur or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    t:Play(); return t
end

local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = inst
    return c
end

local function pad(inst, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = inst
    return p
end

local function gradient(inst, seq, rot)
    local g = Instance.new("UIGradient")
    g.Color = seq
    g.Rotation = rot or 90
    g.Parent = inst
    return g
end

local function parseAsset(id)
    if not id then return nil end
    if type(id) == "number" then return "rbxassetid://" .. id end
    if type(id) == "string" then
        if tonumber(id) then return "rbxassetid://" .. id end
        return id
    end
    return nil
end

local function resolveParent(mode)
    if typeof(mode) == "Instance" then return mode end
    mode = mode or "PlayerGui"
    if mode == "CoreGui" then
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok and typeof(cg) == "Instance" then
            local test = Instance.new("ScreenGui")
            local p_ok = pcall(function() test.Parent = cg end)
            test:Destroy()
            if p_ok then return cg end
        end
    elseif mode == "gethui" and type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and typeof(hui) == "Instance" then return hui end
    end
    local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then pg = Players.LocalPlayer:WaitForChild("PlayerGui", 5) end
    return pg
end

function XevUI:CreateWindow(config)
    config = config or {}
    local T         = XevUI.Theme
    local title     = config.Title or "XevUI"
    local subtitle  = config.Subtitle or "V1"
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    local width     = config.Width or 440
    local height    = config.Height or 320

    local parent = resolveParent(config.Parent)
    local imageUrl = parseAsset(config.Icon)

    local gui = new("ScreenGui", {
        Name = "XevUI", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999,
        Enabled = true, Parent = parent,
    })

    local wrapper = new("Frame", {
        Name = "Wrapper", Size = UDim2.fromOffset(width, height),
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1, Parent = gui,
    })

    local uiScale = Instance.new("UIScale")
    uiScale.Parent = wrapper

    local visualCenterX, visualCenterY = nil, nil
    local function updateWrapperPos()
        if not visualCenterX or not visualCenterY then return end
        local s = uiScale.Scale
        if s <= 0 then return end
        wrapper.Position = UDim2.fromOffset(visualCenterX / s, visualCenterY / s)
    end

    local main = new("Frame", {
        Name = "Main", Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = T.Stroke, BorderSizePixel = 0,
        ClipsDescendants = false, Visible = true, Parent = wrapper,
    })
    corner(main, 10)

    local innerMain = new("Frame", {
        Name = "InnerMain", Size = UDim2.new(1, -2, 1, -2), Position = UDim2.fromOffset(1, 1),
        BackgroundColor3 = T.Background, BorderSizePixel = 0,
        ClipsDescendants = true, Parent = main,
    })
    corner(innerMain, 9)

    local mainGrad = new("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Background,
        BorderSizePixel = 0, ZIndex = 0, Parent = innerMain,
    })
    corner(mainGrad, 9)
    gradient(mainGrad, ColorSequence.new{
        ColorSequenceKeypoint.new(0, T.BgGrad),
        ColorSequenceKeypoint.new(1, T.Background),
    }, 90)

    local function computeScale()
        local cam = workspace.CurrentCamera
        if not cam then return 1 end
        local vp = cam.ViewportSize
        local sx = (vp.X - 40) / width
        local sy = (vp.Y - 40) / height
        return math.clamp(math.min(sx, sy), 0.55, 1)
    end

    local targetScale = computeScale()
    uiScale.Scale = targetScale * 0.85
    task.defer(function()
        tween(uiScale, {Scale = targetScale}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    uiScale:GetPropertyChangedSignal("Scale"):Connect(updateWrapperPos)

    task.defer(function()
        local cam = workspace.CurrentCamera
        if cam then
            local vp = cam.ViewportSize
            visualCenterX = vp.X / 2
            visualCenterY = vp.Y / 2
            updateWrapperPos()
        end
    end)

    task.defer(function()
        local cam = workspace.CurrentCamera
        if cam then
            cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                tween(uiScale, {Scale = computeScale()}, 0.25)
            end)
        end
    end)

    local header = new("Frame", {
        Name = "Header", Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 2, Parent = innerMain,
    })
    corner(header, 9)

    local headGrad = new("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Panel,
        BorderSizePixel = 0, ZIndex = 0, Parent = header,
    })
    corner(headGrad, 9)
    gradient(headGrad, ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 22, 26)),
        ColorSequenceKeypoint.new(0.6, T.Panel),
        ColorSequenceKeypoint.new(1, T.Panel),
    }, 0)

    local headerMask = new("Frame", {
        Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 3, Parent = header,
    })

    local body = new("Frame", {
        Size = UDim2.new(1, 0, 1, -42), Position = UDim2.new(0, 0, 0, 42),
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1, Parent = innerMain,
    })

    local dragFrame = new("Frame", {
        Size = UDim2.new(1, -96, 1, 0), BackgroundTransparency = 1, ZIndex = 4, Parent = header,
    })

    local textX = imageUrl and 48 or 14
    if imageUrl then
        new("ImageLabel", {
            Size = UDim2.fromOffset(26, 26), Position = UDim2.new(0, 14, 0.5, -13),
            BackgroundTransparency = 1, Image = imageUrl, ZIndex = 5, Parent = header,
        })
    end

    local titleLbl = new("TextLabel", {
        Text = title, Font = T.FontBold, TextSize = 16, TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Position = UDim2.new(0, textX, 0, 6), Size = UDim2.new(0.5, 0, 0, 18),
        ZIndex = 5, Parent = header,
    })
    local subtitleLbl = new("TextLabel", {
        Text = subtitle, Font = T.Font, TextSize = 11, TextColor3 = T.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Position = UDim2.new(0, textX, 0, 24), Size = UDim2.new(0.5, 0, 0, 14),
        ZIndex = 5, Parent = header,
    })

    local btnSize = 22
    local minBtn = new("TextButton", {
        Text = "-", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = T.TextDim,
        BackgroundColor3 = T.Element, BorderSizePixel = 0, AutoButtonColor = false,
        Size = UDim2.fromOffset(btnSize, btnSize),
        Position = UDim2.new(1, -14 - btnSize*2 - 8, 0.5, -btnSize/2), ZIndex = 5, Parent = header,
    })
    corner(minBtn, 6)
    local closeBtn = new("TextButton", {
        Text = "X", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.TextDim,
        BackgroundColor3 = T.Element, BorderSizePixel = 0, AutoButtonColor = false,
        Size = UDim2.fromOffset(btnSize, btnSize),
        Position = UDim2.new(1, -14 - btnSize, 0.5, -btnSize/2), ZIndex = 5, Parent = header,
    })
    corner(closeBtn, 6)

    minBtn.MouseEnter:Connect(function() tween(minBtn, {BackgroundColor3 = T.ElementHover, TextColor3 = T.Text}, 0.15) end)
    minBtn.MouseLeave:Connect(function() tween(minBtn, {BackgroundColor3 = T.Element, TextColor3 = T.TextDim}, 0.15) end)
    closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3 = T.Accent, TextColor3 = T.Text}, 0.15) end)
    closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3 = T.Element, TextColor3 = T.TextDim}, 0.15) end)
    closeBtn.MouseButton1Click:Connect(function()
        tween(uiScale, {Scale = 0}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.2, function() gui:Destroy() end)
    end)

    local OPEN_W, OPEN_H = 144, 38
    local opener = new("Frame", {
        Name = "Opener", Size = UDim2.fromOffset(OPEN_W, OPEN_H),
        Position = UDim2.fromOffset(20, 20), BackgroundColor3 = T.Panel,
        BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Parent = gui,
    })
    corner(opener, 10)

    local opGrad = new("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Panel,
        BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 0, Parent = opener,
    })
    corner(opGrad, 10)
    gradient(opGrad, ColorSequence.new{
        ColorSequenceKeypoint.new(0, T.PanelLight),
        ColorSequenceKeypoint.new(0.5, T.Panel),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 18, 20)),
    }, 90)

    local opAccent = new("Frame", {
        Size = UDim2.new(0, 3, 0, 18), Position = UDim2.new(0, 10, 0.5, -9),
        BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 1, Parent = opener,
    })
    corner(opAccent, 2)
    gradient(opAccent, ColorSequence.new{
        ColorSequenceKeypoint.new(0, T.AccentHover),
        ColorSequenceKeypoint.new(1, T.AccentDark),
    }, 90)

    local opTextX = 20
    if imageUrl then
        new("ImageLabel", {
            Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 20, 0.5, -9),
            BackgroundTransparency = 1, Image = imageUrl, ZIndex = 2, Parent = opener,
        })
        opTextX = 44
    else
        new("Frame", {
            Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 20, 0.5, -5),
            BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 1, Parent = opener,
        })
        opTextX = 38
    end

    new("TextLabel", {
        Text = title, Font = T.FontBold, TextSize = 13, TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Position = UDim2.new(0, opTextX, 0, 0), Size = UDim2.new(1, -opTextX - 8, 1, 0),
        ZIndex = 2, Parent = opener,
    })

    local opScale = Instance.new("UIScale")
    opScale.Scale = 0
    opScale.Parent = opener

    local minimized = false
    local animating = false

    local function toggleMinimize()
        if animating then return end
        animating = true
        minimized = not minimized

        if minimized then
            local cam = workspace.CurrentCamera
            local ox, oy = 20, 20
            if cam then
                local vp = cam.ViewportSize
                local wp = wrapper.AbsolutePosition
                local ws = wrapper.AbsoluteSize
                ox = math.clamp(wp.X, 0, vp.X - OPEN_W)
                oy = math.clamp(wp.Y + ws.Y / 2 - OPEN_H / 2, 0, vp.Y - OPEN_H)
            end
            opener.Position = UDim2.fromOffset(ox, oy)

            tween(uiScale, {Scale = 0}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            task.delay(0.2, function()
                wrapper.Visible = false
                opener.Visible = true
                opScale.Scale = 0
                tween(opScale, {Scale = 1}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                task.delay(0.35, function() animating = false end)
            end)
        else
            tween(opScale, {Scale = 0}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            task.delay(0.2, function()
                opener.Visible = false
                wrapper.Visible = true
                uiScale.Scale = 0
                tween(uiScale, {Scale = targetScale}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                task.delay(0.35, function() animating = false end)
            end)
        end
    end

    minBtn.MouseButton1Click:Connect(toggleMinimize)

    do
        local activeInput = nil
        local lastPos = nil

        dragFrame.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch)
                and not activeInput then
                activeInput = input
                lastPos = input.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input ~= activeInput or not lastPos then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then return end

            local d = input.Position - lastPos
            lastPos = input.Position

            local cam = workspace.CurrentCamera
            if not cam or not visualCenterX then return end
            local vp = cam.ViewportSize
            local s = uiScale.Scale
            if s <= 0 then return end

            local halfW = (width * s) / 2
            local halfH = (height * s) / 2

            visualCenterX = math.clamp(visualCenterX + d.X, halfW, vp.X - halfW)
            visualCenterY = math.clamp(visualCenterY + d.Y, halfH, vp.Y - halfH)
            updateWrapperPos()
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input == activeInput then
                activeInput = nil
                lastPos = nil
            end
        end)
    end

    do
        local opInput = nil
        local opLastPos = nil
        local opStartPos = nil
        local opMoved = false

        opener.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not opInput then
                opInput = input
                opLastPos = input.Position
                opStartPos = input.Position
                opMoved = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input ~= opInput or not opLastPos then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then return end

            local d = input.Position - opLastPos
            opLastPos = input.Position
            if (input.Position - opStartPos).Magnitude > 3 then opMoved = true end
            if not opMoved then return end

            local nx = opener.Position.X.Offset + d.X
            local ny = opener.Position.Y.Offset + d.Y
            local cam = workspace.CurrentCamera
            if cam then
                local vp = cam.ViewportSize
                nx = math.clamp(nx, 0, vp.X - OPEN_W)
                ny = math.clamp(ny, 0, vp.Y - OPEN_H)
            end
            opener.Position = UDim2.fromOffset(nx, ny)
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input == opInput then
                if not opMoved then toggleMinimize() end
                opInput = nil
                opLastPos = nil
            end
        end)
    end

    local sidebar = new("Frame", {
        Size = UDim2.new(0, 110, 1, 0), BackgroundColor3 = T.Panel,
        BorderSizePixel = 0, ZIndex = 2, Parent = body,
    })
    corner(sidebar, 9)
    pad(sidebar, 8, 8, 8, 8)

    local searchBox = new("TextBox", {
        Text = "", PlaceholderText = "Search...",
        Font = T.Font, TextSize = 12, TextColor3 = T.Text,
        PlaceholderColor3 = T.TextMuted, BackgroundColor3 = T.Element,
        BorderSizePixel = 0, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 0),
        Parent = sidebar,
    })
    corner(searchBox, 6); pad(searchBox, 8, 0, 8, 0)

    local sidebarList = new("Frame", {
        Size = UDim2.new(1, 0, 1, -26 - 8 - 56), Position = UDim2.new(0, 0, 0, 34),
        BackgroundTransparency = 1, Parent = sidebar,
    })
    new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebarList})

    local profileFrame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 1, -44),
        BackgroundColor3 = T.Element, BorderSizePixel = 0, Parent = sidebar,
    })
    corner(profileFrame, 6)

    local pfp = new("ImageLabel", {
        Size = UDim2.fromOffset(28, 28), Position = UDim2.new(0, 6, 0.5, -14),
        BackgroundColor3 = T.Panel, BorderSizePixel = 0, Image = "", Parent = profileFrame,
    })
    corner(pfp, 14)

    local player = Players.LocalPlayer
    new("TextLabel", {
        Text = player.DisplayName, Font = T.FontBold, TextSize = 12, TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 6), Size = UDim2.new(1, -44, 0, 14),
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = profileFrame,
    })
    new("TextLabel", {
        Text = "@" .. player.Name, Font = T.Font, TextSize = 10, TextColor3 = T.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 22), Size = UDim2.new(1, -44, 0, 12),
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = profileFrame,
    })

    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and img then pfp.Image = img end
    end)

    local content = new("Frame", {
        Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 110, 0, 0),
        BackgroundColor3 = T.Background, BorderSizePixel = 0, ZIndex = 2, Parent = body,
    })
    corner(content, 9)

    local seamFiller = new("Frame", {
        Size = UDim2.fromOffset(18, 12), Position = UDim2.new(0, 101, 1, -12),
        BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 1, Parent = body,
    })
    gradient(seamFiller, ColorSequence.new{
        ColorSequenceKeypoint.new(0, T.Panel),
        ColorSequenceKeypoint.new(0.5, T.Panel),
        ColorSequenceKeypoint.new(1, T.Background),
    }, 0)

    local Window = {Gui = gui, Main = main, Body = body, Tabs = {}}
    local tabs, activeTab = {}, nil

    local allSearchTargets = {}
    local function registerSearchTarget(frame, text)
        table.insert(allSearchTargets, {Frame = frame, Text = (text or ""):lower()})
    end

    local function applySearch(query)
        query = (query or ""):lower()
        for _, t in ipairs(allSearchTargets) do
            if t.Frame and t.Frame.Parent then
                if query == "" then
                    t.Frame.Visible = true
                else
                    t.Frame.Visible = t.Text:find(query, 1, true) ~= nil
                end
            end
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        applySearch(searchBox.Text)
    end)

    function Window:CreateTab(name, iconId)
        local tabIconUrl = parseAsset(iconId)
        local tab = {Name = name, Icon = tabIconUrl}

        local btn = new("TextButton", {
            Text = "", AutoButtonColor = false, BackgroundColor3 = T.Panel,
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), Parent = sidebarList,
        })

        local hl = new("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Element,
            BackgroundTransparency = 1, BorderSizePixel = 0, Parent = btn,
        })
        corner(hl, 6)
        gradient(hl, ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(44, 30, 30)),
            ColorSequenceKeypoint.new(1, T.PanelLight),
        }, 0)

        local acc = new("Frame", {
            Size = UDim2.new(0, 3, 0.5, 0), Position = UDim2.new(0, 0, 0.25, 0),
            BackgroundColor3 = T.Accent, BorderSizePixel = 0, Visible = false, Parent = btn,
        })
        corner(acc, 2)
        gradient(acc, ColorSequence.new{
            ColorSequenceKeypoint.new(0, T.AccentHover),
            ColorSequenceKeypoint.new(1, T.AccentDark),
        }, 90)

        local tabTextX = 12
        if tabIconUrl then
            new("ImageLabel", {
                Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 10, 0.5, -7),
                BackgroundTransparency = 1, Image = tabIconUrl, ZIndex = 1, Parent = btn,
            })
            tabTextX = 30
        end

        local lbl = new("TextLabel", {
            Text = name, Font = T.Font, TextSize = 13, TextColor3 = T.TextDim,
            TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
            Position = UDim2.new(0, tabTextX, 0, 0), Size = UDim2.new(1, -tabTextX - 6, 1, 0), Parent = btn,
        })

        local page = new("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = T.ElementHover,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false, Parent = content,
        })
        pad(page, 10, 10, 10, 10)
        local layout = new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
        local function syncCanvas()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncCanvas)
        task.defer(syncCanvas)

        tab.Button, tab.Highlight, tab.AccentBar, tab.Label, tab.Page = btn, hl, acc, lbl, page

        function tab:Select()
            for _, other in ipairs(tabs) do
                if other == tab then
                    other.Page.Visible = true
                    tween(other.Highlight, {BackgroundTransparency = 0}, 0.2)
                    tween(other.Label, {TextColor3 = T.Text}, 0.2)
                    other.AccentBar.Visible = true
                else
                    other.Page.Visible = false
                    tween(other.Highlight, {BackgroundTransparency = 1}, 0.2)
                    tween(other.Label, {TextColor3 = T.TextDim}, 0.2)
                    other.AccentBar.Visible = false
                end
            end
            activeTab = tab
            syncCanvas()
        end

        btn.MouseButton1Click:Connect(function() tab:Select() end)
        btn.MouseEnter:Connect(function()
            if activeTab ~= tab then tween(btn, {BackgroundTransparency = 0.85}, 0.15) end
        end)
        btn.MouseLeave:Connect(function()
            if activeTab ~= tab then tween(btn, {BackgroundTransparency = 1}, 0.15) end
        end)

        function tab:CreateSection(titleText, descText)
            local section = {Name = titleText}
            local wrap = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1, Parent = page,
            })
            new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = wrap})

            local titleRow = new("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = wrap })
            local dot = new("Frame", {
                Size = UDim2.fromOffset(3, 10), Position = UDim2.new(0, 0, 0.5, -5),
                BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = titleRow,
            })
            corner(dot, 2)
            new("TextLabel", {
                Text = titleText, Font = T.FontBold, TextSize = 12, TextColor3 = T.TextDim,
                TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                Position = UDim2.new(0, 9, 0, 0), Size = UDim2.new(1, -9, 1, 0), Parent = titleRow,
            })

            if descText then
                new("TextLabel", {
                    Text = descText, Font = T.Font, TextSize = 11, TextColor3 = T.TextMuted,
                    TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 9, 0, 16), Size = UDim2.new(1, -9, 0, 14), Parent = wrap,
                })
            end

            local bg = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = T.Panel, BorderSizePixel = 0, Parent = wrap,
            })
            corner(bg, 8)
            pad(bg, 12, 10, 12, 10)
            gradient(bg, ColorSequence.new{
                ColorSequenceKeypoint.new(0, T.PanelLight),
                ColorSequenceKeypoint.new(1, T.Panel),
            }, 90)
            new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bg})

            function section:CreateButton(o)
                o = o or {}
                local b = new("TextButton", {
                    Text = o.Text or "Button", Font = T.Font, TextSize = 13, TextColor3 = T.Text,
                    BackgroundColor3 = T.Element, BorderSizePixel = 0, AutoButtonColor = false,
                    Size = UDim2.new(1, 0, 0, 30), Parent = bg,
                })
                corner(b, 6)
                b.MouseEnter:Connect(function() tween(b, {BackgroundColor3 = T.ElementHover}, 0.15) end)
                b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = T.Element}, 0.15) end)
                b.MouseButton1Click:Connect(function()
                    tween(b, {BackgroundColor3 = T.Accent}, 0.06)
                    task.delay(0.1, function() tween(b, {BackgroundColor3 = T.ElementHover}, 0.25) end)
                    if o.Callback then o.Callback() end
                end)
                registerSearchTarget(b, o.Text)
                return {Button = b}
            end

            function section:CreateToggle(o)
                o = o or {}
                local text, flag, default = o.Text or "Toggle", o.Flag, o.Default or false
                local cb = o.Callback or function() end
                local row = new("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = bg})
                new("TextLabel", {
                    Text = text, Font = T.Font, TextSize = 13, TextColor3 = T.Text,
                    TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 1, 0), Parent = row,
                })
                local pill = new("Frame", {
                    Size = UDim2.fromOffset(34, 18), Position = UDim2.new(1, -34, 0.5, -9),
                    BackgroundColor3 = T.Element, BorderSizePixel = 0, Parent = row,
                })
                corner(pill, 9)
                local knob = new("Frame", {
                    Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 3, 0.5, -6),
                    BackgroundColor3 = T.TextDim, BorderSizePixel = 0, Parent = pill,
                })
                corner(knob, 9)
                local hit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = pill})

                local val = default
                if flag then XevUI.Flags[flag] = val end
                local function set(v, silent)
                    val = v; if flag then XevUI.Flags[flag] = val end
                    tween(pill, {BackgroundColor3 = val and T.Accent or T.Element}, 0.2)
                    tween(knob, {
                        Position = val and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
                        BackgroundColor3 = val and T.Text or T.TextDim,
                    }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    if not silent then cb(val) end
                end
                set(default, true)
                hit.MouseButton1Click:Connect(function() set(not val) end)
                registerSearchTarget(row, text)
                return {Get = function() return val end, Set = function(v) set(v) end, Toggle = function() set(not val) end}
            end

            function section:CreateSlider(o)
                o = o or {}
                local text, flag = o.Text or "Slider", o.Flag
                local mn, mx = o.Min or 0, o.Max or 100
                local default, cb = o.Default or mn, o.Callback or function() end
                local suffix = o.Suffix or ""

                local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = bg})
                new("TextLabel", {
                    Text = text, Font = T.Font, TextSize = 13, TextColor3 = T.Text,
                    TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                    Size = UDim2.new(1, -80, 0, 18), Parent = row,
                })

                local inputBox = new("TextBox", {
                    Text = tostring(default) .. suffix, Font = T.Font, TextSize = 12,
                    TextColor3 = T.TextDim, BackgroundColor3 = T.Element,
                    BorderSizePixel = 0, ClearTextOnFocus = false,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Size = UDim2.new(0, 70, 0, 18),
                    Position = UDim2.new(1, -70, 0, 0), Parent = row,
                })
                corner(inputBox, 4)

                local track = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0, 24),
                    BackgroundColor3 = T.Element, BorderSizePixel = 0, Parent = row,
                })
                corner(track, 2)
                local fill = new("Frame", {
                    Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = T.Accent,
                    BorderSizePixel = 0, Parent = track,
                })
                corner(fill, 2)
                gradient(fill, ColorSequence.new{
                    ColorSequenceKeypoint.new(0, T.AccentHover),
                    ColorSequenceKeypoint.new(1, T.AccentDark),
                }, 0)
                local thumb = new("Frame", {
                    Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -6, 0.5, -6),
                    BackgroundColor3 = T.Text, BorderSizePixel = 0, ZIndex = 2, Parent = fill,
                })
                corner(thumb, 6)

                local val = default
                local function set(v, silent)
                    v = math.clamp(mx - mn >= 10 and math.floor(v + 0.5) or math.floor(v*100)/100, mn, mx)
                    val = v
                    if flag then XevUI.Flags[flag] = val end
                    fill.Size = UDim2.new((v - mn)/(mx - mn), 0, 1, 0)
                    inputBox.Text = tostring(v) .. suffix
                    if not silent then cb(val) end
                end
                set(default, true)

                inputBox.FocusLost:Connect(function()
                    local stripped = inputBox.Text:gsub(suffix, "")
                    local num = tonumber(stripped)
                    if num then
                        set(num)
                    else
                        inputBox.Text = tostring(val) .. suffix
                    end
                end)

                local dragging = false
                local function fromX(x)
                    local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                    set(mn + rel * (mx - mn))
                end
                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true; fromX(input.Position.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        fromX(input.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                registerSearchTarget(row, text)
                return {Get = function() return val end, Set = function(v) set(v) end}
            end

            function section:CreateTextbox(o)
                o = o or {}
                local text, flag = o.Text or "Textbox", o.Flag
                local default, cb = o.Default or "", o.Callback or function() end
                local row = new("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = bg})
                new("TextLabel", {
                    Text = text, Font = T.Font, TextSize = 13, TextColor3 = T.Text,
                    TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, 0, 1, 0), Parent = row,
                })
                local box = new("TextBox", {
                    Text = default, PlaceholderText = o.Placeholder or "",
                    Font = T.Font, TextSize = 12, TextColor3 = T.Text,
                    PlaceholderColor3 = T.TextMuted, BackgroundColor3 = T.Element,
                    BorderSizePixel = 0, ClearTextOnFocus = o.ClearOnFocus or false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), Parent = row,
                })
                corner(box, 6); pad(box, 8, 0, 8, 0)

                local val = default
                if flag then XevUI.Flags[flag] = val end
                local function set(v, silent)
                    val = tostring(v); box.Text = val
                    if flag then XevUI.Flags[flag] = val end
                    if not silent then cb(val) end
                end
                box.Focused:Connect(function() tween(box, {BackgroundColor3 = T.ElementHover}, 0.15) end)
                box.FocusLost:Connect(function() tween(box, {BackgroundColor3 = T.Element}, 0.15); set(box.Text) end)
                registerSearchTarget(row, text)
                return {Get = function() return val end, Set = function(v) set(v) end}
            end

            function section:CreateDropdown(o)
                o = o or {}
                local text, flag = o.Text or "Dropdown", o.Flag
                local options, cb = o.Options or {}, o.Callback or function() end
                local multi = o.Multi or false
                local default = o.Default or options[1]

                local row = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 28), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1, Parent = bg,
                })
                new("UIListLayout", {Padding = UDim.new(0, 4), Parent = row})

                local top = new("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = row})
                new("TextLabel", {
                    Text = text, Font = T.Font, TextSize = 13, TextColor3 = T.Text,
                    TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, 0, 1, 0), Parent = top,
                })
                local display = new("TextButton", {
                    Text = "", AutoButtonColor = false, BackgroundColor3 = T.Element,
                    BorderSizePixel = 0, Size = UDim2.new(0.5, 0, 1, 0),
                    Position = UDim2.new(0.5, 0, 0, 0), Parent = top,
                })
                corner(display, 6)
                local dtext = new("TextLabel", {
                    Text = "", Font = T.Font, TextSize = 12, TextColor3 = T.Text,
                    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                    BackgroundTransparency = 1, Size = UDim2.new(1, -28, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0), Parent = display,
                })
                local arrow = new("TextLabel", {
                    Text = ">", Font = T.FontBold, TextSize = 12, TextColor3 = T.TextDim,
                    BackgroundTransparency = 1, Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.new(1, -18, 0.5, -7), Rotation = 90, Parent = display,
                })

                local list = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = T.Panel,
                    BorderSizePixel = 0, Visible = false, ClipsDescendants = true, Parent = row,
                })
                corner(list, 6); pad(list, 0, 4, 0, 4)
                gradient(list, ColorSequence.new{
                    ColorSequenceKeypoint.new(0, T.PanelLight),
                    ColorSequenceKeypoint.new(1, T.Panel),
                }, 90)
                new("UIListLayout", {Padding = UDim.new(0, 2), Parent = list})

                local sel = multi and (default or {}) or default
                local function update()
                    if multi then
                        local p = {}
                        for _, v in ipairs(sel) do p[#p+1] = tostring(v) end
                        dtext.Text = #p > 0 and table.concat(p, ", ") or "None"
                    else
                        dtext.Text = tostring(sel)
                    end
                end
                local function set(v, silent)
                    sel = v
                    if flag then XevUI.Flags[flag] = sel end
                    update()
                    if not silent then cb(sel) end
                end

                for _, opt in ipairs(options) do
                    local ob = new("TextButton", {
                        Text = tostring(opt), Font = T.Font, TextSize = 12, TextColor3 = T.Text,
                        TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = T.Panel,
                        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 24), Parent = list,
                    })
                    corner(ob, 4); pad(ob, 8, 0, 8, 0)
                    ob.MouseEnter:Connect(function() tween(ob, {BackgroundColor3 = T.ElementHover}, 0.12) end)
                    ob.MouseLeave:Connect(function() tween(ob, {BackgroundColor3 = T.Panel}, 0.12) end)
                    ob.MouseButton1Click:Connect(function()
                        if multi then
                            local found = false
                            for i, v in ipairs(sel) do
                                if v == opt then found = true; table.remove(sel, i); break end
                            end
                            if not found then table.insert(sel, opt) end
                            set(sel)
                        else
                            set(opt)
                            tween(list, {Size = UDim2.new(1, 0, 0, 0)}, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                            tween(arrow, {Rotation = 90}, 0.22)
                            task.delay(0.22, function() list.Visible = false end)
                        end
                    end)
                end

                local open = false
                display.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        local targetH = #options * 26 + 10
                        list.Visible = true
                        list.Size = UDim2.new(1, 0, 0, 0)
                        tween(list, {Size = UDim2.new(1, 0, 0, targetH)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                        tween(arrow, {Rotation = 270}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                    else
                        tween(list, {Size = UDim2.new(1, 0, 0, 0)}, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                        tween(arrow, {Rotation = 90}, 0.22)
                        task.delay(0.22, function() if not open then list.Visible = false end end)
                    end
                end)
                update()
                if flag then XevUI.Flags[flag] = sel end
                registerSearchTarget(row, text)
                return {Get = function() return sel end, Set = function(v) set(v) end}
            end

            function section:CreateColorPicker(o)
                o = o or {}
                local text, flag = o.Text or "Color", o.Flag
                local default, cb = o.Default or Color3.fromRGB(255,255,255), o.Callback or function() end
                local row = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = bg})
                new("TextLabel", {
                    Text = text, Font = T.Font, TextSize = 13, TextColor3 = T.Text,
                    TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, 0, 0, 28), Parent = row,
                })
                local swatch = new("TextButton", {
                    Text = "", AutoButtonColor = false, BackgroundColor3 = default,
                    BorderSizePixel = 0, Size = UDim2.new(0.5, 0, 0, 28),
                    Position = UDim2.new(0.5, 0, 0, 0), Parent = row,
                })
                corner(swatch, 6)
                local hex = new("TextBox", {
                    Text = "", PlaceholderText = "#FFFFFF", Font = T.FontMono, TextSize = 12,
                    TextColor3 = T.Text, BackgroundColor3 = T.Element, BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 32), Parent = row,
                })
                corner(hex, 6); pad(hex, 8, 0, 8, 0)

                local function toHex(c)
                    return string.format("#%02X%02X%02X",
                        math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
                end
                local function fromHex(s)
                    s = s:gsub("#", "")
                    if #s ~= 6 then return nil end
                    local r, g, b = tonumber(s:sub(1,2),16), tonumber(s:sub(3,4),16), tonumber(s:sub(5,6),16)
                    if not (r and g and b) then return nil end
                    return Color3.fromRGB(r, g, b)
                end

                local val = default
                local function set(c, silent)
                    val = c; swatch.BackgroundColor3 = c; hex.Text = toHex(c)
                    if flag then XevUI.Flags[flag] = val end
                    if not silent then cb(val) end
                end
                set(default, true)
                hex.FocusLost:Connect(function()
                    local c = fromHex(hex.Text); if c then set(c) end
                    hex.Text = toHex(val)
                end)
                registerSearchTarget(row, text)
                return {Get = function() return val end, Set = function(c) set(c) end}
            end

            function section:CreateKeybind(o)
                o = o or {}
                local text, flag = o.Text or "Keybind", o.Flag
                local default, cb = o.Default or Enum.KeyCode.Unknown, o.Callback or function() end
                local row = new("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = bg})
                new("TextLabel", {
                    Text = text, Font = T.Font, TextSize = 13, TextColor3 = T.Text,
                    TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, 0, 1, 0), Parent = row,
                })
                local btn = new("TextButton", {
                    Text = default == Enum.KeyCode.Unknown and "None" or default.Name,
                    Font = T.Font, TextSize = 12, TextColor3 = T.Text,
                    BackgroundColor3 = T.Element, BorderSizePixel = 0, AutoButtonColor = false,
                    Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), Parent = row,
                })
                corner(btn, 6)

                local val, listening = default, false
                local function set(k, silent)
                    val = k
                    if flag then XevUI.Flags[flag] = val end
                    btn.Text = (k and k ~= Enum.KeyCode.Unknown) and k.Name or "None"
                    if not silent then cb(val) end
                end
                btn.MouseButton1Click:Connect(function()
                    listening = true; btn.Text = "..."
                    tween(btn, {BackgroundColor3 = T.Accent}, 0.15)
                end)
                UserInputService.InputBegan:Connect(function(input, gp)
                    if listening then
                        if gp or UserInputService:GetFocusedTextBox() then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            listening = false
                            tween(btn, {BackgroundColor3 = T.Element}, 0.15)
                            set(input.KeyCode)
                        end
                    elseif val and val ~= Enum.KeyCode.Unknown and not UserInputService:GetFocusedTextBox() then
                        if input.KeyCode == val then cb(val) end
                    end
                end)
                registerSearchTarget(row, text)
                return {Get = function() return val end, Set = function(k) set(k) end}
            end

            function section:CreateLabel(o)
                o = o or {}
                new("TextLabel", {
                    Text = o.Text or "", Font = T.Font, TextSize = 12, TextColor3 = T.Text,
                    TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18), Parent = bg,
                })
            end

            function section:CreateParagraph(o)
                o = o or {}
                new("TextLabel", {
                    Text = o.Text or "", Font = T.Font, TextSize = 12, TextColor3 = T.TextDim,
                    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = bg,
                })
            end

            function section:CreateDivider()
                new("Frame", {
                    Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Stroke,
                    BorderSizePixel = 0, Parent = bg,
                })
            end

            return section
        end

        function tab:CreateDivider()
            new("Frame", {
                Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 4),
                BackgroundColor3 = T.Stroke, BorderSizePixel = 0, Parent = sidebarList,
            })
        end

        tabs[#tabs+1] = tab
        if #tabs == 1 then task.defer(function() tab:Select() end) end
        return tab
    end

    function Window:SelectTab(name)
        for _, t in ipairs(tabs) do
            if t.Name == name then t:Select() return true end
        end
        return false
    end

    function Window:SetTitle(t)
        titleLbl.Text = t
        for _, ch in ipairs(opener:GetChildren()) do
            if ch:IsA("TextLabel") and ch.Text ~= "" then ch.Text = t break end
        end
    end

    function Window:SetSubtitle(s)
        subtitleLbl.Text = s
    end

    function Window:SaveConfig()
        local data = {}
        for k, v in pairs(XevUI.Flags) do
            if typeof(v) == "Color3" then
                data[k] = {__type = "Color3", r = v.R, g = v.G, b = v.B}
            else
                data[k] = v
            end
        end
        local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
        return ok and encoded or nil
    end

    function Window:LoadConfig(json)
        local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
        if not ok or type(data) ~= "table" then return false end
        for k, v in pairs(data) do
            if type(v) == "table" and v.__type == "Color3" then
                XevUI.Flags[k] = Color3.new(v.r, v.g, v.b)
            else
                XevUI.Flags[k] = v
            end
        end
        return true
    end

    local notes = {}
    local function reposition()
        for i, n in ipairs(notes) do
            tween(n, {Position = UDim2.new(1, -260, 0, 16 + (i-1)*66)}, 0.3, Enum.EasingStyle.Quint)
        end
    end
    function Window:Notify(o)
        o = o or {}
        local n = new("Frame", {
            Size = UDim2.fromOffset(240, 56), Position = UDim2.new(1, 280, 0, 16),
            BackgroundColor3 = T.Panel, BorderSizePixel = 0, Parent = gui,
        })
        corner(n, 8)

        local nGrad = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Panel, ZIndex = 0, Parent = n })
        corner(nGrad, 8)
        gradient(nGrad, ColorSequence.new{
            ColorSequenceKeypoint.new(0, T.PanelLight),
            ColorSequenceKeypoint.new(1, T.Panel),
        }, 90)

        new("TextLabel", {
            Text = o.Title or "Notification", Font = T.FontBold, TextSize = 13, TextColor3 = T.Text,
            TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 8), Size = UDim2.new(1, -18, 0, 16), ZIndex = 2, Parent = n,
        })
        new("TextLabel", {
            Text = o.Text or "", Font = T.Font, TextSize = 11, TextColor3 = T.TextDim,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true, BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 26), Size = UDim2.new(1, -18, 0, 26), ZIndex = 2, Parent = n,
        })

        notes[#notes+1] = n
        task.defer(reposition)
        task.delay(o.Duration or 4, function()
            for i, x in ipairs(notes) do if x == n then table.remove(notes, i); break end end
            tween(n, {Position = UDim2.new(1, 280, 0, 16)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            task.delay(0.35, function() n:Destroy() end)
            reposition()
        end)
    end

    function Window:Destroy() gui:Destroy() end

    if toggleKey then
        UserInputService.InputBegan:Connect(function(input, gp)
            if gp or UserInputService:GetFocusedTextBox() then return end
            if input.KeyCode == toggleKey then toggleMinimize() end
        end)
    end

    log("Window ready:", width, height)
    return Window
end

return XevUI
