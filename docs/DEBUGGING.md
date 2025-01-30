# Debugging with .dSYM Files

## Compiling a Debug Build

To compile a debug build of `powerstatus`, you can use the provided `build.sh` script:

   ```sh
   ksh ./scripts/build.sh
   ```

This script will build `powerstatus.swift` twice:

- Per architecture with debug symbols included.
- As a stripped universal binary for distribution.

After running the script, you will find the debug build in the `./build/debug/` directory. You can then proceed with debugging using `MacSymbolicator` or `lldb` as described below.

## How to Use MacSymbolicator for Debugging

1. **Locate the Crash Report**:
   - Find the crash report in the Console app under "User Reports" or in the `~/Library/Logs/DiagnosticReports` directory.
     - **`~/Library/Logs/DiagnosticReports`**: This directory typically contains `.ips` files, which are crash reports in JSON format.
     - **`~/Library/Logs/CrashReporter`**: This directory may contain symbolic links to crash reports, but it might be empty on some systems.

1. **Download MacSymbolicator**:
   - Download the latest release from the [MacSymbolicator GitHub Releases page](https://github.com/inket/MacSymbolicator/releases/latest).
   - Alternatively, you can install it using Homebrew:

     ```sh
     brew install macsymbolicator
     ```

1. **Run MacSymbolicator**:
   - Open MacSymbolicator and use it to symbolicate your crash report.

## Debug with `lldb`

- For reproducible issues, use the `lldb` debugger to perform detailed debugging:

  ```sh
  # Launch lldb and create a target to the executable
  # For Intel-based Macs, replace `--arch arm64` with `--arch x86_64`.
  lldb --arch arm64 -- ./build/debug/powerstatus_arm64_debug

  # Add the debugging symbols file and run the executable
  (lldb) target symbols add ./build/debug/powerstatus_arm64_debug.dSYM
  (lldb) run
  ```

## Symbolication Explained

**Symbolication** is the process of translating memory addresses (found in crash reports) into human-readable function names, file names, and line numbers using debug symbol files (`.dSYM`). This helps developers understand where in the code the crash occurred.

<!--
## Fallback Options

If MacSymbolicator is not available, you can use the following tools:

1. **Locate the `symbolicatecrash` Script**:
   - The `symbolicatecrash` script is located within the Xcode application bundle. You can find it using the following command:

     ```sh
     find /Applications -name symbolicatecrash -path '*SharedFrameworks/DVTFoundation.framework*'
     ```

     This will typically return:

     ```sh
     /Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources/symbolicatecrash
     ```

1. **Symbolicate the Crash Report**:
   - Use the `symbolicatecrash` script to symbolicate the crash report:

     ```sh
     /Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources/symbolicatecrash <crash-report-path> <dSYM-path>
     ```

     Replace `<crash-report-path>` with the path to your crash report and `<dSYM-path>` with the path to your `.dSYM` file.

1. **Manual Symbolication with `atos`**:
   - `atos` is a command-line tool used for symbolication, translating memory addresses to human-readable function names and line numbers.
   - Use the `atos` command to manually symbolicate the crash report:

     ```sh
     xcrun atos -o /path/to/yourapp.app -d /path/to/yourapp.dSYM -arch x86_64 -l <load address> <crash address>
     ```

     - Replace the placeholders with the appropriate values from your crash report.
     - Replace `-arch arm64` with `-arch x86_64` if you are debugging on an Intel-based Mac (v. Apple Silicon).
   - For detailed information on using `atos`, refer to [Apple’s documentation](https://developer.apple.com/documentation/xcode/adding-identifiable-symbol-names-to-a-crash-report#Symbolicate-the-crash-report-with-the-command-line).

### Notes on Symbolication Tools

- **MacSymbolicator**: Graphical User Interface (GUI) tool for symbolication of entire crash reports.
- **symbolicatecrash**: Command-Line Interface (CLI) tool for symbolication of entire crash reports. It is located within the Xcode application bundle.
- **atos**: Command-Line Interface (CLI) tool for symbolication of specific memory addresses in a crash report. It comes with the Xcode command-line tools. Use `xcrun atos` to ensure the correct version is used. For more detailed information, refer to [Apple’s documentation](https://developer.apple.com/documentation/xcode/adding-identifiable-symbol-names-to-a-crash-report#Symbolicate-the-crash-report-with-the-command-line).
-->

By following these steps, you can obtain detailed information to help diagnose and fix the issue. If you need further assistance, feel free to reach out!
