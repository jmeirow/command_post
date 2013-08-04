require File.expand_path(File.dirname(__FILE__) + '/../../command_post/require')


describe CommandPost::Identity do 
  it 'as the name suggestions, provides the means for objects to have an identity that is used in retrieving it from the database' do 

      class SomeIdentityClass < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end
        def self.schema 
          fields = Hash.new
          fields[  :a_property        ] = { :required => true,       :type => String,    :location => :local  } 
          fields[  :lookup            ] = { :use => :a_property }
          fields 
        end 
      end


      params = Hash.new  # like a web request... 

      var = 'Hello, World!'

      params['a_property'] = var   #hash key is a string to mimic a web post/put

      object = SomeIdentityClass.load_from_hash SomeIdentityClass, params
      puts "OBJECT IS NIL #{'=' * 80}" if object.nil?
      event = CommandPost::AggregateEvent.new 
      event.aggregate_id = object.aggregate_id
      event.object = object
      event.aggregate_type =  SomeIdentityClass
      event.event_description = 'created'
      event.user_id = 'test' 
      

      event.publish

      new_object = CommandPost::Aggregate.get_by_aggregate_id SomeIdentityClass, event.aggregate_id 
      new_object.a_property.must_be_same_as var 

  end
end
