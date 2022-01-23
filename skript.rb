require 'sqlite3'
db=SQLite3::Database.new('db/nft-lootbox.db')
p db.execute('SELECT SCOPE_IDENTITY')
# db=SQLite3::Database.new('db/nft-lootbox.db')

# emojiString="😁 😈 👹 👺 🤡 💩  💀 😘 🤒 😻  🥴 🤮  🤓 😎 😡 😒 😞 😉 😌 🎅🏻 👨🏻‍🦽 🈵 🤑 
#  "



# arr=emojiString.chomp.split()


# for emoji in arr do
#     db.execute("INSERT INTO properties (name) VALUES (?)", emoji)
# end
# # db.execute("IN")

