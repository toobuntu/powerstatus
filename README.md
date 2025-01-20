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

### Compile

To compile `powerstatus` yourself, first clone the repository, ensure you have the Xcode Command Line Tools installed, and then run:

```sh
mkdir bin
xcrun swiftc -Osize -o bin/powerstatus src/powerstatus.swift
```

After compiling, move the `powerstatus` binary to a directory in your `PATH` (e.g., `/usr/local/bin`) for convenient access:

```sh
sudo mv bin/powerstatus /usr/local/bin/
```

And that’s it! You’re all set to use `powerstatus`.

### Build dependencies

To make sure you have the necessary tools for compiling, install Xcode Command Line Tools with the following command:

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
