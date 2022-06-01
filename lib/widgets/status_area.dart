import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';

class StatusArea extends StatelessWidget {
  const StatusArea({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, StatusAreaVM>(
        converter: (store) => StatusAreaVM(store.state.untitled.statusAreaText),
        builder: (_, viewModel) {
          return Text(
            viewModel.text,
            style: TextStyle(color: Colors.black),
          );
        });
  }
}

class StatusAreaVM {
  String text;
  StatusAreaVM(this.text);
}
