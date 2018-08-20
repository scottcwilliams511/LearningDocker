import time
import redis
from flask import Flask


# Define our flask application
app = Flask(__name__)

# redis is the hostname of the redis container on the application's network
cache = redis.Redis(host = 'redis', port = 6379)

'''
The basic retry loop lets us attempt our request multiple times if the redis service
is not available. seful at startup, but also good incase redis needs to be restarted.
Helps handling momentary connection drops between nodes. '''
def get_hit_count():
    retries = 5
    while True:
        try:
            # Increments the number stored at key by one. If the key doesn't exist, it
            # is set to 0 before performing the operation.
            # Returns the value of the key after increment
            return cache.incr('this') 
        except redis.exceptions.ConnectionError as ex:
            if retries == 0:
                raise ex
            retries -= 1
            time.sleep(0.5)

'''
Function that will be called when the user navigates to path "/". '''
@app.route('/')
def hello():
    return 'Hello World! I have been seen {} times.\n'.format(get_hit_count())


'''
Since there is no main() function in Python, when the command to run a python program is given
to the interpreter, the code that is a level 0 indentation is to be executed. However, before doing
that, it will define a few special variables. `__name__` is one of these. If the source file is executed
as the main program, the interpretor sets the __name__ variaboe to "__main__". If it is being imported,
then it will be set to the module's name.

Basically, this will run if command `python app.py` is used. '''
if __name__ == "__main__":
    app.run(host = "0.0.0.0", debug = True)