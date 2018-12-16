require 'dotenv'
require 'sinatra'
require 'messagebird'

require 'semantic_logger'
require_relative 'message_bird_transport'

set :root, File.dirname(__FILE__)

#  Load configuration from .env file
Dotenv.load if Sinatra::Base.development?

SemanticLogger.add_appender(io: STDOUT, level: :debug)
SemanticLogger.add_appender(file_name: 'app.log', level: :info)
appender = SemanticLogger::Appender::MessageBirdTransport.new(level: :error, key: ENV['MESSAGEBIRD_API_KEY'], originator: ENV['MESSAGEBIRD_ORIGINATOR'], recipients: ENV['MESSAGEBIRD_RECIPIENTS'].split(','))
SemanticLogger.add_appender(appender: appender)

logger = SemanticLogger['TestApp']

# Make some test log entries
logger.debug("This is a test at debug level.")
logger.info("This is a test at info level.")
logger.warn("This is a test at warning level.")
logger.error("This is a test at error level.")

get '/' do
  'Hello world!'
end

get '/simulateError' do
  logger.error('This should trigger error handling!')
  halt 500
end
