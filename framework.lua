--!strict
local BloodwareUI = {}
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "BloodwareUI"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local theme = {
    Background = Color3.fromRGB(45, 25, 65),
    Foreground = Color3.fromRGB(100, 60, 160),
    Accent = Color3.fromRGB(180, 120, 255),
    Text = Color3.fromRGB(255, 255, 255),
    BorderRadius = UDim.new(0, 12),
    Font = Enum.Font.GothamBold
}

local function createRoundFrame(parent, size, pos, bg)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = bg or theme.Background
    f.BorderSizePixel = 0
    f.Parent = parent
    local uic = Instance.new("UICorner")
    uic.CornerRadius = theme.BorderRadius
    uic.Parent = f
    return f
end

local function createText(parent, text, size, color, align)
    local l = Instance.new("TextLabel")
    l.Text = text
    l.Size = UDim2.new(1, -10, 0, size + 6)
    l.Position = UDim2.new(0, 5, 0, 0)
    l.TextSize = size
    l.Font = theme.Font
    l.TextColor3 = color or theme.Text
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.BackgroundTransparency = 1
    l.Parent = parent
    return l
end

function BloodwareUI.CreateWindow(opts)
    local win = {}
    local main = createRoundFrame(gui, UDim2.new(0, 500, 0, 350), UDim2.new(0.5, -250, 0.5, -175), theme.Background)
    local titleBar = createRoundFrame(main, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0), theme.Foreground)
    createText(titleBar, opts.Name or "Bloodware", 20, theme.Text, Enum.TextXAlignment.Center)
    local tabContainer = createRoundFrame(main, UDim2.new(0, 120, 1, -40), UDim2.new(0, 0, 0, 40), theme.Background)
    local content = createRoundFrame(main, UDim2.new(1, -120, 1, -40), UDim2.new(0, 120, 0, 40), theme.Background)
    win._tabs = {}
    function win:CreateTab(name)
        local t = {}
        local btn = createRoundFrame(tabContainer, UDim2.new(1, -10, 0, 40), UDim2.new(0, 5, 0, #win._tabs * 45))
        createText(btn, name, 18)
        local tabFrame = createRoundFrame(content, UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5))
        tabFrame.Visible = false
        table.insert(win._tabs, {Button = btn, Frame = tabFrame})
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                for _, v in ipairs(win._tabs) do
                    v.Frame.Visible = false
                end
                tabFrame.Visible = true
            end
        end)
        function t:CreateSection(label)
            local s = createRoundFrame(tabFrame, UDim2.new(1, -10, 0, 35), UDim2.new(0, 5, 0, 5 + (#tabFrame:GetChildren() * 40)))
            createText(s, label, 18, theme.Accent)
        end
        function t:CreateButton(label, callback, opts)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -10, 0, 35)
            b.Position = UDim2.new(0, 5, 0, 5 + (#tabFrame:GetChildren() * 40))
            b.Text = label
            b.Font = theme.Font
            b.TextSize = 18
            b.TextColor3 = theme.Text
            b.BackgroundColor3 = theme.Foreground
            b.BorderSizePixel = 0
            b.AutoButtonColor = true
            local uic = Instance.new("UICorner")
            uic.CornerRadius = theme.BorderRadius
            uic.Parent = b
            b.Parent = tabFrame
            b.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
            if opts and opts.keybind then
                UserInputService.InputBegan:Connect(function(input, gpe)
                    if not gpe and input.KeyCode == opts.keybind then
                        if callback then callback() end
                    end
                end)
            end
        end
        function t:CreateToggle(label, callback, opts)
            local toggle = false
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -10, 0, 35)
            b.Position = UDim2.new(0, 5, 0, 5 + (#tabFrame:GetChildren() * 40))
            b.Text = label .. ": OFF"
            b.Font = theme.Font
            b.TextSize = 18
            b.TextColor3 = theme.Text
            b.BackgroundColor3 = theme.Foreground
            b.BorderSizePixel = 0
            local uic = Instance.new("UICorner")
            uic.CornerRadius = theme.BorderRadius
            uic.Parent = b
            b.Parent = tabFrame
            toggle = opts and opts.default or false
            b.Text = label .. ": " .. (toggle and "ON" or "OFF")
            b.MouseButton1Click:Connect(function()
                toggle = not toggle
                b.Text = label .. ": " .. (toggle and "ON" or "OFF")
                if callback then callback(toggle) end
            end)
        end
        return t
    end
    return win
end

return BloodwareUI
