local _f = 'zdev/client/vgui/zd_cl_menu_neuralnetwork.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

local player = player
local ents = ents
local util = util
local math = math
local string = string
local bit = bit
local gamemode = gamemode
local hook = hook
local Vector = Vector
local VectorRand = VectorRand
local Angle = Angle
local AngleRand = AngleRand
local Entity = Entity
local Color = Color
local FrameTime = FrameTime
local RealTime = RealTime
local CurTime = CurTime
local SysTime = SysTime
local EyePos = EyePos
local EyeAngles = EyeAngles
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber

local Lerp = Lerp
local type = type

--ZDEV = ZDEV or {}
-- print('')

local cli = LocalPlayer()
local SW, SH = ScrW(), ScrH()

--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV VGUI: Neural Network Real-Time Visualizer & Debug Panel
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]

--[[ Real-time neural network visualization system ]]
ZDEV.NeuralViz = ZDEV.NeuralViz or {}
local NeuralViz = ZDEV.NeuralViz

--[[ Visualization state ]]
NeuralViz.selectedNPC = nil
NeuralViz.updateRate = 0.1  --[[ Update every 100ms ]]
NeuralViz.lastUpdate = 0
NeuralViz.networkData = {}
NeuralViz.weightHistory = {}
NeuralViz.maxHistoryLength = 100

--[[ Colors for visualization ]]
NeuralViz.colors = {
    background = Color(20, 20, 30, 240),
    neuron_inactive = Color(60, 60, 80, 200),
    neuron_active = Color(100, 200, 255, 255),
    neuron_input = Color(100, 255, 100, 255),
    neuron_output = Color(255, 100, 100, 255),
    connection_weak = Color(80, 80, 80, 100),
    connection_strong = Color(255, 255, 255, 200),
    text = Color(255, 255, 255, 255),
    grid = Color(40, 40, 60, 100)
}

--[[ Network data collection from NPCs ]]
function NeuralViz.CollectNetworkData()
    if not IsValid(NeuralViz.selectedNPC) then return end
    
    local npc = NeuralViz.selectedNPC
    local data = {
        timestamp = CurTime(),
        architecture = 'Unknown',
        neurons = {},
        weights = {},
        activations = {},
        inputs = {},
        outputs = {},
        performance = {},
        memory_usage = 0
    }
    
    --[[ Detect network type and collect data ]]
    if npc.AdvancedBrain then
        data.architecture = 'Advanced (CNN+LSTM+Multi-Head)'
        data = NeuralViz.CollectAdvancedNetworkData(npc, data)
    elseif npc.Brain then
        if npc.Brain.input_nodes == 6 then
            data.architecture = 'Compressed (6-input optimized)'
        else
            data.architecture = 'Legacy (61-input full)'
        end
        data = NeuralViz.CollectSimpleNetworkData(npc, data)
    else
        data.architecture = 'No Brain Detected'
        return data
    end
    
    --[[ Store in history ]]
    table.insert(NeuralViz.weightHistory, data)
    if #NeuralViz.weightHistory > NeuralViz.maxHistoryLength then
        table.remove(NeuralViz.weightHistory, 1)
    end
    
    NeuralViz.networkData = data
    return data
end

--[[ Collect data from simple/compressed networks ]]
function NeuralViz.CollectSimpleNetworkData(npc, data)
    local brain = npc.Brain
    
    data.neurons = {
        input = brain.input_nodes or 0,
        hidden = brain.hidden_nodes or 0,
        output = brain.output_nodes or 0
    }
    
    --[[ Collect weights ]]
    if brain.weights_ih then
        data.weights.input_hidden = {}
        for i = 1, brain.hidden_nodes do
            data.weights.input_hidden[i] = {}
            for j = 1, brain.input_nodes do
                if brain.weights_ih[i] and brain.weights_ih[i][j] then
                    data.weights.input_hidden[i][j] = brain.weights_ih[i][j]
                end
            end
        end
    end
    
    if brain.weights_ho then
        data.weights.hidden_output = {}
        for i = 1, brain.output_nodes do
            data.weights.hidden_output[i] = {}
            for j = 1, brain.hidden_nodes do
                if brain.weights_ho[i] and brain.weights_ho[i][j] then
                    data.weights.hidden_output[i][j] = brain.weights_ho[i][j]
                end
            end
        end
    end
    
    --[[ Collect activations if available ]]
    if brain.lastInputs then
        data.inputs = brain.lastInputs
    end
    
    if brain.lastOutputs then
        data.outputs = brain.lastOutputs
    end
    
    --[[ Performance metrics ]]
    data.performance.learning_rate = brain.learning_rate or 0
    data.performance.momentum = brain.momentum or 0
    data.performance.total_reward = npc.TotalReward or 0
    
    --[[ Memory calculation ]]
    local totalWeights = (data.neurons.input * data.neurons.hidden) + (data.neurons.hidden * data.neurons.output)
    data.memory_usage = totalWeights * 4  --[[ 4 bytes per float ]]
    
    return data
end

--[[ Collect data from advanced networks ]]
function NeuralViz.CollectAdvancedNetworkData(npc, data)
    local brain = npc.AdvancedBrain
    
    data.neurons = {
        visual_input = brain.visualHeight * brain.visualWidth,
        vector_input = brain.vectorInputSize,
        conv1_filters = 32,
        conv2_filters = 64,
        lstm_units = brain.lstmUnits,
        fc_units = brain.fcUnits,
        action_output = brain.actionDim,
        value_output = 1
    }
    
    --[[ LSTM state ]]
    if brain.lstm_hidden then
        data.activations.lstm_hidden = {}
        for i = 1, brain.lstmUnits do
            data.activations.lstm_hidden[i] = brain.lstm_hidden[i] or 0
        end
    end
    
    if brain.lstm_cell then
        data.activations.lstm_cell = {}
        for i = 1, brain.lstmUnits do
            data.activations.lstm_cell[i] = brain.lstm_cell[i] or 0
        end
    end
    
    --[[ Performance metrics ]]
    data.performance.learning_rate = brain.learning_rate or 0
    data.performance.dropout_rate = brain.dropout_rate or 0
    data.performance.state_value = npc.CurrentStateValue or 0 -- Use the new NPC field
    data.current_behavior = npc.CurrentBehaviorName or "N/A" -- Use the new NPC field
    
    --[[ Memory calculation (rough estimate) ]]
    local convWeights = (32 * 3 * 3) + (64 * 3 * 3)  --[[ Conv layers ]]
    local lstmWeights = brain.lstmUnits * (brain.lstm_input_size + brain.lstmUnits) * 4  --[[ 4 gates ]]
    local fcWeights = brain.fcUnits * brain.lstmUnits
    local outputWeights = (brain.actionDim + 1) * brain.fcUnits
    
    data.memory_usage = (convWeights + lstmWeights + fcWeights + outputWeights) * 4
    
    return data
end

--[[ Save network state to JSON file ]]
function NeuralViz.SaveNetworkToFile(filename)
    if not NeuralViz.networkData or not IsValid(NeuralViz.selectedNPC) then
        chat.AddText(Color(255,100,100), '[ZDEV Neural Viz] No network data to save!')
        return false
    end
    
    local saveData = {
        timestamp = os.date('%Y-%m-%d %H:%M:%S'),
        npc_class = NeuralViz.selectedNPC:GetClass(),
        npc_model = NeuralViz.selectedNPC:GetModel(),
        architecture = NeuralViz.networkData.architecture,
        neurons = NeuralViz.networkData.neurons,
        weights = NeuralViz.networkData.weights,
        performance = NeuralViz.networkData.performance,
        memory_usage = NeuralViz.networkData.memory_usage,
        weight_history = NeuralViz.weightHistory
    }
    
    local jsonData = util.TableToJSON(saveData, true)
    if not jsonData then
        chat.AddText(Color(255,100,100), '[ZDEV Neural Viz] Failed to serialize network data!')
        return false
    end
    
    local filePath = 'zdev/neural_networks/' .. filename .. '.json'
    file.CreateDir('zdev/neural_networks')
    file.Write(filePath, jsonData)
    
    chat.AddText(Color(100,255,100), '[ZDEV Neural Viz] Network saved to: data/' .. filePath)
    return true
end

--[[ Load network state from JSON file ]]
function NeuralViz.LoadNetworkFromFile(filename)
    local filePath = 'zdev/neural_networks/' .. filename .. '.json'
    
    if not file.Exists(filePath, 'DATA') then
        chat.AddText(Color(255,100,100), '[ZDEV Neural Viz] File not found: ' .. filePath)
        return false
    end
    
    local jsonData = file.Read(filePath, 'DATA')
    if not jsonData then
        chat.AddText(Color(255,100,100), '[ZDEV Neural Viz] Failed to read file: ' .. filePath)
        return false
    end
    
    local loadedData = util.JSONToTable(jsonData)
    if not loadedData then
        chat.AddText(Color(255,100,100), '[ZDEV Neural Viz] Failed to parse JSON from: ' .. filePath)
        return false
    end
    
    NeuralViz.networkData = loadedData
    if loadedData.weight_history then
        NeuralViz.weightHistory = loadedData.weight_history
    end
    
    chat.AddText(Color(100,255,100), '[ZDEV Neural Viz] Network loaded from: ' .. filePath)
    chat.AddText(Color(255,255,100), '[ZDEV Neural Viz] Architecture: ' .. (loadedData.architecture or 'Unknown'))
    return true
end

--[[ Get list of saved neural network files ]]
function NeuralViz.GetSavedNetworks()
    local files, _ = file.Find('zdev/neural_networks--[[.json', 'DATA')
    local networks = {}
    
    for _, filename in ipairs(files or {}) do
        local name = string.gsub(filename, '.json', '')
        table.insert(networks, name)
    end
    
    return networks
end

--[[ Real-time update logic ]]
function NeuralViz.Update()
    if CurTime() - NeuralViz.lastUpdate < NeuralViz.updateRate then return end
    
    NeuralViz.lastUpdate = CurTime()
    
    if IsValid(NeuralViz.selectedNPC) then
        NeuralViz.CollectNetworkData()
    end
end

--[[ Hook for real-time updates ]]
hook.Add('Think', 'ZDEV_NeuralViz_Update', function()
    if NeuralViz.selectedNPC then
        NeuralViz.Update()
    end
end)

--[[ ZDEV_UID: ZDEV_FUNC_NN_TESTER | Path: ZDEV.VGUI.NeuralNetworkEditor ]]
function ZDEV.VGUI.NeuralNetworkEditor()
    if IsValid(ZDEV_NN_TESTER_FRAME) then
        ZDEV_NN_TESTER_FRAME:Close()
    end
    
    --[[ Main variables ]]
    local currentNetwork = nil
    local trainingData = {}
    local testData = {}
    local isTraining = false
    local trainingEpoch = 0
    local trainingLoss = 0
    local trainingAccuracy = 0
    local visualizationMode = 'network' --[[ 'network', 'loss', 'accuracy', 'weights', 'realtime' ]]
    local lossHistory = {}
    local accuracyHistory = {}
    local selectedNPCs = {}
    local realTimeMode = false
    
    --[[ Create main frame ]]
    local frame = vgui.Create('DFrame')
    frame:SetTitle('Neural Network Tester & Real-Time Visualizer')
    frame:SetSize(1400, 900)
    frame:Center()
    frame:MakePopup()
    frame:SetDeleteOnClose(true)
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:SetSizable(true)
    frame:SetMinWidth(1200)
    frame:SetMinHeight(700)
    ZDEV_NN_TESTER_FRAME = frame
    
    -- Create toolbar
    local toolbar = vgui.Create("DPanel", frame)
    toolbar:Dock(TOP)
    toolbar:SetHeight(50)
    toolbar:DockMargin(5, 5, 5, 5)
    toolbar.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 45))
    end
    
    -- Import/Export buttons
    local importBtn = vgui.Create("DButton", toolbar)
    importBtn:SetText("Import Network")
    importBtn:SetPos(10, 10)
    importBtn:SetSize(120, 30)
    importBtn.DoClick = function()
        ImportNetwork()
    end
    
    local exportBtn = vgui.Create("DButton", toolbar)
    exportBtn:SetText("Export Network")
    exportBtn:SetPos(140, 10)
    exportBtn:SetSize(120, 30)
    exportBtn.DoClick = function()
        ExportNetwork()
    end
    
    -- Training controls
    local startTrainBtn = vgui.Create("DButton", toolbar)
    startTrainBtn:SetText("Start Training")
    startTrainBtn:SetPos(280, 10)
    startTrainBtn:SetSize(100, 30)
    startTrainBtn.DoClick = function()
        ToggleTraining()
    end
    
    local stopTrainBtn = vgui.Create('DButton', toolbar)
    stopTrainBtn:SetText('Stop Training')
    stopTrainBtn:SetPos(390, 10)
    stopTrainBtn:SetSize(100, 30)
    
    --[[ Real-time visualization controls ]]
    local realtimeBtn = vgui.Create('DButton', toolbar)
    realtimeBtn:SetText('Real-Time Mode')
    realtimeBtn:SetPos(500, 10)
    realtimeBtn:SetSize(120, 30)
    realtimeBtn.DoClick = function()
        realTimeMode = not realTimeMode
        if realTimeMode then
            realtimeBtn:SetText('Real-Time: ON')
            realtimeBtn:SetColor(Color(100, 255, 100))
            visualizationMode = 'realtime'
        else
            realtimeBtn:SetText('Real-Time: OFF')
            realtimeBtn:SetColor(Color(255, 255, 255))
            NeuralViz.selectedNPC = nil
        end
        RefreshVisualization()
    end
    
    --[[ NPC Selection Dropdown ]]
    local npcSelector = vgui.Create('DComboBox', toolbar)
    npcSelector:SetPos(630, 10)
    npcSelector:SetSize(150, 30)
    npcSelector:SetValue('Select NPC...')
    npcSelector.OnSelect = function(_, _, value, data)
        NeuralViz.selectedNPC = data
        chat.AddText(Color(100,255,100), '[ZDEV Neural Viz] Selected NPC: ' .. (IsValid(data) and data:GetClass() or 'None'))
    end
    
    --[[ Save/Load controls ]]
    local saveBtn = vgui.Create('DButton', toolbar)
    saveBtn:SetText('Save Network')
    saveBtn:SetPos(790, 10)
    saveBtn:SetSize(100, 30)
    saveBtn.DoClick = function()
        Derma_StringRequest('Save Neural Network', 'Enter filename:', 'neural_snapshot_' .. os.date('%Y%m%d_%H%M%S'), 
            function(filename)
                NeuralViz.SaveNetworkToFile(filename)
            end
        )
    end
    
    local loadBtn = vgui.Create('DButton', toolbar)
    loadBtn:SetText('Load Network')
    loadBtn:SetPos(900, 10)
    loadBtn:SetSize(100, 30)
    loadBtn.DoClick = function()
        local networks = NeuralViz.GetSavedNetworks()
        if #networks == 0 then
            chat.AddText(Color(255,100,100), '[ZDEV Neural Viz] No saved networks found!')
            return
        end
        
        local menu = DermaMenu()
        for _, networkName in ipairs(networks) do
            menu:AddOption(networkName, function()
                NeuralViz.LoadNetworkFromFile(networkName)
                RefreshVisualization()
            end)
        end
        menu:Open()
    end
    stopTrainBtn:SetEnabled(false)
    stopTrainBtn.DoClick = function()
        StopTraining()
    end
    
    -- Test button
    local testBtn = vgui.Create("DButton", toolbar)
    testBtn:SetText("Test Network")
    testBtn:SetPos(500, 10)
    testBtn:SetSize(100, 30)
    testBtn.DoClick = function()
        TestNetwork()
    end
    
    -- Visualization mode selector
    local vizLabel = vgui.Create("DLabel", toolbar)
    vizLabel:SetText("View:")
    vizLabel:SetPos(620, 15)
    vizLabel:SetSize(40, 20)
    vizLabel:SetTextColor(Color(255, 255, 255))
    
    local vizCombo = vgui.Create("DComboBox", toolbar)
    vizCombo:SetPos(665, 10)
    vizCombo:SetSize(120, 30)
    vizCombo:AddChoice("Network Graph", "network")
    vizCombo:AddChoice("Loss Curve", "loss")
    vizCombo:AddChoice("Accuracy", "accuracy")
    vizCombo:AddChoice("Weight Heatmap", "weights")
    vizCombo:ChooseOption("Network Graph", 1)
    vizCombo.OnSelect = function(self, index, value, data)
        visualizationMode = data
        UpdateVisualization()
    end
    
    -- Create main content area with splitter
    local splitter = vgui.Create("DHorizontalDivider", frame)
    splitter:Dock(FILL)
    splitter:SetDividerWidth(8)
    
    -- Left panel for controls and data
    local leftPanel = vgui.Create("DPanel", splitter)
    leftPanel:SetWide(350)
    leftPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 35))
    end
    
    -- Right panel for visualization
    local rightPanel = vgui.Create("DPanel", splitter)
    rightPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(25, 25, 25))
    end
    
    splitter:SetLeft(leftPanel)
    splitter:SetRight(rightPanel)
    
    -- Network Configuration Panel
    local networkConfig = vgui.Create("DCollapsibleCategory", leftPanel)
    networkConfig:SetLabel("Network Configuration")
    networkConfig:Dock(TOP)
    networkConfig:SetExpanded(true)
    networkConfig:DockMargin(5, 5, 5, 5)
    
    local configList = vgui.Create("DPanelList", networkConfig)
    configList:SetSpacing(5)
    configList:EnableHorizontal(false)
    configList:EnableVerticalScrollbar(true)
    
    -- Layer configuration controls
    local layerPanel = vgui.Create("DPanel", configList)
    layerPanel:SetHeight(200)
    layerPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
    end
    
    local layerLabel = vgui.Create("DLabel", layerPanel)
    layerLabel:SetText("Network Architecture:")
    layerLabel:SetPos(10, 10)
    layerLabel:SetSize(200, 20)
    layerLabel:SetTextColor(Color(255, 255, 255))
    
    local inputSize = vgui.Create("DNumSlider", layerPanel)
    inputSize:SetText("Input Size")
    inputSize:SetPos(10, 35)
    inputSize:SetSize(200, 20)
    inputSize:SetMin(1)
    inputSize:SetMax(100)
    inputSize:SetValue(8)
    inputSize:SetDecimals(0)
    
    local hiddenLayers = vgui.Create("DNumSlider", layerPanel)
    hiddenLayers:SetText("Hidden Layers")
    hiddenLayers:SetPos(10, 65)
    hiddenLayers:SetSize(200, 20)
    hiddenLayers:SetMin(1)
    hiddenLayers:SetMax(10)
    hiddenLayers:SetValue(2)
    hiddenLayers:SetDecimals(0)
    
    local hiddenSize = vgui.Create("DNumSlider", layerPanel)
    hiddenSize:SetText("Hidden Size")
    hiddenSize:SetPos(10, 95)
    hiddenSize:SetSize(200, 20)
    hiddenSize:SetMin(1)
    hiddenSize:SetMax(100)
    hiddenSize:SetValue(12)
    hiddenSize:SetDecimals(0)
    
    local outputSize = vgui.Create("DNumSlider", layerPanel)
    outputSize:SetText("Output Size")
    outputSize:SetPos(10, 125)
    outputSize:SetSize(200, 20)
    outputSize:SetMin(1)
    outputSize:SetMax(50)
    outputSize:SetValue(6)
    outputSize:SetDecimals(0)
    
    local createNetworkBtn = vgui.Create("DButton", layerPanel)
    createNetworkBtn:SetText("Create Network")
    createNetworkBtn:SetPos(10, 155)
    createNetworkBtn:SetSize(120, 25)
    createNetworkBtn.DoClick = function()
        CreateNetwork()
    end
    
    configList:AddItem(layerPanel)
    
    -- Training Parameters Panel
    local trainingConfig = vgui.Create("DCollapsibleCategory", leftPanel)
    trainingConfig:SetLabel("Training Parameters")
    trainingConfig:Dock(TOP)
    trainingConfig:SetExpanded(true)
    trainingConfig:DockMargin(5, 5, 5, 5)
    
    local trainList = vgui.Create("DPanelList", trainingConfig)
    trainList:SetSpacing(5)
    trainList:EnableHorizontal(false)
    trainList:EnableVerticalScrollbar(true)
    
    local trainPanel = vgui.Create("DPanel", trainList)
    trainPanel:SetHeight(180)
    trainPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
    end
    
    local learningRate = vgui.Create("DNumSlider", trainPanel)
    learningRate:SetText("Learning Rate")
    learningRate:SetPos(10, 10)
    learningRate:SetSize(200, 20)
    learningRate:SetMin(0.001)
    learningRate:SetMax(1.0)
    learningRate:SetValue(0.1)
    learningRate:SetDecimals(3)
    
    local epochs = vgui.Create("DNumSlider", trainPanel)
    epochs:SetText("Max Epochs")
    epochs:SetPos(10, 40)
    epochs:SetSize(200, 20)
    epochs:SetMin(1)
    epochs:SetMax(10000)
    epochs:SetValue(1000)
    epochs:SetDecimals(0)
    
    local batchSize = vgui.Create("DNumSlider", trainPanel)
    batchSize:SetText("Batch Size")
    batchSize:SetPos(10, 70)
    batchSize:SetSize(200, 20)
    batchSize:SetMin(1)
    batchSize:SetMax(100)
    batchSize:SetValue(10)
    batchSize:SetDecimals(0)
    
    local generateDataBtn = vgui.Create("DButton", trainPanel)
    generateDataBtn:SetText("Generate Test Data")
    generateDataBtn:SetPos(10, 105)
    generateDataBtn:SetSize(150, 25)
    generateDataBtn.DoClick = function()
        GenerateTrainingData()
    end
    
    local loadDataBtn = vgui.Create("DButton", trainPanel)
    loadDataBtn:SetText("Load Data")
    loadDataBtn:SetPos(10, 135)
    loadDataBtn:SetSize(80, 25)
    loadDataBtn.DoClick = function()
        LoadTrainingData()
    end
    
    local exportDataBtn = vgui.Create("DButton", trainPanel)
    exportDataBtn:SetText("Export Data")
    exportDataBtn:SetPos(95, 135)
    exportDataBtn:SetSize(80, 25)
    exportDataBtn.DoClick = function()
        ExportTrainingData()
    end
    
    trainList:AddItem(trainPanel)
    
    -- Statistics Panel
    local statsPanel = vgui.Create("DCollapsibleCategory", leftPanel)
    statsPanel:SetLabel("Training Statistics")
    statsPanel:Dock(TOP)
    statsPanel:SetExpanded(true)
    statsPanel:DockMargin(5, 5, 5, 5)
    
    local statsList = vgui.Create("DPanelList", statsPanel)
    statsList:SetSpacing(5)
    statsList:EnableHorizontal(false)
    
    local statsDisplay = vgui.Create("DPanel", statsList)
    statsDisplay:SetHeight(120)
    statsDisplay.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
        
        -- Draw statistics
        draw.SimpleText("Epoch: " .. trainingEpoch, "DermaDefault", 10, 10, Color(255, 255, 255))
        draw.SimpleText("Loss: " .. string.format("%.4f", trainingLoss), "DermaDefault", 10, 30, Color(255, 255, 255))
        draw.SimpleText("Accuracy: " .. string.format("%.2f%%", trainingAccuracy * 100), "DermaDefault", 10, 50, Color(255, 255, 255))
        draw.SimpleText("Status: " .. (isTraining and "Training..." or "Idle"), "DermaDefault", 10, 70, isTraining and Color(0, 255, 0) or Color(255, 255, 255))
        
        if currentNetwork then
            draw.SimpleText("Network: " .. GetNetworkInfo(), "DermaDefault", 10, 90, Color(200, 200, 255))
        end
    end
    
    statsList:AddItem(statsDisplay)

    -- Real-Time AI State Display Panel
    local aiStatePanel = vgui.Create("DCollapsibleCategory", leftPanel)
    aiStatePanel:SetLabel("Real-Time AI State")
    aiStatePanel:Dock(TOP)
    aiStatePanel:SetExpanded(true)
    aiStatePanel:DockMargin(5, 5, 5, 5)

    local aiStateList = vgui.Create("DPanelList", aiStatePanel)
    aiStateList:SetSpacing(5)
    aiStateList:EnableHorizontal(false)
    aiStateList:EnableVerticalScrollbar(true)

    local aiStateDisplay = vgui.Create("DPanel", aiStateList)
    aiStateDisplay:SetHeight(200)
    aiStateDisplay.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))

        if not IsValid(NeuralViz.selectedNPC) then
            draw.SimpleText("No NPC selected for real-time data.", "DermaDefault", 10, 10, Color(200, 200, 200))
            return
        end

        local data = NeuralViz.networkData
        local npc = NeuralViz.selectedNPC

        local yOffset = 10
        draw.SimpleText("NPC: " .. npc:GetClass() .. " [" .. npc:EntIndex() .. "]", "DermaDefaultBold", 10, yOffset, Color(255, 255, 255))
        yOffset = yOffset + 20
        draw.SimpleText("Health: " .. npc:Health() .. "/" .. npc:GetMaxHealth(), "DermaDefault", 10, yOffset, Color(100, 255, 100))
        yOffset = yOffset + 20
        draw.SimpleText("Current Behavior: " .. (data.current_behavior or "N/A"), "DermaDefault", 10, yOffset, Color(255, 255, 0))
        yOffset = yOffset + 20
        draw.SimpleText("Total Reward: " .. string.format("%.2f", data.performance.total_reward or 0), "DermaDefault", 10, yOffset, Color(0, 255, 255))
        yOffset = yOffset + 20
        draw.SimpleText("State Value: " .. string.format("%.3f", data.performance.state_value or 0), "DermaDefault", 10, yOffset, Color(255, 150, 100))
        yOffset = yOffset + 20
        draw.SimpleText("Memory Usage: " .. string.format("%.1f KB", (data.memory_usage or 0) / 1024), "DermaDefault", 10, yOffset, Color(200, 200, 200))
    end
    aiStateList:AddItem(aiStateDisplay)
    
    -- Visualization Canvas
    local canvas = vgui.Create("DPanel", rightPanel)
    canvas:Dock(FILL)
    canvas:DockMargin(10, 10, 10, 10)
    canvas.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20))
        
        if visualizationMode == "network" then
            DrawNetworkVisualization(self, w, h)
        elseif visualizationMode == "loss" then
            DrawLossChart(self, w, h)
        elseif visualizationMode == "accuracy" then
            DrawAccuracyChart(self, w, h)
        elseif visualizationMode == "weights" then
            DrawWeightHeatmap(self, w, h)
        elseif visualizationMode == "realtime" then
            DrawRealTimeNetworkVisualization(self, w, h)
        end
    end
    
    -- Function implementations
    function CreateNetwork()
        local inputs = math.floor(inputSize:GetValue())
        local hidden = math.floor(hiddenLayers:GetValue())
        local hiddenNodes = math.floor(hiddenSize:GetValue())
        local outputs = math.floor(outputSize:GetValue())
        
        currentNetwork = {
            layers = {},
            weights = {},
            biases = {},
            activations = {}
        }
        
        -- Create layer structure
        table.insert(currentNetwork.layers, {type = "input", size = inputs, nodes = {}})
        
        for i = 1, hidden do
            table.insert(currentNetwork.layers, {type = "hidden", size = hiddenNodes, nodes = {}})
        end
        
        table.insert(currentNetwork.layers, {type = "output", size = outputs, nodes = {}})
        
        -- Initialize weights and biases
        InitializeNetworkWeights()
        
        notification.AddLegacy("Network created: " .. inputs .. "-" .. hiddenNodes .. "-" .. outputs, NOTIFY_GENERIC, 3)
    end
    
    function InitializeNetworkWeights()
        if not currentNetwork then return end
        
        currentNetwork.weights = {}
        currentNetwork.biases = {}
        
        for i = 1, #currentNetwork.layers - 1 do
            local layer1 = currentNetwork.layers[i]
            local layer2 = currentNetwork.layers[i + 1]
            
            currentNetwork.weights[i] = {}
            currentNetwork.biases[i] = {}
            
            for j = 1, layer2.size do
                currentNetwork.weights[i][j] = {}
                for k = 1, layer1.size do
                    currentNetwork.weights[i][j][k] = (math.random() - 0.5) * 2
                end
                currentNetwork.biases[i][j] = (math.random() - 0.5) * 2
            end
        end
    end
    
    function GenerateTrainingData()
        trainingData = {}
        testData = {}
        
        local inputs = currentNetwork and currentNetwork.layers[1].size or 8
        local outputs = currentNetwork and currentNetwork.layers[#currentNetwork.layers].size or 6
        
        -- Generate XOR-like training data
        for i = 1, 1000 do
            local input = {}
            for j = 1, inputs do
                table.insert(input, math.random())
            end
            
            local target = {}
            for j = 1, outputs do
                -- Simple function: output = sum of inputs > threshold
                local sum = 0
                for k = 1, #input do
                    sum = sum + input[k]
                end
                table.insert(target, sum > (#input / 2) and 1 or 0)
            end
            
            table.insert(trainingData, {input = input, target = target})
        end
        
        notification.AddLegacy("Generated " .. #trainingData .. " training samples", NOTIFY_GENERIC, 3)
    end
    
    function ToggleTraining()
        if not currentNetwork then
            notification.AddLegacy("Please create a network first", NOTIFY_ERROR, 3)
            return
        end
        
        if #trainingData == 0 then
            notification.AddLegacy("Please generate training data first", NOTIFY_ERROR, 3)
            return
        end
        
        isTraining = true
        startTrainBtn:SetEnabled(false)
        stopTrainBtn:SetEnabled(true)
        
        TrainingLoop()
    end
    
    function StopTraining()
        isTraining = false
        startTrainBtn:SetEnabled(true)
        stopTrainBtn:SetEnabled(false)
    end
    
    function TrainingLoop()
        if not isTraining or not currentNetwork then return end
        
        -- Simple training step
        local lr = learningRate:GetValue()
        local bSize = math.floor(batchSize:GetValue())
        
        -- Forward pass on batch
        local totalLoss = 0
        local correct = 0
        
        for i = 1, math.min(bSize, #trainingData) do
            local sample = trainingData[math.random(1, #trainingData)]
            local output = ForwardPass(sample.input)
            local loss = CalculateLoss(output, sample.target)
            totalLoss = totalLoss + loss
            
            if IsCorrectPrediction(output, sample.target) then
                correct = correct + 1
            end
            
            -- Simple backpropagation (placeholder)
            BackwardPass(sample.input, sample.target, output, lr)
        end
        
        trainingLoss = totalLoss / bSize
        trainingAccuracy = correct / bSize
        trainingEpoch = trainingEpoch + 1
        
        -- Store history for charts
        table.insert(lossHistory, trainingLoss)
        table.insert(accuracyHistory, trainingAccuracy)
        
        -- Limit history size
        if #lossHistory > 1000 then
            table.remove(lossHistory, 1)
            table.remove(accuracyHistory, 1)
        end
        
        -- Continue training
        if trainingEpoch < epochs:GetValue() then
            timer.Simple(0.01, TrainingLoop)
        else
            StopTraining()
            notification.AddLegacy("Training completed!", NOTIFY_GENERIC, 3)
        end
    end
    
    function ForwardPass(input)
        if not currentNetwork then return {} end
        
        local activations = {input}
        
        for i = 1, #currentNetwork.layers - 1 do
            local newActivation = {}
            local weights = currentNetwork.weights[i]
            local biases = currentNetwork.biases[i]
            
            for j = 1, #weights do
                local sum = biases[j]
                for k = 1, #activations[i] do
                    sum = sum + activations[i][k] * weights[j][k]
                end
                table.insert(newActivation, math.tanh(sum)) -- Activation function
            end
            
            table.insert(activations, newActivation)
        end
        
        currentNetwork.activations = activations
        return activations[#activations]
    end
    
    function CalculateLoss(output, target)
        local loss = 0
        for i = 1, #output do
            local diff = output[i] - target[i]
            loss = loss + diff * diff
        end
        return loss / #output
    end
    
    function IsCorrectPrediction(output, target)
        for i = 1, #output do
            if math.abs(output[i] - target[i]) > 0.5 then
                return false
            end
        end
        return true
    end
    
    function BackwardPass(input, target, output, learningRate)
        -- Simplified backpropagation
        if not currentNetwork.weights then return end
        
        for i = #currentNetwork.weights, 1, -1 do
            local weights = currentNetwork.weights[i]
            for j = 1, #weights do
                for k = 1, #weights[j] do
                    local gradient = (output[j] - target[j]) * 0.01 -- Simplified
                    currentNetwork.weights[i][j][k] = currentNetwork.weights[i][j][k] - learningRate * gradient
                end
            end
        end
    end
    
    function DrawNetworkVisualization(panel, w, h)
        --[[ Real-time mode: visualize live NPC neural networks ]]
        if realTimeMode and visualizationMode == 'realtime' then
            DrawRealTimeNetworkVisualization(panel, w, h)
            return
        end
        
        --[[ Standard mode: visualize test networks ]]
        if not currentNetwork then
            draw.SimpleText('No network loaded', 'DermaDefaultBold', w/2, h/2, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText('Click "Create Network" to start or enable Real-Time Mode', 'DermaDefault', w/2, h/2 + 20, Color(100, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        
        local layers = currentNetwork.layers
        if #layers == 0 then return end
        
        local layerSpacing = (w - 100) / math.max(1, #layers - 1)
        local nodeRadius = 8
        
        --[[ Draw connections ]]
        surface.SetDrawColor(100, 100, 255, 100)
        for i = 1, #layers - 1 do
            local layer1 = layers[i]
            local layer2 = layers[i + 1]
            local x1 = 50 + (i - 1) * layerSpacing
            local x2 = 50 + i * layerSpacing
            
            for j = 1, layer1.size do
                local y1 = 50 + (j - 1) * (h - 100) / math.max(1, layer1.size - 1)
                for k = 1, layer2.size do
                    local y2 = 50 + (k - 1) * (h - 100) / math.max(1, layer2.size - 1)
                    
                    --[[ Color connection by weight ]]
                    local weight = currentNetwork.weights[i] and currentNetwork.weights[i][k] and currentNetwork.weights[i][k][j] or 0
                    local intensity = math.Clamp(math.abs(weight) * 100, 0, 255)
                    local color = weight > 0 and Color(0, intensity, 0, 100) or Color(intensity, 0, 0, 100)
                    surface.SetDrawColor(color.r, color.g, color.b, color.a)
                    surface.DrawLine(x1, y1, x2, y2)
                end
            end
        end
        
        --[[ Draw nodes ]]
        for i, layer in ipairs(layers) do
            local x = 50 + (i - 1) * layerSpacing
            local color = Color(100, 150, 255)
            if layer.type == 'input' then color = Color(100, 255, 100)
            elseif layer.type == 'output' then color = Color(255, 100, 100) end
            
            for j = 1, layer.size do
                local y = 50 + (j - 1) * (h - 100) / math.max(1, layer.size - 1)
                
                surface.SetDrawColor(color.r, color.g, color.b, 200)
                surface.DrawOutlinedCircle(x, y, nodeRadius)
                
                --[[ Show activation if available ]]
                if currentNetwork.activations and currentNetwork.activations[i] and currentNetwork.activations[i][j] then
                    local activation = currentNetwork.activations[i][j]
                    local intensity = math.Clamp(math.abs(activation) * 255, 0, 255)
                    local actColor = activation > 0 and Color(intensity, intensity, 0, 150) or Color(intensity, 0, intensity, 150)
                    surface.SetDrawColor(actColor.r, actColor.g, actColor.b, actColor.a)
                    surface.DrawFilledCircle(x, y, nodeRadius - 2)
                end
                
                -- Draw node center
                surface.SetDrawColor(255, 255, 255, 100)
                surface.DrawFilledCircle(x, y, 2)
            end
        end
        
        -- Draw labels
        draw.SimpleText("Input", "DermaDefault", 50, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        if #layers > 2 then
            draw.SimpleText("Hidden", "DermaDefault", 50 + layerSpacing, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        end
        draw.SimpleText("Output", "DermaDefault", 50 + (#layers - 1) * layerSpacing, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end
    
    function DrawLossChart(panel, w, h)
        if #lossHistory == 0 then
            draw.SimpleText("No training data yet", "DermaDefaultBold", w/2, h/2, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        
        -- Draw chart background
        draw.RoundedBox(4, 50, 50, w-100, h-100, Color(40, 40, 40))
        
        -- Find min/max for scaling
        local minLoss, maxLoss = math.huge, -math.huge
        for _, loss in ipairs(lossHistory) do
            minLoss = math.min(minLoss, loss)
            maxLoss = math.max(maxLoss, loss)
        end
        
        if maxLoss == minLoss then maxLoss = minLoss + 1 end
        
        -- Draw loss curve
        surface.SetDrawColor(255, 100, 100, 255)
        for i = 2, #lossHistory do
            local x1 = 50 + (i-2) * (w-100) / math.max(1, #lossHistory-1)
            local y1 = 50 + (h-100) - (lossHistory[i-1] - minLoss) / (maxLoss - minLoss) * (h-100)
            local x2 = 50 + (i-1) * (w-100) / math.max(1, #lossHistory-1)
            local y2 = 50 + (h-100) - (lossHistory[i] - minLoss) / (maxLoss - minLoss) * (h-100)
            surface.DrawLine(x1, y1, x2, y2)
        end
        
        -- Draw labels
        draw.SimpleText("Loss: " .. string.format("%.4f", trainingLoss), "DermaDefaultBold", w/2, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("Min: %.4f", minLoss), "DermaDefault", 60, h-40, Color(200, 200, 200))
        draw.SimpleText(string.format("Max: %.4f", maxLoss), "DermaDefault", 60, 60, Color(200, 200, 200))
    end
    
    function DrawAccuracyChart(panel, w, h)
        if #accuracyHistory == 0 then
            draw.SimpleText("No training data yet", "DermaDefaultBold", w/2, h/2, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        
        -- Draw chart background
        draw.RoundedBox(4, 50, 50, w-100, h-100, Color(40, 40, 40))
        
        -- Draw accuracy curve (0-1 range)
        surface.SetDrawColor(100, 255, 100, 255)
        for i = 2, #accuracyHistory do
            local x1 = 50 + (i-2) * (w-100) / math.max(1, #accuracyHistory-1)
            local y1 = 50 + (h-100) - accuracyHistory[i-1] * (h-100)
            local x2 = 50 + (i-1) * (w-100) / math.max(1, #accuracyHistory-1)
            local y2 = 50 + (h-100) - accuracyHistory[i] * (h-100)
            surface.DrawLine(x1, y1, x2, y2)
        end
        
        -- Draw reference lines
        surface.SetDrawColor(100, 100, 100, 100)
        -- 50% line
        local y50 = 50 + (h-100) * 0.5
        surface.DrawLine(50, y50, w-50, y50)
        
        -- Draw labels
        draw.SimpleText("Accuracy: " .. string.format("%.2f%%", trainingAccuracy * 100), "DermaDefaultBold", w/2, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        draw.SimpleText("0%", "DermaDefault", 60, h-40, Color(200, 200, 200))
        draw.SimpleText("100%", "DermaDefault", 60, 60, Color(200, 200, 200))
        draw.SimpleText("50%", "DermaDefault", w-80, y50-10, Color(150, 150, 150))
    end
    
    function DrawWeightHeatmap(panel, w, h)
        if not currentNetwork or not currentNetwork.weights then
            draw.SimpleText("No network weights to display", "DermaDefaultBold", w/2, h/2, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        
        local weights = currentNetwork.weights
        local layerCount = #weights
        if layerCount == 0 then return end
        
        local cellSize = math.min((w-100) / 20, (h-100) / 20)
        local startX = 50
        local startY = 50
        
        -- Draw weight matrices for each layer
        local offsetX = 0
        for layerIdx = 1, layerCount do
            local layerWeights = weights[layerIdx]
            if layerWeights then
                draw.SimpleText("Layer " .. layerIdx, "DermaDefault", startX + offsetX, startY - 20, Color(255, 255, 255))
                
                for i = 1, math.min(10, #layerWeights) do
                    for j = 1, math.min(10, #layerWeights[i]) do
                        local weight = layerWeights[i][j]
                        local intensity = math.Clamp(math.abs(weight) * 255, 0, 255)
                        local color = weight > 0 and Color(0, intensity, 0) or Color(intensity, 0, 0)
                        
                        draw.RoundedBox(0, 
                            startX + offsetX + (j-1) * cellSize, 
                            startY + (i-1) * cellSize, 
                            cellSize-1, cellSize-1, 
                            color)
                    end
                end
                
                offsetX = offsetX + 11 * cellSize + 20
                if offsetX > w - 200 then break end
            end
        end
    end
    
    function ImportNetwork()
        -- Create file browser dialog
        local importFrame = vgui.Create("DFrame")
        importFrame:SetTitle("Import Neural Network")
        importFrame:SetSize(600, 500)
        importFrame:Center()
        importFrame:MakePopup()
        importFrame:SetDeleteOnClose(true)
        
        -- File list panel
        local fileList = vgui.Create("DListView", importFrame)
        fileList:Dock(FILL)
        fileList:DockMargin(10, 10, 10, 80)
        fileList:SetMultiSelect(false)
        fileList:AddColumn("Filename")
        fileList:AddColumn("Size")
        fileList:AddColumn("Modified")
        
        -- Populate with .json files from data folder
        local files, folders = file.Find("*.json", "DATA")
        for _, filename in ipairs(files) do
            local size = file.Size(filename, "DATA")
            local time = file.Time(filename, "DATA")
            local timeStr = os.date("%Y-%m-%d %H:%M", time)
            local line = fileList:AddLine(filename, string.NiceSize(size or 0), timeStr)
            line.filename = filename
        end
        
        -- Control buttons
        local buttonPanel = vgui.Create("DPanel", importFrame)
        buttonPanel:Dock(BOTTOM)
        buttonPanel:SetHeight(70)
        buttonPanel.Paint = function() end
        
        local importBtn = vgui.Create("DButton", buttonPanel)
        importBtn:SetText("Import Selected")
        importBtn:SetPos(10, 10)
        importBtn:SetSize(120, 30)
        importBtn.DoClick = function()
            local selected = fileList:GetSelectedLine()
            if selected then
                local filename = selected.filename
                LoadNetworkFromFile(filename)
                importFrame:Close()
            else
                notification.AddLegacy("Please select a file to import", NOTIFY_ERROR, 3)
            end
        end
        
        local pasteBtn = vgui.Create("DButton", buttonPanel)
        pasteBtn:SetText("Paste JSON")
        pasteBtn:SetPos(140, 10)
        pasteBtn:SetSize(100, 30)
        pasteBtn.DoClick = function()
            Derma_StringRequest("Import from JSON", "Paste network JSON data:", "", function(jsonText)
                LoadNetworkFromJSON(jsonText)
                importFrame:Close()
            end)
        end
        
        local refreshBtn = vgui.Create("DButton", buttonPanel)
        refreshBtn:SetText("Refresh")
        refreshBtn:SetPos(250, 10)
        refreshBtn:SetSize(80, 30)
        refreshBtn.DoClick = function()
            fileList:Clear()
            local files, folders = file.Find("*.json", "DATA")
            for _, filename in ipairs(files) do
                local size = file.Size(filename, "DATA")
                local time = file.Time(filename, "DATA")
                local timeStr = os.date("%Y-%m-%d %H:%M", time)
                local line = fileList:AddLine(filename, string.NiceSize(size or 0), timeStr)
                line.filename = filename
            end
        end
        
        local cancelBtn = vgui.Create("DButton", buttonPanel)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetPos(340, 10)
        cancelBtn:SetSize(80, 30)
        cancelBtn.DoClick = function()
            importFrame:Close()
        end
        
        -- Double-click to import
        fileList.OnRowRightClick = function(self, line)
            local filename = line.filename
            LoadNetworkFromFile(filename)
            importFrame:Close()
        end
    end
    
    -- Helper function to load network from file
    function LoadNetworkFromFile(filename)
        local content = file.Read(filename, "DATA")
        if content then
            LoadNetworkFromJSON(content, filename)
        else
            notification.AddLegacy("Could not read file: " .. filename, NOTIFY_ERROR, 3)
        end
    end
    
    -- Helper function to load network from JSON string
    function LoadNetworkFromJSON(jsonString, filename)
        local success, network = pcall(util.JSONToTable, jsonString)
        if success and network then
            -- Validate network structure
            if ValidateNetworkStructure(network) then
                currentNetwork = network
                -- Reset training variables
                trainingEpoch = 0
                trainingLoss = 0
                trainingAccuracy = 0
                lossHistory = {}
                accuracyHistory = {}
                
                local source = filename and ("from " .. filename) or "from JSON"
                notification.AddLegacy("Network imported successfully " .. source, NOTIFY_GENERIC, 3)
                
                -- Update UI controls to match imported network
                if currentNetwork.layers then
                    inputSize:SetValue(currentNetwork.layers[1] and currentNetwork.layers[1].size or 8)
                    outputSize:SetValue(currentNetwork.layers[#currentNetwork.layers] and currentNetwork.layers[#currentNetwork.layers].size or 6)
                    hiddenLayers:SetValue(math.max(1, #currentNetwork.layers - 2))
                    if #currentNetwork.layers > 2 then
                        hiddenSize:SetValue(currentNetwork.layers[2].size or 12)
                    end
                end
                
                UpdateVisualization()
            else
                notification.AddLegacy("Invalid network structure", NOTIFY_ERROR, 3)
            end
        else
            notification.AddLegacy("Invalid JSON format", NOTIFY_ERROR, 3)
        end
    end
    
    -- Validate network structure
    function ValidateNetworkStructure(network)
        if not network or type(network) ~= "table" then return false end
        if not network.layers or type(network.layers) ~= "table" or #network.layers < 2 then return false end
        
        -- Check each layer has required fields
        for i, layer in ipairs(network.layers) do
            if not layer.type or not layer.size or layer.size < 1 then return false end
            if not (layer.type == "input" or layer.type == "hidden" or layer.type == "output") then return false end
        end
        
        -- First layer should be input, last should be output
        if network.layers[1].type ~= "input" or network.layers[#network.layers].type ~= "output" then
            return false
        end
        
        return true
    end
    
    function ExportNetwork()
        if not currentNetwork then
            notification.AddLegacy("No network to export", NOTIFY_ERROR, 3)
            return
        end
        
        -- Create export dialog
        local exportFrame = vgui.Create("DFrame")
        exportFrame:SetTitle("Export Neural Network")
        exportFrame:SetSize(500, 400)
        exportFrame:Center()
        exportFrame:MakePopup()
        exportFrame:SetDeleteOnClose(true)
        
        -- Main panel
        local mainPanel = vgui.Create("DPanel", exportFrame)
        mainPanel:Dock(FILL)
        mainPanel:DockMargin(10, 10, 10, 10)
        mainPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
        end
        
        -- Filename input
        local filenameLabel = vgui.Create("DLabel", mainPanel)
        filenameLabel:SetText("Filename:")
        filenameLabel:SetPos(10, 15)
        filenameLabel:SetSize(100, 20)
        filenameLabel:SetTextColor(Color(255, 255, 255))
        
        local filenameEntry = vgui.Create("DTextEntry", mainPanel)
        filenameEntry:SetPos(10, 40)
        filenameEntry:SetSize(460, 25)
        filenameEntry:SetValue("neural_network_" .. os.date("%Y%m%d_%H%M%S") .. ".json")
        
        -- Network info display
        local infoLabel = vgui.Create("DLabel", mainPanel)
        infoLabel:SetText("Network Information:")
        infoLabel:SetPos(10, 80)
        infoLabel:SetSize(200, 20)
        infoLabel:SetTextColor(Color(255, 255, 255))
        
        local infoPanel = vgui.Create("DPanel", mainPanel)
        infoPanel:SetPos(10, 105)
        infoPanel:SetSize(460, 120)
        infoPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            local y = 10
            local info = GetNetworkInfo()
            draw.SimpleText("Architecture: " .. info, "DermaDefault", 10, y, Color(255, 255, 255))
            y = y + 20
            
            local paramCount = CalculateParameterCount()
            draw.SimpleText("Parameters: " .. string.Comma(paramCount), "DermaDefault", 10, y, Color(255, 255, 255))
            y = y + 20
            
            draw.SimpleText("Training Epochs: " .. trainingEpoch, "DermaDefault", 10, y, Color(255, 255, 255))
            y = y + 20
            
            if trainingLoss > 0 then
                draw.SimpleText("Final Loss: " .. string.format("%.4f", trainingLoss), "DermaDefault", 10, y, Color(255, 255, 255))
                y = y + 20
                draw.SimpleText("Final Accuracy: " .. string.format("%.2f%%", trainingAccuracy * 100), "DermaDefault", 10, y, Color(255, 255, 255))
            end
        end
        
        -- Export options
        local optionsLabel = vgui.Create("DLabel", mainPanel)
        optionsLabel:SetText("Export Options:")
        optionsLabel:SetPos(10, 240)
        optionsLabel:SetSize(200, 20)
        optionsLabel:SetTextColor(Color(255, 255, 255))
        
        local includeTrainingData = vgui.Create("DCheckBoxLabel", mainPanel)
        includeTrainingData:SetText("Include training data")
        includeTrainingData:SetPos(10, 265)
        includeTrainingData:SetValue(false)
        includeTrainingData:SetTextColor(Color(255, 255, 255))
        
        local includeHistory = vgui.Create("DCheckBoxLabel", mainPanel)
        includeHistory:SetText("Include training history")
        includeHistory:SetPos(200, 265)
        includeHistory:SetValue(true)
        includeHistory:SetTextColor(Color(255, 255, 255))
        
        local prettyJson = vgui.Create("DCheckBoxLabel", mainPanel)
        prettyJson:SetText("Pretty print JSON")
        prettyJson:SetPos(10, 290)
        prettyJson:SetValue(true)
        prettyJson:SetTextColor(Color(255, 255, 255))
        
        -- Action buttons
        local buttonPanel = vgui.Create("DPanel", mainPanel)
        buttonPanel:SetPos(10, 320)
        buttonPanel:SetSize(460, 40)
        buttonPanel.Paint = function() end
        
        local exportBtn = vgui.Create("DButton", buttonPanel)
        exportBtn:SetText("Export Network")
        exportBtn:SetPos(0, 5)
        exportBtn:SetSize(120, 30)
        exportBtn.DoClick = function()
            local filename = filenameEntry:GetValue()
            if filename == "" then
                notification.AddLegacy("Please enter a filename", NOTIFY_ERROR, 3)
                return
            end
            
            -- Ensure .json extension
            if not string.EndsWith(filename, ".json") then
                filename = filename .. ".json"
            end
            
            SaveNetworkToFile(filename, includeTrainingData:GetChecked(), includeHistory:GetChecked(), prettyJson:GetChecked())
            exportFrame:Close()
        end
        
        local copyBtn = vgui.Create("DButton", buttonPanel)
        copyBtn:SetText("Copy JSON")
        copyBtn:SetPos(130, 5)
        copyBtn:SetSize(100, 30)
        copyBtn.DoClick = function()
            local exportData = PrepareNetworkExport(includeTrainingData:GetChecked(), includeHistory:GetChecked())
            local json = util.TableToJSON(exportData, prettyJson:GetChecked())
            SetClipboardText(json)
            notification.AddLegacy("Network JSON copied to clipboard", NOTIFY_GENERIC, 3)
        end
        
        local previewBtn = vgui.Create("DButton", buttonPanel)
        previewBtn:SetText("Preview")
        previewBtn:SetPos(240, 5)
        previewBtn:SetSize(80, 30)
        previewBtn.DoClick = function()
            ShowNetworkPreview(includeTrainingData:GetChecked(), includeHistory:GetChecked(), prettyJson:GetChecked())
        end
        
        local cancelBtn = vgui.Create("DButton", buttonPanel)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetPos(330, 5)
        cancelBtn:SetSize(80, 30)
        cancelBtn.DoClick = function()
            exportFrame:Close()
        end
    end
    
    -- Helper function to calculate parameter count
    function CalculateParameterCount()
        if not currentNetwork or not currentNetwork.weights or not currentNetwork.biases then
            return 0
        end
        
        local count = 0
        
        -- Count weights
        for _, layerWeights in ipairs(currentNetwork.weights) do
            for _, nodeWeights in ipairs(layerWeights) do
                count = count + #nodeWeights
            end
        end
        
        -- Count biases
        for _, layerBiases in ipairs(currentNetwork.biases) do
            count = count + #layerBiases
        end
        
        return count
    end
    
    -- Helper function to prepare network export data
    function PrepareNetworkExport(includeTraining, includeHistories)
        local exportData = table.Copy(currentNetwork)
        
        -- Add metadata
        exportData.metadata = {
            exported_at = os.time(),
            exported_date = os.date("%Y-%m-%d %H:%M:%S"),
            training_epochs = trainingEpoch,
            final_loss = trainingLoss,
            final_accuracy = trainingAccuracy,
            parameter_count = CalculateParameterCount(),
            zdev_version = "1.0",
            format_version = "1.0"
        }
        
        -- Include training data if requested
        if includeTraining and #trainingData > 0 then
            exportData.training_data = trainingData
        end
        
        -- Include training history if requested
        if includeHistories then
            exportData.training_history = {
                loss = lossHistory,
                accuracy = accuracyHistory
            }
        end
        
        return exportData
    end
    
    -- Helper function to save network to file
    function SaveNetworkToFile(filename, includeTraining, includeHistories, prettyPrint)
        local exportData = PrepareNetworkExport(includeTraining, includeHistories)
        local json = util.TableToJSON(exportData, prettyPrint)
        
        file.Write(filename, json)
        
        local size = file.Size(filename, "DATA")
        notification.AddLegacy("Network saved to data/" .. filename .. " (" .. string.NiceSize(size or 0) .. ")", NOTIFY_GENERIC, 3)
    end
    
    -- Helper function to show network preview
    function ShowNetworkPreview(includeTraining, includeHistories, prettyPrint)
        local exportData = PrepareNetworkExport(includeTraining, includeHistories)
        local json = util.TableToJSON(exportData, prettyPrint)
        
        -- Create preview window
        local previewFrame = vgui.Create("DFrame")
        previewFrame:SetTitle("Network JSON Preview")
        previewFrame:SetSize(800, 600)
        previewFrame:Center()
        previewFrame:MakePopup()
        previewFrame:SetDeleteOnClose(true)
        
        local textEntry = vgui.Create("DTextEntry", previewFrame)
        textEntry:Dock(FILL)
        textEntry:DockMargin(10, 10, 10, 10)
        textEntry:SetMultiline(true)
        textEntry:SetValue(json)
        textEntry:SetEditable(false)
    end
    
    function TestNetwork()
        if not currentNetwork then
            notification.AddLegacy("No network to test", NOTIFY_ERROR, 3)
            return
        end
        
        if #testData == 0 then
            -- Generate test data if none exists
            GenerateTrainingData()
            testData = {}
            for i = 1, 100 do
                table.insert(testData, trainingData[i])
            end
        end
        
        local correct = 0
        local total = #testData
        
        for _, sample in ipairs(testData) do
            local output = ForwardPass(sample.input)
            if IsCorrectPrediction(output, sample.target) then
                correct = correct + 1
            end
        end
        
        local accuracy = correct / total
        notification.AddLegacy(string.format("Test Results: %.2f%% accuracy (%d/%d)", accuracy * 100, correct, total), NOTIFY_GENERIC, 5)
    end
    
    function LoadTrainingData()
        -- Create training data import dialog
        local importFrame = vgui.Create("DFrame")
        importFrame:SetTitle("Import Training Data")
        importFrame:SetSize(500, 400)
        importFrame:Center()
        importFrame:MakePopup()
        importFrame:SetDeleteOnClose(true)
        
        -- File list panel
        local fileList = vgui.Create("DListView", importFrame)
        fileList:Dock(FILL)
        fileList:DockMargin(10, 10, 10, 80)
        fileList:SetMultiSelect(false)
        fileList:AddColumn("Filename")
        fileList:AddColumn("Size")
        fileList:AddColumn("Samples")
        
        -- Populate with .json files that might contain training data
        local files = file.Find("*training*.json", "DATA")
        local allFiles = file.Find("*.json", "DATA")
        
        -- Add training-specific files first
        for _, filename in ipairs(files) do
            local content = file.Read(filename, "DATA")
            local sampleCount = "Unknown"
            if content then
                local success, data = pcall(util.JSONToTable, content)
                if success and data then
                    if type(data) == "table" and #data > 0 and data[1].input and data[1].target then
                        sampleCount = tostring(#data)
                    elseif data.training_data then
                        sampleCount = tostring(#data.training_data)
                    end
                end
            end
            
            local size = file.Size(filename, "DATA")
            local line = fileList:AddLine(filename, string.NiceSize(size or 0), sampleCount)
            line.filename = filename
        end
        
        -- Add other JSON files that might contain data
        for _, filename in ipairs(allFiles) do
            local alreadyAdded = false
            for _, trainingFile in ipairs(files) do
                if trainingFile == filename then
                    alreadyAdded = true
                    break
                end
            end
            
            if not alreadyAdded then
                local size = file.Size(filename, "DATA")
                local line = fileList:AddLine(filename, string.NiceSize(size or 0), "Check")
                line.filename = filename
            end
        end
        
        -- Control buttons
        local buttonPanel = vgui.Create("DPanel", importFrame)
        buttonPanel:Dock(BOTTOM)
        buttonPanel:SetHeight(70)
        buttonPanel.Paint = function() end
        
        local loadBtn = vgui.Create("DButton", buttonPanel)
        loadBtn:SetText("Load Selected")
        loadBtn:SetPos(10, 10)
        loadBtn:SetSize(100, 30)
        loadBtn.DoClick = function()
            local selected = fileList:GetSelectedLine()
            if selected then
                LoadTrainingDataFromFile(selected.filename)
                importFrame:Close()
            else
                notification.AddLegacy("Please select a file to load", NOTIFY_ERROR, 3)
            end
        end
        
        local generateBtn = vgui.Create("DButton", buttonPanel)
        generateBtn:SetText("Generate New")
        generateBtn:SetPos(120, 10)
        generateBtn:SetSize(100, 30)
        generateBtn.DoClick = function()
            GenerateTrainingData()
            importFrame:Close()
        end
        
        local exportBtn = vgui.Create("DButton", buttonPanel)
        exportBtn:SetText("Export Current")
        exportBtn:SetPos(230, 10)
        exportBtn:SetSize(100, 30)
        exportBtn.DoClick = function()
            ExportTrainingData()
        end
        
        local cancelBtn = vgui.Create("DButton", buttonPanel)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetPos(340, 10)
        cancelBtn:SetSize(80, 30)
        cancelBtn.DoClick = function()
            importFrame:Close()
        end
    end
    
    -- Helper function to load training data from file
    function LoadTrainingDataFromFile(filename)
        local content = file.Read(filename, "DATA")
        if content then
            local success, data = pcall(util.JSONToTable, content)
            if success and data then
                -- Check if it's a network file with training data
                if data.training_data then
                    trainingData = data.training_data
                    notification.AddLegacy("Loaded " .. #trainingData .. " training samples from network file", NOTIFY_GENERIC, 3)
                -- Check if it's a direct training data array
                elseif type(data) == "table" and #data > 0 and data[1].input and data[1].target then
                    trainingData = data
                    notification.AddLegacy("Loaded " .. #trainingData .. " training samples", NOTIFY_GENERIC, 3)
                else
                    notification.AddLegacy("File does not contain valid training data", NOTIFY_ERROR, 3)
                end
            else
                notification.AddLegacy("Invalid data format", NOTIFY_ERROR, 3)
            end
        else
            notification.AddLegacy("Could not read file: " .. filename, NOTIFY_ERROR, 3)
        end
    end
    
    -- Function to export training data
    function ExportTrainingData()
        if #trainingData == 0 then
            notification.AddLegacy("No training data to export", NOTIFY_ERROR, 3)
            return
        end
        
        Derma_StringRequest("Export Training Data", "Enter filename:", "training_data_" .. os.date("%Y%m%d_%H%M%S") .. ".json", function(filename)
            if filename == "" then
                notification.AddLegacy("Please enter a filename", NOTIFY_ERROR, 3)
                return
            end
            
            -- Ensure .json extension
            if not string.EndsWith(filename, ".json") then
                filename = filename .. ".json"
            end
            
            -- Create export data with metadata
            local exportData = {
                metadata = {
                    exported_at = os.time(),
                    exported_date = os.date("%Y-%m-%d %H:%M:%S"),
                    sample_count = #trainingData,
                    input_size = trainingData[1] and #trainingData[1].input or 0,
                    output_size = trainingData[1] and #trainingData[1].target or 0,
                    zdev_version = "1.0"
                },
                training_data = trainingData
            }
            
            local json = util.TableToJSON(exportData, true)
            file.Write(filename, json)
            
            local size = file.Size(filename, "DATA")
            notification.AddLegacy("Training data saved to data/" .. filename .. " (" .. string.NiceSize(size or 0) .. ")", NOTIFY_GENERIC, 3)
        end)
    end
    
    function UpdateVisualization()
        -- Force canvas repaint
        if IsValid(canvas) then
            canvas:InvalidateLayout()
        end
    end
    
    function GetNetworkInfo()
        if not currentNetwork then return 'None' end
        local info = ''
        for i, layer in ipairs(currentNetwork.layers) do
            info = info .. layer.size
            if i < #currentNetwork.layers then
                info = info .. '-'
            end
        end
        return info
    end
    
    --[[ Real-time neural network visualization ]]
    function DrawRealTimeNetworkVisualization(panel, w, h)
        if not NeuralViz.networkData or not IsValid(NeuralViz.selectedNPC) then
            --[[ Draw NPC selection interface ]]
            draw.SimpleText('Real-Time Neural Network Visualizer', 'DermaDefaultBold', w/2, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            draw.SimpleText('Select an NPC from the dropdown to begin visualization', 'DermaDefault', w/2, 60, Color(200, 200, 200), TEXT_ALIGN_CENTER)
            
            --[[ Populate NPC list ]]
            PopulateNPCList()
            
            --[[ Show available NPCs ]]
            local y = 100
            draw.SimpleText('Available Learning NPCs:', 'DermaDefault', 50, y, Color(255, 255, 255))
            y = y + 25
            
            for _, ent in ipairs(ents.GetAll()) do
                if IsValid(ent) and (ent.Brain or ent.AdvancedBrain) then
                    local npcInfo = string.format('%s [%s] - %s', 
                        ent:GetClass(), 
                        ent.Brain and (ent.Brain.input_nodes == 6 and 'Compressed' or 'Legacy') or 'Advanced',
                        ent:GetModel())
                    draw.SimpleText('• ' .. npcInfo, 'DermaDefault', 70, y, Color(150, 255, 150))
                    y = y + 20
                    if y > h - 50 then break end
                end
            end
            return
        end
        
        local data = NeuralViz.networkData
        
        --[[ Header ]]
        draw.SimpleText('Real-Time: ' .. NeuralViz.selectedNPC:GetClass(), 'DermaDefaultBold', w/2, 10, Color(100, 255, 100), TEXT_ALIGN_CENTER)
        draw.SimpleText('Architecture: ' .. data.architecture, 'DermaDefault', w/2, 30, Color(255, 255, 100), TEXT_ALIGN_CENTER)
        
        --[[ Architecture-specific visualization ]]
        if data.architecture:find('Advanced') then
            DrawAdvancedNetworkVisualization(data, w, h - 100, 50)
        else
            DrawSimpleNetworkVisualization(data, w, h - 100, 50)
        end
        
        --[[ Performance metrics at bottom ]]
        local startY = h - 80
        draw.SimpleText('Performance Metrics:', 'DermaDefault', 10, startY, Color(255, 255, 255))
        
        if data.performance.learning_rate then
            draw.SimpleText('Learning Rate: ' .. string.format('%.4f', data.performance.learning_rate), 'DermaDefault', 10, startY + 15, Color(200, 200, 255))
        end
        
        if data.performance.total_reward then
            draw.SimpleText('Total Reward: ' .. string.format('%.2f', data.performance.total_reward), 'DermaDefault', 150, startY + 15, Color(100, 255, 100))
        end
        
        if data.memory_usage then
            draw.SimpleText('Memory: ' .. string.format('%.1f KB', data.memory_usage / 1024), 'DermaDefault', 280, startY + 15, Color(255, 200, 100))
        end
        
        --[[ Weight history graph ]]
        if #NeuralViz.weightHistory > 1 then
            DrawWeightHistoryGraph(w - 300, h - 150, 280, 120)
        end
    end
    
    --[[ Draw simple neural network visualization ]]
    function DrawSimpleNetworkVisualization(data, w, h, startY)
        if not data.neurons or not data.neurons.input then return end
        
        local layers = {data.neurons.input, data.neurons.hidden, data.neurons.output}
        local layerNames = {'Input', 'Hidden', 'Output'}
        local layerSpacing = (w - 100) / 2
        local nodeRadius = 6
        
        --[[ Draw connections with weights ]]
        if data.weights.input_hidden then
            for i = 1, data.neurons.hidden do
                for j = 1, data.neurons.input do
                    local weight = data.weights.input_hidden[i] and data.weights.input_hidden[i][j] or 0
                    local x1 = 50
                    local y1 = startY + 30 + (j - 1) * (h - 60) / math.max(1, data.neurons.input - 1)
                    local x2 = 50 + layerSpacing
                    local y2 = startY + 30 + (i - 1) * (h - 60) / math.max(1, data.neurons.hidden - 1)
                    
                    local intensity = math.Clamp(math.abs(weight) * 255, 10, 255)
                    local color = weight > 0 and Color(0, intensity, 0, 150) or Color(intensity, 0, 0, 150)
                    surface.SetDrawColor(color.r, color.g, color.b, color.a)
                    surface.DrawLine(x1, y1, x2, y2)
                end
            end
        end
        
        if data.weights.hidden_output then
            for i = 1, data.neurons.output do
                for j = 1, data.neurons.hidden do
                    local weight = data.weights.hidden_output[i] and data.weights.hidden_output[i][j] or 0
                    local x1 = 50 + layerSpacing
                    local y1 = startY + 30 + (j - 1) * (h - 60) / math.max(1, data.neurons.hidden - 1)
                    local x2 = 50 + layerSpacing * 2
                    local y2 = startY + 30 + (i - 1) * (h - 60) / math.max(1, data.neurons.output - 1)
                    
                    local intensity = math.Clamp(math.abs(weight) * 255, 10, 255)
                    local color = weight > 0 and Color(0, intensity, 0, 150) or Color(intensity, 0, 0, 150)
                    surface.SetDrawColor(color.r, color.g, color.b, color.a)
                    surface.DrawLine(x1, y1, x2, y2)
                end
            end
        end
        
        --[[ Draw nodes ]]
        for layerIdx, layerSize in ipairs(layers) do
            local x = 50 + (layerIdx - 1) * layerSpacing
            local color = layerIdx == 1 and NeuralViz.colors.neuron_input or 
                         layerIdx == 3 and NeuralViz.colors.neuron_output or 
                         NeuralViz.colors.neuron_active
            
            for nodeIdx = 1, layerSize do
                local y = startY + 30 + (nodeIdx - 1) * (h - 60) / math.max(1, layerSize - 1)
                
                --[[ Node activation ]]
                local activation = 0
                if layerIdx == 1 and data.inputs and data.inputs[nodeIdx] then
                    activation = data.inputs[nodeIdx]
                elseif layerIdx == 3 and data.outputs and data.outputs[nodeIdx] then
                    activation = data.outputs[nodeIdx]
                end
                
                local fillIntensity = math.Clamp(activation * 255, 0, 255)
                surface.SetDrawColor(color.r, color.g, color.b, fillIntensity)
                surface.DrawOutlinedCircle(x, y, nodeRadius)
                
                if activation > 0.1 then
                    surface.SetDrawColor(255, 255, 255, fillIntensity)
                    surface.DrawOutlinedCircle(x, y, nodeRadius - 2)
                end
            end
            
            --[[ Layer labels ]]
            draw.SimpleText(layerNames[layerIdx], 'DermaDefault', x, startY + 10, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        end
    end
    
    --[[ Draw advanced neural network visualization ]]
    function DrawAdvancedNetworkVisualization(data, w, h, startY)
        if not data.neurons then return end
        
        local sections = {
            {name = 'Visual Input', value = data.neurons.visual_input, x = 50, color = Color(100, 255, 100)},
            {name = 'Vector Input', value = data.neurons.vector_input, x = 150, color = Color(100, 255, 100)},
            {name = 'Conv Filters', value = data.neurons.conv1_filters + data.neurons.conv2_filters, x = 250, color = Color(100, 150, 255)},
            {name = 'LSTM Units', value = data.neurons.lstm_units, x = 350, color = Color(255, 150, 100)},
            {name = 'FC Units', value = data.neurons.fc_units, x = 450, color = Color(150, 255, 150)},
            {name = 'Actions', value = data.neurons.action_output, x = 550, color = Color(255, 100, 100)},
            {name = 'Value', value = data.neurons.value_output, x = 650, color = Color(255, 100, 100)}
        }
        
        --[[ Draw sections ]]
        for _, section in ipairs(sections) do
            if section.x > w - 100 then break end
            
            --[[ Section header ]]
            draw.SimpleText(section.name, 'DermaDefault', section.x, startY + 10, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            draw.SimpleText(tostring(section.value), 'DermaDefault', section.x, startY + 25, section.color, TEXT_ALIGN_CENTER)
            
            --[[ Visual representation ]]
            local rectHeight = math.min(h - 80, section.value * 3)
            surface.SetDrawColor(section.color.r, section.color.g, section.color.b, 100)
            surface.DrawRect(section.x - 20, startY + 40, 40, rectHeight)
            surface.SetDrawColor(section.color.r, section.color.g, section.color.b, 200)
            surface.DrawOutlinedRect(section.x - 20, startY + 40, 40, rectHeight)
        end
        
        --[[ LSTM state visualization ]]
        if data.activations.lstm_hidden then
            local lstmY = startY + h - 100
            draw.SimpleText('LSTM Hidden State:', 'DermaDefault', 50, lstmY, Color(255, 255, 255))
            
            for i = 1, math.min(20, #data.activations.lstm_hidden) do
                local activation = data.activations.lstm_hidden[i]
                local intensity = math.Clamp(math.abs(activation) * 255, 0, 255)
                local color = activation > 0 and Color(0, intensity, 0) or Color(intensity, 0, 0)
                
                surface.SetDrawColor(color.r, color.g, color.b, 200)
                surface.DrawRect(50 + i * 15, lstmY + 15, 10, 20)
            end
        end
    end
    
    --[[ Draw weight history graph ]]
    function DrawWeightHistoryGraph(x, y, w, h)
        surface.SetDrawColor(40, 40, 60, 200)
        surface.DrawRect(x, y, w, h)
        surface.SetDrawColor(100, 100, 150, 255)
        surface.DrawOutlinedRect(x, y, w, h)
        
        draw.SimpleText('Weight History', 'DermaDefault', x + w/2, y - 15, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        
        if #NeuralViz.weightHistory < 2 then return end
        
        --[[ Find reward range ]]
        local minReward, maxReward = math.huge, -math.huge
        for _, data in ipairs(NeuralViz.weightHistory) do
            if data.performance and data.performance.total_reward then
                minReward = math.min(minReward, data.performance.total_reward)
                maxReward = math.max(maxReward, data.performance.total_reward)
            end
        end
        
        if maxReward == minReward then maxReward = minReward + 1 end
        
        --[[ Draw reward curve ]]
        surface.SetDrawColor(100, 255, 100, 255)
        for i = 2, #NeuralViz.weightHistory do
            local data1 = NeuralViz.weightHistory[i-1]
            local data2 = NeuralViz.weightHistory[i]
            
            if data1.performance and data1.performance.total_reward and 
               data2.performance and data2.performance.total_reward then
                
                local x1 = x + (i-2) * w / math.max(1, #NeuralViz.weightHistory-1)
                local y1 = y + h - ((data1.performance.total_reward - minReward) / (maxReward - minReward)) * h
                local x2 = x + (i-1) * w / math.max(1, #NeuralViz.weightHistory-1)
                local y2 = y + h - ((data2.performance.total_reward - minReward) / (maxReward - minReward)) * h
                
                surface.DrawLine(x1, y1, x2, y2)
            end
        end
    end
    
    --[[ Populate NPC dropdown with learning NPCs ]]
    function PopulateNPCList()
        if not npcSelector then return end
        
        npcSelector:Clear()
        npcSelector:AddChoice('Select NPC...', nil)
        
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and (ent.Brain or ent.AdvancedBrain) then
                local archType = ent.Brain and (ent.Brain.input_nodes == 6 and 'Compressed' or 'Legacy') or 'Advanced'
                local displayName = string.format('%s [%s]', ent:GetClass(), archType)
                npcSelector:AddChoice(displayName, ent)
            end
        end
    end
    
    --[[ Refresh visualization and NPC list ]]
    function RefreshVisualization()
        if realTimeMode then
            PopulateNPCList()
        end
    end
end

concommand.Add( "zdev_menu_neuralnetwork", ZDEV.VGUI.NeuralNetworkEditor )

ZDEV.FILE.Loaded( _f )
