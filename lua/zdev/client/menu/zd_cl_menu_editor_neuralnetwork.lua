
-- neural_network_editor.lua
-- A neural network visualization and customization tool for Garry's Mod

AddCSLuaFile()

-- Server-side network strings
if SERVER then
    util.AddNetworkString("NeuralNetworkData")
    util.AddNetworkString("RequestNeuralNetworkData")
end

-- Server-side functions
if SERVER then
    -- Function to generate a neural network
    local function GenerateNeuralNetwork(ply, layers, neuronsPerLayer, activationFunction)
        local network = {
            layers = {},
            connections = {},
            activationFunction = activationFunction or "sigmoid"
        }

        -- Create layers
        for i = 1, layers do
            local layer = {
                type = i == 1 and "input" or (i == layers and "output" or "hidden"),
                neurons = {}
            }

            -- Create neurons in each layer
            local neuronCount = neuronsPerLayer[i] or (i == 1 and 3 or (i == layers and 2 or 4))
            for j = 1, neuronCount do
                table.insert(layer.neurons, {
                    id = "n" .. i .. "_" .. j,
                    bias = math.Rand(-1, 1),
                    activation = 0,
                    x = 0,
                    y = 0
                })
            end

            table.insert(network.layers, layer)
        end

        -- Create connections between layers
        for i = 1, #network.layers - 1 do
            for _, fromNeuron in ipairs(network.layers[i].neurons) do
                for _, toNeuron in ipairs(network.layers[i + 1].neurons) do
                    table.insert(network.connections, {
                        from = fromNeuron.id,
                        to = toNeuron.id,
                        weight = math.Rand(-1, 1)
                    })
                end
            end
        end

        -- Send the network data to the client
        net.Start("NeuralNetworkData")
            net.WriteEntity(ply)
            net.WriteTable(network)
        net.Send(ply)

        return network
    end

    -- Concommand to generate a neural network
    concommand.Add("nn_generate", function(ply, cmd, args)
        local layers = tonumber(args[1]) or 3
        local neuronsPerLayer = {}
        for i = 2, #args do
            neuronsPerLayer[i-1] = tonumber(args[i]) or 4
        end

        GenerateNeuralNetwork(ply, layers, neuronsPerLayer)
    end)

    -- Handle client requests for network data
    net.Receive("RequestNeuralNetworkData", function(len, ply)
        local network = GenerateNeuralNetwork(ply, 3, {3, 4, 2})
    end)
end

-- Client-side code
if CLIENT then
    -- Client-side variables
    local neuralNetworkData = {}
    local selectedNode = nil
    local selectedConnection = nil
    local selectedLayer = nil
    local isDraggingNode = false
    local dragOffsetX = 0
    local dragOffsetY = 0
    local isDraggingCanvas = false
    local canvasOffsetX = 0
    local canvasOffsetY = 0
    local canvasScale = 1.0
    local visualizationPanel = nil
    local propertiesPanel = nil
    local networkCanvas = nil
    local nodeRadius = 20
    local connectionWidth = 2
    local nodeColors = {
        input = Color(100, 200, 100),
        hidden = Color(100, 100, 200),
        output = Color(200, 100, 100)
    }
    local connectionColor = Color(200, 200, 200, 150)
    local selectedColor = Color(255, 255, 0)
    local highlightColor = Color(255, 255, 255, 50)

    -- Training state variables
    local isTraining = false
    local trainingData = {}
    local trainingEpoch = 0
    local trainingMaxEpochs = 100
    local trainingLearningRate = 0.1
    local trainingMomentum = 0.9
    local trainingLossHistory = {}
    local trainingAccuracyHistory = {}
    local currentLoss = 0
    local currentAccuracy = 0
    local trainingTimer = nil
    local trainingSpeed = 0.05 -- seconds between training steps
    local showActivations = true
    local showWeightColors = true

    -- Visualization mode: 'network', 'loss', 'accuracy', 'weights', 'realtime'
    local visualizationMode = 'network'

    -- Real-time NPC visualization state
    local realTimeMode = false
    local selectedNPC = nil
    local npcNetworkData = {}
    local weightHistory = {}
    local maxHistoryLength = 100
    local lastNPCUpdate = 0
    local npcUpdateRate = 0.1

    -- NPC data collection colors
    local npcColors = {
        background = Color(20, 20, 30, 240),
        neuron_inactive = Color(60, 60, 80, 200),
        neuron_active = Color(100, 200, 255, 255),
        neuron_input = Color(100, 255, 100, 255),
        neuron_output = Color(255, 100, 100, 255),
        connection_weak = Color(80, 80, 80, 100),
        connection_strong = Color(255, 255, 255, 200)
    }

    -- Neural entity class identifiers
    local NEURAL_ENTITY_CLASSES = {
        'zdev_npcs_neural_base',
        'zdev_nextbot_neural_base',
        'zdev_nextbot_ghost'
    }

    -- Check if an entity is a neural SNPC or NextBot
    local function IsNeuralEntity(ent)
        if not IsValid(ent) then return false end
        local class = ent:GetClass()
        for _, neuralClass in ipairs(NEURAL_ENTITY_CLASSES) do
            if class == neuralClass or string.find(class, neuralClass) then
                return true
            end
        end
        -- Also check for nn table (neural network weights)
        if ent.nn and (ent.nn.weights1 or ent.nn.weights2) then
            return true
        end
        -- Legacy checks for Brain/AdvancedBrain
        if ent.Brain or ent.AdvancedBrain then
            return true
        end
        return false
    end

    -- Get neural entity architecture type
    local function GetNeuralEntityType(ent)
        if not IsValid(ent) then return "Unknown" end
        local class = ent:GetClass()

        if class == 'zdev_npcs_neural_base' then
            return "Neural SNPC"
        elseif class == 'zdev_nextbot_neural_base' then
            return "Neural NextBot"
        elseif class == 'zdev_nextbot_ghost' then
            if ent.AdvancedBrain then
                return "Ghost (Advanced)"
            elseif ent.Brain then
                return ent.Brain.input_nodes == 6 and "Ghost (Compressed)" or "Ghost (Legacy)"
            end
            return "Ghost"
        elseif ent.AdvancedBrain then
            return "Advanced (CNN+LSTM)"
        elseif ent.Brain then
            return ent.Brain.input_nodes == 6 and "Compressed" or "Legacy"
        elseif ent.nn then
            return "Neural (nn table)"
        end
        return "Unknown"
    end

    -- Collect network data from NPC
    local function CollectNPCNetworkData()
        if not IsValid(selectedNPC) then return nil end

        local npc = selectedNPC
        local data = {
            timestamp = CurTime(),
            architecture = 'Unknown',
            entityClass = npc:GetClass(),
            neurons = {},
            weights = {},
            activations = {},
            inputs = {},
            outputs = {},
            performance = {},
            memory_usage = 0,
            -- Neural entity specific data
            inputLabels = {},
            outputLabels = {},
            hiddenLayers = 1
        }

        -- Check for neural SNPC/NextBot entities with nn table
        local class = npc:GetClass()
        if class == 'zdev_npcs_neural_base' and npc.nn then
            data.architecture = 'Neural SNPC (8→16×6→7)'
            local nn = npc.nn
            -- Get config from NeuralConfig if available
            local inputNodes = 8
            local hiddenNodes = 16
            local hiddenLayers = 6
            local outputNodes = 7

            data.neurons = {
                input = inputNodes,
                hidden = hiddenNodes,
                output = outputNodes,
                hiddenLayers = hiddenLayers
            }
            data.hiddenLayers = hiddenLayers
            data.inputLabels = {'Distance', 'Health', 'Enemy HP', 'Has Weapon', 'Squad Support', 'Can See', 'Can Hear', 'Last Attack'}
            data.outputLabels = {'Attack', 'Defend', 'Retreat', 'Flee', 'Investigate', 'Communicate', 'Idle'}

            -- Collect weights
            if nn.weights1 then
                data.weights.input_hidden = nn.weights1
            end
            if nn.weights2 then
                data.weights.hidden_output = nn.weights2
            end
            if nn.bias1 then data.weights.bias1 = nn.bias1 end
            if nn.bias2 then data.weights.bias2 = nn.bias2 end

            data.performance.generation = nn.generation or 1
            data.performance.parentFitness = nn.parentFitness or 0
            data.performance.decision = npc:GetNWString("Decision", "Unknown")

            -- Networked vars if available
            if npc.GetAIFitness then data.performance.fitness = npc:GetAIFitness() end
            if npc.GetAIGeneration then data.performance.generation = npc:GetAIGeneration() end
            if npc.GetAIBehavior then data.current_behavior = npc:GetAIBehavior() end
            if npc.GetIsTraining then data.performance.isTraining = npc:GetIsTraining() end

            local totalWeights = (inputNodes * hiddenNodes) + (hiddenNodes * outputNodes)
            data.memory_usage = totalWeights * 4

        elseif class == 'zdev_nextbot_neural_base' and npc.nn then
            data.architecture = 'Neural NextBot (6→8→4)'
            local nn = npc.nn
            local inputNodes = 6
            local hiddenNodes = 8
            local outputNodes = 4

            data.neurons = {
                input = inputNodes,
                hidden = hiddenNodes,
                output = outputNodes,
                hiddenLayers = 1
            }
            data.hiddenLayers = 1
            data.inputLabels = {'Distance', 'Can See', 'Health', 'Enemy HP', 'Cover Avail', 'Weapon Ready'}
            data.outputLabels = {'Approach', 'Flee', 'Seek Cover', 'Attack'}

            -- Collect weights
            if nn.weights1 then
                data.weights.input_hidden = nn.weights1
            end
            if nn.weights2 then
                data.weights.hidden_output = nn.weights2
            end
            if nn.bias1 then data.weights.bias1 = nn.bias1 end
            if nn.bias2 then data.weights.bias2 = nn.bias2 end

            data.performance.generation = nn.generation or 1
            data.performance.parentFitness = nn.parentFitness or 0

            -- Networked vars
            if npc.GetFitness then data.performance.fitness = npc:GetFitness() end
            if npc.GetGeneration then data.performance.generation = npc:GetGeneration() end
            if npc.GetAIDecision then data.current_behavior = npc:GetAIDecision() end
            if npc.GetIsLearning then data.performance.isTraining = npc:GetIsLearning() end

            local totalWeights = (inputNodes * hiddenNodes) + (hiddenNodes * outputNodes)
            data.memory_usage = totalWeights * 4

        elseif npc.AdvancedBrain then
            data.architecture = 'Advanced (CNN+LSTM+Multi-Head)'
            local brain = npc.AdvancedBrain
            data.neurons = {
                visual_input = (brain.visualHeight or 0) * (brain.visualWidth or 0),
                vector_input = brain.vectorInputSize or 0,
                conv1_filters = 32,
                conv2_filters = 64,
                lstm_units = brain.lstmUnits or 0,
                fc_units = brain.fcUnits or 0,
                action_output = brain.actionDim or 0,
                value_output = 1
            }
            if brain.lstm_hidden then
                data.activations.lstm_hidden = {}
                for i = 1, (brain.lstmUnits or 0) do
                    data.activations.lstm_hidden[i] = brain.lstm_hidden[i] or 0
                end
            end
            data.performance.learning_rate = brain.learning_rate or 0
            data.performance.dropout_rate = brain.dropout_rate or 0
            data.performance.state_value = npc.CurrentStateValue or 0
            data.current_behavior = npc.CurrentBehaviorName or "N/A"
            local convWeights = (32 * 3 * 3) + (64 * 3 * 3)
            local lstmWeights = (brain.lstmUnits or 0) * ((brain.lstm_input_size or 0) + (brain.lstmUnits or 0)) * 4
            local fcWeights = (brain.fcUnits or 0) * (brain.lstmUnits or 0)
            local outputWeights = ((brain.actionDim or 0) + 1) * (brain.fcUnits or 0)
            data.memory_usage = (convWeights + lstmWeights + fcWeights + outputWeights) * 4
        elseif npc.Brain then
            local brain = npc.Brain
            if brain.input_nodes == 6 then
                data.architecture = 'Compressed (6-input optimized)'
            else
                data.architecture = 'Legacy (61-input full)'
            end
            data.neurons = {
                input = brain.input_nodes or 0,
                hidden = brain.hidden_nodes or 0,
                output = brain.output_nodes or 0
            }
            if brain.weights_ih then
                data.weights.input_hidden = {}
                for i = 1, (brain.hidden_nodes or 0) do
                    data.weights.input_hidden[i] = {}
                    for j = 1, (brain.input_nodes or 0) do
                        if brain.weights_ih[i] and brain.weights_ih[i][j] then
                            data.weights.input_hidden[i][j] = brain.weights_ih[i][j]
                        end
                    end
                end
            end
            if brain.weights_ho then
                data.weights.hidden_output = {}
                for i = 1, (brain.output_nodes or 0) do
                    data.weights.hidden_output[i] = {}
                    for j = 1, (brain.hidden_nodes or 0) do
                        if brain.weights_ho[i] and brain.weights_ho[i][j] then
                            data.weights.hidden_output[i][j] = brain.weights_ho[i][j]
                        end
                    end
                end
            end
            if brain.lastInputs then data.inputs = brain.lastInputs end
            if brain.lastOutputs then data.outputs = brain.lastOutputs end
            data.performance.learning_rate = brain.learning_rate or 0
            data.performance.momentum = brain.momentum or 0
            data.performance.total_reward = npc.TotalReward or 0
            local totalWeights = (data.neurons.input * data.neurons.hidden) + (data.neurons.hidden * data.neurons.output)
            data.memory_usage = totalWeights * 4
        elseif npc.nn then
            -- Generic nn table support for other neural entities
            data.architecture = 'Generic Neural (nn table)'
            local nn = npc.nn
            local inputCount = nn.weights1 and #nn.weights1 or 0
            local hiddenCount = nn.weights1 and nn.weights1[1] and #nn.weights1[1] or 0
            local outputCount = nn.weights2 and nn.weights2[1] and #nn.weights2[1] or 0

            data.neurons = {
                input = inputCount,
                hidden = hiddenCount,
                output = outputCount
            }
            if nn.weights1 then data.weights.input_hidden = nn.weights1 end
            if nn.weights2 then data.weights.hidden_output = nn.weights2 end
            if nn.bias1 then data.weights.bias1 = nn.bias1 end
            if nn.bias2 then data.weights.bias2 = nn.bias2 end

            data.performance.generation = nn.generation or 1
            local totalWeights = (inputCount * hiddenCount) + (hiddenCount * outputCount)
            data.memory_usage = totalWeights * 4
        else
            data.architecture = 'No Brain Detected'
            return data
        end

        -- Store in history
        table.insert(weightHistory, data)
        if #weightHistory > maxHistoryLength then
            table.remove(weightHistory, 1)
        end

        npcNetworkData = data
        return data
    end

    -- Save network to JSON file
    local function SaveNetworkToFile(filename)
        if not neuralNetworkData or not neuralNetworkData.layers then
            notification.AddLegacy("No network data to save!", NOTIFY_ERROR, 2)
            return false
        end

        local saveData = {
            timestamp = os.date('%Y-%m-%d %H:%M:%S'),
            architecture = neuralNetworkData.activationFunction or "Sigmoid",
            layers = neuralNetworkData.layers,
            connections = neuralNetworkData.connections,
            training = {
                epochs = trainingEpoch,
                loss = currentLoss,
                accuracy = currentAccuracy,
                loss_history = trainingLossHistory,
                accuracy_history = trainingAccuracyHistory
            }
        }

        local jsonData = util.TableToJSON(saveData, true)
        if not jsonData then
            notification.AddLegacy("Failed to serialize network data!", NOTIFY_ERROR, 2)
            return false
        end

        file.CreateDir('zdev/neural_networks')
        local filePath = 'zdev/neural_networks/' .. filename .. '.json'
        file.Write(filePath, jsonData)

        notification.AddLegacy("Network saved to: data/" .. filePath, NOTIFY_GENERIC, 3)
        return true
    end

    -- Load network from JSON file
    local function LoadNetworkFromFile(filename)
        local filePath = 'zdev/neural_networks/' .. filename .. '.json'

        if not file.Exists(filePath, 'DATA') then
            notification.AddLegacy("File not found: " .. filePath, NOTIFY_ERROR, 2)
            return false
        end

        local jsonData = file.Read(filePath, 'DATA')
        if not jsonData then
            notification.AddLegacy("Failed to read file: " .. filePath, NOTIFY_ERROR, 2)
            return false
        end

        local loadedData = util.JSONToTable(jsonData)
        if not loadedData then
            notification.AddLegacy("Failed to parse JSON from: " .. filePath, NOTIFY_ERROR, 2)
            return false
        end

        neuralNetworkData = {
            layers = loadedData.layers or {},
            connections = loadedData.connections or {},
            activationFunction = loadedData.architecture or "Sigmoid"
        }

        if loadedData.training then
            trainingEpoch = loadedData.training.epochs or 0
            currentLoss = loadedData.training.loss or 0
            currentAccuracy = loadedData.training.accuracy or 0
            trainingLossHistory = loadedData.training.loss_history or {}
            trainingAccuracyHistory = loadedData.training.accuracy_history or {}
        end

        notification.AddLegacy("Network loaded from: " .. filePath, NOTIFY_GENERIC, 3)
        return true
    end

    -- Get list of saved neural network files
    local function GetSavedNetworks()
        local files = file.Find('zdev/neural_networks--[[.json', 'DATA')
        local networks = {}
        for _, filename in ipairs(files or {}) do
            local name = string.gsub(filename, '.json', '')
            table.insert(networks, name)
        end
        return networks
    end

    -- Load network from a neural entity into the editor
    local function LoadNetworkFromEntity(ent)
        if not IsValid(ent) then
            notification.AddLegacy("Invalid entity!", NOTIFY_ERROR, 2)
            return false
        end

        if not ent.nn then
            notification.AddLegacy("Entity has no neural network (nn table)!", NOTIFY_ERROR, 2)
            return false
        end

        local nn = ent.nn
        local class = ent:GetClass()

        -- Determine architecture from entity class
        local inputCount, hiddenCount, outputCount = 0, 0, 0
        local inputLabels, outputLabels = {}, {}

        if class == 'zdev_npcs_neural_base' then
            inputCount = 8
            hiddenCount = 16
            outputCount = 7
            inputLabels = {'Distance', 'Health', 'Enemy HP', 'Has Weapon', 'Squad Support', 'Can See', 'Can Hear', 'Last Attack'}
            outputLabels = {'Attack', 'Defend', 'Retreat', 'Flee', 'Investigate', 'Communicate', 'Idle'}
        elseif class == 'zdev_nextbot_neural_base' then
            inputCount = 6
            hiddenCount = 8
            outputCount = 4
            inputLabels = {'Distance', 'Can See', 'Health', 'Enemy HP', 'Cover Avail', 'Weapon Ready'}
            outputLabels = {'Approach', 'Flee', 'Seek Cover', 'Attack'}
        else
            -- Try to infer from weights
            inputCount = nn.weights1 and #nn.weights1 or 0
            hiddenCount = nn.weights1 and nn.weights1[1] and #nn.weights1[1] or 0
            outputCount = nn.weights2 and nn.weights2[1] and #nn.weights2[1] or 0
        end

        -- Build network structure for editor
        local layers = {}
        local connections = {}
        local nodeSpacingY = 60

        -- Input layer
        local inputLayer = {type = "input", neurons = {}}
        for i = 1, inputCount do
            table.insert(inputLayer.neurons, {
                id = "n1_" .. i,
                bias = 0,
                activation = 0,
                x = 100,
                y = 50 + (i - 1) * nodeSpacingY,
                label = inputLabels[i] or ("Input " .. i)
            })
        end
        table.insert(layers, inputLayer)

        -- Hidden layer
        local hiddenLayer = {type = "hidden", neurons = {}}
        for i = 1, hiddenCount do
            local bias = nn.bias1 and nn.bias1[i] or 0
            table.insert(hiddenLayer.neurons, {
                id = "n2_" .. i,
                bias = bias,
                activation = 0,
                x = 350,
                y = 50 + (i - 1) * (nodeSpacingY * inputCount / hiddenCount)
            })
        end
        table.insert(layers, hiddenLayer)

        -- Output layer
        local outputLayer = {type = "output", neurons = {}}
        for i = 1, outputCount do
            local bias = nn.bias2 and nn.bias2[i] or 0
            table.insert(outputLayer.neurons, {
                id = "n3_" .. i,
                bias = bias,
                activation = 0,
                x = 600,
                y = 100 + (i - 1) * nodeSpacingY,
                label = outputLabels[i] or ("Output " .. i)
            })
        end
        table.insert(layers, outputLayer)

        -- Build connections from weights
        if nn.weights1 then
            for i = 1, inputCount do
                for j = 1, hiddenCount do
                    local weight = nn.weights1[i] and nn.weights1[i][j] or 0
                    table.insert(connections, {
                        from = "n1_" .. i,
                        to = "n2_" .. j,
                        weight = weight
                    })
                end
            end
        end

        if nn.weights2 then
            for i = 1, hiddenCount do
                for j = 1, outputCount do
                    local weight = nn.weights2[i] and nn.weights2[i][j] or 0
                    table.insert(connections, {
                        from = "n2_" .. i,
                        to = "n3_" .. j,
                        weight = weight
                    })
                end
            end
        end

        neuralNetworkData = {
            layers = layers,
            connections = connections,
            activationFunction = "Sigmoid",
            sourceEntity = ent,
            sourceClass = class,
            generation = nn.generation or 1
        }

        notification.AddLegacy("Loaded network from " .. class .. " (Gen " .. (nn.generation or 1) .. ")", NOTIFY_GENERIC, 3)
        return true
    end

    -- Save entity network weights to a JSON file
    local function SaveEntityWeightsToFile(ent, filename)
        if not IsValid(ent) or not ent.nn then
            notification.AddLegacy("Invalid entity or no neural network!", NOTIFY_ERROR, 2)
            return false
        end

        local saveData = {
            timestamp = os.date('%Y-%m-%d %H:%M:%S'),
            entityClass = ent:GetClass(),
            generation = ent.nn.generation or 1,
            parentFitness = ent.nn.parentFitness or 0,
            weights1 = ent.nn.weights1,
            bias1 = ent.nn.bias1,
            weights2 = ent.nn.weights2,
            bias2 = ent.nn.bias2
        }

        local jsonData = util.TableToJSON(saveData, true)
        if not jsonData then
            notification.AddLegacy("Failed to serialize weights!", NOTIFY_ERROR, 2)
            return false
        end

        file.CreateDir('zdev/neural_entity_weights')
        local filePath = 'zdev/neural_entity_weights/' .. filename .. '.json'
        file.Write(filePath, jsonData)

        notification.AddLegacy("Weights saved to: data/" .. filePath, NOTIFY_GENERIC, 3)
        return true
    end

    -- Get list of saved entity weight files
    local function GetSavedEntityWeights()
        local files = file.Find('zdev/neural_entity_weights--[[.json', 'DATA')
        local weights = {}
        for _, filename in ipairs(files or {}) do
            local name = string.gsub(filename, '.json', '')
            table.insert(weights, name)
        end
        return weights
    end

    -- Helper function: Calculate distance from point to line segment
    local function DistToLine(px, py, x1, y1, x2, y2)
        local dx = x2 - x1
        local dy = y2 - y1
        local lengthSq = dx * dx + dy * dy
        if lengthSq == 0 then
            return math.sqrt((px - x1) ^ 2 + (py - y1) ^ 2)
        end
        local t = math.max(0, math.min(1, ((px - x1) * dx + (py - y1) * dy) / lengthSq))
        local projX = x1 + t * dx
        local projY = y1 + t * dy
        return math.sqrt((px - projX) ^ 2 + (py - projY) ^ 2)
    end

    -- Activation functions
    local function sigmoid(x)
        return 1 / (1 + math.exp(-math.Clamp(x, -500, 500)))
    end

    local function dsigmoid(y)
        return y * (1 - y)
    end

    local function relu(x)
        return math.max(0, x)
    end

    local function drelu(x)
        return x > 0 and 1 or 0
    end

    local function tanh_act(x)
        return math.tanh(x)
    end

    local function dtanh(y)
        return 1 - y * y
    end

    -- Get activation function by name
    local function getActivationFunc(name)
        if name == "ReLU" then return relu, drelu
        elseif name == "Tanh" then return tanh_act, dtanh
        else return sigmoid, dsigmoid end
    end

    -- Forward pass through network
    local function ForwardPass(network, inputs)
        if not network or not network.layers then return {} end

        local activationFunc = getActivationFunc(network.activationFunction)

        -- Set input layer activations
        local inputLayer = network.layers[1]
        if inputLayer then
            for i, neuron in ipairs(inputLayer.neurons) do
                neuron.activation = inputs[i] or 0
            end
        end

        -- Propagate through hidden and output layers
        for layerIdx = 2, #network.layers do
            local layer = network.layers[layerIdx]
            for _, neuron in ipairs(layer.neurons) do
                local sum = neuron.bias or 0
                -- Find all connections to this neuron
                for _, conn in ipairs(network.connections or {}) do
                    if conn.to == neuron.id then
                        -- Find source neuron
                        for _, srcLayer in ipairs(network.layers) do
                            for _, srcNeuron in ipairs(srcLayer.neurons) do
                                if srcNeuron.id == conn.from then
                                    sum = sum + (srcNeuron.activation or 0) * (conn.weight or 0)
                                    break
                                end
                            end
                        end
                    end
                end
                neuron.activation = activationFunc(sum)
            end
        end

        -- Return output layer activations
        local outputLayer = network.layers[#network.layers]
        local outputs = {}
        if outputLayer then
            for _, neuron in ipairs(outputLayer.neurons) do
                table.insert(outputs, neuron.activation or 0)
            end
        end
        return outputs
    end

    -- Calculate loss (MSE)
    local function CalculateLoss(outputs, targets)
        local loss = 0
        for i = 1, math.min(#outputs, #targets) do
            local diff = outputs[i] - targets[i]
            loss = loss + diff * diff
        end
        return loss / math.max(1, #outputs)
    end

    -- Backpropagation training step
    local function TrainStep(network, inputs, targets, learningRate)
        if not network or not network.layers or #network.layers < 2 then return 0 end

        local activationFunc, derivativeFunc = getActivationFunc(network.activationFunction)

        -- Forward pass
        local outputs = ForwardPass(network, inputs)
        local loss = CalculateLoss(outputs, targets)

        -- Calculate output layer errors
        local outputLayer = network.layers[#network.layers]
        local outputErrors = {}
        for i, neuron in ipairs(outputLayer.neurons) do
            local target = targets[i] or 0
            local error = target - (neuron.activation or 0)
            outputErrors[neuron.id] = error * derivativeFunc(neuron.activation or 0)
        end

        -- Backpropagate errors through hidden layers
        local layerErrors = {[#network.layers] = outputErrors}
        for layerIdx = #network.layers - 1, 2, -1 do
            local layer = network.layers[layerIdx]
            local nextLayerErrors = layerErrors[layerIdx + 1]
            local errors = {}

            for _, neuron in ipairs(layer.neurons) do
                local error = 0
                -- Sum weighted errors from next layer
                for _, conn in ipairs(network.connections or {}) do
                    if conn.from == neuron.id and nextLayerErrors[conn.to] then
                        error = error + nextLayerErrors[conn.to] * (conn.weight or 0)
                    end
                end
                errors[neuron.id] = error * derivativeFunc(neuron.activation or 0)
            end
            layerErrors[layerIdx] = errors
        end

        -- Update weights and biases
        for _, conn in ipairs(network.connections or {}) do
            local toError = nil
            for layerIdx, errors in pairs(layerErrors) do
                if errors[conn.to] then
                    toError = errors[conn.to]
                    break
                end
            end

            if toError then
                -- Find source neuron activation
                local fromActivation = 0
                for _, layer in ipairs(network.layers) do
                    for _, neuron in ipairs(layer.neurons) do
                        if neuron.id == conn.from then
                            fromActivation = neuron.activation or 0
                            break
                        end
                    end
                end

                -- Update weight
                local delta = learningRate * toError * fromActivation
                conn.weight = (conn.weight or 0) + delta
            end
        end

        -- Update biases
        for layerIdx = 2, #network.layers do
            local layer = network.layers[layerIdx]
            local errors = layerErrors[layerIdx] or {}
            for _, neuron in ipairs(layer.neurons) do
                if errors[neuron.id] then
                    neuron.bias = (neuron.bias or 0) + learningRate * errors[neuron.id]
                end
            end
        end

        return loss
    end

    -- Generate unique neuron ID
    local function GenerateNeuronId(layerIdx, neuronIdx)
        return "n" .. layerIdx .. "_" .. neuronIdx .. "_" .. math.random(1000, 9999)
    end

    -- Rebuild connections after structure change
    local function RebuildConnections(network)
        network.connections = {}
        for i = 1, #network.layers - 1 do
            for _, fromNeuron in ipairs(network.layers[i].neurons) do
                for _, toNeuron in ipairs(network.layers[i + 1].neurons) do
                    table.insert(network.connections, {
                        from = fromNeuron.id,
                        to = toNeuron.id,
                        weight = math.Rand(-1, 1)
                    })
                end
            end
        end
    end

    -- Auto-layout network nodes
    local function AutoLayoutNetwork(network, canvasWidth, canvasHeight)
        if not network or not network.layers then return end

        local layerCount = #network.layers
        local layerSpacing = (canvasWidth - 200) / math.max(1, layerCount - 1)

        for layerIdx, layer in ipairs(network.layers) do
            local neuronCount = #layer.neurons
            local neuronSpacing = (canvasHeight - 100) / math.max(1, neuronCount + 1)
            local x = 100 + (layerIdx - 1) * layerSpacing

            for neuronIdx, neuron in ipairs(layer.neurons) do
                neuron.x = x
                neuron.y = 50 + neuronIdx * neuronSpacing
            end
        end
    end

    -- Get color based on activation value
    local function GetActivationColor(activation)
        local a = math.Clamp(activation or 0, 0, 1)
        return Color(
            math.floor(255 * (1 - a)),
            math.floor(255 * a),
            50,
            255
        )
    end

    -- Get color based on weight value
    local function GetWeightColor(weight)
        local w = math.Clamp(weight or 0, -1, 1)
        if w >= 0 then
            return Color(50, math.floor(100 + 155 * w), 50, 150 + math.floor(105 * math.abs(w)))
        else
            return Color(math.floor(100 + 155 * math.abs(w)), 50, 50, 150 + math.floor(105 * math.abs(w)))
        end
    end

    -- Create the main frame
    local function CreateNeuralNetworkEditor()
        -- Forward declarations for functions used before definition
        local FindNodeById
        local UpdatePropertiesPanel
        local DrawNetwork

        local frame = vgui.Create("DFrame")
        frame:SetSize(ScrW() * 0.8, ScrH() * 0.8)
        frame:Center()
        frame:SetTitle("Neural Network Editor")
        frame:SetSizable(true)
        frame:MakePopup()

        -- Create a menu bar
        local menuBar = vgui.Create("DMenuBar", frame)
        menuBar:Dock(TOP)

        -- File menu
        local fileMenu = menuBar:AddMenu("File")
        fileMenu:AddOption("New Network", function()
            net.Start("RequestNeuralNetworkData")
            net.SendToServer()
        end)
        fileMenu:AddSpacer()

        -- Save Network submenu
        local saveSubMenu = fileMenu:AddSubMenu("Save Network")
        saveSubMenu:AddOption("Save to File...", function()
            Derma_StringRequest("Save Network", "Enter filename:", "network_" .. os.date("%Y%m%d_%H%M%S"),
                function(filename)
                    SaveNetworkToFile(filename)
                end, nil, "Save", "Cancel")
        end)
        saveSubMenu:AddOption("Quick Save (Overwrite)", function()
            if neuralNetworkData and neuralNetworkData.sourceClass then
                SaveNetworkToFile(neuralNetworkData.sourceClass .. "_network")
            else
                SaveNetworkToFile("quick_save_" .. os.date("%Y%m%d"))
            end
        end)

        -- Load Network submenu
        local loadSubMenu = fileMenu:AddSubMenu("Load Network")
        loadSubMenu:AddOption("Load from File...", function()
            local savedNetworks = GetSavedNetworks()
            if #savedNetworks == 0 then
                notification.AddLegacy("No saved networks found!", NOTIFY_ERROR, 2)
                return
            end

            local selectFrame = vgui.Create("DFrame")
            selectFrame:SetSize(300, 200)
            selectFrame:SetTitle("Load Network")
            selectFrame:Center()
            selectFrame:MakePopup()

            local list = vgui.Create("DListView", selectFrame)
            list:Dock(FILL)
            list:DockMargin(5, 5, 5, 35)
            list:AddColumn("Saved Networks")

            for _, name in ipairs(savedNetworks) do
                list:AddLine(name)
            end

            list.OnRowSelected = function(_, _, row)
                LoadNetworkFromFile(row:GetValue(1))
                selectFrame:Close()
                if networkCanvas then networkCanvas:InvalidateLayout(true) end
            end
        end)
        loadSubMenu:AddOption("Load from Selected NPC", function()
            if IsValid(selectedNPC) then
                LoadNetworkFromEntity(selectedNPC)
                if networkCanvas then networkCanvas:InvalidateLayout(true) end
            else
                notification.AddLegacy("No NPC selected! Use the NPC dropdown.", NOTIFY_ERROR, 2)
            end
        end)

        fileMenu:AddSpacer()

        -- Entity Weights submenu
        local entitySubMenu = fileMenu:AddSubMenu("Entity Weights")
        entitySubMenu:AddOption("Save NPC Weights to File...", function()
            if not IsValid(selectedNPC) then
                notification.AddLegacy("No NPC selected!", NOTIFY_ERROR, 2)
                return
            end
            if not selectedNPC.nn then
                notification.AddLegacy("Selected NPC has no neural network!", NOTIFY_ERROR, 2)
                return
            end
            Derma_StringRequest("Save Entity Weights", "Enter filename:",
                selectedNPC:GetClass() .. "_gen" .. (selectedNPC.nn.generation or 1),
                function(filename)
                    SaveEntityWeightsToFile(selectedNPC, filename)
                end, nil, "Save", "Cancel")
        end)
        entitySubMenu:AddOption("Load Weights from File...", function()
            local savedWeights = GetSavedEntityWeights()
            if #savedWeights == 0 then
                notification.AddLegacy("No saved entity weights found!", NOTIFY_ERROR, 2)
                return
            end

            local selectFrame = vgui.Create("DFrame")
            selectFrame:SetSize(300, 200)
            selectFrame:SetTitle("Load Entity Weights")
            selectFrame:Center()
            selectFrame:MakePopup()

            local list = vgui.Create("DListView", selectFrame)
            list:Dock(FILL)
            list:DockMargin(5, 5, 5, 35)
            list:AddColumn("Saved Weights")

            for _, name in ipairs(savedWeights) do
                list:AddLine(name)
            end

            list.OnRowSelected = function(_, _, row)
                -- Load the weights file and display info
                local filePath = 'zdev/neural_entity_weights/' .. row:GetValue(1) .. '.json'
                local jsonData = file.Read(filePath, 'DATA')
                if jsonData then
                    local weightData = util.JSONToTable(jsonData)
                    if weightData then
                        notification.AddLegacy("Loaded: " .. weightData.entityClass .. " Gen " .. (weightData.generation or 1), NOTIFY_GENERIC, 3)
                        -- Could extend to apply weights to selected NPC via networking
                    end
                end
                selectFrame:Close()
            end
        end)

        fileMenu:AddSpacer()
        fileMenu:AddOption("Exit", function() frame:Close() end)

        -- Edit menu
        local editMenu = menuBar:AddMenu("Edit")
        editMenu:AddOption("Undo", function() end)
        editMenu:AddOption("Redo", function() end)
        editMenu:AddSpacer()
        editMenu:AddOption("Cut", function() end)
        editMenu:AddOption("Copy", function() end)
        editMenu:AddOption("Paste", function() end)
        editMenu:AddSpacer()
        editMenu:AddOption("Preferences", function() end)

        -- View menu
        local viewMenu = menuBar:AddMenu("View")
        viewMenu:AddOption("Zoom In", function()
            canvasScale = canvasScale * 1.1
        end)
        viewMenu:AddOption("Zoom Out", function()
            canvasScale = canvasScale * 0.9
        end)
        viewMenu:AddOption("Reset Zoom", function()
            canvasScale = 1.0
        end)

        -- Create a horizontal divider for the main content
        local hDivider = vgui.Create("DHorizontalDivider", frame)
        hDivider:Dock(FILL)
        hDivider:SetDividerWidth(4)

        -- Left panel for network visualization (created without parent, assigned via SetLeft)
        visualizationPanel = vgui.Create("DPanel")
        visualizationPanel:SetBackgroundColor(Color(40, 40, 40))

        -- Create the network canvas
        networkCanvas = vgui.Create("DPanel", visualizationPanel)
        networkCanvas:Dock(FILL)
        networkCanvas:SetBackgroundColor(Color(30, 30, 30))
        canvasScale = 1.0
        canvasOffsetX = 0
        canvasOffsetY = 0

        -- Right panel for properties and controls (created without parent, assigned via SetRight)
        propertiesPanel = vgui.Create("DPanel")
        propertiesPanel:SetBackgroundColor(Color(50, 50, 50))

        -- Configure the divider
        hDivider:SetLeft(visualizationPanel)
        hDivider:SetRight(propertiesPanel)
        hDivider:SetLeftMin(200)
        hDivider:SetRightMin(200)
        hDivider:SetLeftWidth(frame:GetWide() * 0.7)

        -- Create properties panel content
        local propertiesSheet = vgui.Create("DPropertySheet", propertiesPanel)
        propertiesSheet:Dock(FILL)

        -- ============================================
        -- STRUCTURE TAB - Network Architecture Editor
        -- ============================================
        local structureProps = vgui.Create("DScrollPanel", propertiesSheet)
        structureProps:Dock(FILL)
        structureProps.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50))
        end

        local structureForm = vgui.Create("DForm", structureProps)
        structureForm:Dock(TOP)
        structureForm:SetName("Network Structure")

        -- Layer count display
        local layerCountLabel = vgui.Create("DLabel", structureForm)
        layerCountLabel:Dock(TOP)
        layerCountLabel:SetTall(24)
        layerCountLabel:SetText("Layers: 3")
        layerCountLabel:SetTextColor(color_white)

        -- Add Layer button
        local addLayerBtn = vgui.Create("DButton", structureForm)
        addLayerBtn:Dock(TOP)
        addLayerBtn:SetTall(28)
        addLayerBtn:SetText("+ Add Hidden Layer")
        addLayerBtn.DoClick = function()
            if neuralNetworkData and neuralNetworkData.layers then
                local newLayerIdx = #neuralNetworkData.layers
                local newLayer = {
                    type = "hidden",
                    neurons = {}
                }
                -- Add 4 neurons by default
                for i = 1, 4 do
                    table.insert(newLayer.neurons, {
                        id = GenerateNeuronId(newLayerIdx, i),
                        bias = math.Rand(-1, 1),
                        activation = 0,
                        x = 0, y = 0
                    })
                end
                -- Insert before output layer
                table.insert(neuralNetworkData.layers, newLayerIdx, newLayer)
                RebuildConnections(neuralNetworkData)
                AutoLayoutNetwork(neuralNetworkData, 800, 600)
                layerCountLabel:SetText("Layers: " .. #neuralNetworkData.layers)
                DrawNetwork()
            end
        end

        -- Remove Layer button
        local removeLayerBtn = vgui.Create("DButton", structureForm)
        removeLayerBtn:Dock(TOP)
        removeLayerBtn:SetTall(28)
        removeLayerBtn:SetText("- Remove Selected Layer")
        removeLayerBtn.DoClick = function()
            if selectedLayer and neuralNetworkData and #neuralNetworkData.layers > 2 then
                if selectedLayer.type ~= "input" and selectedLayer.type ~= "output" then
                    for i, layer in ipairs(neuralNetworkData.layers) do
                        if layer == selectedLayer then
                            table.remove(neuralNetworkData.layers, i)
                            break
                        end
                    end
                    selectedLayer = nil
                    RebuildConnections(neuralNetworkData)
                    AutoLayoutNetwork(neuralNetworkData, 800, 600)
                    layerCountLabel:SetText("Layers: " .. #neuralNetworkData.layers)
                    DrawNetwork()
                else
                    notification.AddLegacy("Cannot remove input/output layers", NOTIFY_ERROR, 2)
                end
            end
        end

        -- Neurons per layer section
        local neuronsLabel = vgui.Create("DLabel", structureForm)
        neuronsLabel:Dock(TOP)
        neuronsLabel:SetTall(24)
        neuronsLabel:SetText("Selected Layer Neurons:")
        neuronsLabel:SetTextColor(color_white)
        neuronsLabel:DockMargin(0, 10, 0, 0)

        local addNeuronBtn = vgui.Create("DButton", structureForm)
        addNeuronBtn:Dock(TOP)
        addNeuronBtn:SetTall(28)
        addNeuronBtn:SetText("+ Add Neuron to Layer")
        addNeuronBtn.DoClick = function()
            if selectedLayer then
                local neuronIdx = #selectedLayer.neurons + 1
                local layerIdx = 1
                for i, layer in ipairs(neuralNetworkData.layers) do
                    if layer == selectedLayer then layerIdx = i break end
                end
                table.insert(selectedLayer.neurons, {
                    id = GenerateNeuronId(layerIdx, neuronIdx),
                    bias = math.Rand(-1, 1),
                    activation = 0,
                    x = 0, y = 0
                })
                RebuildConnections(neuralNetworkData)
                AutoLayoutNetwork(neuralNetworkData, 800, 600)
                DrawNetwork()
            end
        end

        local removeNeuronBtn = vgui.Create("DButton", structureForm)
        removeNeuronBtn:Dock(TOP)
        removeNeuronBtn:SetTall(28)
        removeNeuronBtn:SetText("- Remove Selected Neuron")
        removeNeuronBtn.DoClick = function()
            if selectedNode and selectedLayer and #selectedLayer.neurons > 1 then
                for i, neuron in ipairs(selectedLayer.neurons) do
                    if neuron == selectedNode then
                        table.remove(selectedLayer.neurons, i)
                        break
                    end
                end
                selectedNode = nil
                RebuildConnections(neuralNetworkData)
                AutoLayoutNetwork(neuralNetworkData, 800, 600)
                DrawNetwork()
            end
        end

        -- Activation function
        local activationRow = vgui.Create("DPanel", structureForm)
        activationRow:Dock(TOP)
        activationRow:SetTall(32)
        activationRow:DockMargin(0, 10, 0, 0)
        activationRow.Paint = function() end

        local activationLabel = vgui.Create("DLabel", activationRow)
        activationLabel:SetText("Activation")
        activationLabel:SetWide(80)
        activationLabel:Dock(LEFT)
        activationLabel:SetTextColor(color_white)

        local activationCombo = vgui.Create("DComboBox", activationRow)
        activationCombo:Dock(FILL)
        activationCombo:AddChoice("Sigmoid")
        activationCombo:AddChoice("ReLU")
        activationCombo:AddChoice("Tanh")
        activationCombo.OnSelect = function(self, idx, val)
            if neuralNetworkData then
                neuralNetworkData.activationFunction = val
            end
        end
        activationCombo:SetValue("Sigmoid")

        -- Auto-layout button
        local autoLayoutBtn = vgui.Create("DButton", structureForm)
        autoLayoutBtn:Dock(TOP)
        autoLayoutBtn:SetTall(28)
        autoLayoutBtn:DockMargin(0, 10, 0, 0)
        autoLayoutBtn:SetText("Auto-Layout Network")
        autoLayoutBtn.DoClick = function()
            if neuralNetworkData then
                AutoLayoutNetwork(neuralNetworkData, 800, 600)
                DrawNetwork()
            end
        end

        -- ============================================
        -- TRAINING TAB - Training Controls & Metrics
        -- ============================================
        local trainingProps = vgui.Create("DScrollPanel", propertiesSheet)
        trainingProps:Dock(FILL)
        trainingProps.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50))
        end

        local trainingForm = vgui.Create("DForm", trainingProps)
        trainingForm:Dock(TOP)
        trainingForm:SetName("Training Controls")

        -- Training status
        local statusLabel = vgui.Create("DLabel", trainingForm)
        statusLabel:Dock(TOP)
        statusLabel:SetTall(24)
        statusLabel:SetText("Status: Idle")
        statusLabel:SetTextColor(Color(100, 255, 100))

        -- Epoch counter
        local epochLabel = vgui.Create("DLabel", trainingForm)
        epochLabel:Dock(TOP)
        epochLabel:SetTall(24)
        epochLabel:SetText("Epoch: 0 / 100")
        epochLabel:SetTextColor(color_white)

        -- Loss display
        local lossLabel = vgui.Create("DLabel", trainingForm)
        lossLabel:Dock(TOP)
        lossLabel:SetTall(24)
        lossLabel:SetText("Loss: 0.0000")
        lossLabel:SetTextColor(color_white)

        -- Accuracy display
        local accuracyLabel = vgui.Create("DLabel", trainingForm)
        accuracyLabel:Dock(TOP)
        accuracyLabel:SetTall(24)
        accuracyLabel:SetText("Accuracy: 0%")
        accuracyLabel:SetTextColor(color_white)

        -- Learning rate slider
        local lrRow = vgui.Create("DPanel", trainingForm)
        lrRow:Dock(TOP)
        lrRow:SetTall(32)
        lrRow:DockMargin(0, 10, 0, 0)
        lrRow.Paint = function() end

        local lrLabel = vgui.Create("DLabel", lrRow)
        lrLabel:SetText("Learn Rate")
        lrLabel:SetWide(70)
        lrLabel:Dock(LEFT)
        lrLabel:SetTextColor(color_white)

        local lrSlider = vgui.Create("DNumSlider", lrRow)
        lrSlider:Dock(FILL)
        lrSlider:SetMin(0.001)
        lrSlider:SetMax(1.0)
        lrSlider:SetDecimals(3)
        lrSlider:SetValue(0.1)
        lrSlider.OnValueChanged = function(self, val)
            trainingLearningRate = val
        end

        -- Max epochs slider
        local epochRow = vgui.Create("DPanel", trainingForm)
        epochRow:Dock(TOP)
        epochRow:SetTall(32)
        epochRow.Paint = function() end

        local epochRowLabel = vgui.Create("DLabel", epochRow)
        epochRowLabel:SetText("Max Epochs")
        epochRowLabel:SetWide(70)
        epochRowLabel:Dock(LEFT)
        epochRowLabel:SetTextColor(color_white)

        local epochSlider = vgui.Create("DNumSlider", epochRow)
        epochSlider:Dock(FILL)
        epochSlider:SetMin(10)
        epochSlider:SetMax(1000)
        epochSlider:SetDecimals(0)
        epochSlider:SetValue(100)
        epochSlider.OnValueChanged = function(self, val)
            trainingMaxEpochs = math.floor(val)
        end

        -- Training speed slider
        local speedRow = vgui.Create("DPanel", trainingForm)
        speedRow:Dock(TOP)
        speedRow:SetTall(32)
        speedRow.Paint = function() end

        local speedLabel = vgui.Create("DLabel", speedRow)
        speedLabel:SetText("Speed")
        speedLabel:SetWide(70)
        speedLabel:Dock(LEFT)
        speedLabel:SetTextColor(color_white)

        local speedSlider = vgui.Create("DNumSlider", speedRow)
        speedSlider:Dock(FILL)
        speedSlider:SetMin(0.01)
        speedSlider:SetMax(0.5)
        speedSlider:SetDecimals(2)
        speedSlider:SetValue(0.05)
        speedSlider.OnValueChanged = function(self, val)
            trainingSpeed = val
        end

        -- Training data section
        local dataLabel = vgui.Create("DLabel", trainingForm)
        dataLabel:Dock(TOP)
        dataLabel:SetTall(24)
        dataLabel:DockMargin(0, 10, 0, 0)
        dataLabel:SetText("Training Data: 0 samples")
        dataLabel:SetTextColor(color_white)

        -- Generate sample data button
        local genDataBtn = vgui.Create("DButton", trainingForm)
        genDataBtn:Dock(TOP)
        genDataBtn:SetTall(28)
        genDataBtn:SetText("Generate XOR Dataset")
        genDataBtn.DoClick = function()
            trainingData = {
                {inputs = {0, 0}, targets = {0}},
                {inputs = {0, 1}, targets = {1}},
                {inputs = {1, 0}, targets = {1}},
                {inputs = {1, 1}, targets = {0}}
            }
            dataLabel:SetText("Training Data: " .. #trainingData .. " samples")
            notification.AddLegacy("XOR dataset loaded", NOTIFY_GENERIC, 2)
        end

        -- Generate AND dataset
        local genAndBtn = vgui.Create("DButton", trainingForm)
        genAndBtn:Dock(TOP)
        genAndBtn:SetTall(28)
        genAndBtn:SetText("Generate AND Dataset")
        genAndBtn.DoClick = function()
            trainingData = {
                {inputs = {0, 0}, targets = {0}},
                {inputs = {0, 1}, targets = {0}},
                {inputs = {1, 0}, targets = {0}},
                {inputs = {1, 1}, targets = {1}}
            }
            dataLabel:SetText("Training Data: " .. #trainingData .. " samples")
            notification.AddLegacy("AND dataset loaded", NOTIFY_GENERIC, 2)
        end

        -- Start/Stop training buttons
        local startTrainBtn = vgui.Create("DButton", trainingForm)
        startTrainBtn:Dock(TOP)
        startTrainBtn:SetTall(32)
        startTrainBtn:DockMargin(0, 10, 0, 0)
        startTrainBtn:SetText("▶ Start Training")
        startTrainBtn:SetTextColor(Color(100, 255, 100))

        local stopTrainBtn = vgui.Create("DButton", trainingForm)
        stopTrainBtn:Dock(TOP)
        stopTrainBtn:SetTall(32)
        stopTrainBtn:SetText("■ Stop Training")
        stopTrainBtn:SetTextColor(Color(255, 100, 100))
        stopTrainBtn:SetEnabled(false)

        -- Training step function
        local function DoTrainingStep()
            if not isTraining or #trainingData == 0 then return end

            local totalLoss = 0
            local correct = 0

            for _, sample in ipairs(trainingData) do
                local loss = TrainStep(neuralNetworkData, sample.inputs, sample.targets, trainingLearningRate)
                totalLoss = totalLoss + loss

                -- Check accuracy
                local outputs = ForwardPass(neuralNetworkData, sample.inputs)
                local isCorrect = true
                for i, target in ipairs(sample.targets) do
                    if math.abs((outputs[i] or 0) - target) > 0.5 then
                        isCorrect = false
                        break
                    end
                end
                if isCorrect then correct = correct + 1 end
            end

            currentLoss = totalLoss / #trainingData
            currentAccuracy = (correct / #trainingData) * 100
            trainingEpoch = trainingEpoch + 1

            table.insert(trainingLossHistory, currentLoss)
            table.insert(trainingAccuracyHistory, currentAccuracy)

            -- Update UI
            epochLabel:SetText("Epoch: " .. trainingEpoch .. " / " .. trainingMaxEpochs)
            lossLabel:SetText(string.format("Loss: %.4f", currentLoss))
            accuracyLabel:SetText(string.format("Accuracy: %.1f%%", currentAccuracy))

            -- Redraw network with updated activations
            if networkCanvas then
                networkCanvas:InvalidateLayout(true)
            end

            -- Check if training complete
            if trainingEpoch >= trainingMaxEpochs then
                isTraining = false
                statusLabel:SetText("Status: Complete")
                statusLabel:SetTextColor(Color(100, 200, 255))
                startTrainBtn:SetEnabled(true)
                stopTrainBtn:SetEnabled(false)
                if trainingTimer then
                    timer.Remove("NNEditorTraining")
                    trainingTimer = nil
                end
                notification.AddLegacy("Training complete!", NOTIFY_GENERIC, 2)
            end
        end

        startTrainBtn.DoClick = function()
            if #trainingData == 0 then
                notification.AddLegacy("No training data loaded!", NOTIFY_ERROR, 2)
                return
            end
            isTraining = true
            trainingEpoch = 0
            trainingLossHistory = {}
            trainingAccuracyHistory = {}
            statusLabel:SetText("Status: Training...")
            statusLabel:SetTextColor(Color(255, 200, 100))
            startTrainBtn:SetEnabled(false)
            stopTrainBtn:SetEnabled(true)

            timer.Create("NNEditorTraining", trainingSpeed, 0, DoTrainingStep)
            trainingTimer = true
        end

        stopTrainBtn.DoClick = function()
            isTraining = false
            statusLabel:SetText("Status: Stopped")
            statusLabel:SetTextColor(Color(255, 100, 100))
            startTrainBtn:SetEnabled(true)
            stopTrainBtn:SetEnabled(false)
            if trainingTimer then
                timer.Remove("NNEditorTraining")
                trainingTimer = nil
            end
        end

        -- Reset weights button
        local resetBtn = vgui.Create("DButton", trainingForm)
        resetBtn:Dock(TOP)
        resetBtn:SetTall(28)
        resetBtn:DockMargin(0, 10, 0, 0)
        resetBtn:SetText("Reset Weights")
        resetBtn.DoClick = function()
            if neuralNetworkData and neuralNetworkData.connections then
                for _, conn in ipairs(neuralNetworkData.connections) do
                    conn.weight = math.Rand(-1, 1)
                end
                for _, layer in ipairs(neuralNetworkData.layers or {}) do
                    for _, neuron in ipairs(layer.neurons) do
                        neuron.bias = math.Rand(-1, 1)
                        neuron.activation = 0
                    end
                end
                trainingEpoch = 0
                trainingLossHistory = {}
                trainingAccuracyHistory = {}
                epochLabel:SetText("Epoch: 0 / " .. trainingMaxEpochs)
                lossLabel:SetText("Loss: 0.0000")
                accuracyLabel:SetText("Accuracy: 0%")
                DrawNetwork()
                notification.AddLegacy("Weights reset", NOTIFY_GENERIC, 2)
            end
        end

        -- ============================================
        -- VISUALIZATION TAB - Display Options
        -- ============================================
        local vizProps = vgui.Create("DScrollPanel", propertiesSheet)
        vizProps:Dock(FILL)
        vizProps.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50))
        end

        local vizForm = vgui.Create("DForm", vizProps)
        vizForm:Dock(TOP)
        vizForm:SetName("Visualization Options")

        -- Show activations checkbox
        local showActCheck = vgui.Create("DCheckBoxLabel", vizForm)
        showActCheck:Dock(TOP)
        showActCheck:SetTall(24)
        showActCheck:SetText("Show Activation Colors")
        showActCheck:SetTextColor(color_white)
        showActCheck:SetValue(true)
        showActCheck.OnChange = function(self, val)
            showActivations = val
            if networkCanvas then networkCanvas:InvalidateLayout(true) end
        end

        -- Show weight colors checkbox
        local showWeightCheck = vgui.Create("DCheckBoxLabel", vizForm)
        showWeightCheck:Dock(TOP)
        showWeightCheck:SetTall(24)
        showWeightCheck:SetText("Show Weight Colors")
        showWeightCheck:SetTextColor(color_white)
        showWeightCheck:SetValue(true)
        showWeightCheck.OnChange = function(self, val)
            showWeightColors = val
            if networkCanvas then networkCanvas:InvalidateLayout(true) end
        end

        -- Node radius slider
        local radiusRow = vgui.Create("DPanel", vizForm)
        radiusRow:Dock(TOP)
        radiusRow:SetTall(32)
        radiusRow:DockMargin(0, 10, 0, 0)
        radiusRow.Paint = function() end

        local radiusLabel = vgui.Create("DLabel", radiusRow)
        radiusLabel:SetText("Node Size")
        radiusLabel:SetWide(70)
        radiusLabel:Dock(LEFT)
        radiusLabel:SetTextColor(color_white)

        local radiusSlider = vgui.Create("DNumSlider", radiusRow)
        radiusSlider:Dock(FILL)
        radiusSlider:SetMin(10)
        radiusSlider:SetMax(40)
        radiusSlider:SetDecimals(0)
        radiusSlider:SetValue(20)
        radiusSlider.OnValueChanged = function(self, val)
            nodeRadius = val
            if networkCanvas then networkCanvas:InvalidateLayout(true) end
        end

        -- Loss graph panel
        local graphLabel = vgui.Create("DLabel", vizForm)
        graphLabel:Dock(TOP)
        graphLabel:SetTall(24)
        graphLabel:DockMargin(0, 10, 0, 0)
        graphLabel:SetText("Training Loss Graph:")
        graphLabel:SetTextColor(color_white)

        local lossGraph = vgui.Create("DPanel", vizForm)
        lossGraph:Dock(TOP)
        lossGraph:SetTall(120)
        lossGraph:DockMargin(0, 5, 0, 0)
        lossGraph.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))

            if #trainingLossHistory > 1 then
                local maxLoss = 0.001
                for _, loss in ipairs(trainingLossHistory) do
                    maxLoss = math.max(maxLoss, loss)
                end

                surface.SetDrawColor(100, 200, 100)
                local prevX, prevY = 0, h
                for i, loss in ipairs(trainingLossHistory) do
                    local x = (i - 1) / math.max(1, #trainingLossHistory - 1) * w
                    local y = h - (loss / maxLoss) * (h - 10)
                    if i > 1 then
                        surface.DrawLine(prevX, prevY, x, y)
                    end
                    prevX, prevY = x, y
                end
            else
                draw.SimpleText("No data", "DermaDefault", w/2, h/2, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        -- ============================================
        -- NODE PROPERTIES TAB
        -- ============================================
        local nodeProps = vgui.Create("DScrollPanel", propertiesSheet)
        nodeProps:Dock(FILL)
        nodeProps.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50))
        end

        local nodeForm = vgui.Create("DForm", nodeProps)
        nodeForm:Dock(TOP)
        nodeForm:SetName("Node Properties")

        local nodeIdLabel = vgui.Create("DLabel", nodeForm)
        nodeIdLabel:Dock(TOP)
        nodeIdLabel:SetTall(24)
        nodeIdLabel:SetText("Node: (none selected)")
        nodeIdLabel:SetTextColor(color_white)

        local nodeTypeLabel = vgui.Create("DLabel", nodeForm)
        nodeTypeLabel:Dock(TOP)
        nodeTypeLabel:SetTall(24)
        nodeTypeLabel:SetText("Type: -")
        nodeTypeLabel:SetTextColor(color_white)

        -- Bias slider
        local biasRow = vgui.Create("DPanel", nodeForm)
        biasRow:Dock(TOP)
        biasRow:SetTall(32)
        biasRow:DockMargin(0, 10, 0, 0)
        biasRow.Paint = function() end

        local biasLabel = vgui.Create("DLabel", biasRow)
        biasLabel:SetText("Bias")
        biasLabel:SetWide(70)
        biasLabel:Dock(LEFT)
        biasLabel:SetTextColor(color_white)

        local biasSlider = vgui.Create("DNumSlider", biasRow)
        biasSlider:Dock(FILL)
        biasSlider:SetMin(-5)
        biasSlider:SetMax(5)
        biasSlider:SetDecimals(3)
        biasSlider:SetValue(0)
        biasSlider.OnValueChanged = function(self, val)
            if selectedNode then
                selectedNode.bias = val
            end
        end

        -- Activation display
        local actRow = vgui.Create("DPanel", nodeForm)
        actRow:Dock(TOP)
        actRow:SetTall(32)
        actRow.Paint = function() end

        local actLabel = vgui.Create("DLabel", actRow)
        actLabel:SetText("Activation")
        actLabel:SetWide(70)
        actLabel:Dock(LEFT)
        actLabel:SetTextColor(color_white)

        local activationSlider = vgui.Create("DNumSlider", actRow)
        activationSlider:Dock(FILL)
        activationSlider:SetMin(0)
        activationSlider:SetMax(1)
        activationSlider:SetDecimals(4)
        activationSlider:SetValue(0)
        activationSlider:SetEnabled(false)

        -- ============================================
        -- CONNECTION PROPERTIES TAB
        -- ============================================
        local connectionProps = vgui.Create("DScrollPanel", propertiesSheet)
        connectionProps:Dock(FILL)
        connectionProps.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50))
        end

        local connectionForm = vgui.Create("DForm", connectionProps)
        connectionForm:Dock(TOP)
        connectionForm:SetName("Connection Properties")

        local connFromLabel = vgui.Create("DLabel", connectionForm)
        connFromLabel:Dock(TOP)
        connFromLabel:SetTall(24)
        connFromLabel:SetText("From: -")
        connFromLabel:SetTextColor(color_white)

        local connToLabel = vgui.Create("DLabel", connectionForm)
        connToLabel:Dock(TOP)
        connToLabel:SetTall(24)
        connToLabel:SetText("To: -")
        connToLabel:SetTextColor(color_white)

        -- Weight slider
        local weightRow = vgui.Create("DPanel", connectionForm)
        weightRow:Dock(TOP)
        weightRow:SetTall(32)
        weightRow:DockMargin(0, 10, 0, 0)
        weightRow.Paint = function() end

        local weightLabel = vgui.Create("DLabel", weightRow)
        weightLabel:SetText("Weight")
        weightLabel:SetWide(70)
        weightLabel:Dock(LEFT)
        weightLabel:SetTextColor(color_white)

        local weightSlider = vgui.Create("DNumSlider", weightRow)
        weightSlider:Dock(FILL)
        weightSlider:SetMin(-5)
        weightSlider:SetMax(5)
        weightSlider:SetDecimals(3)
        weightSlider:SetValue(0)
        weightSlider.OnValueChanged = function(self, val)
            if selectedConnection then
                selectedConnection.weight = val
            end
        end

        -- Add tabs to the property sheet
        propertiesSheet:AddSheet("Structure", structureProps, "icon16/chart_organisation.png")
        propertiesSheet:AddSheet("Training", trainingProps, "icon16/arrow_refresh.png")
        propertiesSheet:AddSheet("Visualization", vizProps, "icon16/eye.png")
        propertiesSheet:AddSheet("Node", nodeProps, "icon16/shape_square.png")
        propertiesSheet:AddSheet("Connection", connectionProps, "icon16/arrow_switch.png")

        -- Create a toolbar at the bottom using DPanel with DImageButton elements
        local toolbar = vgui.Create("DPanel", frame)
        toolbar:Dock(BOTTOM)
        toolbar:SetTall(40)
        toolbar:SetBackgroundColor(Color(45, 45, 45))

        local function AddToolbarButton(icon, tooltip, callback)
            local btn = vgui.Create("DImageButton", toolbar)
            btn:SetImage(icon)
            btn:SetSize(24, 24)
            btn:Dock(LEFT)
            btn:DockMargin(4, 8, 0, 8)
            btn:SetTooltip(tooltip)
            btn.DoClick = callback
            return btn
        end

        AddToolbarButton("icon16/application_add.png", "New Network", function()
            net.Start("RequestNeuralNetworkData")
            net.SendToServer()
        end)

        AddToolbarButton("icon16/disk.png", "Save Network", function()
            Derma_StringRequest("Save Neural Network", "Enter filename:", "network_" .. os.date("%Y%m%d_%H%M%S"),
                function(filename)
                    SaveNetworkToFile(filename)
                end
            )
        end)

        AddToolbarButton("icon16/folder.png", "Load Network", function()
            local networks = GetSavedNetworks()
            if #networks == 0 then
                notification.AddLegacy("No saved networks found!", NOTIFY_ERROR, 2)
                return
            end
            local menu = DermaMenu()
            for _, networkName in ipairs(networks) do
                menu:AddOption(networkName, function()
                    LoadNetworkFromFile(networkName)
                    if networkCanvas then networkCanvas:InvalidateLayout(true) end
                end)
            end
            menu:Open()
        end)

        AddToolbarButton("icon16/arrow_switch.png", "Train Network", function()
            notification.AddLegacy("Use Training tab to start training", NOTIFY_HINT, 2)
        end)

        -- Separator
        local sep1 = vgui.Create("DPanel", toolbar)
        sep1:SetWide(2)
        sep1:Dock(LEFT)
        sep1:DockMargin(8, 4, 8, 4)
        sep1.Paint = function(self, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(80, 80, 80)) end

        -- Visualization mode selector
        local vizLabel = vgui.Create("DLabel", toolbar)
        vizLabel:SetText("View:")
        vizLabel:SetWide(35)
        vizLabel:Dock(LEFT)
        vizLabel:DockMargin(4, 0, 0, 0)
        vizLabel:SetTextColor(color_white)
        vizLabel:SetContentAlignment(5)

        local vizCombo = vgui.Create("DComboBox", toolbar)
        vizCombo:SetWide(120)
        vizCombo:Dock(LEFT)
        vizCombo:DockMargin(4, 8, 0, 8)
        vizCombo:AddChoice("Network Graph", "network")
        vizCombo:AddChoice("Loss Curve", "loss")
        vizCombo:AddChoice("Accuracy", "accuracy")
        vizCombo:AddChoice("Weight Heatmap", "weights")
        vizCombo:AddChoice("Real-Time NPC", "realtime")
        vizCombo:ChooseOption("Network Graph", 1)
        vizCombo.OnSelect = function(self, index, value, data)
            visualizationMode = data
            if data == "realtime" then
                realTimeMode = true
            else
                realTimeMode = false
            end
            if networkCanvas then networkCanvas:InvalidateLayout(true) end
        end

        -- Separator
        local sep2 = vgui.Create("DPanel", toolbar)
        sep2:SetWide(2)
        sep2:Dock(LEFT)
        sep2:DockMargin(8, 4, 8, 4)
        sep2.Paint = function(self, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(80, 80, 80)) end

        -- NPC selector for real-time mode
        local npcLabel = vgui.Create("DLabel", toolbar)
        npcLabel:SetText("NPC:")
        npcLabel:SetWide(30)
        npcLabel:Dock(LEFT)
        npcLabel:DockMargin(4, 0, 0, 0)
        npcLabel:SetTextColor(color_white)
        npcLabel:SetContentAlignment(5)

        local npcSelector = vgui.Create("DComboBox", toolbar)
        npcSelector:SetWide(150)
        npcSelector:Dock(LEFT)
        npcSelector:DockMargin(4, 8, 0, 8)
        npcSelector:SetValue("Select NPC...")
        npcSelector.OnSelect = function(self, index, value, data)
            selectedNPC = data
            if IsValid(data) then
                notification.AddLegacy("Selected NPC: " .. data:GetClass(), NOTIFY_GENERIC, 2)
            end
        end

        -- Refresh NPC list button
        AddToolbarButton("icon16/arrow_refresh.png", "Refresh NPC List", function()
            npcSelector:Clear()
            npcSelector:AddChoice("Select NPC...", nil)
            local count = 0
            for _, ent in ipairs(ents.GetAll()) do
                if IsValid(ent) and IsNeuralEntity(ent) then
                    local archType = GetNeuralEntityType(ent)
                    local displayName = string.format("%s [%s]", ent:GetClass(), archType)
                    npcSelector:AddChoice(displayName, ent)
                    count = count + 1
                end
            end
            notification.AddLegacy("Found " .. count .. " neural entities", NOTIFY_GENERIC, 2)
        end)

        -- Add a status bar
        local statusBar = vgui.Create("DPanel", frame)
        statusBar:Dock(BOTTOM)
        statusBar:SetTall(20)
        statusBar:SetBackgroundColor(Color(60, 60, 60))

        local statusLabel = vgui.Create("DLabel", statusBar)
        statusLabel:Dock(FILL)
        statusLabel:SetText("Ready")
        statusLabel:SetContentAlignment(4)
        statusLabel:SetTextColor(Color(200, 200, 200))

        -- Visualization drawing functions
        local function DrawNetworkGraph(w, h)
            -- Draw network connections
            if neuralNetworkData and neuralNetworkData.connections then
                for _, conn in ipairs(neuralNetworkData.connections) do
                    local fromNode = FindNodeById(conn.from)
                    local toNode = FindNodeById(conn.to)

                    if fromNode and toNode then
                        local fromX = (fromNode.x + nodeRadius) * canvasScale + canvasOffsetX
                        local fromY = (fromNode.y + nodeRadius) * canvasScale + canvasOffsetY
                        local toX = (toNode.x + nodeRadius) * canvasScale + canvasOffsetX
                        local toY = (toNode.y + nodeRadius) * canvasScale + canvasOffsetY

                        -- Draw connection line with weight coloring
                        local connColor = connectionColor
                        if showWeightColors and conn.weight then
                            local intensity = math.Clamp(math.abs(conn.weight) * 255, 50, 255)
                            if conn.weight > 0 then
                                connColor = Color(0, intensity, 0, 200)
                            else
                                connColor = Color(intensity, 0, 0, 200)
                            end
                        end
                        surface.SetDrawColor(conn == selectedConnection and selectedColor or connColor)
                        surface.DrawLine(fromX, fromY, toX, toY)

                        -- Draw weight indicator
                        local midX = (fromX + toX) / 2
                        local midY = (fromY + toY) / 2
                        local weight = conn.weight or 0
                        local weightText = string.format("%.2f", weight)
                        draw.SimpleText(weightText, "DermaDefault", midX, midY, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
            end

            -- Draw network nodes
            if neuralNetworkData and neuralNetworkData.layers then
                for _, layer in ipairs(neuralNetworkData.layers) do
                    for _, neuron in ipairs(layer.neurons) do
                        local x = (neuron.x + nodeRadius) * canvasScale + canvasOffsetX
                        local y = (neuron.y + nodeRadius) * canvasScale + canvasOffsetY
                        local radius = nodeRadius * canvasScale

                        -- Draw node with activation coloring
                        local nodeColor = nodeColors[layer.type] or Color(150, 150, 150)
                        if showActivations and neuron.activation then
                            local actIntensity = math.Clamp(neuron.activation * 255, 0, 255)
                            nodeColor = Color(actIntensity, actIntensity, 255, 255)
                        end
                        surface.SetDrawColor(nodeColor)
                        surface.DrawCircle(x, y, radius, nodeColor)

                        -- Draw node ID
                        draw.SimpleText(neuron.id, "DermaDefault", x, y, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                        -- Highlight selected node
                        if neuron == selectedNode then
                            surface.SetDrawColor(selectedColor)
                            surface.DrawCircle(x, y, radius + 2, selectedColor)
                        end
                    end
                end
            end
        end

        local function DrawLossChart(w, h)
            draw.SimpleText("Loss History", "DermaDefaultBold", w/2, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER)

            if #trainingLossHistory < 2 then
                draw.SimpleText("No training data yet. Start training to see loss curve.", "DermaDefault", w/2, h/2, Color(150, 150, 150), TEXT_ALIGN_CENTER)
                return
            end

            local margin = 60
            local graphW = w - margin * 2
            local graphH = h - margin * 2

            -- Draw axes
            surface.SetDrawColor(100, 100, 100)
            surface.DrawLine(margin, margin, margin, h - margin)
            surface.DrawLine(margin, h - margin, w - margin, h - margin)

            -- Find min/max loss
            local minLoss, maxLoss = math.huge, -math.huge
            for _, loss in ipairs(trainingLossHistory) do
                minLoss = math.min(minLoss, loss)
                maxLoss = math.max(maxLoss, loss)
            end
            if maxLoss == minLoss then maxLoss = minLoss + 0.1 end

            -- Draw loss curve
            surface.SetDrawColor(255, 100, 100)
            for i = 2, #trainingLossHistory do
                local x1 = margin + (i - 2) * graphW / math.max(1, #trainingLossHistory - 1)
                local y1 = h - margin - ((trainingLossHistory[i-1] - minLoss) / (maxLoss - minLoss)) * graphH
                local x2 = margin + (i - 1) * graphW / math.max(1, #trainingLossHistory - 1)
                local y2 = h - margin - ((trainingLossHistory[i] - minLoss) / (maxLoss - minLoss)) * graphH
                surface.DrawLine(x1, y1, x2, y2)
            end

            -- Draw labels
            draw.SimpleText(string.format("%.4f", maxLoss), "DermaDefault", margin - 5, margin, Color(200, 200, 200), TEXT_ALIGN_RIGHT)
            draw.SimpleText(string.format("%.4f", minLoss), "DermaDefault", margin - 5, h - margin, Color(200, 200, 200), TEXT_ALIGN_RIGHT)
            draw.SimpleText("Epoch 0", "DermaDefault", margin, h - margin + 15, Color(200, 200, 200), TEXT_ALIGN_CENTER)
            draw.SimpleText("Epoch " .. #trainingLossHistory, "DermaDefault", w - margin, h - margin + 15, Color(200, 200, 200), TEXT_ALIGN_CENTER)
            draw.SimpleText(string.format("Current Loss: %.6f", currentLoss), "DermaDefault", w/2, h - 20, Color(255, 200, 100), TEXT_ALIGN_CENTER)
        end

        local function DrawAccuracyChart(w, h)
            draw.SimpleText("Accuracy History", "DermaDefaultBold", w/2, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER)

            if #trainingAccuracyHistory < 2 then
                draw.SimpleText("No training data yet. Start training to see accuracy curve.", "DermaDefault", w/2, h/2, Color(150, 150, 150), TEXT_ALIGN_CENTER)
                return
            end

            local margin = 60
            local graphW = w - margin * 2
            local graphH = h - margin * 2

            -- Draw axes
            surface.SetDrawColor(100, 100, 100)
            surface.DrawLine(margin, margin, margin, h - margin)
            surface.DrawLine(margin, h - margin, w - margin, h - margin)

            -- Draw accuracy curve (0-100%)
            surface.SetDrawColor(100, 255, 100)
            for i = 2, #trainingAccuracyHistory do
                local x1 = margin + (i - 2) * graphW / math.max(1, #trainingAccuracyHistory - 1)
                local y1 = h - margin - (trainingAccuracyHistory[i-1] / 100) * graphH
                local x2 = margin + (i - 1) * graphW / math.max(1, #trainingAccuracyHistory - 1)
                local y2 = h - margin - (trainingAccuracyHistory[i] / 100) * graphH
                surface.DrawLine(x1, y1, x2, y2)
            end

            -- Draw labels
            draw.SimpleText("100%", "DermaDefault", margin - 5, margin, Color(200, 200, 200), TEXT_ALIGN_RIGHT)
            draw.SimpleText("0%", "DermaDefault", margin - 5, h - margin, Color(200, 200, 200), TEXT_ALIGN_RIGHT)
            draw.SimpleText("Epoch 0", "DermaDefault", margin, h - margin + 15, Color(200, 200, 200), TEXT_ALIGN_CENTER)
            draw.SimpleText("Epoch " .. #trainingAccuracyHistory, "DermaDefault", w - margin, h - margin + 15, Color(200, 200, 200), TEXT_ALIGN_CENTER)
            draw.SimpleText(string.format("Current Accuracy: %.2f%%", currentAccuracy), "DermaDefault", w/2, h - 20, Color(100, 255, 100), TEXT_ALIGN_CENTER)
        end

        local function DrawWeightHeatmap(w, h)
            draw.SimpleText("Weight Heatmap", "DermaDefaultBold", w/2, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER)

            if not neuralNetworkData or not neuralNetworkData.connections or #neuralNetworkData.connections == 0 then
                draw.SimpleText("No network data available.", "DermaDefault", w/2, h/2, Color(150, 150, 150), TEXT_ALIGN_CENTER)
                return
            end

            local margin = 60
            local numConns = #neuralNetworkData.connections
            local cellSize = math.min((w - margin * 2) / math.ceil(math.sqrt(numConns)), 30)
            local cols = math.floor((w - margin * 2) / cellSize)

            for i, conn in ipairs(neuralNetworkData.connections) do
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)
                local x = margin + col * cellSize
                local y = margin + 30 + row * cellSize

                local weight = conn.weight or 0
                local intensity = math.Clamp(math.abs(weight) * 255, 0, 255)
                local color = weight > 0 and Color(0, intensity, 0) or Color(intensity, 0, 0)

                surface.SetDrawColor(color)
                surface.DrawRect(x, y, cellSize - 2, cellSize - 2)
                surface.SetDrawColor(80, 80, 80)
                surface.DrawOutlinedRect(x, y, cellSize - 2, cellSize - 2)
            end

            draw.SimpleText("Green = Positive, Red = Negative, Intensity = Magnitude", "DermaDefault", w/2, h - 30, Color(200, 200, 200), TEXT_ALIGN_CENTER)
        end

        local function DrawRealTimeVisualization(w, h)
            if not IsValid(selectedNPC) then
                draw.SimpleText("Real-Time Neural Network Visualizer", "DermaDefaultBold", w/2, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER)
                draw.SimpleText("Select an NPC from the dropdown to begin visualization", "DermaDefault", w/2, 60, Color(200, 200, 200), TEXT_ALIGN_CENTER)

                -- Show available NPCs using the new detection
                local y = 100
                draw.SimpleText("Available Neural Entities:", "DermaDefault", 50, y, Color(255, 255, 255))
                y = y + 25

                for _, ent in ipairs(ents.GetAll()) do
                    if IsValid(ent) and IsNeuralEntity(ent) then
                        local archType = GetNeuralEntityType(ent)
                        local npcInfo = string.format("%s [%s] - %s", ent:GetClass(), archType, ent:GetModel())
                        draw.SimpleText("• " .. npcInfo, "DermaDefault", 70, y, Color(150, 255, 150))
                        y = y + 20
                        if y > h - 50 then break end
                    end
                end
                return
            end

            local data = npcNetworkData
            if not data or not data.architecture then
                CollectNPCNetworkData()
                data = npcNetworkData
            end

            if not data or not data.architecture then
                draw.SimpleText("Collecting data from NPC...", "DermaDefault", w/2, h/2, Color(200, 200, 200), TEXT_ALIGN_CENTER)
                return
            end

            -- Header
            draw.SimpleText("Real-Time: " .. selectedNPC:GetClass(), "DermaDefaultBold", w/2, 10, Color(100, 255, 100), TEXT_ALIGN_CENTER)
            draw.SimpleText("Architecture: " .. data.architecture, "DermaDefault", w/2, 30, Color(255, 255, 100), TEXT_ALIGN_CENTER)
            if data.current_behavior then
                draw.SimpleText("Current Behavior: " .. tostring(data.current_behavior), "DermaDefault", w/2, 45, Color(200, 255, 200), TEXT_ALIGN_CENTER)
            end

            -- Draw network visualization based on architecture
            if data.architecture:find("Advanced") then
                -- Draw advanced network sections
                local sections = {
                    {name = "Visual Input", value = data.neurons.visual_input or 0, x = 50, color = Color(100, 255, 100)},
                    {name = "Vector Input", value = data.neurons.vector_input or 0, x = 150, color = Color(100, 255, 100)},
                    {name = "Conv Filters", value = (data.neurons.conv1_filters or 0) + (data.neurons.conv2_filters or 0), x = 250, color = Color(100, 150, 255)},
                    {name = "LSTM Units", value = data.neurons.lstm_units or 0, x = 350, color = Color(255, 150, 100)},
                    {name = "FC Units", value = data.neurons.fc_units or 0, x = 450, color = Color(150, 255, 150)},
                    {name = "Actions", value = data.neurons.action_output or 0, x = 550, color = Color(255, 100, 100)},
                    {name = "Value", value = data.neurons.value_output or 0, x = 650, color = Color(255, 100, 100)}
                }

                for _, section in ipairs(sections) do
                    if section.x > w - 100 then break end
                    draw.SimpleText(section.name, "DermaDefault", section.x, 70, Color(255, 255, 255), TEXT_ALIGN_CENTER)
                    draw.SimpleText(tostring(section.value), "DermaDefault", section.x, 85, section.color, TEXT_ALIGN_CENTER)

                    local rectHeight = math.min(h - 200, section.value * 3)
                    surface.SetDrawColor(section.color.r, section.color.g, section.color.b, 100)
                    surface.DrawRect(section.x - 20, 100, 40, rectHeight)
                    surface.SetDrawColor(section.color.r, section.color.g, section.color.b, 200)
                    surface.DrawOutlinedRect(section.x - 20, 100, 40, rectHeight)
                end
            elseif data.architecture:find("Neural SNPC") or data.architecture:find("Neural NextBot") then
                -- Draw neural SNPC/NextBot visualization with labels
                local inputCount = data.neurons.input or 0
                local hiddenCount = data.neurons.hidden or 0
                local outputCount = data.neurons.output or 0
                local hiddenLayers = data.hiddenLayers or 1

                local layerSpacing = (w - 160) / (2 + hiddenLayers)
                local nr = 8
                local startY = 80

                -- Input layer with labels
                local inputX = 80
                draw.SimpleText("Input (" .. inputCount .. ")", "DermaDefaultBold", inputX, startY - 20, Color(100, 255, 100), TEXT_ALIGN_CENTER)
                for i = 1, math.min(inputCount, 12) do
                    local nodeY = startY + (i - 1) * 28
                    surface.SetDrawColor(npcColors.neuron_input)
                    draw.RoundedBox(4, inputX - nr, nodeY - nr, nr * 2, nr * 2, npcColors.neuron_input)
                    -- Draw input label
                    local label = data.inputLabels and data.inputLabels[i] or ("In " .. i)
                    draw.SimpleText(label, "DermaDefault", inputX + nr + 5, nodeY, Color(200, 255, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end

                -- Hidden layers
                for hl = 1, hiddenLayers do
                    local hiddenX = inputX + hl * layerSpacing
                    local displayNodes = math.min(hiddenCount, 16)
                    draw.SimpleText("Hidden " .. hl, "DermaDefaultBold", hiddenX, startY - 20, Color(100, 150, 255), TEXT_ALIGN_CENTER)
                    for i = 1, displayNodes do
                        local nodeY = startY + (i - 1) * 20
                        surface.SetDrawColor(npcColors.neuron_active)
                        draw.RoundedBox(4, hiddenX - nr/2, nodeY - nr/2, nr, nr, npcColors.neuron_active)
                    end
                    if hiddenCount > displayNodes then
                        draw.SimpleText("+" .. (hiddenCount - displayNodes), "DermaDefault", hiddenX, startY + displayNodes * 20, Color(150, 150, 150), TEXT_ALIGN_CENTER)
                    end
                end

                -- Output layer with labels
                local outputX = inputX + (hiddenLayers + 1) * layerSpacing
                draw.SimpleText("Output (" .. outputCount .. ")", "DermaDefaultBold", outputX, startY - 20, Color(255, 100, 100), TEXT_ALIGN_CENTER)
                for i = 1, outputCount do
                    local nodeY = startY + (i - 1) * 35
                    surface.SetDrawColor(npcColors.neuron_output)
                    draw.RoundedBox(4, outputX - nr, nodeY - nr, nr * 2, nr * 2, npcColors.neuron_output)
                    -- Draw output label
                    local label = data.outputLabels and data.outputLabels[i] or ("Out " .. i)
                    draw.SimpleText(label, "DermaDefault", outputX + nr + 5, nodeY, Color(255, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end

                -- Draw connection lines (simplified)
                surface.SetDrawColor(80, 80, 120, 100)
                for i = 1, math.min(inputCount, 8) do
                    local fromY = startY + (i - 1) * 28
                    local hiddenX = inputX + layerSpacing
                    for j = 1, math.min(hiddenCount, 8) do
                        local toY = startY + (j - 1) * 20
                        surface.DrawLine(inputX + nr, fromY, hiddenX - nr/2, toY)
                    end
                end
            else
                -- Draw simple network (legacy/compressed/generic)
                if data.neurons and data.neurons.input then
                    local layers = {data.neurons.input, data.neurons.hidden, data.neurons.output}
                    local layerNames = {"Input", "Hidden", "Output"}
                    local layerSpacing = (w - 100) / 2
                    local nr = 6

                    for layerIdx, layerSize in ipairs(layers) do
                        local x = 50 + (layerIdx - 1) * layerSpacing
                        local layerColor = layerIdx == 1 and npcColors.neuron_input or
                                           layerIdx == 3 and npcColors.neuron_output or
                                           npcColors.neuron_active

                        draw.SimpleText(layerNames[layerIdx] .. " (" .. layerSize .. ")", "DermaDefault", x, 70, Color(255, 255, 255), TEXT_ALIGN_CENTER)

                        for nodeIdx = 1, math.min(layerSize, 20) do
                            local nodeY = 95 + (nodeIdx - 1) * 15
                            surface.SetDrawColor(layerColor)
                            draw.RoundedBox(nr/2, x - nr/2, nodeY - nr/2, nr, nr, layerColor)
                        end
                        if layerSize > 20 then
                            draw.SimpleText("+" .. (layerSize - 20) .. " more", "DermaDefault", x, 95 + 20 * 15, Color(150, 150, 150), TEXT_ALIGN_CENTER)
                        end
                    end
                end
            end

            -- Performance metrics at bottom
            local startY = h - 100
            draw.RoundedBox(4, 5, startY - 5, w - 10, 95, Color(30, 30, 40, 200))
            draw.SimpleText("Performance Metrics:", "DermaDefaultBold", 10, startY, Color(255, 255, 255))

            local metricX = 10
            local metricY = startY + 18

            if data.performance then
                -- Generation and fitness for neural entities
                if data.performance.generation then
                    draw.SimpleText("Generation: " .. tostring(data.performance.generation), "DermaDefault", metricX, metricY, Color(200, 200, 255))
                    metricX = metricX + 120
                end
                if data.performance.fitness then
                    draw.SimpleText("Fitness: " .. string.format("%.2f", data.performance.fitness), "DermaDefault", metricX, metricY, Color(100, 255, 100))
                    metricX = metricX + 100
                end
                if data.performance.isTraining ~= nil then
                    local trainColor = data.performance.isTraining and Color(100, 255, 100) or Color(255, 150, 100)
                    draw.SimpleText("Training: " .. (data.performance.isTraining and "Yes" or "No"), "DermaDefault", metricX, metricY, trainColor)
                    metricX = metricX + 100
                end
                if data.performance.learning_rate then
                    draw.SimpleText("LR: " .. string.format("%.4f", data.performance.learning_rate), "DermaDefault", metricX, metricY, Color(200, 200, 255))
                    metricX = metricX + 100
                end
                if data.performance.total_reward then
                    draw.SimpleText("Reward: " .. string.format("%.2f", data.performance.total_reward), "DermaDefault", metricX, metricY, Color(100, 255, 100))
                end
            end

            -- Second row of metrics
            metricX = 10
            metricY = startY + 36
            if data.memory_usage then
                draw.SimpleText("Memory: " .. string.format("%.1f KB", data.memory_usage / 1024), "DermaDefault", metricX, metricY, Color(255, 200, 100))
                metricX = metricX + 120
            end
            if data.performance and data.performance.decision then
                draw.SimpleText("Decision: " .. tostring(data.performance.decision), "DermaDefault", metricX, metricY, Color(255, 255, 150))
            end

            -- Weight history graph
            if #weightHistory > 1 then
                local graphX, graphY, graphW, graphH = w - 280, h - 140, 260, 100
                surface.SetDrawColor(40, 40, 60, 200)
                surface.DrawRect(graphX, graphY, graphW, graphH)
                surface.SetDrawColor(100, 100, 150, 255)
                surface.DrawOutlinedRect(graphX, graphY, graphW, graphH)

                draw.SimpleText("Reward History", "DermaDefault", graphX + graphW/2, graphY - 15, Color(255, 255, 255), TEXT_ALIGN_CENTER)

                local minReward, maxReward = math.huge, -math.huge
                for _, histData in ipairs(weightHistory) do
                    if histData.performance and histData.performance.total_reward then
                        minReward = math.min(minReward, histData.performance.total_reward)
                        maxReward = math.max(maxReward, histData.performance.total_reward)
                    end
                end
                if maxReward == minReward then maxReward = minReward + 1 end

                surface.SetDrawColor(100, 255, 100, 255)
                for i = 2, #weightHistory do
                    local d1 = weightHistory[i-1]
                    local d2 = weightHistory[i]
                    if d1.performance and d1.performance.total_reward and d2.performance and d2.performance.total_reward then
                        local x1 = graphX + (i-2) * graphW / math.max(1, #weightHistory-1)
                        local y1 = graphY + graphH - ((d1.performance.total_reward - minReward) / (maxReward - minReward)) * graphH
                        local x2 = graphX + (i-1) * graphW / math.max(1, #weightHistory-1)
                        local y2 = graphY + graphH - ((d2.performance.total_reward - minReward) / (maxReward - minReward)) * graphH
                        surface.DrawLine(x1, y1, x2, y2)
                    end
                end
            end
        end

        -- Network canvas painting function
        function networkCanvas:Paint(w, h)
            surface.SetDrawColor(Color(30, 30, 30))
            surface.DrawRect(0, 0, w, h)

            if visualizationMode == "network" then
                DrawNetworkGraph(w, h)
            elseif visualizationMode == "loss" then
                DrawLossChart(w, h)
            elseif visualizationMode == "accuracy" then
                DrawAccuracyChart(w, h)
            elseif visualizationMode == "weights" then
                DrawWeightHeatmap(w, h)
            elseif visualizationMode == "realtime" then
                DrawRealTimeVisualization(w, h)
            else
                DrawNetworkGraph(w, h)
            end
        end

        -- Network canvas mouse handling
        function networkCanvas:OnMousePressed(mcode)
            if mcode == MOUSE_LEFT then
                -- Check if we clicked on a node
                local mouseX, mouseY = self:CursorPos()
                local foundNode = false

                if neuralNetworkData and neuralNetworkData.layers then
                    for _, layer in ipairs(neuralNetworkData.layers) do
                        for _, neuron in ipairs(layer.neurons) do
                            local x = (neuron.x + nodeRadius) * canvasScale + canvasOffsetX
                            local y = (neuron.y + nodeRadius) * canvasScale + canvasOffsetY
                            local radius = nodeRadius * canvasScale

                            if math.Dist(mouseX, mouseY, x, y) <= radius then
                                selectedNode = neuron
                                selectedConnection = nil
                                isDraggingNode = true
                                dragOffsetX = x - mouseX
                                dragOffsetY = y - mouseY
                                foundNode = true
                                UpdatePropertiesPanel()
                                break
                            end
                        end
                        if foundNode then break end
                    end
                end

                -- If we didn't click on a node, check for connections
                if not foundNode and neuralNetworkData and neuralNetworkData.connections then
                    for _, conn in ipairs(neuralNetworkData.connections) do
                        local fromNode = FindNodeById(conn.from)
                        local toNode = FindNodeById(conn.to)

                        if fromNode and toNode then
                            local fromX = (fromNode.x + nodeRadius) * canvasScale + canvasOffsetX
                            local fromY = (fromNode.y + nodeRadius) * canvasScale + canvasOffsetY
                            local toX = (toNode.x + nodeRadius) * canvasScale + canvasOffsetX
                            local toY = (toNode.y + nodeRadius) * canvasScale + canvasOffsetY

                            -- Check if we clicked near the connection line
                            local dist = DistToLine(mouseX, mouseY, fromX, fromY, toX, toY)
                            if dist <= connectionWidth * 2 then
                                selectedConnection = conn
                                selectedNode = nil
                                UpdatePropertiesPanel()
                                break
                            end
                        end
                    end
                end

                -- If we didn't click on anything, start dragging the canvas
                if not foundNode and not selectedConnection then
                    isDraggingCanvas = true
                    dragOffsetX = mouseX - canvasOffsetX
                    dragOffsetY = mouseY - canvasOffsetY
                end
            elseif mcode == MOUSE_RIGHT then
                -- Right-click menu
                local menu = DermaMenu()

                menu:AddOption("Add Node", function()
                    -- Add node logic
                    notification.AddLegacy("Node added", NOTIFY_GENERIC, 2)
                end)

                menu:AddOption("Remove Node", function()
                    if selectedNode then
                        -- Remove node logic
                        notification.AddLegacy("Node removed", NOTIFY_GENERIC, 2)
                    end
                end)

                menu:AddOption("Add Connection", function()
                    -- Add connection logic
                    notification.AddLegacy("Connection added", NOTIFY_GENERIC, 2)
                end)

                menu:AddOption("Remove Connection", function()
                    if selectedConnection then
                        -- Remove connection logic
                        notification.AddLegacy("Connection removed", NOTIFY_GENERIC, 2)
                    end
                end)

                menu:Open()
            end
        end

        function networkCanvas:OnMouseReleased(mcode)
            if mcode == MOUSE_LEFT then
                isDraggingNode = false
                isDraggingCanvas = false
            end
        end

        function networkCanvas:OnCursorMoved(x, y)
            if isDraggingNode and selectedNode then
                local mouseX, mouseY = self:CursorPos()
                selectedNode.x = (mouseX + dragOffsetX - canvasOffsetX) / canvasScale - nodeRadius
                selectedNode.y = (mouseY + dragOffsetY - canvasOffsetY) / canvasScale - nodeRadius
                UpdatePropertiesPanel()
            elseif isDraggingCanvas then
                local mouseX, mouseY = self:CursorPos()
                canvasOffsetX = mouseX - dragOffsetX
                canvasOffsetY = mouseY - dragOffsetY
            end
        end

        function networkCanvas:OnMouseWheeled(delta)
            -- Zoom with mouse wheel
            if delta > 0 then
                canvasScale = canvasScale * 1.1
            else
                canvasScale = canvasScale * 0.9
            end
            -- Scale is tracked via canvasScale variable, used in Paint
        end

        -- Helper function to find a node by ID
        FindNodeById = function(id)
            if neuralNetworkData and neuralNetworkData.layers then
                for _, layer in ipairs(neuralNetworkData.layers) do
                    for _, neuron in ipairs(layer.neurons) do
                        if neuron.id == id then
                            return neuron
                        end
                    end
                end
            end
            return nil
        end

        -- Update properties panel based on selection
        UpdatePropertiesPanel = function()
            if selectedNode then
                -- Update node properties
                if nodeIdLabel and IsValid(nodeIdLabel) then
                    nodeIdLabel:SetText("Node: " .. (selectedNode.id or "unknown"))
                end
                if nodeTypeLabel and IsValid(nodeTypeLabel) then
                    -- Find layer type for this node
                    local layerType = "hidden"
                    if neuralNetworkData and neuralNetworkData.layers then
                        for _, layer in ipairs(neuralNetworkData.layers) do
                            for _, neuron in ipairs(layer.neurons) do
                                if neuron == selectedNode then
                                    layerType = layer.type or "hidden"
                                    selectedLayer = layer
                                    break
                                end
                            end
                        end
                    end
                    nodeTypeLabel:SetText("Type: " .. layerType)
                end
                if biasSlider and IsValid(biasSlider) then
                    biasSlider:SetValue(selectedNode.bias or 0)
                end
                if activationSlider and IsValid(activationSlider) then
                    activationSlider:SetValue(selectedNode.activation or 0)
                end
            elseif selectedConnection then
                -- Update connection properties
                if connFromLabel and IsValid(connFromLabel) then
                    connFromLabel:SetText("From: " .. (selectedConnection.from or "-"))
                end
                if connToLabel and IsValid(connToLabel) then
                    connToLabel:SetText("To: " .. (selectedConnection.to or "-"))
                end
                if weightSlider and IsValid(weightSlider) then
                    weightSlider:SetValue(selectedConnection.weight or 0)
                end
            end
        end

        -- Draw the network on the canvas
        DrawNetwork = function()
            if not neuralNetworkData or not neuralNetworkData.layers then
                -- Create a default network if none exists
                neuralNetworkData = {
                    layers = {
                        {
                            type = "input",
                            neurons = {
                                {id = "n1_1", bias = 0, activation = 0, x = 100, y = 100},
                                {id = "n1_2", bias = 0, activation = 0, x = 100, y = 200},
                                {id = "n1_3", bias = 0, activation = 0, x = 100, y = 300}
                            }
                        },
                        {
                            type = "hidden",
                            neurons = {
                                {id = "n2_1", bias = 0, activation = 0, x = 300, y = 100},
                                {id = "n2_2", bias = 0, activation = 0, x = 300, y = 200},
                                {id = "n2_3", bias = 0, activation = 0, x = 300, y = 300},
                                {id = "n2_4", bias = 0, activation = 0, x = 300, y = 400}
                            }
                        },
                        {
                            type = "output",
                            neurons = {
                                {id = "n3_1", bias = 0, activation = 0, x = 500, y = 150},
                                {id = "n3_2", bias = 0, activation = 0, x = 500, y = 250}
                            }
                        }
                    },
                    connections = {
                        {from = "n1_1", to = "n2_1", weight = 0.5},
                        {from = "n1_1", to = "n2_2", weight = -0.3},
                        {from = "n1_1", to = "n2_3", weight = 0.8},
                        {from = "n1_1", to = "n2_4", weight = -0.2},
                        {from = "n1_2", to = "n2_1", weight = 0.7},
                        {from = "n1_2", to = "n2_2", weight = 0.1},
                        {from = "n1_2", to = "n2_3", weight = -0.6},
                        {from = "n1_2", to = "n2_4", weight = 0.4},
                        {from = "n1_3", to = "n2_1", weight = -0.5},
                        {from = "n1_3", to = "n2_2", weight = 0.9},
                        {from = "n1_3", to = "n2_3", weight = 0.2},
                        {from = "n1_3", to = "n2_4", weight = -0.7},
                        {from = "n2_1", to = "n3_1", weight = 0.6},
                        {from = "n2_1", to = "n3_2", weight = -0.4},
                        {from = "n2_2", to = "n3_1", weight = 0.3},
                        {from = "n2_2", to = "n3_2", weight = 0.8},
                        {from = "n2_3", to = "n3_1", weight = -0.2},
                        {from = "n2_3", to = "n3_2", weight = 0.5},
                        {from = "n2_4", to = "n3_1", weight = 0.9},
                        {from = "n2_4", to = "n3_2", weight = -0.1}
                    },
                    activationFunction = "sigmoid"
                }
            end

            -- Redraw the canvas
            networkCanvas:InvalidateLayout(true)
        end

        -- Handle network data received from server
        net.Receive("NeuralNetworkData", function()
            neuralNetworkData = net.ReadTable()
            DrawNetwork()
        end)

        -- Real-time NPC data collection hook
        hook.Add("Think", "ZDEV_NNEditor_NPCUpdate", function()
            if realTimeMode and IsValid(selectedNPC) and CurTime() - lastNPCUpdate >= npcUpdateRate then
                lastNPCUpdate = CurTime()
                CollectNPCNetworkData()
                if IsValid(networkCanvas) then
                    networkCanvas:InvalidateLayout(true)
                end
            end
        end)

        -- Cleanup hook when frame is closed
        frame.OnClose = function()
            hook.Remove("Think", "ZDEV_NNEditor_NPCUpdate")
            if trainingTimer then
                timer.Remove("NeuralNetworkTraining")
                trainingTimer = nil
            end
        end

        -- Initial draw
        DrawNetwork()

        -- Add a console command to open the editor
        concommand.Add("nn_editor", function()
            if not frame:IsValid() then
                CreateNeuralNetworkEditor()
            else
                frame:SetVisible(true)
                frame:MakePopup()
            end
        end)
    end

    -- Create the editor when the script loads
    hook.Add("InitPostEntity", "CreateNeuralNetworkEditor", function()
        timer.Simple(1, function()
            CreateNeuralNetworkEditor()
        end)
    end)
end