import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';

class StatusArea extends StatelessWidget {
  const StatusArea({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, StatusAreaVM>(
        distinct: true,
        converter: (store) => StatusAreaVM(store.state.status.statusAreaText),
        builder: (_, viewModel) {
          return Text(
            viewModel.text,
            style: TextStyle(fontWeight: FontWeight.w700),
          );
        });
  }
}

class StatusAreaVM {
  String text;
  StatusAreaVM(this.text);
  @override
  bool operator ==(other) {
    return (other is StatusAreaVM) && (text == other.text);
  }

  @override
  int get hashCode {
    return text.hashCode;
  }
}
