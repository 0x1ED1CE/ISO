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

#include "isovm.h"

void iso_vm_interrupt(
	iso_vm *context,
	iso_uint interrupt
) {
	context->INT=interrupt;
}

iso_char iso_vm_fetch(
	iso_vm *context
) {
	if (context->INT)
		return 0;
	
	iso_uint  PC           = context->PC;
	iso_uint  program_size = context->program_size;
	iso_char *program      = context->program;
	
	if (PC==program_size) {
		iso_vm_interrupt(
			context,
			ISO_INT_END_OF_PROGRAM
		);
		
		return 0;
	}
	
	context->PC = PC+1;
	
	return program[PC];
}

void iso_vm_push(
	iso_vm *context,
	iso_uint value
) {
	if (context->INT)
		return;
	
	iso_uint  SP         = context->SP;
	iso_uint  stack_size = context->stack_size;
	iso_uint *stack      = context->stack;
	
	if (SP>=stack_size) {
		iso_vm_interrupt(
			context,
			ISO_INT_STACK_OVERFLOW
		);
		
		return;
	}
	
	context->SP = SP+1;
	stack[SP]   = value;
}

iso_uint iso_vm_pop(
	iso_vm *context
) {
	if (context->INT)
		return 0;
	
	iso_uint  SP    = context->SP;
	iso_uint *stack = context->stack;
	
	if (SP==0) {
		iso_vm_interrupt(
			context,
			ISO_INT_STACK_UNDERFLOW
		);
		
		return 0;
	}
	
	context->SP=SP-1;
	
	return stack[context->SP];
}

void iso_vm_set(
	iso_vm *context,
	iso_uint address,
	iso_uint value
) {
	if (context->INT)
		return;
	
	iso_uint  SP    = context->SP;
	iso_uint *stack = context->stack;
	
	if (address>=SP) {
		iso_vm_interrupt(
			context,
			ISO_INT_OUT_OF_BOUNDS
		);
		
		return;
	}
	
	stack[address]=value;
}

iso_uint iso_vm_get(
	iso_vm *context,
	iso_uint address
) {
	if (context->INT)
		return 0;
	
	iso_uint  SP    = context->SP;
	iso_uint *stack = context->stack;
	
	if (address>=SP) {
		iso_vm_interrupt(
			context,
			ISO_INT_OUT_OF_BOUNDS
		);
		
		return 0;
	}
	
	return stack[address];
}

void iso_vm_jump(
	iso_vm *context,
	iso_uint address
) {
	if (context->INT)
		return;
	
	if (address>=context->program_size) {
		iso_vm_interrupt(
			context,
			ISO_INT_INVALID_JUMP
		);
		
		return;
	}
	
	context->PC=address;
}

void iso_vm_run(
	iso_vm *context
) {
	if (context->INT)
		return;
	
	/* Registers */
	
	iso_uint *INT = &context->INT;
	iso_uint *SP  = &context->SP;
	
	/* Working variables */
	
	iso_uint A,B,C;
	iso_char D,E,F;
	
	do {
		switch(iso_vm_fetch(context)) {
			case ISO_OP_NUM:
				D = iso_vm_fetch(context);
				E = iso_vm_fetch(context);
				
				for (; E>0; E--) {
					A = 0;
					
					for (F=0; F<D; F++) {
						B = (iso_uint)iso_vm_fetch(context);
						A = (A<<8)|B;
					}
					
					iso_vm_push(context,A);
				}
				
				break;
			case ISO_OP_INT:
				A = iso_vm_pop(context);
				
				iso_vm_interrupt(context,A);
				
				break;
			case ISO_OP_POS:
				iso_vm_push(context,*SP);
				
				break;
			case ISO_OP_DUP:
				A = iso_vm_pop(context);
				B = iso_vm_get(context,*SP-1);
				
				for (; A>0; A--) {
					iso_vm_push(context,B);
				}
				
				break;
			case ISO_OP_POP:
				A = iso_vm_pop(context);
				
				for (; A>0; A--) {
					iso_vm_pop(context);
				}
				
				break;
			case ISO_OP_ROT:
				A = iso_vm_get(context,*SP-2);
				B = iso_vm_get(context,*SP-1);
				
				iso_vm_set(context,*SP-2,B);
				iso_vm_set(context,*SP-1,A);
				
				break;
			case ISO_OP_SET:
				A = iso_vm_pop(context);
				B = iso_vm_pop(context);
				
				iso_vm_set(context,A,B);
				
				break;
			case ISO_OP_GET:
				A = iso_vm_pop(context);
				B = iso_vm_get(context,A);
				
				iso_vm_push(context,B);
				
				break;
			case ISO_OP_JMP:
				A = iso_vm_pop(context);
				
				iso_vm_jump(context,A);
				
				break;
			case ISO_OP_JEQ:
				A = iso_vm_pop(context);
				C = iso_vm_pop(context);
				B = iso_vm_pop(context);
				
				if (B==C)
					iso_vm_jump(context,A);
				
				break;
			case ISO_OP_JNE:
				A = iso_vm_pop(context);
				C = iso_vm_pop(context);
				B = iso_vm_pop(context);
				
				if (B!=C)
					iso_vm_jump(context,A);
				
				break;
			case ISO_OP_JLS:
				A = iso_vm_pop(context);
				C = iso_vm_pop(context);
				B = iso_vm_pop(context);
				
				if (B<C)
					iso_vm_jump(context,A);
				
				break;
			case ISO_OP_JLE:
				A = iso_vm_pop(context);
				C = iso_vm_pop(context);
				B = iso_vm_pop(context);
				
				if (B<=C)
					iso_vm_jump(context,A);
				
				break;
			case ISO_OP_ADD:
				B = iso_vm_pop(context);
				A = iso_vm_pop(context);
				
				iso_vm_push(context,A+B);
				
				break;
			case ISO_OP_SUB:
				B = iso_vm_pop(context);
				A = iso_vm_pop(context);
				
				iso_vm_push(context,A-B);
				
				break;
			case ISO_OP_MUL:
				B = iso_vm_pop(context);
				A = iso_vm_pop(context);
				
				iso_vm_push(context,A*B);
				
				break;
			case ISO_OP_DIV:
				B = iso_vm_pop(context);
				A = iso_vm_pop(context);
				
				iso_vm_push(context,A/B);
				
				break;
			case ISO_OP_POW:
				B = iso_vm_pop(context);
				A = iso_vm_pop(context);
				C = 1;
				
				for (; B>0; B--) {
					C=C*A;
				}
				
				iso_vm_push(context,C);
				
				break;
			case ISO_OP_MOD:
				B = iso_vm_pop(context);
				A = iso_vm_pop(context);
				
				iso_vm_push(context,A%B);
				
				break;
			case ISO_OP_NOT:
				A = iso_vm_pop(context);
				
				iso_vm_push(context,~A);
				
				break;
			case ISO_OP_AND:
				B = iso_vm_pop(context);
				A = iso_vm_pop(context);
				
				iso_vm_push(context,A&B);
				
				break;
			case ISO_OP_BOR:
				B = iso_vm_pop(context);
				A = iso_vm_pop(context);
				
				iso_vm_push(context,A|B);
				
				break;
			case ISO_OP_XOR:
				B = iso_vm_pop(context);
				A = iso_vm_pop(context);
				
				iso_vm_push(context,A^B);
				
				break;
			case ISO_OP_LSH:
				B = iso_vm_pop(context);
				A = iso_vm_pop(context);
				
				iso_vm_push(context,A<<B);
				
				break;
			case ISO_OP_RSH:
				B = iso_vm_pop(context);
				A = iso_vm_pop(context);
				
				iso_vm_push(context,A>>B);
				
				break;
			default:
				iso_vm_interrupt(
					context,
					ISO_INT_ILLEGAL_OPERATION
				);
		}
	} while (*INT==ISO_INT_NONE);
}