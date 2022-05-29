import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/providers/main_provider.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:provider/provider.dart';

class StatusArea extends StatelessWidget {
  const StatusArea({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusAreaText = context.watch<MainProvider>().statusAreaText;
    return StoreConnector<AppState, StatusAreaVM>(
        converter: (store) => StatusAreaVM(store.state.untitled.statusAreaText),
        builder: (_, viewModel) {
          return Container(
              alignment: Alignment.center,
              padding: EdgeInsets.only(bottom: 5),
              child: Text(
                viewModel.text,
                style: TextStyle(color: Colors.black),
              ));
        });
  }
}

class StatusAreaVM {
  String text;
  StatusAreaVM(this.text);
}
