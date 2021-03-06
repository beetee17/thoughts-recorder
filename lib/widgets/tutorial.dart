import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Minutes/widgets/quote.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/settings_screen.dart';

class Tutorial extends StatelessWidget {
  final TextStyle defaultStyle = TextStyle(fontSize: 15, height: 1.75);
  DEFAULT_SPAN(String content) {
    return TextSpan(text: content, style: defaultStyle);
  }

  BOLD_SPAN(String content) {
    return TextSpan(
        text: content,
        style: defaultStyle.merge(TextStyle(fontWeight: FontWeight.w800)));
  }

  URL_SPAN(String content) {
    return TextSpan(
      text: content,
      style: defaultStyle.merge(TextStyle(
        decoration: TextDecoration.underline,
        color: Colors.blue,
      )),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          launchUrl(Uri.parse(content));
        },
    );
  }

  Tutorial({Key? key}) : super(key: key);

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
    final InlineSpan SETTINGS_SPAN = WidgetSpan(
        child: GestureDetector(
            onTap: () {
              print("PUSHED");
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()));
            },
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: 'Settings',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                WidgetSpan(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                )
              ]),
            )));

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
                "Picovoice???s unique approach to speech recognition differentiates itself from other vendors. It doesn???t require data gathering to train models."),
      ),
      DEFAULT_SPAN("\n\nTherefore, both "),
      PICOVOICE,
      DEFAULT_SPAN(" and this app "),
      BOLD_SPAN("DO NOT"),
      DEFAULT_SPAN(" collect user audio/speech/voice data. \n\n"
          "To get started, sign up for a Picovoice account at "),
      URL_SPAN("https://console.picovoice.ai"),
      DEFAULT_SPAN(
          "\n\nAfter creating your free account, paste your unique access key into "),
      SETTINGS_SPAN
    ]));

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 20),
            child: Text(
              'Getting Started',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: FAQ,
          ),
        ],
      ),
    );
  }
}
