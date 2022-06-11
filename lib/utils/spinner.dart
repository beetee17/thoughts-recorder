import 'package:flutter/material.dart';

Future<T?> showSpinnerUntil<T>(
    BuildContext context, Future<T?> Function() asyncFuction,
    {Duration? delay}) async {
  showDialog(
    barrierLabel: 'Dismiss',
    barrierDismissible: true,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
    context: context,
  );
  return Future.delayed(delay ?? Duration(milliseconds: 200), asyncFuction)
      .then((value) {
    Navigator.of(context, rootNavigator: true).pop();
    return value;
  }).onError((error, stackTrace) {
    Navigator.of(context, rootNavigator: true).pop();
    return null;
  });
}
