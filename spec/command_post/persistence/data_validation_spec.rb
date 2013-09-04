require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

 

class SomeClass  < CommandPost::Persistence 
  include CommandPost::Identity

  def initialize
    super
  end

  def self.schema 
    {
        "title"           => "SomeClass",
        "required"        => ["first_name", "last_name", "birth_date", "favorite_number" ],
        "type"            => "object",
        "properties" => {
                          "first_name"          =>  { "type"          =>  "string"        },

                          "last_name"           =>  { "type"          =>  "string"        },

                          "birth_date"          =>  { "type"          =>  "object", 
                                                      "class"         =>  "Date"          },

                          "favorite_number"     =>  { "type"          =>  "integer"       }
                        },
      }


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
    obj.birth_date = Date.new(1980,1,1)
    obj.favorite_number = 3
    puts ""
    puts ""
    puts  "#{'=' * 85}"
    puts "==== DEBUG:   HashUtil.stringify_keys(obj.to_h)  #{HashUtil.stringify_keys(obj.to_h)}  "
    puts  "#{'=' * 85}"
    puts ""
    puts ""
    JSON::Validator.validate(SomeClass.schema, HashUtil.stringify_keys(obj.to_h),  :validate_schema => true).must_equal true

  end

  it 'should not be valid if missing required fields ' do
    obj = get_instance
    obj.first_name = 'Joe'
    obj.last_name = 'Schmoe'
    obj.birth_date = Date.new(1980,1,1)
    # ===>  missing      obj.favorite_number = 3      
    JSON::Validator.validate(SomeClass.schema, obj.to_h,  :validate_schema => true).must_equal false
  end

  it 'should not be valid if a type is incorrect ' do
    obj = get_instance
    obj.first_name = 'Joe'
    obj.last_name = 'Schmoe'
    obj.birth_date = Date.new(1980,1,1)
    obj.favorite_number = "3"  # <---- should be Fixnum      
    JSON::Validator.validate(SomeClass.schema, obj.to_h,  :validate_schema => true).must_equal false
  end
end
















 
