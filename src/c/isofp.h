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

/* ISO Floating Point Extension */

#include "isovm.h"

#ifndef ISO_FP_H
#define ISO_FP_H

#define ISO_OP_FTU 0x60 //FLOAT TO UNSIGNED
#define ISO_OP_UTF 0x61 //UNSIGNED TO FLOAT
#define ISO_OP_FEQ 0x62 //COMPARE IF FLOAT EQUAL
#define ISO_OP_FNE 0x63 //COMPARE IF FLOAT NOT EQUAL
#define ISO_OP_FLS 0x64 //COMPARE IF FLOAT LESS THAN
#define ISO_OP_FLE 0x65 //COMPARE IF FLOAT LESS OR EQUAL
#define ISO_OP_FAD 0x70 //FLOAT ADD
#define ISO_OP_FSU 0x71 //FLOAT SUBTRACT
#define ISO_OP_FMU 0x72 //FLOAT MULTIPLY
#define ISO_OP_FDI 0x73 //FLOAT DIVIDE
#define ISO_OP_FPO 0x74 //FLOAT POWER
#define ISO_OP_FMO 0x75 //FLOAT MODULO

typedef float iso_float;
typedef struct {
	iso_uint uint;
	iso_float fp;
} iso_uint_float;

void iso_fp_run(
	iso_vm *vm
);

#endif