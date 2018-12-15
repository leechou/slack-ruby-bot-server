# This code is taken from the lib directory of SlackRubyBotServer 0.8.2
# with modifications to the concurrency library (celluloid instead of async/websocket)
# and changes in the activerecord team tablename 

# require 'async/websocket'
require 'celluloid/current'

#require 'grape-swagger'
require 'slack-ruby-bot'
require 'slack-ruby-bot-server/server'
require 'slack-ruby-bot-server/ping'
require 'slack-ruby-bot-server/config'

require 'slack-ruby-bot-server/ext'
require 'slack-ruby-bot-server/version'
require 'slack-ruby-bot-server/info'

require "slack-ruby-bot-server/config/database_adapters/#{SlackRubyBotServer::Config.database_adapter}.rb"

#require 'slack-ruby-bot-server/api'
require 'slack-ruby-bot-server/app'
require 'slack-ruby-bot-server/service'
