local Toaster = {}
Toaster.__index = Toaster

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "Toaster"
screenGui.Parent = CoreGui

local function createToast(message, duration)
    duration = duration or 3
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 50)
    frame.Position = UDim2.new(1, 310, 1, -60)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BackgroundTransparency = 0.1
    frame.Parent = screenGui

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    TweenService:Create(frame, TweenInfo.new(0.4), {Position = UDim2.new(1, -310, 1, -60)}):Play()

    task.delay(duration, function()
        local tween = TweenService:Create(frame, TweenInfo.new(0.4), {Position = UDim2.new(1, 310, 1, -60)})
        tween:Play()
        tween.Completed:Connect(function()
            frame:Destroy()
        end)
    end)
end

function Toaster.Notify(message, duration)
    createToast(message, duration)
end

return Toaster
