require 'require.rb'


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
          fields 
        end 
      end



      object = SomeIdentityClass.new
      var = 'Hello, World!' 
      object.a_property = var 
      event = AggregateEvent.new 
      event.object = object
      event.aggregate_type =  'SomeIdentityClass'
      event.mutate 

      new_object = Aggregate.get_by_aggregate_id SomeIdentityClass, event.aggregate_id 
      new_object.a_property.must_be_same_as var 

  end
end
