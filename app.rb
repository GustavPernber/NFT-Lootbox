require 'sinatra'
require 'slim'
require 'sqlite3'
require 'base64'
require 'bcrypt'


enable :sessions

get('/') do
    db=SQLite3::Database.new('db/nft-lootbox.db')
    db.results_as_hash=true
    result=db.execute("SELECT * FROM Lootbox")
    
    slim(:'lootbox/index', locals:{lootboxes:result})
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
    session
end

get('/lootbox/new') do
    slim(:'lootbox/new')
end

get('/register')do
    slim(:register)
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
            session[:firstLetter]=username.split('')[0]
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
       
    if password==password_confirm || username=="" || password==""
        begin
            password_digest=BCrypt::Password.create(password)
            db=SQLite3::Database.new('db/nft-lootbox.db')
            db.execute('INSERT INTO users (username, pwdigest) VALUES(?, ?)', username, password_digest )
            id=db.execute("SELECT id FROM users WHERE username=?", username).first
            session[:error]=false
            session[:auth]=true
            session[:id]=id
            session[:firstLetter]=username.split('')[0]
            redirect('/')
            
        rescue => exception
            p exception
            session[:registerError]=true
            redirect('/register')
        end
    else
        p 'dont match'
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
   
    
    if images.length==1
       

        # png=File.open "public/img.png", 'rb'

        enc1= Base64.encode64(images[0].read)  

    #    read1=images[0].read
    #    blob1=SQLite3::Blob.new read1
    #    p blob1
       db.execute("INSERT INTO Lootbox (img1, rarity, title, price) VALUES(?, ?, ?, ?)", enc1, rarity, title, price)
    elsif images.length==2
        read1=images[0].read
        blob1=SQLite3::Blob.new read1
        read2=images[1].read
        blob2=SQLite3::Blob.new read2
        

        
        db.execute("INSERT INTO Lootbox (img1, img2, rarity, title, price) VALUES(?, ?, ?, ?, ?)", blob1, blob2, rarity, title, price)
    elsif images.length==3
        read1=images[0].read
        blob1=SQLite3::Blob.new read1
        read2=images[1].read
        blob2=SQLite3::Blob.new read2
        read3=images[2].read
        blob2=SQLite3::Blob.new read3
        
        db.execute("INSERT INTO Lootbox (img1, img2, img3, rarity, title, price) VALUES(?,?,?, ?, ?, ?)", blob1, blob2, blob3, rarity, title, price)
      
    end

    redirect('/lootbox/new')
end
