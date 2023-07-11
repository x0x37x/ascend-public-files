local library = {}
library.ui =
    loadstring(game:HttpGet("https://raw.githubusercontent.com/x0x37x/ascend-public-files/main/ui-components.lua"))()
library.flags = {}
library.storage = {}
library.currentTab = "Welcome"

local coreGui = game:GetService("CoreGui")
local userInputService = game:GetService("UserInputService")
local mouse = game:GetService("Players").LocalPlayer:GetMouse()
local tweenService = game:GetService("TweenService")
local defaultTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local isToggled = false
function library:ToggleHamborger()
    isToggled = not isToggled

    local tween1 =
        library:Tween(
        library.ui.Main.TabBtnFrame,
        {
            Position = UDim2.new(0, isToggled and 0 or -114, 0, 48)
        }
    )

    local tween2 =
        library:Tween(
        library.ui.Main.TopBar.Hamborger,
        {
            Rotation = isToggled and 180 or 0
        }
    )

    local tween3 =
        library:Tween(
        library.ui.Main.Tabs,
        {
            Position = UDim2.new(0, isToggled and 114 or 0, 0, 48)
        }
    )

    tween3:Play()
    tween1:Play()
    tween2:Play()
    tween1.Completed:Wait()
end

function library:SwitchTab(NewTab)
    if NewTab == library.currentTab then
        if isToggled then
            library:ToggleHamborger()
        end
        return
    end
    local tabs = library.ui.Main.Tabs
    local tab = tabs:FindFirstChild(("Tab_%s"):format(NewTab))
    local currentTab = tabs:FindFirstChild(("Tab_%s"):format(library.currentTab))
    library.currentTab = NewTab
    local tween1 =
        library:Tween(
        tabs,
        {
            Position = UDim2.new(1.25, 0, 0, 48)
        }
    )
    tween1:Play()
    tween1.Completed:Wait()
    tabs.Position = UDim2.new(0, 0, -1.25, 0)
    currentTab.Visible = false
    tab.Visible = true
    library:ToggleHamborger()
end

function library:UpdateSlider(Flag, Value)
    local slider = library.storage[Flag]
    local sliderOptions = library.storage[("Options_%s"):format(Flag)]
    local percent = (mouse.X - slider.SliderValueBack.AbsolutePosition.X) / slider.SliderValueBack.AbsoluteSize.X
    local useTween = false
    if Value then
        useTween = true
        percent = (Value - sliderOptions.Min) / (sliderOptions.Max - sliderOptions.Min)
    end
    percent = math.clamp(percent, 0, 1)
    if precise then
        Value =
            Value or
            tonumber(
                string.format("%.1f", tostring(sliderOptions.Min + (sliderOptions.Max - sliderOptions.Min) * percent))
            )
    else
        Value = Value or math.floor(sliderOptions.Min + (sliderOptions.Max - sliderOptions.Min) * percent)
    end
    library.flags[Flag] = tonumber(Value)
    slider.SliderValue.Text = tostring(Value)
    if useTween then
        library:Tween(
            slider.SliderValueBack.SliderPosition,
            {
                Size = UDim2.new(percent, 0, 1, 0)
            }
        ):Play()
    else
        slider.SliderValueBack.SliderPosition.Size = UDim2.new(percent, 0, 1, 0)
    end
    sliderOptions.Callback(tonumber(Value))
end

function library:Tween(Object, Properties, Data)
    return tweenService:Create(Object, Data and Data or defaultTweenInfo, Properties)
end

function library:UpdateToggle(Flag, NewValue)
    library.flags[Flag] = NewValue == nil and not library.flags[Flag] or NewValue or false
    local toggleModule = library.storage[Flag]
    toggleModule.ToggleState.BackgroundColor3 =
        library.flags[Flag] and Color3.fromRGB(69, 241, 184) or Color3.fromRGB(241, 135, 135)
    library.storage[("CB_%s"):format(Flag)](library.flags[Flag])
end

function library:Create(name)
    if syn and syn.protect_gui then
        syn.protect_gui(library.ui)
    end
    library.ui.Parent = gethui and gethui() or coreGui
    library.ui.Name = name
    library.ui.ResetOnSpawn = false

    local main = library.ui.Main
    main.TopBar.Title.Text = name

    local drag = function(objDrag, objHold)
        local objHold = objHold or objDrag
        local dragging = false
        local dragInput
        local dragStart
        local startPos

        local function update(input)
            local delta = input.Position - dragStart
            objDrag.Position =
                UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end

        objHold.InputBegan:Connect(
            function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    dragStart = input.Position
                    startPos = objDrag.Position

                    input.Changed:Connect(
                        function()
                            if input.UserInputState == Enum.UserInputState.End then
                                dragging = false
                            end
                        end
                    )
                end
            end
        )

        objDrag.InputChanged:Connect(
            function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    dragInput = input
                end
            end
        )

        userInputService.InputChanged:Connect(
            function(input)
                if input == dragInput and dragging then
                    update(input)
                end
            end
        )
    end

    drag(main, main.TopBar)

    main.TopBar.Hamborger.MouseButton1Click:Connect(
        function()
            library:ToggleHamborger()
        end
    )

    main.TabBtnFrame.TabBtns.TabBtnsPadding.PaddingBottom = UDim.new(0, 2)
    main.TabBtnFrame.TabBtns.CanvasSize = UDim2.new(0, 0, 0, 0)
    main.TabBtnFrame.TabBtns.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local tabs = {}
    function tabs:New(TabName)
        local tab = main.Tabs.Tab:Clone()
        local tabButton = main.TabBtnFrame.TabBtns.TabBtn:Clone()
        tab.Name = TabName
        tab.CanvasSize = UDim2.new(0, 0, 0, 16)
        tab.AutomaticCanvasSize = Enum.AutomaticSize.Y

        tabButton.Name = ("Tab_%s"):format(TabName)
        tabButton.Visible = true
        tabButton.Text = TabName
        tabButton.Name = TabName
        tabButton.Parent = main.TabBtnFrame.TabBtns

        tab.Name = ("Tab_%s"):format(TabName)
        tab.Parent = main.Tabs
        tabButton.MouseButton1Click:Connect(
            function()
                library:SwitchTab(TabName)
            end
        )

        local components = {}
        function components:Button(Text, Callback)
            local Callback = Callback or function()
                end
            local button = main.Components.ButtonModule:Clone()
            button.ButtonLabel.Text = Text
            button.MouseButton1Click:Connect(Callback)
            button.Parent = tab
            button.Visible = true
        end

        function components:Toggle(Text, Flag, Default, Callback)
            library.flags[Flag] = Default or false
            local Callback = Callback or function()
                end
            local toggle = main.Components.ToggleModule:Clone()
            toggle.Name = ("Toggle_%s"):format(Flag)
            toggle.ToggleLabel.Text = Text
            toggle.ToggleState.BackgroundColor3 =
                Default and Color3.fromRGB(69, 241, 184) or Color3.fromRGB(241, 135, 135)
            toggle.MouseButton1Click:Connect(
                function()
                    library:UpdateToggle(Flag)
                end
            )
            library.storage[Flag] = toggle
            library.storage[("CB_%s"):format(Flag)] = Callback or function()
                end
            toggle.Parent = tab
            toggle.Visible = true
        end

        function components:Slider(Text, Flag, Min, Max, Default, Precise, Callback)
            local Callback = Callback or function()
                end
            library.flags[Flag] = Default or Min
            library.storage[("Options_%s"):format(Flag)] = {
                Min = Min,
                Max = Max,
                Default = Default,
                Precise = Precise,
                Callback = Callback or function()
                    end
            }
            local slider = main.Components.SliderModule:Clone()
            library.storage[Flag] = slider
            slider.Name = ("Slider_%s"):format(Flag)
            slider.SliderLabel.Text = Text
            slider.Parent = tab
            slider.Visible = true

            slider.SliderValue.Text = tostring(Default)

            local dragging, boxFocused, allowed =
                false,
                false,
                {
                    [""] = true,
                    ["-"] = true
                }

            slider.SliderValueBack.InputBegan:Connect(
                function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        library:UpdateSlider(Flag)
                        dragging = true
                    end
                end
            )

            ascendOrig.connections[#ascendOrig.connections + 1] =
                userInputService.InputEnded:Connect(
                function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end
            )

            ascendOrig.connections[#ascendOrig.connections + 1] =
                userInputService.InputChanged:Connect(
                function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        library:UpdateSlider(Flag)
                    end
                end
            )

            slider.SliderValue.Focused:Connect(
                function()
                    boxFocused = true
                end
            )

            slider.SliderValue.FocusLost:Connect(
                function()
                    boxFocused = false
                    if slider.SliderValue.Text == "" then
                        library:UpdateSlider(Flag, Default)
                    end
                    library:UpdateSlider(Flag, math.clamp(tonumber(slider.SliderValue.Text), Min, Max))
                end
            )

            slider.SliderValue:GetPropertyChangedSignal("Text"):Connect(
                function()
                    if not boxFocused then
                        return
                    end
                    slider.SliderValue.Text = slider.SliderValue.Text:gsub("%D+", "")

                    local text = slider.SliderValue.Text

                    if not tonumber(text) then
                        slider.SliderValue.Text = tostring(library.Flags[Flag])
                    end
                end
            )

            library:UpdateSlider(Flag, Default)
        end

        function components:Keybind(Text, Flag, Default, Callback)
            library.flags[Flag] = typeof(Default) == "string" and Enum.KeyCode[Default] or Default
            local Callback = Callback or function()
                end
            local keybind = main.Components.KeybindModule:Clone()
            keybind.KeybindLabel.Text = Text
            keybind.Name = ("Keybind_%s"):format(Flag)
            keybind.Visible = true
            keybind.Parent = tab
            local banned = {
                Return = true,
                Space = true,
                Tab = true,
                Backquote = true,
                CapsLock = true,
                Escape = true,
                Unknown = true,
                Backspace = true
            }

            local shortNames = {
                RightControl = "RCtrl",
                LeftControl = "LCtrl",
                LeftShift = "LShift",
                RightShift = "RShift",
                Semicolon = ";",
                Quote = '"',
                LeftBracket = "[",
                RightBracket = "]",
                Equals = "=",
                Minus = "-",
                RightAlt = "RAlt",
                LeftAlt = "RAlt"
            }

            local keyName = Default == nil and "None" or type(Default) ~= "string" and Default.Name or Default or nil

            local defaultName = (keyName == nil and "None") or shortNames[keyName] or keyName or "None"

            keybind.KeybindValue.KeybindValueLabel.Text = defaultName

            ascendOrig.connections[#ascendOrig.connections + 1] =
                userInputService.InputBegan:Connect(
                function(inp, gpe)
                    if gpe then
                        return
                    end
                    if inp.UserInputType ~= Enum.UserInputType.Keyboard then
                        return
                    end
                    if inp.KeyCode ~= library.flags[Flag] then
                        return
                    end
                    if Callback then
                        Callback(tostring(library.flags[Flag]))
                    end
                end
            )

            keybind.MouseButton1Click:Connect(
                function()
                    keybind.KeybindValue.KeybindValueLabel.Text = "..."
                    task.wait()
                    local key = userInputService.InputEnded:Wait()
                    if key.UserInputType ~= Enum.UserInputType.Keyboard then
                        keybind.KeybindValue.KeybindValueLabel.Text = defaultName
                        return
                    end
                    local keyName = key.KeyCode.Name
                    if banned[keyName] then
                        keybind.KeybindValue.KeybindValueLabel.Text = "None"
                        library.flags[Flag] = nil
                        return
                    end
                    library.flags[Flag] = Enum.KeyCode[keyName]
                    defaultName = shortNames[keyName] or keyName
                    keybind.KeybindValue.KeybindValueLabel.Text = defaultName
                end
            )
        end

        function components:Dropdown(Text, Flag, Options, Callback)
            local Callback = Callback or function()
                end
            local isOpen = false
            local dropdownTop, dropdownBottom =
                main.Components.DropdownTop:Clone(),
                main.Components.DropdownBottom:Clone()

            local function setAllVisible()
                local options = dropdownBottom:GetChildren()
                for i = 1, #options do
                    local option = options[i]
                    if option:IsA("TextButton") then
                        option.Visible = true
                    end
                end
            end

            local function toggleDropdown()
                isOpen = not isOpen
                library:Tween(
                    dropdownTop.DropdownIco.DropdownIcoLabel,
                    {
                        Rotation = isOpen and 180 or 0
                    }
                ):Play()
                if isOpen then
                    setAllVisible()
                    dropdownBottom.Visible = true
                    library:Tween(
                        dropdownBottom,
                        {
                            Size = UDim2.new(0, 438, 0, dropdownBottom.UIListLayout.AbsoluteContentSize.Y)
                        }
                    ):Play()
                else
                    local t =
                        library:Tween(
                        dropdownBottom,
                        {
                            Size = UDim2.new(0, 438, 0, 0)
                        }
                    )
                    t:Play()
                    t.Completed:Wait()
                    dropdownBottom.Visible = false
                end
            end

            local options = {}

            local function createOption(Option)
                if dropdownBottom:FindFirstChild(("Option_%s"):format(Option.Key)) then
                    return
                end

                table.insert(options, Option)

                local option = main.Components.DropdownOption:Clone()
                option.Text = Option.Key
                option.Name = ("Option_%s"):format(Option.Key)
                option.Visible = true
                option.Parent = dropdownBottom
                option.MouseButton1Click:Connect(
                    function()
                        task.spawn(toggleDropdown)
                        dropdownTop.TextBox.Text = Option.Key
                        library.flags[Flag] = Option
                        Callback(Option.Value)
                    end
                )
            end

            local function resizeShit()
                dropdownTop.TextBox.Size = UDim2.new(0, dropdownTop.TextBox.TextBounds.X + 12, 0, 22)
                local posX = -(dropdownTop.TextBox.Size.X.Offset + 34)
                dropdownTop.TextBox.Position = UDim2.new(1, posX, 0.5, 0)
            end

            local function removeOption(optionName)
                local option = dropdownBottom:FindFirstChild(("Option_%s"):format(optionName))
                if option then
                    option:Destroy()
                    for i, v in next, options do
                        if v.Key == optionName then
                            table.remove(options, i)
                            break
                        end
                    end
                end
            end

            local function removeAllOptions()
                for _, v in next, dropdownBottom:GetChildren() do
                    print(v.Name:sub(1, 7))
                    if v.Name:sub(1, 7) == "Option_" then
                        print(v.Name, v.Text)
                        removeOption(v.Text)
                    end
                end
            end

            local function refreshOptions(Options)
                print(Options)
                removeAllOptions()
                for i, v in next, Options do
                    if typeof(i) == "number" then
                        print(i, v)
                        createOption({Key = v, Value = v})
                    else
                        print(i, v)
                        createOption({Key = i, Value = v})
                    end
                end
                dropdownTop.TextBox.Text = (options[1] and options[1].Key or "None")
                library.flags[Flag] = options[1] or "None"
            end

            local function searchDropdown(text)
                local options = dropdownBottom:GetChildren()
                for i = 1, #options do
                    local option = options[i]
                    if text == "" then
                        setAllVisible()
                    else
                        if option:IsA("TextButton") then
                            if option.Name:lower():sub(8, string.len(text) + 7) == text:lower() then
                                option.Visible = true
                            else
                                option.Visible = false
                            end
                        end
                    end
                end
            end

            local isSearching = false
            dropdownTop.TextBox.Focused:Connect(
                function()
                    if not isOpen then
                        toggleDropdown()
                    end
                    isSearching = true
                end
            )

            dropdownTop.TextBox.FocusLost:Connect(
                function()
                    isSearching = false
                    if dropdownTop.TextBox.Text == "" then
                        dropdownTop.TextBox.Text = library.flags[Flag].Key
                    end
                end
            )

            dropdownTop.TextBox:GetPropertyChangedSignal("Text"):Connect(
                function()
                    resizeShit()
                    if isSearching then
                        searchDropdown(dropdownTop.TextBox.Text)
                    end
                end
            )

            dropdownBottom.ChildAdded:Connect(
                function()
                    if isOpen then
                        library:Tween(
                            dropdownBottom,
                            {
                                Size = UDim2.new(0, 438, 0, dropdownBottom.UIListLayout.AbsoluteContentSize.Y)
                            }
                        ):Play()
                    end
                end
            )

            refreshOptions(Options)
            dropdownTop.TextBox.Text = (options[1] and options[1].Key or "None")
            dropdownTop.Visible = true
            dropdownTop.Parent = tab
            dropdownBottom.Parent = tab
            library.flags[Flag] = options[1] or "None"
            dropdownTop.TextLabel.Text = Text

            dropdownTop.DropdownIco.InputEnded:Connect(
                function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        toggleDropdown()
                    end
                end
            )

            resizeShit()

            return {
                removeOption = removeOption,
                removeAllOptions = removeAllOptions,
                createOption = createOption,
                refreshOptions = refreshOptions
            }
        end

        function components:Separator()
            local separator = main.Components.Separator:Clone()
            separator.Visible = true
            separator.Parent = tab
        end

        function components:Label(Text)
            local label = main.Components.Label:Clone()
            label.Text = Text
            label.Visible = true
            label.Parent = tab
            return label
        end

        return components
    end
    return tabs
end

return library
