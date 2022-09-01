// use nix::mount::{self, MsFlags};
// use errno::{errno, set_errno, Errno};
use std::ffi::c_void;
use std::fs::{self, File};
use std::io::Write;
use std::path::Path;
use std::process::{exit, Command, Stdio};
use std::ptr::null;

extern "C" {
    fn mount(
        src: *const u8,
        target: *const u8,
        fstype: *const u8,
        flags: u64,
        data: *const c_void,
    ) -> i32;

    fn sync();
    fn umount(src: *const u8) -> i32;

    fn seteuid(uid: u32) -> i32;
    // fn setegid(gid: u32) -> i32;
}

const MOUNTED_HOME_PATH: &str = "/home/node";

fn main() {
    println!("VM Booted up and starting");

    // When filesystemtype is set, the source is ignored, hence empty strs.
    ensure_mount("", "/proc", "proc");
    ensure_mount("", "/dev/pts", "devpts");
    ensure_mount("", "/dev/mqueue", "mqueue");
    ensure_mount("", "/dev/shm", "tmpfs");
    ensure_mount("", "/sys", "sysfs");
    ensure_mount("", "/sys/fs/cgroup", "cgroup");

    ensure_mount("/dev/vdb", MOUNTED_HOME_PATH, "");

    run_command(["/bin/mount", "-a"]);

    // Set effective user to "node".
    set_effective_group(0);

    println!("Starting machine...");
    let result = Command::new("/bin/sh")
        .env(
            "PATH",
            "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin",
        )
        .current_dir(MOUNTED_HOME_PATH)
        .spawn();

    if let Ok(mut child) = result {
        let _ = child.wait();
        // Set effective user to "root".
        set_effective_group(0);

        // Unmount the mounted home partition to flush writes.
        unmount(MOUNTED_HOME_PATH);

        // Flush any pending writes.
        unsafe { sync() };

        exit(0);
    } else {
        println!("Unexpected error");
        exit(0);
    }
}

fn ensure_nameserver() {
    let resolv_file = File::options()
        .append(true)
        .create(true)
        .open("/etc/resolv.conf");

    if let Ok(mut resolv) = resolv_file {
        let _ = writeln!(resolv, "nameserver 1.1.1.1");
    }
}

fn ensure_mount(source: &str, target: &str, fstype: &str) {
    let target_path = Path::new(target);

    if !target_path.exists() && !target_path.is_dir() {
        let _ = fs::create_dir_all(target)
            .map_err(|_| println!("Could not create directory, might already exist"));
    }

    let source = format!("{}\0", source);
    let target = format!("{}\0", target);
    let fstype = format!("{}\0", fstype);

    let result = unsafe { mount(source.as_ptr(), target.as_ptr(), fstype.as_ptr(), 0, null()) };

    if result != 0 {
        println!(
            "Error creating mount {}:{} fs: {}, error nr ({:?})",
            source,
            target,
            fstype,
            std::io::Error::last_os_error().raw_os_error()
        );
    }
}

fn unmount(target: &str) {
    let target = format!("{}\0", target);

    // Flush any pending writes.
    unsafe { sync() };

    // Unmount location.
    let result = unsafe { umount(target.as_ptr()) };
    if result != 0 {
        println!("Error unmounting {}", target);
    }
}

fn set_effective_group(user_id: u32) {
    let result = unsafe { seteuid(user_id) };
    if result != 0 {
        println!("Unable to set effective user {}", user_id);
    }
}

fn spawn_command<const N: usize>(args: [&str; N]) {
    let mut cmd = Command::new(args[0]);

    for arg in &args[1..] {
        cmd.arg(arg);
    }

    cmd.env(
        "PATH",
        "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin",
    );

    cmd.stdout(Stdio::piped());

    let result = cmd.status();

    if let Ok(run) = result {
        println!("Ran with exit code: {}", run);
    } else if let Err(err) = result {
        println!("Error could not run: {}", err);
    }
}

fn run_command<const N: usize>(args: [&str; N]) -> Option<String> {
    let mut cmd = Command::new(args[0]);
    for arg in &args[1..] {
        cmd.arg(arg);
    }

    let result = cmd.output();

    cmd.env(
        "PATH",
        "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin",
    );

    if let Ok(output) = result {
        if let Ok(string) = String::from_utf8(output.stdout) {
            if !string.trim().is_empty() {
                return Some(string.trim().to_owned());
            }
        }
    } else {
        println!("Could not run command {}", args[0]);
    }

    None
}
