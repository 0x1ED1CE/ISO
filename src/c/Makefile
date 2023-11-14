CC = gcc -std=gnu99 -Wall -Wextra -s -O2

all: iso

iso: iso_con.c arger.o iso_vm.o iso_io.o iso_aux.o
	$(CC) iso_con.c -o \
	iso \
	arger.o \
	iso_vm.o \
	iso_io.o \
	iso_aux.o 

arger.o: arger.h arger.c
	$(CC) -c arger.c -o arger.o

iso_vm.o: iso.h iso_vm.h iso_vm.c
	$(CC) -c iso_vm.c -o iso_vm.o

iso_io.o: iso.h iso_vm.h iso_io.h iso_io.c
	$(CC) -c iso_io.c -o iso_io.o

iso_aux.o: iso.h iso_vm.h iso_aux.h iso_aux.c
	$(CC) -c iso_aux.c -o iso_aux.o

clean:
	$(RM) \
	iso \
	arger.o \
	iso_vm.o \
	iso_io.o \
	iso_aux.o 