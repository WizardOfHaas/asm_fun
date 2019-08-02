main : main.asm
	nasm main.asm -o startup.bin -Wall

install : startup.bin
	mkdir -p ./mnt
	sudo mount boot.img ./mnt
	sudo cp startup.bin ./mnt
	sudo umount ./mnt

test : boot.img
	qemu-system-i386 -fda boot.img -monitor stdio

doit :
	make
	make install
	make test
