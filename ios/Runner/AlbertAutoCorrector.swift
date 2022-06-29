//
//  AlbertAutoCorrector.swift
//  Runner
//
//  Created by Brandon Thio on 29/6/22.
//


import Foundation
import CoreML
import Accelerate

class AlbertAutoCorrector {
    
    let model: AutoCorrectModel
    
    init(model: AutoCorrectModel) {
        self.model = model
    }
    
    private let tokenizer = BertTokenizer()
    public let seqLen = 128
    
    
    
    /// This function takes in a String of text , tokenizes it, and sends the tokens to our PunctuatorModel for inference. The model returns 4 float values for each token, corresponding to the 4 punctuation options in `punctuationMapper`. The function outputs this multi-dimensional array, after applying the softmax function to each slice of 4 values to get the model's  confidence score.
    /// - Parameter text: The text to be punctuated
    /// - Returns: Confidence scores for the 4 punctuation options for each of the tokens in `text`
    func autoCorrect(tokens: [Int], targets: [Int]) ->  [Float] {
        // Convert to lowercase and remove all punctuation
        // All whitepsaces and newlines are combined
        // Trim the ends
        
        let input = getInputs(tokens: tokens)
        let maskIndex = findMaskIndex(tokens: tokens)
        print("MASK AT INDEX \(maskIndex)")
        
        let (output, time) = Utils.time {
            return try! model.prediction(input: input).scoresShapedArray
        }
        
        let outputAtMaskIndex = output[0, maskIndex+1]
        print("Took <\(time)s>")
        print("Mask Index Result: \(outputAtMaskIndex.shape) ")
        for i in 0...20 {
            print(outputAtMaskIndex[i].scalar!)
        }
        
        var result: [Float] = []
        
        for i in outputAtMaskIndex.indices {
            if targets.contains(i) {
                let targetScore = outputAtMaskIndex[i].scalar ?? -1
                result.append(targetScore)
                print("\(i) GOT SCORE FOR TARGET \(tokenizer.unTokenize(token: i)): \(targetScore)")
            }
        }
        result = softmax(result)
        print("SOFTMAXING RESULT: \(result)")
        return result
    }
    
    private func findMaskIndex(tokens: [Int]) -> Int {
        return tokens.firstIndex(of: tokenizer.tokenToId(token: "[MASK]")) ?? -1
    }

    
    private func getInputs(tokens: [Int]) -> AutoCorrectModelInput {
        
        let nPadding = seqLen - tokens.count - 2
        /// Sequence of input symbols. The sequence starts with a start token (101) followed by question tokens that are followed be a separator token (102) and the document tokens.The document tokens end with a separator token (102) and the sequenceis padded with 0 values to length 384.
        var currTokensWithPad: [Int] = []
        
        currTokensWithPad.append(
            tokenizer.tokenToId(token: "[CLS]")
        )
        currTokensWithPad.append(contentsOf: tokens)
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
        
        return AutoCorrectModelInput(tokens: MLMultiArray.from(currTokensWithPad, dims: 2), attention_mask: attention_mask)
        
    }
    
}

