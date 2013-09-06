require_relative 'lib/command_post.rb'

require 'securerandom'
require 'json-schema'
require 'pp'
require 'json'
require 'date'
require 'faker'
require 'money'

# $DB['delete from aggregates'].delete
# $DB['delete from aggregate_events'].delete
# $DB['delete from aggregate_index_decimals'].delete
# $DB['delete from aggregate_index_integers'].delete
# $DB['delete from aggregate_index_strings'].delete

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
    [:favorite_number, :ssn, :hourly_rate, :state]
  end
end

 

# 500.times do
#   params = Hash.new  # like a web request... 
#   params['first_name']  = Faker::Name.first_name                                           #hash key is a string to mimic a web post/put
#   params['last_name']   = Faker::Name.last_name                                            #hash key is a string to mimic a web post/put
#   params['ssn']         = "%09d" %  CommandPost::SequenceGenerator.misc                    #hash key is a string to mimic a web post/put
#   params['favorite_number'] = rand(5)
#   params['state'] = Faker::Address.state_abbr    
#   params['hourly_rate'] = (Money.new(1000,'USD').to_f * rand(5.0))



post '/add_new_person:person_data'  do
  new_person = TestXXXPerson.load_from_hash params[:person_data]
  TestXXXPerson.put new_person , "hired new employee.", "smithmr"
end 













