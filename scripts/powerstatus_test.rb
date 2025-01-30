#! /usr/bin/env ruby

# SPDX-FileCopyrightText: Copyright 2025 Todd Schulman
#
# SPDX-License-Identifier: Apache-2.0 OR BSD-2-Clause OR GPL-3.0-or-later

# Main script documentation
# This script tests the `powerstatus` binary with different arguments,
# verifying the expected exit codes and checking for correct output
# on stdout and stderr.

# typed: strict
# frozen_string_literal: true

require "English"
require "open3"
require "optparse"

POWERSTATUS = "./bin/powerstatus"

# Check if the powerstatus binary exists and is executable
unless File.executable?(POWERSTATUS)
  $stderr.puts "Error: The powerstatus binary does not exist or is not executable."
  exit 1
end

# Usage banner
banner = <<~BANNER
  Usage: powerstatus_test [options]

  Description:
    Tests powerstatus for correct behavior under various conditions.

  Options:
BANNER

options = { verbose: 0, debug: false }

OptionParser.new do |opts|
  opts.banner = banner

  opts.on("-v", "--verbose[=N]", Integer, "Set verbosity level to N") do |v|
    options[:verbose] = if v.nil?
      1
    else
      v
    end
  end

  opts.on("--debug", "Enable debug mode") do
    options[:debug] = true
  end

  opts.on("-h", "--help", "Show this help message") do
    $stderr.puts opts
    $stderr.puts "\nIf an option is provided several times, the last set value is used."
    exit
  end
end.parse!

$stderr.puts "Debug: #{options.inspect}" if options[:debug]

module PowerstatusTest
  # The Tester class contains methods to test the `powerstatus` binary
  # with different arguments, verifying the expected exit codes and
  # checking for correct output on stdout and stderr.
  class Tester
    YELLOW = "\e[33m"
    GRAY = "\e[90m"
    GREEN = "\e[32m"
    RESET = "\e[0m"

    TESTS = [
      { name: "help", args: "--help", expected_code: 65, stderr_regex: /^Usage: powerstatus \[options\]$/ },
      { name: "no_args", args: "", expected_code: [0, 1, 2], stdout_check: lambda(&:empty?),
stderr_check: lambda(&:empty?) },
      { name: "double_dash", args: "-- --ignored", expected_code: [0, 1, 2],
message: "The double dash ended option parsing, as expected." },
      { name: "unknown_option", args: "--unknown", expected_code: 64, stderr_regex: /^Unknown option:/ },
      { name: "verbose", args: "--verbose", expected_code: [0, 1, 2],
stdout_regex: /^Device is (running on battery|plugged into (AC|UPS)).$/ },
      { name: "debug", args: "--debug", expected_code: [0, 1, 2], stderr_regex: /^Current power source type:/ },
    ].freeze

    def initialize(verbose: 0, debug: false)
      @verbose = verbose
      @debug = debug
      TESTS.each { |test| define_test_method(test) }
    end

    def define_test_method(test)
      self.class.define_method(:"test_#{test[:name]}") do
        args_display = test[:args].empty? ? "powerstatus" : "powerstatus #{test[:args]}"
        puts "Testing `#{args_display}`..."
        stdout, stderr, exit_code = capture_output_and_status("#{POWERSTATUS} #{test[:args]}")
        puts(test[:message]) if test[:message] && @verbose >= 1

        assert_exit_code(exit_code, test[:expected_code])
        if test[:stdout_regex] || test[:stdout_check]
          assert_output(stdout, test[:stdout_regex] || test[:stdout_check],
                        "stdout")
        end
        if test[:stderr_regex] || test[:stderr_check]
          assert_output(stderr, test[:stderr_regex] || test[:stderr_check],
                        "stderr")
        end

        puts "#{GREEN}Test passed!#{RESET}"
      end
    end

    def run_all_tests
      test_methods = methods.grep(/^test_/)
      test_methods.each_with_index do |test, index|
        send(test)
        puts if index < test_methods.size - 1
      end
    end

    private

    def run_command(command)
      system(command)
      $CHILD_STATUS.exitstatus
    end

    def capture_output_and_status(command)
      stdout, stderr, status = Open3.capture3(command)
      [stdout, stderr, status.exitstatus]
    end

    def assert_exit_code(exit_code, expected_codes)
      expected_codes = [expected_codes] unless expected_codes.is_a?(Array)
      if expected_codes.include?(exit_code)
        if expected_codes.size > 1
          puts "`powerstatus` exited with allowed code #{exit_code}." if @verbose >= 1
        elsif @verbose >= 1
          puts "`powerstatus` exited with code #{exit_code}, as expected."
        end
        if @verbose >= 2
          $stderr.puts "#{YELLOW}==>#{GRAY} Allowed exit codes for this test: #{expected_codes.inspect}.#{RESET}"
        end
      else
        $stderr.puts "Unexpected exit code: #{exit_code}. Expected one of: #{expected_codes.join(", ")}."
        exit 1
      end
    end

    def assert_output(output, check, stream)
      if check.is_a?(Regexp)
        if output.match?(check)
          puts "Output on #{stream} contained expected string." if @verbose >= 1
          $stderr.puts "#{YELLOW}==>#{GRAY} #{check.inspect}#{RESET}" if @verbose >= 2
        else
          $stderr.puts "Output on #{stream} did not contain expected string: #{GRAY}#{check.inspect}#{RESET}."
          exit 1
        end
      elsif check.respond_to?(:call)
        # puts "#{YELLOW}==>#{GRAY} Invoking callable check on #{stream}...#{RESET}" if @debug
        if check.call(output)
          puts "Output on #{stream} was empty, as expected." if @verbose >= 1
        else
          $stderr.puts "Output on #{stream} was not empty, which was unexpected."
          exit 1
        end
      else
        $stderr.puts "Output on #{stream} did not meet the condition."
        exit 1
      end
    end
  end
end

# Run the tests
tester = PowerstatusTest::Tester.new(verbose: options[:verbose], debug: options[:debug])
tester.run_all_tests
