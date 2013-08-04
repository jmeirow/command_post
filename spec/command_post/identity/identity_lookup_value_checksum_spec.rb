require File.expand_path(File.dirname(__FILE__) + '/../../command_post/require')





    class Test002Person < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end
        def self.schema 
          fields = Hash.new
          fields[  :first_name        ] = { :required => true,       :type => String,    :location => :local  } 
          fields[  :last_name         ] = { :required => true,       :type => String,    :location => :local  } 
          fields[  :ssn               ] = { :required => true,       :type => String,    :location => :local  } 
          fields[  :lookup            ] = { :use => :checksum }
          fields 
        end 
      end




describe CommandPost::Identity do 
  it 'should produce and return a checksum when declaring the lookup to be :checksum in the schema and the checksum should be able to find the aggregate by value (checksum)'  do 

      params = Hash.new  # like a web request... 

      

      params['first_name']  = 'John'                                             #hash key is a string to mimic a web post/put
      params['last_name']   = 'Doe'                                          #hash key is a string to mimic a web post/put
      params['ssn']         = "%09d" %  CommandPost::SequenceGenerator.misc     #hash key is a string to mimic a web post/put

      object = Test002Person.load_from_hash Test002Person, params
      event = CommandPost::AggregateEvent.new 
      event.aggregate_id = object.aggregate_id
      event.object = object
      event.aggregate_type =  Test002Person
      event.event_description = 'hired'
      event.user_id = 'test' 
      

      event.publish

      saved_person = CommandPost::Aggregate.get_by_aggregate_id Test002Person, event.aggregate_id 
      saved_person2 = CommandPost::Aggregate.get_aggregate_by_lookup_value Test002Person,  saved_person.aggregate_lookup_value

      
      params['first_name'].must_equal saved_person.first_name
      params['last_name'].must_equal saved_person.last_name
      params['ssn'].must_equal saved_person.ssn

      params['first_name'].must_equal saved_person2.first_name
      params['last_name'].must_equal saved_person2.last_name
      params['ssn'].must_equal saved_person2.ssn


  end











  
end
