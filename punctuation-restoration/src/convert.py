import torch
from config import *
import os
import torch.multiprocessing
import coremltools as ct
from coremltools.converters.mil.mil import types
from model import Punctuator

save_path = 'out'
model_save_path = os.path.join(save_path, 'weights.pt')

def convertToMLModel():
    with torch.no_grad():
        torch_model = Punctuator()
        torch_model.load_state_dict(torch.load(model_save_path))
        # Set the model in evaluation mode.
        torch_model.eval()

        # Trace the model with random data.
        example_input = torch.tensor([ord('a') for i in range(2560)], dtype=torch.int32)
        traced_model = torch.jit.trace(torch_model, example_input)
        
        # Convert to Core ML program using the Unified Conversion API.
        # From https://developer.apple.com/videos/play/wwdc2021/10038/
        model = ct.convert(
            traced_model,
            convert_to="mlprogram", 
            inputs=[ ct.TensorType(name='text', shape=example_input.shape, dtype=types.int32)],
            minimum_deployment_target = ct.target.iOS15,
        )

        # Set model metadata
        model.author = 'Brandon Thio'
        model.short_description = 'Restores punctuation in unpunctuated text'

        # Set feature descriptions manually
        # model.input_description['tokens'] = 'The text in tokenised form, according to vocab.txt'
        # model.input_description['attention_mask'] = 'The attention mask'

        # Set the output descriptions
        spec = model.get_spec()
        output_names = [out.name for out in spec.description.output]

        ct.utils.rename_feature(spec, str(output_names[0]), 'token_scores')
        model = ct.models.MLModel(spec, weights_dir=model.weights_dir)

        model.output_description['token_scores'] = "A 2D array where each outer array corresponds to each token of the input. The array's values correspond to relative confidence of the punctuation options for that token."
        

        # Save the converted model.
        model.save("model.mlpackage")

if __name__ == "__main__":
    convertToMLModel()