import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:leopard_demo/providers/main_provider.dart';
import 'package:provider/provider.dart';

class StatusArea extends StatelessWidget {
  const StatusArea({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusAreaText = context.watch<MainProvider>().statusAreaText;
    return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(bottom: 5),
        child: Text(
          statusAreaText,
          style: TextStyle(color: Colors.black),
        ));
  }
}
