import 'dart:ffi';

import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/global_variables.dart';
import 'package:flutter/cupertino.dart';
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
      if (index < mask.length && mask[index]) {
        String word = words[wordPos];

        final Pair<int, double> punctuationResult =
            Math.argmax(punctuationScores);
        if (punctuationResult.first > 1 && wordPos + 1 < words.length) {
          // Capitalise the next word if the previous punctuation is not a comma
          words[wordPos + 1] = words[wordPos + 1].toCapitalized();
        }

        if (wordPos == 0) {
          // Capitalise the first word
          word = word.toCapitalized();
        }

        final punctuatedWord = PunctuatedWord(
            word + punctuationMap[punctuationResult.first]!,
            punctuationResult.first,
            punctuationResult.second);
        punctuatedWords.add(punctuatedWord);

        print('${punctuatedWord.content} ${punctuatedWord.confidence}');

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
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: RichText(
              text: TextSpan(
                  children: punctuatedWords
                      .map((item) => TextSpan(
                          text: item.content + " ",
                          style: item.punctuationValue == 0
                              ? TextStyle(fontSize: 20)
                              : TextStyle(
                                  fontSize: 20,
                                  color: Color.lerp(
                                      CupertinoColors.destructiveRed,
                                      CupertinoColors
                                          .activeGreen.darkHighContrastColor,
                                      item.confidence))))
                      .toList())),
        ),
      ]),
    );
  }
}
