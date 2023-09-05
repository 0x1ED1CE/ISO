local bit=bit32 or require("bit")

local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local bit_and    = bit.band
local bit_or     = bit.bor
local bit_xor    = bit.bxor
local bit_not    = bit.bnot

local table_unpack = unpack or table.unpack

local compiler={}

-------------------------------------------------------------------------------

compiler.warn=function(compiler,filename,row,column,message)
	print((
		string.char(27).."[93m[WARNING]"..
		string.char(27).."[36m[%s,%d,%d]"..
		string.char(27).."[0m %s"
	):format(
		filename,
		row,
		column,
		message
	))
end

compiler.report=function(compiler,filename,row,column,message)
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

compiler.paste_uint32=function(compiler,buffer,address,value)
	buffer[address]   = string.char(bit_and(bit_rshift(value,24),0xFF))
	buffer[address+1] = string.char(bit_and(bit_rshift(value,16),0xFF))
	buffer[address+2] = string.char(bit_and(bit_rshift(value,8),0xFF))
	buffer[address+3] = string.char(bit_and(value,0xFF))
end

-------------------------------------------------------------------------------

compiler.translator={units={}}

compiler.translator.units["INT"] = string.char(0x01)
compiler.translator.units["JMP"] = string.char(0x10)
compiler.translator.units["JMC"] = string.char(0x11)
compiler.translator.units["CEQ"] = string.char(0x12)
compiler.translator.units["CNE"] = string.char(0x13)
compiler.translator.units["CLS"] = string.char(0x14)
compiler.translator.units["CLE"] = string.char(0x15)
compiler.translator.units["HOP"] = string.char(0x20)
compiler.translator.units["POS"] = string.char(0x21)
compiler.translator.units["DUP"] = string.char(0x22)
compiler.translator.units["POP"] = string.char(0x23)
compiler.translator.units["SET"] = string.char(0x24)
compiler.translator.units["GET"] = string.char(0x25)
compiler.translator.units["ADD"] = string.char(0x30)
compiler.translator.units["SUB"] = string.char(0x31)
compiler.translator.units["MUL"] = string.char(0x32)
compiler.translator.units["DIV"] = string.char(0x33)
compiler.translator.units["POW"] = string.char(0x34)
compiler.translator.units["MOD"] = string.char(0x35)
compiler.translator.units["NOT"] = string.char(0x40)
compiler.translator.units["AND"] = string.char(0x41)
compiler.translator.units["BOR"] = string.char(0x42)
compiler.translator.units["XOR"] = string.char(0x43)
compiler.translator.units["LSH"] = string.char(0x44)
compiler.translator.units["RSH"] = string.char(0x45)
compiler.translator.units["FTU"] = string.char(0x50)
compiler.translator.units["UTF"] = string.char(0x51)
compiler.translator.units["FEQ"] = string.char(0x52)
compiler.translator.units["FNE"] = string.char(0x53)
compiler.translator.units["FLS"] = string.char(0x54)
compiler.translator.units["FLE"] = string.char(0x55)
compiler.translator.units["FAD"] = string.char(0x60)
compiler.translator.units["FSU"] = string.char(0x61)
compiler.translator.units["FMU"] = string.char(0x62)
compiler.translator.units["FDI"] = string.char(0x63)
compiler.translator.units["FPO"] = string.char(0x64)
compiler.translator.units["FMO"] = string.char(0x65)

compiler.translator.units["NUM"]=function(compiler,context,operation)
	if #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local bytecode=context.bytecode
	local wordsize=1
	
	for _,value in ipairs(operation.parameters[1]) do
		local bytes=0
		
		while value>0 do
			value=bit_rshift(value,8)
			bytes=bytes+1
		end
		
		if bytes>wordsize then
			wordsize=bytes
		end
	end
	
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(wordsize)
	bytecode[#bytecode+1] = string.char(#operation.parameters[1])
	
	for _,value in ipairs(operation.parameters[1]) do
		for i=(wordsize-1)*8,0,-8 do
			bytecode[#bytecode+1] = string.char(
				bit_and(bit_rshift(value,i),0xFF)
			)
		end
	end
end

compiler.translator.units["REM"]=function(compiler,context,operation)
end

compiler.translator.units["RAW"]=function(compiler,context,operation)
	
end

compiler.translator.units["DEF"]=function(compiler,context,operation)
	if (
		#operation.parameters~=2 or
		#operation.parameters[1]==0 or
		#operation.parameters[2]==0
	) then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected 2 parameters"
		)
	end
	
	local definitions = context.definitions
	local parameters  = operation.parameters
	
	local definition
	
	for _,definition_ in ipairs(definitions) do
		if #definition_.tag==#parameters[1] then
			local match_=true
			
			for i=1,#definition_.tag do
				if definition_.tag[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				definition=definition_
				break
			end
		end
	end
	
	if not definition then
		definitions[#definitions+1]={
			tag   = parameters[1],
			value = parameters[2]
		}
	else
		definition.value=parameters[2]
		
		compiler:warn(
			operation.filename,
			operation.row,
			operation.column,
			"Redefinition"
		)
	end
end

compiler.translator.units["REF"]=function(compiler,context,operation)
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
	local parameters  = operation.parameters
	local definitions = context.definitions
	local definition
	
	for _,definition_ in ipairs(definitions) do
		if #definition_.tag==#parameters[1] then
			local match_=true
			
			for i=1,#definition_.tag do
				if definition_.tag[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				definition=definition_
				break
			end
		end
	end
	
	if definition then
		compiler.translator.translate(
			compiler,
			context,
			{
				filename   = operation.filename,
				row        = operation.row,
				column     = operation.column,
				opcode     = "NUM",
				parameters = {definition.value}
			}
		)
	else
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Undefined reference"
		)
	end
end

compiler.translator.units["GBL"]=function(compiler,context,operation)
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

compiler.translator.units["VAR"]=function(compiler,context,operation)
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

compiler.translator.units["FUN"]=function(compiler,context,operation)
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
	
	if #subroutines>0 then
		compiler.translator.translate(
			compiler,
			context,
			{
				filename   = operation.filename,
				row        = operation.row,
				column     = operation.column,
				opcode     = "RET",
				parameters = {}
			}
		)
	end
	
	if not subroutine then
		subroutines[#subroutines+1]={
			tag       = parameters[1],
			address   = #bytecode,
			arguments = {table_unpack(
				parameters,
				2,
				#parameters
			)},
			variables = {},
			sections  = {},
			recalls   = {}
		}
		
		bytecode[#bytecode+1] = compiler.translator.units["POS"]
		bytecode[#bytecode+1] = string.char(0x00) --NUM
		bytecode[#bytecode+1] = string.char(0x04)
		bytecode[#bytecode+1] = string.char(0x01)
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

compiler.translator.units["GSR"]=function(compiler,context,operation)
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
		address   = #bytecode+4
	}
	
	bytecode[#bytecode+1] = string.char(0x00) --NUM
	bytecode[#bytecode+1] = string.char(0x04)
	bytecode[#bytecode+1] = string.char(0x01)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
end

compiler.translator.units["SEC"]=function(compiler,context,operation)
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
			"Section must be inside subroutine"
		)
	end
	
	local sections = subroutine.sections
	local section
	
	for _,section_ in ipairs(sections) do
		if #section_.tag==#parameters[1] then
			local match_=true
			
			for i=1,#section_.tag do
				if section_.tag[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				section=section_
				break
			end
		end
	end
	
	if not section then
		sections[#sections+1]={
			tag     = parameters[1],
			address = #bytecode
		}
	else
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Section already defined"
		)
	end
end

compiler.translator.units["REC"]=function(compiler,context,operation)
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
	
	local parameters  = operation.parameters
	local bytecode    = context.bytecode
	local subroutines = context.subroutines
	local subroutine  = subroutines[#subroutines]
	
	if not subroutine then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Cannot recall section outside of function"
		)
	end
	
	local recalls = subroutine.recalls
	
	recalls[#recalls+1]={
		operation = operation,
		tag       = parameters[1],
		address   = #bytecode+4
	}
	
	bytecode[#bytecode+1] = string.char(0x00) --NUM
	bytecode[#bytecode+1] = string.char(0x04)
	bytecode[#bytecode+1] = string.char(0x01)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
end

compiler.translator.units["RUN"]=function(compiler,context,operation)
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
	
	if #operation.parameters==1 then
		callers[#callers+1]={
			operation = operation,
			tag       = parameters[1],
			address   = #bytecode+4
		}
		
		bytecode[#bytecode+1] = string.char(0x00) --NUM
		bytecode[#bytecode+1] = string.char(0x04)
		bytecode[#bytecode+1] = string.char(0x01)
		bytecode[#bytecode+1] = string.char(0x00)
		bytecode[#bytecode+1] = string.char(0x00)
		bytecode[#bytecode+1] = string.char(0x00)
		bytecode[#bytecode+1] = string.char(0x00)
	end
	
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
	compiler.translator.translate(
		compiler,
		context,
		{
			filename   = operation.filename,
			row        = operation.row,
			column     = operation.column,
			opcode     = "GBL",
			parameters = {{("ISO_RETURN_ADDRESS"):byte(1,18)}}
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
	bytecode[#bytecode+1] = string.char(0x00) --NUM
	bytecode[#bytecode+1] = string.char(0x04)
	bytecode[#bytecode+1] = string.char(0x01)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	bytecode[#bytecode+1] = string.char(0x00)
	
	local resolve=#bytecode-3
	
	compiler.translator.translate(
		compiler,
		context,
		{
			filename   = operation.filename,
			row        = operation.row,
			column     = operation.column,
			opcode     = "GBL",
			parameters = {{("ISO_RETURN_ADDRESS"):byte(1,18)}}
		}
	)
	bytecode[#bytecode+1] = compiler.translator.units["SET"]
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
	bytecode[#bytecode+1] = compiler.translator.units["JMP"]
	
	compiler:paste_uint32(bytecode,resolve,#bytecode)
	
	compiler.translator.translate( --Restore call stack
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
	bytecode[#bytecode+1] = compiler.translator.units["HOP"]
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
	compiler.translator.translate(
		compiler,
		context,
		{
			filename   = operation.filename,
			row        = operation.row,
			column     = operation.column,
			opcode     = "GBL",
			parameters = {{("ISO_RETURN_ADDRESS"):byte(1,18)}}
		}
	)
	bytecode[#bytecode+1] = compiler.translator.units["SET"]
end

compiler.translator.units["RET"]=function(compiler,context,operation)
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
			parameters = {{("ISO_RETURN_ADDRESS"):byte(1,18)}}
		}
	)
	bytecode[#bytecode+1] = compiler.translator.units["GET"]
	bytecode[#bytecode+1] = compiler.translator.units["JMP"]
end

compiler.translator.translate=function(compiler,context,operation)
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

compiler.compile=function(compiler,operations)
	local context={
		operations  = operations,
		bytecode    = {
			string.char(0x00), --NUM
			string.char(0x04),
			string.char(0x01),
			string.char(0x00),
			string.char(0x00),
			string.char(0x00),
			string.char(0x00),
			compiler.translator.units["HOP"]
		},
		definitions = {},
		subroutines = {},
		callers     = {},
		globals     = {
			{("ISO_CALL_STACK"):byte(1,14)},
			{("ISO_CALL_ADDRESS"):byte(1,16)},
			{("ISO_RETURN_ADDRESS"):byte(1,18)}
		}
	}
	
	local bytecode    = context.bytecode
	local globals     = context.globals
	local subroutines = context.subroutines
	local callers     = context.callers
	
	for _,operation in ipairs(context.operations) do
		compiler.translator.translate(
			compiler,
			context,
			operation
		)
	end
	
	compiler:paste_uint32(bytecode,4,#globals)
	
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
	
	for _,subroutine in ipairs(subroutines) do
		compiler:paste_uint32(
			bytecode,
			subroutine.address+5,
			#subroutine.variables
		)
		
		for _,recall in ipairs(subroutine.recalls) do
			local address
			
			for _,section in ipairs(subroutine.sections) do
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
	end
	
	if #subroutines>0 then
		compiler.translator.translate(
			compiler,
			context,
			{
				filename   = "",
				row        = 0,
				column     = 0,
				opcode     = "RET",
				parameters = {}
			}
		)
	end
	
	return context
end

-------------------------------------------------------------------------------

return compiler