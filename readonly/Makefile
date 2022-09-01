all: root extract image space

root:
	docker build -f readonly.dockerfile -t agent-b .

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
	# echo "$$TMP/etc/resolv.comf"  ;\
	sudo sh -c "echo \"nameserver 1.1.1.1\" > $$TMP/etc/resolv.conf" ;\
	sudo umount $$TMP ;\
	sudo rm -r $$TMP ;\
	sudo chmod 777 ./rootfs.img

space: 
	set -e
	rm -rf space.ext4 || : ;\
	dd if=/dev/zero of=space.ext4 bs=1M count=1536 ;\
	sudo mkfs.ext4 -E root_owner=1000:1000 -U 116154ec-9b15-4341-a8a8-fffef734ac4d ./space.ext4  ;\
