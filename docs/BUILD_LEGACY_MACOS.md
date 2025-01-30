# Building for Older macOS Versions

To compile for macOS versions older than macOS 13, follow these steps:

1. **Identify the macOS Version**: Determine the macOS version you are targeting.
1. **Select the Swift Version**: Use the Swift version compatible with that macOS version.
1. **Compile with Swift**: Use the `swiftc` command with the appropriate target and SDK. You may wish to look at `scripts/build.sh` for ideas of which compiler flags to include.

## Example Command Line

For example, to compile for macOS 12 (Monterey) using Swift 5.5 on an Intel CPU:

```sh
# Ensure necessary directories are created
mkdir -p ./build/dist ./bin

# Compile the source code with the specified flags
xcrun --sdk macosx swiftc \
  -target "x86_64-apple-macos12.0" \
  -swift-version 5.5 \
  -emit-executable \
  -O \
  -whole-module-optimization \
  -Xfrontend -enable-ossa-modules \
  -Xlinker -dead_strip \
  -Xcc -fstack-protector-strong \
  -o "./build/dist/powerstatus_x86_64" \
  ./src/powerstatus.swift

# Strip debugging symbols to reduce binary size and save result to bin directory
# Note: Debug builds, which retain full debug information, are described in docs/DEBUGGING.md.
xcrun strip -Sx -o "./bin/powerstatus" - "./build/dist/powerstatus_x86_64"

# Clean up temporary build artifacts
rm -rf ./build/dist
```

- Replace the target and Swift version as needed based on your macOS version.
- Make sure you have the corresponding Xcode version installed that includes the required Swift version.
