# Project imports.
require 'sinatra'
require 'bcrypt'
require_relative 'ruby-scripts/database-model.rb'
require_relative 'user-authentication.rb'
require_relative 'ruby-scripts/support-functions.rb'
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
        erb :loginpage
    else
        redirect '/'
    end
end


post '/authenticate-user' do

    @login = params[:user_email]
    @password = params[:user_password]
    @result = UserAuthentication.check @login , @password
    @error=""
    
    if @result == -1
        @error = "Invalid login or password"
    elsif @result == "Suspended"
        redirect '/msg?msg=suspended'
    else
        session[:userID] = @result
        redirect '/'
    end
    
    erb:loginpage

end

get '/registration' do
    erb :registration
end

post '/registration' do

    @error_msg = ""
    @displayName = params[:displayName]
    @email = params[:email]
    @email_valid = params[:email_validation]
    
    if @error_msg == ""
        newUser @displayName , @email, params[:password]
        redirect '/msg?msg=newUser'
    else
        erb:registration
    end

end

# Search handling.
get '/search' do
    req = Rack::Request.new(env)
    req.post?
    @searchQuery = req.params["search_query"]

    @results = Bookmarks.getHomepageData @searchQuery
    
    if(@results.length != 0) then
        erb :search
    else
        erb :noResults
    end
end

get '/report-bookmark' do
    erb :newReport
end

post '/report-bookmark' do

    @ID = params[:bookmarkID]
    @type = params[:category]
    @desc = params[:details]=="" ? nil : params[:details]
    @reporterID = session[:userID]

    newReport @ID, @reporterID, @type, @desc

    redirect '/msg?msg=reportThanks'

end

get '/bookmark-spesifics' do

    @ID = params[:bookmarkID]
    @details = Bookmarks.getGuestBookmarkDetails @ID.to_i
    @title = @details[:details][:title]
    @desc = @details[:details][:description]
    @date = @details[:details][:date]
    @displayName = @details[:details][:displayName]
    @displayName = @details[:details][:email] if @displayName == nil
    @link = @details[:details][:link]

    addView @ID, session[:userID]

    erb :bookmarkDetails

end

get '/newBookmark' do
    if session[:userID] != -1 
        if Bookmarks.isVerified session[:userID]
            @tagList = Bookmarks.getTagNames
            erb :newBookmark
        else
            redirect '/msg?msg=waitForVerification'
        end
    else
        redirect '/'
    end
end

post '/newBookmark' do
    @title = params[:title]
    @link = params[:link]
    @desc = params[:desc]
    @tags = extractTagsFromParams params
    @userID = session[:userID]

    newBookmark @userID, @title, @link, @desc
    redirect '/msg?msg=newBookmarkMsg' 
   
end

get '/delete-bookmark' do 
    @bookmarkID = params[:bookmarkID]
    @userID = session[:userID]
    @creator = Bookmarks.getBookmarkCreator(@bookmarkID)
   if @userID == @creator then
        erb :deleteBookmark
   else
        redirect '/msg?msg=deleteError'
   end       
end        

post '/delete-bookmark' do
    @bookmarkID = params[:bookmarkID]

    deleteBookmark @bookmarkID
    redirect '/msgGoHome?msg=successfulDelete'
end

get '/bookmark-addView' do
    addView params[:bookmarkID], session[:userID]
    redirect back
end

get '/msg' do
    @message = params[:msg]==nil ? :defaultMsg : params[:msg].to_sym
    erb :message
end

get '/msgGoHome' do
    @message = params[:msg]==nil ? :defaultMsg : params[:msg].to_sym
    erb :messageGoHome
end

get '/testing' do
    @tagList = Bookmarks.getTagNames
    @checked = ['tag0']
    @returnedTags = extractTagsFromParams params
    erb :test
end