local table_unpack = unpack or table.unpack

local decompiler={}

-------------------------------------------------------------------------------

decompiler.report=function(
	decompiler,
	filename,
	location,
	message
)
	print((
		string.char(27).."[91m[DECOMPILATION ERROR]"..
		string.char(27).."[36m[%s,%d]"..
		string.char(27).."[0m %s"
	):format(
		filename,
		location,
		message
	))
	os.exit(1)
end

-------------------------------------------------------------------------------

decompiler.opcodes={}

decompiler.opcodes[0x10] = "INT"
decompiler.opcodes[0x20] = "JMP"
decompiler.opcodes[0x21] = "JMC"
decompiler.opcodes[0x22] = "CEQ"
decompiler.opcodes[0x23] = "CNE"
decompiler.opcodes[0x24] = "CLS"
decompiler.opcodes[0x25] = "CLE"
decompiler.opcodes[0x30] = "HOP"
decompiler.opcodes[0x31] = "POS"
decompiler.opcodes[0x32] = "DUP"
decompiler.opcodes[0x33] = "POP"
decompiler.opcodes[0x34] = "SET"
decompiler.opcodes[0x35] = "GET"
decompiler.opcodes[0x40] = "ADD"
decompiler.opcodes[0x41] = "SUB"
decompiler.opcodes[0x42] = "MUL"
decompiler.opcodes[0x43] = "DIV"
decompiler.opcodes[0x44] = "POW"
decompiler.opcodes[0x45] = "MOD"
decompiler.opcodes[0x50] = "NOT"
decompiler.opcodes[0x51] = "AND"
decompiler.opcodes[0x52] = "BOR"
decompiler.opcodes[0x53] = "XOR"
decompiler.opcodes[0x54] = "LSH"
decompiler.opcodes[0x55] = "RSH"
decompiler.opcodes[0x70] = "FTU"
decompiler.opcodes[0x71] = "UTF"
decompiler.opcodes[0x72] = "FEQ"
decompiler.opcodes[0x73] = "FNE"
decompiler.opcodes[0x74] = "FLS"
decompiler.opcodes[0x75] = "FLE"
decompiler.opcodes[0x80] = "FAD"
decompiler.opcodes[0x81] = "FSU"
decompiler.opcodes[0x82] = "FMU"
decompiler.opcodes[0x83] = "FDI"
decompiler.opcodes[0x84] = "FPO"
decompiler.opcodes[0x85] = "FMO"

-------------------------------------------------------------------------------

decompiler.decompile=function(
	decompiler,
	bytecode,
	filename
)
	local source = {}
	local index  = 1
	
	while index<=#bytecode do
		source[#source+1]=("REM 0x%.8X "):format(index-1)
		
		local opcode = bytecode:sub(
			index,
			index
		):byte()
		
		if opcode>=0x00 and opcode<=0x0F then
			index=index+1
			
			local length = bytecode:sub(
				index,
				index
			):byte()+1
			
			source[#source+1]="NUM"
			
			for i=1,length do
				local value=0
				
				for j=0,opcode do
					index = index+1
					value = (
						(value<<8)|
						bytecode:sub(
							index,
							index
						):byte()
					)
				end
				
				source[#source+1]=" 0x"..("%%.%dX"):format(
					(opcode+1)*2
				):format(
					value
				)
			end
		elseif opcode>=0x60 and opcode<=0x6F then
			index=index+1
			
			local precision = bytecode:sub(
				index,
				index
			):byte()
			
			index=index+1
			
			local length = bytecode:sub(
				index,
				index
			):byte()+1
			
			source[#source+1]="FPU"
			
			for i=1,length do
				local value=0
				
				for j=0,opcode-0x60 do
					index = index+1
					value = (
						(value<<8)|
						bytecode:sub(
							index,
							index
						):byte()
					)
				end
				
				source[#source+1]=" "..tostring(
					value/(1<<precision)
				)
			end
		else
			local opname = decompiler.opcodes[opcode]
			
			if opname then
				source[#source+1]=opname
			else
				decompiler:report(
					filename,
					index-1,
					"Invalid operation"
				)
			end
		end
		
		source[#source+1]="\n"
		
		index=index+1
	end
	
	return table.concat(source)
end

-------------------------------------------------------------------------------

return decompiler