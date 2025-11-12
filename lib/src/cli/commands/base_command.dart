import 'dart:io';

import 'package:args/args.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';

/// Base class for CLI commands
abstract class CliCommand {
  CliCommand(this.name, this.description) {
    setupArguments();
  }

  /// Command name
  final String name;

  /// Command description
  final String description;

  /// Argument parser
  final ArgParser argParser = ArgParser();

  /// Setup arguments
  void setupArguments();

  /// Execute command
  Future<void> run(ArgResults results, CliConfig config);

  /// Show help
  void printHelp() {
    print('$name - $description');
    print('');
    print('Usage: rinne $name [options]');
    print('');
    print('Options:');
    print(argParser.usage);
  }

  /// Validate required option
  void validateRequiredOption(
      ArgResults results, String option, String description) {
    if (results[option] == null) {
      stderr.writeln('Error: $description is required (--$option)');
      exit(1);
    }
  }

  /// Validate file exists
  void validateFileExists(String filePath, String description) {
    if (!File(filePath).existsSync()) {
      stderr.writeln('Error: $description not found: $filePath');
      exit(1);
    }
  }

  /// Ensure directory exists (create if necessary)
  Future<void> ensureDirectoryExists(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Confirm overwrite of output file
  bool confirmOverwrite(String filePath, CliConfig config) {
    if (!File(filePath).existsSync()) {
      return true;
    }

    if (config.quiet) {
      return true; // Overwrite without confirmation in quiet mode
    }

    stdout.write('File $filePath already exists. Overwrite? (y/N): ');
    final input = stdin.readLineSync()?.toLowerCase();
    return input == 'y' || input == 'yes';
  }

  /// Show progress
  void showProgress(String message, CliConfig config) {
    if (!config.quiet) {
      stdout.write('\r$message');
    }
  }

  /// Complete progress
  void completeProgress(CliConfig config) {
    if (!config.quiet) {
      stdout.writeln();
    }
  }
}
