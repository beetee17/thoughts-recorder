import torch.nn as nn
import torch
from config import *
import os
import numpy as np
import torch.multiprocessing
import re
from tqdm import tqdm
from dataset import Dataset
import augmentation
from model import Punctuator

if __name__ == "__main__":
    
    pretrained_model = 'albert-base-v2'
    save_path = 'out'
    model_save_path = os.path.join(save_path, 'weights.pt')
    device = torch.device('cpu') # Need to be false when converting to coreml
    tokenizer = MODELS[pretrained_model][1].from_pretrained(pretrained_model)
    augmentation.tokenizer = tokenizer
    augmentation.sub_style = 'unk'
    augmentation.alpha_sub = 0.4
    augmentation.alpha_del = 0.4
    epochs = 5
    token_style = MODELS['albert-base-v2'][3]
    ar = 0.15
    lr=5e-06
    decay=0
    sequence_len = 256
    aug_type = 'all'
    torch.multiprocessing.set_sharing_strategy('file_system')   # https://github.com/pytorch/pytorch/issues/11201

    # for reproducibility
    torch.manual_seed(1)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False
    np.random.seed(1)

    data_path = 'data'
    token_style = MODELS[pretrained_model][3]

    # Datasets
    train_set = Dataset(os.path.join(data_path, 'en/ted_talks_train.txt'), tokenizer=tokenizer, sequence_len=sequence_len,
                        token_style=token_style, is_train=True, augment_rate=ar, augment_type=aug_type)
    val_set = Dataset(os.path.join(data_path, 'en/ted_talks_val.txt'), tokenizer=tokenizer, sequence_len=sequence_len,
                        token_style=token_style, is_train=False)
    test_set_also = Dataset(os.path.join(data_path, 'en/ted_talks_test.txt'), tokenizer=tokenizer, sequence_len=sequence_len,
                        token_style=token_style, is_train=False)
    test_set = [val_set, test_set_also]

    # Data Loaders
    data_loader_params = {
        'batch_size': 8,
        'shuffle': True,
        'num_workers': 1
    }

    train_loader = torch.utils.data.DataLoader(train_set, **data_loader_params)
    val_loader = torch.utils.data.DataLoader(val_set, **data_loader_params)
    test_loaders = [torch.utils.data.DataLoader(x, **data_loader_params) for x in test_set]


    # logs
    os.makedirs(save_path, exist_ok=True)
    log_path = os.path.join(save_path, 'model' + '_logs.txt')


    # Model
    model = Punctuator()
    model.to(device)

    # UNCOMMENT to resume training on existing weights. Make sure this file exists!
    # deep_punctuation.load_state_dict(torch.load(model_save_path))
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=lr, weight_decay=decay)


    def validate(data_loader):
        """
        :return: validation accuracy, validation loss
        """
        num_iteration = 0
        model.eval()
        correct = 0
        total = 0
        val_loss = 0
        with torch.no_grad():
            for x, y, att, y_mask in tqdm(data_loader, desc='eval'):
                x, y, att, y_mask = x.to(device), y.to(device), att.to(device), y_mask.to(device)
                y_mask = y_mask.view(-1)

                y_predict = model(x=x, attn_mask=att)[0]
                y = y.view(-1)
                y_predict = y_predict.view(-1, y_predict.shape[2])
                loss = criterion(y_predict, y)
                y_predict = torch.argmax(y_predict, dim=1).view(-1)

                val_loss += loss.item()
                num_iteration += 1
                y_mask = y_mask.view(-1)
                correct += torch.sum(y_mask * (y_predict == y).long()).item()
                total += torch.sum(y_mask).item()
        return correct/total, val_loss/num_iteration


    def test(data_loader):
        """
        :return: precision[numpy array], recall[numpy array], f1 score [numpy array], accuracy, confusion matrix
        """
        num_iteration = 0
        model.eval()
        # +1 for overall result
        tp = np.zeros(1+len(punctuation_dict), dtype=np.int)
        fp = np.zeros(1+len(punctuation_dict), dtype=np.int)
        fn = np.zeros(1+len(punctuation_dict), dtype=np.int)
        cm = np.zeros((len(punctuation_dict), len(punctuation_dict)), dtype=np.int)
        correct = 0
        total = 0
        with torch.no_grad():
            for x, y, att, y_mask in tqdm(data_loader, desc='test'):
                x, y, att, y_mask = x.to(device), y.to(device), att.to(device), y_mask.to(device)
                y_mask = y_mask.view(-1)

                y_predict = model(x=x, attn_mask=att)[0]
                y = y.view(-1)
                y_predict = y_predict.view(-1, y_predict.shape[2])
                y_predict = torch.argmax(y_predict, dim=1).view(-1)

                num_iteration += 1
                y_mask = y_mask.view(-1)
                correct += torch.sum(y_mask * (y_predict == y).long()).item()
                total += torch.sum(y_mask).item()
                for i in range(y.shape[0]):
                    if y_mask[i] == 0:
                        # we can ignore this because we know there won't be any punctuation in this position
                        # since we created this position due to padding or sub-word tokenization
                        continue
                    cor = y[i]
                    prd = y_predict[i]
                    if cor == prd:
                        tp[cor] += 1
                    else:
                        fn[cor] += 1
                        fp[prd] += 1
                    cm[cor][prd] += 1
        # ignore first index which is for no punctuation
        tp[-1] = np.sum(tp[1:])
        fp[-1] = np.sum(fp[1:])
        fn[-1] = np.sum(fn[1:])
        precision = tp/(tp+fp)
        recall = tp/(tp+fn)
        f1 = 2 * precision * recall / (precision + recall)

        return precision, recall, f1, correct/total, cm


    def train():
        with open(log_path, 'a') as f:
            f.write(str('START')+'\n')
        best_val_acc = 0
        for epoch in range(epochs):
            train_loss = 0.0
            train_iteration = 0
            correct = 0
            total = 0
            model.train()
            for x, y, att, y_mask in tqdm(train_loader, desc='train'):
                # All are torch.Size([8, 256])
                x, y, att, y_mask = x.to(device), y.to(device), att.to(device), y_mask.to(device)
                y_mask = y_mask.view(-1)
       
                y_predict = model(x=x, attn_mask=att)[0]
                y_predict = y_predict.view(-1, y_predict.shape[2])
                y = y.view(-1)
                loss = criterion(y_predict, y)
                y_predict = torch.argmax(y_predict, dim=1).view(-1)

                correct += torch.sum(y_mask * (y_predict == y).long()).item()

                optimizer.zero_grad()
                train_loss += loss.item()
                train_iteration += 1
                loss.backward()

                optimizer.step()

                y_mask = y_mask.view(-1)

                total += torch.sum(y_mask).item()

            train_loss /= train_iteration
            log = 'epoch: {}, Train loss: {}, Train accuracy: {}'.format(epoch, train_loss, correct / total)
            with open(log_path, 'a') as f:
                f.write(log + '\n')
            print(log)

            val_acc, val_loss = validate(val_loader)
            log = 'epoch: {}, Val loss: {}, Val accuracy: {}'.format(epoch, val_loss, val_acc)
            with open(log_path, 'a') as f:
                f.write(log + '\n')
            print(log)
            if val_acc > best_val_acc:
                best_val_acc = val_acc
                torch.save(model.state_dict(), model_save_path)

        print('Best validation Acc:', best_val_acc)
        model.load_state_dict(torch.load(model_save_path))
        for loader in test_loaders:
            precision, recall, f1, accuracy, cm = test(loader)
            log = 'Precision: ' + str(precision) + '\n' + 'Recall: ' + str(recall) + '\n' + 'F1 score: ' + str(f1) + \
                '\n' + 'Accuracy:' + str(accuracy) + '\n' + 'Confusion Matrix' + str(cm) + '\n'
            print(log)
            with open(log_path, 'a') as f:
                f.write(log)
            log_text = ''
            for i in range(1, 5):
                log_text += str(precision[i] * 100) + ' ' + str(recall[i] * 100) + ' ' + str(f1[i] * 100) + ' '
            with open(log_path, 'a') as f:
                f.write(log_text[:-1] + '\n\n')

    train()