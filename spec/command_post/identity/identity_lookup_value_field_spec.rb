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

    params['first_name']  = 'John'                                            #hash key is a string to mimic a web post/put
    params['last_name']   = 'Doe'                                             #hash key is a string to mimic a web post/put
    params['ssn']         = "%09d" %  CommandPost::SequenceGenerator.misc     #hash key is a string to mimic a web post/put


    #----------------------------------------------------------------
    # The code below will eventually be replaced by the 
    # 'handle' method of the CommandXXXXXX class.
    #----------------------------------------------------------------

    object = Test001Person.load_from_hash Test001Person, params
    puts "OBJECT IS NIL #{'=' * 80}" if object.nil?
    event = CommandPost::AggregateEvent.new 
    event.aggregate_id = object.aggregate_id
    event.object = object
    event.aggregate_type =  Test001Person
    event.event_description = 'hired'
    event.user_id = 'test' 
    event.publish


    #----------------------------------------------------------------
    # Retrieve the object by both aggregate_id and aggregate_lookup_value
    # Both ways should retrieve the same object and the fields of both
    # should match the original values used to create the object.
    #----------------------------------------------------------------


    saved_person = CommandPost::Aggregate.get_by_aggregate_id Test001Person, event.aggregate_id 
    saved_person2 = CommandPost::Aggregate.get_aggregate_by_lookup_value Test001Person,  saved_person.aggregate_lookup_value

    
    params['first_name'].must_equal saved_person.first_name
    params['last_name'].must_equal saved_person.last_name
    params['ssn'].must_equal saved_person.ssn

    params['first_name'].must_equal saved_person2.first_name
    params['last_name'].must_equal saved_person2.last_name
    params['ssn'].must_equal saved_person2.ssn
  end
end













