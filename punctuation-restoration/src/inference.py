import torch
from config import *
import os
import torch.multiprocessing
import re
from model import Punctuator

save_path = 'out'
model_save_path = os.path.join(save_path, 'weights.pt')

if __name__ == "__main__":

    def inference(text):
        ascii = torch.tensor([ord(c) for c in text])
        torch_model = Punctuator()
        torch_model.load_state_dict(torch.load(model_save_path))
        # Set the model in evaluation mode.
        torch_model.eval()

        text = re.sub(r"[,:\-–.!;?]", '', text)
        words_original_case = text.split()


        with torch.no_grad():
            y_predict, y_mask, word_pos, punctuated_text = torch_model(ascii=ascii)

        print('scores', y_predict)
        print('mask:', y_mask)
        print('stop at', word_pos, words_original_case[min(word_pos, len(words_original_case) -1)])
        print('Punctuated text')
        print(''.join([chr(c.item()) for c in punctuated_text if c != -1]).replace('▁', ' '))

    inference("Superficially, the meritocratic rhetoric is empowering as it inspires one to strive to be their best self, and instills a sense of personal responsibility and freedom. However, the converse scenario is not as inspiring and is often ignored. The losers feel that their failures are no one's fault but their own, and the winners look down at those less well off, leading to feelings of humiliation and resentment. In a meritocratic society, income may be associated with success, which in turn implies hard work and talent of the successful individual. Low income workers like janitors or nurses who contribute in vital ways to the society may feel they do not get the recognition and acknowledgement for their efforts, stripping them of their esteem and dignity.  Such a mentality makes it difficult for those who are successful to empathise with the rest of society, and creates a division that threatens democracy. ")