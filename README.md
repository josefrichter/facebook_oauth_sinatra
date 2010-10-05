# Facebook oauth and api in Sinatra

### iframe apps authentication with cookie problem workaround

here are the steps:

1. Render index page with JS SDK stuff: FB.init and FB.getLoginStatus - see `index.erb`
2. If getLoginStatus returns session, take signed_request from url and do top redirect **outside** facebook to `yourapp.com/setcookie`:

	line 16 of `index.erb`:
	 
	`top.location = "<%= APP_CONFIG['app_url'] %>/setcookie?signed_request="+jQuery.url.param("signed_request");`
	
3. At yourapp.com/setcookie take `signed_request` from url and save it to cookie. Then redirect back to `apps.facebook.com/your-app/iframe-dashboard`. It actually happens so fast, that the FB chrome around the iframe doesn't even disappear and users won't notice they were redirected outside and back

	lines 19, 20 of fbsin.rb:
	
	`session[:signed_request] = params[:signed_request] # just save parameter to cookie...`
	
	`redirect APP_CONFIG['fb_app_url']+"/iframe-dashboard"`
	
4. At `apps.facebook.com/your-app/iframe-dashboard` you can now read the `signed_request` from cookie
5. And of course you can read it on any other page of your app without sending it in url params 


### FB oauth process without any SDK

In everyday life you would probably use JS/PHP/Python/Ruby SDK, but it's useful to see how it works underneath.
Put your config to config.yml and you should be ready to go.
There are explanatory comments throughout the code.

##### FB oauth process:

* server side authenticating as user ('/connect')
* JS SDK authentication on client side ('/js')

##### Publishing message:

* from server side through "old" rest api (POST to '/restapi')
* from server side through new graph api (POST to '/graphapi')
* from client side using JS SDK ('/js')
* from client side by displaying pre-filled modal window (using JS SDK as well) ('/js')

Feel free to reuse