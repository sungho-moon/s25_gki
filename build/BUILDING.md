# Building

The release was produced with the Android Clang `r522817` toolchain and
`pahole` 1.30. A recent Linux host with the standard Android kernel build
dependencies is required. The toolchain itself is not redistributed here.

The source archive already contains the ReSukiSU source at
`drivers/kernelsu`, the SUSFS integration, the KMI compatibility changes, and
both final defconfigs. No external setup script should be run before building
the source snapshot.

Build the built-in ReSukiSU/SUSFS variant:

```bash
./build/build-release.sh builtin
```

Build the LKM-ready variant:

```bash
./build/build-release.sh lkm
```

Set `PATH` so that `clang`, LLVM binutils, and the required host tools resolve
to the intended toolchain. `OUT_DIR` and `JOBS` may be overridden.

The original WSL1 integration/build script is retained as
`build-integration-reference.sh`. It records the local merge and build
environment but contains machine-specific paths and is not the recommended
public build entry point.
