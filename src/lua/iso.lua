--[[
MIT License

Copyright (c) 2023 Shoelee

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local lexer     = require "lexer"
local parser    = require "parser"
local validator = require "validator"
local optimizer = require "optimizer"
local compiler  = require "compiler"

local table_unpack = unpack or table.unpack

-------------------------------------------------------------------------------

local function report(message)
	print(
		string.char(27).."[91m[FATAL ERROR]"..
		string.char(27).."[0m "..
		message
	)
	os.exit(1)
end

-------------------------------------------------------------------------------

if #arg==0 then
	print(
		"ISO v0.6 Copyright (C) 2023 Dice\n"..
		"Usage: iso -i <file> -e <file>\n"..
		"Options:\n"..
		"-i\tImport source\n"..
		"-e\tExport binary\n"..
		"-h\tExport header\n"..
		"-s\tExport symbol\n"..
		"-o\tOptimize"
	)
	
	return
end

local source    = {}
local arguments = {}

for _,parameter in ipairs(arg) do
	if parameter:sub(1,1)=="-" then
		arguments[#arguments+1]={parameter}
	elseif #arguments>0 then
		local argument=arguments[#arguments]
		
		argument[#argument+1]=parameter
	else
		report("Missing argument")
	end
end

for _,argument in ipairs(arguments) do
	if argument[1]=="-i" then
		for i=2,#argument do
			local filename = argument[i]
			local file     = io.open(filename,"rb")
			
			if not file then
				report("Cannot open file: '"..filename.."'")
			end
			
			local oplist=parser:parse(
				lexer:lex(
					file:read("*a"),
					filename
				)
			)
			
			file:close()
			
			for _,op in ipairs(oplist) do
				source[#source+1]=op
			end
		end
	elseif argument[1]=="-e" then
		local filename = argument[2]
		local file     = io.open(filename,"wb")
		
		if not file then
			report("Cannot open file: '"..filename.."'")
		end
		
		local output = compiler:compile(source)
		local binary = table.concat(output.bytecode)
		
		file:write(binary)
		file:close()
	elseif argument[1]=="-h" then
		local filename = argument[2]
		local file     = io.open(filename,"wb")
		
		if not file then
			report("Cannot open file: '"..filename.."'")
		end
		
		local output = compiler:compile(source)
		local binary = table.concat(output.bytecode)
		
		file:write(
			"unsigned char "..
			filename
			:match("^.+[/\\](.+)$")
			:gsub("[%s%.]","_")
			:upper()..
			"[]={\n"
		)
		
		for i=1,#binary do
			file:write(("0x%.2X"):format(
				binary:sub(i,i):byte()
			))
			
			if i~=#binary then
				file:write(",")
			end
			
			if i%8==0 or i==#binary then
				file:write("\n")
			end
		end
		
		file:write("};\n")
		file:close()
	elseif argument[1]=="-s" then
		local filename = argument[2]
		local file     = io.open(filename,"w")
		
		if not file then
			report("Cannot open file: '"..filename.."'")
		end
		
		local compilation=compiler:compile(source)
		
		for index,global in ipairs(compilation.globals) do
			file:write(("SP: %.8X - %s\n"):format(
				index-1,
				string.char(table_unpack(global))
			))
		end
		
		for _,subroutine in ipairs(compilation.subroutines) do
			file:write(("PC: %.8X - %s\n"):format(
				subroutine.address,
				string.char(table_unpack(subroutine.tag))
			))
		end
		
		file:close()
	elseif argument[1]=="-o" then
		optimizer:optimize(source)
	end
end