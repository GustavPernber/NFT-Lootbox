require 'sqlite3'
# db=SQLite3::Database.new('db/nft-lootbox.db')
# p db.execute('SELECT id FROM lootbox ORDER BY id DESC').first.first
db=SQLite3::Database.new('db/nft-lootbox.db')

emojiString="😁 😈 👹 👺 🤡 💩  💀 😘 🤒 😻  🥴 🤮  🤓 😎 😡 😒 😞 😉 😌 🎅🏻 👨🏻‍🦽 🈵 🤑 
 "



arr=emojiString.chomp.split()


for emoji in arr do
    db.execute("INSERT INTO properties (name) VALUES (?)", emoji)
end
# db.execute("IN")

