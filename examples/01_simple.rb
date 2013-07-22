require_relative '../persistence/persistence.rb'
require_relative '../identity/identity.rb'
 


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

    raise "Person is not valid!" if per.valid? == false
    dupe = Aggregate.get_aggregate_by_lookup_value(Person, @person.ssn)   
    raise "Person with this SSN already exists " if dupe != {}

    event.publish 
    Aggregate.get_by_aggregate_id(Person, event.aggregate_id)
  end 
end

 

per = Person.new 
per.first_name = 'John'
per.last_name = 'Doe'
per.date_of_birth = Date.new(1970,7,10)
per.ssn =  "%09d" % SequenceGenerator.misc

cmd = CommandPersonAdd.new per 
person =  cmd.execute 


x = Aggregate.get_aggregate_by_lookup_value Person, person.ssn

# person and x should be the same.
pp person 
pp x 













