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

#ifndef ISO_H
#define ISO_H

/* Operation codes */

#define ISO_OP_NUM 0x00
#define ISO_OP_INT 0x10
#define ISO_OP_POS 0x20
#define ISO_OP_DUP 0x21
#define ISO_OP_POP 0x22
#define ISO_OP_ROT 0x23
#define ISO_OP_SET 0x24
#define ISO_OP_GET 0x25
#define ISO_OP_JMP 0x30
#define ISO_OP_JEQ 0x31
#define ISO_OP_JNE 0x32
#define ISO_OP_JLS 0x33
#define ISO_OP_JLE 0x34
#define ISO_OP_ADD 0x40
#define ISO_OP_SUB 0x41
#define ISO_OP_MUL 0x42
#define ISO_OP_DIV 0x43
#define ISO_OP_POW 0x44
#define ISO_OP_MOD 0x45
#define ISO_OP_NOT 0x50
#define ISO_OP_AND 0x51
#define ISO_OP_BOR 0x52
#define ISO_OP_XOR 0x53
#define ISO_OP_LSH 0x54
#define ISO_OP_RSH 0x55

typedef unsigned int  iso_uint;
typedef unsigned char iso_char;
typedef float         iso_float;
typedef union {
	iso_uint uint;
	iso_float fp;
} iso_word;

#endif