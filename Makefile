all: forth

run: forth
	./forth

forth: forth.o
	ld -m elf_i386 -o forth -N forth.o

forth.o: forth.s
	nasm -f elf -l forth.l forth.s
