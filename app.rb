require 'sinatra'
require 'slim'
require 'sqlite3'

get ('/') do
    slim(:'lootbox/index')
end

get ('/lootbox/new') do
    slim(:'lootbox/new')
end

post ('/lootbox/create') do
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
       read1=images[0].read
       blob1=SQLite3::Blob.new read1
       queryString= "INSERT INTO Lootbox (img1) VALUES(?)"

       db.execute(queryString, blob1)
    elsif images.length==2
        read1=images[0].read
        blob1=SQLite3::Blob.new read1
        read2=images[1].read
        blob2=SQLite3::Blob.new read2
        queryString= "INSERT INTO Lootbox (img1, img2) VALUES(?, ?)"

        db.execute(queryString, blob1, blob2, blob3)
    elsif images.length==3
        read1=images[0].read
        blob1=SQLite3::Blob.new read1
        read2=images[1].read
        blob2=SQLite3::Blob.new read2
        read3=images[2].read
        blob2=SQLite3::Blob.new read3
        queryString= "INSERT INTO Lootbox (img1, img2, img3) VALUES(?, ?, ?)"
        db.execute(queryString, blob1, blob2, blob3)
      
    end

    redirect('/lootbox/new')
end