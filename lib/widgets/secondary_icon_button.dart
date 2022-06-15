import 'package:Minutes/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SecondaryIconButton extends StatelessWidget {
  final Function onPress;
  final Widget icon;
  final EdgeInsetsGeometry margin;
  const SecondaryIconButton(
      {Key? key,
      required this.onPress,
      required this.icon,
      required this.margin})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(50),
        ),
        color: CupertinoColors.darkBackgroundGray,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          )
        ],
      ),
      child: IconButton(
        onPressed: () => onPress(),
        icon: icon,
        color: CupertinoColors.systemGrey4,
      ),
    );
  }
}
