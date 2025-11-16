.PHONY: gen fix command arizal

gen:
	dart run build_runner build --delete-conflicting-outputs

fix:
	dart fix --apply lib
	dart fix --apply test
	dart format lib test

command:
	dart compile exe -o bin/rinne bin/rinne.dart
