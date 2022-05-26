import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

class StatusArea extends StatelessWidget {
  final String statusAreaText;
  const StatusArea({Key? key, required this.statusAreaText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(bottom: 5),
        child: Text(
          statusAreaText,
          style: TextStyle(color: Colors.black),
        ));
  }
}
