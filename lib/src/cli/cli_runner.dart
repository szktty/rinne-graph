import 'dart:io';

import 'package:args/args.dart';
import 'package:rinne_graph/src/cli/commands/commands.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';

/// Main runner for RinneGraph command-line tool
class CliRunner {
  CliRunner() {
    _setupCommands();
  }

  final ArgParser _parser = ArgParser();
  final Map<String, CliCommand> _commands = {};

  void _setupCommands() {
    // Global options
    _parser.addFlag(
      'help',
      abbr: 'h',
      help: 'Show help',
      negatable: false,
    );
    _parser.addFlag(
      'version',
      help: 'Show version information',
      negatable: false,
    );
    _parser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Output verbose logs',
      negatable: false,
    );
    _parser.addFlag(
      'quiet',
      abbr: 'q',
      help: 'Suppress output except errors',
      negatable: false,
    );
    _parser.addOption(
      'config',
      help: 'Specify configuration file',
    );

    // Register subcommands
    _registerCommand(CreateCommand());
    _registerCommand(ImportCommand());
    _registerCommand(ExportCommand());
    _registerCommand(InfoCommand());
    _registerCommand(ValidateCommand());
    _registerCommand(QueryCommand());
    _registerCommand(SampleCommand());
  }

  void _registerCommand(CliCommand command) {
    _commands[command.name] = command;
    _parser.addCommand(command.name, command.argParser);
  }

  Future<void> run(List<String> arguments) async {
    try {
      // Special case: handle command name + --help
      if (arguments.length >= 2 && arguments[1] == '--help') {
        final commandName = arguments[0];
        final command = _commands[commandName];
        if (command != null) {
          command.printHelp();
          return;
        }
      }

      // Special case: handle import json --help, import csv --help
      if (arguments.length >= 3 &&
          arguments[2] == '--help' &&
          arguments[0] == 'import') {
        final subcommand = arguments[1];
        final command = _commands['import'];
        if (command != null && command is ImportCommand) {
          if (subcommand == 'json') {
            command.printJsonHelp();
            return;
          } else if (subcommand == 'csv') {
            command.printCsvHelp();
            return;
          }
        }
      }

      final results = _parser.parse(arguments);

      // Handle global options
      if (results['help'] as bool) {
        _printUsage();
        return;
      }

      if (results['version'] as bool) {
        _printVersion();
        return;
      }

      // Initialize configuration
      final config = CliConfig();
      if (results['config'] != null) {
        await config.loadFromFile(results['config'] as String);
      } else {
        await config.loadDefault();
      }

      // Set log level
      if (results['verbose'] as bool) {
        config.setVerbose(true);
      }
      if (results['quiet'] as bool) {
        config.setQuiet(true);
      }

      // Execute subcommand
      if (results.command == null) {
        _printUsage();
        exit(1);
      }

      final commandName = results.command!.name;
      final command = _commands[commandName];
      if (command == null) {
        stderr.writeln('Unknown command: $commandName');
        exit(1);
      }

      await command.run(results.command!, config);
    } on FormatException catch (e) {
      stderr.writeln('Error: ${e.message}');
      stderr.writeln();
      _printUsage();
      exit(1);
    }
  }

  void _printUsage() {
    print('RinneGraph - Graph database operation tool');
    print('');
    print('Usage: rinne <command> [options]');
    print('');
    print('Available commands:');
    for (final command in _commands.values) {
      print('  ${command.name.padRight(12)} ${command.description}');
    }
    print('');
    print('Global options:');
    print(_parser.usage);
    print('');
    print('Detailed help: rinne <command> --help');
  }

  void _printVersion() {
    print('RinneGraph CLI version 0.0.1');
  }
}
