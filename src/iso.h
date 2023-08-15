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

#define ISO_OP_NUM 0x00 //NUMBER
#define ISO_OP_INT 0x10 //INTERRUPT
#define ISO_OP_POS 0x20 //STACK POSITION
#define ISO_OP_DUP 0x21 //DUPLICATE
#define ISO_OP_POP 0x22 //POP
#define ISO_OP_ROT 0x23 //ROTATE
#define ISO_OP_SET 0x24 //SET ADDRESS
#define ISO_OP_GET 0x25 //GET ADDRESS
#define ISO_OP_JMP 0x30 //JUMP
#define ISO_OP_JEQ 0x31 //JUMP IF EQUAL
#define ISO_OP_JNE 0x32 //JUMP IF NOT EQUAL
#define ISO_OP_JLS 0x33 //JUMP IF LESS THAN
#define ISO_OP_JLE 0x34 //JUMP IF LESS OR EQUAL
#define ISO_OP_ADD 0x40 //ADD
#define ISO_OP_SUB 0x41 //SUBTRACT
#define ISO_OP_MUL 0x42 //MULTIPLY
#define ISO_OP_DIV 0x43 //DIVIDE
#define ISO_OP_POW 0x44 //POWER
#define ISO_OP_MOD 0x45 //MODULO
#define ISO_OP_NOT 0x50 //NOT
#define ISO_OP_AND 0x51 //AND
#define ISO_OP_BOR 0x52 //OR
#define ISO_OP_XOR 0x53 //XOR
#define ISO_OP_LSH 0x54 //LEFT SHIFT
#define ISO_OP_RSH 0x55 //RIGHT SHIFT

typedef unsigned int  iso_uint;
typedef unsigned char iso_char;
typedef float         iso_float;
typedef union {
	iso_uint uint;
	iso_float fp;
} iso_word;

#endif