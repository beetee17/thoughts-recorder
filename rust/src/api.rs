// As a reminder, you need to run these commands every time your Rust code changes and before you run flutter run:
// flutter_rust_bridge_codegen \
//     -r rust/src/api.rs \
//     -d lib/bridge_generated.dart \
//     -c ios/Runner/bridge_generated.h \

// # if using Dart codegen
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
    println!("Tokens: {:?}", tokens);

    return tokens

}
