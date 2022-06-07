import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/screens/files_screen.dart';
import 'package:Minutes/screens/transcript_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
//Import the font package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: MaterialApp(
        home: FilesScreen(),
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
      ),
    );
  }
}
