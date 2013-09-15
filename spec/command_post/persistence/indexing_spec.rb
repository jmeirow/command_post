require 'faker'
require 'securerandom'
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'money'

 

$DB['delete from aggregates'].delete
$DB['delete from aggregate_events'].delete
$DB['delete from aggregate_index_decimals'].delete
$DB['delete from aggregate_index_integers'].delete
$DB['delete from aggregate_index_strings'].delete




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


5000.times do |i|


  params = Hash.new  # like a web request... 

  params['first_name']  = Faker::Name.first_name                                           #hash key is a string to mimic a web post/put
  params['last_name']   = Faker::Name.last_name                                            #hash key is a string to mimic a web post/put
  params['ssn']         = "%09d" %  CommandPost::SequenceGenerator.misc                    #hash key is a string to mimic a web post/put
  params['favorite_number'] = rand(5)
  params['state'] = Faker::Address.state_abbr    
  params['hourly_rate'] = (Money.new(1000,'USD').to_f * rand(5.0))

  #----------------------------------------------------------------
  # The code below will eventually be replaced by the 
  # 'handle' method of the CommandXXXXXX class.
  #----------------------------------------------------------------

  object = TestXXXPerson.load_from_hash   params
  #puts "JSON =   #{JSON.generate(object.to_h)}"
  TestXXXPerson.put object, 'hired', 'smithmr'  

  #----------------------------------------------------------------
  # Retrieve the object by both aggregate_id and aggregate_lookup_value
  # Both ways should retrieve the same object and the fields of both
  # should match the original values used to create the object.
  #----------------------------------------------------------------

  saved_person = TestXXXPerson.find(object.aggregate_id)

end



describe CommandPost::Identity do 
  it 'select for index, in list' do 

    sql_cnts_in_array = 0

    $DB.fetch("SELECT count(*) cnt FROM aggregate_index_integers WHERE index_field  = 'TestXXXPerson.favorite_number' and index_value in (1,2,3) " ) do |row|
      sql_cnts_in_array = row[:cnt]
    end

    ids = TestXXXPerson.favorite_number_one_of([1,2,3])

  end

  it 'select for decimal, equal' do 

    sql_cnts_eq = 0
    $DB.fetch("SELECT count(*) cnt FROM aggregate_index_decimals WHERE index_field  = 'TestXXXPerson.hourly_rate' and index_value = 30.00 " ) do |row|
      sql_cnts_eq = row[:cnt]
    end

    ids = TestXXXPerson.hourly_rate_eq(Money.new(3000,'USD').to_f)
    ids.length.must_equal sql_cnts_eq
    assert_equal ids.length, sql_cnts_eq

  end






  it 'select for string, equal' do 

    sql_counts_eq = 0

    ssn = ''
    $DB.fetch("SELECT min(index_value) ssn FROM aggregate_index_strings WHERE index_field  = 'TestXXXPerson.ssn'  " ) do |row|
      ssn  = row[:ssn]
    end
 
    results = TestXXXPerson.ssn_eq(ssn)
    assert_equal results.length, 1

  end



  it 'select for integers, equal ' do 

    sql_cnts_in_array = 0

    $DB.fetch("SELECT count(*) cnt FROM aggregate_index_integers WHERE index_field  = 'TestXXXPerson.favorite_number' and index_value  = 2  " ) do |row|
      sql_cnts_in_array = row[:cnt]
    end
    ids = TestXXXPerson.favorite_number_eq(2)
    assert_equal ids.length, sql_cnts_in_array

  end



end




















