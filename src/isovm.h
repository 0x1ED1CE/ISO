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

#include "iso.h"

#ifndef ISO_VM_H
#define ISO_VM_H

/* Interrupt codes */

#define ISO_INT_NONE              0x00
#define ISO_INT_REGISTER_VALUE    0x10
#define ISO_INT_END_OF_PROGRAM    0x20
#define ISO_INT_ILLEGAL_OPERATION 0x21
#define ISO_INT_ILLEGAL_JUMP      0x22
#define ISO_INT_ILLEGAL_ACCESS    0x30
#define ISO_INT_STACK_OVERFLOW    0x31
#define ISO_INT_STACK_UNDERFLOW   0x32

typedef struct {
	iso_uint  INT;
	iso_uint  PC;
	iso_uint  SP;
	iso_uint  program_size;
	iso_uint  stack_size;
	iso_char *program;
	iso_uint *stack;
} iso_vm;

void iso_vm_interrupt(
	iso_vm *context,
	iso_uint interrupt
);

iso_char iso_vm_fetch(
	iso_vm *context
);

void iso_vm_push(
	iso_vm *context,
	iso_uint value
);

iso_uint iso_vm_pop(
	iso_vm *context
);

void iso_vm_set(
	iso_vm *context,
	iso_uint address,
	iso_uint value
);

iso_uint iso_vm_get(
	iso_vm *context,
	iso_uint address
);

void iso_vm_jump(
	iso_vm *context,
	iso_uint address
);

iso_uint iso_vm_run(
	iso_vm *context
);

#endif