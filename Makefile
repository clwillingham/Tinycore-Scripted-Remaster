all: unpack combine pack buildiso

combine:
	#cp -r src/extract bin
	#cp -r src/packages/squashfs-root/* bin/extract
	cp -r src/extras/* bin/extract
	#cp -r src/iso bin/newiso
	

pack:
	cd bin/extract/; find | cpio -o -H newc | gzip -2 > ../newiso/boot/tinycore.gz
	advdef -z1 bin/newiso/boot/tinycore.gz

buildiso:
	mkisofs -l -J -R -V TC-custom -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat -o tinyRemaster.iso bin/newiso


clean:
	rm -r bin/*
	rm tinyRemaster.iso

run:
	qemu --cdrom tinyRemaster.iso

unpack: 
	sudo mount tinycore-current.iso /mnt/tmp -o loop,ro
	mkdir bin/newiso
	cp -a /mnt/tmp/* bin/newiso/boot/
	umount /mnt/tmp
	mkdir bin/extract
	cd bin/extract;zcat ../newiso/boot/tinycore.gz | cpio -i -H newc -d
	

