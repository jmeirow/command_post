require_relative '../persistence/persistence.rb'
require_relative '../identity/identity.rb'
require 'faker'


class Person < Persistence
  include Identity
  def initialize
    super

    fields = Hash.new
    fields[ 'first_name'        ] = { :required => true,       :type => String,    :location => :local                        } 
    fields[ 'last_name'         ] = { :required => true,       :type => String,    :location => :local                        } 
    fields[ 'date_of_birth'     ] = { :required => true,       :type => Date,      :location => :local                        } 
    fields[ 'ssn'               ] = { :required => true,       :type => String,    :location => :local                        } 

    Person.init_schema fields     
  end

 
  def set_aggregate_lookup_value 

    @data['aggregate_lookup_value'] =  ssn
  end
end



class CommandPersonAdd
  
  def initialize  person 
    raise  ArgumentError.new("Expected Person") if (person.class != Person)
    @person = person
  end

  def execute  

    event = AggregateEvent.new  
    event.aggregate_id = SequenceGenerator.aggregate_id
    event.aggregate_type = Person.to_s
    event.event_description = "person created"
    event.object = @person
    event.user_id = 'joe'
    @person.set_aggregate_lookup_value

    raise "Person is not valid!" if @person.valid? == false
    dupe = Aggregate.get_aggregate_by_lookup_value(Person, @person.ssn)   
    raise "Person with this SSN already exists " if dupe != {}
    event.publish 
    Aggregate.get_by_aggregate_id(Person, event.aggregate_id)
  end 
end

 
50_000_000.times do  |i|
  per = Person.new 
  per.first_name = Faker::Name.first_name
  per.last_name = Faker::Name.last_name
  per.date_of_birth = Date.new(1970,7,10)
  per.ssn =  "%09d" % SequenceGenerator.misc

  cmd = CommandPersonAdd.new per 
  person =  cmd.execute 

  puts i if ((i % 1000)==0)
end


 












