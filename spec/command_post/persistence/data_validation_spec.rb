require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

 

class SomeClass  < CommandPost::Persistence 
  include CommandPost::Identity

  def initialize
    super
  end



  def self.schema 
    {    
      "title"           => "SomeClass",
      "required"        => ["first_name", "last_name", "ssn", "favorite_number", "birth_date" ],
      "type"            => "object",
      "properties" => {
                        "first_name"          =>  { "type"          =>  "string"        },
                        "last_name"           =>  { "type"          =>  "string"        },
                        "ssn"                 =>  { "type"          =>  "string"        },
                        "favorite_number"     =>  { "type"          =>  "integer"       },
                        "birth_date"          =>  { "type"          =>  "string"        }
                      },
    }
  end

  def self.unique_lookup_value
    :ssn
  end

  def self.indexes
    []
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
    obj.ssn = CommandPost::SequenceGenerator.misc

    JSON::Validator.validate(SomeClass.schema, obj.to_h,  :validate_schema => true).must_equal true

  end

 

  it 'should not be valid if missing required fields ' do
    obj = get_instance
    obj.first_name = 'Joe'
    obj.last_name = 'Schmoe'
    obj.birth_date =  Date.new(1980,1,1) 
    # ===>  missing      obj.favorite_number = 3      
    obj.ssn = CommandPost::SequenceGenerator.misc
    JSON::Validator.validate(SomeClass.schema,   obj.to_h,  :validate_schema => true).must_equal false
  end

  it 'should not be valid if a type is incorrect ' do
    obj = get_instance
    obj.first_name = 'Joe'
    obj.last_name = 'Schmoe'
    obj.birth_date =  Date.new(1980,1,1) 
    obj.favorite_number = "x"  # <---- should be Fixnum      


    obj.ssn = CommandPost::SequenceGenerator.misc

    JSON::Validator.validate(SomeClass.schema,  JSON::Schema.add_indifferent_access(obj.to_h),  :validate_schema => true).must_equal false
  end


  schema = {
        "title"           => "SomeClass",
        "required"        => ["first_name", "last_name", "birth_date", "favorite_number", "ssn" ],
        "type"            => "object",
        "properties" => {
                          "first_name"          =>  { "type"          =>  "string"        },
                          "last_name"           =>  { "type"          =>  "string"        },
                          "ssn"                 =>  { "type"          =>  "string"        },
                        
                          "birth_date"          =>  { "type"          =>  "string" , 
                                                      "class"         =>  "Date"          },
                          "favorite_number"     =>  { "type"          =>  "integer"       }
                        }
    }

    # data = {'first_name' => 'joe', 'last_name' => 'schmoe', 'ssn' =>'321564987', 'favorite_number' => 3, 'birth_date' => "1/1/2014"      }

 



    params = ['first_name' => 'Joe' , 'last_name' => 'Schmoe',   'birth_date' =>  Date.new(1980,1,1) , 'favorite_number' => 3]
    obj = SomeClass.load_from_hash params
    event = CommandPost::AggregateEvent.new 
    event.aggregate_id = obj.aggregate_id
    event.object = obj
    event.aggregate_type =  SomeClass
    event.event_description = 'hired'
    event.user_id = 'test' 
    event.publish

    result = CommandPost::Aggregate.get_by_aggregate_id(SomeClass,obj.aggregate_id)

    pp result  



end