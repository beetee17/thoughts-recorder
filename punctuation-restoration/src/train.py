import os
import torch
import torchvision
import torch.nn as nn
import numpy as np
from torch.utils import data
import torch.multiprocessing
import coremltools as ct
from coremltools.converters.mil.mil import types

from tqdm import tqdm

from argparser import parse_arguments
from dataset import Dataset
from model import DeepPunctuation, DeepPunctuationCRF
from config import *
import augmentation

torch.multiprocessing.set_sharing_strategy('file_system')   # https://github.com/pytorch/pytorch/issues/11201

args = parse_arguments()

# for reproducibility
torch.manual_seed(args.seed)
torch.backends.cudnn.deterministic = True
torch.backends.cudnn.benchmark = False
np.random.seed(args.seed)

# tokenizer
tokenizer = MODELS[args.pretrained_model][1].from_pretrained(args.pretrained_model)
augmentation.tokenizer = tokenizer
augmentation.sub_style = args.sub_style
augmentation.alpha_sub = args.alpha_sub
augmentation.alpha_del = args.alpha_del
token_style = MODELS[args.pretrained_model][3]
ar = args.augment_rate
sequence_len = args.sequence_length
aug_type = 'all' # Suddenly gave KeyError: all/x0

# Datasets
if args.language == 'english':
    train_set = Dataset(os.path.join(args.data_path, 'en/train2012'), tokenizer=tokenizer, sequence_len=sequence_len,
                        token_style=token_style, is_train=True, augment_rate=ar, augment_type=aug_type)
    val_set = Dataset(os.path.join(args.data_path, 'en/dev2012'), tokenizer=tokenizer, sequence_len=sequence_len,
                      token_style=token_style, is_train=False)
    test_set_ref = Dataset(os.path.join(args.data_path, 'en/test2011'), tokenizer=tokenizer, sequence_len=sequence_len,
                           token_style=token_style, is_train=False)
    test_set_asr = Dataset(os.path.join(args.data_path, 'en/test2011asr'), tokenizer=tokenizer, sequence_len=sequence_len,
                           token_style=token_style, is_train=False)
    test_set = [val_set, test_set_ref, test_set_asr]
elif args.language == 'bangla':
    train_set = Dataset(os.path.join(args.data_path, 'bn/train'), tokenizer=tokenizer, sequence_len=sequence_len,
                        token_style=token_style, is_train=True, augment_rate=ar, augment_type=aug_type)
    val_set = Dataset(os.path.join(args.data_path, 'bn/dev'), tokenizer=tokenizer, sequence_len=sequence_len,
                      token_style=token_style, is_train=False)
    test_set_news = Dataset(os.path.join(args.data_path, 'bn/test_news'), tokenizer=tokenizer, sequence_len=sequence_len,
                            token_style=token_style, is_train=False)
    test_set_ref = Dataset(os.path.join(args.data_path, 'bn/test_ref'), tokenizer=tokenizer, sequence_len=sequence_len,
                           token_style=token_style, is_train=False)
    test_set_asr = Dataset(os.path.join(args.data_path, 'bn/test_asr'), tokenizer=tokenizer, sequence_len=sequence_len,
                           token_style=token_style, is_train=False)
    test_set = [val_set, test_set_news, test_set_ref, test_set_asr]
elif args.language == 'english-bangla':
    train_set = Dataset([os.path.join(args.data_path, 'en/train2012'), os.path.join(args.data_path, 'bn/train_bn')],
                        tokenizer=tokenizer, sequence_len=sequence_len, token_style=token_style, is_train=True,
                        augment_rate=ar, augment_type=aug_type)
    val_set = Dataset([os.path.join(args.data_path, 'en/dev2012'), os.path.join(args.data_path, 'bn/dev_bn')],
                      tokenizer=tokenizer, sequence_len=sequence_len, token_style=token_style, is_train=False)
    test_set_ref = Dataset(os.path.join(args.data_path, 'en/test2011'), tokenizer=tokenizer, sequence_len=sequence_len,
                           token_style=token_style, is_train=False)
    test_set_asr = Dataset(os.path.join(args.data_path, 'en/test2011asr'), tokenizer=tokenizer, sequence_len=sequence_len,
                           token_style=token_style, is_train=False)
    test_set_news = Dataset(os.path.join(args.data_path, 'bn/test_news'), tokenizer=tokenizer, sequence_len=sequence_len,
                            token_style=token_style, is_train=False)
    test_bn_ref = Dataset(os.path.join(args.data_path, 'bn/test_ref'), tokenizer=tokenizer, sequence_len=sequence_len,
                          token_style=token_style, is_train=False)
    test_bn_asr = Dataset(os.path.join(args.data_path, 'bn/test_asr'), tokenizer=tokenizer, sequence_len=sequence_len,
                          token_style=token_style, is_train=False)
    test_set = [val_set, test_set_ref, test_set_asr, test_set_news, test_bn_ref, test_bn_asr]
else:
    raise ValueError('Incorrect language argument for Dataset')

# Data Loaders
data_loader_params = {
    'batch_size': args.batch_size,
    'shuffle': True,
    'num_workers': 1
}
train_loader = torch.utils.data.DataLoader(train_set, **data_loader_params)
val_loader = torch.utils.data.DataLoader(val_set, **data_loader_params)
test_loaders = [torch.utils.data.DataLoader(x, **data_loader_params) for x in test_set]


# logs
os.makedirs(args.save_path, exist_ok=True)
model_save_path = os.path.join(args.save_path, 'weights.pt')
log_path = os.path.join(args.save_path, args.name + '_logs.txt')


# Model
device = torch.device('mps' if (args.cuda and torch.backends.mps.is_available()) else 'cpu') # Need to be false when converting to coreml
if args.use_crf:
    deep_punctuation = DeepPunctuationCRF(args.pretrained_model, freeze_bert=args.freeze_bert, lstm_dim=args.lstm_dim)
else:
    deep_punctuation = DeepPunctuation(args.pretrained_model, freeze_bert=args.freeze_bert, lstm_dim=args.lstm_dim)
deep_punctuation.to(device)
# deep_punctuation.load_state_dict(torch.load(model_save_path))
criterion = nn.CrossEntropyLoss()
optimizer = torch.optim.Adam(deep_punctuation.parameters(), lr=args.lr, weight_decay=args.decay)


def validate(data_loader):
    """
    :return: validation accuracy, validation loss
    """
    num_iteration = 0
    deep_punctuation.eval()
    correct = 0
    total = 0
    val_loss = 0
    with torch.no_grad():
        for x, y, att, y_mask in tqdm(data_loader, desc='eval'):
            x, y, att, y_mask = x.to(device), y.to(device), att.to(device), y_mask.to(device)
            y_mask = y_mask.view(-1)
            if args.use_crf:
                y_predict = deep_punctuation(x, att, y)
                loss = deep_punctuation.log_likelihood(x, att, y)
                y_predict = y_predict.view(-1)
                y = y.view(-1)
            else:
                y_predict = deep_punctuation(x, att)
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
    deep_punctuation.eval()
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
            if args.use_crf:
                y_predict = deep_punctuation(x, att, y)
                y_predict = y_predict.view(-1)
                y = y.view(-1)
            else:
                y_predict = deep_punctuation(x, att)
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
        f.write(str(args)+'\n')
    best_val_acc = 0
    for epoch in range(args.epoch):
        train_loss = 0.0
        train_iteration = 0
        correct = 0
        total = 0
        deep_punctuation.train()
        for x, y, att, y_mask in tqdm(train_loader, desc='train'):
            # All are torch.Size([8, 256])
            x, y, att, y_mask = x.to(device), y.to(device), att.to(device), y_mask.to(device)
            y_mask = y_mask.view(-1)
            if args.use_crf:
                loss = deep_punctuation.log_likelihood(x, att, y)
                # y_predict = deep_punctuation(x, att, y)
                # y_predict = y_predict.view(-1)
                y = y.view(-1)
            else:
                y_predict = deep_punctuation(x, att)
                y_predict = y_predict.view(-1, y_predict.shape[2])
                y = y.view(-1)
                loss = criterion(y_predict, y)
                y_predict = torch.argmax(y_predict, dim=1).view(-1)

                correct += torch.sum(y_mask * (y_predict == y).long()).item()

            optimizer.zero_grad()
            train_loss += loss.item()
            train_iteration += 1
            loss.backward()

            if args.gradient_clip > 0:
                torch.nn.utils.clip_grad_norm_(deep_punctuation.parameters(), args.gradient_clip)
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
            torch.save(deep_punctuation.state_dict(), model_save_path)

    print('Best validation Acc:', best_val_acc)
    deep_punctuation.load_state_dict(torch.load(model_save_path))
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

def convertToMLModel():
    with torch.no_grad():
        for x, y, att, y_mask in train_loader:
            # This is just to get example_input
            x, y, att, y_mask = x.to(device), y.to(device), att.to(device), y_mask.to(device)
            # print(x)
            # print(x.shape)
            # print(y)
            # print(y.shape)
            # print(att)
            # print(att.shape)
            # print(y_mask)
            # print(y_mask.shape)

            torch_model = deep_punctuation
            torch_model.load_state_dict(torch.load(model_save_path))
            # Set the model in evaluation mode.
            torch_model.eval()

            # Trace the model with random data.
            example_input = (x, att)
            traced_model = torch.jit.trace(torch_model, example_input)
            
            # Convert to Core ML program using the Unified Conversion API.
            # From https://developer.apple.com/videos/play/wwdc2021/10038/
            model = ct.convert(
                traced_model,
                convert_to="mlprogram", 
                inputs=[ct.TensorType(name='tokens', shape=(1, 256), dtype=types.int32), 
                        ct.TensorType(name='attention_mask', shape=(1, 256), dtype=types.int32)],
                minimum_deployment_target = ct.target.iOS15,
                compute_precision = ct.precision.FLOAT32 # Trade-off between precision and use of neural engine & model size
                # inputs=[ct.TensorType(shape=x.shape, dtype=types.int64), ct.TensorType(shape=att.shape, dtype=types.int64)]
            )

            # Set model metadata
            model.author = 'Brandon Thio'
            model.short_description = 'Restores punctuation in unpunctuated text'

            # Set feature descriptions manually
            model.input_description['tokens'] = 'The text in tokenised form, according to vocab.txt'
            model.input_description['attention_mask'] = 'The attention mask'

            # Set the output descriptions
            spec = model.get_spec()
            output_names = [out.name for out in spec.description.output]

            ct.utils.rename_feature(spec, str(output_names[0]), 'token_scores')
            model = ct.models.MLModel(spec, weights_dir=model.weights_dir)

            model.output_description['token_scores'] = "A 2D array where each outer array corresponds to each token of the input. The array's values correspond to relative confidence of the punctuation options for that token."
            

            # Save the converted model.
            model.save("model.mlpackage")
            break

def test_output():
    # Here we want to test that our mlmodel produces similar output to the original model. 
    # Some values may not correspond due to the conversion process and/or reduction in 
    # precision of the values e.g. int64 to int32

    # Load the model
    model = ct.models.MLModel('model.mlpackage')

    # Make predictions
    for x, y, att, y_mask in train_loader:
        # This is just to get example_input
        x, y, att, y_mask = x.to(device), y.to(device), att.to(device), y_mask.to(device)
        coreml_output = model.predict({'x_1': x.numpy().astype(np.float64), 'attn_masks': att.numpy().astype(np.float64)})['var_1067']
        actual_output = deep_punctuation(x, att)
        # print("THIS IS THE RAW OUTPUT")
        # print(actual_output)
        # print(coreml_output)

        # print("FLATTEN THE FIRST LAYER")
        # print(actual_output.view(-1, actual_output.shape[2]))
        # print(coreml_output.reshape(-1, coreml_output.shape[2]))

        # print("FIND MAX CONFIDENCE OUT OF ALL OPTIONS")
        print(torch.argmax(actual_output.view(-1, actual_output.shape[2]), dim=1).view(-1))
        print(np.argmax(coreml_output.reshape(-1, coreml_output.shape[2]), axis=1).reshape(-1))


if __name__ == '__main__':
    train()
    # convertToMLModel()
    # test_output()
