import 'package:flutter/material.dart';

Future<void> showTextInputDialog(BuildContext context, Text title,
    String initialText, Function(String) confirm) async {
  final textEditingController = TextEditingController(text: initialText);
  return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: title,
          content: TextField(
            controller: textEditingController,
            decoration: InputDecoration(hintText: "Text Field in Dialog"),
          ),
          actions: <Widget>[
            TextButton(
                child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.pop(context);
                confirm(textEditingController.text);
              },
            ),
          ],
        );
      });
}
