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

#include <stdio.h>
#include <stdlib.h>

#include "isoaux.h"

void iso_aux_vm_debug_info(
	iso_vm *vm
) {
	printf(
		"INT: %.8X\nPC: %.8X\nSP: %.8X\n",
		vm->INT,
		vm->PC,
		vm->SP
	);
}

iso_uint iso_aux_handle_interrupt(
	iso_vm *vm
) {
	switch(vm->INT) {
		case ISO_INT_CONSOLE_OUTPUT:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			iso_uint B = iso_vm_pop(vm);
			iso_uint A = iso_vm_pop(vm);
			
			for (; A<B; A++) {
				putc(iso_vm_get(vm,A),stdout);
			}
			
			break;
		case ISO_INT_CONSOLE_INPUT:
			break;
		case ISO_INT_FILE_OPEN:
			break;
		case ISO_INT_FILE_CLOSE:
			break;
		case ISO_INT_FILE_SIZE:
			break;
		case ISO_INT_FILE_READ:
			break;
		case ISO_INT_FILE_WRITE:
			break;
		case ISO_INT_ILLEGAL_OPERATION:
			printf("ILLEGAL OPERATION\n");
			iso_aux_vm_debug_info(vm);
			
			break;
		case ISO_INT_ILLEGAL_JUMP:
			printf("ILLEGAL JUMP\n");
			iso_aux_vm_debug_info(vm);
			
			break;
		case ISO_INT_ILLEGAL_ACCESS:
			printf("ILLEGAL ACCESS\n");
			iso_aux_vm_debug_info(vm);
			
			break;
		case ISO_INT_STACK_OVERFLOW:
			printf("STACK OVERFLOW\n");
			iso_aux_vm_debug_info(vm);
			
			break;
		case ISO_INT_STACK_UNDERFLOW:
			printf("STACK UNDERFLOW\n");
			iso_aux_vm_debug_info(vm);
			
			break;
		case ISO_INT_END_OF_PROGRAM:
			break;
	}
	
	return vm->INT;
}