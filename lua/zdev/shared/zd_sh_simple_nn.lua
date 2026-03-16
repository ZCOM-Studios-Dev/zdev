local _f = 'zdev/shared/sh_simple_nn.lua'
if ZDEV and ZDEV.FILE and ZDEV.FILE.Loaded( _f ) then return end
---------------------------------------------------------------------------
-- Simple Neural Network Library
-- A basic, self-contained NN for ZDEV NextBots.
---------------------------------------------------------------------------

ZDEV.SimpleNN = {}
local SimpleNN = ZDEV.SimpleNN

-- Activation function (Sigmoid)
local function sigmoid(x)
	return 1 / (1 + math.exp(-x))
end

-- Derivative of sigmoid, for backpropagation with gradient clipping
local function dsigmoid(y)
    local derivative = y * (1 - y)
    -- Prevent vanishing gradients by ensuring minimum derivative
    local min_derivative = 0.01  -- Minimum gradient to prevent complete vanishing
    return math.max(derivative, min_derivative)
end

-- Ensure all optimization arrays are properly sized and initialized
function SimpleNN:ensureOptimizationArrays()
    -- Initialize velocity and gradient accumulation arrays if missing
    if not self.velocity_ih then self.velocity_ih = {} end
    if not self.velocity_ho then self.velocity_ho = {} end
    if not self.grad_acc_ih then self.grad_acc_ih = {} end
    if not self.grad_acc_ho then self.grad_acc_ho = {} end
    
    -- Ensure input-to-hidden arrays are properly sized
    for i = 1, self.hidden_nodes do
        if not self.velocity_ih[i] then self.velocity_ih[i] = {} end
        if not self.grad_acc_ih[i] then self.grad_acc_ih[i] = {} end
        
        for j = 1, self.input_nodes do
            if not self.velocity_ih[i][j] then self.velocity_ih[i][j] = 0 end
            if not self.grad_acc_ih[i][j] then self.grad_acc_ih[i][j] = 0 end
        end
    end
    
    -- Ensure hidden-to-output arrays are properly sized
    for i = 1, self.output_nodes do
        if not self.velocity_ho[i] then self.velocity_ho[i] = {} end
        if not self.grad_acc_ho[i] then self.grad_acc_ho[i] = {} end
        
        for j = 1, self.hidden_nodes do
            if not self.velocity_ho[i][j] then self.velocity_ho[i][j] = 0 end
            if not self.grad_acc_ho[i][j] then self.grad_acc_ho[i][j] = 0 end
        end
    end
end

-- Creates a new neural network
function SimpleNN:new(input_nodes, hidden_nodes, output_nodes)
	local nn = {}
	setmetatable(nn, self)
	self.__index = self

	nn.input_nodes = input_nodes
	nn.hidden_nodes = hidden_nodes
	nn.output_nodes = output_nodes

	nn.learning_rate = 0.8  -- Reduced for stability with improved gradients
	nn.momentum = 0.9       -- Momentum coefficient for accelerated learning
	nn.decay_rate = 0.95    -- Weight decay for regularization

	-- Initialize velocity arrays for momentum
	nn.velocity_ih = {}
	nn.velocity_ho = {}
	
	-- Initialize accumulated gradients for adaptive learning
	nn.grad_acc_ih = {}
	nn.grad_acc_ho = {}

	-- Create weights with Xavier/Glorot initialization to prevent saturation
	nn.weights_ih = {} -- Input to Hidden
	nn.velocity_ih = {} -- Momentum for Input to Hidden
	nn.grad_acc_ih = {} -- Accumulated gradients for adaptive learning
	local xavier_ih = math.sqrt(2.0 / (input_nodes + hidden_nodes))  -- Xavier initialization
	for i = 1, hidden_nodes do
		nn.weights_ih[i] = {}
		nn.velocity_ih[i] = {}
		nn.grad_acc_ih[i] = {}
		for j = 1, input_nodes do
			nn.weights_ih[i][j] = (math.Rand(-1, 1) * xavier_ih)  -- Smaller initial weights
			nn.velocity_ih[i][j] = 0
			nn.grad_acc_ih[i][j] = 0
		end
	end

	nn.weights_ho = {} -- Hidden to Output
	nn.velocity_ho = {} -- Momentum for Hidden to Output
	nn.grad_acc_ho = {} -- Accumulated gradients for adaptive learning
	local xavier_ho = math.sqrt(2.0 / (hidden_nodes + output_nodes))  -- Xavier initialization
	for i = 1, output_nodes do
		nn.weights_ho[i] = {}
		nn.velocity_ho[i] = {}
		nn.grad_acc_ho[i] = {}
		for j = 1, hidden_nodes do
			nn.weights_ho[i][j] = (math.Rand(-1, 1) * xavier_ho)  -- Smaller initial weights
			nn.velocity_ho[i][j] = 0
			nn.grad_acc_ho[i][j] = 0
		end
	end

	return nn
end

-- Resize network to handle different input sizes
function SimpleNN:resize(new_input_nodes, new_hidden_nodes, new_output_nodes)
    MsgC(Color(255,255,0), "[", SysTime(), "] [ZDEV NN] Resizing network from ", self.input_nodes, "-", self.hidden_nodes, "-", self.output_nodes, " to ", new_input_nodes, "-", new_hidden_nodes, "-", new_output_nodes, "\n")
    
    -- Resize input to hidden weights and optimization arrays
    if new_input_nodes ~= self.input_nodes or new_hidden_nodes ~= self.hidden_nodes then
        local old_weights_ih = self.weights_ih
        local old_velocity_ih = self.velocity_ih or {}
        local old_grad_acc_ih = self.grad_acc_ih or {}
        
        self.weights_ih = {}
        self.velocity_ih = {}
        self.grad_acc_ih = {}
        
        for i = 1, new_hidden_nodes do
            self.weights_ih[i] = {}
            self.velocity_ih[i] = {}
            self.grad_acc_ih[i] = {}
            for j = 1, new_input_nodes do
                -- Try to preserve existing weights and momentum
                if old_weights_ih[i] and old_weights_ih[i][j] then
                    self.weights_ih[i][j] = old_weights_ih[i][j]
                    self.velocity_ih[i][j] = (old_velocity_ih[i] and old_velocity_ih[i][j]) or 0
                    self.grad_acc_ih[i][j] = (old_grad_acc_ih[i] and old_grad_acc_ih[i][j]) or 0
                else
                    self.weights_ih[i][j] = math.Rand(-0.1, 0.1)
                    self.velocity_ih[i][j] = 0
                    self.grad_acc_ih[i][j] = 0
                end
            end
        end
    end
    
    -- Resize hidden to output weights and optimization arrays
    if new_hidden_nodes ~= self.hidden_nodes or new_output_nodes ~= self.output_nodes then
        local old_weights_ho = self.weights_ho
        local old_velocity_ho = self.velocity_ho or {}
        local old_grad_acc_ho = self.grad_acc_ho or {}
        
        self.weights_ho = {}
        self.velocity_ho = {}
        self.grad_acc_ho = {}
        
        for i = 1, new_output_nodes do
            self.weights_ho[i] = {}
            self.velocity_ho[i] = {}
            self.grad_acc_ho[i] = {}
            for j = 1, new_hidden_nodes do
                -- Try to preserve existing weights and momentum
                if old_weights_ho[i] and old_weights_ho[i][j] then
                    self.weights_ho[i][j] = old_weights_ho[i][j]
                    self.velocity_ho[i][j] = (old_velocity_ho[i] and old_velocity_ho[i][j]) or 0
                    self.grad_acc_ho[i][j] = (old_grad_acc_ho[i] and old_grad_acc_ho[i][j]) or 0
                else
                    self.weights_ho[i][j] = math.Rand(-0.1, 0.1)
                    self.velocity_ho[i][j] = 0
                    self.grad_acc_ho[i][j] = 0
                end
            end
        end
    end
    
    -- Update node counts
    self.input_nodes = new_input_nodes
    self.hidden_nodes = new_hidden_nodes
    self.output_nodes = new_output_nodes
    
    MsgC(Color(255,255,0), "[", SysTime(), "] [ZDEV NN] Network resizing completed with advanced optimization arrays\n")
end

-- Add comprehensive debugging to neural network library
-- This will track all weight changes and calculation steps
MsgC(Color(255,255,255), "[", SysTime(), "] [ZDEV DEBUG] Adding comprehensive debugging to SimpleNN library\n")

function SimpleNN:forward(inputs)
    MsgC(Color(128,255,128), "[", SysTime(), "] [ZDEV NN] forward() called with ", #inputs, " inputs, expecting ", self.input_nodes, "\n")
    
    -- Validate input size
    if #inputs ~= self.input_nodes then
        MsgC(Color(255,0,0), "[", SysTime(), "] [ZDEV NN] ERROR: Input size mismatch! Got ", #inputs, " inputs, expected ", self.input_nodes, "\n")
        -- Pad or truncate inputs to match expected size
        local adjusted_inputs = {}
        for i = 1, self.input_nodes do
            adjusted_inputs[i] = inputs[i] or 0
        end
        inputs = adjusted_inputs
        MsgC(Color(255,255,0), "[", SysTime(), "] [ZDEV NN] WARNING: Adjusted inputs to size ", #inputs, "\n")
    end
    
    -- Generate hidden outputs
    local hidden = {}
    for i = 1, self.hidden_nodes do
        local sum = 0
        for j = 1, self.input_nodes do
            -- Safety check for weight existence
            if not self.weights_ih[i] or not self.weights_ih[i][j] then
                MsgC(Color(255,0,0), "[", SysTime(), "] [ZDEV NN] ERROR: Missing weight at weights_ih[", i, "][", j, "]\n")
                -- Initialize missing weight
                if not self.weights_ih[i] then self.weights_ih[i] = {} end
                self.weights_ih[i][j] = math.Rand(-1, 1)
                MsgC(Color(255,255,0), "[", SysTime(), "] [ZDEV NN] WARNING: Initialized missing weight weights_ih[", i, "][", j, "] = ", self.weights_ih[i][j], "\n")
            end
            
            sum = sum + inputs[j] * self.weights_ih[i][j]
            -- Reduced debug output to prevent spam
            if GetConVar('learning_npc_debug') and GetConVar('learning_npc_debug'):GetBool() then
                MsgC(Color(128,255,128), "[", SysTime(), "] [ZDEV NN] Hidden node ", i, " weight[", i, "][", j, "]=", self.weights_ih[i][j], " input[", j, "]=", inputs[j], "\n")
            end
        end
        hidden[i] = sigmoid(sum)
        -- Only show hidden node results if basic debug is enabled
        if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
            MsgC(Color(128,255,128), "[", SysTime(), "] [ZDEV NN] Hidden node ", i, " sum=", sum, " output=", hidden[i], "\n")
        end
    end

    -- Generate final outputs
    local outputs = {}
    for i = 1, self.output_nodes do
        local sum = 0
        for j = 1, self.hidden_nodes do
            -- Safety check for weight existence
            if not self.weights_ho[i] or not self.weights_ho[i][j] then
                MsgC(Color(255,0,0), "[", SysTime(), "] [ZDEV NN] ERROR: Missing weight at weights_ho[", i, "][", j, "]\n")
                -- Initialize missing weight
                if not self.weights_ho[i] then self.weights_ho[i] = {} end
                self.weights_ho[i][j] = math.Rand(-1, 1)
                MsgC(Color(255,255,0), "[", SysTime(), "] [ZDEV NN] WARNING: Initialized missing weight weights_ho[", i, "][", j, "] = ", self.weights_ho[i][j], "\n")
            end
            
            sum = sum + hidden[j] * self.weights_ho[i][j]
            -- Only show detailed weight logging if both debug flags are enabled
            if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() and
               GetConVar("zdev_debug") and GetConVar("zdev_debug"):GetBool() then
                MsgC(Color(128,255,128), "[", SysTime(), "] [ZDEV NN] Output node ", i, " weight[", i, "][", j, "]=", self.weights_ho[i][j], " hidden[", j, "]=", hidden[j], "\n")
            end
        end
        outputs[i] = sigmoid(sum)
        -- Only show output node results if basic debug is enabled
        if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
            MsgC(Color(128,255,128), "[", SysTime(), "] [ZDEV NN] Output node ", i, " sum=", sum, " output=", outputs[i], "\n")
        end
    end

    -- Store recent values for training
    self.recent_inputs = inputs
    self.recent_hidden = hidden
    self.recent_outputs = outputs
    
    MsgC(Color(128,255,128), "[", SysTime(), "] [ZDEV NN] forward() completed with ", #outputs, " outputs\n")
    return outputs
end

-- Backpropagation training algorithm
function SimpleNN:train(targets)
    MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] train() called with ", #targets, " targets for ", self.output_nodes, " outputs\n")
    
    -- We use the values stored from the most recent forward pass
    local inputs = self.recent_inputs
    local hidden = self.recent_hidden
    local outputs = self.recent_outputs

    if not inputs or not hidden or not outputs then
        MsgC(Color(255,0,0), "[", SysTime(), "] [ZDEV NN] ERROR: Cannot train without forward pass data\n")
        return
    end
    
    -- Safety check: Ensure all optimization arrays are properly initialized
    self:ensureOptimizationArrays()

    if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
        MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Using cached data: inputs=[", table.concat(inputs, ", "), "] outputs=[", table.concat(outputs, ", "), "]\n")
    end    -- Calculate output layer errors (target - actual)
    local output_errors = {}
    for i = 1, self.output_nodes do
        -- Only train outputs that have targets, others get zero error (no change)
        if targets[i] then
            output_errors[i] = targets[i] - outputs[i]
            MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Output error[", i, "] = ", targets[i], " - ", outputs[i], " = ", output_errors[i], "\n")
        else
            output_errors[i] = 0
            if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
                MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Output error[", i, "] = 0 (no target provided)\n")
            end
        end
    end

    -- Calculate output gradient (errors * derivative of sigmoid * learning_rate) with clipping
    local output_gradients = {}
    local max_gradient = 5.0  -- Gradient clipping threshold
    for i = 1, self.output_nodes do
        local raw_gradient = dsigmoid(outputs[i]) * output_errors[i] * self.learning_rate
        -- Apply gradient clipping to prevent exploding gradients
        output_gradients[i] = math.max(-max_gradient, math.min(max_gradient, raw_gradient))
        if output_errors[i] ~= 0 then -- Only log non-zero gradients to reduce spam
            MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Output gradient[", i, "] = ", dsigmoid(outputs[i]), " * ", output_errors[i], " * ", self.learning_rate, " = ", raw_gradient, " (clipped to ", output_gradients[i], ")\n")
        end
    end

    -- Calculate hidden->output weight deltas
    local deltas_ho = {}
    for i = 1, self.output_nodes do
        deltas_ho[i] = {}
        for j = 1, self.hidden_nodes do
            local hiddenVal = hidden[j] or 0
            deltas_ho[i][j] = output_gradients[i] * hiddenVal
            -- Only show detailed delta logging if explicitly requested
            if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() and
               GetConVar("zdev_debug") and GetConVar("zdev_debug"):GetBool() then
                MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Delta HO[", i, "][", j, "] = ", output_gradients[i], " * ", hiddenVal, " = ", deltas_ho[i][j], "\n")
            end
        end
    end

    -- Calculate hidden layer errors (by backpropagating output errors)
    local hidden_errors = {}
    for i = 1, self.hidden_nodes do
        hidden_errors[i] = 0
        for j = 1, self.output_nodes do
            hidden_errors[i] = hidden_errors[i] + self.weights_ho[j][i] * output_errors[j]
        end
        -- Only show detailed error logging if explicitly requested
        if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() and
           GetConVar("zdev_debug") and GetConVar("zdev_debug"):GetBool() then
            MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Hidden error[", i, "] = ", hidden_errors[i], "\n")
        end
    end

    -- Calculate hidden gradient with clipping
    local hidden_gradients = {}
    for i = 1, self.hidden_nodes do
        local hiddenVal = hidden[i] or 0
        local raw_gradient = dsigmoid(hiddenVal) * hidden_errors[i] * self.learning_rate
        -- Apply gradient clipping to prevent exploding gradients
        hidden_gradients[i] = math.max(-max_gradient, math.min(max_gradient, raw_gradient))
        -- Only show detailed gradient logging if explicitly requested
        if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() and
           GetConVar("zdev_debug") and GetConVar("zdev_debug"):GetBool() then
            MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Hidden gradient[", i, "] = ", raw_gradient, " (clipped to ", hidden_gradients[i], ")\n")
        end
    end

    -- Calculate input->hidden weight deltas
    local deltas_ih = {}
    for i = 1, self.hidden_nodes do
        deltas_ih[i] = {}
        for j = 1, self.input_nodes do
            local inputVal = inputs[j] or 0
            deltas_ih[i][j] = hidden_gradients[i] * inputVal
            -- Only show detailed IH delta logging if explicitly requested
            if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() and
               GetConVar("zdev_debug") and GetConVar("zdev_debug"):GetBool() then
                MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Delta IH[", i, "][", j, "] = ", deltas_ih[i][j], "\n")
            end
        end
    end

    -- Apply deltas to update the weights using momentum and adaptive learning
    MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Applying advanced weight updates with momentum...\n")
    local significant_updates = 0
    local epsilon = 1e-8  -- Small constant to prevent division by zero
    
    -- Update Hidden to Output weights with momentum and RMSprop-like adaptive learning
    for i = 1, self.output_nodes do
        for j = 1, self.hidden_nodes do
            local oldWeight = self.weights_ho[i][j]
            local gradient = deltas_ho[i][j]
            
            -- Update accumulated gradient (RMSprop-style)
            self.grad_acc_ho[i][j] = self.decay_rate * self.grad_acc_ho[i][j] + (1 - self.decay_rate) * gradient * gradient
            
            -- Adaptive learning rate
            local adaptive_lr = self.learning_rate / (math.sqrt(self.grad_acc_ho[i][j]) + epsilon)
            
            -- Update velocity (momentum)
            self.velocity_ho[i][j] = self.momentum * self.velocity_ho[i][j] + adaptive_lr * gradient
            
            -- Apply weight update
            self.weights_ho[i][j] = self.weights_ho[i][j] + self.velocity_ho[i][j]
            
            if math.abs(self.velocity_ho[i][j]) > 0.00001 then
                significant_updates = significant_updates + 1
                if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
                    MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Weight HO[", i, "][", j, "] updated: ", oldWeight, " -> ", self.weights_ho[i][j], " (velocity: ", self.velocity_ho[i][j], ", adaptive_lr: ", adaptive_lr, ")\n")
                end
            end
        end
    end

    -- Update Input to Hidden weights with momentum and adaptive learning
    for i = 1, self.hidden_nodes do
        for j = 1, self.input_nodes do
            local oldWeight = self.weights_ih[i][j]
            local gradient = deltas_ih[i][j]
            
            -- Update accumulated gradient (RMSprop-style)
            self.grad_acc_ih[i][j] = self.decay_rate * self.grad_acc_ih[i][j] + (1 - self.decay_rate) * gradient * gradient
            
            -- Adaptive learning rate
            local adaptive_lr = self.learning_rate / (math.sqrt(self.grad_acc_ih[i][j]) + epsilon)
            
            -- Update velocity (momentum)
            self.velocity_ih[i][j] = self.momentum * self.velocity_ih[i][j] + adaptive_lr * gradient
            
            -- Apply weight update
            self.weights_ih[i][j] = self.weights_ih[i][j] + self.velocity_ih[i][j]
            
            if math.abs(self.velocity_ih[i][j]) > 0.00001 then
                significant_updates = significant_updates + 1
                if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
                    MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Weight IH[", i, "][", j, "] updated: ", oldWeight, " -> ", self.weights_ih[i][j], " (velocity: ", self.velocity_ih[i][j], ", adaptive_lr: ", adaptive_lr, ")\n")
                end
            end
        end
    end
    
    MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] train() completed successfully - ", significant_updates, " significant weight updates (with momentum & adaptive learning)\n")
end

-- Helper function for partial training (train only specific outputs)
function SimpleNN:trainPartial(target_indices, target_values)
    if #target_indices ~= #target_values then
        MsgC(Color(255,0,0), "[", SysTime(), "] [ZDEV NN] ERROR: Mismatched indices and values for partial training\n")
        return
    end
    
    -- Create a full targets array, using current outputs as defaults
    local targets = {}
    for i = 1, self.output_nodes do
        targets[i] = self.recent_outputs[i] or 0 -- Keep current output as target if no specific target provided
    end
    
    -- Override with specific targets
    for i = 1, #target_indices do
        local idx = target_indices[i]
        if idx >= 1 and idx <= self.output_nodes then
            targets[idx] = target_values[i]
        end
    end
    
    MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Partial training: ", #target_indices, " specific targets\n")
    
    -- Use the standard training function
    self:train(targets)
end

-- Advanced learning rate scheduling and parameter adjustment
function SimpleNN:adjustLearningParameters(performance_metric)
    -- Adaptive learning rate based on performance
    -- If performance is good (low error), slightly reduce learning rate for fine-tuning
    -- If performance is poor (high error), increase learning rate for faster learning
    
    if performance_metric then
        if performance_metric < 0.1 then  -- Very good performance
            self.learning_rate = math.max(0.1, self.learning_rate * 0.98)  -- Reduce slightly
            self.momentum = math.min(0.95, self.momentum * 1.01)  -- Increase momentum slightly
        elseif performance_metric > 0.5 then  -- Poor performance
            self.learning_rate = math.min(2.0, self.learning_rate * 1.02)  -- Increase slightly
            self.momentum = math.max(0.7, self.momentum * 0.99)  -- Reduce momentum slightly
        end
        
        if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
            MsgC(Color(128,255,255), "[", SysTime(), "] [ZDEV NN] Learning parameters adjusted: LR=", self.learning_rate, " Momentum=", self.momentum, " (Performance: ", performance_metric, ")\n")
        end
    end
end

-- Self-optimization through automatic architecture adjustment
function SimpleNN:attemptSelfOptimization(performance_history)
    if not performance_history or #performance_history < 10 then return false end
    
    -- Calculate performance trend
    local recent_avg = 0
    local older_avg = 0
    local half = math.floor(#performance_history / 2)
    
    for i = half + 1, #performance_history do
        recent_avg = recent_avg + performance_history[i]
    end
    recent_avg = recent_avg / half
    
    for i = 1, half do
        older_avg = older_avg + performance_history[i]
    end
    older_avg = older_avg / half
    
    local improvement_rate = (older_avg - recent_avg) / older_avg
    
    if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
        MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Self-optimization analysis: Improvement rate: ", improvement_rate, "\n")
    end
    
    -- If learning has plateaued or degraded, attempt structural changes
    if improvement_rate < 0.05 then  -- Less than 5% improvement
        return self:tryStructuralOptimization()
    end
    
    return false
end

-- Attempt to optimize network structure dynamically
function SimpleNN:tryStructuralOptimization()
    local optimization_attempts = {
        -- Try adding a hidden neuron
        function()
            if self.hidden_nodes < 16 then  -- Cap at reasonable size
                MsgC(Color(255,255,128), "[", SysTime(), "] [ZDEV NN] Self-optimization: Adding hidden neuron (", self.hidden_nodes, " -> ", self.hidden_nodes + 1, ")\n")
                self:resize(self.input_nodes, self.hidden_nodes + 1, self.output_nodes)
                return true
            end
            return false
        end,
        
        -- Try adjusting learning parameters more aggressively
        function()
            MsgC(Color(255,255,128), "[", SysTime(), "] [ZDEV NN] Self-optimization: Adjusting learning parameters\n")
            self.learning_rate = self.learning_rate * 1.5
            self.momentum = math.min(0.95, self.momentum * 1.1)
            return true
        end,
        
        -- Try weight reinitialization for poorly performing connections
        function()
            MsgC(Color(255,255,128), "[", SysTime(), "] [ZDEV NN] Self-optimization: Reinitializing weak connections\n")
            self:reinitializeWeakConnections()
            return true
        end
    }
    
    -- Randomly try one optimization approach
    local chosen_optimization = optimization_attempts[math.random(1, #optimization_attempts)]
    return chosen_optimization()
end

-- Reinitialize connections that aren't contributing much to learning
function SimpleNN:reinitializeWeakConnections()
    local weak_threshold = 0.01  -- Weights below this are considered "weak"
    local reinitialized_count = 0
    
    -- Check input-to-hidden weights
    for i = 1, self.hidden_nodes do
        for j = 1, self.input_nodes do
            if math.abs(self.weights_ih[i][j]) < weak_threshold then
                self.weights_ih[i][j] = math.Rand(-0.5, 0.5)
                self.velocity_ih[i][j] = 0  -- Reset momentum for reinitialized weights
                reinitialized_count = reinitialized_count + 1
            end
        end
    end
    
    -- Check hidden-to-output weights
    for i = 1, self.output_nodes do
        for j = 1, self.hidden_nodes do
            if math.abs(self.weights_ho[i][j]) < weak_threshold then
                self.weights_ho[i][j] = math.Rand(-0.5, 0.5)
                self.velocity_ho[i][j] = 0  -- Reset momentum for reinitialized weights
                reinitialized_count = reinitialized_count + 1
            end
        end
    end
    
    if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
        MsgC(Color(128,255,128), "[", SysTime(), "] [ZDEV NN] Reinitialized ", reinitialized_count, " weak connections\n")
    end
end

-- Weight regularization to prevent overfitting
function SimpleNN:applyRegularization(l2_strength)
    l2_strength = l2_strength or 0.001  -- Default L2 regularization strength
    
    -- Apply L2 regularization to weights (weight decay)
    for i = 1, self.output_nodes do
        for j = 1, self.hidden_nodes do
            self.weights_ho[i][j] = self.weights_ho[i][j] * (1 - l2_strength)
        end
    end
    
    for i = 1, self.hidden_nodes do
        for j = 1, self.input_nodes do
            self.weights_ih[i][j] = self.weights_ih[i][j] * (1 - l2_strength)
        end
    end
end

-- Calculate network performance metrics
function SimpleNN:calculatePerformanceMetrics(recent_errors)
    if not recent_errors or #recent_errors == 0 then return nil end
    
    local sum = 0
    local count = #recent_errors
    
    for i = 1, count do
        sum = sum + recent_errors[i]
    end
    
    local avg_error = sum / count
    
    -- Calculate standard deviation for stability assessment
    local variance = 0
    for i = 1, count do
        variance = variance + (recent_errors[i] - avg_error) * (recent_errors[i] - avg_error)
    end
    local std_dev = math.sqrt(variance / count)
    
    return {
        avg_error = avg_error,
        std_dev = std_dev,
        stability = 1 / (1 + std_dev)  -- Higher stability = lower std deviation
    }
end

-- Mutate weights for evolution
function SimpleNN:mutate(rate)
    local function mutate_weights(weights)
        for i = 1, #weights do
            for j = 1, #weights[i] do
                if math.random() < rate then
                    weights[i][j] = weights[i][j] + math.Rand(-0.1, 0.1)
                end
            end
        end
    end

    mutate_weights(self.weights_ih)
    mutate_weights(self.weights_ho)
end

-- Meta-learning: Learn how to learn better
function SimpleNN:enableMetaLearning()
    self.meta_learning = {
        enabled = true,
        adaptation_history = {},
        successful_adaptations = {},
        learning_rate_history = {},
        performance_memory = {},
        optimal_lr_estimate = self.learning_rate,
        optimal_momentum_estimate = self.momentum
    }
end

-- Update meta-learning based on recent performance
function SimpleNN:updateMetaLearning(performance_improvement, current_lr, current_momentum)
    if not self.meta_learning or not self.meta_learning.enabled then return end
    
    local meta = self.meta_learning
    
    -- Store adaptation result
    table.insert(meta.adaptation_history, {
        lr = current_lr,
        momentum = current_momentum,
        improvement = performance_improvement,
        timestamp = SysTime()
    })
    
    -- Keep only recent history (last 20 adaptations)
    if #meta.adaptation_history > 20 then
        table.remove(meta.adaptation_history, 1)
    end
    
    -- If this adaptation was successful, remember it
    if performance_improvement > 0.1 then  -- Significant improvement
        table.insert(meta.successful_adaptations, {
            lr = current_lr,
            momentum = current_momentum,
            improvement = performance_improvement
        })
        
        -- Update optimal estimates based on successful adaptations
        self:updateOptimalEstimates()
    end
    
    if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
        MsgC(Color(255,128,255), "[", SysTime(), "] [ZDEV NN] Meta-learning update: Improvement=", performance_improvement, " Adaptations=", #meta.adaptation_history, "\n")
    end
end

-- Update estimates of optimal learning parameters
function SimpleNN:updateOptimalEstimates()
    local meta = self.meta_learning
    if #meta.successful_adaptations == 0 then return end
    
    local lr_sum, momentum_sum = 0, 0
    local weight_sum = 0
    
    -- Weight recent successful adaptations more heavily
    for i, adaptation in ipairs(meta.successful_adaptations) do
        local age_weight = math.exp(-(#meta.successful_adaptations - i) * 0.1)  -- Exponential decay
        local improvement_weight = adaptation.improvement
        local total_weight = age_weight * improvement_weight
        
        lr_sum = lr_sum + adaptation.lr * total_weight
        momentum_sum = momentum_sum + adaptation.momentum * total_weight
        weight_sum = weight_sum + total_weight
    end
    
    if weight_sum > 0 then
        meta.optimal_lr_estimate = lr_sum / weight_sum
        meta.optimal_momentum_estimate = momentum_sum / weight_sum
        
        if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
            MsgC(Color(128,255,128), "[", SysTime(), "] [ZDEV NN] Meta-learning: Optimal LR estimate=", meta.optimal_lr_estimate, " Momentum=", meta.optimal_momentum_estimate, "\n")
        end
    end
end

-- Use meta-learning to suggest better parameters
function SimpleNN:getMetaLearningAdjustment()
    if not self.meta_learning or not self.meta_learning.enabled then
        return self.learning_rate, self.momentum
    end
    
    local meta = self.meta_learning
    
    -- If we have enough meta-learning data, trend toward optimal estimates
    if #meta.successful_adaptations >= 3 then
        local alpha = 0.1  -- How much to move toward optimal estimates
        local suggested_lr = self.learning_rate * (1 - alpha) + meta.optimal_lr_estimate * alpha
        local suggested_momentum = self.momentum * (1 - alpha) + meta.optimal_momentum_estimate * alpha
        
        return suggested_lr, suggested_momentum
    end
    
    return self.learning_rate, self.momentum
end

-- Self-adaptive training that uses meta-learning
function SimpleNN:adaptiveTrain(targets, performance_metric)
    -- Use meta-learning to get better parameters
    local suggested_lr, suggested_momentum = self:getMetaLearningAdjustment()
    
    -- Store original parameters
    local original_lr, original_momentum = self.learning_rate, self.momentum
    
    -- Apply suggested parameters
    self.learning_rate, self.momentum = suggested_lr, suggested_momentum
    
    -- Perform training
    local pre_performance = performance_metric or 0
    self:train(targets)
    
    -- Calculate improvement (this would need to be called with updated performance metric)
    -- For now, we estimate improvement based on error reduction
    local estimated_improvement = math.abs(self.learning_rate - original_lr) + math.abs(self.momentum - original_momentum)
    
    -- Update meta-learning
    self:updateMetaLearning(estimated_improvement, self.learning_rate, self.momentum)
    
    if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
        MsgC(Color(255,255,128), "[", SysTime(), "] [ZDEV NN] Adaptive training: LR=", self.learning_rate, " Momentum=", self.momentum, " Improvement=", estimated_improvement, "\n")
    end
end

if ZDEV and ZDEV.FILE and ZDEV.FILE.SetLoaded then ZDEV.FILE.SetLoaded( _f ) end

-- Dynamic Architecture Modification System
-- Allows the neural network to modify its own structure based on performance

-- Add a new hidden neuron dynamically
function SimpleNN:addHiddenNeuron()
    if self.hidden_nodes >= 32 then  -- Reasonable upper limit
        return false, "Maximum hidden nodes reached"
    end
    
    local old_hidden = self.hidden_nodes
    self:resize(self.input_nodes, self.hidden_nodes + 1, self.output_nodes)
    
    -- Initialize the new neuron's connections with small random weights
    local new_idx = self.hidden_nodes  -- After resize, this is the correct index
    
    -- Ensure all arrays are properly initialized
    if not self.weights_ih[new_idx] then
        self.weights_ih[new_idx] = {}
        self.velocity_ih[new_idx] = {}
        self.grad_acc_ih[new_idx] = {}
    end
    
    -- Initialize input-to-new-hidden weights
    for j = 1, self.input_nodes do
        self.weights_ih[new_idx][j] = math.Rand(-0.1, 0.1)
        self.velocity_ih[new_idx][j] = 0
        self.grad_acc_ih[new_idx][j] = 0
    end
    
    -- Initialize new-hidden-to-output weights
    for i = 1, self.output_nodes do
        if not self.weights_ho[i] then
            self.weights_ho[i] = {}
            self.velocity_ho[i] = {}
            self.grad_acc_ho[i] = {}
        end
        
        -- Ensure arrays are long enough
        self.weights_ho[i][new_idx] = math.Rand(-0.1, 0.1)
        self.velocity_ho[i][new_idx] = 0
        self.grad_acc_ho[i][new_idx] = 0
    end
    
    if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
        MsgC(Color(128,255,128), "[", SysTime(), "] [ZDEV NN] Added hidden neuron: ", old_hidden, " -> ", self.hidden_nodes, "\n")
    end
    
    return true, "Hidden neuron added successfully"
end

-- Remove underperforming hidden neurons
function SimpleNN:pruneHiddenNeurons()
    if self.hidden_nodes <= 2 then  -- Keep minimum viable network
        return false, "Cannot prune below minimum hidden nodes"
    end
    
    -- Calculate activation levels for each hidden neuron over recent forward passes
    local activation_scores = {}
    for i = 1, self.hidden_nodes do
        local total_weight = 0
        local connection_count = 0
        
        -- Sum incoming weights
        for j = 1, self.input_nodes do
            total_weight = total_weight + math.abs(self.weights_ih[i][j])
            connection_count = connection_count + 1
        end
        
        -- Sum outgoing weights
        for k = 1, self.output_nodes do
            total_weight = total_weight + math.abs(self.weights_ho[k][i])
            connection_count = connection_count + 1
        end
        
        activation_scores[i] = total_weight / connection_count
    end
    
    -- Find the weakest neuron
    local weakest_idx = 1
    local weakest_score = activation_scores[1]
    for i = 2, self.hidden_nodes do
        if activation_scores[i] < weakest_score then
            weakest_score = activation_scores[i]
            weakest_idx = i
        end
    end
    
    -- Only prune if the neuron is truly underperforming
    if weakest_score < 0.05 then  -- Very low activation threshold
        self:removeHiddenNeuron(weakest_idx)
        return true, "Pruned underperforming neuron " .. weakest_idx
    end
    
    return false, "No neurons meet pruning criteria"
end

-- Remove a specific hidden neuron
function SimpleNN:removeHiddenNeuron(neuron_idx)
    if neuron_idx < 1 or neuron_idx > self.hidden_nodes then
        return false
    end
    
    -- Create new weight matrices without the specified neuron
    local new_weights_ih = {}
    local new_velocity_ih = {}
    local new_grad_acc_ih = {}
    
    local new_idx = 1
    for i = 1, self.hidden_nodes do
        if i ~= neuron_idx then
            new_weights_ih[new_idx] = self.weights_ih[i]
            new_velocity_ih[new_idx] = self.velocity_ih[i]
            new_grad_acc_ih[new_idx] = self.grad_acc_ih[i]
            new_idx = new_idx + 1
        end
    end
    
    -- Update hidden-to-output weights
    for i = 1, self.output_nodes do
        local new_weights_row = {}
        local new_velocity_row = {}
        local new_grad_acc_row = {}
        
        new_idx = 1
        for j = 1, self.hidden_nodes do
            if j ~= neuron_idx then
                new_weights_row[new_idx] = self.weights_ho[i][j]
                new_velocity_row[new_idx] = self.velocity_ho[i][j]
                new_grad_acc_row[new_idx] = self.grad_acc_ho[i][j]
                new_idx = new_idx + 1
            end
        end
        
        self.weights_ho[i] = new_weights_row
        self.velocity_ho[i] = new_velocity_row
        self.grad_acc_ho[i] = new_grad_acc_row
    end
    
    -- Update matrices and node count
    self.weights_ih = new_weights_ih
    self.velocity_ih = new_velocity_ih
    self.grad_acc_ih = new_grad_acc_ih
    self.hidden_nodes = self.hidden_nodes - 1
    
    if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
        MsgC(Color(255,128,128), "[", SysTime(), "] [ZDEV NN] Removed hidden neuron ", neuron_idx, " (now ", self.hidden_nodes, " hidden)\n")
    end
    
    return true
end

-- Comprehensive self-optimization routine
function SimpleNN:performSelfOptimization(performance_history, current_performance)
    if not self.meta_learning then
        self:enableMetaLearning()
    end
    
    local optimizations_performed = {}
    
    -- 1. Try parameter optimization
    if current_performance then
        self:adjustLearningParameters(current_performance)
        table.insert(optimizations_performed, "parameter_adjustment")
    end
    
    -- 2. Try structural optimization if performance is stagnant
    if performance_history and #performance_history >= 10 then
        local structure_changed = self:attemptSelfOptimization(performance_history)
        if structure_changed then
            table.insert(optimizations_performed, "structural_change")
        end
    end
    
    -- 3. Try neuron pruning if network is getting too large
    if self.hidden_nodes > 12 then
        local pruned, msg = self:pruneHiddenNeurons()
        if pruned then
            table.insert(optimizations_performed, "neuron_pruning")
        end
    end
    
    -- 4. Meta-learning update
    if current_performance then
        local improvement = 0
        if performance_history and #performance_history > 0 then
            improvement = performance_history[#performance_history] - current_performance
        end
        self:updateMetaLearning(improvement, self.learning_rate, self.momentum)
        table.insert(optimizations_performed, "meta_learning")
    end
    
    if GetConVar("learning_npc_debug") and GetConVar("learning_npc_debug"):GetBool() then
        MsgC(Color(255,255,128), "[", SysTime(), "] [ZDEV NN] Self-optimization complete: ", table.concat(optimizations_performed, ", "), "\n")
    end
    
    return optimizations_performed
end
