require 'date'
require 'minitest/autorun'
require 'minitest/spec'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/command_post/persistence/persistence')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/command_post/persistence/data_validation')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/command_post/identity/identity')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/command_post/event_sourcing/aggregate')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/command_post/event_sourcing/aggregate_event')