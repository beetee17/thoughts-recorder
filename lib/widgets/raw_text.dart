import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/redux_/untitled.dart';
import 'package:leopard_demo/utils/extensions.dart';

import '../utils/pair.dart';

class RawTextList extends StatefulWidget {
  const RawTextList({Key? key}) : super(key: key);

  @override
  State<RawTextList> createState() => _RawTextListState();
}

class _RawTextListState extends State<RawTextList> {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RawTextListVM>(
        converter: ((store) =>
            RawTextListVM(store.state.untitled.transcriptTextList)),
        distinct: true,
        builder: (_, viewModel) {
          return ListView(
            children: viewModel.transcriptTextList
                .asMap()
                .map((index, partialTranscript) {
                  return MapEntry(
                      index,
                      RawTextField(
                        index: index,
                        partialTranscript: partialTranscript,
                      ));
                })
                .values
                .toList(),
          );
        });
  }
}

class RawTextField extends StatefulWidget {
  final int index;
  final Pair<String, double> partialTranscript;
  const RawTextField(
      {Key? key, required this.partialTranscript, required this.index})
      : super(key: key);

  @override
  State<RawTextField> createState() => _RawTextFieldState();
}

class _RawTextFieldState extends State<RawTextField> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController =
        TextEditingController(text: widget.partialTranscript.first);
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RawTextFieldVM>(
        converter: (store) =>
            RawTextFieldVM(store.state.untitled.highlightedSpanIndex),
        builder: (_, viewModel) {
          TextStyle shouldHighlightSpan() {
            if (viewModel.highlightedSpanIndex == widget.index) {
              return TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold);
            }
            return TextStyle(color: Color.fromARGB(205, 0, 0, 0));
          }

          return Container(
            padding: EdgeInsets.symmetric(vertical: 0),
            child: TextField(
                onChanged: (updatedText) {
                  store.dispatch(UpdateTranscriptTextList(widget.index,
                      Pair(updatedText, widget.partialTranscript.second)));
                },
                maxLines: null,
                style: shouldHighlightSpan(),
                decoration: InputDecoration(
                    prefixText:
                        '${Duration(seconds: widget.partialTranscript.second.toInt()).toAudioDurationString()}  ',
                    prefixStyle: TextStyle(color: Colors.grey)),
                controller: _textEditingController),
          );
        });
  }
}

class RawTextListVM {
  List<Pair<String, double>> transcriptTextList;
  RawTextListVM(this.transcriptTextList);
  @override
  bool operator ==(other) {
    return (other is RawTextListVM) &&
        (transcriptTextList == other.transcriptTextList);
  }

  @override
  int get hashCode {
    return transcriptTextList.hashCode;
  }
}

class RawTextFieldVM {
  int? highlightedSpanIndex;
  RawTextFieldVM(this.highlightedSpanIndex);
  @override
  bool operator ==(other) {
    return (other is RawTextFieldVM) &&
        (highlightedSpanIndex == other.highlightedSpanIndex);
  }

  @override
  int get hashCode {
    return highlightedSpanIndex.hashCode;
  }
}
