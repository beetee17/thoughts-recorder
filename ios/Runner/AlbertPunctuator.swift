//
//  BertForQuestionAnswering.swift
//  CoreMLBert
//
//  Created by Julien Chaumond on 27/06/2019.
//  Copyright © 2019 Hugging Face. All rights reserved.
//

import Foundation
import CoreML
import Accelerate

class AlbertPunctuator {
    
    static var punctuationMapper: [Int : String] = [0 : "", 1 : ",", 2 : ".", 3 : "?"]
    

    let model: PunctuatorModel
    
    init(model: PunctuatorModel) {
        self.model = model
    }
    
    private let tokenizer = BertTokenizer()
    public let seqLen = 256
    
    
    
    /// This function takes in a String of text , tokenizes it, and sends the tokens to our PunctuatorModel for inference. The model returns 4 float values for each token, corresponding to the 4 punctuation options in `punctuationMapper`. The function outputs this multi-dimensional array, after applying the softmax function to each slice of 4 values to get the model's  confidence score.
    /// - Parameter text: The text to be punctuated
    /// - Returns: Confidence scores for the 4 punctuation options for each of the tokens in `text`
    func punctuate(tokens: [Int]) -> (scores: [[Float]], words:[String], mask: [Bool]) {
        // Convert to lowercase and remove all punctuation
        // All whitepsaces and newlines are combined
        // Trim the ends

        let decodedText = tokenizer.unTokenize(tokens: tokens).joined(separator: "")
        print("Decoded this piece of text: \n\(decodedText)")
        
        let inputs = getInputs(tokens: tokens)
        
        let words: [String] = decodedText.replacingOccurrences(of: "▁", with: " ").trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespacesAndNewlines)
    
      
        var allScores: [[Float]] = []
        
        
        // This will be same length as allScores
        var mask: [Bool] = []
        
        for input in inputs {
            let (output, time) = Utils.time {
                return try! model.prediction(input: input).token_scoresShapedArray
            }
            print("Took <\(time)s>")
            
            let tokens = input.tokens
            for i in 0..<tokens.count {
                let wordPiece = tokenizer.unTokenize(token:tokens[i].intValue)
                if ["[UNK]", "[SEP]", "[PAD]", "[CLS]", "[MASK]"].contains(wordPiece)  {
                    mask.append(false)
                } else if i < tokens.count - 1 {
                    // There is a piece after this. If it starts with ▁ then this current piece must be the last of its word
                    let nextWordPiece = tokenizer.unTokenize(token:tokens[i+1].intValue)
                    
                    // If it is the last piece then the next one is a stop token
                    mask.append(nextWordPiece.starts(with: "▁") || nextWordPiece == "[SEP]")
                
                } else {
                    // This is the last piece. The last token is always a [CLS]
                    mask.append(false)
                }
            }
            
            var softMaxScores: [[Float]] = []
            
            
            for i in 0..<output.shape[1] {
                let tokenPunctuationScores = output[0, i].scalars // Should have 4 items, one for each punctuation option
                softMaxScores.append(softmax(tokenPunctuationScores))
            }
            
            allScores.append(contentsOf: softMaxScores)

        }
        
        return (allScores, words, mask)
    }
    

    
    private func getInputs(tokens: [Int]) -> [PunctuatorModelInput] {
        var remainingTokens = tokens
        var inputs: [PunctuatorModelInput] = []
        
        while !remainingTokens.isEmpty {
            
            let currTokens = Array(remainingTokens.prefix(seqLen - 2))
            remainingTokens = Array(remainingTokens.dropFirst(seqLen - 2))
            
            
            let nPadding = seqLen - currTokens.count - 2
            /// Sequence of input symbols. The sequence starts with a start token (101) followed by question tokens that are followed be a separator token (102) and the document tokens.The document tokens end with a separator token (102) and the sequenceis padded with 0 values to length 384.
            var currTokensWithPad: [Int] = []
            
            currTokensWithPad.append(
                tokenizer.tokenToId(token: "[CLS]")
            )
            currTokensWithPad.append(contentsOf: currTokens)
            currTokensWithPad.append(
                tokenizer.tokenToId(token: "[SEP]")
            )
            
            currTokensWithPad.append(contentsOf: Array(repeating: 0, count: nPadding))
        
            /// A masking matrix (logits). It has zero values in the first X number of columns, where X = number of input tokens without the padding,and value -1e+4 in the remaining 384-X (padding) columns.
            let attention_mask = try! MLMultiArray(shape: [1, NSNumber(value: seqLen)], dataType: .double)
            for i in 0..<seqLen {
                // 1 if not padding else 0
                attention_mask[i] = (i < seqLen - nPadding) ? 1 : 0
            }
            print(currTokensWithPad)
            inputs.append(PunctuatorModelInput(tokens: MLMultiArray.from(currTokensWithPad, dims: 2), attention_mask: attention_mask))
        
        }
        return inputs
    }
    

}

