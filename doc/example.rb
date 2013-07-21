require_relative '../persistence/persistence.rb'
require_relative '../identity/identity.rb'




class Address < Persistence
  def initialize
    super
    fields = Hash.new
    fields[ 'address1'  ] = { :required => true,       :type => String,    :location => :local  } 
    fields[ 'address2'  ] = { :required => false,      :type => String,    :location => :local  } 
    fields[ 'city'      ] = { :required => true,       :type => String,    :location => :local  } 
    fields[ 'state'     ] = { :required => true,       :type => String,    :location => :local  } 
    fields[ 'zipcode'   ] = { :required => true,       :type => String,    :location => :local  } 

    Address.init_schema fields 
  end
 
  def set_aggregate_lookup_value 
    @data['aggregate_lookup_value'] =  ssn
  end
end


class Citizen < Persistence
  include Identity
  def initialize
    super

    fields = Hash.new
    fields[ 'first_name'        ] = { :required => true,       :type => String,    :location => :local                        } 
    fields[ 'last_name'         ] = { :required => true,       :type => String,    :location => :local                        } 
    fields[ 'date_of_birth'     ] = { :required => true,       :type => Date,      :location => :local                        } 
    fields[ 'ssn'               ] = { :required => true,       :type => String,    :location => :local                        } 
    fields[ 'address'           ] = { :required => true,       :type => Address,   :location => :local,  :auto_load => true   } 

    Citizen.init_schema fields     
  end

 
  def set_aggregate_lookup_value 

    @data['aggregate_lookup_value'] =  ssn
  end
end


# require 'Faker'


class CommandCitizenAdd
  def initialize  person 
    raise  ArgumentError.new("Expected Citizen") if (person.class != Citizen)
    @person = person
  end
  def execute  

    event = AggregateEvent.new  
    event.aggregate_id = SequenceGenerator.aggregate_id
    event.aggregate_type = @person.class.to_s
    event.event_description = "created"
    event.object = @person
    event.user_id = 'joe'
    @person.set_aggregate_lookup_value

 


    if Aggregate.exists?(Citizen, @person.aggregate_lookup_value)
    else 
      event.publish 
      x = Aggregate.get_by_aggregate_id(Citizen, event.aggregate_id)
      x
    end
  end 
end

class CommandCitizenAddFavoriteColor 
  def initialize  citizen, favorite_color 
    raise  ArgumentError.new("Expected Citizen") if (person.class != Citizen)
    raise  ArgumentError.new("Expected String") if (favorite_color.class != String)
    @citizen = citizen
    @favorite_color = favorite_color

  end

  def execute  

    event = AggregateEvent.new  
    event.aggregate_id = SequenceGenerator.aggregate_id
    event.aggregate_type = @citizen.class.to_s
    event.event_description = "added favorite color"
    event.changes =  { 'favorite_color' => favorite_color}
    event.user_id = 'joe'
    event.publish
  end 
end

cit = Citizen.new 
cit.first_name = 'Joe'
cit.last_name = 'Meirow'
cit.date_of_birth = Date.new(1963,8,10)
cit.ssn = '999999999'

addr = Address.new
addr.address1 = '72422 Campground Road'
addr.city = 'Romeo'
addr.state = 'MI'
addr.zip = '48065'

cit.address = addr 

cmd = CommandCitizenAdd.new cit 
cmd.execute 

x = Aggregate.get_aggregate_by_lookup_value Citizen, '999999999'

puts "printing information"
puts "Name:  #{x.first_name}"
puts "City:  #{x.address.city}"









