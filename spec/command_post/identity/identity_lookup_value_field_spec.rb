require File.expand_path(File.dirname(__FILE__) + '/../../command_post/require')





    class Test001Person < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end
        def self.schema 
          fields = Hash.new
          fields[  :first_name        ] = { :required => true,       :type => String,    :location => :local  } 
          fields[  :last_name         ] = { :required => true,       :type => String,    :location => :local  } 
          fields[  :ssn               ] = { :required => true,       :type => String,    :location => :local  } 
          fields[  :lookup            ] = { :use => :ssn }
          fields 
        end 
      end




describe CommandPost::Identity do 
  it 'it should return use the SSN as the lookup value' do 

      params = Hash.new  # like a web request... 

      params['first_name']  = 'John'                                             #hash key is a string to mimic a web post/put
      params['last_name']   = 'Doe'                                          #hash key is a string to mimic a web post/put
      params['ssn']         = "%09d" %  CommandPost::SequenceGenerator.misc     #hash key is a string to mimic a web post/put

      object = Test001Person.load_from_hash Test001Person, params
      puts "OBJECT IS NIL #{'=' * 80}" if object.nil?
      event = CommandPost::AggregateEvent.new 
      event.aggregate_id = object.aggregate_id
      event.object = object
      event.aggregate_type =  Test001Person
      event.event_description = 'hired'
      event.user_id = 'test' 
      

      event.publish

      saved_person = CommandPost::Aggregate.get_aggregate_by_lookup_value Test001Person,  params['ssn']
      
      params['first_name'].must_equal saved_person.first_name
      params['last_name'].must_equal saved_person.last_name
      params['ssn'].must_equal saved_person.ssn

  end












end
