import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:provider/provider.dart';

class ErrorMessage extends StatelessWidget {
  const ErrorMessage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ErrorMessageVM>(
      converter: (store) => ErrorMessageVM(store.state.untitled.errorMessage),
      builder: (_, viewModel) {
        final isError = viewModel.errorMessage != null;
        return Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(left: 20, right: 20),
            padding: EdgeInsets.all(5),
            decoration: !isError
                ? null
                : BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(5)),
            child: !isError
                ? null
                : Text(
                    viewModel.errorMessage!,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ));
      },
    );
  }
}

class ErrorMessageVM {
  String? errorMessage;
  ErrorMessageVM(this.errorMessage);
}
