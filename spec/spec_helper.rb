require File.expand_path(File.dirname(__FILE__) + '/../lib/command_post/db/connection')
CommandPost::Connection.connection_string = ENV['CONNECTION_STRING']

require File.expand_path(File.dirname(__FILE__) + '/../lib/command_post')
require 'minitest/autorun'
require 'minitest/spec'
