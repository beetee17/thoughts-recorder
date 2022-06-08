import 'package:flutter/material.dart';

Future<T> showSpinnerUntil<T>(
    BuildContext context, Future<T> Function() asyncFuction,
    {Duration? delay}) async {
  showDialog(
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
    context: context,
  );
  return Future.delayed(delay ?? Duration(milliseconds: 200), asyncFuction)
      .then((value) {
    Navigator.pop(context);
    return value;
  });
}
