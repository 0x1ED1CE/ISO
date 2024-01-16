local bit=bit32 or require("bit")

local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local bit_and    = bit.band
local bit_or     = bit.bor
local bit_xor    = bit.bxor
local bit_not    = bit.bnot

local table_unpack = unpack or table.unpack

local optimizer={}

-------------------------------------------------------------------------------

optimizer.truncate=function(
	optimizer,
	operations,
	index
)
	local op_a = operations[index-1]
	local op_b = operations[index]
	
	if op_a==nil or op_b==nil then
		return
	end
	
	if (
		(op_a.opcode~="NUM" or op_b.opcode~="NUM") and
		(op_a.opcode~="FPU" or op_b.opcode~="FPU")
	) then
		return
	end
	
	local values_a = op_a.parameters[1]
	local values_b = op_b.parameters[1]
	
	while #values_a<256 and #values_b>0 do
		values_a[#values_a+1] = values_b[#values_b]
		values_b[#values_b]   = nil
	end
	
	if #values_b==0 then
		table.remove(operations,index)
	end
end

-------------------------------------------------------------------------------

optimizer.preprocess={}

optimizer.preprocess["CEQ"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = value_a==value_b and 1 or 0
	
	table.remove(operations,index)
end

optimizer.preprocess["CNE"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = value_a~=value_b and 1 or 0
	
	table.remove(operations,index)
end

optimizer.preprocess["CLS"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = value_a<value_b and 1 or 0
	
	table.remove(operations,index)
end

optimizer.preprocess["CLE"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = value_a<=value_b and 1 or 0
	
	table.remove(operations,index)
end

optimizer.preprocess["ADD"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = value_a+value_b
	
	table.remove(operations,index)
end

optimizer.preprocess["SUB"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	if value_a<value_b then
		return --Integer underflow is non-portable
	end
	
	values[#values] = nil
	values[#values] = value_a-value_b
	
	table.remove(operations,index)
end

optimizer.preprocess["MUL"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = value_a*value_b
	
	table.remove(operations,index)
end

optimizer.preprocess["DIV"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	if value_b==0 then
		return --Division by zero is non-portable
	end
	
	values[#values] = nil
	values[#values] = math.floor(value_a/value_b)
	
	table.remove(operations,index)
end

optimizer.preprocess["POW"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = value_a^value_b
	
	table.remove(operations,index)
end

optimizer.preprocess["MOD"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = value_a%value_b
	
	table.remove(operations,index)
end

optimizer.preprocess["AND"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = bit_and(value_a,value_b)
	
	table.remove(operations,index)
end

optimizer.preprocess["BOR"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = bit_or(value_a,value_b)
	
	table.remove(operations,index)
end

optimizer.preprocess["XOR"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = bit_xor(value_a,value_b)
	
	table.remove(operations,index)
end

optimizer.preprocess["LSH"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = bit_lshift(value_a,value_b)
	
	table.remove(operations,index)
end

optimizer.preprocess["RSH"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="NUM" or
		#values<2
	) then
		return
	end
	
	local value_a = math.floor(values[#values-1])
	local value_b = math.floor(values[#values])
	
	values[#values] = nil
	values[#values] = bit_rshift(value_a,value_b)
	
	table.remove(operations,index)
end

optimizer.preprocess["FAD"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="FPU" or
		#values<2
	) then
		return
	end
	
	local value_a = values[#values-1]
	local value_b = values[#values]
	
	values[#values] = nil
	values[#values] = value_a+value_b
	
	table.remove(operations,index)
end

optimizer.preprocess["FSU"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="FPU" or
		#values<2
	) then
		return
	end
	
	local value_a = values[#values-1]
	local value_b = values[#values]
	
	values[#values] = nil
	values[#values] = value_a-value_b
	
	table.remove(operations,index)
end

optimizer.preprocess["FMU"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="FPU" or
		#values<2
	) then
		return
	end
	
	local value_a = values[#values-1]
	local value_b = values[#values]
	
	values[#values] = nil
	values[#values] = value_a*value_b
	
	table.remove(operations,index)
end

optimizer.preprocess["FDI"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="FPU" or
		#values<2
	) then
		return
	end
	
	local value_a = values[#values-1]
	local value_b = values[#values]
	
	if value_b==0 then
		return --Division by zero is non-portable
	end
	
	values[#values] = nil
	values[#values] = value_a/value_b
	
	table.remove(operations,index)
end

optimizer.preprocess["FPO"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="FPU" or
		#values<2
	) then
		return
	end
	
	local value_a = values[#values-1]
	local value_b = values[#values]
	
	values[#values] = nil
	values[#values] = value_a^value_b
	
	table.remove(operations,index)
end

optimizer.preprocess["FMO"]=function(
	optimizer,
	operations,
	index
)
	local operator = operations[index]
	local operands = operations[index-1]
	local values   = operands.parameters[1]
	
	if (
		operands==nil or
		operands.opcode~="FPU" or
		#values<2
	) then
		return
	end
	
	local value_a = values[#values-1]
	local value_b = values[#values]
	
	values[#values] = nil
	values[#values] = value_a%value_b
	
	table.remove(operations,index)
end

-------------------------------------------------------------------------------

optimizer.optimize=function(
	optimizer,
	operations
)
	
	for i=#operations,1,-1 do
		optimizer:truncate(operations,i)
	end
	
	do
		local index=1
		
		while index<=#operations do
			local operation  = operations[index]
			local preprocess = optimizer.preprocess[operation.opcode]
			
			if preprocess then
				local last_size=#operations
				
				preprocess(
					optimizer,
					operations,
					index
				)
				
				optimizer:truncate(
					operations,
					index
				)
				
				index=index+(#operations-last_size)
			end
			
			index=index+1
		end
	end
end

-------------------------------------------------------------------------------

return optimizer