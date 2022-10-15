import logging
import json
import string
from pathlib import Path
from collections import Counter
from itertools import chain
import operator

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

DICT = "words"

ALLOWABLE_CHARACTERS = set(string.ascii_letters)
ALLOWED_ATTEMPTS = 6
WORD_LENGTH = 5


WORDS = {
  word.lower()
  for word in Path(DICT).read_text().splitlines()
  if len(word) == WORD_LENGTH and set(word) < ALLOWABLE_CHARACTERS
}

LETTER_COUNTER = Counter(chain.from_iterable(WORDS))
LETTER_FREQUENCY = {
    character: value / sum(LETTER_COUNTER.values())
    for character, value in LETTER_COUNTER.items()
}

def calculate_word_commonality(word):
    score = 0.0
    for char in word:
        score += LETTER_FREQUENCY[char]
    return score / (WORD_LENGTH - len(set(word)) + 1)

def sort_by_word_commonality(words):
    sort_by = operator.itemgetter(1)
    return sorted(
        [(word, calculate_word_commonality(word)) for word in words],
        key=sort_by,
        reverse=True,
    )

def display_word_table(word_commonalities):
    for (word, freq) in word_commonalities:
        print(f"{word:<10} | {freq:<5.2}")


def match_word_vector(word, word_vector):
    assert len(word) == len(word_vector)
    for letter, v_letter in zip(word, word_vector):
        if letter not in v_letter:
            return False
    return True

def match(word_vector, possible_words):
    return [word for word in possible_words if match_word_vector(word, word_vector)]


def suggest_words(attempts):
    possible_words = WORDS.copy()
    word_vector = [set(string.ascii_lowercase) for _ in range(WORD_LENGTH)]
    for attempt,wordle_response in attempts:
        for idx, letter in enumerate(wordle_response):
            if letter.upper() == "G":
                word_vector[idx] = {attempt[idx]}
            elif letter.upper() == "Y":
                try:
                    word_vector[idx].remove(attempt[idx])
                except KeyError:
                    pass
            elif letter.upper() == "?":
                for vector in word_vector:
                    try:
                        vector.remove(attempt[idx])
                    except KeyError:
                        pass
    possible_words = match(word_vector, possible_words)
    display_word_table(sort_by_word_commonality(possible_words)[:15])
    return sort_by_word_commonality(possible_words)[:15]


def handler(event, context):
    body_payload = json.loads(event.get("body"))
    LOGGER.info(f'PAYLOAD:{body_payload}')
    LOGGER.info(f'ITEMS:{body_payload.get("items")}')

    word_pairs = [(x.get("text", "").lower(), x.get("result", "" ).upper()) for x in body_payload.get("items")]
    

    event['key'] = 'value'
    return {
        'statusCode':200, 
        'body': json.dumps(suggest_words(word_pairs)),
        'headers': {
            'Access-Control-Allow-Headers': '*',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        }
    }