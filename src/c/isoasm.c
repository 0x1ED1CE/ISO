/*
MIT License

Copyright (c) 2023 Dice

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
*/

#include "isoasm.h"

#define TOKEN_SYMBOL 1
#define TOKEN_NUMBER 2
#define TOKEN_STRING 3
#define TOKEN_COMMA  4

#define IS_CHAR(C)   (C>='A' && C<='Z')
#define IS_NUMBER(C) (C>='0' && C<='9')
#define IS_STRING(C) (C=='"')
#define IS_COMMA(C)  (C==',')
#define IS_SPACE(C)  (C==' ' || C=='\t')

typedef struct {
	iso_char *label;
	iso_uint  length;
} iso_asm_tag;

typedef struct {
	iso_char    type;
	iso_asm_tag tag;
} iso_asm_token;

typedef struct {
	iso_asm_tag reference;
	iso_uint    address;
} iso_asm_reference;

typedef struct {
	iso_char          *source;
	iso_char          *binary;
	iso_asm_tag       *globals;
	iso_asm_tag       *defines;
	iso_asm_reference *references;
	iso_uint           source_size;
	iso_uint           binary_size;
	iso_uint           char_pos;
	iso_uint           byte_pos;
	iso_uint           global_count;
	iso_uint           define_count;
	iso_uint           reference_count;
} iso_asm;

static const iso_char opcodes[38][4] = {
	"NUM\x00", "INT\x01",
	"JMP\x10", "JMC\x11", "CEQ\x12", "CNE\x13", "CLS\x14", "CLE\x15",
	"HOP\x20", "POS\x21", "DUP\x22", "POP\x23", "SET\x24", "GET\x25",
	"ADD\x30", "SUB\x31", "MUL\x32", "DIV\x33", "POW\x34", "MOD\x35",
	"NOT\x40", "AND\x41", "BOR\x42", "XOR\x43", "LSH\x44", "RSH\x45",
	"FTU\x50", "UTF\x51", "FEQ\x52", "FNE\x53", "FLS\x54", "FLE\x55",
	"FAD\x60", "FSU\x61", "FMU\x62", "FDI\x63", "FPO\x64", "FMO\x65"
};

static const iso_char macros[12][3] = {
	"REM", "RAW",
	"DEF", "REF",
	"GBL", "VAR",
	"FUN", "GSR",
	"SEC", "REC",
	"CSR", "RET"
};

static iso_char get_opcode(
	iso_char *symbol
) {
	for (unsigned int i=0; i<38; i++) {
		char match=1;
		
		for (unsigned int j=0; j<3; j++) {
			if (opcodes[i][j]!=symbol[j]) {
				match=0;
				break;
			}
		}
		
		if (match)
			return opcodes[i][3];
	}
	
	return 0;
}

static iso_char get_macro(
	iso_char *symbol
) {
	for (unsigned int i=0; i<12; i++) {
		char match=1;
		
		for (unsigned int j=0; j<3; j++) {
			if (macros[i][j]!=symbol[j]) {
				match=0;
				break;
			}
		}
		
		if (match)
			return i;
	}
	
	return 0;
}

