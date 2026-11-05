local XevUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/krislowk/XevUI/refs/heads/main/source/XevUI.lua"))()

local Window = XevUI:CreateWindow({
    Title = "XevUI",
    Subtitle = "V1 Demo",
    Parent = "PlayerGui",
    Icon = "rbxassetid://7733750337",
    Width = 440,
    Height = 320,
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = Window:CreateTab("Main", "rbxassetid://7733750337")
local Combat = Window:CreateTab("Combat", "rbxassetid://7733750293")
local Config = Window:CreateTab("Config", "rbxassetid://7733750401")

local Visuals = Main:CreateSection("Visuals", "ESP, highlights, and rendering")

Visuals:CreateToggle({
    Text = "Enable ESP",
    Flag = "ESP",
    Default = true,
    Callback = function(state)
        print("[Example] ESP:", state)
    end,
})

Visuals:CreateColorPicker({
    Text = "ESP Color",
    Flag = "ESPColor",
    Default = Color3.fromRGB(224, 44, 52),
    Callback = function(color)
        print("[Example] ESP Color:", color)
    end,
})

Visuals:CreateSlider({
    Text = "Render Distance",
    Flag = "RenderDistance",
    Min = 100,
    Max = 5000,
    Default = 1000,
    Suffix = "m",
    Callback = function(value)
        print("[Example] Render Distance:", value)
    end,
})

Visuals:CreateDropdown({
    Text = "Box Style",
    Flag = "BoxStyle",
    Options = {"2D", "3D", "Corner", "Filled"},
    Default = "2D",
    Callback = function(selected)
        print("[Example] Box Style:", selected)
    end,
})

local PlayerSection = Main:CreateSection("Player", "Local player modifications")

PlayerSection:CreateToggle({
    Text = "Infinite Jump",
    Flag = "InfJump",
    Default = false,
    Callback = function(state)
        print("[Example] Infinite Jump:", state)
    end,
})

PlayerSection:CreateSlider({
    Text = "Walk Speed",
    Flag = "WalkSpeed",
    Min = 16,
    Max = 500,
    Default = 16,
    Callback = function(speed)
        local char = game.Players.LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = speed end
    end,
})

PlayerSection:CreateSlider({
    Text = "Jump Power",
    Flag = "JumpPower",
    Min = 50,
    Max = 500,
    Default = 50,
    Callback = function(power)
        local char = game.Players.LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.JumpPower = power end
    end,
})

local Aimbot = Combat:CreateSection("Aimbot", "Target selection and aim control")

Aimbot:CreateToggle({
    Text = "Enable Aimbot",
    Flag = "Aimbot",
    Default = false,
    Callback = function(state)
        print("[Example] Aimbot:", state)
    end,
})

Aimbot:CreateKeybind({
    Text = "Aim Key",
    Flag = "AimKey",
    Default = Enum.KeyCode.E,
    Callback = function(key)
        print("[Example] Aim Key:", key.Name)
    end,
})

Aimbot:CreateSlider({
    Text = "FOV",
    Flag = "AimbotFOV",
    Min = 10,
    Max = 360,
    Default = 90,
    Suffix = "°",
    Callback = function(fov)
        print("[Example] Aimbot FOV:", fov)
    end,
})

Aimbot:CreateDropdown({
    Text = "Aim Part",
    Flag = "AimPart",
    Options = {"Head", "Torso", "UpperTorso", "LowerTorso"},
    Default = "Head",
    Callback = function(part)
        print("[Example] Aim Part:", part)
    end,
})

local Target = Combat:CreateSection("Target Filter", "Who the aimbot can target")

Target:CreateDropdown({
    Text = "Team Check",
    Flag = "TeamCheck",
    Options = {"Enemies Only", "Everyone", "Ignore"},
    Default = "Enemies Only",
    Callback = function(mode)
        print("[Example] Team Check:", mode)
    end,
})

Target:CreateDropdown({
    Text = "Whitelisted Players",
    Flag = "Whitelist",
    Multi = true,
    Options = {"Player1", "Player2", "Player3", "Player4"},
    Default = {},
    Callback = function(list)
        print("[Example] Whitelist updated:", #list, "players")
    end,
})

local ConfigSection = Config:CreateSection("Config", "Save and load your settings")

ConfigSection:CreateButton({
    Text = "Save Config",
    Callback = function()
        local ok, json = pcall(function() return Window:SaveConfig() end)
        if ok and json then
            local writeOk = pcall(function()
                writefile("xevui_config.json", json)
            end)
            if writeOk then
                Window:Notify({
                    Title = "Saved",
                    Text = "Config written to xevui_config.json",
                    Duration = 3,
                })
            else
                Window:Notify({
                    Title = "Save Failed",
                    Text = "Executor does not support writefile",
                    Duration = 4,
                })
            end
        end
    end,
})

ConfigSection:CreateButton({
    Text = "Load Config",
    Callback = function()
        local readOk, data = pcall(function()
            return readfile("xevui_config.json")
        end)
        if readOk and data then
            local loadOk = Window:LoadConfig(data)
            if loadOk then
                Window:Notify({
                    Title = "Loaded",
                    Text = "Config restored from file",
                    Duration = 3,
                })
            else
                Window:Notify({
                    Title = "Load Failed",
                    Text = "File is corrupted or invalid",
                    Duration = 4,
                })
            end
        else
            Window:Notify({
                Title = "Load Failed",
                Text = "No config file found",
                Duration = 4,
            })
        end
    end,
})

ConfigSection:CreateButton({
    Text = "Reset All",
    Callback = function()
        for key, value in pairs(XevUI.Flags) do
            if type(value) == "boolean" then
                XevUI.Flags[key] = false
            elseif type(value) == "number" then
                XevUI.Flags[key] = 0
            end
        end
        Window:Notify({
            Title = "Reset",
            Text = "All flags cleared",
            Duration = 3,
        })
    end,
})

ConfigSection:CreateDivider()

local InfoSection = Config:CreateSection("Info", "Library information")

InfoSection:CreateTextbox({
    Text = "Username",
    Placeholder = "Type your name",
    Flag = "Username",
    Default = game.Players.LocalPlayer.Name,
    Callback = function(value)
        print("[Example] Username set to:", value)
    end,
})

InfoSection:CreateParagraph({
    Text = "XevUI is a single-file UI library for Roblox with drag clamping, minimize to opener, search filter, save and load, and full element coverage. All elements write to XevUI.Flags when a Flag is provided.",
})

InfoSection:CreateLabel({
    Text = "Version: V1",
})

local AboutSection = Config:CreateSection("About", "Quick actions")

AboutSection:CreateButton({
    Text = "Show Welcome Notification",
    Callback = function()
        Window:Notify({
            Title = "Welcome to XevUI",
            Text = "Press RightShift to toggle the menu",
            Duration = 5,
        })
    end,
})

AboutSection:CreateButton({
    Text = "Switch to Combat Tab",
    Callback = function()
        Window:SelectTab("Combat")
    end,
})

AboutSection:CreateButton({
    Text = "Destroy UI",
    Callback = function()
        Window:Destroy()
    end,
})

task.delay(0.5, function()
    Window:Notify({
        Title = "XevUI Loaded",
        Text = "Example script running. Press RightShift to toggle.",
        Duration = 5,
    })
end)
