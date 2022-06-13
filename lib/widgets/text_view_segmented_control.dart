import 'package:Minutes/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux_/rootStore.dart';
import '../redux_/ui.dart';

class TextViewSegmentedControl extends StatelessWidget {
  final Function(int) onChange;
  TextViewSegmentedControl({
    Key? key,
    required this.onChange,
  }) : super(key: key);

  Tween<double> _slideTween = Tween(begin: 1, end: 4);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, TextViewSegmentedControlVM>(
        converter: (store) =>
            TextViewSegmentedControlVM(store.state.ui.showMinutes),
        builder: (_, viewModel) {
          return Container(
            width: 300,
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: Duration(milliseconds: 300),
                  alignment: viewModel.showMinutes
                      ? Alignment.center
                      : Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => onChange(0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.list_bullet,
                          color:
                              viewModel.showMinutes ? Colors.blue : textColor,
                          size: 20,
                        ),
                        SizedBox(width: 5),
                        AnimatedDefaultTextStyle(
                            child: Text('Minutes'),
                            style: TextStyle(
                                color: viewModel.showMinutes
                                    ? Colors.blue
                                    : textColor),
                            duration: Duration(milliseconds: 300))
                      ],
                    ),
                    style: viewModel.showMinutes
                        ? ButtonStyle(
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    side: BorderSide(
                                        color: Colors.blue,
                                        width: 1,
                                        style: BorderStyle.solid),
                                    borderRadius: BorderRadius.circular(50))))
                        : ButtonStyle(),
                  ),
                ),
                AnimatedAlign(
                  duration: Duration(milliseconds: 300),
                  alignment: viewModel.showMinutes
                      ? Alignment.centerRight
                      : Alignment.center,
                  child: TextButton(
                    onPressed: () => onChange(1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.eye,
                          color:
                              viewModel.showMinutes ? textColor : Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 5),
                        AnimatedDefaultTextStyle(
                            child: Text('Preview'),
                            style: TextStyle(
                                color: viewModel.showMinutes
                                    ? textColor
                                    : Colors.blue),
                            duration: Duration(milliseconds: 300)),
                      ],
                    ),
                    style: viewModel.showMinutes
                        ? ButtonStyle()
                        : ButtonStyle(
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    side: BorderSide(
                                        color: Colors.blue,
                                        width: 1,
                                        style: BorderStyle.solid),
                                    borderRadius: BorderRadius.circular(50)))),
                  ),
                ),
              ],
            ),
          );
        });
  }
}

class TextViewSegmentedControlVM {
  bool showMinutes;
  int get groupvalue => showMinutes ? 0 : 1;
  TextViewSegmentedControlVM(this.showMinutes);
  @override
  bool operator ==(other) {
    return (other is TextViewSegmentedControlVM) &&
        (showMinutes == other.showMinutes);
  }

  @override
  int get hashCode {
    return showMinutes.hashCode;
  }
}
