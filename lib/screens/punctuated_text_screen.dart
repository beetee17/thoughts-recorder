import 'dart:ffi';

import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/global_variables.dart';
import 'package:flutter/material.dart';

import '../utils/pair.dart';

class PunctuatedWord {
  String content;
  int punctuationValue;
  double confidence;
  PunctuatedWord(this.content, this.punctuationValue, this.confidence);
}

class PunctuatedTextScreen extends StatelessWidget {
  final Map punctuatorResult;

  const PunctuatedTextScreen({Key? key, required this.punctuatorResult})
      : super(key: key);

  List<PunctuatedWord> formatPunctuatorResult(Map result) {
    final words = (punctuatorResult['words'] as List)
        .map((word) => word as String?)
        .whereType<String>()
        .toList();

    final allScores = (punctuatorResult['scores'] as List)
        .map((punctuationScores) => (punctuationScores as List)
            .map((score) => score as double?)
            .whereType<double>()
            .toList())
        .toList();

    print(allScores);

    final mask = (punctuatorResult['mask'] as List)
        .map((item) => item as bool?)
        .whereType<bool>()
        .toList();

    List<PunctuatedWord> punctuatedWords = [];
    int wordPos = 0;
    allScores.asMap().forEach((index, punctuationScores) {
      if (mask[index]) {
        final word = words[wordPos];
        final Pair<int, double> punctuationResult =
            Math.argmax(punctuationScores);
        final punctuatedWord = PunctuatedWord(
            word + punctuationMap[punctuationResult.first]!,
            punctuationResult.first,
            punctuationResult.second);
        punctuatedWords.add(punctuatedWord);
        wordPos += 1;
      }
    });

    return punctuatedWords;
  }

  @override
  Widget build(BuildContext context) {
    final punctuatedWords = formatPunctuatorResult(punctuatorResult);

    return Scaffold(
      appBar: AppBar(
          title: Text('Punctuated'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.of(context).pop(),
          )),
      resizeToAvoidBottomInset: false,
      body: RichText(
          text: TextSpan(
              children: punctuatedWords
                  .map((item) => TextSpan(
                      text: item.content + " ",
                      style: item.punctuationValue == 0
                          ? TextStyle(fontSize: 20)
                          : TextStyle(
                              fontSize: 20,
                              color: Color.lerp(
                                  Colors.orangeAccent.shade100,
                                  Colors.greenAccent.shade700,
                                  item.confidence))))
                  .toList())),
    );
  }
}
