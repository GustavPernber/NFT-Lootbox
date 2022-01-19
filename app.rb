require 'sinatra'
require 'slim'
require 'sqlite3'
require 'base64'
require 'bcrypt'


enable :sessions

get('/') do
    db=SQLite3::Database.new('db/nft-lootbox.db')
    db.results_as_hash=true
    lootboxes=db.execute("SELECT * FROM Lootbox")
    
    
    slim(:'lootbox/index', locals:{lootboxes:lootboxes})
end

get('/lol')do
    db=SQLite3::Database.new('db/nft-lootbox.db')
    db.results_as_hash=true
    result=db.execute("SELECT * FROM Lootbox WHERE id=10").first
    imgBlob=result["img1"]
    # send_file ''
    # "<img src=#{imgBlob}>"
    # srcString="data:image/png;base64, #{imgBlob}"
    # blobString="lol"
    srcString="'data:image/png;base64,#{imgBlob}'"
    
    

    "<img src=#{srcString}>"
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
    slim(:'lootbox/new')
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
    begin
        pwdigest=result["pwdigest"]
        id=result["id"]
    
        if BCrypt::Password.new(pwdigest)==password
            session[:loginError]=false
            session[:id]=id
            session[:auth]=true

            session[:balance]=result["balance"]
            session[:colour]=result["colour"]
            session[:username]=result["username"]

            db.results_as_hash=false
            boughtResult=db.execute("SELECT lootbox_id FROM lootbox_ownership WHERE user_id=? ", session[:id])

            boughtBoxes = boughtResult.map do |id|
                id=id.first
            end 
            session[:boughtBoxes]=boughtBoxes

            redirect('/')
            
        else
            session[:loginError]=true
            redirect('/login')
        end
        
    rescue => exception
        p exception
        session[:loginError]=true
        redirect('/login')

    end

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

            db.results_as_hash=false
            boughtResult=db.execute("SELECT lootbox_id FROM lootbox_ownership WHERE user_id=? ", session[:id])
            boughtBoxes = boughtResult.map do |id|
                id=id.first
            end 
            session[:boghtBoxes]=boughtBoxes


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

post('/lootbox/create') do
    title=params[:title]
    rarity=params[:rarity]
    price=params[:price]

    images=[]

    i=1
    while i<4
        imgString="img#{i}"
        if params.key?(imgString)
            images << params[imgString][:tempfile]
        end
        i+=1
    end
    
    db=SQLite3::Database.new('db/nft-lootbox.db')
    creator_id=session[:id]

    if images.length==1
        enc1= Base64.encode64(images[0].read)  
        
        db.execute("INSERT INTO Lootbox (img1, rarity, title, price, creator_id) VALUES(?, ?, ?, ?, ?)", enc1, rarity, title, price, creator_id)
    elsif images.length==2
        enc1= Base64.encode64(images[0].read)  
        enc2= Base64.encode64(images[1].read)  
        

        
        db.execute("INSERT INTO Lootbox (img1, img2, rarity, title, price, creator_id) VALUES(?, ?, ?, ?, ?, ?)", enc1, enc2, rarity, title, price, creator_id)
    elsif images.length==3
        enc1= Base64.encode64(images[0].read)  
        enc2= Base64.encode64(images[1].read)  
        enc3= Base64.encode64(images[2].read)  
        
        db.execute("INSERT INTO Lootbox (img1, img2, img3, rarity, title, price, creator_id) VALUES(?, ?,?,?, ?, ?, ?)", enc1, enc2, enc3, rarity, title, price, creator_id)
    end

    redirect('/lootbox/new')
end
