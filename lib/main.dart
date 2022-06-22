import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/screens/files_screen.dart';
import 'package:Minutes/utils/colors.dart';
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
    // .then((value) => print(value));
    return StoreProvider(
      store: store,
      child: MaterialApp(
        home: FilesScreen(),
        // debugShowCheckedModeBanner: false,
        theme: ThemeData(
            brightness: Brightness.dark,
            sliderTheme: SliderThemeData(
              trackHeight: 5,
              thumbColor: Colors.blue.shade800,
              activeTrackColor: Colors.blue.shade800,
              thumbShape: RoundSliderThumbShape(elevation: 3),
              valueIndicatorColor: Colors.black87,
              overlayColor: Colors.grey.withOpacity(0.2),
            ),
            scaffoldBackgroundColor: bgColor,
            appBarTheme: AppBarTheme(
                backgroundColor: bgColor,
                foregroundColor: textColor //here you can give the text color
                ),
            textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: textColor,
                  displayColor: textColor,
                )),
      ),
    );
  }
}
