






# given 


class Person < CommandPost::Persistence 
  include CommandPost::Identity

  def initialize
    super
  end
  def self.schema 
    fields = Hash.new
    fields[  :first_name        ] = { :required => true,       :type => String,    :location => :local  } 
    fields[  :last_name         ] = { :required => true,       :type => String,    :location => :local  } 
    fields[  :department        ] = { :required => true,       :type => String,    :location => :local , :indexed => true,  } 
    fields[  :location          ] = { :required => true,       :type => String,    :location => :local , :indexed => true,  } 
    fields[  :ssn               ] = { :required => true,       :type => String,    :location => :local  } 
    fields[  :lookup            ] = { :use => :aggregate_id }
    fields 
  end 
end


# the above :indexed => true syntax causes the following to happen:

# a table, new to this version is updated



aggregate_indexes 
aggregate_field ('Person.Department')
index_value
aggregate_id  


(Person.department_in(['sales']) & Person.location_in(['midwest'])

end


def method_missing args 

  if index_fields.include?(field_name) && args[1].class == Array 
    field_base_name = ...
    sql = "SELECT aggregate_id from aggregate_indexes WHERE index_field = '#{self.class}.#{field_base_name}' and index_value in (args[1])"
  end






