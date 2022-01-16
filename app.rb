require 'sinatra'
require 'slim'
require 'sqlite3'

get ('/') do
    slim(:'lootbox/index')
end

get ('/lootbox/new') do
    slim(:'lootbox/create')
end