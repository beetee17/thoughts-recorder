import 'dart:ffi';

import 'package:Minutes/redux_/transcript.dart';
import 'package:Minutes/utils/colors.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/global_variables.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';

import '../redux_/rootStore.dart';
import '../utils/pair.dart';

class PunctuatedWord {
  static final EMPTY = PunctuatedWord('BLAHBLAH', -1, double.infinity);
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
                      .asMap()
                      .map((wordIndex, item) {
                        final span = WidgetSpan(
                            child: PunctuatedSpan(
                          word: item,
                          wordIndex: wordIndex,
                        ));
                        return MapEntry(wordIndex, span);
                      })
                      .values
                      .toList())),
        ),
      ]),
    );
  }
}

class PunctuatedSpan extends StatefulWidget {
  final PunctuatedWord word;
  final int wordIndex;
  const PunctuatedSpan({Key? key, required this.wordIndex, required this.word})
      : super(key: key);

  @override
  State<PunctuatedSpan> createState() => _PunctuatedSpanState();
}

class _PunctuatedSpanState extends State<PunctuatedSpan> {
  Offset _tapPosition = Offset.zero;
  bool _isHighlighted = false;

  _acceptChanges() {
    store.dispatch(EditWordAction(widget.word.content, widget.wordIndex));

    // print('edited word ${widget.wordIndex}');
    // print(store.state.transcript.transcriptText);
  }

  _declineChanges() {}

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, PunctuatedSpanVM>(
        distinct: true,
        converter: (store) => PunctuatedSpanVM(
            store.state.transcript.highlightSpan,
            store.state.transcript.highlightedParent,
            store.state.audio.duration),
        builder: (_, viewModel) {
          return AnimatedDefaultTextStyle(
            child: GestureDetector(
              child: Text('${widget.word.content} '),
              onLongPress: _declineChanges,
              onDoubleTap: _acceptChanges,
            ),
            style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: widget.word.punctuationValue == 0
                    ? textColor
                    : Color.lerp(
                        CupertinoColors.destructiveRed,
                        CupertinoColors.activeGreen.darkHighContrastColor,
                        widget.word.confidence)),
            duration: Duration(milliseconds: 300),
          );
        });
  }
}

class PunctuatedSpanVM {
  void Function(String) highlightParent;
  String? highlightedParent;
  Duration audioDuration;
  PunctuatedSpanVM(
      this.highlightParent, this.highlightedParent, this.audioDuration);
  @override
  bool operator ==(other) {
    return (other is PunctuatedSpanVM) &&
        (highlightParent == other.highlightParent) &&
        (highlightedParent == other.highlightedParent) &&
        (audioDuration == other.audioDuration);
  }

  @override
  int get hashCode {
    return Object.hash(highlightParent, highlightedParent, audioDuration);
  }
}
