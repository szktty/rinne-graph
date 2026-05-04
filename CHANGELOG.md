# Changelog

## Unreleased

* Enable WAL mode on database open to allow concurrent read/write access across multiple SQLite connections to the same file.
* Replaced the internal `DebugLogger` singleton with the standard `logging` package.
  Log output can be received by attaching a listener to `Logger.root`.
  Logger hierarchy: `rinne_graph.database` (database/transaction layer),
  `rinne_graph.traversal` (traversal layer).

## 0.7.0

* Initial release.