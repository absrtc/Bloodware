local Bloodware = {}
Bloodware.__index = Bloodware

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local function new(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if type(k) == "number" then
            -- ignore numeric keys
        else
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
    Gray = {
        Background = "2B2B2B",
        Sidebar = "1F1F1F",
        Accent = "9E9E9E",
        Font = "Inter",
    },
    Amethyst = {
        Background = "4B0082",
        Sidebar = "330066",
        Accent = "D580FF",
        Font = "Inter",
    },
    Ruby = {
        Background = "8B0000",
        Sidebar = "660000",
        Accent = "FF5555",
        Font = "Inter",
    }
}

local function saveConfig(filename, tbl)
    local ok, err
    local json = HttpService:JSONEncode(tbl)
    if writefile then
        ok, err = pcall(function() writefile(filename, json) end)
    else
        local player = Players.LocalPlayer
        if player and player:FindFirstChild("PlayerGui") then
            local folder = player.PlayerGui:FindFirstChild("_BloodwareConfig") or Instance.new("Folder")
            folder.Name = "_BloodwareConfig"
            folder.Parent = player.PlayerGui
            local value = folder:FindFirstChild(filename) or Instance.new("StringValue")
            value.Name = filename
            value.Value = json
            value.Parent = folder
            ok = true
        else
            ok = false
            err = "no writefile and no PlayerGui"
        end
    end
    return ok, err
end

local function loadConfig(filename)
    local ok, content
    if isfile then
        ok, content = pcall(function() return readfile(filename) end)
        if ok then
            return HttpService:JSONDecode(content)
        end
    elseif Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") then
        local folder = Players.LocalPlayer.PlayerGui:FindFirstChild("_BloodwareConfig")
        if folder then
            local value = folder:FindFirstChild(filename)
            if value and value:IsA("StringValue") then
                return HttpService:JSONDecode(value.Value)
            end
        end
    end
    return nil
end

local IconRegistry = {
    close = "rbxassetid://0",
    minimize = "rbxassetid://0",
    play = "rbxassetid://0",
    -- todo: add mapping from lucide names to asset ids
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
    local configName = (options.Configuration and options.Configuration.FileName) or "BloodwareConfig.json"
    local theme = options.Theme or DefaultThemes.Gray

    local self = setmetatable({}, Bloodware)
    self.Theme = theme
    self.ConfigFile = configName
    self.Tabs = {}
    self.Keybinds = {}

    local player = Players.LocalPlayer
    local screenGui = Instance.new("ScreenGui")
    screenGui.ResetOnSpawn = false
    screenGui.Name = windowName
    screenGui.Parent = player:WaitForChild("PlayerGui")
    self.ScreenGui = screenGui

    local main = new("Frame", {
        Name = "BloodwareMain",
        Parent = screenGui,
        Size = UDim2.new(0, 800, 0, 500),
        Position = UDim2.new(0.5, -400, 0.5, -250),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = hexToColor3(theme.Background),
    })
    local uiCorner = new("UICorner", {Parent = main, CornerRadius = UDim.new(0, 10)})
    self.Main = main

    local topBar = new("Frame", {Parent = main, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
    local title = new("TextLabel", {Parent = topBar, Size = UDim2.new(1,-80,1,0), Text = windowName, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.SourceSans, TextSize = 18, BackgroundTransparency = 1, Position = UDim2.new(0,12,0,0)})
    local btnClose = new("TextButton", {Parent = topBar, Size = UDim2.new(0,32,0,24), Position = UDim2.new(1,-40,0,6), Text = "X", BackgroundTransparency = 0, BorderSizePixel = 0})
    local btnMin = new("TextButton", {Parent = topBar, Size = UDim2.new(0,32,0,24), Position = UDim2.new(1,-80,0,6), Text = "-", BackgroundTransparency = 0, BorderSizePixel = 0})
    for _, b in ipairs({btnClose, btnMin}) do
        new("UICorner", {Parent = b, CornerRadius = UDim.new(0,6)})
    end

    btnClose.MouseButton1Click:Connect(function()
        main:Destroy()
    end)
    btnMin.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)

    local dragging
    local dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local sidebar = new("Frame", {Parent = main, Size = UDim2.new(0, 220, 1, -36), Position = UDim2.new(0,0,0,36), BackgroundColor3 = hexToColor3(theme.Sidebar)})
    new("UICorner", {Parent = sidebar, CornerRadius = UDim.new(0,8)})

    local profile = new("Frame", {Parent = sidebar, Size = UDim2.new(1,0,0,92), BackgroundTransparency = 1})
    local avatar = new("ImageLabel", {Parent = profile, Size = UDim2.new(0,0,0,64), Position = UDim2.new(0,12,0,12), BackgroundTransparency = 1, Image = ""})
    new("UICorner", {Parent = avatar, CornerRadius = UDim.new(1,0)})
    local uname = new("TextLabel", {Parent = profile, Position = UDim2.new(0,88/220,0,12), Size = UDim2.new(1,-100,0,22), Text = player.Name, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.SourceSans, TextSize = 16})
    local dname = new("TextLabel", {Parent = profile, Position = UDim2.new(0,88/220,0,36), Size = UDim2.new(1,-100,0,16), Text = player.DisplayName, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.SourceSans, TextSize = 12, TextColor3 = Color3.fromRGB(200,200,200)})

    spawn(function()
        local success, url = pcall(function()
            return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if success and url then
            avatar.Image = url
        end
    end)

    local searchBox = new("TextBox", {Parent = sidebar, Position = UDim2.new(0,12,0,108), Size = UDim2.new(1,-24,0,28), PlaceholderText = "Search...", Text = "", TextXAlignment = Enum.TextXAlignment.Left})
    new("UICorner", {Parent = searchBox, CornerRadius = UDim.new(0,6)})

    local tabsFrame = new("ScrollingFrame", {Parent = sidebar, Position = UDim2.new(0,0,0,148), Size = UDim2.new(1,0,1,-148), CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 6})
    local layout = new("UIListLayout", {Parent = tabsFrame, Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder})
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabsFrame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 12)
    end)

    local content = new("Frame", {Parent = main, Position = UDim2.new(0,220,0,36), Size = UDim2.new(1, -220, 1, -36), BackgroundTransparency = 1})

    self.UI = {
        Main = main,
        Sidebar = sidebar,
        TabsFrame = tabsFrame,
        Content = content,
        Search = searchBox,
        Title = title,
    }

    Keybinds[toggleKey] = Keybinds[toggleKey] or {}
    table.insert(Keybinds[toggleKey], function()
        screenGui.Enabled = not screenGui.Enabled
    end)

    local cfg = loadConfig(configName)
    if cfg and cfg.Theme and DefaultThemes[cfg.Theme] then
        self.Theme = DefaultThemes[cfg.Theme]
    end

    function self:CreateTab(name, opts)
        opts = opts or {}
        local tab = {}
        tab.Name = name
        tab.Button = new("TextButton", {Parent = tabsFrame, Size = UDim2.new(1,-12,0,36), Text = name, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
        new("UICorner", {Parent = tab.Button, CornerRadius = UDim.new(0,6)})

        tab.Page = new("Frame", {Parent = content, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false})

        tab.Button.MouseButton1Click:Connect(function()
            for _, t in ipairs(self.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundTransparency = 1
            end
            tab.Page.Visible = true
            tab.Button.BackgroundTransparency = 0
            -- save last tab
            local ok, err = saveConfig(self.ConfigFile, {Theme = "Gray", LastTab = name})
            if not ok then
                -- ignore
            end
        end)

        function tab:CreateButton(text, callback, options)
            options = options or {}
            local btn = new("TextButton", {Parent = tab.Page, Size = UDim2.new(1, -24, 0, 36), Position = UDim2.new(0,12,0,0), Text = text, BackgroundTransparency = 0, BorderSizePixel = 0})
            local corner = new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
            -- position flow
            local list = tab.Page:FindFirstChild("_Layout") or new("UIListLayout", {Parent = tab.Page, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
            btn.LayoutOrder = (#tab.Page:GetChildren())
            btn.MouseButton1Click:Connect(function()
                pcall(callback)
            end)
            -- keybind support
            if options.keybind and typeof(options.keybind) == "EnumItem" then
                Keybinds[options.keybind] = Keybinds[options.keybind] or {}
                table.insert(Keybinds[options.keybind], function()
                    pcall(callback)
                end)
            end
            return btn
        end

        function tab:CreateToggle(text, callback, options)
            options = options or {}
            local frame = new("Frame", {Parent = tab.Page, Size = UDim2.new(1, -24, 0, 36), Position = UDim2.new(0,12,0,0), BackgroundTransparency = 1})
            local label = new("TextLabel", {Parent = frame, Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0,0,0,0), Text = text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            local toggle = new("TextButton", {Parent = frame, Size = UDim2.new(0,48,0,24), Position = UDim2.new(1,-52,0,6), Text = "Off", BackgroundTransparency = 0, BorderSizePixel = 0})
            new("UICorner", {Parent = toggle, CornerRadius = UDim.new(0,6)})
            local state = options.default or false
            local function setState(v)
                state = v
                toggle.Text = state and "On" or "Off"
                pcall(callback, state)
            end
            toggle.MouseButton1Click:Connect(function()
                setState(not state)
            end)
            return toggle
        end

        function tab:CreateSlider(name, min, max, default, callback, options)
            options = options or {}
            min = min or 0; max = max or 100; default = default or min
            local frame = new("Frame", {Parent = tab.Page, Size = UDim2.new(1,-24,0,48), Position = UDim2.new(0,12,0,0), BackgroundTransparency = 1})
            local label = new("TextLabel", {Parent = frame, Text = name, Size = UDim2.new(1, -12, 0, 18), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            local sliderBg = new("Frame", {Parent = frame, Size = UDim2.new(1, -24, 0, 12), Position = UDim2.new(0,12,0,28), BackgroundTransparency = 0})
            new("UICorner", {Parent = sliderBg, CornerRadius = UDim.new(0,6)})
            local handle = new("Frame", {Parent = sliderBg, Size = UDim2.new((default-min)/(max-min), 0, 1, 0), BackgroundTransparency = 0})
            new("UICorner", {Parent = handle, CornerRadius = UDim.new(0,6)})
            local dragging = false
            sliderBg.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            sliderBg.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            sliderBg.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                    local rel = math.clamp((inp.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                    handle.Size = UDim2.new(rel, 0, 1, 0)
                    local val = min + (max - min) * rel
                    pcall(callback, val)
                end
            end)
            return frame
        end

        function tab:CreateTextbox(name, callback, options)
            options = options or {}
            local frame = new("Frame", {Parent = tab.Page, Size = UDim2.new(1,-24,0,36), Position = UDim2.new(0,12,0,0), BackgroundTransparency = 1})
            local label = new("TextLabel", {Parent = frame, Text = name, Size = UDim2.new(0.4,0,1,0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            local box = new("TextBox", {Parent = frame, Position = UDim2.new(0.4,8,0,6), Size = UDim2.new(0.6,-8,1,-12), Text = options.default or "", PlaceholderText = options.placeholder or ""})
            new("UICorner", {Parent = box, CornerRadius = UDim.new(0,6)})
            box.FocusLost:Connect(function(enter)
                pcall(callback, box.Text)
            end)
            return box
        end

        function tab:CreateSection(name)
            local lbl = new("TextLabel", {Parent = tab.Page, Text = name, Size = UDim2.new(1,-24,0,24), Position = UDim2.new(0,12,0,0), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
            return lbl
        end

        table.insert(self.Tabs, tab)
        return tab
    end

    return self
end

return Bloodware

--[[ example:
local BloodwareUI = require(https://github.com/absrtc/Bloodware/master/framework.lua)
local ui = BloodwareUI.CreateWindow({Name = "Bloodware", Configuration = {FileName = "BloodwareConfig.json"}})
local home = ui:CreateTab("Home")
home:CreateSection("General")
home:CreateButton("Click me", function() print("clicked") end, {keybind = Enum.KeyCode.E})
home:CreateToggle("Enable", function(v) print(v) end, {default = true})
]]
