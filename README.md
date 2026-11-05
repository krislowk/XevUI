# XevUI

A single-file UI library for Roblox. Dark theme, red accents, zero dependencies. Built for script hubs, internal tools, and exploit menus.

## Features

- Auto-scales to viewport size
- Draggable window with boundary clamping
- Minimizes to a draggable, semi-transparent opener widget
- Search bar filters elements by label name
- Custom script icon support (header and opener)
- Per-tab icons
- Profile section displays local player avatar, display name, and username
- Save and load configs to JSON
- Slider supports drag and direct text input

## Load

```lua
local XevUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/krislowk/xevui/main/Source/XevUI.lua"))()
```

## Quick Start

```lua
local Window = XevUI:CreateWindow({
    Title = "XevUI",
    Subtitle = "V1",
    Parent = "PlayerGui",
    Icon = "rbxassetid://7733750337",
    Width = 440,
    Height = 320,
})

local Main = Window:CreateTab("Main", "rbxassetid://7733750337")
local Section = Main:CreateSection("Visuals", "Toggle and configure ESP")

Section:CreateToggle({
    Text = "Enable ESP",
    Flag = "ESP",
    Default = true,
    Callback = function(value)
        print("ESP:", value)
    end,
})

Section:CreateSlider({
    Text = "Render Distance",
    Min = 100,
    Max = 2000,
    Default = 1000,
    Suffix = "m",
    Flag = "RenderDistance",
})
```

## API

### Window

| Method | Description |
|---|---|
| `XevUI:CreateWindow(config)` | Creates the UI. Returns the Window object. |
| `Window:CreateTab(name, iconId)` | Adds a tab. `iconId` is optional. |
| `Window:SelectTab(name)` | Switches to a specific tab by name. |
| `Window:Notify(options)` | Shows a notification. Options: Title, Text, Duration. |
| `Window:SaveConfig()` | Returns a JSON string of all current Flags. |
| `Window:LoadConfig(json)` | Restores Flags from a JSON string. |
| `Window:SetTitle(text)` | Updates the window title. |
| `Window:SetSubtitle(text)` | Updates the window subtitle. |
| `Window:Destroy()` | Destroys the UI. |

### Config keys

| Key | Type | Default |
|---|---|---|
| `Title` | string | `"XevUI"` |
| `Subtitle` | string | `"V1"` |
| `Parent` | string or Instance | `"PlayerGui"` |
| `Icon` | number or string | `nil` |
| `Width` | number | `440` |
| `Height` | number | `320` |
| `ToggleKey` | Enum.KeyCode | `RightShift` |

### Tab

| Method | Description |
|---|---|
| `Tab:CreateSection(title, description)` | Creates a section. Description is optional. |
| `Tab:CreateDivider()` | Adds a thin horizontal line between tabs. |
| `Tab:Select()` | Activates this tab. |

### Section Elements

| Method | Options |
|---|---|
| `CreateButton` | Text, Callback |
| `CreateToggle` | Text, Flag, Default, Callback |
| `CreateSlider` | Text, Min, Max, Default, Suffix, Flag, Callback |
| `CreateTextbox` | Text, Placeholder, Default, Flag, Callback |
| `CreateDropdown` | Text, Options, Default, Multi, Flag, Callback |
| `CreateColorPicker` | Text, Default, Flag, Callback |
| `CreateKeybind` | Text, Default, Flag, Callback |
| `CreateLabel` | Text |
| `CreateParagraph` | Text |
| `CreateDivider` | none |

## Flags

Any element with a `Flag` string writes to `XevUI.Flags[flag]` when its value changes. Read this table anywhere in your script.

```lua
print(XevUI.Flags.ESP)
print(XevUI.Flags.RenderDistance)
```

## Save and Load

```lua
local json = Window:SaveConfig()
writefile("xevui_config.json", json)

local data = readfile("xevui_config.json")
Window:LoadConfig(data)
```

Color3 values are encoded with a type tag. LoadConfig restores them as Color3 instances.

## Search

Typing into the sidebar search box filters every element across all tabs by its label text. Empty query restores all elements.

## Structure

```
XevUI/
  Source/
    XevUI.lua
  README.md
  example.lua
```
