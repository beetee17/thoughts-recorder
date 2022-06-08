import 'package:flutter/cupertino.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux_/rootStore.dart';
import '../redux_/ui.dart';

class TextViewSegmentedControl extends StatelessWidget {
  final Function(int) onChange;
  const TextViewSegmentedControl({
    Key? key,
    required this.onChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, TextViewSegmentedControlVM>(
        converter: (store) =>
            TextViewSegmentedControlVM(store.state.ui.showMinutes),
        builder: (_, viewModel) {
          return CupertinoSlidingSegmentedControl(
            children: {0: Text('Minutes'), 1: Text('Preview')},
            onValueChanged: (newValue) => onChange(newValue as int),
            groupValue: viewModel.groupvalue,
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
