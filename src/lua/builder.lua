--This is only for bootstrapping. It does not have error handling!

local bit=bit32 or require("bit")

local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local bit_and    = bit.band
local bit_or     = bit.bor
local bit_xor    = bit.bxor
local bit_not    = bit.bnot

local table_unpack = unpack or table.unpack

local builder={}

-------------------------------------------------------------------------------

builder.token_type={
	SYMBOL = 1,
	NUMBER = 2,
	STRING = 3,
	SPLICE = 4
}

-------------------------------------------------------------------------------

builder.paste_uint32=function(
	builder,
	buffer,
	address,
	value
)
	buffer[address]   = string.char(bit_and(bit_rshift(value,24),0xFF))
	buffer[address+1] = string.char(bit_and(bit_rshift(value,16),0xFF))
	buffer[address+2] = string.char(bit_and(bit_rshift(value,8),0xFF))
	buffer[address+3] = string.char(bit_and(value,0xFF))
end

builder.paste_float32=function(
	builder,
	buffer,
	address,
	value
)
	if value==0.0 then
		builder:paste_uint32(
			buffer,
			address,
			0
		)
		
		return
	end

	local sign=0
	if value<0.0 then
		sign=0x80
		value=-value
	end

	local mant,expo=math.frexp(value)
	local hext={}

	if mant~=mant then
		hext[#hext+1]=string.char(0xFF,0x88,0x00,0x00)
	elseif mant==math.huge or expo>0x80 then
		if sign==0 then
			hext[#hext+1]=string.char(0x7F,0x80,0x00,0x00)
		else
			hext[#hext+1]=string.char(0xFF,0x80,0x00,0x00)
		end
	elseif (mant==0.0 and expo==0) or expo<-0x7E then
		hext[#hext+1]=string.char(sign,0x00,0x00,0x00)
	else
		expo=expo+0x7E
		mant=(mant*2.0-1.0)*0.5*(2^24)--math.ldexp(0.5,24)
		hext[#hext+1]=string.char(
			sign+math.floor(expo/0x2),
			(expo%0x2)*0x80+math.floor(mant/0x10000),
			math.floor(mant/0x100)%0x100,
			mant%0x100
		)
	end

	builder:paste_uint32(
		buffer,
		address,
		tonumber(string.gsub(table.concat(hext),"(.)",
			function(c)
				return string.format(
					"%02X%s",
					string.byte(c),""
				)
			end),
			16
		)
	)
end

-------------------------------------------------------------------------------

builder.tokenize=function(
	builder,
	source,
	index_a
)
	local token_type = 0
	local index_b    = index_a
	
	while (
		index_a<=#source and
		token_type==0
	) do
		local char_=source:sub(index_a,index_a)
		
		if char_:find("%u") then
			index_b=index_a
			
			repeat
				index_b = index_b+1
				char_   = source:sub(index_b,index_b)
			until
				not char_:find("%u") or
				index_b>=#source
			
			index_b    = index_b-1
			token_type = builder.token_type.SYMBOL
		elseif (
			char_:find("%d") or 
			char_=="-" or 
			char_=="."
		) then
			index_b=index_a
			
			repeat
				index_b = index_b+1
				char_   = source:sub(index_b,index_b)
			until
				char_:find("%s") or 
				char_:find("%c") or
				char_=="," or
				index_b>=#source
			
			index_b    = index_b-1
			token_type = builder.token_type.NUMBER
		elseif char_=='"' then
			index_b=index_a
			
			repeat
				index_b = index_b+1
				char_   = source:sub(index_b,index_b)
			until
				char_=='"' or
				index_b>#source
			
			token_type=builder.token_type.STRING
		elseif char_=="," then
			index_b    = index_a
			token_type = builder.token_type.SPLICE
		else
			index_a=index_a+1
		end
	end
	
	return
		token_type,
		index_a,
		index_b
end

-------------------------------------------------------------------------------



-------------------------------------------------------------------------------

builder.parse=function(
	builder,
	source,
	index
)
	
end

-------------------------------------------------------------------------------

builder.translate={}

builder.translate["INT"] = 0x10
builder.translate["JMP"] = 0x20
builder.translate["JMC"] = 0x21
builder.translate["CEQ"] = 0x22
builder.translate["CNE"] = 0x23
builder.translate["CLS"] = 0x24
builder.translate["CLE"] = 0x25
builder.translate["HOP"] = 0x30
builder.translate["POS"] = 0x31
builder.translate["DUP"] = 0x32
builder.translate["POP"] = 0x33
builder.translate["SET"] = 0x34
builder.translate["GET"] = 0x35
builder.translate["ADD"] = 0x40
builder.translate["SUB"] = 0x41
builder.translate["MUL"] = 0x42
builder.translate["DIV"] = 0x43
builder.translate["POW"] = 0x44
builder.translate["MOD"] = 0x45
builder.translate["NOT"] = 0x50
builder.translate["AND"] = 0x51
builder.translate["BOR"] = 0x52
builder.translate["XOR"] = 0x53
builder.translate["LSH"] = 0x54
builder.translate["RSH"] = 0x55
builder.translate["FTU"] = 0x60
builder.translate["UTF"] = 0x61
builder.translate["FEQ"] = 0x62
builder.translate["FNE"] = 0x63
builder.translate["FLS"] = 0x64
builder.translate["FLE"] = 0x65
builder.translate["FAD"] = 0x70
builder.translate["FSU"] = 0x71
builder.translate["FMU"] = 0x72
builder.translate["FDI"] = 0x73
builder.translate["FPO"] = 0x74
builder.translate["FMO"] = 0x75

builder.translate["DEF"] = function(
	builder,
	context
)
	
end

-------------------------------------------------------------------------------

builder.compile=function(
	builder,
	source
)
	local context={
		source = source,
		binary = {},
		macros = {},
		blocks = {},
		caller = {},
		global = {},
		sindex = 1
	}
	
	return table.concat(
		context.binary
	)
end

return builder