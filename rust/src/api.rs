// cd rust
// cargo clean
// cargo build
// cd ..
// cargo install flutter_rust_bridge_codegen just
// dart pub global activate ffigen 5.0.1

/*
// Using ffigen 6.0 results in 
 void store_dart_post_cobject(
           ^
    Failed to package /Users/brandonthio/thoughts-recorder.
    Command PhaseScriptExecution failed with a nonzero exit code
*/

// As a reminder, you need to run the commands below every time your Rust code changes and before you run flutter run:

// flutter_rust_bridge_codegen \
//     -r rust/src/api.rs \
//     -d lib/bridge_generated.dart \
//     -c ios/Runner/bridge_generated.h
// flutter pub run build_runner build

use rust_tokenizers::tokenizer::{AlbertTokenizer, Tokenizer, TruncationStrategy};
use rust_tokenizers::vocab::{AlbertVocab, SentencePieceModel, Vocab};


pub fn tokenize(text: String, model_path: String) -> Vec<i64> {

    let strip_accents = false;
    let lower_case = false;
    let model = SentencePieceModel::from_file(&model_path).unwrap();
    println!("Got model!");

    let vocab = AlbertVocab::from_file(&model_path).unwrap();
    println!("Got vocab!");

    let tokenizer =
        AlbertTokenizer::from_existing_vocab_and_model(vocab, model, lower_case, strip_accents);

    let word_pieces = tokenizer.tokenize(text);
   
    let tokens: Vec<i64> =  tokenizer.convert_tokens_to_ids(&word_pieces);

    println!("Word Pieces: {:?}", word_pieces);
    println!("Rust returning tokens...");

    return tokens

}

pub fn tokenize_word(word: String, model_path: String) -> Vec<i64> {

    let strip_accents = false;
    let lower_case = false;
    let model = SentencePieceModel::from_file(&model_path).unwrap();
    println!("Got model!");

    let vocab = AlbertVocab::from_file(&model_path).unwrap();
    println!("Got vocab!");

    let tokenizer =
        AlbertTokenizer::from_existing_vocab_and_model(vocab, model, lower_case, strip_accents);
   
    let tokens: Vec<i64> =  tokenizer.convert_tokens_to_ids([word]);

    println!("Rust returning tokens...");

    return tokens

}