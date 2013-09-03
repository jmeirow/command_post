
require 'json-schema'
require 'pp'





 - Validation still depends on hash keys as symbols. This is contrary to the most recent version's notes.



"Make hashes indifferent to strings and symbols when using Ruby in the schema or the data"


  $ gem list | grep json    =>  json-schema (2.1.3)



 'age' is requried to be an integer


 schema = {
        "type"        => "object",
        "required"    => ["first_name", "last_name", "ssn", "age"],
        "properties"  => {
                            "first_name"    =>  { "type"          =>  "string"              },
                            "last_name"     =>  { "type"          =>  "string"              }, 
                            "ssn"           =>  { "type"          =>  "string"              }, 
                            "age"           =>  { "type"          =>  "integer"             },
                            "address"       =>  { "type"          =>  "object"              }
                          }
      }


- validation properly enforced when data hash has string keys


data = {'first_name' => 'Joseph', 'last_name' => 'Smith', 'age' => false, 'ssn' => '123456789',  }

pp JSON::Validator.fully_validate(schema, data, :errors_as_objects => true, :validate_schema => true)


-> [{:schema=>
    #<URI::Generic:0x007fa714a0c590 URL:b3506251-b386-5804-a591-d72a6b3e417d#>,
   :fragment=>"#/age",
   :message=>
    "The property '#/age' of type FalseClass did not match the following type: integer in schema b3506251-b386-5804-a591-d72a6b3e417d#",
   :failed_attribute=>"TypeV4"}]



- validation does not catch invalid type for 'age' 

data = {:first_name => 'Joseph', :last_name => 'Smith', :age => false, :ssn => '123456789',  }

pp JSON::Validator.fully_validate(schema, data, :errors_as_objects => true, :validate_schema => true)

=> []


