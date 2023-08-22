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

#include <math.h>

#include "isofp.h"

void iso_fp_run(
	iso_vm *vm
) {
	if (vm->INT!=ISO_INT_ILLEGAL_OPERATION)
		return;
	
	iso_uint_float A = {0};
	iso_uint_float B = {0};
	iso_uint_float C = {0};
	
	iso_vm_jump(vm,vm->PC-1);
	
	switch(iso_vm_fetch(vm)) {
		case ISO_OP_FTU:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			A.uint = (iso_uint)iso_vm_pop(vm);
			
			iso_vm_push(vm,A.uint);
			
			break;
		case ISO_OP_UTF:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			A.fp = (iso_float)iso_vm_pop(vm);
			
			iso_vm_push(vm,A.uint);
			
			break;
		case ISO_OP_FEQ:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			A.uint = iso_vm_pop(vm);
			C.uint = iso_vm_pop(vm);
			B.uint = iso_vm_pop(vm);
			
			if (B.fp==C.fp)
				iso_vm_jump(vm,A.uint);
			
			break;
		case ISO_OP_FNE:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			A.uint = iso_vm_pop(vm);
			C.uint = iso_vm_pop(vm);
			B.uint = iso_vm_pop(vm);
			
			if (B.fp!=C.fp)
				iso_vm_jump(vm,A.uint);
			
			break;
		case ISO_OP_FLS:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			A.uint = iso_vm_pop(vm);
			C.uint = iso_vm_pop(vm);
			B.uint = iso_vm_pop(vm);
			
			if (B.fp<C.fp)
				iso_vm_jump(vm,A.uint);
			
			break;
		case ISO_OP_FLE:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			A.uint = iso_vm_pop(vm);
			C.uint = iso_vm_pop(vm);
			B.uint = iso_vm_pop(vm);
			
			if (B.fp<=C.fp)
				iso_vm_jump(vm,A.uint);
			
			break;
		case ISO_OP_FAD:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			B.uint = iso_vm_pop(vm);
			A.uint = iso_vm_pop(vm);
			C.fp   = A.fp+B.fp;
			
			iso_vm_push(vm,C.uint);
			
			break;
		case ISO_OP_FSU:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			B.uint = iso_vm_pop(vm);
			A.uint = iso_vm_pop(vm);
			C.fp   = A.fp-B.fp;
			
			iso_vm_push(vm,C.uint);
			
			break;
		case ISO_OP_FMU:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			B.uint = iso_vm_pop(vm);
			A.uint = iso_vm_pop(vm);
			C.fp   = A.fp*B.fp;
			
			iso_vm_push(vm,C.uint);
			
			break;
		case ISO_OP_FDI:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			B.uint = iso_vm_pop(vm);
			A.uint = iso_vm_pop(vm);
			C.fp   = A.fp/B.fp;
			
			iso_vm_push(vm,C.uint);
			
			break;
		case ISO_OP_FPO:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			B.uint = iso_vm_pop(vm);
			A.uint = iso_vm_pop(vm);
			C.fp   = powf(A.fp,B.fp);
			
			iso_vm_push(vm,C.uint);
			
			break;
		case ISO_OP_FMO:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			B.uint = iso_vm_pop(vm);
			A.uint = iso_vm_pop(vm);
			C.fp   = fmod(A.fp,B.fp);
			
			iso_vm_push(vm,C.uint);
			
			break;
	}
}