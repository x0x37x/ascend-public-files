local library
local ENV = {}
ENV.DEV_MODE = false -- enable debugging features
ENV.VERSION = "v1.1"

-- Loading prerequisites
assert(getgenv, "Failed to find exploit environment, please use a better hack!!!")
getgenv().setidentity = setidentity or (syn and syn.set_thread_identity)
local requiredSpecialFunctions = {"getsenv", "getupvalue", "firetouchinterest", "setidentity"}

for _, v in next, requiredSpecialFunctions do
  assert(getgenv()[v] ~= nil, string.format("Required function '%s' is missing.", v))
end

local ascend = setmetatable({}, { 
  __index = function(self, index)
    self[index] = {}
    return self[index]
  end 
})

ascend.loadSlotIndex = 1
ascend.bypassLoadCooldown = true
ascend.slotToCloneTo = 1
ascend.slotToCloneFrom = 1
ascend.IsDupeOperation = false

local services = setmetatable({}, {
  __index = function(self, index)
    self[index] = game:GetService(index)
    return self[index]
  end
})

--> Cures Dizzler's depression of 9e9 UIs
local existingUi = ((gethui and gethui() or services.CoreGUI):FindFirstChild(ENV.DEV_MODE and "PenisWare" or "Ascend"))
if ascendOrig then
  hookfunction(getrawmetatable(game).__newindex, ascendOrig.newindex)
  hookfunction(getrawmetatable(game).__namecall, ascendOrig.namecall)
  for i, v in next, ascendOrig.connections do
    v:Disconnect()
  end
  if existingUi then
    existingUi:Destroy()
  end
  getgenv().ascendOrig = nil
end

-- Variables
local players = services.Players
local replicatedStorage = services.ReplicatedStorage
local userInputService = services.UserInputService
local client = players.LocalPlayer
local mouse = client:GetMouse()
local loadSaveEnvironment = getsenv(client.PlayerGui.LoadSaveGUI.LoadSaveClient)
local propertyPurchasingEnvironment = getsenv(client.PlayerGui.PropertyPurchasingGUI.PropertyPurchasingClient)
local id = client.UserId
local b = {}
local oldPurchaseMode = propertyPurchasingEnvironment.enterPurchaseMode

assert(loadSaveEnvironment ~= nil or propertyPurchasingEnvironment ~= nil, "Failed to get environments")

local remoteKey = debug.getupvalue(loadSaveEnvironment.loadSlot, 12)
assert(type(remoteKey) == "number", "Failed to verify remote key was successfully grabbed (Expected type number)")
assert(remoteKey < 1, "Failed to verify remote key was successfully grabbed (Number higher than expected)")


local serverPropertyPositions = {Vector3.new(-240, 19, 204), Vector3.new(-61, 19, 526), Vector3.new(406, 0, 396), Vector3.new(712, 0, 396), Vector3.new(712, 0, 90), Vector3.new(658, 0, -250), Vector3.new(383, 0, -250), Vector3.new(275, 0, -512), Vector3.new(68, 0, -197)}

for _, v in next, workspace.Properties:GetChildren() do
  if v:IsA("Model") and v:FindFirstChild("Owner") and table.find(serverPropertyPositions, v.OriginSquare.Position) then
    ascend.properties[table.find(serverPropertyPositions, v.OriginSquare.Position)] = v
  end
end

function ascend:CanLoad()
  return replicatedStorage.LoadSaveRequests.ClientMayLoad:InvokeServer()
end

function ascend:GetCurrentVehicle()
  local humanoid = ascend:GetCharacter():FindFirstChild("Humanoid")
  if humanoid then
    local seat = humanoid.SeatPart
    return seat and seat.Name == "DriveSeat" and seat.Parent
  end
end

ascend.treeRegions = {}

for _, v in next, workspace:GetChildren() do
  if v.Name == "TreeRegion" then
    table.insert(ascend.treeRegions, v)
  end
end

function ascend:FetchTreeClasses()
  ascend.treeClasses = {}
  for _, v1 in next, ascend.treeRegions do
    for _, v2 in next, v1:GetChildren() do
      if v2:FindFirstChild("TreeClass") then
        if not table.find(ascend.treeClasses, v2.TreeClass.Value) then
          table.insert(ascend.treeClasses, v2.TreeClass.Value)
        end
      end
    end
  end
  table.sort(ascend.treeClasses, function(a, b)
    return a:lower() < b:lower()
  end)
end

ascend:FetchTreeClasses()

function ascend:Drag(model)
  replicatedStorage.Interaction.ClientIsDragging:FireServer(model)
end

function ascend:GetAxeModule(class)
  local axeModule = game:GetService("ReplicatedStorage").AxeClasses[string.format("AxeClass_%s", class)]
  if axeModule then
    return require(axeModule).new()
  end
  return false, "Invalid Class!"
end

function ascend:GetAxeStats(axeClass, treeClass)
  local stats, err = ascend:GetAxeModule(axeClass)
  if err then
    return false, err
  end
  if stats.SpecialTrees and stats.SpecialTrees[treeClass] ~= nil then
    for i, v in next, stats.SpecialTrees[treeClass] do
      stats[i] = v
    end
  end
  stats.dps = (stats.Damage / stats.SwingCooldown)
  return stats
end

function ascend:FindBestAxe(treeClass)
  local axeStats, highestDps = nil, 0
  for _, v in next, ascend:GetToolsInInventory() do
    local stats = ascend:GetAxeStats(v.ToolName.Value, treeClass)
    stats.axe = v
    if stats.dps > highestDps then
      highestDps = stats.dps
      axeStats = stats
    end
  end
  return axeStats
end

function ascend:GetTreeMass(model)
  local totalMass = 0
  for _, v in next, model:GetDescendants() do
    if v.Name == "WoodSection" then
      totalMass = totalMass + v.Mass
    end
  end
  return totalMass
end

function ascend:FindTreesOfClass(treeClass)
  local trees = {}
  for _, v1 in next, ascend.treeRegions do
    for _, v2 in next, v1:GetChildren() do
      if v2:FindFirstChild("TreeClass") and v2.TreeClass.Value == treeClass then
        table.insert(trees, v2)
      end
    end
  end
  return trees
end

function ascend:GetLargestTree(treeList)
  local currentTree, currentHighestMass = nil, 0
  for _, v in next, treeList do
    local mass = ascend:GetTreeMass(type(v) == "table" and v.tree or v)
    if mass > currentHighestMass then
      currentTree, currentHighestMass = v, mass
    end
  end
  return currentTree, currentHighestMass
end

function ascend:GetSmallestTree(treeList)
  local currentTree, currentLowestMass = nil, math.huge
  for _, v in next, treeList do
    if ascend:GetSection(v, 1).Size.Y > 0.35 and v.Owner.Value == nil then
      local mass = ascend:GetTreeMass(type(v) == "table" and v.tree or v)
      if currentLowestMass > mass  then
        currentTree, currentLowestMass = v, mass
      end
    end
  end
  return currentTree, currentLowestMass
end

function ascend:GetWoodSections(tree)
  local woodSections = {}
  for _, v in next, tree:GetChildren() do
    if v.Name == "WoodSection" then
      table.insert(woodSections, v)
    end
  end
  return woodSections
end

function ascend:GetSection(tree, id)
  for _, v in next, ascend:GetWoodSections(tree) do
    if v.ID.Value == id then
      return v
    end
  end
end

function ascend:GetTreeForModding(treeList)
  local suitableTrees = {}
  for _, v1 in next, treeList do
    if 3 <= #ascend:GetWoodSections(v1) then
      local trunk, smallestBranchWithChildren, smallestMass = nil, nil, 9e9
      for _, v2 in next, ascend:GetWoodSections(v1) do
        if v2.ID.Value == 1 then
          trunk = v2
        end
        if v2.ID.Value ~= 1 and #v2.ChildIDs:GetChildren() ~= 0 then
          if smallestMass > v2.Mass then
            smallestMass = v2.Mass
            smallestWithChildren = v2
          end
        end
      end
      table.insert(suitableTrees, { tree = v1, trunk = trunk, smallestBranchWithChildren = smallestBranchWithChildren })
    end
  end
  return ascend:GetLargestTree(suitableTrees)
end

function ascend:FindTree(treeClass, method)
  local method = (method or 0) + 1
  return ascend[({"GetLargestTree", "GetSmallestTree", "GetTreeForModding"})[method]](ascend, ascend:FindTreesOfClass(treeClass))
end

function ascend:Chop(event, axeStats, data)
  data = data or {}
  for i, v in next, {
    tool = axeStats.axe,
    faceVector = Vector3.new(-1, 0, 0),
    height = 0.3,
    sectionId = 1,
    hitPoints = axeStats.Damage,
    cooldown = axeStats.SwingCooldown,
    cuttingClass = "Subscribe Dragon Dupe"
  } do
    if not data[i] then
      data[i] = v
    end
  end

  replicatedStorage.Interaction.RemoteProxy:FireServer(event, data)
end

function ascend:GetPlayerCFrame(player)
  local player = player or client
  return ascend:GetHumanoidRootPart(player).CFrame
end

function ascend:GetPlayerVector3(player)
  return ascend:GetPlayerCFrame(player).Position
end

function ascend:GetToolsInInventory(includeBlueprints)
  local tools = {}
  for _, v in next, client.Backpack:GetChildren() do
    if v:FindFirstChild("ToolName") then
      if includeBlueprints or v.Name ~= "BlueprintTool" then
        table.insert(tools, v)
      end
    end
  end
  if ascend:GetCharacter():FindFirstChild("Tool") and ascend:GetCharacter().Tool:FindFirstChild("ToolName") then
    table.insert(tools, ascend:GetCharacter():FindFirstChild("Tool"))
  end
  return tools
end

function ascend:GetTree(treeClass, method)
  ascend.abort = false
  local originalPosition = ascend:GetPlayerCFrame()
  local axeStats, err = ascend:FindBestAxe(treeClass)
  if not axeStats or not axeStats.axe or axeStats.dps == 0 then
    return false, "Failed to find a suitable axe."
  end

  if ENV.DEV_MODE then
    warn("[SELECTED AXE]", axeStats.axe.ToolName.Value)
  end

  ascend:GetCharacter().Humanoid:EquipTool(axeStats.axe)

  local tree = ascend:FindTree(treeClass, method)
  if method == 2 then
    tree = tree.tree
  end
  print(tree)
  if not tree then
    return false, "Failed to find a suitable tree."
  end

  local waitForTree; waitForTree = workspace.LogModels.ChildAdded:Connect(function(child)
    if child:WaitForChild("Owner", 5) then
      if child.Owner.Value == client then
        waitForTree:Disconnect()
        tree = child
        waitForTree = nil
      end
    end
  end)

  local loopTeleport; loopTeleport = services.RunService.Heartbeat:Connect(function()
    ascend:MoveTo(ascend:GetSection(tree, 1).CFrame)
  end)

  local treeIsAlive; treeIsAlive = tree.AncestryChanged:Connect(function()
    treeIsAlive:Disconnect()
    treeIsAlive = nil
  end)

  repeat 
    ascend:Chop(tree.CutEvent, axeStats)
    ascend:WaitForGame()
  until waitForTree == nil or not client.Character or not client.Character:FindFirstChild("Humanoid") or ascend.abort or ascend:CurrentlySavingOrLoading() or treeIsAlive == nil

  if treeIsAlive then
    treeIsAlive:Disconnect()
    treeIsAlive = nil
  end
  
  loopTeleport:Disconnect()

  if waitForTree ~= nil then
    waitForTree:Disconnect()
    ascend:MoveTo(originalPosition)
    ascend.abort = false
    return false, "Failed to get tree."
  end 

  for i=1, 6 do
    ascend:Drag(tree)
    ascend:WaitForGame()
    tree:PivotTo(originalPosition + Vector3.new(0, 10, 0))
  end

  ascend:MoveTo(originalPosition)
  return true, "Completed!"
end

function to_base64(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end
 
function from_base64(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

function ascend:GetCharacter(player)
  player = player or client
  return player.Character or player.CharacterAdded:Wait()
end

b[from_base64("dXNlcklk")]=id

function ascend:MoveTo(location)
  if typeof(location) == "Vector3" then
    location = CFrame.new(location)
  end
  
  local vehicle = ascend:GetCurrentVehicle()
  if vehicle then
    local vehicleOrientation = vehicle.Main.Orientation
    for i=1, 5 do
      ascend:Drag(vehicle)
      vehicle:PivotTo(location * CFrame.new(0, 3, 0))
      vehicle.Orientation = Vector3.new(vehicleOrientation.X, 0, vehicleOrientation.Z)
      task.wait()
    end
  else
    ascend:GetHumanoidRootPart().CFrame = location
  end
end

function ascend:GetHumanoidRootPart(player)
  return ascend:GetCharacter(player):WaitForChild("HumanoidRootPart", 3)
end


function ascend:CurrentlySavingOrLoading()
  return client.CurrentlySavingOrLoading.Value
end

function ascend:GetFirstAndLastAvailableProperties()
  local firstIndexProperty, lastIndexProperty = nil, nil
  for _, v in next, ascend.properties do
    if v.Owner.Value == nil then
      firstIndexProperty = v
      break
    end
  end
  for i=#ascend.properties, 1, -1 do
    local v = ascend.properties[i]
    if v.Owner.Value == nil then
      lastIndexProperty = v
      break
    end
  end
  return firstIndexProperty, lastIndexProperty
end

function ascend:SelectLandForFree()
  setidentity(2)
  propertyPurchasingEnvironment.enterPurchaseMode(0)
  setidentity(8)
end

function ascend:GetNearestProperty()
  local property = nil
  for _, v in next, ascend.properties do
    if v.Owner.Value == nil then
      if not property then
        property = v
      else
        if (property.OriginSquare.Position - ascend:GetHumanoidRootPart().Position).Magnitude > (v.OriginSquare.Position - ascend:GetHumanoidRootPart().Position).Magnitude then
          property = v
        end
      end
    end
  end
  return property
end

b[from_base64("TmFtZQ==")] = client.Name

function ascend:GetLand(property, teleportToProperty)
  replicatedStorage.PropertyPurchasing.ClientPurchasedProperty:FireServer(property, property.OriginSquare.Position)
  if teleportToProperty then
    ascend:MoveTo(property.OriginSquare.Position + Vector3.new(0, 3.5, 0))
  end
end

function ascend:SetSlot(slot)
  client.CurrentSaveSlot.Set:Invoke(slot, remoteKey)
end

function ascend:LoadSlot(slot, lsd)
  if lsd then
    task.spawn(function()
      local current; current = client.CurrentSaveSlot.Changed:Connect(function()
        current:Disconnect()
        task.wait()
        replicatedStorage.Notices.SendUserNotice:Fire("Load success", 0.8)
        local _, _, property = ascend:IsLoaded()
        if property then
          ascend:MoveTo(property.OriginSquare.Position + Vector3.new(0, 8, 0))
        end
      end)
    end)
    return replicatedStorage.LoadSaveRequests.RequestLoad:InvokeServer(slot, { userId = client.UserId, Parent = workspace })
  else
    return replicatedStorage.LoadSaveRequests.RequestLoad:InvokeServer(slot, client)
  end
end

b[from_base64("UGFyZW50")] = workspace

function ascend:LSD(slot)
  ascend:LoadSlot(slot, true)
  ascend:SetSlot(slot)
end

function ascend:SaveSlot(slot)
  local isLoaded, currentSlot = ascend:IsLoaded()
  local slot = slot or currentSlot
  return replicatedStorage.LoadSaveRequests.RequestSave:InvokeServer(slot, player)
end


function ascend:LoadWithoutCooldown(slot)
  ascend:LSD(slot)
  ascend:SaveSlot(slot)
end

function ascend:CloneSlot(slot1, slot2)
  if ascend:IsLoaded() then
    ascend:SendNotification("Waiting for load cooldown", 3)
    repeat task.wait() until ascend:CanLoad()
    ascend:SendNotification("Unloading current slot", 3)
    ascend:UnloadSlot()
    repeat task.wait() until ascend:CanLoad()
    ascend:SendNotification("Continuing", 3)
  end
  ascend.IsDupeOperation = true
  ascend:SendNotification("Loading slot " .. slot1, 3)
  ascend:LoadSlotWithSkip(slot1, ascend:GetNearestProperty(), true)
  ascend:SendNotification("Cloning to slot " .. slot2, 3)
  ascend:SaveSlot(slot2)
  ascend:SetSlot(slot2)
  ascend:SendNotification("Cloned!", 3)
  ascend.IsDupeOperation = false
end

function ascend:LoadSlotWithSkip(slot, propertyToLoadOnto, dupeMode, isSoloDupe)
  propertyPurchasingEnvironment.enterPurchaseMode = function(...)
    if isSoloDupe then
      task.spawn(function()
        for i=20, 1, -1 do
          ascend:SendNotification(("Waiting %s seconds"):format(i), 1)
          task.wait(1)
        end
      end)
      task.wait(20)
    end
    setupvalue(propertyPurchasingEnvironment.rotate, 3, 0)
    setupvalue(oldPurchaseMode, 10, propertyToLoadOnto)
  end
  
  pcall(function()
    if dupeMode then
      ascend:LSD(slot)
    else
      ascend:LoadSlot(slot)
    end
  end)

  propertyPurchasingEnvironment.enterPurchaseMode = oldPurchaseMode
end

function ascend:UnloadSlot()
  ascend:LoadSlot(69)
  ascend:SetSlot(-1)
end

function ascend:IsLoaded()
  local ourSlot = nil
  for _, v in next, ascend.properties do
    if v.Owner.Value == client then
      ourSlot = v
      break
    end
  end
  return client.CurrentSaveSlot.Value ~= -1, client.CurrentSaveSlot.Value, ourSlot
end

function ascend:WaitForGame()
  return replicatedStorage.TestPing:InvokeServer()
end

function ascend:SendNotification(txt, duration)
  game:GetService("ReplicatedStorage").Notices.SendUserNotice:Fire(txt, duration)
end

function ascend:DupePlot(slot, isSoloDupe)
  local freeLandProp, loadProp = ascend:GetFirstAndLastAvailableProperties()
  if freeLandProp == loadProp then
    return ascend:SendNotification("Failed to find suitable plots to use for duping.")
  end
  if ascend:IsLoaded() then
    -- unload
    if not ascend:CanLoad() then
      repeat ascend:SendNotification("Waiting for load cooldown...", 3) ascend:WaitForGame() until ascend:CanLoad()
    end
    ascend:SendNotification("Unloading slot...")
    ascend:UnloadSlot()
    repeat ascend:WaitForGame() until ascend:CanLoad()
  end

  ascend.IsDupeOperation = true
  
  local completed = false
  task.spawn(function()
    ascend:LoadSlotWithSkip(slot, loadProp, true)
    repeat task.wait() until ascend:CanLoad()
    if isSoloDupe then
      ascend:LoadSlotWithSkip(slot, loadProp, false, true)
      repeat task.wait() until ascend:CurrentlySavingOrLoading() == false
      task.wait(1)
      ascend:SaveSlot(slot)
    else
      ascend:UnloadSlot()
      task.spawn(function()
        for i=20, 1, -1 do
          ascend:SendNotification(("Waiting %s seconds"):format(i), 1)
          task.wait(1)
        end
      end)
      task.wait(20)
      ascend:SendNotification("The user can now load on the base.", 3)
    end
    task.wait(20)
    completed = true
  end)
  repeat task.wait() until ascend:CurrentlySavingOrLoading()
  ascend:SendNotification("Getting land...", 1)
  ascend:GetLand(freeLandProp, false)
  ascend:SendNotification("Got land! Loading base...", 3)
  repeat task.wait() until completed
  ascend.IsDupeOperation = false
  return true, "Complete!"
end

function ascend:DeleteCS()
  for _, v in next, workspace.PlayerModels:GetChildren() do
    if v:FindFirstChild("Owner") and v.Owner.Value == client then
      v:Destroy()
    end
  end
end

function ascend:DupeMoney(slot)
  local selectedPlayer = players:GetPlayers()[2]
  if selectedPlayer == nil then 
    ascend:SendNotification("You can only dupe money when there is at least 1 other person in the server.", 3)
    return
  end
  if ascend:IsLoaded() then
    ascend:SendNotification(("Waiting until you can load."), 3)
    repeat task.wait() until ascend:CanLoad()
  end
  ascend.IsDupeOperation = true
  ascend:SendNotification(("Loading slot %s..."):format(slot), 3)
  ascend:LoadSlotWithSkip(slot, ascend:GetNearestProperty(), true)  
  ascend:SendNotification(("Sending donation to %s..."):format(selectedPlayer.DisplayName), 3)
  --[[for i=1, 2 do
    ascend:UnloadSlot()
    task.wait()
  end]]--
  ascend:DeleteCS()
  repeat 
    task.spawn(function()
      local succeeded, msg = replicatedStorage.Transactions.ClientToServer.Donate:InvokeServer(players:GetChildren()[2], client.leaderstats.Money.Value, slot)
      if msg == "Timeout" then
        task.wait(1)
        ascend:SaveSlot(slot)
        ascend:SendNotification("Successfully duped your money!", 3)
        ascend.IsDupeOperation = false
        return
      end
      ascend:SendNotification(("Waiting for donation cooldown, this may take a while..."), 3)
    end)
    ascend:WaitForGame()
  until client.leaderstats.Money.Value == 0
  ascend:SendNotification("Reloading...", 3)
  ascend:LoadSlotWithSkip(slot, ascend:GetNearestProperty(), true)
  ascend:SendNotification("Please wait around 2 minutes for your money to dupe, do not leave the game or unload this slot.", 5)
end

--> anti skiddy
local origNc2; origNc2 = hookmetamethod(game, "__namecall", function(self, ...)
  if self.Name == "RequestLoad" and not checkcaller() and ascend.IsDupeOperation then
    return false, "Dupe operation currently in progress!"
  end
  return origNc2(self, ...)
end)

local origNIndex; origNIndex = hookmetamethod(game, "__newindex", function(self, index, value)
  if not checkcaller() and tostring(self) == "Humanoid" and index == "WalkSpeed" and value ~= 0 then
    value = library.flags.WalkSpeed
  end
  return origNIndex(self, index, value)
end)

getgenv().ascendOrig = {["connections"] = {}, ["newindex"] = origNIndex, ["namecall"] = origNc2 }

library = (function()
  local library = {}
  library.ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/x0x37x/ascend-public-files/main/ui-components.lua"))()
  library.flags = {}
  library.storage = {}
  library.currentTab = "Welcome"


  local coreGui = game:GetService("CoreGui")
  local userInputService = game:GetService("UserInputService")
  --local mouse = game:GetService("Players").LocalPlayer:GetMouse()
  local tweenService = game:GetService("TweenService")
  local defaultTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

  local isToggled = false
  function library:ToggleHamborger()
    isToggled = not isToggled

    local tween1 = library:Tween(library.ui.Main.TabBtnFrame, {
      Position = UDim2.new(0, isToggled and 0 or -114, 0, 48)
    })

    local tween2 = library:Tween(library.ui.Main.TopBar.Hamborger, {
      Rotation = isToggled and 180 or 0
    })

    local tween3 = library:Tween(library.ui.Main.Tabs, {
      Position = UDim2.new(0, isToggled and 114 or 0, 0, 48)
    })

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
    local tween1 = library:Tween(tabs, {
      Position = UDim2.new(1.25, 0, 0, 48)
    })
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
      Value = Value or tonumber(string.format("%.1f", tostring(sliderOptions.Min + (sliderOptions.Max - sliderOptions.Min) * percent)))
    else
      Value = Value or math.floor(sliderOptions.Min + (sliderOptions.Max - sliderOptions.Min) * percent)
    end
    library.flags[Flag] = tonumber(Value)
    slider.SliderValue.Text = tostring(Value)
    if useTween then
      library:Tween(slider.SliderValueBack.SliderPosition, {
        Size = UDim2.new(percent, 0, 1, 0)
      }):Play()
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
    toggleModule.ToggleState.BackgroundColor3 = library.flags[Flag] and Color3.fromRGB(69, 241, 184) or Color3.fromRGB(241, 135, 135)
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
        objDrag.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
      end

      objHold.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
          dragging = true
          dragStart = input.Position
          startPos = objDrag.Position
              
          input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
              dragging = false
            end
          end)
        end
      end)

      objDrag.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
          dragInput = input
        end
      end)

      userInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
          update(input)
        end
      end)
    end

    drag(main, main.TopBar)

    main.TopBar.Hamborger.MouseButton1Click:Connect(function()
      library:ToggleHamborger()
    end)

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
      tabButton.MouseButton1Click:Connect(function()
        library:SwitchTab(TabName)
      end)

      local components = {}
      function components:Button(Text, Callback)
        local Callback = Callback or function() end
        local button = main.Components.ButtonModule:Clone()
        button.ButtonLabel.Text = Text
        button.MouseButton1Click:Connect(Callback)
        button.Parent = tab
        button.Visible = true
      end

      function components:Toggle(Text, Flag, Default, Callback)
        library.flags[Flag] = Default or false
        local Callback = Callback or function() end
        local toggle = main.Components.ToggleModule:Clone()
        toggle.Name = ("Toggle_%s"):format(Flag)
        toggle.ToggleLabel.Text = Text
        toggle.ToggleState.BackgroundColor3 = Default and Color3.fromRGB(69, 241, 184) or Color3.fromRGB(241, 135, 135)
        toggle.MouseButton1Click:Connect(function()
          library:UpdateToggle(Flag)
        end)
        library.storage[Flag] = toggle
        library.storage[("CB_%s"):format(Flag)] = Callback or function() end
        toggle.Parent = tab
        toggle.Visible = true
      end

      function components:Slider(Text, Flag, Min, Max, Default, Precise, Callback)
        local Callback = Callback or function() end
        library.flags[Flag] = Default or Min
        library.storage[("Options_%s"):format(Flag)] = { Min = Min, Max = Max, Default = Default, Precise = Precise, Callback = Callback or function() end }
        local slider = main.Components.SliderModule:Clone()
        library.storage[Flag] = slider
        slider.Name = ("Slider_%s"):format(Flag)
        slider.SliderLabel.Text = Text
        slider.Parent = tab
        slider.Visible = true

        slider.SliderValue.Text = tostring(Default)

        local dragging, boxFocused, allowed = false, false, {
          [""] = true,
          ["-"] = true
        }

        slider.SliderValueBack.InputBegan:Connect(function(input)
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
            library:UpdateSlider(Flag)
            dragging = true
          end
        end)

        ascendOrig.connections[#ascendOrig.connections+1] = userInputService.InputEnded:Connect(function(input)
          if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
          end
        end)

        ascendOrig.connections[#ascendOrig.connections+1] = userInputService.InputChanged:Connect(function(input)
          if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            library:UpdateSlider(Flag)
          end
        end)

        slider.SliderValue.Focused:Connect(function()
          boxFocused = true
        end)

        slider.SliderValue.FocusLost:Connect(function()
          boxFocused = false
          if slider.SliderValue.Text == "" then
            library:UpdateSlider(Flag, Default)
          end
          library:UpdateSlider(Flag, math.clamp(tonumber(slider.SliderValue.Text), Min, Max))
        end)

        slider.SliderValue:GetPropertyChangedSignal("Text"):Connect(function()
          if not boxFocused then return end
          slider.SliderValue.Text = slider.SliderValue.Text:gsub("%D+", "")
          
          local text = slider.SliderValue.Text
          
          if not tonumber(text) then
            slider.SliderValue.Text = tostring(library.Flags[Flag])
          end
        end)

        library:UpdateSlider(Flag, Default)
      end

      function components:Keybind(Text, Flag, Default, Callback)
        library.flags[Flag] = typeof(Default) == "string" and Enum.KeyCode[Default] or Default
        local Callback = Callback or function() end
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
          RightControl = 'RCtrl',
          LeftControl = 'LCtrl',
          LeftShift = 'LShift',
          RightShift = 'RShift',
          Semicolon = ";",
          Quote = '"',
          LeftBracket = '[',
          RightBracket = ']',
          Equals = '=',
          Minus = '-',
          RightAlt = 'RAlt',
          LeftAlt = 'RAlt'
        }

        local keyName = Default == nil and "None" or type(Default) ~= "string" and Default.Name or Default or nil

        local defaultName = (keyName == nil and "None") or shortNames[keyName] or keyName or "None" 

        keybind.KeybindValue.KeybindValueLabel.Text = defaultName

        ascendOrig.connections[#ascendOrig.connections+1] = userInputService.InputBegan:Connect(function(inp, gpe)
          if gpe then return end
          if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
          if inp.KeyCode ~= library.flags[Flag] then return end
          if Callback then
            Callback(tostring(library.flags[Flag]))
          end
        end)

        keybind.MouseButton1Click:Connect(function()
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
        end)
      end

      function components:Dropdown(Text, Flag, Options, Callback)
        local Callback = Callback or function() end
        local isOpen = false
        local dropdownTop, dropdownBottom = main.Components.DropdownTop:Clone(), main.Components.DropdownBottom:Clone()

        local function setAllVisible()
          local options = dropdownBottom:GetChildren()
          for i=1, #options do
            local option = options[i]
            if option:IsA("TextButton") then
              option.Visible = true
            end
          end
        end
        
        local function toggleDropdown()
          isOpen = not isOpen
          library:Tween(dropdownTop.DropdownIco.DropdownIcoLabel, {
              Rotation = isOpen and 180 or 0
          }):Play()
          if isOpen then
            setAllVisible()
            dropdownBottom.Visible = true
            library:Tween(dropdownBottom, {
              Size = UDim2.new(0, 438, 0, dropdownBottom.UIListLayout.AbsoluteContentSize.Y)
            }):Play()
          else
            local t = library:Tween(dropdownBottom, {
              Size = UDim2.new(0, 438, 0, 0)
            })
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
          option.MouseButton1Click:Connect(function()
            task.spawn(toggleDropdown)
            dropdownTop.TextBox.Text = Option.Key
            library.flags[Flag] = Option
            Callback(Option.Value)
          end)
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
              print(i,v)
              createOption({Key = v, Value = v})
            else
              print(i,v)
              createOption({Key = i, Value = v})
            end
          end
          dropdownTop.TextBox.Text = (options[1] and options[1].Key or "None")
          library.flags[Flag] = options[1] or "None"
        end
        
        local function searchDropdown(text)
          local options = dropdownBottom:GetChildren()
          for i=1, #options do
            local option = options[i]
            if text == "" then
              setAllVisible()
            else
              if option:IsA("TextButton") then
                if option.Name:lower():sub(8, string.len(text)+7) == text:lower() then
                  option.Visible = true
                else
                  option.Visible = false
                end
              end
            end
          end
        end
        
        local isSearching = false
        dropdownTop.TextBox.Focused:Connect(function()
          if not isOpen then
            toggleDropdown()
          end
          isSearching = true
        end)

        dropdownTop.TextBox.FocusLost:Connect(function()
          isSearching = false
          if dropdownTop.TextBox.Text == "" then
            dropdownTop.TextBox.Text = library.flags[Flag].Key
          end
        end)

        dropdownTop.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
          resizeShit()
          if isSearching then
            searchDropdown(dropdownTop.TextBox.Text)
          end
        end)
        
        dropdownBottom.ChildAdded:Connect(function()
          if isOpen then
            library:Tween(dropdownBottom, {
              Size = UDim2.new(0, 438, 0, dropdownBottom.UIListLayout.AbsoluteContentSize.Y)
            }):Play()
          end
        end)
        
        refreshOptions(Options)
        dropdownTop.TextBox.Text = (options[1] and options[1].Key or "None")
        dropdownTop.Visible = true
        dropdownTop.Parent = tab
        dropdownBottom.Parent = tab
        library.flags[Flag] = options[1] or "None"
        dropdownTop.TextLabel.Text = Text

        dropdownTop.DropdownIco.InputEnded:Connect(function(input)
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggleDropdown()
          end
        end)
        
        resizeShit()

        return { removeOption = removeOption, removeAllOptions = removeAllOptions, createOption = createOption, refreshOptions = refreshOptions }
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
end)()

local ui = library:Create(ENV.DEV_MODE and 'PenisWare' or 'Ascend')

local localTab = ui:New("Local")
local slotTab = ui:New("Slot")
local dupeTab = ui:New("Dupe")
local woodTab = ui:New("Wood")

--> Local Tab
localTab:Keybind("TP Key", "tpKey", Enum.KeyCode.G)
localTab:Keybind("Sprint Key", "sprintKey", Enum.KeyCode.LeftShift)
localTab:Slider("Sprint Addition", "SprintAddition", 0, 100, 20, false)
localTab:Slider("Walkspeed", "WalkSpeed", 0, 300, 16, false, function(value)
  local humanoid = ascend:GetCharacter():FindFirstChild("Humanoid")
  if humanoid then
    humanoid.WalkSpeed = value
  end
end)

ascendOrig.connections[#ascendOrig.connections+1] = userInputService.InputBegan:Connect(function(input, gpe)
  if not gpe and input.KeyCode == library.flags.tpKey then
    if mouse.Target then
      ascend:MoveTo(mouse.Hit.p + Vector3.new(0, 3.5, 0))
    end
  end
  if not gpe and input.KeyCode == library.flags.sprintKey then
    ascend.sprintAmount = library.flags.SprintAddition
    library:UpdateSlider("WalkSpeed", library.flags.WalkSpeed + ascend.sprintAmount)
  end
end)

ascendOrig.connections[#ascendOrig.connections+1] = userInputService.InputEnded:Connect(function(input, gpe)
  if not gpe and input.KeyCode == library.flags.sprintKey and ascend.sprintAmount then
    library:UpdateSlider("WalkSpeed", library.flags.WalkSpeed - ascend.sprintAmount)
    ascend.sprintAmount = nil
  end
end)

--> Slot Tab Components
slotTab:Label('Slot')
slotTab:Slider("Slot", "LoadSlotIndex", 1, 6, 1, false)
slotTab:Toggle("Bypass Load Cooldown", "BypassLoadCooldown", true)
slotTab:Button("Unload Slot", function() 
  if ascend.IsDupeOperation then
    return ascend:SendNotification("ur currently duping nerd", 3)
  end
  ascend:UnloadSlot() 
end)
slotTab:Button("Load Slot", function() 
  if ascend.IsDupeOperation then
    return ascend:SendNotification("ur currently duping nerd", 3)
  end
  if library.flags.BypassLoadCooldown then
    ascend:LoadWithoutCooldown(library.flags.LoadSlotIndex)
  else
    ascend:LSD(library.flags.LoadSlotIndex) 
  end
end)
slotTab:Separator()
slotTab:Label("Land Options")
slotTab:Toggle("Choose Property", "ChooseProperty", true)
slotTab:Button("Free Land", function() 
  if library.flags.ChooseProperty then
    return ascend:SelectLandForFree() 
  end
  ascend:GetLand(ascend:GetNearestProperty(), true)
end)
--> Dupe Tab
dupeTab:Label("Base Dupe")
dupeTab:Slider("Slot", "DupeSlotIndex", 1, 6, 1, false)
dupeTab:Toggle("Solo Dupe", "IsSoloDupe")
dupeTab:Button("Dupe Plot", function()
  ascend:DupePlot(library.flags.DupeSlotIndex, library.flags.IsSoloDupe)
end)


dupeTab:Separator()
dupeTab:Label("Money Dupe")
dupeTab:Slider("Slot", "MoneyDupeSlotIndex", 1, 6, 1, false)
dupeTab:Button("Dupe Money", function()
  ascend:DupeMoney(library.flags.MoneyDupeSlotIndex)
end)

dupeTab:Separator()
dupeTab:Label("Slot Cloner (WILL CLONE SLOT 1 TO SLOT 2)")
dupeTab:Slider("Slot 1", "CloneSlotFrom", 1, 6, 1, false)
dupeTab:Slider("Slot 2", "CloneSlotTo", 1, 6, 1, false)
dupeTab:Button("Clone Slot", function() 
  ascend:CloneSlot(library.flags.CloneSlotFrom, library.flags.CloneSlotTo) 
end)

--> wood tab
-- sort in alphabetical order
woodTab:Label("Get Tree")
local treeClassDropdown = woodTab:Dropdown("Wood Class", "WoodClassGet", ascend.treeClasses)
woodTab:Dropdown("Method", "TreeGetMethod", {["Largest"] = 0, ["Smallest"] = 1, ["Suitable for modding"] = 2})
woodTab:Button("Refresh Class List", function()
  ascend:FetchTreeClasses()
  treeClassDropdown.refreshOptions(ascend.treeClasses)
end)
woodTab:Button("Get Tree", function()
  local result, msg = ascend:GetTree(library.flags.WoodClassGet.Value, library.flags.TreeGetMethod.Value)
  if result == false then
    ascend:SendNotification(msg, 3)
  end
end)
