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

#include "iso_vm.h"

#ifndef ISO_IO_H
#define ISO_IO_H

#define MAX_FILES 256

#define ISO_INT_TERMINATE      0x10
#define ISO_INT_EXECUTE        0x11
#define ISO_INT_CONSOLE_OUTPUT 0x20
#define ISO_INT_CONSOLE_INPUT  0x21
#define ISO_INT_FILE_INIT      0x30
#define ISO_INT_FILE_DEINIT    0x31
#define ISO_INT_FILE_OPEN      0x32
#define ISO_INT_FILE_CLOSE     0x33
#define ISO_INT_FILE_SIZE      0x34
#define ISO_INT_FILE_SEEK_SET  0x35
#define ISO_INT_FILE_SEEK_GET  0x36
#define ISO_INT_FILE_READ      0x37
#define ISO_INT_FILE_WRITE     0x38
#define ISO_INT_CLOCK          0x40

#define ISO_FILE_MODE_READ   0x00
#define ISO_FILE_MODE_WRITE  0x01
#define ISO_FILE_MODE_BOTH   0x02
#define ISO_FILE_MODE_APPEND 0x03

void iso_io_run(
	iso_vm *vm
);

#endif