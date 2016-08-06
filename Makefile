all: forth forth.bin

run: forth
	./forth

forth: forth.o
	ld -m elf_i386 -o forth -N forth.o

forth.o: forth.s
	nasm -f elf -l forth.l forth.s

forth.bin: forth DCPUAsm
	./forth < DCPUAsm | grep "DUMP TEST" -A 100000 | tail -n +2 | head -n -1 | xxd -r -p - forth.bin
