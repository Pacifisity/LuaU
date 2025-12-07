loadstring(
    game:HttpGet(
        'https://raw.githubusercontent.com/Pacifisity/LuaU/refs/heads/main/Global.lua'
    )
)()

# **Sage UI Library**

A lightweight, animated, fantasy-themed Roblox UI framework featuring draggable windows, tabs, sections, buttons, toggles, inputs, sliders, and a CoreGui-aligned minimize system.

---

## **📦 Installation**

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/<yourname>/<repo>/main/Sage.lua"
))()
```

---

## **🚀 Quick Start**

```lua
local Window = Library:CreateWindow({
    Title = "My Script",
    Size = Vector2.new(500, 300)
})

local MainTab = Window:Tab({ Title = "Main" })
local Actions = MainTab:Section({ Title = "Actions" })

Actions:Button({
    Title = "Do Something",
    Callback = function()
        print("Button clicked!")
    end
})

local toggle = Actions:Toggle({
    Title = "Auto Farm",
    Default = false,
    Callback = function(state)
        print("AutoFarm =", state)
    end
})

local input = Actions:Input({
    Title = "Player Name",
    Placeholder = "Enter name...",
    Callback = function(text)
        print("User typed:", text)
    end
})

local slider = Actions:Slider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 100,
    Default = 16,
    Decimals = 0,
    Callback = function(value)
        print("Speed:", value)
    end
})
```

---

## **🧱 UI Structure**

```
Window  
 └─ Tabs  
     └─ Sections  
         ├─ Buttons  
         ├─ Toggles  
         ├─ Inputs  
         └─ Sliders  
```

---

## **✨ Features**

### **Window**
- Draggable
- Customizable size/title  
- Close + minimize  
- Floating “S” restore icon  
- Autos resets toggles on close  

### **Tabs**
- Left-side tabbar  
- Smooth fade/hover animations  
- First tab auto-selected  

### **Sections**
- Auto-sizing  
- Rounded corners  
- Clean spacing  

### **Buttons**
- Smooth hover/click tweens  
- Callback support  

### **Toggles**
- Animated switch  
- `.Set(bool)` / `.Get()`  
- Auto-reset on window close  

### **Inputs**
- Placeholder text  
- Callback fires on Enter  

### **Sliders**
- Drag interaction  
- Min/Max/Default  
- Decimal precision  
- `.Set(value)` / `.Get()`  

---

## **📘 API Reference**

### **`Library:CreateWindow(options)`**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Title` | string | `"Pain"` | Window title |
| `Size` | Vector2 | `(500, 300)` | Window size |

Returns a **Window**.

---

### **`Window:Tab(options)`**
| Option | Type | Default |
|--------|------|---------|
| `Title` | string | `"Tab"` |

Returns a **Tab**.

---

### **`Tab:Section(options)`**
| Option | Type | Default |
|--------|------|---------|
| `Title` | string | `"Section"` |

Returns a **Section**.

---

### **`Section:Button(options)`**
| Field | Description |
|-------|-------------|
| `Title` | Button text |
| `Callback` | Runs when clicked |

---

### **`Section:Toggle(options)`**
| Field | Description |
|-------|-------------|
| `Title` | Label text |
| `Default` | Initial value |
| `Callback` | Receives `(state)` |

Returns:

```lua
{
    Set = function(bool),
    Get = function() -> bool
}
```

---

### **`Section:Input(options)`**
| Field | Description |
|-------|-------------|
| `Title` | Label |
| `Placeholder` | Hint text |
| `Callback` | Receives `(text)` |

Returns the TextBox instance.

---

### **`Section:Slider(options)`**
| Field | Description |
|-------|-------------|
| `Title` | Label |
| `Min` | Minimum |
| `Max` | Maximum |
| `Default` | Initial value |
| `Decimals` | Decimal places |
| `Callback` | Receives `(value)` |

Returns:

```lua
{
    Get = function() -> number,
    Set = function(number)
}
```

---

## **🎨 Theme (Fantasy Dark Purple)**

```lua
Theme = {
    Background = Color3.fromRGB(10, 10, 16),
    Accent = Color3.fromRGB(145, 70, 255),
    AccentDark = Color3.fromRGB(90, 40, 180),
    Text = Color3.fromRGB(235, 220, 255),
    TextMuted = Color3.fromRGB(155, 130, 190),
    Section = Color3.fromRGB(20, 10, 30),
    Button = Color3.fromRGB(25, 15, 40),
    ToggleOn = Color3.fromRGB(150, 90, 255),
    ToggleOff = Color3.fromRGB(50, 40, 60),
}
```

---

## **📜 Module Export**

```lua
return {
    CreateWindow = Library.CreateWindow
}
```
