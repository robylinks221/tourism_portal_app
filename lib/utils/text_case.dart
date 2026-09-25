extension TitleCaseText on String {
  String toTitleCase() {
    final matches =
        RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)?").allMatches(this).toList();
    if (matches.isEmpty) return this;

    const minorWords = <String>{
      'a',
      'an',
      'and',
      'as',
      'at',
      'by',
      'for',
      'from',
      'in',
      'of',
      'on',
      'or',
      'the',
      'to',
      'with',
    };
    const acronyms = <String>{'AC', 'API', 'GPS', 'ID', 'UGX', 'URL', 'USD'};
    final output = StringBuffer();
    var cursor = 0;

    for (var index = 0; index < matches.length; index++) {
      final match = matches[index];
      final word = match.group(0)!;
      final lower = word.toLowerCase();
      output.write(substring(cursor, match.start));

      if (acronyms.contains(word.toUpperCase())) {
        output.write(word.toUpperCase());
      } else if (index > 0 &&
          index < matches.length - 1 &&
          minorWords.contains(lower)) {
        output.write(lower);
      } else {
        output.write('${lower[0].toUpperCase()}${lower.substring(1)}');
      }
      cursor = match.end;
    }

    output.write(substring(cursor));
    return output.toString();
  }
}
