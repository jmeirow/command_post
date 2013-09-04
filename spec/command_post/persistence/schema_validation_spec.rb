require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')


 

  describe CommandPost::Persistence do 

    it 'should complain if the schema is bad' do

      class SomeClass01 < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end

        def self.schema 
          {
            "title"           => "TestXXXPerson",
            "required"        => ["first_name", "last_name"],
            "type"            => "object",
            "properties" => {
                              "first_name"        =>  { "type"          =>  "string"        },
                              "last_name"         =>  { "type"          =>  "string"        }
                               
                            },
          }
        end
        def self.indexes
          []
        end
      end
      some_class = SomeClass01.new 
      some_class.class.must_be_same_as SomeClass01
    end







    it 'should raise an error when a instance of Symbol is not used to identify a field.' do 

      class SomeClass02 < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end

        def self.schema 
          {
            "title"           => "TestXXXPerson",
            "required"        => ["first_name", "last_name"],
            "type"            => "object",
            "properties" => {
                              "first_name"        =>  { "type"          =>  "string"        },
                              "last_name"         =>  { "type"          =>  "string"        }
                               
                            },
          }
        end 
        def self.indexes
          []
        end
      end

      assert_raises(ArgumentError) { some_class = SomeClass02.new } 
    end

  end 



 




 




 
 


 
