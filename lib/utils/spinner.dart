import 'package:flutter/material.dart';

showSpinnerAfter<T>(BuildContext context, Future<T> Function() asyncFuction) {
  showDialog(
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
    context: context,
  );
  asyncFuction().then((value) => Navigator.of(context).pop());
}
