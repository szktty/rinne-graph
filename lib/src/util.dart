String escapeSqlString(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('"', r'\"')
      .replaceAll('\b', r'\b')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t')
      .replaceAll('\x1A', r'\Z'); // Ctrl+Z
}
