require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')


 

  describe CommandPost::Persistence do 
 



      schemas = Hash.new 
      schemas['ruby_1_9_hash_syntax'] =
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


      schemas['ruby_hash_symbolized_keys_with_hashrocket'] =
      {
            :title    =>    "SomeClass",
            :required  =>   ["first_name", "last_name", "birth_date", "favorite_number", "ssn" ],
            :type      =>  "object",
            :properties  =>  {
                                :first_name      =>     { :type => "string"        },
                                :last_name       =>     { :type => "string"        },
                                :ssn             =>     { :type => "string"        },

                                :birth_date      =>  {   :type => "string",       
                                                         :class => "Date"         }, 

                                :favorite_number =>  {   :type => "integer"       }
                            }
        }

      schemas['ruby_hash_string_keys_with_hashrocket'] =
      {
            'title'    =>    "SomeClass",
            'required'  =>   ["first_name", "last_name", "birth_date", "favorite_number", "ssn" ],
            'type'      =>  "object",
            'properties'  =>  {
                                'first_name'      =>     { 'type' => "string"        },
                                'last_name'       =>     { 'type' => "string"        },
                                'ssn'             =>     { 'type' => "string"        },

                                'birth_date'      =>  {   'type' => "string",       
                                                          'class' => "Date"         }, 

                                'favorite_number' =>  {   'type' => "integer"       }
                            }
        }






      data = Hash.new
      data['ruby_hash_symbolized_keys_with_hashrocket']    = { :first_name => 'joe',   :last_name => 'schmoe',     :ssn => '321564987',    :favorite_number =>  3   ,  :birth_date      =>  Date.new(1980,1,1)    }
      data['ruby_hash_string_keys_with_hashrocket']      = { 'first_name' => 'joe',  'last_name' => 'schmoe',    'ssn' => '321564987',   'favorite_number' =>   3   , 'birth_date'     =>  Date.new(1980,1,1)   }
      data['ruby_1_9_hash_syntax']                        = { first_name: 'joe',      last_name: 'schmoe',        ssn: '321564987',       favorite_number:      3   ,      birth_date:         Date.new(1980,1,1)   }

        













    it 'should work when schema is              ruby_hash_symbolized_keys_with_hashrocket              and data is              ruby_hash_string_keys_with_hashrocket ' do
        json_schema = JSON.generate(schemas['ruby_hash_symbolized_keys_with_hashrocket'])
        json_data =   JSON.generate(data['ruby_hash_string_keys_with_hashrocket'])
        JSON::Validator.fully_validate(json_schema, json_data, :errors_as_objects => true, :validate_schema => true).must_equal []
    end


 
     it 'should work when schema is              ruby_hash_symbolized_keys_with_hashrocket              and data is              ruby_1_9_hash_syntax ' do
        json_schema = JSON.generate(schemas['ruby_hash_symbolized_keys_with_hashrocket'])
        json_data =   JSON.generate(data['ruby_1_9_hash_syntax'])
        JSON::Validator.fully_validate(json_schema, json_data, :errors_as_objects => true, :validate_schema => true).must_equal []
    end


    it 'should work when schema is              ruby_hash_symbolized_keys_with_hashrocket              and data is              ruby_hash_symbolized_keys_with_hashrocket ' do
        json_schema = JSON.generate(schemas['ruby_hash_symbolized_keys_with_hashrocket'])
        json_data =   JSON.generate(data['ruby_hash_symbolized_keys_with_hashrocket'])
        JSON::Validator.fully_validate(json_schema, json_data, :errors_as_objects => true, :validate_schema => true).must_equal []
    end





    it 'should work when schema is              ruby_hash_string_keys_with_hashrocket              and data is              ruby_hash_string_keys_with_hashrocket ' do
        json_schema = JSON.generate(schemas['ruby_hash_string_keys_with_hashrocket'])
        json_data =   JSON.generate(data['ruby_hash_string_keys_with_hashrocket'])
        JSON::Validator.fully_validate(json_schema, json_data, :errors_as_objects => true, :validate_schema => true).must_equal []
    end


 
     it 'should work when schema is              ruby_hash_string_keys_with_hashrocket              and data is              ruby_hash_symbolized_keys_with_hashrocket ' do
        json_schema = JSON.generate(schemas['ruby_hash_string_keys_with_hashrocket'])
        json_data =   JSON.generate(data['ruby_hash_symbolized_keys_with_hashrocket'])
        JSON::Validator.fully_validate(json_schema, json_data, :errors_as_objects => true, :validate_schema => true).must_equal []
    end


    it 'should work when schema is              ruby_hash_string_keys_with_hashrocket              and data is              ruby_1_9_hash_syntax ' do
        json_schema = JSON.generate(schemas['ruby_hash_string_keys_with_hashrocket'])
        json_data =   JSON.generate(data['ruby_1_9_hash_syntax'])
        JSON::Validator.fully_validate(json_schema, json_data, :errors_as_objects => true, :validate_schema => true).must_equal []
    end


 


    it 'should work when schema is              ruby_1_9_hash_syntax              and data is              ruby_1_9_hash_syntax ' do
        json_schema = JSON.generate(schemas['ruby_1_9_hash_syntax'])
        json_data =   JSON.generate(data['ruby_1_9_hash_syntax'])
        JSON::Validator.fully_validate(json_schema, json_data, :errors_as_objects => true, :validate_schema => true).must_equal []
    end


 
     it 'should work when schema is              ruby_1_9_hash_syntax              and data is              ruby_hash_string_keys_with_hashrocket ' do
        json_schema = JSON.generate(schemas['ruby_1_9_hash_syntax'])
        json_data =   JSON.generate(data['ruby_hash_string_keys_with_hashrocket'])
        JSON::Validator.fully_validate(json_schema, json_data, :errors_as_objects => true, :validate_schema => true).must_equal []
    end


    it 'should work when schema is              ruby_1_9_hash_syntax              and data is              ruby_hash_symbolized_keys_with_hashrocket ' do
        json_schema = JSON.generate(schemas['ruby_1_9_hash_syntax'])
        json_data =   JSON.generate(data['ruby_hash_symbolized_keys_with_hashrocket'])
        JSON::Validator.fully_validate(json_schema, json_data, :errors_as_objects => true, :validate_schema => true).must_equal []
    end


  end 



 




 




 
 


 
