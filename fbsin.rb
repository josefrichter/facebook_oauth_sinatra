require 'rubygems'
require 'sinatra'
require 'cgi'
require 'httparty'
require 'ruby-debug'

enable :sessions

APP_CONFIG = YAML.load_file("config.yml")

get '/' do

  # this makes the first call (redirect to facebook). If the user is not logged in, he will be prompted to do so by facebook
  # once logged in, he will be redirected back to the oauth_redirect path
  # the whole process is described here http://developers.facebook.com/docs/authentication/#web_server_auth
  url = "https://graph.facebook.com/oauth/authorize?client_id=#{APP_CONFIG['app_id']}&redirect_uri=#{APP_CONFIG['app_url']}/oauth_redirect&scope=publish_stream" 
  # request permissions. see http://developers.facebook.com/docs/authentication/ section section "Requesting Extended Permissions"
  redirect url
  
end 

get '/oauth_redirect' do
  
  # in the first step facebook will return this verification code
  if !params[:code].nil?
    # we need to send the code back to get the token. the redirect_uri must be exactly the same!!!
    url = "https://graph.facebook.com/oauth/access_token?client_id=#{APP_CONFIG['app_id']}&redirect_uri=#{APP_CONFIG['app_url']}/oauth_redirect&client_secret=#{secret}&code=#{CGI.escape(params[:code])}"
    res = HTTParty.get(url) # we do direct call here, no redirect needed anymore
    
    # we need to parse the response we got
    parts = res.body.split("&")
    hash = {}
    parts.each do |p| (k,v) = p.split("=")
      hash[k]=v
    end
    
    # from parsing we got beautiful access_token and its expiry. can store that in session
    session["access_token"] = hash["access_token"]
    session["expires"] = hash["expires"]
    redirect '/dashboard' # now we have token so the fun may begin
  end
  
end

get '/dashboard' do
  
  @token = session["access_token"] # get the token
  
  # here we can do anything that requires a user's token
  
  erb :dashboard
  
end

get '/js' do
  # this one makes use of the JS SDK entirely on client side
  erb :js
end

get '/restapi' do
  
  message = "message sent thru rest api"
  
  # rest api way
  # note: graph api is not to replace "old" rest api. it should serve as simpler way to access most common data. but the true power remains with rest api and they will co-exist
  # it's like activerecord vs. SQL - you would use AR everyday for most common stuff, but once in a while you need the power of SQL
  # documentation here http://developers.facebook.com/docs/reference/rest/stream.publish
  url="https://api.facebook.com/method/stream.publish?uid=#{APP_CONFIG['user_id']}&target_id=#{APP_CONFIG['friend_id']}&message=#{CGI.escape(message)}&access_token=#{CGI.escape(app_token)}"
  @res = HTTParty.get(url)
  
  erb :index
  
end

get '/graphapi' do
  
  message = "message sent thru graph api"
  
  # graph api way:
  # documentation here http://developers.facebook.com/docs/reference/api/post
  post_params = {:message => message, :access_token => app_token}
  # url = "https://graph.facebook.com/#{APP_CONFIG['user_id']}/feed" # publishing to user's wall
  url = "https://graph.facebook.com/#{APP_CONFIG['friend_id']}/feed" # publishing to friend's wall
  @res = HTTParty.post(url, :query => post_params) # note you send GET to rest api, but POST to graph api
  
  erb :index

end

def app_token
  
  # we will authenticate as app here
  # this is generally needed for publishing to facebook
  # described here http://developers.facebook.com/docs/api#publishing and here: http://developers.facebook.com/docs/authentication/#client_credentials
  post_data = HTTParty.get("https://graph.facebook.com/oauth/access_token?grant_type=client_credentials&client_id=#{APP_CONFIG['app_id']}&client_secret=#{APP_CONFIG['secret']}")

  # the following will get me the access token into hash["access_token"]
  parts = post_data.split("&")
  hash = {}
  parts.each do |p| (k,v) = p.split("=")
    hash[k]=v
  end
  
  return hash.values[0]

end