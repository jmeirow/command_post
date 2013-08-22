require File.expand_path(File.dirname(__FILE__) + '/../../command_post/require')

require 'faker'
require 'securerandom'



class Test100Person < CommandPost::Persistence 
  include CommandPost::Identity

  def initialize
    super
  end
  def self.schema 
    fields = Hash.new
    fields[  :first_name        ] = { :required => true,       :type => String,    :location => :local  } 
    fields[  :last_name         ] = { :required => true,       :type => String,    :location => :local  } 
    fields[  :ssn               ] = { :required => true,       :type => String,    :location => :local  } 
    fields[  :favorite_number   ] = { :required => true,       :type => Fixnum,    :location => :local  } 
    fields[  :lookup            ] = { :use => :ssn }
    fields 
  end 
  def self.indexes
    [:favorite_number]
  end
end



describe CommandPost::Identity do 
  it 'should aggregate_ids via index methods' do 



    1000.times do |i|


      puts "count = #{i.to_s}"
      params = Hash.new  # like a web request... 

      params['first_name']  = Faker::Name.first_name                                           #hash key is a string to mimic a web post/put
      params['last_name']   = Faker::Name.last_name                                            #hash key is a string to mimic a web post/put
      params['ssn']         = "%09d" %  CommandPost::SequenceGenerator.misc     #hash key is a string to mimic a web post/put
      params['favorite_number'] = rand(20)

      #----------------------------------------------------------------
      # The code below will eventually be replaced by the 
      # 'handle' method of the CommandXXXXXX class.
      #----------------------------------------------------------------

      object = Test100Person.load_from_hash Test100Person, params
      puts "OBJECT IS NIL #{'=' * 80}" if object.nil?
      event = CommandPost::AggregateEvent.new 
      event.aggregate_id = object.aggregate_id
      event.object = object
      event.aggregate_type =  Test100Person
      event.event_description = 'hired'
      event.user_id = 'test' 
      event.publish


      #----------------------------------------------------------------
      # Retrieve the object by both aggregate_id and aggregate_lookup_value
      # Both ways should retrieve the same object and the fields of both
      # should match the original values used to create the object.
      #----------------------------------------------------------------


      saved_person = CommandPost::Aggregate.get_by_aggregate_id Test100Person, event.aggregate_id 

    end
  end
end




