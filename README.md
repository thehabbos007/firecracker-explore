# Exploration of Firecracker

This repo contains two small explorations of using Firecracker microVMs for building JS packages with `yarn`. Only one of the variants accomplishes the task (`read-write`).

Initially, I had set out to create a readonly file system to be shared amongst untrusted users. Each user would then have an allocated partition to do whatever work they require.
The idea was to reduce the amount of data to copy when executing multiple VMs at once - it would only be necessary to allocate this extra disk rather than the entire root filesystem. Unfortunately it wasn't trivial to make `yarn` properly work under a readonly root file system.

The `read-write` exploration created a full root filesystem that would have to be copied (or recreated) for each user - but it worked.

## Prerequisites

It is assumed you're running under Linux and have KVM working, as explained in the firecracker [quickstart guide](https://github.com/firecracker-microvm/firecracker/blob/main/docs/getting-started.md).
You should have the `firecracker` binary in your path as well as `docker` for building root filesystems.

## How to run

To run either kind of VM, you have to first initialize networking through the script in the root, `networking.sh` (clean up by running `clean-up-networking.sh`).
After this, you can enter either of the folders and execute the following command (note: everything runs as root as of now):

```bash
$ make all
```

This will create a `rootfs` from the respective `Dockerfile` in the given directory. Now it is possible to start VMs with networking capabilities:

**start a readonly VM**:

```bash
$ pwd
../readonly
$ ./run.sh
```

This starts a `sh` session in the writeable mounted partition `/home/node` in which yarn commands can be run.

**start a read-write VM**:

```bash
$ pwd
../read-write
$ ./run.sh https://gitpkg.now.sh/hashintel/hash/packages/blocks/callout\?main
```

This builds a type script package at https://github.com/hashintel/hash/tree/main/packages/blocks/callout. At the end you should see the output of the build tarball and have a `out.tgz` file in your `/read-write` directory.

If at any point you get an error in the shape of `Error creating the HTTP server: IO error: Address already in use (os error 98)`
simply delete the firecracker socket: `rm -f /tmp/firecracker.socket`.

## General setup

The VMs both mount a `rootfs` built by docker. Using the provided `init-agent` built into the docker images, the VM will use a custom init program to set up its initial state. This program is just meant to provide the bare minimum to facilitate a linux environment (it's not very tested/thought through). I've made use of command line tools directly from the init program when it comes to the build stages of the `read-write` exploration, as it was easier than orchestrating builds with bindings or in a custom program.

The idea is that an orchestrator can kick off these VMs in a centralized fasion. Ideally the VMs would share some root filesystem, and have their own disk to do whatever (this is what `readonly` does). To facilitate communication back and forth with the VMs, `MMDS` is used, which sort of acts like a key/value store. Down the line the VMs could send payloads back to the orchestrator.
