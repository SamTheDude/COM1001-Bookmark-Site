require 'sqlite3'
require 'bcrypt'

module Bookmarks
    
    #===Constants declaration
    UNVERIFIED_STRING = "Unverified"
    USER_STRING = "User"
    ADMIN_STRING = "Admin"
    #===Setup methods===

    #Run to open the database connection
    
    def Bookmarks.init databaseDirectory
        @@db = SQLite3::Database.open File.join(File.dirname(__FILE__), databaseDirectory)
        @@db.results_as_hash = true
    end 

    #===Execute Override===
    #(Only to be used for the testing and database resets.)

    def Bookmarks.execute query
        return @@db.execute query
    end

    #===Queries methods===

    #Retursns list of bookmarks with titles containing param search
    #Params: search - what to look for in target titles
    #Returns: A array of hashes with following keys (or nil if input was incorrect): 
    #   :ID - id of a bookmark
    #   :title - title of a bookmark
    #   :link - link to the bookmark
    #   :rating - avg rating of a bookmark
    #   :views - total view count of a bookmark
    def Bookmarks.getHomepageData search
        result = nil
        if search
            query = "SELECT * FROM bookmark_list
                    WHERE title LIKE ?;"  
            result = @@db.execute query, "%#{search}%"
            result.each do |row|
                for i in 0..(row.length()/2)
                    row.delete(i)
                end
                row.transform_keys!(&:to_sym)
                row.each do |key,value|
                    if row[key] == nil
                        row[key] = 0
                    end
                end
            end
        end
        return result
    end

    #Returns list of all bookmarks 
    #Returns: A array of hashes with following keys: 
    #   :ID - id of a bookmark
    #   :title - title of a bookmark
    #   :rating - avg rating of a bookmark
    #   :views - total view count of a bookmark
    def Bookmarks.getHomepageDataAll
        return Bookmarks.getHomepageData ""
    end

    #Returns: An array of distinct user emails(strings)
    def Bookmarks.currentUserEmails
        query = "SELECT DISTINCT user_email AS email
                FROM users;"
        result = @@db.execute query
        (0..(result.length()-1)).each do |i|
            result[i] = result[i]["email"]
        end
        return result
    end

    #Given an email returns id and password hash of a given user
    #Params: email - an email of a current user
    #Returns: A hash with following keys (or nil if input was incorrect):
    #   :id - user id
    #   :password - user password's hash
    def Bookmarks.getDetailsByEmail email
        result = nil
        if email
            query = "SELECT 
                    user_id AS id,
                    user_password AS password,
                    user_suspended AS suspended,
                    user_type AS type
                    FROM users
                    WHERE user_email=?;"
            result = @@db.execute query,email

            if result.length > 0
                result = result[0]
                for i in 0..(result.length()/2)
                    result.delete(i)
                end
                result.transform_keys!(&:to_sym)
            else
                result = nil
            end
        end
        return result
    end

    #Returns details of a bookmark when viewed by a guest
    #Params: id (integer) - an id of a bookmark in current system
    #Returns: A hash with following keys:
    #   :details - A hash with following keys (or nil if input was incorrect):
    #       :ID - id of a bookmark
    #       :title - title of a bookmark
    #       :description - description of a bookmark
    #       :link - link of a bookmark
    #       :date - date of creation of a bookmark
    #       :email - email of an autor of a bookmark
    #       :displayName - display name of an author of a bookmark
    #   :tags - An array of hashes with following keys (or nil if input wasn't an integer):
    #       :name - name of a tag the bookmark is tagged with
    #       :colour - coulour of a tag the bookmark is tagged with
    def Bookmarks.getBookmarkDetails id
        
        result = Hash.new
        result[:details] = nil
        result[:tags] = nil
       
        if Bookmarks.isInteger(id)

            query = "SELECT 
            bookmark_ID AS ID,
            bookmark_title AS title,
            bookmark_description AS description,
            bookmark_link AS link,
            date_created AS date,
            user_email AS email,
            user_displayName AS displayName
            FROM bookmark JOIN users ON creator_ID = user_ID
            WHERE bookmark_ID = ?;"

            result[:details] = @@db.execute query , id.to_i

            if result[:details].length() >0
                result[:details] = result[:details][0]
                for i in 0..(result[:details].length()/2)
                    result[:details].delete(i)        
                end
                result[:details].transform_keys!(&:to_sym)
            else
                result[:details] = nil
            end

            query = "SELECT 
                    tag_name AS name,
                    tag_colour AS colour
                    FROM tag_bookmark_link JOIN tag USING(tag_ID)
                    WHERE bookmark_ID = ?;"
            result[:tags] = @@db.execute query, id.to_i
            result[:tags].each do |row|
                for i in 0..(row.length()/2)
                    row.delete(i)        
                end
            end
            result[:tags].map{|row| row.transform_keys!(&:to_sym)}       
        end

        return result
    end

    #Returns value the user rated the bookmark with
    #Params:
    #   bookmark_id - an id of a bookmark in current system
    #   user_id - an id of a user viewing the bookmark
    #Returns: a value the user rated bookmark with 
    #         or nil if the bookmark hasn't been rated yet or input was incorrect
    def Bookmarks.getRating bookmark_ID, user_ID
        if (Bookmarks.isInteger bookmark_ID) && (Bookmarks.isInteger user_ID)
            query = "SELECT rating_value
                    FROM rating
                    WHERE bookmark_ID = ? AND rater_ID = ?"
            value = @@db.get_first_value query , bookmark_ID.to_i, user_ID.to_i
            value = value.to_i if !value.nil?
            return value;
        end
        return nil
    end

    #Returns true if giben bookmark was liked by the user and false if not
    #Params:
    #   bookmark_id - an id of a bookmark in current system
    #   user_id - an id of a user viewing the bookmark
    def Bookmarks.isLiked bookmark_ID, user_ID
        if (Bookmarks.isInteger user_ID) && (Bookmarks.isInteger bookmark_ID)
                query = "SELECT * FROM favourite
                WHERE user_ID = ? AND bookmark_ID = ?;"
                rows = @@db.execute query, user_ID.to_i, bookmark_ID.to_i
                if(rows.length() != 0) 
                    return true
                else     
                   return false
                end
        end
        return nil
    end

    #Returns: An array with all the tag names
    def Bookmarks.getTagNames
        query = "SELECT tag_name FROM tag";
        result = @@db.execute query
        (0..(result.length()-1)).each do |i|
            result[i] = result[i]["tag_name"]
        end

        return result
    end

    #Returns tagId with the given name
    def Bookmarks.getTagId name
        if name
            query = "SELECT tag_ID
                    FROM tag
                    WHERE tag_name = ?;"
            result = @@db.get_first_value query, name.to_s
            return result
        end

        return nil

    end

    #Returns a name of a given tag
    def Bookmarks.getTagName tagID
        if Bookmarks.isInteger tagID
            query = "SELECT tag_name
                    FROM tag
                    WHERE tag_ID = ?;"
            result = @@db.get_first_value query, tagID
            
            return result
        end
        return nil
    end

    #Returns names of tags the bookmark is tagged with
    def Bookmarks.getBookmarkTagsNames bookmarkID
        
        if Bookmarks.isInteger bookmarkID
            query = "SELECT tag_name
                    FROM tag_bookmark_link JOIN tag ON tag.tag_ID = tag_bookmark_link.tag_ID      
                    WHERE bookmark_ID = ?;"
            result = @@db.execute query, bookmarkID
            
            if  result.length()>0
                for i in 0..(result.length()/2)
                    result.delete(i)        
                end
                (0..(result.length-1)).each do |i|
                    result[i] = result[i]["tag_name"]
                end
            else
                result = Array.new
            end

            return result
        end
        return nil
    end
    
    #Returns details of a user with given id
    #Params: id(integer) - an id of a user 
    #Returns: A hash containing with following keys (or nil if input was incorrect):
    #   :name - display name of a user
    #   :email - email of a user
    #   :department - department of a user
    def Bookmarks.getUserDetails id
        result = nil
        if Bookmarks.isInteger id
            query = "SELECT user_displayName AS name,
                    user_email AS email,
                    user_department AS department
                    FROM users
                    WHERE user_ID = ?;"
            result = @@db.execute query, id.to_i

            if(result.length()>0)
                result = result[0]
                for i in 0..(result.length()/2)
                    result.delete(i)        
                end
                result.transform_keys!(&:to_sym)
            else
                result = nil
            end
        end
        return result
    end 

    #Returns list of bookmarks on given users favourite list
    #Params: id (integer) - id of a given user
    #Returns: An array of hashes with following keys (or nil if input was incorrect): 
    #   :ID - id of a bookmark
    #   :title - title of a bookmark
    #   :link - link to the bookmark
    #   :rating - avg rating of a bookmark (nil if no ratings)
    #   :views - total view count of a bookmark
    def Bookmarks.getFavouriteList id
        result = nil
        if Bookmarks.isInteger id
            query = "SELECT ID, title, rating, views 
                    FROM favourite JOIN bookmark_list ON bookmark_ID = ID
                    WHERE user_ID = ?;"
            result = @@db.execute query,id.to_i
            result.each do |row|
                for i in 0..(row.length()/2)
                    row.delete(i)        
                end
                row.each do |key,value|
                    if row[key] == nil
                        row[key] = 0
                    end
                end
            end
            result.map{|row| row.transform_keys!(&:to_sym)}
        end

        return result
    end

    #Returns a list of users waiting for verification
    #Returns: An array of hashes with following keys:
    #   :ID - id of a user
    #   :email - email of a user 
    #   :displayName - display name of a user
    #   :department - department of a user
    def Bookmarks.getUnverifiedList 
        query = "SELECT 
                user_ID AS ID,
                user_email AS email,
                user_displayName as displayName,
                user_department as department
                FROM users
                WHERE user_type = ?;"
        result = @@db.execute query, UNVERIFIED_STRING
        result.each do |row|
            for i in 0..(row.length()/2)
                row.delete(i)        
            end
        end
        result.map{|row| row.transform_keys!(&:to_sym)}
        
        return result
    end
    
    #Returns a list of users already verified
    #Returns: An array of hashes with following keys:
    #   :ID - id of a user
    #   :email - email of a user 
    #   :displayName - display name of a user
    #   :department - department of a user
    #   :status - type of user perrmisons
    #   :suspended - is the usersuspended
    def Bookmarks.getVerifiedList
        query = "SELECT 
                user_ID AS ID,
                user_email AS email,
                user_displayName AS displayName,
                user_department AS department,
                user_type AS status
                FROM users
                WHERE NOT user_type = ?
                AND user_suspended = 0;"
        result = @@db.execute query, UNVERIFIED_STRING
        result.each do |row|
            for i in 0..(row.length()/2)
                row.delete(i)        
            end
        end
        result.map{|row| row.transform_keys!(&:to_sym)}

        return result
    end
    
    #Returns details needed for accessRight check
    def Bookmarks.getAccessDetails userID
        
        if (Bookmarks.isInteger userID) && userID != -1
            query = "SELECT user_type,
                    user_suspended
                    FROM users
                    WHERE user_ID = ?;"
            result = @@db.execute query, userID
            result = result[0]
            if result
                for i in 0..(result.length()/2)
                    result.delete(i)        
                end
                result.transform_keys!(&:to_sym)
            end
            
            return result
        else
            return nil
        end
    end

    #Returns a viewing history of specified user
    #Params: id (integer) - is of the specified user
    #Returns: An array of hashes with following keys (or nil if input was incorrect):
    #   :bookmark_ID - id of a bookmark viewed
    #   :date - when was the bookmark viewed
    def Bookmarks.getViewHistory id
        result = nil
        if Bookmarks.isInteger id
            query = "SELECT
                    bookmark_viewed_ID AS bookmark_ID,
                    view_date AS date
                    FROM views
                    WHERE viewer_ID = ?;"
            result = @@db.execute query, id.to_i
            result.each do |row|
                for i in 0..(row.length()/2)
                    row.delete(i)        
                end
            end
            result.map{|row| row.transform_keys!(&:to_sym)}
        end

        return result
    end

    #Returns a list of unresolved reports
    #Returns: An array of hashes with following keys:
    #   :bookmark_ID - id of a bookmark reported 
    #   :title - title of a bookmark
    #   :link - link to the bookmark
    #   :rating - avg rating of a bookmark  (nil if no ratings)
    #   :views - total view count of a bookmark

    def Bookmarks.getUnresolvedReports
        query = "SELECT 
                ID,
                title,
                rating,
                views
                FROM bookmark_list JOIN(
                    SELECT DISTINCT bookmark_ID
                    FROM report
                    WHERE report_resolved = 0
                ) ON ID = bookmark_ID;"
        result = @@db.execute query
        result.each do |row|
            for i in 0..(row.length()/2)
                row.delete(i)        
            end
        end
        result.map{|row| row.transform_keys!(&:to_sym)}
                    
        return result
    end

    # Returns the number of unresolved reports for a bookmark
    def Bookmarks.getReportCount bookmarkID
        result = nil
        if Bookmarks.isInteger(bookmarkID)
            query = "SELECT
                    COUNT(bookmark_ID) AS count
                    FROM report
                    WHERE bookmark_ID = ? AND report_resolved = 0;"
            result = @@db.execute query, bookmarkID
            result = result[0]
            if result
                for i in 0..(result.length()/2)
                    result.delete(i)        
                end
                result.transform_keys!(&:to_sym)
            end
            
            return result[:count]
        end
        return result
    end

    # Returns the details of all the reports on a bookmark
    def Bookmarks.getReportDetails(bookmarkID)
        result = nil
        if Bookmarks.isInteger(bookmarkID)
            query = "SELECT 
                report_type AS type,
                report_details AS details,
                report_date AS date,
                user_email AS email,
                user_displayName AS displayName
                FROM report 
                JOIN users
                ON reporter_ID = user_ID
                WHERE bookmark_ID = ?;"
            result = @@db.execute query, bookmarkID
            result.each do |row|
            for i in 0..(row.length()/2)
                row.delete(i)        
                end
            end
            result.map{|row| row.transform_keys!(&:to_sym)}
                        
            return result
        end
        return result
    end 


    #Returns details of a reported bookmark
    #Params: id (integer) - an id of a specified bookmark
    #Returns: A hash with following keys (or nil if the input was incorrect):
    #   :title - title of a bookmark
    #   :link - link of a bookmark
    #   :report_type - a type of the report
    #   :details - details of the report
    def Bookmarks.getReportedBookmarkDetails id
        result = nil
        if Bookmarks.isInteger id
            query = "SELECT 
                    bookmark_title AS title,
                    bookmark_link AS link,
                    report_type AS report_type,
                    report_details AS details
                    FROM bookmark JOIN report USING(bookmark_ID)
                    WHERE bookmark_ID = ?;"
            result = @@db.execute query,id
            result.each do |row|
                for i in 0..(row.length()/2)
                    row.delete(i)        
                end
            end
            result.map{|row| row.transform_keys!(&:to_sym)}
        end

        return result
    end

    # Returns details of all users marked as suspended
    def Bookmarks.getSuspendedUsers
        query = "SELECT 
                user_ID AS ID,
                user_email AS email,
                user_displayName AS displayName,
                user_department AS department
                FROM users
                WHERE user_suspended = 1;"
        result = @@db.execute query
        result.each do |row|
            for i in 0..(row.length()/2)
                row.delete(i)        
            end
        end
        result.map{|row| row.transform_keys!(&:to_sym)}
    end

    # Returns userID of the bookmark creator
    # Params: bookmarkID - id of bookmark
    # Returns: userID of bookmark creator
    def Bookmarks.getBookmarkCreator bookmarkID
        if Bookmarks.isInteger(bookmarkID)
            query = "SELECT creator_ID AS userID
                    FROM bookmark
                    WHERE bookmark_id = ?;"
            result = @@db.execute query, bookmarkID
            result = result[0]
            for i in 0..(result.length()/2)
                result.delete(i)        
            end
            result.transform_keys!(&:to_sym)
            return result[:userID]
        end
        return nil
    end

    # Returns all IDs for all tags of bookmark
    def Bookmarks.getBookmarkTags bookmarkID
        if Bookmarks.isInteger(bookmarkID)
            query = "SELECT tag_ID 
                    FROM tag_bookmark_link
                    WHERE bookmark_ID = ?;"
            result = @@db.execute query, bookmarkID
            result.each do |row|
                for i in 0..(row.length()/2)
                    row.delete(i)        
                end
            end
            result.map{|row| row.transform_keys!(&:to_sym)}
            return result
        end
        return nil
    end


    # Calculate avergae rating for bookmark
    def Bookmarks.getAvgRating bookmarkID
        if Bookmarks.isInteger(bookmarkID)
            query = "SELECT AVG(rating_value)
                FROM rating
                WHERE bookmark_ID = ?;"
            result = @@db.get_first_value query, bookmarkID

            result = 0 if result.nil?;
            return result.round(2);
        end
        return nil
    end 

    # Return amount of ratings for bookmark
    def Bookmarks.getRatingCount bookmarkID
        if Bookmarks.isInteger(bookmarkID) then
            query = "SELECT counts
                FROM ratings_quantity
                WHERE bookmark_ID = ?;"
            result = @@db.execute query, bookmarkID
            result = result[0]
            for i in 0..(result.length()/2)
                result.delete(i)        
            end
            result.transform_keys!(&:to_sym)
            return result[:counts]
        end
        return nil
    end

    def Bookmarks.getComments bookmarkID 
        if Bookmarks.isInteger(bookmarkID) then
            query = "SELECT comment_ID AS ID,
                    commenter_ID AS commenter,
                    comment_details AS details,
                    date_created AS date,
                    date_deleted AS deleted,
                    user_displayName AS displayName
                    FROM comment JOIN users
                    ON commenter_ID = user_ID
                    WHERE bookmark_ID = ?;"
            result = @@db.execute query, bookmarkID 
            result.each do |row|
                for i in 0..(row.length()/2)
                    row.delete(i)        
                end
            end
            result.map{|row| row.transform_keys!(&:to_sym)}
            return result
        end
        return nil
    end

    #Returns table names in current database in an array
    def Bookmarks.getTableNames
        query = "SELECT 
                name
                FROM sqlite_master 
                WHERE type ='table' AND name NOT LIKE 'sqlite_%';"
        result = @@db.execute query
        
        (0..(result.length()-1)).each do |i|
            result[i]=result[i]["name"]
        end

        return result
    end

    #Returns column names given table in an array
    def Bookmarks.getColumnNames tableName
        if Bookmarks.getTableNames.include? tableName

            query = "PRAGMA table_info ('#{tableName}');"
            result = @@db.execute query

            (0..(result.length()-1)).each do |i|
                result[i]=result[i]["name"]
            end

            return result
        end
        return Array.new
    end 

    #Checks if value passed exists in a database
    #Params tableName - name of the table in which to look for uniqness
    #       columnName - name of the column in which to check uniqness
    #       value - value to be looked for
    #Returns: true - if value doesn't exist in a given column in given table
    #         false - if it does
    #         nil -if given column or table name are incorrect
    def Bookmarks.isUniqueValue tableName , columnName , value
        if (Bookmarks.getColumnNames tableName).include? columnName
            query = "SELECT DISTINCT #{columnName}
                     FROM #{tableName} ;"
            result = @@db.execute query
            
            (0..(result.length()-1)).each do |i|
                if result[i][columnName] == value
                    return false
                end
            end
            return true

        end
        return nil
    end 

    #checks if entry with given id exists in table (dont call for linking tables)
    def Bookmarks.resourceExists? entryID, tableName

        if (Bookmarks.isInteger entryID) && (Bookmarks.getTableNames.include? tableName)
            
            #find primary key of this table
            query = "PRAGMA table_info ('#{tableName}');"
            columns = @@db.execute query
            primaryKey = ""
            columns.each do |column|
                if column["pk"] != 0
                    if primaryKey == ""
                        primaryKey = column["name"]
                    else
                        # if found more then one primary key
                        return false
                    end
                    
                end
            end

            #check if primary key with value entryID exists
            query = "SELECT #{primaryKey}
                    FROM #{tableName}
                    WHERE #{primaryKey} = ?;"
            result = @@db.execute query, entryID

            if result && result.length() > 0
                return true
            end

        end

        #if something went wrong or didn't found key
        return false

    end

    # Returns true if the value is an integer
    def Bookmarks.isInteger value
        result = Integer(value) rescue false
        return (result && true) #couldn't find to_bool function so this is a workaround
    end 
    

    # Checks if value is outside of range of ID's in table
    # Params id - value to being checked
    # columnName - column where ID's are stored
    # tableName - table of ID being checked
    # Returns true - if 'id' is outside of the range
    #         false - if 'id' is within the range

    def Bookmarks.idOutOfRange id, columnName, tableName
        query = "SELECT DISTINCT #{columnName}
                     FROM #{tableName} ;"
        result = @@db.execute query

        largest = 0
        (0..(result.length()-1)).each do |i|
            if result[i][0] > largest then
                largest = result[i][0]
            end
        end

        if id > largest || id < -1 then
            return true
        else
            return false
        end
    end

    # === Insert Methods ========

    # Insert user's details into db when they register an account
    def Bookmarks.addRegisterDetails (uEmail, uDisplay, uDepartment, password)
        if !Bookmarks.isUniqueValue('users','user_email',uEmail) then
            return false
         
        elsif uEmail.nil? then
            return false         
        else
            query = "INSERT INTO users(user_email, user_displayName, user_department,
                    user_password, user_type, user_suspended)
                    VALUES (?, ?, ?, ?, ?, ?);"
            @@db.execute query, uEmail, uDisplay, uDepartment, BCrypt::Password.create(password), UNVERIFIED_STRING, 0
            return true
        end 
    end
    
    # Insert admin user's details when registering account
    def Bookmarks.addAdminUser(uEmail, uDisplay, uDepartment, password)
        if !Bookmarks.isUniqueValue('users','user_email',uEmail) then
            return false
         
        elsif uEmail.nil? then
            return false         
        else
            query = "INSERT INTO users(user_email, user_displayName, user_department,
                                    user_password, user_type, user_suspended)
                    VALUES (?, ?, ?, ?, ?,?);"
            @@db.execute query, uEmail, uDisplay, uDepartment, BCrypt::Password.create(password), ADMIN_STRING, 0
            return true
        end
    end 
    
    # Add bookmark details to the db
    def Bookmarks.addBookmark (bookmarkTitle, bookmarkDesc, bookmarkLink, bookmarkCreationDate, creatorID)
        if bookmarkTitle.nil? || creatorID.nil? then
            return false
        elsif Bookmarks.idOutOfRange(creatorID.to_i,'user_ID','users') then
            return false
        else
            query = "INSERT INTO bookmark(bookmark_title, bookmark_description, bookmark_link, date_created,
                                        creator_ID)
                    VALUES (?, ?, ?, ?, ?);"
            @@db.execute query, bookmarkTitle, bookmarkDesc, bookmarkLink, bookmarkCreationDate, creatorID.to_i
            return @@db.last_insert_row_id
        end
    end
    
    # Adding details of edit made to bookmark
    def Bookmarks.addBookmarkEdit(editor, bookmark, editDate)
        if !Bookmarks.isInteger(editor) || !Bookmarks.isInteger(bookmark) then
            return false 
        elsif editor.nil? || bookmark.nil? then
            return false
        elsif Bookmarks.idOutOfRange(editor.to_i,'user_ID','users') || Bookmarks.idOutOfRange(bookmark.to_i,'bookmark_ID','bookmark') then
            return false
        else
            query = "INSERT INTO edit(editor_ID, bookmark_edited_ID, edit_date)
                    VALUES(?,?,?);"
            @@db.execute query, editor.to_i, bookmark.to_i, editDate
            return true
        end
    end
    
    # Add comment details to db
    def Bookmarks.addComment(bookmark, commenter, details, dateCreated)
        if !Bookmarks.isInteger(bookmark) || !Bookmarks.isInteger(commenter) then
            return false
        elsif bookmark.nil? || commenter.nil? then
            return false
        elsif Bookmarks.idOutOfRange(bookmark.to_i,'bookmark_ID','bookmark') || Bookmarks.idOutOfRange(commenter.to_i,'user_ID','users') then
            return false
        else
            query = "INSERT INTO comment(bookmark_ID, commenter_ID, comment_details, date_created)
                    VALUES(?,?,?,?);"
            @@db.execute query, bookmark.to_i, commenter.to_i, details, dateCreated
            return true
        end
    end
    
    # Add details of favourite into db
    def Bookmarks.addFavourite(user,bookmark)
        if !Bookmarks.isInteger(user) || !Bookmarks.isInteger(bookmark) then
            return false
        elsif user.nil? || bookmark.nil? then
            return false
        elsif Bookmarks.idOutOfRange(user.to_i,'user_ID','users') || Bookmarks.idOutOfRange(bookmark.to_i,'bookmark_ID','bookmark') then
            return false
        else
            query = "INSERT INTO favourite(user_ID,bookmark_ID)
                    VALUES(?,?);"
            @@db.execute query, user.to_i, bookmark.to_i
            return true
        end
    end
    
    # Adds details of a rating to the db
    def Bookmarks.addRating(bookmark, rater, value, dateCreated)
        if !Bookmarks.isInteger(bookmark) || !Bookmarks.isInteger(rater) || !Bookmarks.isInteger(value) then
            return false
        elsif bookmark.nil? || rater.nil? || value.nil? then
            return false
        elsif  Bookmarks.idOutOfRange(bookmark.to_i,'bookmark_ID','bookmark') || Bookmarks.idOutOfRange(rater.to_i,'user_ID','users') then
            return false
        elsif value < 1 || value > 5 then
            return false
        else
            query = "INSERT INTO rating(bookmark_ID, rater_ID, rating_value, rating_created)
                    VALUES(?,?,?,?);"
            @@db.execute query, bookmark.to_i, rater.to_i, value, dateCreated
            return true
        end
    end
    
    # Add details of a report to the db
    def Bookmarks.addReport (reportedPageID, reportType, reportDetails, reporterID, reportDate)
        if !Bookmarks.isInteger(reportedPageID) or !Bookmarks.isInteger(reporterID) then
            return false
        elsif reportedPageID.nil? then
            return false
        elsif Bookmarks.idOutOfRange(reportedPageID.to_i,'bookmark_ID','bookmark') || Bookmarks.idOutOfRange(reporterID.to_i,'user_id','users') then
            return false
        else
            query = "INSERT INTO report(bookmark_ID, report_type, report_details, 
                                        reporter_ID, report_date,report_resolved)
                    VALUES (?, ?, ?, ?, ?, ?);"
            @@db.execute query, reportedPageID.to_i, reportType, reportDetails, reporterID.to_i, reportDate, 0
            return true
        end
    end
    
    # Adds tag to db
    def Bookmarks.addTag(name, colour, dateCreated)
        if !name.nil? then
            query = "INSERT INTO tag(tag_name, tag_colour, tag_date_created)
                    VALUES(?,?,?);"
            @@db.execute query, name, colour, dateCreated
            return true
        else
            return false
        end
    end
    
    # Add tag and bookmark ID's to the linking table
    def Bookmarks.addTagBookmarkLink(tag, bookmark)
        if !Bookmarks.isInteger(tag) or !Bookmarks.isInteger(bookmark) then
            return false
        elsif tag.nil? or bookmark.nil? then
            return false
        elsif Bookmarks.idOutOfRange(bookmark.to_i,'bookmark_ID','bookmark') || Bookmarks.idOutOfRange(tag.to_i,'tag_ID','tag') then
            return false
        else 
            query = "INSERT INTO tag_bookmark_link(tag_ID,bookmark_ID)
                    VALUES(?,?);"
            @@db.execute query, tag.to_i, bookmark.to_i
            return true
        end 
    end
    
    # Add details of a view into the db
    def Bookmarks.addView(viewer, bookmark, dateViewed)
        if !Bookmarks.isInteger(viewer) || !Bookmarks.isInteger(bookmark) then
            return false
        elsif viewer.nil? || bookmark.nil? then
            return false
        elsif Bookmarks.idOutOfRange(viewer.to_i,'user_id','users') || Bookmarks.idOutOfRange(bookmark.to_i,'bookmark_id','bookmark') then
            return false
        else
            query = "INSERT INTO views(viewer_ID, bookmark_viewed_ID, view_date)
                    VALUES(?,?,?);"
            @@db.execute query, viewer.to_i, bookmark.to_i, dateViewed  
            return true
        end
    end 

    # ========= Deletion ==============

    #Removes connection between given tag and bookmark form database
    def Bookmarks.deleteTagBookmarkLink tagId, bookmarkId
        if Bookmarks.isInteger(tagId) && Bookmarks.isInteger(bookmarkId)
            query = "DELETE FROM tag_bookmark_link
                    WHERE tag_ID = ? AND bookmark_ID = ?;"
            @@db.execute query, tagId, bookmarkId
            return true
        end
        return false
    end

    def Bookmarks.deleteAllTagBookmarkLinks bookmarkId
        if Bookmarks.isInteger(bookmarkId)
            query = "DELETE FROM tag_bookmark_link
                    WHERE bookmark_ID = ?;"
            @@db.execute query, bookmarkId
            return true
        end
        return false
    end

    # Removes all view records for bookmark
    def Bookmarks.deleteAllBookmarkViews bookmarkID
        if Bookmarks.isInteger bookmarkID then
            query = "DELETE FROM views
                    WHERE bookmark_viewed_ID = ?;"
            @@db.execute query, bookmarkID
            return true
        end
        return false
    end

    # Removes all report records for bookmark
    def Bookmarks.deleteAllBookmarkReports bookmarkID
        if Bookmarks.isInteger bookmarkID then
            query = "DELETE FROM report
                    WHERE bookmark_ID = ?;"
            @@db.execute query, bookmarkID
            return true
        end
        return false
    end

    # Removes all comments records for bookmark
    def Bookmarks.deleteAllBookmarkComments bookmarkID
        if Bookmarks.isInteger bookmarkID then
            query = "DELETE FROM comment
                    WHERE bookmark_ID = ?;"
            @@db.execute query, bookmarkID
            return true
        end
        return false
    end

    # Removes all edits records for bookmark
    def Bookmarks.deleteAllBookmarkEdits bookmarkID
        if Bookmarks.isInteger bookmarkID then
            query = "DELETE FROM edit
                    WHERE bookmark_edited_ID = ?;"
            @@db.execute query, bookmarkID
            return true
        end
        return false
    end

    # Removes all rating records for bookmark
    def Bookmarks.deleteAllBookmarkRatings bookmarkID
        if Bookmarks.isInteger bookmarkID then
            query = "DELETE FROM rating
                    WHERE bookmark_ID = ?;"
            @@db.execute query, bookmarkID
            return true
        end
        return false
    end

    #Removes bookmark from user favourites
    def Bookmarks.deleteFavourite(user,bookmark)
        if (Bookmarks.isInteger bookmark) && (Bookmarks.isInteger user) then
            query = "DELETE FROM favourite
                    WHERE bookmark_ID = ? AND user_ID = ?;"
            @@db.execute query, bookmark, user
            return true
        end
        return false
    end

    # Removes all favourite records for bookmark
    def Bookmarks.deleteAllBookmarkFavourite bookmarkID
        if Bookmarks.isInteger bookmarkID then
            query = "DELETE FROM favourite
                    WHERE bookmark_ID = ?;"
            @@db.execute query, bookmarkID
            return true
        end
        return false
    end

    def Bookmarks.deleteBookmark bookmarkID
        if Bookmarks.isInteger bookmarkID then
            query = "DELETE FROM bookmark
                    WHERE bookmark_ID = ?;"
                    
            Bookmarks.deleteAllBookmarkViews(bookmarkID)
            Bookmarks.deleteAllBookmarkReports(bookmarkID) 
            Bookmarks.deleteAllBookmarkComments(bookmarkID) 
            Bookmarks.deleteAllBookmarkRatings(bookmarkID) 
            Bookmarks.deleteAllBookmarkEdits(bookmarkID) 
            Bookmarks.deleteAllBookmarkFavourite(bookmarkID)
            Bookmarks.deleteAllTagBookmarkLinks(bookmarkID)
            
            @@db.execute query, bookmarkID
            return true

        end
        return false
    end

    # Mark comment as deleted
    def Bookmarks.deleteComment commentID, date
        if Bookmarks.isInteger commentID then
            query = "UPDATE comment
                    SET date_deleted = ?
                    WHERE comment_ID = ?;"
            @@db.execute query, date, commentID
            return true
        end
        return false
    end

    # Delete user record
    def Bookmarks.deleteUser userID
        if Bookmarks.isInteger userID then
            query = "DELETE FROM users
                    WHERE user_ID = ?;"
            @@db.execute query, userID
            return true
        end
        return false
    end

    # =========== Update Statements =================
    # Change value for user's rating of bookmark 
    def Bookmarks.changeRating bookmarkID, userID, newValue, newDate
        if Bookmarks.isInteger(bookmarkID) &&  Bookmarks.isInteger(userID) then
            query = "UPDATE rating
                SET rating_value = ?,
                rating_created = ?
                WHERE bookmark_ID = ? AND rater_ID = ?;"
            @@db.execute query, newValue, newDate, bookmarkID, userID
            return true
        end
        return false
    end 

    def Bookmarks.verifyUser userID
        if Bookmarks.isInteger(userID) then
            query = "UPDATE users
            SET user_type = ?
            WHERE user_ID = ?;"
            @@db.execute query, USER_STRING, userID
            return true
        end
        return false
    end

    #Change bookmark details
    def Bookmarks.updateBookmark (bookmarkID, bookmarkTitle, bookmarkDesc, bookmarkLink)
        if bookmarkTitle.nil? || bookmarkLink.nil? then
            return false
        else
            query = "UPDATE bookmark 
                    SET bookmark_title = ?, bookmark_description = ?, bookmark_link = ?
                    WHERE bookmark_ID = ?;"
            @@db.execute query, bookmarkTitle, bookmarkDesc, bookmarkLink, bookmarkID
            return true
        end
    end

    # Mark all reports for a bookmark as a resolved
    def Bookmarks.resolveReports(bookmarkID)
        if Bookmarks.isInteger(bookmarkID)
            query = "UPDATE report
                SET report_resolved = 1
                WHERE bookmark_ID = ?;"
            @@db.execute query, bookmarkID
            return true
        end
        return false
    end

    # Suspend user account (set user_suspended to 1)
    def Bookmarks.suspendUser userID
        if Bookmarks.isInteger(userID)
            query = "UPDATE users
                SET user_suspended = 1
                WHERE user_ID = ?"
            @@db.execute query, userID
            return true
        end 
        return false
    end


     # Revoke suspension for user
     def Bookmarks.unsuspendUser userID
        if Bookmarks.isInteger(userID)
            query = "UPDATE users
                SET user_suspended = 0
                WHERE user_ID = ?"
            @@db.execute query, userID
            return true
        end 
        return false
    end

    # Change user_type to 'Admin'
    def Bookmarks.promoteToAdmin userID
        if Bookmarks.isInteger(userID)
            query = "UPDATE users
                SET user_type = ?
                WHERE user_ID = ?;"
            @@db.execute query, ADMIN_STRING, userID
            return true
        end 
        return false
    end

    # Changes users password - stored as hash in dataabse
    def Bookmarks.resetPassword userID, password
        if Bookmarks.isInteger(userID)
            query = "UPDATE users
                SET user_password = ?
                WHERE user_ID = ?;"
            @@db.execute query, BCrypt::Password.create(password), userID
            return true
        end
        return false
    end     
end

