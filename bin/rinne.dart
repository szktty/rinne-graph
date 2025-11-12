#!/usr/bin/env dart

import 'dart:io';

import 'package:rinne_graph/src/cli/cli_runner.dart';

Future<void> main(List<String> arguments) async {
  final runner = CliRunner();

  try {
    await runner.run(arguments);
  } on Exception catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
