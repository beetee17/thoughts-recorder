import 'package:Minutes/screens/home_screen.dart';
import 'package:flutter/material.dart';
//Import the font package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
      // debugShowCheckedModeBanner: false,
      theme: ThemeData(
          sliderTheme: SliderThemeData(
            trackHeight: 5,
            thumbColor: Colors.blue.shade800,
            activeTrackColor: Colors.blue.shade800,
            thumbShape: RoundSliderThumbShape(elevation: 3),
            valueIndicatorColor: Colors.black87,
            overlayColor: Colors.grey.withOpacity(0.2),
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black //here you can give the text color
              ),
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: Colors.black,
                displayColor: Colors.black,
              )),
    );
  }
}
