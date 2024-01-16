local table_unpack = unpack or table.unpack

local compiler={}

-------------------------------------------------------------------------------

compiler.report=function(
	compiler,
	filename,
	row,
	column,
	message
)
	print((
		string.char(27).."[91m[COMPILATION ERROR]"..
		string.char(27).."[36m[%s,%d,%d]"..
		string.char(27).."[0m %s"
	):format(
		filename,
		row,
		column,
		message
	))
	os.exit(1)
end

-------------------------------------------------------------------------------

compiler.paste_uint32=function(
	compiler,
	buffer,
	address,
	value
)
	buffer[address]   = string.char((value>>24)&0xFF)
	buffer[address+1] = string.char((value>>16)&0xFF)
	buffer[address+2] = string.char((value>>8)&0xFF)
	buffer[address+3] = string.char(value&0xFF)
end

-------------------------------------------------------------------------------

compiler.translator={units={}}

compiler.translator.units["INT"] = string.char(0x10)
compiler.translator.units["JMP"] = string.char(0x20)
compiler.translator.units["JMC"] = string.char(0x21)
compiler.translator.units["CEQ"] = string.char(0x22)
compiler.translator.units["CNE"] = string.char(0x23)
compiler.translator.units["CLS"] = string.char(0x24)
compiler.translator.units["CLE"] = string.char(0x25)
compiler.translator.units["HOP"] = string.char(0x30)
compiler.translator.units["POS"] = string.char(0x31)
compiler.translator.units["DUP"] = string.char(0x32)
compiler.translator.units["POP"] = string.char(0x33)
compiler.translator.units["SET"] = string.char(0x34)
compiler.translator.units["GET"] = string.char(0x35)
compiler.translator.units["ADD"] = string.char(0x40)
compiler.translator.units["SUB"] = string.char(0x41)
compiler.translator.units["MUL"] = string.char(0x42)
compiler.translator.units["DIV"] = string.char(0x43)
compiler.translator.units["POW"] = string.char(0x44)
compiler.translator.units["MOD"] = string.char(0x45)
compiler.translator.units["NOT"] = string.char(0x50)
compiler.translator.units["AND"] = string.char(0x51)
compiler.translator.units["BOR"] = string.char(0x52)
compiler.translator.units["XOR"] = string.char(0x53)
compiler.translator.units["LSH"] = string.char(0x54)
compiler.translator.units["RSH"] = string.char(0x55)
compiler.translator.units["FTU"] = string.char(0x70)
compiler.translator.units["UTF"] = string.char(0x71)
compiler.translator.units["FEQ"] = string.char(0x72)
compiler.translator.units["FNE"] = string.char(0x73)
compiler.translator.units["FLS"] = string.char(0x74)
compiler.translator.units["FLE"] = string.char(0x75)
compiler.translator.units["FAD"] = string.char(0x80)
compiler.translator.units["FSU"] = string.char(0x81)
compiler.translator.units["FMU"] = string.char(0x82)
compiler.translator.units["FDI"] = string.char(0x83)
compiler.translator.units["FPO"] = string.char(0x84)
compiler.translator.units["FMO"] = string.char(0x85)
compiler.translator.units["SIN"] = string.char(0x90)
compiler.translator.units["COS"] = string.char(0x91)
compiler.translator.units["TAN"] = string.char(0x92)
compiler.translator.units["SQR"] = string.char(0x93)
compiler.translator.units["LOG"] = string.char(0x94)
compiler.translator.units["EXP"] = string.char(0x95)

compiler.translator.units["NUM"]=function(
	compiler,
	context,
	operation
)
	if #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local parameters = operation.parameters
	local bytecode   = context.bytecode
	local values     = parameters[1]
	local wordsize   = 0
	
	if #values>0xFF then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many numbers"
		)
	end
	
	for _,value in ipairs(values) do
		local bytes=0
		
		while value>>(bytes*8)>0 do
			bytes=bytes+1
		end
		
		if bytes-1>wordsize then
			wordsize=bytes-1
		end
	end
	
	if wordsize>0x0F then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Number is too large"
		)
	end
	
	bytecode[#bytecode+1] = string.char(wordsize)
	bytecode[#bytecode+1] = string.char(math.max(#values-1,0))
	
	for _,value in ipairs(values) do
		for i=wordsize*8,0,-8 do
			bytecode[#bytecode+1] = string.char(
				(value>>i)&0xFF
			)
		end
	end
end

compiler.translator.units["FPU"]=function(
	compiler,
	context,
	operation
)
	if #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local parameters = operation.parameters
	local bytecode   = context.bytecode
	local values     = parameters[1]
	local range      = 0
	
	if #values>0xFF then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many numbers"
		)
	end
	
	for _,value in ipairs(values) do
		local bits = value<0 and 1 or 0
		
		while math.floor(math.abs(value))>>bits>0 and bits<32 do
			bits=bits+1
		end
		
		if bits>range then
			range=bits
		end
	end
	
	bytecode[#bytecode+1] = string.char(0x63)
	bytecode[#bytecode+1] = string.char(math.min(24,31-range))
	bytecode[#bytecode+1] = string.char(math.max(#values-1,0))
	
	for _,value in ipairs(values) do
		compiler:paste_uint32(
			bytecode,
			#bytecode+1,
			math.ceil(
				(
					value*
					(1<<math.min(24,31-range))
				)-0.5
			)
		)
	end
end

compiler.translator.units["REM"]=function(
	compiler,
	context,
	operation
)
end

compiler.translator.units["STR"]=function(
	compiler,
	context,
	operation
)
	local parameters = operation.parameters
	local bytecode   = context.bytecode
	local values     = parameters[1]
	local words      = math.ceil(#values/4)
	
	compiler.translator.translate(
		compiler,
		context,
		{
			filename   = operation.filename,
			row        = operation.row,
			column     = operation.column,
			opcode     = "NUM",
			parameters = {{#values}}
		}
	)
	
	bytecode[#bytecode+1] = string.char(0x03)
	bytecode[#bytecode+1] = string.char(math.max(math.ceil(#values/4)-1,0))
	
	for i=1,math.ceil(#values/4)*4 do
		local value=values[i] or 0
		
		if value>0xFF then
			compiler:report(
				operation.filename,
				operation.row,
				operation.column,
				"Character cannot exceed 255"
			)
		end
		
		bytecode[#bytecode+1] = string.char(value)
	end
end

compiler.translator.units["SEC"]=function(
	compiler,
	context,
	operation
)
	if #operation.parameters==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local bytecode   = context.bytecode
	local sections   = context.sections
	local parameters = operation.parameters
	
	for _,section in ipairs(sections) do
		if #section.tag==#parameters[1] then
			local match_=true
			
			for i=1,#section.tag do
				if section.tag[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				compiler:report(
					operation.filename,
					operation.row,
					operation.column,
					"Section is already defined"
				)
			end
		end
	end
	
	sections[#sections+1]={
		tag     = parameters[1],
		address = #bytecode
	}
end

compiler.translator.units["REC"]=function(
	compiler,
	context,
	operation
)
	if #operation.parameters==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local bytecode   = context.bytecode
	local recalls    = context.recalls
	local parameters = operation.parameters
	
	recalls[#recalls+1]={
		operation = operation,
		tag       = parameters[1],
		address   = #bytecode+3
	}
	
	bytecode[#bytecode+1] = string.char(0x03) --NUM
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
end

compiler.translator.units["GBL"]=function(
	compiler,
	context,
	operation
)
	if #operation.parameters==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local bytecode   = context.bytecode
	local globals    = context.globals
	local parameters = operation.parameters
	
	local address
	
	for index,global in ipairs(globals) do
		if #global==#parameters[1] then
			local match_=true
			
			for i=1,#global do
				if global[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				address=index-1
				break
			end
		end
	end
	
	if not address then
		address=#globals
		globals[#globals+1]=parameters[1]
	end
	
	compiler.translator.translate(
		compiler,
		context,
		{
			filename   = operation.filename,
			row        = operation.row,
			column     = operation.column,
			opcode     = "NUM",
			parameters = {{address}}
		}
	)
end

compiler.translator.units["VAR"]=function(
	compiler,
	context,
	operation
)
	if #operation.parameters==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local bytecode    = context.bytecode
	local subroutines = context.subroutines
	local parameters  = operation.parameters
	local subroutine  = subroutines[#subroutines]
	
	if not subroutine then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Local variable outside function"
		)
	end
	
	local offset
	local arguments = subroutine.arguments
	local variables = subroutine.variables
	
	for index,argument in ipairs(arguments) do
		if #argument==#parameters[1] then
			local match_=true
			
			for i=1,#argument do
				if argument[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				offset=(#arguments-index)+3
				break
			end
		end
	end
	
	if offset then
		compiler.translator.translate(
			compiler,
			context,
			{
				filename   = operation.filename,
				row        = operation.row,
				column     = operation.column,
				opcode     = "GBL",
				parameters = {{("ISO_CALL_STACK"):byte(1,16)}}
			}
		)
		bytecode[#bytecode+1] = compiler.translator.units["GET"]
		compiler.translator.translate(
			compiler,
			context,
			{
				filename   = operation.filename,
				row        = operation.row,
				column     = operation.column,
				opcode     = "NUM",
				parameters = {{offset}}
			}
		)
		bytecode[#bytecode+1] = compiler.translator.units["SUB"]
		
		return
	end
	
	for index,variable in ipairs(variables) do
		if #variable==#parameters[1] then
			local match_=true
			
			for i=1,#variable do
				if variable[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				offset=index-1
				break
			end
		end
	end
	
	if not offset then
		offset                  = #variables
		variables[#variables+1] = parameters[1]
	end
	
	compiler.translator.translate(
		compiler,
		context,
		{
			filename   = operation.filename,
			row        = operation.row,
			column     = operation.column,
			opcode     = "GBL",
			parameters = {{("ISO_CALL_STACK"):byte(1,14)}}
		}
	)
	bytecode[#bytecode+1] = compiler.translator.units["GET"]
	
	if offset>0 then
		compiler.translator.translate(
			compiler,
			context,
			{
				filename   = operation.filename,
				row        = operation.row,
				column     = operation.column,
				opcode     = "NUM",
				parameters = {{offset}}
			}
		)
		bytecode[#bytecode+1] = compiler.translator.units["ADD"]
	end
end

compiler.translator.units["FUN"]=function(
	compiler,
	context,
	operation
)
	if #operation.parameters==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	end
	
	for a=2,#operation.parameters do
		local parameter_a=operation.parameters[a]
		
		for b=a+1,#operation.parameters do
			local parameter_b=operation.parameters[b]
			
			if #parameter_a==#parameter_b then
				local match_=true
			
				for i,v in ipairs(parameter_a) do
					if parameter_b[i]~=v then
						match_=false
						
						break
					end
				end
				
				if match_ then
					compiler:report(
						operation.filename,
						operation.row,
						operation.column,
						"Cannot have duplicate arguments"
					)
				end
			end
		end
	end
	
	local operations  = context.operations
	local bytecode    = context.bytecode
	local subroutines = context.subroutines
	local parameters  = operation.parameters
	
	local subroutine
	
	for _,subroutine_ in ipairs(subroutines) do
		if #subroutine_.tag==#parameters[1] then
			local match_=true
			
			for i=1,#subroutine_.tag do
				if subroutine_.tag[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				subroutine=subroutine_
				break
			end
		end
	end
	
	if not subroutine then
		subroutines[#subroutines+1]={
			tag       = parameters[1],
			operation = operation,
			address   = #bytecode,
			arguments = {table_unpack(
				parameters,
				2,
				#parameters
			)},
			variables = {}
		}
		
		bytecode[#bytecode+1] = compiler.translator.units["POS"]
		bytecode[#bytecode+1] = string.char(0x03) --NUM
		bytecode[#bytecode+1] = string.char(0x00)
		bytecode[#bytecode+1] = string.char(0x00)
		bytecode[#bytecode+1] = string.char(0x00)
		bytecode[#bytecode+1] = string.char(0x00)
		bytecode[#bytecode+1] = string.char(0x00)
		bytecode[#bytecode+1] = compiler.translator.units["ADD"]
		bytecode[#bytecode+1] = compiler.translator.units["HOP"]
	else
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Function already defined"
		)
	end
end

compiler.translator.units["PTR"]=function(
	compiler,
	context,
	operation
)
	if #operation.parameters==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local parameters = operation.parameters
	local bytecode   = context.bytecode
	local callers    = context.callers
	
	callers[#callers+1]={
		operation = operation,
		tag       = parameters[1],
		address   = #bytecode+3
	}
	
	bytecode[#bytecode+1] = string.char(0x03) --NUM
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
end

compiler.translator.units["RUN"]=function(
	compiler,
	context,
	operation
)
	if #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local parameters = operation.parameters
	local bytecode   = context.bytecode
	local callers    = context.callers
	
	if #operation.parameters==0 then
		compiler.translator.translate(
			compiler,
			context,
			{
				filename   = operation.filename,
				row        = operation.row,
				column     = operation.column,
				opcode     = "GBL",
				parameters = {{("ISO_CALL_ADDRESS"):byte(1,16)}}
			}
		)
		bytecode[#bytecode+1] = compiler.translator.units["SET"]
	end
	
	local resolve=#bytecode+3
	
	bytecode[#bytecode+1] = string.char(0x03) --NUM
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	
	compiler.translator.translate(
		compiler,
		context,
		{
			filename   = operation.filename,
			row        = operation.row,
			column     = operation.column,
			opcode     = "GBL",
			parameters = {{("ISO_CALL_STACK"):byte(1,16)}}
		}
	)
	bytecode[#bytecode+1] = compiler.translator.units["GET"]
	bytecode[#bytecode+1] = compiler.translator.units["POS"]
	compiler.translator.translate(
		compiler,
		context,
		{
			filename   = operation.filename,
			row        = operation.row,
			column     = operation.column,
			opcode     = "GBL",
			parameters = {{("ISO_CALL_STACK"):byte(1,16)}}
		}
	)
	bytecode[#bytecode+1] = compiler.translator.units["SET"]
	
	if #operation.parameters==0 then
		compiler.translator.translate(
			compiler,
			context,
			{
				filename   = operation.filename,
				row        = operation.row,
				column     = operation.column,
				opcode     = "GBL",
				parameters = {{("ISO_CALL_ADDRESS"):byte(1,16)}}
			}
		)
		bytecode[#bytecode+1] = compiler.translator.units["GET"]
	else
		callers[#callers+1]={
			operation = operation,
			tag       = parameters[1],
			address   = #bytecode+3
		}
		
		bytecode[#bytecode+1] = string.char(0x03) --NUM
		bytecode[#bytecode+1] = string.char(0x00)
		bytecode[#bytecode+1] = string.char(0x00)
		bytecode[#bytecode+1] = string.char(0x00)
		bytecode[#bytecode+1] = string.char(0x00)
		bytecode[#bytecode+1] = string.char(0x00)
	end
	
	bytecode[#bytecode+1] = compiler.translator.units["JMP"]
	
	compiler:paste_uint32(bytecode,resolve,#bytecode)
end

compiler.translator.units["RET"]=function(
	compiler,
	context,
	operation
)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode    = context.bytecode
	local subroutines = context.subroutines
	
	if subroutines==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Cannot return without function"
		)
	end
	
	compiler.translator.translate(
		compiler,
		context,
		{
			filename   = operation.filename,
			row        = operation.row,
			column     = operation.column,
			opcode     = "GBL",
			parameters = {{("ISO_CALL_STACK"):byte(1,18)}}
		}
	)
	bytecode[#bytecode+1] = compiler.translator.units["GET"]
	bytecode[#bytecode+1] = compiler.translator.units["HOP"]
	compiler.translator.translate(
		compiler,
		context,
		{
			filename   = operation.filename,
			row        = operation.row,
			column     = operation.column,
			opcode     = "GBL",
			parameters = {{("ISO_CALL_STACK"):byte(1,18)}}
		}
	)
	bytecode[#bytecode+1] = compiler.translator.units["SET"]
	bytecode[#bytecode+1] = compiler.translator.units["JMP"]
end

compiler.translator.translate=function(
	compiler,
	context,
	operation
)
	local unit = compiler.translator.units[operation.opcode]
	
	if type(unit)=="string" then
		if #operation.parameters>0 then
			compiler:report(
				operation.filename,
				operation.row,
				operation.column,
				"Unexpected parameter"
			)
		end
		
		context.bytecode[#context.bytecode+1] = unit
	elseif type(unit)=="function" then
		unit(
			compiler,
			context,
			operation
		)
	else
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Invalid opcode: "..operation.opcode
		)
	end
end

-------------------------------------------------------------------------------

compiler.compile=function(
	compiler,
	operations
)
	local context={
		operations  = operations,
		bytecode    = {
			string.char(0x03), --NUM
			string.char(0x00),
			string.char(0x00),
			string.char(0x00),
			string.char(0x00),
			string.char(0x00),
			compiler.translator.units["HOP"]
		},
		sections    = {},
		recalls     = {},
		subroutines = {},
		callers     = {},
		globals     = {
			{("ISO_CALL_STACK"):byte(1,14)},
			{("ISO_CALL_ADDRESS"):byte(1,16)}
		}
	}
	
	local bytecode    = context.bytecode
	local globals     = context.globals
	local sections    = context.sections
	local recalls     = context.recalls
	local subroutines = context.subroutines
	local callers     = context.callers
	
	for _,operation in ipairs(operations) do
		compiler.translator.translate(
			compiler,
			context,
			operation
		)
	end
	
	compiler:paste_uint32(bytecode,3,#globals)
	
	for _,subroutine in ipairs(subroutines) do
		compiler:paste_uint32(
			bytecode,
			subroutine.address+4,
			#subroutine.variables
		)
	end
	
	for _,recall in ipairs(recalls) do
		local address
		
		for _,section in ipairs(sections) do
			if #section.tag==#recall.tag then
				local match_=true
				
				for i,value in ipairs(section.tag) do
					if recall.tag[i]~=value then
						match_=false
						break
					end
				end
				
				if match_ then
					address=section.address
					break
				end
			end
		end
		
		if address then
			compiler:paste_uint32(
				bytecode,
				recall.address,
				address
			)
		else
			compiler:report(
				recall.operation.filename,
				recall.operation.row,
				recall.operation.column,
				"Undefined section"
			)
		end
	end
	
	for _,caller in ipairs(callers) do
		local address
		
		for _,subroutine in ipairs(subroutines) do
			if #subroutine.tag==#caller.tag then
				local match_=true
				
				for i,value in ipairs(subroutine.tag) do
					if caller.tag[i]~=value then
						match_=false
						break
					end
				end
				
				if match_ then
					address=subroutine.address
					break
				end
			end
		end
		
		if address then
			compiler:paste_uint32(
				bytecode,
				caller.address,
				address
			)
		else
			compiler:report(
				caller.operation.filename,
				caller.operation.row,
				caller.operation.column,
				"Undefined function"
			)
		end
	end
	
	return context
end

-------------------------------------------------------------------------------

return compiler