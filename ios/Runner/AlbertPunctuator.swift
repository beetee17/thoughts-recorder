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
    func punctuate(text: String) -> (scores: [[Float]], words:[String], mask: [Bool]) {
        // Convert to lowercase and remove all punctuation
        // All whitepsaces and newlines are combined
        // Trim the ends
        var charactersToRemove = CharacterSet.punctuationCharacters
        charactersToRemove.remove(charactersIn: "'") // Only remove apostrophes, if single-quote
        var formattedText = text.replacingOccurrences(of: "’", with: "'") .replacingOccurrences(of: " '", with: "").replacingOccurrences(of: "' ", with: "")
        
        
         formattedText = formattedText.lowercased().components(separatedBy: charactersToRemove).joined().split(usingRegex: "\\s+").joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("Punctuating this piece of text: \n\(formattedText)")
        let inputs = tokenize(text: formattedText)
        
        
        let words: [String] = formattedText.components(separatedBy: .whitespacesAndNewlines)
        
        var wordPos = 0
      
        var allScores: [[Float]] = []
        
        
        // This will be same length as allScores
        var mask: [Bool] = []
        
        for input in inputs {
            let (output, time) = Utils.time {
                return try! model.prediction(input: input).token_scoresShapedArray
            }
            
            let tokens = input.tokens
            for i in 0..<tokens.count {
                let token = tokens[i]
                if ["[UNK]", "[SEP]", "[PAD]", "[CLS]", "[MASK]"].contains(tokenizer.unTokenize(token: token.intValue)) {
                    // Skip this in terms of wordPos
                    mask.append(false)
               
                } else if wordPos < words.count{
                    let wordTokens: [String] = tokenizer.tokenize(text: words[wordPos])
                    for _ in 0..<max(0, wordTokens.count-1) {
                        mask.append(false)
                    }
                    mask.append(true)
                  
                    wordPos += 1
                }
            }
        
          
            print("Took <\(time)s>")
            
            var softMaxScores: [[Float]] = []
            
            
            for i in 0..<output.shape[1] {
                let tokenPunctuationScores = output[0, i].scalars // Should have 4 items, one for each punctuation option
                softMaxScores.append(softmax(tokenPunctuationScores))
            }
            
            allScores.append(contentsOf: softMaxScores)

        }
        
        return (allScores, words, mask)
    }
    
  
    
    func getPunctuatedText(from allScores: [[Float]], for words: [String], mask: [Bool]) -> String {
        var punctuatedText: String = ""
        var wordPos = 0
        
        for (index, punctuationScores) in allScores.enumerated() {
            if mask[index] {
                let word = words[wordPos]
                let punctuationResult = argmax(punctuationScores)
                punctuatedText += word + AlbertPunctuator.punctuationMapper[punctuationResult.0]! + " "
                wordPos += 1
            }
        }
        
        return punctuatedText
    }
    
    
    private func tokenize(text: String) -> [PunctuatorModelInput] {
        var remainingTokens = tokenizer.tokenizeToIds(text: text)
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

