require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

 

class SomeClass  < CommandPost::Persistence 
  include CommandPost::Identity

  def initialize
    super
  end

  def self.schema 
    {
        title: "SomeClass",
        required: ["first_name", "last_name", "birth_date", "favorite_number", "ssn" ],
        type:  "object",
        properties: {
                           first_name:        { type: "string"        },
                           last_name:         { type: "string"        },
                           ssn:               { type: "string"        },

                           birth_date:        { type: "string",       
                                                class: "Date"         }, 

                           favorite_number:   { type: "integer"       }
                        }
    }
  end

  def self.unique_lookup_value
    :ssn
  end

  def self.indexes
    [:ssn]
  end
end







def get_instance
  some_class = SomeClass.new 
  SomeClass.new 
end


describe CommandPost::DataValidation do 


  it 'should be valid if all required fields are present and types are correct' do
    obj = get_instance
    obj.first_name = 'Joe'
    obj.last_name = 'Schmoe'
    obj.birth_date =  Date.new(1980,1,1) 
    obj.favorite_number = 3
    obj.ssn = CommandPost::SequenceGenerator.misc.to_s

    (obj.data_errors.length == 0 ).must_equal true


  end

 

  it 'should not be valid if missing required fields ' do
    obj = get_instance
    obj.first_name = 'Joe'
    obj.last_name = 'Schmoe'
    obj.birth_date =  Date.new(1980,1,1) 
    # ===>  missing      obj.favorite_number = 3      
    obj.ssn = CommandPost::SequenceGenerator.misc.to_s
    (obj.data_errors.length == 0 ).must_equal false

  end

  it 'should not be valid if a type is incorrect ' do
    obj = get_instance
    obj.first_name = 'Joe'
    obj.last_name = 'Schmoe'
    obj.birth_date =  Date.new(1980,1,1) 
    obj.favorite_number = "3"  # <---- should be Fixnum      
    obj.ssn = CommandPost::SequenceGenerator.misc.to_s

    (obj.data_errors.length == 0 ).must_equal false
  end



  it 'should be able to get the native data type out of the object after a save to the database' do 

    ssn =  CommandPost::SequenceGenerator.misc.to_s
    data = { first_name: 'joe', last_name: 'schmoe', ssn: ssn, favorite_number: 3, birth_date:  Date.today  }


    obj = SomeClass.load_from_hash data

 
    event = CommandPost::AggregateEvent.new 
    event.aggregate_id = obj.aggregate_id
    event.object = obj
    event.aggregate_type =  obj.class
    event.event_description = 'hired'
    event.user_id = 'test' 
    event.publish

    result = SomeClass.find(obj.aggregate_id)
 
    result.favorite_number.must_equal 3
 

  end


  it 'should be able to get the object (Date) data type out of the object after a save to the database' do 

    ssn =  CommandPost::SequenceGenerator.misc.to_s
    data = { first_name: 'joe', last_name: 'schmoe', ssn: ssn, favorite_number: 3, birth_date:  Date.today  }


    obj = SomeClass.load_from_hash data

 
    event = CommandPost::AggregateEvent.new 
    event.aggregate_id = obj.aggregate_id
    event.object = obj
    event.aggregate_type =  obj.class
    event.event_description = 'hired'
    event.user_id = 'test' 
    event.publish

    result = SomeClass.find(obj.aggregate_id)
 
    result.birth_date = Date.today
 

  end





end




 



 