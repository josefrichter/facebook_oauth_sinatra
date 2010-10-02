Facebook oauth and api in Sinatra

In everyday life you would probably use JS/PHP/Python/Ruby SDK, but it's useful to see how it works underneath.
Put your config to config.yml and you should be ready to go.
There are explanatory comments throughout the code.

FB oauth process:
- server side authenticating as user ('/' path)
- server side authenticating as application (both '/restapi' and '/graphapi')
- JS SDK authentication on client side ('/js')

Publishing message:
- from server side through "old" rest api ('/restapi')
- from server side through new graph api ('/graphapi')
- from client side using JS SDK ('/js')
- from client side by displaying pre-filled modal window (using JS SDK as well) ('/js')

Feel free to reuse