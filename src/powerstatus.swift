// SPDX-FileCopyrightText: Copyright 2025 Todd Schulman
//
// SPDX-License-Identifier: Apache-2.0 OR BSD-2-Clause OR GPL-3.0-or-later
//
// SPDX-FileType: SOURCE
//
// SPDX-FileName: ./src/powerstatus.swift

/*
 A command-line tool to check the current power source of the device
 (whether it is running on battery or plugged into power).

 Usage:
   powerstatus [options]

 Options:
   -v, --verbose      Enable verbose output
   --debug            Enable debug output

 Exit Code Summary:
   0: Device is running on battery.
   1: Device is plugged into AC.
   2: Device is plugged into UPS.

 Dependencies:
   This program is designed to work on macOS, and uses the IOKit
   framework to retrieve power source information.
 */

import Foundation
import IOKit.ps

// Constants for exit codes
// exit() expects Int32
let exitCodeBattery: Int32 = 0
let exitCodeAC: Int32 = 1
let exitCodeUPS: Int32 = 2
let exitCodeUnknownOption: Int32 = 64
let exitCodeUsage: Int32 = 65
let exitCodeFailedRetrieve: Int32 = 70
let exitCodeFailedType: Int32 = 71
let exitCodeUnrecognized: Int32 = 80
let exitCodeUnexpected: Int32 = 99

// Constants for power source types
let batteryPower = "Battery Power" // kBatteryPower
let upsPower = "UPS Power" // kUPSPower
let acPower = "AC Power" // kACPower

// Custom error enum
enum PowerSourceError: Error {
    case powerSourcesInfoUnavailable
    case providingPowerSourceTypeUnavailable
    case failedToRetrievePowerSources
    case failedToGetPowerSourceType
    case unrecognizedPowerSourceType(String)
    case unknownOption(String) // For unknown options
}

// Define the ParsedArguments struct
struct ParsedArguments {
    let verbose: Bool
    let debug: Bool
    let additionalArgs: [String]
}

// Helper function for printing messages
func printMessage(_ message: String, toStderr: Bool) {
    let outputStream = toStderr ? stderr : stdout
    fputs(message, outputStream) // Write the message
    fputs("\n", outputStream) // Write the newline
}

func assignPowerSourceTypeCode(verbose _: Bool, debug: Bool) throws -> Int32 {
    guard let powerSourcesInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
        throw PowerSourceError.failedToRetrievePowerSources
    }

    guard let providingPowerSourceType = IOPSGetProvidingPowerSourceType(powerSourcesInfo)?.takeRetainedValue() else {
        throw PowerSourceError.failedToGetPowerSourceType
    }

    let powerSourceType = providingPowerSourceType as String

    if debug {
        var outputString = "Current power source type: "
        outputString.append(powerSourceType)
        printMessage(outputString, toStderr: true)
    }

    switch powerSourceType {
    case batteryPower:
        return exitCodeBattery
    case acPower:
        return exitCodeAC
    case upsPower:
        return exitCodeUPS
    default:
        throw PowerSourceError.unrecognizedPowerSourceType(powerSourceType)
    }
}

func printUsage() {
    let exitCodes = [
        (exitCodeBattery, "Device is running on battery."),
        (exitCodeAC, "Device is plugged into AC."),
        (exitCodeUPS, "Device is plugged into UPS."),
        (exitCodeUnknownOption, "Unknown option provided."),
        (exitCodeUsage, "Usage message shown."),
        (exitCodeFailedRetrieve, "Failed to retrieve power sources."),
        (exitCodeFailedType, "Failed to get power source type."),
        (exitCodeUnrecognized, "Unknown power source type."),
        (exitCodeUnexpected, "Unexpected error.")
    ]

    let formattedExitCodes = exitCodes.map { String(format: " %2d: %@", $0.0, $0.1) }.joined(separator: "\n")

    let usageMessage = """
    Usage: powerstatus [options]

    Check the current power source type (Battery or AC/UPS).

    Options:
      -v, --verbose      Enable verbose output
      --debug            Enable debug output
      -h, --help         Show this help message

    Exit Codes:
    \(formattedExitCodes)
    """
    printMessage(usageMessage, toStderr: true)
}

// Parse command-line arguments
func parseArguments() throws -> ParsedArguments {
    var verbose = false
    var debug = false
    var additionalArgs: [String] = []
    var parsingOptions = true

    for arg in CommandLine.arguments.dropFirst() {
        if parsingOptions {
        switch arg {
            case "--":
                parsingOptions = false
            case "-v", "--verbose":
                verbose = true
            case "--debug":
                debug = true
            case "-h", "--help":
                printUsage()
                exit(exitCodeUsage) // Exit after printing usage message
            default:
                if arg.hasPrefix("-") {
                    throw PowerSourceError.unknownOption(arg)
                } else {
                    parsingOptions = false
                    additionalArgs.append(arg)
                }
            }
        } else {
            additionalArgs.append(arg)
        }
    }

    return ParsedArguments(verbose: verbose, debug: debug, additionalArgs: additionalArgs)
}

func handleVerboseOutput(for powerSourceTypeCode: Int32) {
    switch powerSourceTypeCode {
    case exitCodeBattery:
        print("Device is running on battery.")
    case exitCodeAC:
        print("Device is plugged into AC.")
    case exitCodeUPS:
        print("Device is plugged into UPS.")
    default:
        print("Unknown power source.")
    }
}

func printExitMessage(for powerSourceTypeCode: Int32) {
    var outputStream = "Exiting with status: "
    outputStream.append(String(powerSourceTypeCode)) // Convert Int32 to String
    printMessage(outputStream, toStderr: true)
}

func processPowerSourceInfo(verbose: Bool, debug: Bool) throws -> Int32 {
    let powerSourceTypeCode = try assignPowerSourceTypeCode(verbose: verbose, debug: debug)

    if debug {
        printExitMessage(for: powerSourceTypeCode)
    }

    if verbose {
        handleVerboseOutput(for: powerSourceTypeCode)
    }

    return powerSourceTypeCode
}

func main() {
    do {
        let parsedArguments = try parseArguments()
        let verbose = parsedArguments.verbose
        let debug = parsedArguments.debug

        // Process power source information
        let powerSourceTypeCode = try processPowerSourceInfo(verbose: verbose, debug: debug)

        // Exit with the correct exit code based on power source
        exit(powerSourceTypeCode)

    } catch PowerSourceError.powerSourcesInfoUnavailable {
        printMessage("Failed to retrieve power sources information.", toStderr: true)
        exit(exitCodeFailedRetrieve)

    } catch PowerSourceError.providingPowerSourceTypeUnavailable {
        printMessage("Failed to get providing power source type.", toStderr: true)
        exit(exitCodeFailedType)

    } catch let PowerSourceError.unrecognizedPowerSourceType(type) {
        printMessage("Unrecognized power source type: \(type)", toStderr: true)
        exit(exitCodeUnrecognized)

    } catch let PowerSourceError.unknownOption(option) {
        printMessage("Unknown option: \(option)", toStderr: true)
        printUsage()
        exit(exitCodeUnknownOption)

    } catch {
        printMessage("Unexpected error occurred.", toStderr: true)
        exit(exitCodeUnknownOption)
    }
}

main()
