import csv
import os
import re

from sympy import fu

dirname = os.path.dirname(__file__)
csv_filename = os.path.join(dirname, '../data/en/ted_talks_en.csv')
train_filename = os.path.join(dirname, '../data/en/ted_talks_train.txt')
test_filename = os.path.join(dirname, '../data/en/ted_talks_test.txt')
val_filename = os.path.join(dirname, '../data/en/ted_talks_val.txt')

with open(csv_filename, 'r') as file:
    csvreader = csv.reader(file)
    transcripts = []
    for row in csvreader:
        # Last column is transcript column
        transcript = row[-1]

        """
        From https://stackoverflow.com/questions/14596884/remove-text-between-and
        Removes everything between and including [] and ()
        Does not work with nested brackets
        """
        transcript = re.sub("[\(\[].*?[\)\]]", "", transcript)

        # Replace elipses with single period
        transcript = transcript.replace('...', '.')

        # Remove all double-quotes
        transcript = transcript.replace('"', '')

        # Converts hyphenated word to separate words e.g. "low-cost" -> "low cost"
        transcript = re.sub("-", " ", transcript)

        # Treat exclamation mark like full stop
        transcript = re.sub('!', ".", transcript)

        # Removes any extra whitespaces between words
        transcript = re.sub(r'\s+', ' ', transcript)
        
        # Removes whitespaces before punctuation
        transcript = re.sub(r'\s([?.!"](?:\s|$))', r'\1', transcript)

        transcripts.append(transcript.strip())

    # First row is headers
    transcripts = transcripts[1:]
    print(transcripts[0])

    length = len(transcripts)

    TRAIN_FRAC = int(0.8 * length)
    TEST_FRAC = (length - TRAIN_FRAC) // 2 + TRAIN_FRAC

    # Concatenate everything
    train = [word for word in " ".join(transcripts[:TRAIN_FRAC]).split(" ") if len(word.strip()) > 0]
    test = [word for word in " ".join(transcripts[TRAIN_FRAC:TEST_FRAC]).split(" ") if len(word.strip()) > 0]
    val = [word for word in " ".join(transcripts[TEST_FRAC:]).split(" ") if len(word.strip()) > 0]


    with open(train_filename, 'w') as out_file:
        """
        the first symbol of the label indicates what punctuation mark 
        should follow the word (where O means no punctuation needed).
        The second symbol determines if a word needs to be capitalized or not
        (where U indicates that the word should be upper cased, 
        and O - no capitalization needed.) The complete list of all possible labels is: 
        OO    ,O    .O   ?O   OU  ,U  .U, ?U.
        """
        for word in train:
            if word.endswith("."):
                out_file.write(word[:-1].lower() + "\t" + ".")
            elif word.endswith(","):
                out_file.write(word[:-1].lower() + "\t" + ",")
            elif word.endswith("?"):
                out_file.write(word[:-1].lower() + "\t" + "?")
            else:
                out_file.write(word.lower() + "\t" + "O")

            if word[0].isupper():
                out_file.write("U")
            else:
                out_file.write("O")

            out_file.write("\n")

        with open(test_filename, 'w') as out_file:
            for word in test:
                if word.endswith("."):
                    out_file.write(word[:-1].lower() + "\t" + ".")
                elif word.endswith(","):
                    out_file.write(word[:-1].lower() + "\t" + ",")
                elif word.endswith("?"):
                    out_file.write(word[:-1].lower() + "\t" + "?")
                else:
                    out_file.write(word.lower() + "\t" + "O")

                if word[0].isupper():
                    out_file.write("U")
                else:
                    out_file.write("O")

                out_file.write("\n")

        with open(val_filename, 'w') as out_file:
            for word in val:
                if word.endswith("."):
                    out_file.write(word[:-1].lower() + "\t" + ".")
                elif word.endswith(","):
                    out_file.write(word[:-1].lower() + "\t" + ",")
                elif word.endswith("?"):
                    out_file.write(word[:-1].lower() + "\t" + "?")
                else:
                    out_file.write(word.lower() + "\t" + "O")

                if word[0].isupper():
                    out_file.write("U")
                else:
                    out_file.write("O")

                out_file.write("\n")
            


        
            