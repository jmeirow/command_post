require 'date'
require_relative '../persistence/persistence.rb'
require_relative '../identity/identity.rb'
require_relative '../lib/string_util.rb'




class Person < CommandPost::Persistence
  
  include CommandPost::Identity
  
  def initialize
    super
    Person.init_schema  Person.schema 
  end
 
  def set_aggregate_lookup_value 

    @data['aggregate_lookup_value'] =  ssn
  end

  def self.schema 
    fields = Hash.new
    fields[ 'first_name'        ] = { :required => true,       :type => String,    :location => :local      } 
    fields[ 'last_name'         ] = { :required => true,       :type => String,    :location => :local      } 
    fields[ 'date_of_birth'     ] = { :required => true,       :type => Date,      :location => :local      } 
    fields[ 'ssn'               ] = { :required => true,       :type => String,    :location => :local, :upcase => true      } 
    fields
  end 

  def self.commands 

    @@commands[self]
  end

  def self.create_commands

    @@commands ||= Hash.new 
    @@commands[self] ||= Array.new 

    schema_fields.each do |field_name, field_info|

      camel_case_name = CommandPost::StringUtil.to_camel_case field_name, Person.upcase?(field_name) #(field_info.keys.include?(:upcase) ? field_info[:upcase] : false)   

      name = "CommandPersonCorrect#{camel_case_name}"
      klass = Object::const_set(name.intern, Class::new do


      end
      )

      def_init = Array.new 
      def_init <<  "def initialize person, #{field_name} " 
      def_init <<  %q(  raise "Initialization error in #{self.class}. Expected instance of Person but received instance of #{person.class}"   if person.class != Person)
      def_init <<  %q(  raise "Initialization error in #{self.class}. Expected instance of ) + field_info[:type].to_s + %q( but received instance of ) +  '#{' + "#{field_name}" + '.class}" ' + "if #{field_name.class} != #{field_info[:type].to_s}  "
      def_init <<  "end "
      

      meth = def_init.join("\n")
      puts meth

      klass.class_eval meth
      @@commands[self] << klass

      




    end
  end



end






  Person.init_schema Person.schema 
  Person.create_commands 
  

  Person.commands.each {|x| puts x.to_s }




  


































