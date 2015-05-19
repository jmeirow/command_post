require File.expand_path(File.dirname(__FILE__) + '/../lib/command_post')
require 'minitest/autorun'
require 'minitest/spec'

CommandPost::Connection.connection_string = ENV['CONNECTION_STRING']

db = CommandPost::Connection.db_cqrs
db['delete from aggregates'].delete
db['delete from aggregate_events'].delete
db['delete from aggregate_index_decimals'].delete
db['delete from aggregate_index_integers'].delete
db['delete from aggregate_index_strings'].delete




