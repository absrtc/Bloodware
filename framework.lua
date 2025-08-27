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
        Background = "4B0082",
        Sidebar = "330066",
        Accent = "D580FF",
        Font = Enum.Font.GothamBold
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
    local toggleKey = options.ToggleUiVisibilityKey or Enum.KeyCode.RightShift
    local theme = DefaultThemes.Amethyst

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
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = hexToColor3(theme.Background)
    })
    new("UICorner", {Parent = main, CornerRadius = UDim.new(0,12)})

    local topBar = new("Frame", {Parent = main, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
    local title = new("TextLabel", {
        Parent = topBar,
        Size = UDim2.new(1,-80,1,0),
        Text = windowName,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = theme.Font,
        TextSize = 20,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,12,0,0),
        TextColor3 = Color3.fromRGB(255,255,255)
    })
    local btnClose = new("TextButton", {Parent = topBar, Size = UDim2.new(0,32,0,24), Position = UDim2.new(1,-40,0,6), Text = "X", BackgroundColor3 = hexToColor3(theme.Accent), BorderSizePixel = 0, TextColor3 = Color3.new(1,1,1), Font = theme.Font, TextSize = 18})
    local btnMin = new("TextButton", {Parent = topBar, Size = UDim2.new(0,32,0,24), Position = UDim2.new(1,-80,0,6), Text = "-", BackgroundColor3 = hexToColor3(theme.Accent), BorderSizePixel = 0, TextColor3 = Color3.new(1,1,1), Font = theme.Font, TextSize = 18})
    for _, b in ipairs({btnClose, btnMin}) do
        new("UICorner", {Parent = b, CornerRadius = UDim.new(0,6)})
    end

    btnClose.MouseButton1Click:Connect(function() main:Destroy() end)
    btnMin.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

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
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
        end
    end)

    local sidebar = new("Frame", {Parent = main, Size = UDim2.new(0,220,1,-36), Position = UDim2.new(0,0,0,36), BackgroundColor3 = hexToColor3(theme.Sidebar)})
    new("UICorner", {Parent = sidebar, CornerRadius = UDim.new(0,12)})

    local tabsFrame = new("ScrollingFrame", {Parent = sidebar, Position = UDim2.new(0,0,0,0), Size = UDim2.new(1,0,1,0), CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 6})
    local layout = new("UIListLayout", {Parent = tabsFrame, Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder})
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabsFrame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 12)
    end)

    local content = new("Frame", {Parent = main, Position = UDim2.new(0,220,0,36), Size = UDim2.new(1,-220,1,-36), BackgroundTransparency = 1})

    self.UI = {
        Main = main,
        Sidebar = sidebar,
        TabsFrame = tabsFrame,
        Content = content,
        Title = title
    }

    Keybinds[toggleKey] = Keybinds[toggleKey] or {}
    table.insert(Keybinds[toggleKey], function() screenGui.Enabled = not screenGui.Enabled end)

    function self:CreateTab(name)
        local tab = {}
        tab.Button = new("TextButton", {Parent = tabsFrame, Size = UDim2.new(1,-12,0,36), Text = name, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = theme.Font, TextSize = 18, TextColor3 = Color3.new(1,1,1)})
        new("UICorner", {Parent = tab.Button, CornerRadius = UDim.new(0,6)})
        tab.Page = new("Frame", {Parent = content, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false})

        tab.Button.MouseButton1Click:Connect(function()
            for _, t in ipairs(self.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundTransparency = 1
            end
            tab.Page.Visible = true
            tab.Button.BackgroundTransparency = 0
        end)

        function tab:CreateButton(text, callback)
            local btn = new("TextButton", {Parent = tab.Page, Size = UDim2.new(1,-24,0,36), Position = UDim2.new(0,12,0,0), Text = text, BackgroundColor3 = hexToColor3(theme.Accent), BorderSizePixel = 0, Font = theme.Font, TextSize = 18, TextColor3 = Color3.new(1,1,1)})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
            btn.MouseButton1Click:Connect(function() pcall(callback) end)
            return btn
        end

        function tab:CreateToggle(text, callback, default)
            local state = default or false
            local btn = new("TextButton", {Parent = tab.Page, Size = UDim2.new(1,-24,0,36), Position = UDim2.new(0,12,0,0), Text = text .. ": " .. (state and "On" or "Off"), BackgroundColor3 = hexToColor3(theme.Accent), BorderSizePixel = 0, Font = theme.Font, TextSize = 18, TextColor3 = Color3.new(1,1,1)})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.Text = text .. ": " .. (state and "On" or "Off")
                pcall(callback, state)
            end)
            return btn
        end

        table.insert(self.Tabs, tab)
        return tab
    end

    return self
end

return Bloodware
