import torch.nn as nn
import torch
from transformers import AlbertForMaskedLM, AlbertTokenizer
from torchcrf import CRF


class AutoCorrect(nn.Module):
    def __init__(self):
        super(AutoCorrect, self).__init__()
        self.model = AlbertForMaskedLM.from_pretrained("albert-base-v2", return_dict=False)
        self.tokenizer = AlbertTokenizer.from_pretrained("albert-base-v2")

    def forward(self, tokens, attn_masks=None):
        logits = self.model(tokens, attention_mask=attn_masks).logits
        print("LOGITS: {} \n{}".format(logits.shape, logits))
        
        probs = logits.softmax(dim=-1)

        return probs
        