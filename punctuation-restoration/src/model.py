import torch.nn as nn
import torch
from config import *
import re

pretrained_model = 'albert-base-v2'
tokenizer = MODELS[pretrained_model][1].from_pretrained(pretrained_model)
token_style = MODELS['albert-base-v2'][3]
sequence_len = 256
device = torch.device('cpu') # Need to be false when converting to coreml

# Here we are relying on the assumption that 2560 characters is always sufficient to represent 256 tokens
max_output_string_length = sequence_len  +  2560 # max_input_string_length 

"""

Instead of outputting y_mask for us to decode Flutter side, we should try to output
the punctuated text directly, in tokenized form.

We can adapt from inference.py to format the output, then encode into an integer tensor via ascii values
We should try using the tokenize method on the punctuated string first which should take care of varying whitespace issues
It should combine all the whitespaces into a special ▁ delimiter which we can split on on Flutter side

On Flutter side we only need to worry about matching the punctuating text with the input text
- Use split('▁') to easily get the punctuated words
- Remove all whitespace, punctuation, basically anything but alphanumeric chars from both words
for semantic comparison ONLY
- If the words pass the semantic comparison, we compare the pseudo-raw versions of the 
input (remove whitespaces ONLY) and punctuated versions (should have no whitespace already)
- If they are different we say that the model has suggested a different punctuation 
- Remember to add back the removed whitespaces!
"""
class Punctuator(nn.Module):
    def __init__(self, freeze_bert=False, lstm_dim=-1):
        super(Punctuator, self).__init__()
        self.output_dim = len(punctuation_dict)
        self.tokenizer = tokenizer
        self.bert_layer = MODELS[pretrained_model][0].from_pretrained(pretrained_model)
        # Freeze bert layers
        if freeze_bert:
            for p in self.bert_layer.parameters():
                p.requires_grad = False
        bert_dim = MODELS[pretrained_model][2]
        if lstm_dim == -1:
            hidden_size = bert_dim
        else:
            hidden_size = lstm_dim
        self.lstm = nn.LSTM(input_size=bert_dim, hidden_size=hidden_size, num_layers=1, bidirectional=True)
        self.linear = nn.Linear(in_features=hidden_size*2, out_features=len(punctuation_dict))

    def forward(self, ascii=None, x=None, attn_mask=None):
        y_mask = torch.zeros([1, 256], dtype=torch.int32) # dummy y_mask
        word_pos = -1 # dummy word_pos
        punctuated_text = torch.tensor([ord('a') for i in range(max_output_string_length)]) # dummy output

        if ascii is not None:
            x, attn_mask, y_mask, word_pos = self.tokenize(ascii)

        if len(x.shape) == 1:
            x = x.view(1, x.shape[0])  # add dummy batch for single sample
        # (B, N, E) -> (B, N, E)
        y_predict = self.bert_layer(x, attention_mask=attn_mask)[0]
        # (B, N, E) -> (N, B, E)
        y_predict = torch.transpose(y_predict, 0, 1)
        y_predict, (_, _) = self.lstm(y_predict)
        # (N, B, E) -> (B, N, E)
        y_predict = torch.transpose(y_predict, 0, 1)
        y_predict = self.linear(y_predict)

        if ascii is not None:
            punctuated_text = self.getPunctuatedWords(x, y_predict, y_mask)
        
        return y_predict, y_mask, word_pos, punctuated_text
    
    def getPunctuatedWords(self, tokens, y_predict, y_mask):
        punctuatedWords = ""
        punctuation_map =  {0:'OO', 1:',O', 2:'.O', 3:'?O', 4:'OU', 5:',U', 6:'.U', 7:'?U'}
        print(y_predict, y_predict.shape)
        with torch.no_grad():
            tokens = tokens.view(-1)
            # Get the inner array -> now shape is (256, 4)
            y_predict = y_predict.view(-1, y_predict.shape[2])
            # For each row of 4 items, get the one with the highest value 
            # This is the suggested punctuation -> 0 is no punctuation
            y_predict = torch.argmax(y_predict, dim=1).view(-1)
            print(tokens)
        for i in range(y_mask.shape[0]):
            word_piece = self.tokenizer._convert_id_to_token(tokens[i].item())
            if y_mask[i] == 1:
                prediction = punctuation_map[y_predict[i].item()]
                print(prediction)
                if prediction[0] != "O":
                    word_piece += prediction[0] 
                if prediction[1] == "O":
                    word_piece = word_piece.lower()
                if prediction[1] == "U":
                    word_piece = word_piece.title()
            punctuatedWords += word_piece
        print(punctuatedWords)
        punctuatedWords = [ord(c) for c in punctuatedWords]
        while len(punctuatedWords) < max_output_string_length:
            punctuatedWords.append(-1)
        return punctuatedWords

    def tokenize(self, ascii):
        text = ''.join([chr(c) for c in ascii])
        text = re.sub(r"[,:\-–.!;?]", '', text)
        words = text.lower().split()

        word_pos = 0

        # while word_pos < len(words):
        tokens = [TOKEN_IDX[token_style]['START_SEQ']]
        y_mask = [0]

        while len(tokens) < sequence_len and word_pos < len(words):
            word_pieces = self.tokenizer.tokenize(words[word_pos])
            print(word_pieces)
            if len(word_pieces) + len(tokens) >= sequence_len:
                break
            else:
                for i in range(len(word_pieces) - 1):
                    tokens.append(self.tokenizer.convert_tokens_to_ids(word_pieces[i]))
                    y_mask.append(0)
                tokens.append(self.tokenizer.convert_tokens_to_ids(word_pieces[-1]))
                y_mask.append(1)
                word_pos += 1
        tokens.append(TOKEN_IDX[token_style]['END_SEQ'])
        y_mask.append(0)
        if len(tokens) < sequence_len:
            tokens = tokens + [TOKEN_IDX[token_style]['PAD'] for _ in range(sequence_len - len(tokens))]
            y_mask = y_mask + [0 for _ in range(sequence_len - len(y_mask))]
        attn_mask = [1 if token != TOKEN_IDX[token_style]['PAD'] else 0 for token in tokens]

        tokens = torch.tensor(tokens).reshape(1,-1)
        y_mask = torch.tensor(y_mask)
        attn_mask = torch.tensor(attn_mask).reshape(1,-1)
        tokens, attn_mask, y_mask = tokens.to(device), attn_mask.to(device), y_mask.to(device)
        
        return tokens, attn_mask, y_mask, torch.tensor([word_pos - 1], dtype=torch.int32)
