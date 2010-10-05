require 'rubygems'
require 'sinatra'
require 'cgi'
require 'httparty'
require 'ruby-debug'

enable :sessions

APP_CONFIG = YAML.load_file("config.yml")

get '/' do
  
  if params[:signed_request]
    #redirect '/dashboard'
  end
  erb :index
end

get '/setcookie' do
  #debugger
  session[:signed_request] = params[:signed_request]
  redirect APP_CONFIG['fb_app_url']+"/dashboard"
end

get '/auth' do

  # this makes the first call (redirect to facebook). If the user is not logged in, he will be prompted to do so by facebook and asked to grant permissions to your app
  # once logged in, he will be redirected back to this app to the /oauth_redirect path
  # the whole process is described here http://developers.facebook.com/docs/authentication/#web_server_auth
  url = "https://graph.facebook.com/oauth/authorize?client_id=#{APP_CONFIG['app_id']}&redirect_uri=#{APP_CONFIG['app_url']}/oauth_redirect&scope=publish_stream" 
  # scope parameter is for requesting permissions. see http://developers.facebook.com/docs/authentication/ section section "Requesting Extended Permissions"
  redirect url
  
end 

get '/oauth_redirect' do
  
  # in the first step facebook will return this verification code
  if params[:code] # if this path is called by facebook with the code in parameter

    # we need to send the code back to get the token. the redirect_uri must be exactly the same!!!
    post_params = {:client_id => APP_CONFIG['app_id'], :client_secret => APP_CONFIG['secret'], :code => params[:code], :redirect_uri => APP_CONFIG['app_url']+"/oauth_redirect"}
    url = "https://graph.facebook.com/oauth/access_token"
    res = HTTParty.get(url, :query => post_params) # we do direct call here, no redirect needed anymore
    
    # we need to parse the response we got
    parts = res.body.split("&")
    hash = {}
    parts.each do |p| (k,v) = p.split("=")
      hash[k]=v
    end
    
    # from parsing we got beautiful access_token and its expiry. can store that in session
    session["access_token"] = hash["access_token"]
    session["expires"] = hash["expires"]
    redirect '/dashboard?token='+CGI.escape(hash["access_token"]) # now we have token so the fun may begin
  end
  
end

get '/dashboard' do
  #debugger
  #@token = session["access_token"] # get the token
  @signed_request = session[:signed_request]
  # here we can do anything that requires a user's token
  # like get basic info about user
  #@me = HTTParty.get("https://graph.facebook.com/me",:query => {:access_token => session["access_token"]})
  #@me = HTTParty.get("https://graph.facebook.com/me",:query => {:access_token => params[:token]})
  
  erb :dashboard
  
end

get '/js' do
  # this one makes use of the JS SDK entirely on client side
  erb :js
end

post '/restapi' do
  
  # rest api way
  # note: graph api is not to replace "old" rest api. it should serve as simpler way to access most common data. but the true power remains with rest api and they will co-exist
  # it's like activerecord vs. SQL - you would use AR everyday for most common stuff, but once in a while you need the power of SQL
  # documentation here http://developers.facebook.com/docs/reference/rest/stream.publish
  #post_params = {:uid => APP_CONFIG['user_id'], :target_id => APP_CONFIG['friend_id'], :message => message, :access_token => session["access_token"]} # sending from particular user to his particular friend's wall
  post_params = {:message => params[:message], :access_token => session["access_token"]}
  url="https://api.facebook.com/method/stream.publish"
  @res = HTTParty.get(url, :query => post_params)

  erb :response
  
end

post '/graphapi' do
  
  # graph api way:
  # documentation here http://developers.facebook.com/docs/reference/api/post
  post_params = {:message => params[:message], :access_token => session["access_token"]}
  url = "https://graph.facebook.com/me/feed" # publishing to user's wall
  # url = "https://graph.facebook.com/#{APP_CONFIG['friend_id']}/feed" # publishing to friend's wall
  @res = HTTParty.post(url, :query => post_params) # note you send GET to rest api, but POST to graph api
  
  erb :response

end

get '/test' do
end

get '/please' do
  @sr = session[:signed_request]
  erb :please
end

def app_token
  
  # we will authenticate as app here
  # this is generally needed for publishing to facebook
  # described here http://developers.facebook.com/docs/api#publishing and here: http://developers.facebook.com/docs/authentication/#client_credentials
  post_params = {:grant_type => "client_credentials", :client_id => APP_CONFIG['app_id'], :client_secret => APP_CONFIG['secret']}
  url = "https://graph.facebook.com/oauth/access_token"
  get_token = HTTParty.get(url,:query => post_params)

  # the following will get me the access token into hash["access_token"]
  parts = get_token.split("&")
  hash = {}
  parts.each do |p| (k,v) = p.split("=")
    hash[k]=v
  end
  app_token =  hash.values[0]
  
  return app_token

end