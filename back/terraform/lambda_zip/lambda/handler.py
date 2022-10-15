import logging
import json
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

def handler(event, context):
    LOGGER.info(f'Event Object: {event}')
    LOGGER.info(f'Context Object: {context}')
    event.body(event.body)
    LOGGER.info(f'BODY:{}')

    event['key'] = 'value'
    return {
    	'statusCode':200, 
    	'body':'<html>success</html>',
    	'headers': {
    		'Access-Control-Allow-Headers': '*',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
    	}
    }