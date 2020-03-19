# Project imports.
require 'sinatra'
require 'bcrypt'
require_relative 'ruby-scripts/database-model.rb'
require_relative 'user-authentication.rb'

# For running the server from codio.
set :bind, '0.0.0.0'
enable :sessions

Bookmarks.init "../database/test.db"

before do
    if !session[:userID] 
        session[:userID] = -1
    end
end

# Redirect to the index view when a general 
# get connection is opened.
get '/' do
    
    @results = Bookmarks.getHomepageDataAll
    erb :index
end

get '/login' do
    if session[:userID] == -1 
        erb :loginPage
    else
        redirect '/'
    end
end

get '/search/:searchQuery' do
    @results = Bookmarks.getHomepageData params[:searchQuery]
    erb :search
end

post '/authenticate-user' do

    @login = params[:user_email]
    @password = params[:user_password]

    session[:userID] = UserAuthentication.check @login , @password
    if session[:userID] = -1
        @error = "Invalid login or password."
        erb :loginPage
    else
        redirect '/'
    end

end