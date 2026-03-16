local _f = 'zdev/shared/sh_advanced_nn.lua'
if ZDEV and ZDEV.FILE and ZDEV.FILE.Loaded( _f ) then return end
---------------------------------------------------------------------------
-- Advanced Neural Network Library for ZDEV
-- Implements CNN + LSTM + Multi-Head architecture for visual AI
---------------------------------------------------------------------------

ZDEV.AdvancedNN = {}
local AdvancedNN = ZDEV.AdvancedNN

-- Activation functions for advanced network
local function relu(x)
    return math.max(0, x)
end

local function tanh_activation(x)
    return math.tanh(x)
end

local function softmax(outputs)
    local maxVal = -math.huge
    for i = 1, #outputs do
        maxVal = math.max(maxVal, outputs[i])
    end
    
    local sum = 0
    local result = {}
    for i = 1, #outputs do
        result[i] = math.exp(outputs[i] - maxVal)
        sum = sum + result[i]
    end
    
    for i = 1, #result do
        result[i] = result[i] / sum
    end
    
    return result
end

-- Convolution operation for 2D input
local function convolution2d(input, filter, stride, padding)
    local inputHeight, inputWidth = #input, #input[1]
    local filterHeight, filterWidth = #filter, #filter[1]
    
    local outputHeight = math.floor((inputHeight + 2 * padding - filterHeight) / stride) + 1
    local outputWidth = math.floor((inputWidth + 2 * padding - filterWidth) / stride) + 1
    
    local output = {}
    for i = 1, outputHeight do
        output[i] = {}
        for j = 1, outputWidth do
            local sum = 0
            
            for fi = 1, filterHeight do
                for fj = 1, filterWidth do
                    local inputI = (i - 1) * stride + fi - padding
                    local inputJ = (j - 1) * stride + fj - padding
                    
                    if inputI >= 1 and inputI <= inputHeight and inputJ >= 1 and inputJ <= inputWidth then
                        sum = sum + input[inputI][inputJ] * filter[fi][fj]
                    end
                end
            end
            
            output[i][j] = relu(sum)
        end
    end
    
    return output
end

-- Max pooling operation
local function maxPooling2d(input, poolSize, stride)
    local inputHeight, inputWidth = #input, #input[1]
    local outputHeight = math.floor((inputHeight - poolSize) / stride) + 1
    local outputWidth = math.floor((inputWidth - poolSize) / stride) + 1
    
    local output = {}
    for i = 1, outputHeight do
        output[i] = {}
        for j = 1, outputWidth do
            local maxVal = -math.huge
            
            for pi = 1, poolSize do
                for pj = 1, poolSize do
                    local inputI = (i - 1) * stride + pi
                    local inputJ = (j - 1) * stride + pj
                    
                    if inputI <= inputHeight and inputJ <= inputWidth then
                        maxVal = math.max(maxVal, input[inputI][inputJ])
                    end
                end
            end
            
            output[i][j] = maxVal
        end
    end
    
    return output
end

-- Flatten 2D array to 1D
local function flatten(input)
    local result = {}
    for i = 1, #input do
        for j = 1, #input[i] do
            table.insert(result, input[i][j])
        end
    end
    return result
end

-- Creates a new advanced neural network with CNN + LSTM architecture
function AdvancedNN:new(visualInputSize, visualChannels, vectorInputSize, lstmUnits, actionDim)
    local nn = {}
    setmetatable(nn, self)
    self.__index = self
    
    nn.visualHeight = visualInputSize[1] or 32
    nn.visualWidth = visualInputSize[2] or 32
    nn.visualChannels = visualChannels or 3 -- New: Number of channels for visual input
    nn.vectorInputSize = vectorInputSize or 6
    nn.lstmUnits = lstmUnits or 128
    nn.actionDim = actionDim or 13
    nn.fcUnits = 64
    
    nn.learning_rate = 0.001
    nn.dropout_rate = 0.2
    
    -- Convolutional Layer 1: 32 filters, 3x3 kernel
    nn.conv1_filters = {}
    nn.conv1_biases = {}
    for f = 1, 32 do
        nn.conv1_filters[f] = {}
        for c = 1, nn.visualChannels do -- Filters now have depth for channels
            nn.conv1_filters[f][c] = {}
            for i = 1, 3 do
                nn.conv1_filters[f][c][i] = {}
                for j = 1, 3 do
                    nn.conv1_filters[f][c][i][j] = (math.random() - 0.5) * 0.2
                end
            end
        end
        nn.conv1_biases[f] = (math.random() - 0.5) * 0.1
    end
    
    -- Convolutional Layer 2: 64 filters, 3x3 kernel
    nn.conv2_filters = {}
    nn.conv2_biases = {}
    for f = 1, 64 do
        nn.conv2_filters[f] = {}
        for c = 1, 32 do -- Input channels for conv2 are the output filters of conv1
            nn.conv2_filters[f][c] = {}
            for i = 1, 3 do
                nn.conv2_filters[f][c][i] = {}
                for j = 1, 3 do
                    nn.conv2_filters[f][c][i][j] = (math.random() - 0.5) * 0.2
                end
            end
        end
        nn.conv2_biases[f] = (math.random() - 0.5) * 0.1
    end
    
    -- Calculate flattened CNN output size (simplified estimation)
    -- This needs to be more accurate based on conv/pool operations
    -- For now, keep it as an estimate, but note it's a simplification
    nn.cnn_output_size = 256  -- Estimated flattened size
    
    -- LSTM weights (simplified implementation)
    nn.lstm_input_size = nn.cnn_output_size + nn.vectorInputSize
    nn.lstm_weights = {}
    nn.lstm_biases = {}
    
    for gate = 1, 4 do
        nn.lstm_weights[gate] = {}
        nn.lstm_biases[gate] = {}
        
        for i = 1, nn.lstmUnits do
            nn.lstm_weights[gate][i] = {}
            nn.lstm_biases[gate][i] = (math.random() - 0.5) * 0.1
            
            for j = 1, nn.lstm_input_size + nn.lstmUnits do
                nn.lstm_weights[gate][i][j] = (math.random() - 0.5) * 0.2
            end
        end
    end
    
    -- LSTM state
    nn.lstm_hidden = {}
    nn.lstm_cell = {}
    for i = 1, nn.lstmUnits do
        nn.lstm_hidden[i] = 0
        nn.lstm_cell[i] = 0
    end
    
    -- Fully Connected Layer weights
    nn.fc_weights = {}
    nn.fc_biases = {}
    for i = 1, nn.fcUnits do
        nn.fc_weights[i] = {}
        nn.fc_biases[i] = (math.random() - 0.5) * 0.1
        
        for j = 1, nn.lstmUnits do
            nn.fc_weights[i][j] = (math.random() - 0.5) * 0.2
        end
    end
    
    -- Actor Head (Action probabilities)
    nn.actor_weights = {}
    nn.actor_biases = {}
    for i = 1, nn.actionDim do
        nn.actor_weights[i] = {}
        nn.actor_biases[i] = (math.random() - 0.5) * 0.1
        
        for j = 1, nn.fcUnits do
            nn.actor_weights[i][j] = (math.random() - 0.5) * 0.2
        end
    end
    
    -- Value Head (State value estimation)
    nn.value_weights = {}
    nn.value_bias = (math.random() - 0.5) * 0.1
    for i = 1, nn.fcUnits do
        nn.value_weights[i] = (math.random() - 0.5) * 0.2
    end
    
    MsgC(Color(0,255,128), "[ZDEV Advanced NN] Created CNN+LSTM network: Visual(", nn.visualHeight, "x", nn.visualWidth, "x", nn.visualChannels, ") + Vector(", nn.vectorInputSize, ") → LSTM(", nn.lstmUnits, ") → Actor(", nn.actionDim, ") + Value(1)\n")
    
    return nn
end

-- Convolution operation for 2D input with multiple channels
local function convolution2d_multi_channel(input, filters, stride, padding)
    local inputHeight, inputWidth = #input[1], #input[1][1]
    local inputChannels = #input
    local numFilters = #filters
    local filterHeight, filterWidth = #filters[1][1], #filters[1][1][1]
    
    local outputHeight = math.floor((inputHeight + 2 * padding - filterHeight) / stride) + 1
    local outputWidth = math.floor((inputWidth + 2 * padding - filterWidth) / stride) + 1
    
    local output = {}
    for f = 1, numFilters do
        output[f] = {}
        for i = 1, outputHeight do
            output[f][i] = {}
            for j = 1, outputWidth do
                local sum = 0
                
                for c = 1, inputChannels do
                    for fi = 1, filterHeight do
                        for fj = 1, filterWidth do
                            local inputI = (i - 1) * stride + fi - padding
                            local inputJ = (j - 1) * stride + fj - padding
                            
                            if inputI >= 1 and inputI <= inputHeight and inputJ >= 1 and inputJ <= inputWidth then
                                sum = sum + input[c][inputI][inputJ] * filters[f][c][fi][fj]
                            end
                        end
                    end
                end
                output[f][i][j] = relu(sum)
            end
        end
    end
    
    return output
end

-- Forward pass through the entire network
function AdvancedNN:forward(visualInput, vectorInput)
    if not visualInput or #visualInput ~= self.visualChannels or #visualInput[1] ~= self.visualHeight then
        MsgC(Color(255,0,0), "[ZDEV Advanced NN] Invalid visual input size or channels\n")
        return nil
    end
    
    if not vectorInput or #vectorInput ~= self.vectorInputSize then
        MsgC(Color(255,0,0), "[ZDEV Advanced NN] Invalid vector input size\n")
        return nil
    end
    
    -- CNN processing with multiple channels
    local conv1_raw_outputs = convolution2d_multi_channel(visualInput, self.conv1_filters, 1, 0)
    local conv1_outputs = {}
    for f = 1, #conv1_raw_outputs do
        conv1_outputs[f] = maxPooling2d(conv1_raw_outputs[f], 2, 2)
    end
    
    local conv2_raw_outputs = convolution2d_multi_channel(conv1_outputs, self.conv2_filters, 1, 0)
    local conv2_outputs = {}
    for f = 1, #conv2_raw_outputs do
        conv2_outputs[f] = maxPooling2d(conv2_raw_outputs[f], 2, 2)
    end
    
    -- Flatten and merge
    local flattened = {}
    for f = 1, #conv2_outputs do
        local flat = flatten(conv2_outputs[f])
        for i = 1, #flat do
            table.insert(flattened, flat[i])
        end
    end
    
    -- Truncate or pad flattened output to match nn.cnn_output_size
    local cnn_output_adjusted = {}
    for i = 1, self.cnn_output_size do
        cnn_output_adjusted[i] = flattened[i] or 0
    end

    local merged_input = {}
    for i = 1, #cnn_output_adjusted do
        merged_input[i] = cnn_output_adjusted[i]
    end
    for i = 1, #vectorInput do
        merged_input[#cnn_output_adjusted + i] = vectorInput[i]
    end
    
    -- LSTM processing (simplified)
    local lstm_input = {}
    for i = 1, math.min(#merged_input, self.lstm_input_size) do
        lstm_input[i] = merged_input[i] or 0
    end
    for i = 1, self.lstmUnits do
        lstm_input[#lstm_input + 1] = self.lstm_hidden[i] or 0
    end
    
    -- Update LSTM state (simplified gates)
    for i = 1, self.lstmUnits do
        local input_sum = 0
        for j = 1, math.min(#lstm_input, 64) do  -- Limit for performance
            input_sum = input_sum + (lstm_input[j] or 0) * (self.lstm_weights[1][i][j] or 0)
        end
        self.lstm_hidden[i] = tanh_activation(input_sum + (self.lstm_biases[1][i] or 0))
    end
    
    -- Fully Connected Layer
    local fc_output = {}
    for i = 1, self.fcUnits do
        local sum = self.fc_biases[i] or 0
        for j = 1, self.lstmUnits do
            sum = sum + (self.lstm_hidden[j] or 0) * (self.fc_weights[i][j] or 0)
        end
        fc_output[i] = relu(sum)
    end
    
    -- Actor Head
    local actor_logits = {}
    for i = 1, self.actionDim do
        local sum = self.actor_biases[i] or 0
        for j = 1, self.fcUnits do
            sum = sum + (fc_output[j] or 0) * (self.actor_weights[i][j] or 0)
        end
        actor_logits[i] = sum
    end
    local action_probs = softmax(actor_logits)
    
    -- Value Head
    local value = self.value_bias or 0
    for i = 1, self.fcUnits do
        value = value + (fc_output[i] or 0) * (self.value_weights[i] or 0)
    end
    
    return {
        actions = action_probs,
        value = value,
        lstm_state = {hidden = self.lstm_hidden, cell = self.lstm_cell}
    }
end

-- Reset LSTM state
function AdvancedNN:resetState()
    for i = 1, self.lstmUnits do
        self.lstm_hidden[i] = 0
        self.lstm_cell[i] = 0
    end
end

-- Create visual input from NPC's field of view
function AdvancedNN:createVisualInput(npc)
    local visual = {}
    for c = 1, self.visualChannels do
        visual[c] = {}
        for i = 1, self.visualHeight do
            visual[c][i] = {}
            for j = 1, self.visualWidth do
                visual[c][i][j] = 0 -- Initialize all channels to 0
            end
        end
    end

    local myPos = npc:GetPos() + Vector(0,0,64) -- Eye level
    local fovDistance = 1000 -- Max raycast distance

    for i = 1, self.visualHeight do
        for j = 1, self.visualWidth do
            local angle = (j - self.visualWidth/2) / self.visualWidth * 90
            local pitch = (i - self.visualHeight/2) / self.visualHeight * 45
            
            local forward = npc:GetForward()
            local right = npc:GetRight()
            local up = npc:GetUp()
            
            local rayDir = forward
            rayDir = rayDir + right * math.sin(math.rad(angle)) * 0.5
            rayDir = rayDir + up * math.sin(math.rad(pitch)) * 0.5
            rayDir:Normalize()
            
            local trace = util.TraceLine({
                start = myPos,
                endpos = myPos + rayDir * fovDistance,
                filter = npc,
                mask = MASK_SOLID
            })
            
            local distance_norm = trace.Fraction -- 0 to 1, 1 means far away
            
            -- Channel 1: Distance to obstacle/entity
            visual[1][i][j] = distance_norm
            
            if trace.Hit then
                if IsValid(trace.Entity) then
                    if trace.Entity:IsPlayer() then
                        -- Channel 2: Enemy presence
                        visual[2][i][j] = 1.0
                    elseif trace.Entity:IsNPC() and trace.Entity:Disposition(npc) == D_LI then
                        -- Channel 3: Friendly presence (D_LI = Like)
                        visual[3][i][j] = 1.0
                    else
                        -- Channel 3: Generic obstacle (world, prop, neutral NPC)
                        visual[3][i][j] = 0.5 -- Lower value for generic obstacles
                    end
                else
                    -- Channel 3: World geometry obstacle
                    visual[3][i][j] = 1.0
                end
            end
        end
    end
    
    return visual
end

if ZDEV and ZDEV.FILE and ZDEV.FILE.SetLoaded then ZDEV.FILE.SetLoaded( _f ) end
