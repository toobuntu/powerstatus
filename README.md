<!--
SPDX-FileCopyrightText: Copyright 2025 Todd Schulman

SPDX-License-Identifier: Apache-2.0 OR BSD-2-Clause OR GPL-3.0-or-later
-->

# powerstatus
[![standard-readme compliant](https://img.shields.io/badge/standard--readme-OK-green.svg)](https://github.com/RichardLitt/standard-readme)
![License: Apache--2.0 OR BSD--2--Clause OR GPL--3.0--or--later](https://img.shields.io/badge/License-Apache--2.0%20OR%20BSD--2--Clause%20OR%20GPL--3.0--or--later-lightgrey)
![GitHub commits since latest release](https://img.shields.io/github/commits-since/toobuntu/powerstatus/latest)
![GitHub last commit](https://img.shields.io/github/last-commit/toobuntu/powerstatus)
![Endpoint Badge](https://img.shields.io/endpoint?url=https%3A%2F%2Floc-counter.onrender.com%2F%3Frepo%3Dtoobuntu%2Fpowerstatus%26branch%3Dmain%26ignored%3D.github%2CLICENSES%2CREADME.md%26languages%3DSwift%26stat%3DlinesOfCode&label=lines%20of%20Swift%20code) <!-- loc-count wrapper for codetabs.com allows specifying a code language; https://github.com/shdwmtr/gloc -->
![GitHub Release Date](https://img.shields.io/github/release-date/toobuntu/powerstatus)
![GitHub Created At](https://img.shields.io/github/created-at/toobuntu/powerstatus)

Check the current power source type (Battery or AC/UPS).

`powerstatus` is a command-line tool written in Swift to determine the current power source of a macOS device (battery, AC, or UPS) and exit with a corresponding status code.

## Install

You can either download a precompiled binary or compile it yourself.

### Download

The precompiled binary is a universal build, compatible with both Intel and Apple Silicon Macs. To download it, run:

```sh
curl --fail --silent --show-error --location --output-dir bin --create-dirs --remote-name --url "https://github.com/toobuntu/powerstatus/releases/latest/download/powerstatus"

# It’s not signed or notarized, so remove any potential runtime issues
if xattr -p com.apple.quarantine bin/powerstatus 2>/dev/null; then
  xattr -d com.apple.quarantine bin/powerstatus
fi
```

<!--
  Note: For more details on running software that hasn’t been signed or notarized, see Apple’s [Gatekeeper documentation](https://support.apple.com/en-us/102445#openanyway).
-->

Install to your `PATH` (e.g., `/usr/local/bin`):

```sh
# Install to your PATH for global access
sudo install -m 0755 bin/powerstatus /usr/local/bin/

# Run it from anywhere
powerstatus --help
```

Or, run it directly from the `bin` directory:

```sh
# Make it executable
chmod +x bin/powerstatus

# Run directly from the bin directory
./bin/powerstatus --help
```

### Compile

If you’d rather compile the binary yourself, first clone this repository and ensure the Xcode Command Line Tools are installed. Then run:

```sh
mkdir bin
xcrun swiftc -Osize -o bin/powerstatus src/powerstatus.swift
```

And that’s it! You’re all set to use `powerstatus`. There’s no need to code sign or notarize software for it to run on the machine where it was compiled.

Once compiled, you can either run it directly from the `bin` directory or install it to a directory in your `PATH` and run it from anywhere:

```sh
# Run directly from the bin directory
./bin/powerstatus --help

# Or, install to a directory in your PATH (e.g., /usr/local/bin)
sudo install -m 0755 bin/powerstatus /usr/local/bin/
powerstatus --help
```

### Build dependencies

The Swift compiler is provided by Xcode Command Line Tools, which you can install with:

```sh
xcode-select --install
```

## Usage

```sh
powerstatus [options]

Options:
  -v, --verbose      Enable verbose output
  --debug            Enable debug output
  -h, --help         Show this help message

Exit Codes:
 0: Device is running on battery.
 1: Device is plugged into AC.
 2: Device is plugged into UPS.
```

## Compatibility

This command-line utility supports macOS 13 (Ventura) and later. Note that testing on macOS versions earlier than 13 is no longer feasible as GitHub runners only support macOS 13 and later.

The program relies on the `IOKit` framework, specifically using `IOPSCopyPowerSourcesInfo` and `IOPSGetProvidingPowerSourceType` functions. These functions have been available since macOS 10.0. However, considering modern Swift features and compiling requirements, the minimum macOS version that can be targeted is macOS 10.12 (Sierra).

For detailed build instructions on older macOS versions, refer to the [BUILD.md](./docs/BUILD.md) file.

For debugging instructions, refer to the [DEBUGGING.md](./docs/DEBUGGING.md) file.

## If You Want To Thank Me

- You can star ⭐️ this project on GitHub
- Or share the program on social networks


## Maintainer

👤 Todd Schulman

* Github: [@toobuntu](https://github.com/toobuntu)

## Contributing

Contributions are welcome. Please open an issue or submit a pull request for bug reports and feature requests. For major changes, please open an issue first to discuss what you would like to change.

Small note: If editing the README, please conform to the [standard-readme](https://github.com/RichardLitt/standard-readme) specification.

## License

This project is available under your choice of the following licenses:

- Apache-2.0
- BSD-2-Clause
- GPL-3.0-or-later

You may select any of those, or use a combination of them. The default license is Apache-2.0, in accordance with GNU guidelines for small programs with fewer than 300 lines of code.
