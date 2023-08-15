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

#ifndef ISO_AUX_H
#define ISO_AUX_H

#define ISO_INT_CONSOLE_OUTPUT 0x40
#define ISO_INT_CONSOLE_INPUT  0x41
#define ISO_INT_FILE_OPEN      0x50
#define ISO_INT_FILE_CLOSE     0x51
#define ISO_INT_FILE_SIZE      0x52
#define ISO_INT_FILE_READ      0x53
#define ISO_INT_FILE_WRITE     0x54
#define ISO_INT_CLOCK          0x60

void iso_aux_vm_debug_info(
	iso_vm *vm
);

iso_uint iso_aux_handle_interrupt(
	iso_vm *vm
);

#endif