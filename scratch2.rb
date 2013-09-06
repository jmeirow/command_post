require_relative 'lib/command_post.rb'

require 'securerandom'
require 'json-schema'
require 'pp'
require 'json'
require 'date'
 

class TestXXXPerson < CommandPost::Persistence 
  include CommandPost::Identity

  def initialize
    super
  end
  def self.schema 
    {
        title:            "TestXXXPerson",
        required:         ["first_name", "last_name", "ssn", "state", "favorite_number", 'hourly_rate'],
        type:             "object",
        properties:   {
                          first_name:           { type:            "string"        },
                          last_name:            { type:            "string"        },
                          ssn:                  { type:            "string"        },
                          state:                { type:            "string"        },
                          favorite_number:      { type:            "integer"       },
                          hourly_rate:          { type:            "number"        }
                        },
      }

  end

  def self.indexes
    [:favorite_number, :ssn, :hourly_rate]
  end
end

 

TestXXXPerson.new 




# params = TestXXXPerson.find(63434052).to_h
# params[:state] = "MI"
# new_person = TestXXXPerson.load_from_hash params
# TestXXXPerson.put new_person , "Changed value of 'state' because person relocated.", "smithmr"


pp  CommandPost::AggregateEvent.get_history_by_aggregate_id(63434052)




# person = TestXXXPerson.find(63434052)











