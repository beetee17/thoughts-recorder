import numpy as np
from transformers import AlbertForMaskedLM, AlbertTokenizer, pipeline
import os
import torch.multiprocessing
import coremltools as ct
from coremltools.converters.mil.mil import types

import torch.nn as nn
import torch
from transformers import AlbertForMaskedLM, AlbertTokenizer
from torchcrf import CRF


class AutoCorrect(nn.Module):
    def __init__(self):
        super(AutoCorrect, self).__init__()
        self.model = AlbertForMaskedLM.from_pretrained("albert-base-v2")
        self.tokenizer = AlbertTokenizer.from_pretrained("albert-base-v2")

    def forward(self, tokens, attn_masks=None):
        model_outputs = self.model(tokens, attention_mask=attn_masks)
        tensorsDictPrint(model_outputs)
        logits = model_outputs.logits
        print("LOGITS: {} \n{}".format(logits.shape, logits))
        
        probs = logits.softmax(dim=-1)
        print(probs.shape, probs)
        return probs

def convertToMLModel():
    model = AlbertForMaskedLM.from_pretrained("albert-base-v2", return_dict=False)
    query = """ Minutes is able to generate subtitle-like timestamps for your transcriptions that [MASK] with audio playback
            Minutes is able to generate subtitle-like timestamps for your transcriptions that sync with audio playback
            Minutes is able to generate subtitle-like timestamps for your transcriptions that sync with audio playback
            Minutes is able to generate subtitle-like timestamps for your transcriptions that sync with audio playback
            Minutes is able to generate subtitle-like timestamps for your transcriptions that sync with audio playback
            Minutes is able to generate subtitle-like timestamps for your transcriptions that sync with audio playback. """
    tokenizer = AlbertTokenizer.from_pretrained("albert-base-v2")
    model_inputs = tokenizer(query, return_tensors='pt')
    example_input = model_inputs['input_ids']

    traced_model = torch.jit.trace(model, (example_input, example_input))

    model = ct.convert(
            traced_model,
            convert_to="mlprogram", 
            inputs=[ct.TensorType(name='tokens', shape=example_input.shape, dtype=types.int32),
                    ct.TensorType(name='attention_mask', shape=example_input.shape, dtype=types.int32)],
            minimum_deployment_target = ct.target.iOS15,
        )
    # Set model metadata
    model.author = 'Brandon Thio'
    model.short_description = 'Performs auto correct on a sentence'

    # Set feature descriptions manually
    # model.input_description['tokens'] = 'The text in tokenised form, according to vocab.txt'
    # model.input_description['attention_mask'] = 'The attention mask'

    # Set the output descriptions
    spec = model.get_spec()
    output_names = [out.name for out in spec.description.output]

    ct.utils.rename_feature(spec, str(output_names[0]), 'scores')
    model = ct.models.MLModel(spec, weights_dir=model.weights_dir)

    model.output_description['scores'] = """An array of size 1 x <MAX_SEQ_LEN> x <VOCAB_SIZE> 
                                            with each inner array corresponding to the input token at that index,
                                            containing the confidence scores for every word in vocab.txt"""
    

    # Save the converted model.
    model.save("model.mlpackage")

def convertAgain():
    model = AutoCorrect()
    query = """ Minutes is able to generate subtitle-like timestamps for your transcriptions that [MASK] with audio playback
            Minutes is able to generate subtitle-like timestamps for your transcriptions that sync with audio playback
            Minutes is able to generate subtitle-like timestamps for your transcriptions that sync with audio playback
            Minutes is able to generate subtitle-like timestamps for your transcriptions that sync with audio playback
            Minutes is able to generate subtitle-like timestamps for your transcriptions that sync with audio playback
            Minutes is able to generate subtitle-like timestamps for your transcriptions that sync with audio playback. """
    tokenizer = AlbertTokenizer.from_pretrained("albert-base-v2")
    model_inputs = tokenizer(query, return_tensors='pt')
    example_input = model_inputs['input_ids']

    traced_model = torch.jit.trace(model, (example_input, example_input))

    model = ct.convert(
            traced_model,
            convert_to="mlprogram", 
            inputs=[ct.TensorType(name='tokens', shape=example_input.shape, dtype=types.int32),
                    ct.TensorType(name='attention_mask', shape=example_input.shape, dtype=types.int32)],
            minimum_deployment_target = ct.target.iOS15,
        )
    # Set model metadata
    model.author = 'Brandon Thio'
    model.short_description = 'Performs auto correct on a sentence'

    # Set feature descriptions manually
    # model.input_description['tokens'] = 'The text in tokenised form, according to vocab.txt'
    # model.input_description['attention_mask'] = 'The attention mask'

    # Set the output descriptions
    spec = model.get_spec()
    output_names = [out.name for out in spec.description.output]

    ct.utils.rename_feature(spec, str(output_names[0]), 'scores')
    model = ct.models.MLModel(spec, weights_dir=model.weights_dir)

    model.output_description['scores'] = """An array of size 1 x <MAX_SEQ_LEN> x <VOCAB_SIZE> 
                                                with each inner array corresponding to the input token at that index,
                                                containing the softmax-ed scores for every word in vocab.txt"""
        

    # Save the converted model.
    model.save("model.mlpackage")

def pipelineDemo():
    unmasker = pipeline('fill-mask', model='albert-base-v2')
    while True:
        query = input("Enter a sentence with the masked token {}\n".format(unmasker.tokenizer.mask_token))

        if len(query) != 0:
            targets = []
            while True:
                target = input("Enter a target word (or nothing if you are done):\n")
                if len(target) != 0:
                    targets.append(target)
                else:
                    break
            try:
                if len(targets) == 0:
                    predictions = unmasker(query, top_k=10)
                else:
                    predictions = unmasker(query, targets=targets)
                for p in predictions:
                    print("PREDICTED TOKEN {}: {}, CONFIDENCE {}".format(p["token"], p["token_str"], p['score']))
                    print(p["sequence"])
                    print("\n")

                print("\n")
            except Exception as e:
                print(e)
                continue
        else:
            break

def tensorsDictPrint(dict):
 for key, value in dict.items():
        print(key, value.shape)
        print(value)

def get_target_ids(tokenizer, targets, top_k=None):
        if isinstance(targets, str):
            targets = [targets]
        try:
            vocab = tokenizer.get_vocab()
        except Exception:
            vocab = {}
        target_ids = []
        for target in targets:
            id_ = vocab.get(target, None)
            if id_ is None:
                input_ids = tokenizer(
                    target,
                    add_special_tokens=False,
                    return_attention_mask=False,
                    return_token_type_ids=False,
                    max_length=1,
                    truncation=True,
                )["input_ids"]
                if len(input_ids) == 0:
                    print(
                        f"The specified target token `{target}` does not exist in the model vocabulary. "
                        f"We cannot replace it with anything meaningful, ignoring it"
                    )
                    continue
                id_ = input_ids[0]
                # XXX: If users encounter this pass
                # it becomes pretty slow, so let's make sure
                # The warning enables them to fix the input to
                # get faster performance.
                print(
                    f"The specified target token `{target}` does not exist in the model vocabulary. "
                    f"Replacing with `{tokenizer.convert_ids_to_tokens(id_)}`."
                )
            target_ids.append(id_)
        target_ids = list(set(target_ids))
        if len(target_ids) == 0:
            raise ValueError("At least one target must be provided when passed.")
        target_ids = np.array(target_ids)
        return target_ids

def testAlbertForMaskedLM():
    print("LOADING, PLEASE WAIT...")
    model = AlbertForMaskedLM.from_pretrained("albert-base-v2")
    query = """Minutes is able to generate subtitle-like timestamps for your transcriptions that [MASK] with audio playback"""

    tokenizer = AlbertTokenizer.from_pretrained("albert-base-v2")

    model_inputs = tokenizer(query, return_tensors='pt')
    input_ids = model_inputs['input_ids']
    tensorsDictPrint(model_inputs)

    model_outputs = model(input_ids)
    tensorsDictPrint(model_outputs)


    masked_index = torch.nonzero(input_ids == tokenizer.mask_token_id, as_tuple=False).squeeze(-1)[0, 1].item()
    print("MASK AT INDEX", masked_index)

    logits = model_outputs.logits
    logits = logits[0, masked_index, :]
    print("LOGITS: {} \n{}".format(logits.shape, logits))
    
    probs = logits.softmax(dim=-1)
    print("PROBS:", probs)

    targets = ['coincide']

    targets_as_ids = get_target_ids(tokenizer=tokenizer, targets=targets)
    for i in range(len(targets)):
        idx = targets_as_ids[i]
        print("{}: {}".format(targets[i], probs[idx].item()))

if __name__ == "__main__":
    
    # convertAgain()
    # testAlbertForMaskedLM()
   
    pipelineDemo()
    