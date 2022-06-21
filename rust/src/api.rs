// As a reminder, you need to run these commands every time your Rust code changes and before you run flutter run:
// flutter_rust_bridge_codegen \
//     -r rust/src/api.rs \
//     -d lib/bridge_generated.dart \
//     -c ios/Runner/bridge_generated.h \

// # if using Dart codegen
// flutter pub run build_runner build

pub fn tokenize() -> String {
    return "Hello World".to_string();
}
