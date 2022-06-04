import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Minutes/widgets/secondary_icon_button.dart';
import 'package:Minutes/widgets/tutorial.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ErrorMessage extends StatelessWidget {
  final String errorMessage;
  const ErrorMessage({Key? key, required this.errorMessage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage,
                style: GoogleFonts.rubik(
                        fontSize: 28, fontWeight: FontWeight.w500, height: 1.4)
                    .merge(TextStyle(color: Colors.black54)),
              ),
              SecondaryIconButton(
                  onPress: () => showCupertinoModalBottomSheet(
                        expand: true,
                        context: context,
                        builder: (context) => Tutorial(),
                      ),
                  icon: Icon(Icons.question_mark),
                  margin: EdgeInsets.only(top: 20))
            ],
          )),
    );
  }
}
