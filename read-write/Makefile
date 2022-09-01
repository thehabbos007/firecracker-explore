all: root extract image

root:
	docker build -f read-write.dockerfile -t agent-b .

extract:
	docker rm -f extract || :
	rm -rf rootfs.tar || :
	docker create --name extract agent-b
	docker export extract -o rootfs.tar
	docker rm -f extract

image:
	set -e 
	rm -rf rootfs.img || : ;\
	sudo fallocate -l 2G ./rootfs.img  ;\
	sudo mkfs.ext4 ./rootfs.img  ;\
	TMP=$$(mktemp -d)  ;\
	echo $$TMP  ;\
	sudo mount -o loop ./rootfs.img $$TMP  ;\
	sudo tar -xvf rootfs.tar -C $$TMP  ;\
	sudo sh -c "echo \"nameserver 1.1.1.1\" > $$TMP/etc/resolv.conf" ;\
	sudo umount $$TMP ;\
	sudo rm -r $$TMP ;\
	sudo chmod 777 ./rootfs.img

