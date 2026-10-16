-- Cien Lab v1.1.0 | Roblox Studio LocalScript | Android-first authorized configuration UI
-- Place in StarterPlayer > StarterPlayerScripts. Gameplay effects require approved Bindable integrations.

local VERSION = "1.1.0"
local GUI_NAME = "CienLabGui"
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild(GUI_NAME) then return end

local DEFAULTS = {
 theme = "Obsidian", accent = Color3.fromRGB(0, 225, 190), secondary = Color3.fromRGB(82, 105, 255),
 backgroundOpacity = 0.08, borderIntensity = 0.7, cornerRadius = 12, glow = true, particles = false,
 animationIntensity = 0.7, reducedMotion = false, textScale = 1, uiScale = 1, compact = false,
 aimbotEnabled = false, aimlockEnabled = false, cameraFOV = 90, selectionRadius = 140, circleVisible = true,
 circleThickness = 2, circleOpacity = 0.45, cursorAlignment = true, sensitivity = 1, smoothness = 0.35,
 responseLimit = 8, predictionEnabled = false, predictionLead = 0.12, cursorPreset = "Crosshair",
 cursorImageId = "", cursorScale = 1, cursorOpacity = 1, cursorOutline = true, notifications = true,
 notificationDuration = 2.5, notificationPosition = "Top", notificationSound = false,
 masterVolume = 0.5, uiVolume = 0.35, notificationVolume = 0.55, uiSounds = true,
 soundPreset = "Soft", customSoundId = "", menuTransitions = true, logoAnimation = true,
 gradientAnimation = true, notificationTransitions = true, circleAnimation = false, hitEffects = true,
}
local settings = table.clone(DEFAULTS)
local state = { destroyed = false, connections = {}, tweens = {}, activeSounds = {}, currentTab = "Precision", menuOpen = false, controller = nil }
local function connect(signal, callback)
 local c = signal:Connect(callback); table.insert(state.connections, c); return c
end
local function disconnectAll()
 for _, c in ipairs(state.connections) do pcall(function() c:Disconnect() end) end
 table.clear(state.connections)
 for _, t in ipairs(state.tweens) do pcall(function() t:Cancel() end) end
 table.clear(state.tweens)
 for _, s in ipairs(state.activeSounds) do pcall(function() s:Stop(); s:Destroy() end) end
 table.clear(state.activeSounds)
end
local function tween(obj, duration, props, style)
 if settings.reducedMotion or settings.animationIntensity <= 0 then
  for k, v in pairs(props) do pcall(function() obj[k] = v end) end
  return nil
 end
 local t = TweenService:Create(obj, TweenInfo.new(duration / math.max(settings.animationIntensity, 0.15), style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
 table.insert(state.tweens, t); t:Play(); return t
end
local function clamp(v, lo, hi) return math.clamp(tonumber(v) or lo, lo, hi) end
local function isAssetId(value) return tostring(value):match("^%d+$") ~= nil and #tostring(value) <= 20 end
local function make(class, props, parent)
 local obj = Instance.new(class)
 for k, v in pairs(props or {}) do obj[k] = v end
 obj.Parent = parent
 return obj
end
local themes = {
 Obsidian = { bg=Color3.fromRGB(13,16,23), panel=Color3.fromRGB(22,27,37), text=Color3.fromRGB(238,244,250), muted=Color3.fromRGB(145,158,176), accent=Color3.fromRGB(0,225,190), secondary=Color3.fromRGB(82,105,255) },
 Violet = { bg=Color3.fromRGB(18,13,27), panel=Color3.fromRGB(32,23,45), text=Color3.fromRGB(247,239,255), muted=Color3.fromRGB(175,157,196), accent=Color3.fromRGB(193,105,255), secondary=Color3.fromRGB(91,122,255) },
 Ember = { bg=Color3.fromRGB(24,16,15), panel=Color3.fromRGB(39,27,25), text=Color3.fromRGB(255,243,236), muted=Color3.fromRGB(190,157,146), accent=Color3.fromRGB(255,125,74), secondary=Color3.fromRGB(255,190,80) },
 Ice = { bg=Color3.fromRGB(11,21,29), panel=Color3.fromRGB(20,37,49), text=Color3.fromRGB(235,250,255), muted=Color3.fromRGB(145,179,195), accent=Color3.fromRGB(95,220,255), secondary=Color3.fromRGB(105,150,255) },
}
local theme = themes[settings.theme]
local gui = make("ScreenGui", {Name=GUI_NAME, ResetOnSpawn=false, IgnoreGuiInset=false, DisplayOrder=50, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, playerGui)
local scale = make("UIScale", {Scale=settings.uiScale}, gui)

-- Visual practice overlays only; these never target or modify players.
local overlayGui = make("ScreenGui", {
 Name="CienLabOverlayGui", ResetOnSpawn=false, IgnoreGuiInset=false,
 DisplayOrder=10, ZIndexBehavior=Enum.ZIndexBehavior.Sibling
}, playerGui)
local fovCircle = make("Frame", {
 Name="SelectionCircle", AnchorPoint=Vector2.new(0.5,0.5),
 Position=UDim2.fromScale(0.5,0.5),
 Size=UDim2.fromOffset(settings.selectionRadius*2,settings.selectionRadius*2),
 BackgroundTransparency=1, BorderSizePixel=0, Active=false, ZIndex=1
}, overlayGui)
make("UICorner", {CornerRadius=UDim.new(1,0)}, fovCircle)
local fovStroke = make("UIStroke", {
 Color=settings.accent or theme.accent, Thickness=settings.circleThickness,
 Transparency=1-settings.circleOpacity
}, fovCircle)
local reticle = make("TextLabel", {
 Name="TrainingReticle", AnchorPoint=Vector2.new(0.5,0.5),
 Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(34,34),
 BackgroundTransparency=1, Text="＋", Font=Enum.Font.GothamBold,
 TextSize=28, TextColor3=settings.accent or theme.accent,
 TextStrokeColor3=Color3.new(0,0,0),
 TextStrokeTransparency=settings.cursorOutline and 0.15 or 1, ZIndex=2
}, overlayGui)
local customReticle = make("ImageLabel", {
 Name="CustomTrainingReticle", AnchorPoint=Vector2.new(0.5,0.5),
 Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(34,34),
 BackgroundTransparency=1, Image="", ImageTransparency=0, Visible=false, ZIndex=2
}, overlayGui)
local function refreshOverlays()
 if not fovCircle.Parent then return end
 local radius=clamp(settings.selectionRadius,20,420)
 fovCircle.Size=UDim2.fromOffset(radius*2,radius*2)
 fovCircle.Visible=settings.circleVisible==true
 fovStroke.Color=settings.accent or theme.accent
 fovStroke.Thickness=clamp(settings.circleThickness,1,8)
 fovStroke.Transparency=1-clamp(settings.circleOpacity,0,1)
 local glyphs={Crosshair="＋",Dot="•",Ring="○",Chevron="⌄"}
 local scaleFactor=clamp(settings.cursorScale,0.5,2)
 local size=math.floor(34*scaleFactor)
 reticle.Size=UDim2.fromOffset(size,size)
 reticle.TextSize=math.floor(28*scaleFactor)
 reticle.Text=glyphs[settings.cursorPreset] or glyphs.Crosshair
 reticle.TextColor3=settings.accent or theme.accent
 reticle.TextTransparency=1-clamp(settings.cursorOpacity,0.1,1)
 reticle.TextStrokeTransparency=settings.cursorOutline and 0.15 or 1
 local imageId=tostring(settings.cursorImageId or "")
 local validImage=imageId:match("^%d+$")~=nil and #imageId<=20
 customReticle.Visible=validImage
 customReticle.Image=validImage and ("rbxassetid://"..imageId) or ""
 customReticle.ImageTransparency=1-clamp(settings.cursorOpacity,0.1,1)
 customReticle.Size=UDim2.fromOffset(size,size)
 reticle.Visible=not validImage
end
local bubble = make("TextButton", {Name="CienBubble", Text="C", Font=Enum.Font.GothamBlack, TextSize=23, TextColor3=Color3.new(1,1,1), AutoButtonColor=false, Size=UDim2.fromOffset(54,54), Position=UDim2.new(0,18,0.55,-27), BackgroundColor3=theme.panel, ZIndex=20}, gui)
make("UICorner", {CornerRadius=UDim.new(1,0)}, bubble)
local bubbleStroke = make("UIStroke", {Color=theme.accent, Thickness=2, Transparency=0.12}, bubble)
local bubbleGradient = make("UIGradient", {Color=ColorSequence.new(theme.accent, theme.secondary), Rotation=35}, bubble)
local main = make("Frame", {Name="Main", Size=UDim2.new(0.9,0,0.82,0), Position=UDim2.new(0.5,0,0.5,0), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=theme.bg, BackgroundTransparency=settings.backgroundOpacity, Visible=false, ClipsDescendants=true}, gui)
make("UICorner", {CornerRadius=UDim.new(0,settings.cornerRadius)}, main)
local mainStroke = make("UIStroke", {Color=theme.accent, Thickness=1.4, Transparency=1-settings.borderIntensity}, main)
local header = make("Frame", {Size=UDim2.new(1,0,0,58), BackgroundColor3=theme.panel, BorderSizePixel=0}, main)
make("UIGradient", {Color=ColorSequence.new(theme.panel, theme.bg), Rotation=0}, header)
local logo = make("TextLabel", {BackgroundTransparency=1, Position=UDim2.new(0,16,0,5), Size=UDim2.new(1,-125,0,29), Font=Enum.Font.GothamBlack, Text="CIEN LAB", TextColor3=theme.text, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left}, header)
local subtitle = make("TextLabel", {BackgroundTransparency=1, Position=UDim2.new(0,17,0,32), Size=UDim2.new(1,-130,0,17), Font=Enum.Font.GothamMedium, Text="PRECISION SYSTEMS  /  v"..VERSION, TextColor3=theme.accent, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left}, header)
local function headerButton(text, x, color)
 local b=make("TextButton", {Text=text, Font=Enum.Font.GothamBold, TextSize=17, TextColor3=color or theme.text, BackgroundColor3=theme.bg, AutoButtonColor=false, Size=UDim2.fromOffset(34,32), Position=UDim2.new(1,x,0,13)}, header)
 make("UICorner", {CornerRadius=UDim.new(0,8)}, b); return b
end
local helpBtn=headerButton("?",-78,theme.accent); local minimizeBtn=headerButton("—",-40); local closeBtn=headerButton("×",-2,Color3.fromRGB(255,105,120))
local nav = make("ScrollingFrame", {Name="Navigation", Size=UDim2.new(1,0,0,42), Position=UDim2.new(0,0,0,58), BackgroundColor3=theme.panel, BorderSizePixel=0, ScrollBarThickness=2, ScrollingDirection=Enum.ScrollingDirection.X, CanvasSize=UDim2.new(0,0,0,0)}, main)
make("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder}, nav)
make("UIPadding", {PaddingLeft=UDim.new(0,9), PaddingRight=UDim.new(0,9), PaddingTop=UDim.new(0,5), PaddingBottom=UDim.new(0,5)}, nav)
local content = make("ScrollingFrame", {Name="Content", Size=UDim2.new(1,-16,1,-116), Position=UDim2.new(0,8,0,108), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=theme.accent, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y}, main)
make("UIPadding", {PaddingBottom=UDim.new(0,12), PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,4), PaddingTop=UDim.new(0,4)}, content)
make("UIListLayout", {Padding=UDim.new(0,9), SortOrder=Enum.SortOrder.LayoutOrder}, content)
local toastLayer=make("Frame", {Name="Notifications", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), ZIndex=40}, gui)
local function notify(title, message, duration)
 if not settings.notifications then return end
 local card=make("Frame", {BackgroundColor3=theme.panel, BackgroundTransparency=0.06, Size=UDim2.new(0.78,0,0,66), Position=UDim2.new(0.5,0,0,12), AnchorPoint=Vector2.new(0.5,0), ZIndex=41}, toastLayer)
 make("UICorner", {CornerRadius=UDim.new(0,10)}, card); make("UIStroke", {Color=theme.accent, Transparency=0.15}, card)
 make("TextLabel", {BackgroundTransparency=1, Position=UDim2.new(0,12,0,7), Size=UDim2.new(1,-24,0,19), Text=string.upper(title), Font=Enum.Font.GothamBold, TextSize=12, TextColor3=theme.accent, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=42}, card)
 make("TextLabel", {BackgroundTransparency=1, Position=UDim2.new(0,12,0,28), Size=UDim2.new(1,-24,0,28), Text=message, Font=Enum.Font.Gotham, TextSize=11, TextWrapped=true, TextColor3=theme.text, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=42}, card)
 card.Position=UDim2.new(0.5,0,0,-80); tween(card,0.25,{Position=UDim2.new(0.5,0,0,12)})
 task.delay(duration or settings.notificationDuration,function() if card.Parent then tween(card,0.2,{Position=UDim2.new(0.5,0,0,-80)}); task.delay(0.25,function() if card.Parent then card:Destroy() end end) end end)
end
local function applyTheme()
 refreshOverlays()
 theme=themes[settings.theme] or themes.Obsidian
 bubble.BackgroundColor3=theme.panel; bubbleStroke.Color=settings.accent or theme.accent; bubbleGradient.Color=ColorSequence.new(settings.accent or theme.accent, settings.secondary or theme.secondary)
 main.BackgroundColor3=theme.bg; main.BackgroundTransparency=clamp(settings.backgroundOpacity,0,0.45); mainStroke.Color=settings.accent or theme.accent; mainStroke.Transparency=1-clamp(settings.borderIntensity,0,1)
 header.BackgroundColor3=theme.panel; logo.TextColor3=theme.text; subtitle.TextColor3=settings.accent or theme.accent
 nav.BackgroundColor3=theme.panel; content.ScrollBarImageColor3=settings.accent or theme.accent; scale.Scale=clamp(settings.uiScale,0.75,1.15)
 for _,obj in ipairs(main:GetDescendants()) do
  if obj:IsA("TextLabel") or obj:IsA("TextButton") then
   if obj:GetAttribute("CienAccent") then obj.TextColor3=settings.accent or theme.accent elseif obj:GetAttribute("CienMuted") then obj.TextColor3=theme.muted elseif not obj:GetAttribute("CienKeepColor") then obj.TextColor3=theme.text end
  end
  if obj:IsA("UIStroke") and obj:GetAttribute("CienBorder") then obj.Color=settings.accent or theme.accent end
 end
end
local function saveSetting(key,value)
 if DEFAULTS[key]==nil then return end
 local default=DEFAULTS[key]
 if typeof(default)=="number" then value=clamp(value, key=="cameraFOV" and 70 or key=="selectionRadius" and 20 or 0, key=="cameraFOV" and 130 or key=="selectionRadius" and 420 or key=="textScale" and 1.3 or key=="uiScale" and 1.15 or key=="notificationDuration" and 8 or key=="predictionLead" and 1 or key=="sensitivity" and 3 or key=="smoothness" and 1 or key=="responseLimit" and 30 or key=="circleThickness" and 8 or key=="circleOpacity" and 1 or key=="cursorScale" and 2 or key=="cursorOpacity" and 1 or key=="masterVolume" and 1 or key=="uiVolume" and 1 or key=="notificationVolume" and 1 or key=="animationIntensity" and 1 or key=="borderIntensity" and 1 or key=="backgroundOpacity" and 0.45 or key=="cornerRadius" and 24 or 1)
 elseif typeof(default)=="boolean" then value=not not value
 elseif typeof(default)=="string" then value=tostring(value) end
 settings[key]=value
 if key=="theme" then applyTheme() elseif key=="uiScale" then scale.Scale=value elseif key=="backgroundOpacity" or key=="borderIntensity" or key=="cornerRadius" then applyTheme() end
 refreshOverlays()
 if state.controller and state.controller:IsA("BindableEvent") then pcall(function() state.controller:Fire("SettingChanged",key,value) end) end
end
local function findController()
 local root=player:FindFirstChild("PlayerScripts")
 if root then
  local c=root:FindFirstChild("CienLabController")
  if c and (c:IsA("BindableFunction") or c:IsA("BindableEvent")) then state.controller=c; return true end
 end
 state.controller=nil; return false
end
local function requestController(action, payload)
 if not findController() then return false,"Authorized controller unavailable" end
 local ok,result=pcall(function()
  if state.controller:IsA("BindableFunction") then return state.controller:Invoke(action,payload) end
  state.controller:Fire(action,payload); return true
 end)
 if not ok then return false,"Controller error: "..tostring(result) end
 if result==false then return false,"Controller declined request" end
 return true,result
end
local function clearContent()
 for _,v in ipairs(content:GetChildren()) do if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then v:Destroy() end end
end
local function section(title, description)
 local card=make("Frame",{BackgroundColor3=theme.panel,BackgroundTransparency=0.05,Size=UDim2.new(1,0,0,54),AutomaticSize=Enum.AutomaticSize.Y},content)
 make("UICorner",{CornerRadius=UDim.new(0,10)},card); make("UIPadding",{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)},card)
 make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},card)
 local h=make("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),Text=title,Font=Enum.Font.GothamBold,TextSize=14*settings.textScale,TextColor3=theme.text,TextXAlignment=Enum.TextXAlignment.Left,AutomaticSize=Enum.AutomaticSize.Y},card)
 local d=make("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,Text=description or "",TextWrapped=true,Font=Enum.Font.Gotham,TextSize=11*settings.textScale,TextColor3=theme.muted,TextXAlignment=Enum.TextXAlignment.Left},card)
 return card
end
local function button(parent,text,callback,accent)
 local b=make("TextButton",{BackgroundColor3=accent and theme.accent or theme.bg,Size=UDim2.new(1,0,0,36),Text=text,Font=Enum.Font.GothamBold,TextSize=12*settings.textScale,TextColor3=accent and theme.bg or theme.text,AutoButtonColor=false},parent)
 make("UICorner",{CornerRadius=UDim.new(0,8)},b)
 connect(b.Activated,function() callback(b) end)
 connect(b.MouseEnter,function() tween(b,0.12,{BackgroundTransparency=0.12}) end); connect(b.MouseLeave,function() tween(b,0.12,{BackgroundTransparency=0}) end)
 return b
end
local function toggle(parent,label,key,description,onChange)
 local row=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,48)},parent)
 local text=make("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,-72,1,0),Text=label..(description and "\n"..description or ""),TextWrapped=true,Font=Enum.Font.GothamMedium,TextSize=12*settings.textScale,TextColor3=theme.text,TextXAlignment=Enum.TextXAlignment.Left},row)
 local b=make("TextButton",{Size=UDim2.fromOffset(52,28),Position=UDim2.new(1,-52,0.5,-14),Text="",BackgroundColor3=settings[key] and theme.accent or Color3.fromRGB(58,66,79),AutoButtonColor=false},row)
 make("UICorner",{CornerRadius=UDim.new(1,0)},b)
 local knob=make("Frame",{Size=UDim2.fromOffset(22,22),Position=settings[key] and UDim2.new(1,-25,0.5,-11) or UDim2.new(0,3,0.5,-11),BackgroundColor3=Color3.new(1,1,1)},b); make("UICorner",{CornerRadius=UDim.new(1,0)},knob)
 local function refresh() tween(b,0.12,{BackgroundColor3=settings[key] and theme.accent or Color3.fromRGB(58,66,79)}); tween(knob,0.12,{Position=settings[key] and UDim2.new(1,-25,0.5,-11) or UDim2.new(0,3,0.5,-11)}) end
 connect(b.Activated,function() saveSetting(key,not settings[key]); refresh(); if onChange then onChange(settings[key]) end end)
 return row
end
local function slider(parent,label,key,minV,maxV,step,unit)
 local row=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,58)},parent)
 local value=make("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),Text="",Font=Enum.Font.GothamMedium,TextSize=12*settings.textScale,TextColor3=theme.text,TextXAlignment=Enum.TextXAlignment.Left},row)
 local track=make("TextButton",{Text="",AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(52,61,75),Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,0,31)},row); make("UICorner",{CornerRadius=UDim.new(1,0)},track)
 local fill=make("Frame",{BackgroundColor3=settings.accent or theme.accent,Size=UDim2.new(0,0,1,0)},track); make("UICorner",{CornerRadius=UDim.new(1,0)},fill)
 local knob=make("Frame",{BackgroundColor3=Color3.new(1,1,1),Size=UDim2.fromOffset(16,16),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0,0,0.5,0)},track); make("UICorner",{CornerRadius=UDim.new(1,0)},knob)
 local dragging=false
 local function setFromX(x)
  local alpha=clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
  local v=minV+(maxV-minV)*alpha; v=math.floor(v/step+0.5)*step; saveSetting(key,v)
  local a=(settings[key]-minV)/(maxV-minV); value.Text=label..": "..tostring(settings[key])..(unit or ""); fill.Size=UDim2.new(a,0,1,0); knob.Position=UDim2.new(a,0,0.5,0)
 end
 local function refresh() local a=(settings[key]-minV)/(maxV-minV); value.Text=label..": "..tostring(settings[key])..(unit or ""); fill.Size=UDim2.new(a,0,1,0); knob.Position=UDim2.new(a,0,0.5,0) end
 connect(track.InputBegan,function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true; setFromX(input.Position.X) end end)
 connect(UserInputService.InputChanged,function(input) if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then setFromX(input.Position.X) end end)
 connect(UserInputService.InputEnded,function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
 refresh(); return row
end
local function selector(parent,label,key,options,callback)
 local row=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,40)},parent)
 make("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(0.48,0,1,0),Text=label,Font=Enum.Font.GothamMedium,TextSize=12*settings.textScale,TextColor3=theme.text,TextXAlignment=Enum.TextXAlignment.Left},row)
 local b=make("TextButton",{Size=UDim2.new(0.52,0,1,0),Position=UDim2.new(0.48,0,0,0),BackgroundColor3=theme.bg,Text=tostring(settings[key]).."  ▾",Font=Enum.Font.Gotham,TextSize=11*settings.textScale,TextColor3=theme.text,AutoButtonColor=false},row); make("UICorner",{CornerRadius=UDim.new(0,7)},b)
 local index=table.find(options,settings[key]) or 1
 connect(b.Activated,function() index=index%#options+1; saveSetting(key,options[index]); b.Text=tostring(settings[key]).."  ▾"; if callback then callback(settings[key]) end end)
 return row
end
local function textInput(parent,label,key,placeholder)
 local row=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,58)},parent)
 make("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),Text=label,Font=Enum.Font.GothamMedium,TextSize=12*settings.textScale,TextColor3=theme.text,TextXAlignment=Enum.TextXAlignment.Left},row)
 local box=make("TextBox",{Size=UDim2.new(1,0,0,31),Position=UDim2.new(0,0,0,24),BackgroundColor3=theme.bg,Text=tostring(settings[key]),PlaceholderText=placeholder or "Enter value",ClearTextOnFocus=false,Font=Enum.Font.Code,TextSize=11,TextColor3=theme.text,PlaceholderColor3=theme.muted},row); make("UICorner",{CornerRadius=UDim.new(0,7)},box)
 connect(box.FocusLost,function() local v=box.Text:gsub("%s+",""); if v=="" or v=="0" then saveSetting(key,""); box.Text=""; return end
  if (key=="cursorImageId" or key=="customSoundId") and not isAssetId(v) then box.Text=settings[key]; notify("INVALID ASSET ID","Use numeric Roblox asset ID only."); return end
  saveSetting(key,v); box.Text=v
 end)
 return row
end
local function statusCard(parent,title,desc,key)
 local c=section(title,desc)
 local status=make("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,22),Text="STATUS: checking controller…",Font=Enum.Font.GothamBold,TextSize=10,TextColor3=theme.muted,TextXAlignment=Enum.TextXAlignment.Left},c)
 local function refresh() local ok=findController(); status.Text=ok and "STATUS: controller detected · request not yet confirmed" or "STATUS: INACTIVE · authorized controller unavailable"; status.TextColor3=ok and theme.accent or Color3.fromRGB(255,174,102) end
 button(c,settings[key] and "Disable" or "Enable",function(b)
  local wanted=not settings[key]
  if wanted then local ok,msg=requestController("EnableFeature",{feature=key,settings=settings}); if not ok then notify("INTEGRATION UNAVAILABLE",msg); refresh(); return end end
  saveSetting(key,wanted); b.Text=wanted and "Disable" or "Enable"; refresh()
  if not wanted then requestController("DisableFeature",{feature=key}) end
 end,true)
 button(c,"Open feature settings",function() state.currentTab=key=="aimbotEnabled" and "Precision" or "Precision"; notify("CONFIGURATION","Use the Precision controls below.") end)
 refresh(); return c
end
local function buildTab(tab)
 clearContent(); state.currentTab=tab
 if tab=="Precision" then
  section("AUTHORIZED AIM SYSTEM","These controls only send configuration requests to your experience's approved controller. They do not target players by themselves.")
  statusCard(content,"Aimbot Button","Camera-assisted targeting request. Inactive unless CienLabController accepts it.","aimbotEnabled")
  statusCard(content,"Aimlock Button","Weapon aiming configuration request. Weapon authority remains on your game server.","aimlockEnabled")
  local s=section("TARGET SELECTION","Camera FOV uses degrees. Selection radius uses screen-space pixels.")
  slider(s,"Camera FOV","cameraFOV",70,130,1,"°"); slider(s,"Selection radius","selectionRadius",20,420,5," px")
  toggle(s,"Show selection circle","circleVisible"); slider(s,"Circle thickness","circleThickness",1,8,1," px"); slider(s,"Circle opacity","circleOpacity",0,1,0.05)
  toggle(s,"Cursor-aligned selection","cursorAlignment","Prefer targets nearest the approved controller's cursor ray.")
  local p=section("CAMERA RESPONSE","These values are sent to the authorized controller; this UI does not alter the camera alone.")
  slider(p,"Sensitivity","sensitivity",0.1,3,0.05,"×"); slider(p,"Smoothness","smoothness",0,1,0.05); slider(p,"Response limit","responseLimit",1,30,1,"°/frame")
  toggle(p,"Enable prediction","predictionEnabled"); slider(p,"Prediction lead","predictionLead",0,1,0.01," s")
  button(p,"Send configuration to controller",function() local ok,msg=requestController("ApplySettings",settings); notify(ok and "CONFIGURATION SENT" or "CONTROLLER UNAVAILABLE",ok and "Controller accepted the request." or msg) end,true)
 elseif tab=="Appearance" then
  local s=section("THEME ENGINE","Preset themes apply immediately. Custom accent colors use RGB values configured in source defaults.")
  selector(s,"Theme","theme",{"Obsidian","Violet","Ember","Ice"},applyTheme)
  slider(s,"Background opacity","backgroundOpacity",0,0.45,0.01); slider(s,"Border intensity","borderIntensity",0,1,0.05); slider(s,"Corner radius","cornerRadius",4,24,1," px")
  toggle(s,"Glow accents","glow"); toggle(s,"Decorative particles","particles"); toggle(s,"Compact layout","compact", "Use tighter spacing where supported.")
  slider(s,"Animation intensity","animationIntensity",0,1,0.05); toggle(s,"Reduced motion","reducedMotion"); slider(s,"Text scale","textScale",0.85,1.3,0.05,"×"); slider(s,"UI scale","uiScale",0.75,1.15,0.05,"×")
 elseif tab=="Cursor" then
  local s=section("CURSOR PREVIEW","A GUI cursor overlay is not the operating-system cursor and may not override every Roblox interface.")
  selector(s,"Preset","cursorPreset",{"Crosshair","Dot","Ring","Chevron"},function() end)
  textInput(s,"Custom image asset ID","cursorImageId","Numeric asset ID (optional)"); slider(s,"Cursor scale","cursorScale",0.5,2,0.05,"×"); slider(s,"Cursor opacity","cursorOpacity",0.1,1,0.05)
  toggle(s,"Cursor outline","cursorOutline"); button(s,"Validate / preview cursor",function() if settings.cursorImageId~="" and not isAssetId(settings.cursorImageId) then notify("INVALID ID","Use numeric asset ID."); return end; notify("CURSOR CONFIGURATION",settings.cursorImageId~="" and "Asset ID saved. Runtime asset access depends on Roblox permissions." or ("Preset: "..settings.cursorPreset)) end,true)
  button(s,"Reset cursor",function() saveSetting("cursorPreset",DEFAULTS.cursorPreset); saveSetting("cursorImageId",""); saveSetting("cursorScale",1); saveSetting("cursorOpacity",1); saveSetting("cursorOutline",true); buildTab("Cursor") end)
 elseif tab=="Audio" then
  local s=section("AUDIO MIXER","Test sounds are temporary and destroyed after playback. Asset permissions are controlled by Roblox.")
  slider(s,"Master volume","masterVolume",0,1,0.05); slider(s,"UI volume","uiVolume",0,1,0.05); slider(s,"Notification volume","notificationVolume",0,1,0.05)
  toggle(s,"UI sounds","uiSounds"); toggle(s,"Notification sound","notificationSound"); selector(s,"Sound preset","soundPreset",{"Soft","Digital","Pulse"})
  textInput(s,"Custom sound asset ID","customSoundId","Numeric asset ID (optional)")
  button(s,"Test sound",function()
   if not settings.uiSounds then notify("AUDIO DISABLED","Enable UI sounds to test."); return end
   local id=settings.customSoundId~="" and settings.customSoundId or (settings.soundPreset=="Pulse" and "9118823101" or settings.soundPreset=="Digital" and "6026984224" or "9118828565")
   if not isAssetId(id) then notify("INVALID SOUND ID","Use a numeric asset ID."); return end
   local sound=make("Sound",{Name="CienLabTempSound",SoundId="rbxassetid://"..id,Volume=settings.masterVolume*settings.uiVolume},SoundService); table.insert(state.activeSounds,sound)
   local ok=pcall(function() ContentProvider:PreloadAsync({sound}) end); if not ok then notify("SOUND UNAVAILABLE","Asset could not be preloaded."); sound:Destroy(); return end
   sound.Ended:Connect(function() sound:Destroy() end); sound:Play(); task.delay(10,function() if sound.Parent then sound:Stop(); sound:Destroy() end end)
  end,true)
  button(s,"Stop sounds",function() for _,sound in ipairs(state.activeSounds) do pcall(function() sound:Stop(); sound:Destroy() end) end; table.clear(state.activeSounds); notify("AUDIO","Temporary sounds stopped.") end)
 elseif tab=="Effects" then
  local s=section("MOTION & EFFECTS","Effects are bounded UI animations. Reduced motion disables tween-based transitions.")
  toggle(s,"Menu transitions","menuTransitions"); toggle(s,"Logo animation","logoAnimation"); toggle(s,"Gradient animation","gradientAnimation"); toggle(s,"Notification transitions","notificationTransitions"); toggle(s,"Selection-circle animation","circleAnimation"); toggle(s,"Hit-confirmation effects","hitEffects","Requires your approved gameplay controller."); toggle(s,"Decorative particles","particles"); slider(s,"Glow intensity","borderIntensity",0,1,0.05)
 elseif tab=="Help" then
  local s=section("CIEN LAB QUICK GUIDE","Search-free, mobile-readable control reference.")
  local help={
   {"Precision","Aimbot and Aimlock are independent requests to an approved controller. Without it, both remain inactive. Camera FOV is degrees; selection radius is screen-space pixels."},
   {"Sensitivity & smoothness","Sensitivity scales the controller's response. Smoothness is a 0–1 interpolation setting. Response limit is degrees per frame."},
   {"Prediction","Prediction lead is seconds of lead time for moving targets supplied by your own controller. It does not discover targets."},
   {"Cursor","Choose a built-in preset or numeric Roblox image asset ID. Asset access can fail; use a built-in preset as fallback."},
   {"Notifications","Notification duration is adjustable. Events must come from your approved controller; this UI does not scan players."},
   {"Audio","Master, UI, and notification volume are 0–1. Sound assets require permission and may not load."},
   {"Appearance & Effects","Themes update immediately. Reduced motion minimizes transitions; UI scale and text scale support small screens."},
   {"Moving the UI","Drag the Cien bubble to reposition. Tap it to open; use — to minimize. × closes the panel and returns to the bubble."},
   {"Reset & persistence","Reset asks for confirmation. Settings persist across character respawns for this client session; LocalScripts cannot securely save settings between separate sessions."},
  }
  for _,item in ipairs(help) do section(item[1],item[2]) end
  button(s,"Check authorized controller",function() notify("CONTROLLER",findController() and "CienLabController found in PlayerScripts." or "No approved CienLabController found.") end,true)
 else
  local s=section("SETTINGS","Client-side configuration is session-only. Add server-backed storage in your own experience for cross-session persistence.")
  button(s,"Reset all settings",function()
   local dialog=make("Frame",{Size=UDim2.new(0.84,0,0,142),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=theme.panel,ZIndex=80},gui); make("UICorner",{CornerRadius=UDim.new(0,12)},dialog); make("UIStroke",{Color=theme.accent,Thickness=2},dialog)
   make("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,12),Size=UDim2.new(1,-24,0,42),Text="Reset every Cien Lab setting to defaults?",TextWrapped=true,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=theme.text,ZIndex=81},dialog)
   local yes=make("TextButton",{Size=UDim2.new(0.44,0,0,34),Position=UDim2.new(0.04,0,1,-45),Text="RESET",BackgroundColor3=theme.accent,TextColor3=theme.bg,Font=Enum.Font.GothamBold,ZIndex=81},dialog); make("UICorner",{CornerRadius=UDim.new(0,8)},yes)
   local no=make("TextButton",{Size=UDim2.new(0.44,0,0,34),Position=UDim2.new(0.52,0,1,-45),Text="CANCEL",BackgroundColor3=theme.bg,TextColor3=theme.text,Font=Enum.Font.GothamBold,ZIndex=81},dialog); make("UICorner",{CornerRadius=UDim.new(0,8)},no)
   yes.Activated:Once(function() for k,v in pairs(DEFAULTS) do settings[k]=v end; applyTheme(); dialog:Destroy(); buildTab("Settings"); notify("RESET COMPLETE","Defaults restored for this session.") end); no.Activated:Once(function() dialog:Destroy() end)
  end,true)
  button(s,"Reset appearance only",function() for _,k in ipairs({"theme","accent","secondary","backgroundOpacity","borderIntensity","cornerRadius","glow","particles","animationIntensity","reducedMotion","textScale","uiScale","compact"}) do settings[k]=DEFAULTS[k] end; applyTheme(); buildTab("Appearance"); notify("APPEARANCE RESET","Targeting settings were preserved.") end)
  button(s,"Recheck controller",function() notify("CONTROLLER",findController() and "Controller found." or "Controller unavailable.") end)
 end
 content.CanvasPosition=Vector2.zero
end
local tabs={"Precision","Cursor","Appearance","Audio","Effects","Help","Settings"}
for i,tab in ipairs(tabs) do
 local b=make("TextButton",{Name=tab,Size=UDim2.fromOffset(94,30),BackgroundColor3=tab==state.currentTab and theme.accent or theme.bg,Text=tab,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=tab==state.currentTab and theme.bg or theme.text,AutoButtonColor=false,LayoutOrder=i},nav)
 make("UICorner",{CornerRadius=UDim.new(0,7)},b)
 connect(b.Activated,function()
  for _,child in ipairs(nav:GetChildren()) do if child:IsA("TextButton") then local active=child.Name==tab; child.BackgroundColor3=active and theme.accent or theme.bg; child.TextColor3=active and theme.bg or theme.text end end
  buildTab(tab)
 end)
end
connect(nav.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"),function() nav.CanvasSize=UDim2.new(0,nav.UIListLayout.AbsoluteContentSize.X+20,0,0) end)
local function openMenu()
 main.Visible=true; state.menuOpen=true; if settings.menuTransitions and not settings.reducedMotion then main.Size=UDim2.new(0.86,0,0.78,0); tween(main,0.22,{Size=UDim2.new(0.9,0,0.82,0)}) end
 bubble.Visible=false; buildTab(state.currentTab)
end
local function minimize() main.Visible=false; state.menuOpen=false; bubble.Visible=true end
connect(bubble.Activated,openMenu); connect(minimizeBtn.Activated,minimize); connect(closeBtn.Activated,minimize); connect(helpBtn.Activated,function() buildTab("Help") end)
local dragging,dragStart,startPos,dragMoved=false,nil,nil,false
connect(bubble.InputBegan,function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragMoved=false; dragStart=input.Position; startPos=bubble.Position end end)
connect(UserInputService.InputChanged,function(input)
 if dragging and dragStart and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
  local delta=input.Position-dragStart; if math.abs(delta.X)+math.abs(delta.Y)>6 then dragMoved=true end
  local cam=workspace.CurrentCamera; local vp=cam and cam.ViewportSize or Vector2.new(800,600)
  local x=clamp(startPos.X.Offset+delta.X,0,math.max(0,vp.X-bubble.AbsoluteSize.X)); local y=clamp(startPos.Y.Scale*vp.Y+startPos.Y.Offset+delta.Y,0,math.max(0,vp.Y-bubble.AbsoluteSize.Y))
  bubble.Position=UDim2.fromOffset(x,y)
 end
end)
connect(UserInputService.InputEnded,function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false; dragStart=nil end end)
-- Drag header to reposition the main panel on touch or desktop.
local panelDragging,panelStart,panelPos=false,nil,nil
connect(header.InputBegan,function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then panelDragging=true; panelStart=input.Position; panelPos=main.Position end end)
connect(UserInputService.InputChanged,function(input) if panelDragging and panelStart and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then local d=input.Position-panelStart; main.Position=UDim2.new(panelPos.X.Scale,panelPos.X.Offset+d.X,panelPos.Y.Scale,panelPos.Y.Offset+d.Y) end end)
connect(UserInputService.InputEnded,function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then panelDragging=false; panelStart=nil end end)
connect(player.CharacterAdded,function() task.defer(function() if gui.Parent and not state.destroyed then findController() end end) end)
connect(gui.Destroying,function() state.destroyed=true; disconnectAll() end)
connect(bubble.MouseEnter,function() if settings.glow then tween(bubbleStroke,0.12,{Thickness=3}) end end)
connect(bubble.MouseLeave,function() tween(bubbleStroke,0.12,{Thickness=2}) end)
-- Low-cost optional logo/gradient animation; no permanent render-step binding.
if settings.logoAnimation then task.spawn(function() while gui.Parent and not state.destroyed do if not settings.reducedMotion and settings.logoAnimation then tween(bubbleGradient,2,{Rotation=bubbleGradient.Rotation+45},Enum.EasingStyle.Linear) end; task.wait(2.1) end end) end
applyTheme(); refreshOverlays(); buildTab("Precision")
notify("CIEN LAB READY","UI loaded. Gameplay integrations are inactive until your approved controller is connected.",3)
