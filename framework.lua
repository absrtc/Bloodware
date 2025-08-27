--!strict
local Bloodware = {}
Bloodware.__index = Bloodware

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

local function new(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if type(k) ~= "number" then
            pcall(function() obj[k] = v end)
        end
    end
    return obj
end

local function hexToColor3(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
end

local DefaultThemes = {
    Amethyst = {
        Background = "2B1A4F",
        Sidebar = "1F123A",
        Accent = "A855F7",
        Text = "E5E7EB",
        Font = Enum.Font.GothamBold,
        Shadow = "1A1033"
    }
}

local Keybinds = {}
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local kc = input.KeyCode
        local handlers = Keybinds[kc]
        if handlers then
            for _, fn in ipairs(handlers) do
                pcall(fn)
            end
        end
    end
end)

function Bloodware.CreateWindow(options)
    options = options or {}
    local windowName = options.Name or "Bloodware"
    local toggleKey = options.ToggleKey or Enum.KeyCode.U
    local theme = options.Theme or DefaultThemes.Amethyst

    local self = setmetatable({}, Bloodware)
    self.Tabs = {}

    local screenGui = Instance.new("ScreenGui")
    screenGui.ResetOnSpawn = false
    screenGui.Name = windowName
    screenGui.Parent = CoreGui
    self.ScreenGui = screenGui

    local main = new("Frame", {
        Name = "MainFrame",
        Parent = screenGui,
        Size = UDim2.new(0, 800, 0, 500),
        Position = UDim2.new(0.5, -400, 0.5, -250),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = hexToColor3(theme.Background),
        ClipsDescendants = true
    })
    new("UICorner", {Parent = main, CornerRadius = UDim.new(0, 16)})
    new("UIStroke", {Parent = main, Color = hexToColor3(theme.Shadow), Thickness = 2, Transparency = 0.8})

    local shadow = new("Frame", {
        Parent = main,
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        BackgroundTransparency = 1,
        ZIndex = -1
    })
    new("ImageLabel", {
        Parent = shadow,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = hexToColor3(theme.Shadow),
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(Vector2.new(10, 10), Vector2.new(10, 10))
    })

    local topBar = new("Frame", {
        Parent = main,
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = hexToColor3(theme.Background),
        BorderSizePixel = 0
    })
    new("UIStroke", {Parent = topBar, Color = hexToColor3(theme.Shadow), Thickness = 1, Transparency = 0.9})

    local title = new("TextLabel", {
        Parent = topBar,
        Size = UDim2.new(1, -80, 1, 0),
        Text = windowName,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = theme.Font,
        TextSize = 22,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        TextColor3 = hexToColor3(theme.Text)
    })

    local btnClose = new("TextButton", {
        Parent = topBar,
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(1, -48, 0, 6),
        Text = "×",
        BackgroundColor3 = hexToColor3(theme.Accent),
        BorderSizePixel = 0,
        TextColor3 = Color3.new(1, 1, 1),
        Font = theme.Font,
        TextSize = 20
    })
    new("UICorner", {Parent = btnClose, CornerRadius = UDim.new(0, 8)})
    new("UIStroke", {Parent = btnClose, Color = hexToColor3(theme.Shadow), Thickness = 1})

    btnClose.MouseButton1Click:Connect(function()
        local tween = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 0, 0, 0)})
        tween:Play()
        tween.Completed:Connect(function() main:Destroy() end)
    end)

    local dragging, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local sidebar = new("Frame", {
        Parent = main,
        Size = UDim2.new(0, 240, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundColor3 = hexToColor3(theme.Sidebar)
    })
    new("UICorner", {Parent = sidebar, CornerRadius = UDim.new(0, 12)})
    new("UIStroke", {Parent = sidebar, Color = hexToColor3(theme.Shadow), Thickness = 1, Transparency = 0.9})

    local tabsFrame = new("ScrollingFrame", {
        Parent = sidebar,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 1, -16),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        BackgroundTransparency = 1,
        ScrollBarImageColor3 = hexToColor3(theme.Accent)
    })
    local layout = new("UIListLayout", {
        Parent = tabsFrame,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabsFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
    end)

    local content = new("Frame", {
        Parent = main,
        Position = UDim2.new(0, 240, 0, 48),
        Size = UDim2.new(1, -240, 1, -48),
        BackgroundTransparency = 1
    })

    self.UI = {
        Main = main,
        Sidebar = sidebar,
        TabsFrame = tabsFrame,
        Content = content,
        Title = title
    }

    Keybinds[toggleKey] = Keybinds[toggleKey] or {}
    table.insert(Keybinds[toggleKey], function()
        main.Visible = not main.Visible
        if main.Visible then
            TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 800, 0, 500)}):Play()
        end
    end)

    function self:CreateTab(name)
        local tab = {}
        tab.Button = new("TextButton", {
            Parent = tabsFrame,
            Size = UDim2.new(1, -8, 0, 40),
            Text = name,
            BackgroundColor3 = hexToColor3(theme.Sidebar),
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = theme.Font,
            TextSize = 18,
            TextColor3 = hexToColor3(theme.Text),
            BorderSizePixel = 0
        })
        new("UICorner", {Parent = tab.Button, CornerRadius = UDim.new(0, 8)})
        new("UIStroke", {Parent = tab.Button, Color = hexToColor3(theme.Shadow), Thickness = 1, Transparency = 0.8})
        tab.Page = new("Frame", {
            Parent = content,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false
        })
        local pageLayout = new("UIListLayout", {
            Parent = tab.Page,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        tab.Button.MouseButton1Click:Connect(function()
            for _, t in ipairs(self.Tabs) do
                t.Page.Visible = false
                TweenService:Create(t.Button, TweenInfo.new(0.2), {BackgroundColor3 = hexToColor3(theme.Sidebar)}):Play()
            end
            tab.Page.Visible = true
            TweenService:Create(tab.Button, TweenInfo.new(0.2), {BackgroundColor3 = hexToColor3(theme.Accent)}):Play()
        end)

        function tab:CreateButton(text, callback)
            local btn = new("TextButton", {
                Parent = tab.Page,
                Size = UDim2.new(1, -24, 0, 40),
                Position = UDim2.new(0, 12, 0, 0),
                Text = text,
                BackgroundColor3 = hexToColor3(theme.Accent),
                BorderSizePixel = 0,
                Font = theme.Font,
                TextSize = 18,
                TextColor3 = hexToColor3(theme.Text)
            })
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 8)})
            new("UIStroke", {Parent = btn, Color = hexToColor3(theme.Shadow), Thickness = 1})
            btn.MouseButton1Click:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = hexToColor3(theme.Sidebar)}):Play()
                task.wait(0.1)
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = hexToColor3(theme.Accent)}):Play()
                pcall(callback)
            end)
            return btn
        end

        function tab:CreateToggle(text, callback, default)
            local state = default or false
            local btn = new("TextButton", {
                Parent = tab.Page,
                Size = UDim2.new(1, -24, 0, 40),
                Position = UDim2.new(0, 12, 0, 0),
                Text = text .. ": " .. (state and "On" or "Off"),
                BackgroundColor3 = hexToColor3(theme.Accent),
                BorderSizePixel = 0,
                Font = theme.Font,
                TextSize = 18,
                TextColor3 = hexToColor3(theme.Text)
            })
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 8)})
            new("UIStroke", {Parent = btn, Color = hexToColor3(theme.Shadow), Thickness = 1})
            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.Text = text .. ": " .. (state and "On" or "Off")
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = state and hexToColor3(theme.Accent) or hexToColor3(theme.Sidebar)}):Play()
                pcall(callback, state)
            end)
            return btn
        end

        table.insert(self.Tabs, tab)
        if #self.Tabs == 1 then
            tab.Button.BackgroundColor3 = hexToColor3(theme.Accent)
            tab.Page.Visible = true
        end
        return tab
    end

    return self
end

return Bloodware
