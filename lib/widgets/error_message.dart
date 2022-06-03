import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/utils/global_variables.dart';
import 'package:leopard_demo/widgets/quote.dart';
import 'package:leopard_demo/widgets/secondary_icon_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ErrorMessage extends StatelessWidget {
  final String errorMessage;
  const ErrorMessage({Key? key, required this.errorMessage}) : super(key: key);

  DEFAULT_SPAN(String content) {
    return TextSpan(text: content, style: TextStyle(color: Colors.black));
  }

  QUOTE_SPAN(String content) {
    return TextSpan(text: content, style: TextStyle(color: Colors.black));
  }

  BOLD_SPAN(String content) {
    return TextSpan(
        text: content,
        style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black));
  }

  URL_SPAN(String content) {
    return TextSpan(
      text: content,
      style: TextStyle(
        decoration: TextDecoration.underline,
        color: Colors.blue,
      ),
      recognizer: new TapGestureRecognizer()
        ..onTap = () {
          launchUrl(Uri.parse(content));
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    final WidgetSpan PICOVOICE = WidgetSpan(
        child: GestureDetector(
      onTap: () => launchUrl(Uri.parse("https://picovoice.ai")),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 3.0),
        child: SvgPicture.asset(
          'assets/picovoice.svg',
          width: 70,
        ),
      ),
    ));

    final RichText FAQ = RichText(
        text: TextSpan(children: [
      DEFAULT_SPAN("This App relies on "),
      PICOVOICE,
      DEFAULT_SPAN(" technology to transcribe audio. \n\n"
          "At the time of writing, a "),
      PICOVOICE,
      DEFAULT_SPAN(" account is "),
      BOLD_SPAN("FREE"),
      DEFAULT_SPAN(" to create ("),
      BOLD_SPAN("NO credit card required"),
      DEFAULT_SPAN("). \n\n" "The free account allows you to transcribe "),
      BOLD_SPAN("100 HOURS"),
      DEFAULT_SPAN(
          " of audio per month, on up to 3 unique devices per month. \n\n"
          "From "),
      URL_SPAN("https://picovoice.ai/docs/faq/general/"),
      DEFAULT_SPAN(",\n"),
      WidgetSpan(
        child: Quote(
            author: null,
            quote:
                "Picovoice’s unique approach to speech recognition differentiates itself from other vendors. It doesn’t require data gathering to train models."),
      ),
      DEFAULT_SPAN("\n\nTherefore, both "),
      PICOVOICE,
      DEFAULT_SPAN(" and this app "),
      BOLD_SPAN("DO NOT"),
      DEFAULT_SPAN(" collect user audio/speech/voice data. \n\n"
          "To get started, sign up for a Picovoice account at "),
      URL_SPAN("https://console.picovoice.ai"),
      DEFAULT_SPAN(
          "\n\nAfter creating your free account, paste your unique access key into the Settings page.")
    ]));
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
                        builder: (context) => SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 40.0, horizontal: 10.0),
                            child: FAQ,
                          ),
                        ),
                      ),
                  icon: Icon(Icons.question_mark),
                  margin: EdgeInsets.only(top: 20))
            ],
          )),
    );
  }
}
