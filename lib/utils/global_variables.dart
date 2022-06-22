final Duration maxRecordingLength = Duration(hours: 1);
final Map<int, String> punctuationMap = {
  0: 'OO',
  1: ',O',
  2: '.O',
  3: '?O',
  4: 'OU',
  5: ',U',
  6: '.U',
  7: '?U'
};
final punctuationCharacters = RegExp(r"[,:\-–.!;?]");
final invalidCharacters = RegExp(r'\s+');
