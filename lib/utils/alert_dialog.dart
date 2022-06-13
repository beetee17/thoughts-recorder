import 'package:Minutes/utils/colors.dart';
import 'package:flutter/material.dart';

Future<void> showAlertDialog(BuildContext context, String title, String content,
    {List<Widget>? actions}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: accentColor,
        title: Text(title),
        content: Text(content),
        actions: actions ??
            <Widget>[
              TextButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
      );
    },
  );
}
