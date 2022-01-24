require 'sinatra'
require 'slim'
require 'sqlite3'
require 'base64'
require 'bcrypt'


enable :sessions

#Define all errors

#Define all sessions
def loginSessions(username) 
    db=SQLite3::Database.new('db/nft-lootbox.db')
    db.results_as_hash=true
    # session[:loginError]=false
    result=db.execute('SELECT * FROM users WHERE username = ?', username).first
    # begin
        pwdigest=result["pwdigest"]
        id=result["id"]


    session[:id]=id
    session[:auth]=true

    session[:balance]=result["balance"]
    session[:colour]=result["colour"]
    session[:username]=result["username"]
    session[:createError]={
        status:false,
        message:""
    }

    db.results_as_hash=false
    boughtResult=db.execute("SELECT lootbox_id FROM lootbox_ownership WHERE user_id=? ", session[:id])

    if boughtResult!=nil
        boughtBoxes = boughtResult.map do |id|
            id=id.first
        end 
    end
    session[:boughtBoxes]=boughtBoxes
    if session[:boughtBoxes]==nil
        session[:boughtBoxes]=[0]
    end

end

get('/') do
    db=SQLite3::Database.new('db/nft-lootbox.db')
    db.results_as_hash=true
    lootboxes=db.execute("SELECT * FROM Lootbox")

    slim(:'lootbox/index', locals:{lootboxes:lootboxes})
end

get('/login')do
    slim(:login)
end

get('/logout')do
    session.destroy
    session[:auth]=false
    redirect('/')
end

get('/lootbox/new') do
    if session[:auth]
        
        db=SQLite3::Database.new('db/nft-lootbox.db')
        db.results_as_hash=true
        props=db.execute('SELECT * FROM properties')
        
        slim(:'lootbox/new', locals:{props:props})
    else
        "401"
    end
end

get('/register')do
    slim(:register)
end

get('/lootbox/edit/:id')do
    lootbox_id=params[:id]
    db=SQLite3::Database.new('db/nft-lootbox.db')
    db.results_as_hash=true

    lootbox=db.execute('SELECT * FROM lootbox WHERE id=?', lootbox_id).first
    



    if lootbox["creator_id"]==session[:id] #creator id samma som session id, 

        imgSources=[]
        
        i=0
        while i<4
            if lootbox["img#{i+1}"]!=nil
                
                imgBlob=lootbox["img#{i+1}"]
                imgSources<<"data:image/png;base64,#{imgBlob}"
            
            end
            i+=1
        end

        db.results_as_hash=false
        creator=db.execute("SELECT username FROM Users WHERE id=?", lootbox["creator_id"]).first.first

       slim(:'lootbox/edit', locals:{lootbox:lootbox, images:imgSources, creator:creator})
    else
        "401 Not auth"
    end
end

get('/lootbox/show/:id') do
    lootbox_id=params[:id].to_i
    db=SQLite3::Database.new('db/nft-lootbox.db')
    db.results_as_hash=true
    lootbox=db.execute("SELECT * FROM Lootbox WHERE id=?", lootbox_id).first
    
    if session[:boughtBoxes].include?(lootbox_id)==false && lootbox["creator_id"]!=session[:id] && session[:balance]>=lootbox   ["price"] #inte äger den och tillräckligt med para
        

        i=0
        imgSources=[]
        
        while i<4
            if lootbox["img#{i+1}"]!=nil
                
                imgBlob=lootbox["img#{i+1}"]
                imgSources<<"data:image/png;base64,#{imgBlob}"
            
        end
        i+=1
        end 

        
        #Dra av pengar
        
        new_balance=session[:balance]-lootbox["price"]
        db.execute("UPDATE users SET balance=? WHERE id=?", new_balance, session[:id])
        
        session[:balance]=new_balance
        
        
        
        
        #Lägg till i köpta lådor
        
        db.execute("INSERT INTO lootbox_ownership (lootbox_id, user_id) VALUES (?,?)", lootbox["id"], session[:id])
        
        
        db.results_as_hash=false
        boughtResult=db.execute("SELECT lootbox_id FROM lootbox_ownership WHERE user_id=? ", session[:id])
        
        boughtBoxes = boughtResult.map do |id|
            id=id.first
        end 
        
        creator=db.execute("SELECT username FROM Users WHERE id=?", lootbox["creator_id"]).first.first
        
        
        slim(:'lootbox/show', locals:{images:imgSources, lootbox:lootbox, creator:creator, boughtBoxes:boughtBoxes})
        
        
    elsif session[:boughtBoxes].include?(lootbox_id)
        
        db.results_as_hash=false
        creator=db.execute("SELECT username FROM Users WHERE id=?", lootbox["creator_id"]).first.first
        i=0
        imgSources=[]
        
        while i<4
            if lootbox["img#{i+1}"]!=nil
                
                imgBlob=lootbox["img#{i+1}"]
                imgSources<<"data:image/png;base64,#{imgBlob}"
            
        end
        i+=1
        end 

        slim(:'lootbox/show', locals:{images:imgSources, lootbox:lootbox, creator:creator})

    else #not auth
        "#{session[:boughtBoxes].include?(lootbox_id)}"
        "#{lootbox["creator_id"]!=session[:id]}"
        "401 Error!"
    end
    
end


get('/user/show/:id')do
    id=params[:id].to_i

    if session[:id]==id
        db=SQLite3::Database.new('db/nft-lootbox.db')
        db.results_as_hash=true
        own_lootboxes=db.execute('SELECT * FROM lootbox WHERE creator_id=?', session[:id])
        boughtBoxes=db.execute('SELECT * FROM lootbox WHERE id IN (SELECT lootbox_id FROM lootbox_ownership WHERE user_id=?)', id)
        
        slim(:'user/show', locals:{own_lootboxes:own_lootboxes, boughtBoxes:boughtBoxes})
        
        
        else
            p session[:id]
            p id
            "401 not auth. session id: #{session[:id]}."  
        end

    
end


#POSTS

post('/lootbox/create') do
    
    if session[:auth]
        
        title=params[:title]
        rarity=params[:rarity]
        price=params[:price]
    
        db=SQLite3::Database.new('db/nft-lootbox.db')
    
        images=[]
        i=1
        while i<4
            imgString="img#{i}"
            if params.key?(imgString)
                images << params[imgString][:tempfile]
            end
            i+=1
        end
        
        creator_id=session[:id]
        
        #Om det finns images. Loopa igenom och lägg in dom i base64 format. Annars skicka session error.
        if images.length !=0

            begin
                
                db.execute("INSERT INTO lootbox (rarity, title, price, creator_id) VALUES (?,?,?,?)", rarity, title, price, creator_id)
                
                images.each_with_index do |image, i|
                    encImg=Base64.encode64(image.read)
                    db.execute("UPDATE lootbox SET img#{i+1}=? WHERE title=?", encImg, title)
                end 
        
                #PROPERTIES
                db.results_as_hash=false
                
                #Hämta id för lootboxen för att sätta in i relationstabell
                boxId=db.execute('SELECT id FROM lootbox WHERE title=?', title).first
                propsLength=db.execute("SELECT COUNT(*) FROM properties").first.first
                i=0
                while i<=propsLength
            
                    propId=params["#{i}"]
                    if propId!=nil
                        
                        #Sätt in propId i relationstabell med lootbox id
                        db.execute("INSERT INTO lootbox_props (lootbox_id, prop_id) VALUES (?,?)", boxId, propId.to_i   )
                    end
                    i+=1
                    
                end
            rescue => exception
                session[:createError]={
                    status:true,
                    message:"Name of lootbox already taken!"
                }
                redirect('/lootbox/new')
            end
    
        else
            session[:createError]={
                status:true,
                message:"No valid images submited!"
            }
            redirect('/lootbox/new')
        end
    
        redirect('/')
    else
        "401"
    end
end

post('/lootbox/:id/delete')do
    id=params[:id]
    
    db=SQLite3::Database.new('db/nft-lootbox.db')
    db.results_as_hash=true

    db.execute('DELETE FROM lootbox WHERE id=?', id)
    db.execute('DELETE FROM lootbox_ownership WHERE lootbox_id=?', id)

    redirect("/user/show/#{session[:id]}")

end

post('/lootbox/:id/update')do
    id=params[:id]
    rarity=params[:rarity]
    title=params[:title]
    price=params[:price]

    db=SQLite3::Database.new('db/nft-lootbox.db')
    db.results_as_hash=true

    db.execute("UPDATE lootbox SET rarity=?, title=?, price=? WHERE id=?", rarity, title, price, id)
    redirect("/user/show/#{session[:id]}")
end

post('/login')do
    username=params[:username]
    password=params[:password]
    db=SQLite3::Database.new('db/nft-lootbox.db')
    db.results_as_hash=true
    result=db.execute('SELECT * FROM users WHERE username = ?', username).first
    # begin
        pwdigest=result["pwdigest"]
        id=result["id"]
    
        if BCrypt::Password.new(pwdigest)==password
            # session[:loginError]=false
            # session[:id]=id
            # session[:auth]=true

            # session[:balance]=result["balance"]
            # session[:colour]=result["colour"]
            # session[:username]=result["username"]
            # session[:createError]={
            #     status:false,
            #     message:""
            # }

            # db.results_as_hash=false
            # boughtResult=db.execute("SELECT lootbox_id FROM lootbox_ownership WHERE user_id=? ", session[:id])

            # if boughtResult!=nil
            #     boughtBoxes = boughtResult.map do |id|
            #         id=id.first
            #     end 
            # end
            # session[:boughtBoxes]=boughtBoxes
            # if session[:boughtBoxes]==nil
            #     session[:boughtBoxes]=[0]
            # end
            loginSessions(username)

            redirect('/')
            
        else
            session[:loginError]=true
            redirect('/login')
        end
        
    # rescue => exception
    #     p exception
    #     session[:loginError]=true
    #     redirect('/login')
        
    # end

end

post('/register')do
    username=params[:username]
    password=params[:password]
    password_confirm=params[:password_confirm]
    colour = "%06x" % (rand * 0xffffff)
    balance=100
       
    if password==password_confirm || username=="" || password==""
        begin
            password_digest=BCrypt::Password.create(password)
            db=SQLite3::Database.new('db/nft-lootbox.db')
            db.execute('INSERT INTO users (username, pwdigest, colour, balance) VALUES(?, ?, ?, ?)', username, password_digest, colour, balance)
            # db.results_as_hash=true
            id=db.execute("SELECT id FROM users WHERE username=?", username).first.first
            
            session[:error]=false
            session[:auth]=true
            session[:id]=id

            session[:balance]=balance
            session[:colour]=colour
            session[:username]=username

            
            session[:boughtBoxes]=[0]


            redirect('/')
            
        rescue => exception
            p exception
            session[:registerError]=true
            redirect('/register')
        end
    else
        session[:registerError]=true
        redirect('/register')
    end
    
end

