#! /bin/ksh
set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

# SDK
typeset SDK
SDK="$(xcrun --show-sdk-path --sdk macosx || print "macosx")"

# Check both CI environment and terminal
if [[ ${CI:-} == "true" ]] || ! [[ -t 0 ]]; then
  # Non-interactive/CI mode
  AUTO_RUN=true
else
  # Interactive terminal mode
  AUTO_RUN=false
fi

function intro_message {
  # Initial system message
  print "========================================================================"
  print " PowerStatus Build System"
  print "------------------------------------------------------------------------"
  print " Building universal binary for macOS 13+ (Ventura)"
  print " Components: IOKit power source monitoring CLI tool"
  print " Build artifacts: ./bin/ (final) ./build/ (temporary)"
  print " Note: Both directories excluded via .gitignore"
  print "========================================================================"
  print
}

function interactive_continue_prompt {
  if [[ $AUTO_RUN == "false" ]]; then
    print "Press Enter to continue."
    read -r
  fi
}

function build_debug {
  # Clean and create debug build workspace
  /bin/rm -rf ./build/debug
  /bin/mkdir -p ./build/debug

  # Compile for each architecture
  for arch in x86_64 arm64; do
    print "Building debug binary for ${arch}..."
    interactive_continue_prompt
    xcrun --sdk "$SDK" swiftc \
      -target "${arch}-apple-macos13" \
      -emit-executable \
      -Onone \
      -g \
      -debug-info-format=dwarf \
      -Xfrontend -emit-symbol-graph \
      -verify-debug-info \
      -warn-concurrency \
      -strict-concurrency=complete \
      -Xlinker -no_deduplicate \
      -o "./build/debug/powerstatus_${arch}_debug" \
      ./src/powerstatus.swift

    print "Verifying build:"

    # Verify dynamic library dependencies
    # Ensures Swift runtime links are present for debugging
    print
    print 'Checking dynamic library links (*.dylib)...'
    interactive_continue_prompt
    otool -L "./build/debug/powerstatus_${arch}_debug" | /usr/bin/grep --fixed-strings libswift | /usr/bin/awk '/.+\.dylib/ {print $1}'

    # Verify debug symbols presence
    # Each DW_TAG_compile_unit represents a debug info source unit
    printf "\nVerifying debug symbols presence. Look for a positive integer...\n"
    interactive_continue_prompt
    # Full source-level debug information from the .dSYM bundle
    typeset -i debug_symbol_count
    debug_symbol_count="$(
      dwarfdump --debug-info "./build/debug/powerstatus_${arch}_debug.dSYM/Contents/Resources/DWARF/powerstatus_${arch}_debug" |
        /usr/bin/grep --fixed-strings --count "DW_TAG_compile_unit"
    )"
    print "Source-level debug information from the .dSYM bundle:"
    printf "  dwarf symbol count: %d\n" "$debug_symbol_count"

    # Count of linkage symbols in the binary for basic stack traces
    # These are stripped in the release builds (in the dist directory)
    typeset -i linkage_symbol_count
    linkage_symbol_count="$(
      otool -l "./build/debug/powerstatus_${arch}_debug" |
        /usr/bin/awk '/cmd LC_SYMTAB/,/nsyms/ {if($1 == "nsyms") {print $2}}'
      # grep -A4 LC_SYMTAB |
      # grep nsyms # Number of symbols
    )"
    print "Linkage symbols in the binary for basic stack traces:"
    printf "  linkage symbol count: %d\n" "$linkage_symbol_count"

    # Verify dSYM UUID matches binary UUID
    printf "\nVerifying dSYM UUID matches binary UUID.\n"
    interactive_continue_prompt
    typeset uuid_binary uuid_dwarf
    uuid_binary="$(dwarfdump --uuid "./build/debug/powerstatus_${arch}_debug" | /usr/bin/awk '{print $2}')"
    uuid_dwarf="$(dwarfdump --uuid "./build/debug/powerstatus_${arch}_debug.dSYM" | /usr/bin/awk '{print $2}')"
    if [[ $uuid_binary == "$uuid_dwarf" ]]; then
      print "UUIDs match."
    else
      print -u2 "Error: UUID mismatch."
      print -u2 "  uuid_binary=$uuid_binary"
      print -u2 "  uuid_dwarf=$uuid_dwarf"
    fi
    # dwarfdump --uuid "./build/debug/powerstatus_${arch}_debug" "./build/debug/powerstatus_${arch}_debug.dSYM"
    print
  done

  # Symbolicate crashes using:
  # atos -arch arm64 -o ./build/debug/powerstatus_arm64_debug.dSYM/Contents/Resources/DWARF/powerstatus_debug -l 0x100000000

  ## Debugging Instructions:
  # For Apple Silicon debugging:
  # lldb ./build/debug/powerstatus_arm64_debug -s ./build/debug/powerstatus_arm64_debug.dSYM

  # For Intel debugging:
  # lldb ./build/debug/powerstatus_x86_64_debug -s ./build/debug/powerstatus_x86_64_debug.dSYM
}

function build_dist {
  # Clean and create build workspace
  /bin/rm -rf ./build/dist ./bin
  /bin/mkdir -p ./build/dist ./bin

  # Compile for each architecture
  for arch in x86_64 arm64; do
    print "Building distribution binary for ${arch}..."
    interactive_continue_prompt

    xcrun --sdk "$SDK" swiftc \
      -target "${arch}-apple-macos13" \
      -emit-executable \
      -O \
      -whole-module-optimization \
      -Xfrontend -enable-ossa-modules \
      -Xlinker -dead_strip \
      -Xcc -fstack-protector-strong \
      -o "./build/dist/powerstatus_${arch}" \
      ./src/powerstatus.swift

    # Strip symbols
    xcrun strip -Sx "./build/dist/powerstatus_${arch}"

    print "Verifying build:"

    # Verify ASLR (Address Space Layout Randomization)
    # Enhances security by randomizing memory addresses.
    # PIE (Position-Independent Executable) indicates ASLR is enabled.
    printf "\nVerifying ASLR (Address Space Layout Randomization) status...\n"
    interactive_continue_prompt
    if otool -hv "./build/dist/powerstatus_${arch}" |
      /usr/bin/grep --quiet --fixed-strings "PIE"; then
      print "ASLR is enabled."
    else
      print -u2 "Security Alert: ASLR is not enabled."
    fi
    print

    # Verify dynamic library dependencies
    # Ensures Swift runtime links are present for debugging
    print
    print 'Checking dynamic library links (*.dylib)...'
    interactive_continue_prompt
    otool -L "./build/dist/powerstatus_${arch}" | /usr/bin/grep --fixed-strings libswift | /usr/bin/awk '/.+\.dylib/ {print $1}'

    # Validate stack protector
    # Prevents stack-based buffer overflows by inserting "canary" values, which are checked before function returns to ensure stack integrity.
    printf "\nChecking the stack protector...\n"
    interactive_continue_prompt
    if objdump -d "./build/dist/powerstatus_${arch}" |
      /usr/bin/grep --quiet --fixed-strings "__stack_chk_fail"; then
      print -u2 "Security Alert: Failed to validate presence of stack protections."
    else
      print "Stack protections are present."
    fi
    print
  done

  # Create universal binary
  print "Creating universal binary..."
  xcrun lipo -create \
    ./build/dist/powerstatus_x86_64 \
    ./build/dist/powerstatus_arm64 \
    -output ./bin/powerstatus

  # Verify distribution binary architectures
  printf "\nChecking architectures...\n"
  interactive_continue_prompt
  if xcrun lipo ./bin/powerstatus -verify_arch x86_64 arm64 2> /dev/null; then
    print "Expected architectures are present."
  else
    print "Error: Architecture check failed."
    print "  Expected x86_64 and arm64 (universal binary)..."
    # Print a literal backslash without shell expansion
    # shellcheck disable=SC2016
    print '  `lipo -archs`:'
    xcrun lipo -archs ./bin/powerstatus 2> /dev/null
    print
    # Print a literal backslash without shell expansion
    # shellcheck disable=SC2016
    print '  `file`:'
    file ./bin/powerstatus # Should show universal binary
  fi

  # Add copyright and license info
  printf '\nAdding copyright and license into a *.license file...\n'
  pipx run reuse annotate --copyright="Todd Schulman" --copyright-prefix=spdx-string --license="Apache-2.0 OR BSD-2-Clause OR GPL-3.0-or-later" --force-dot-license "./bin/powerstatus"
}

function tests {
  typeset arch
  arch="$(uname -m)"
  print "Testing ./bin/powerstatus..."
  interactive_continue_prompt
  time ./bin/powerstatus --verbose

  case "$arch" in
    arm64)
      printf "\nOn arch %s. Skipping x86_64 tests.\n" "${arch}"
      printf "\nTesting ./build/dist/powerstatus_arm64...\n"
      time ./build/dist/powerstatus_arm64 --verbose
      printf "\nTesting ./build/debug/powerstatus_arm64_debug...\n"
      time ./build/debug/powerstatus_arm64_debug --verbose
      ;;
    x86_64)
      printf "\nOn arch %s. Skipping arm64 tests.\n" "${arch}"
      printf "\nTesting ./build/dist/powerstatus_x86_64...\n"
      time ./build/dist/powerstatus_x86_64 --verbose
      printf "\nTesting ./build/debug/powerstatus_x86_64_debug...\n"
      time ./build/debug/powerstatus_x86_64_debug --verbose
      ;;
    *) print -u2 "Error: Unexpected architecture reported by OS." ;;
  esac

  print
  print "Displaying build artifacts..."
  printf "\n  /usr/bin/find...\n"
  interactive_continue_prompt
  /usr/bin/find ./bin ./build -type f -not -path '*/.*' -print | /usr/bin/xargs /bin/ls -lAhF | /usr/bin/sed "s/$USER/<user>/g"
  print
  printf "\n  /bin/ls...\n"
  interactive_continue_prompt
  /bin/ls -lAhF ./bin ./build/{debug,dist} ./build/debug/powerstatus_{arm64,x86_64}_debug.dSYM/Contents/Resources/DWARF | /usr/bin/sed "s/$USER/<user>/g"
}

function outro_message {
  # Final system message
  print "========================================================================"
  print " PowerStatus Build System"
  print "------------------------------------------------------------------------"
  print " Completed all tasks. Exiting..."
  print "========================================================================"
  print
}

function main {
  intro_message
  build_debug
  print
  build_dist
  print
  tests
  print
  outro_message
}
main
