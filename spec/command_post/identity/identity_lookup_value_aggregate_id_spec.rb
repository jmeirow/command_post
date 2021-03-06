require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

 


class Test003Person < CommandPost::Persistence 
  include CommandPost::Identity

  def initialize
    super
  end
  def self.schema 
    {
        "title"           => "Test003Person",
        "required"        => ["first_name", "last_name", "ssn"],
        "type"            => "object",
        "properties" => {
                          "first_name"    =>  { "type"          =>  "string"        },
                          "last_name"     =>  { "type"          =>  "string"        },
                          "ssn"           =>  { "type"          =>  "string"        }
                           
                        },
      }
  end

 

  def self.indexes
    [:ssn]
  end
end


describe CommandPost::Identity do 
  it 'as the name suggestions, provides the means for objects to have an identity that is used in retrieving it from the database' do 

    params = Hash.new  # like a web request... 
    params['first_name']  = 'John'                                              #hash key is a string to mimic a web post/put
    params['last_name']   = 'Doe'                                               #hash key is a string to mimic a web post/put
    params['ssn']         = "%09d" %  CommandPost::SequenceGenerator.misc       #hash key is a string to mimic a web post/put


    #----------------------------------------------------------------
    # The code below will eventually be replaced by the 
    # 'handle' method of the CommandXXXXXX class.
    #----------------------------------------------------------------

    object = Test003Person.load_from_hash params
    Test003Person.put object, 'hired', 'smithmr'


    #----------------------------------------------------------------
    # Retrieve the object by both aggregate_id and by indexed field.
    # Both ways should retrieve the same object and the fields of both
    # should match the original values used to create the object.
    #----------------------------------------------------------------

    saved_person = Test003Person.find(object.aggregate_id)
    saved_person2 = Test003Person.ssn_eq(saved_person.ssn).first

    
    params['first_name'].must_equal saved_person.first_name
    params['last_name'].must_equal saved_person.last_name
    params['ssn'].must_equal saved_person.ssn

    params['first_name'].must_equal saved_person2.first_name
    params['last_name'].must_equal saved_person2.last_name
    params['ssn'].must_equal saved_person2.ssn
  end
end

























