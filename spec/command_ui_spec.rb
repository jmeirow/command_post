require 'date'
require_relative '../persistence/persistence.rb'
require_relative '../identity/identity.rb'




class Person < CommandPost::Persistence
  include CommandPost::Identity
  def initialize
    super
    create_schema
    create_commands

    
  end

 
  def set_aggregate_lookup_value 

    @data['aggregate_lookup_value'] =  ssn
  end



private 
  def create_schema

    fields = Hash.new
    fields[ 'first_name'        ] = { :required => true,       :type => String,    :location => :local                        } 
    fields[ 'last_name'         ] = { :required => true,       :type => String,    :location => :local                        } 
    fields[ 'date_of_birth'     ] = { :required => true,       :type => Date,      :location => :local                        } 
    fields[ 'ssn'               ] = { :required => true,       :type => String,    :location => :local                        } 


    Person.init_schema fields 
  end

  def create_commands

    legal_fname_chg = CommandPost::CommandUITemplate.new
    legal_fname_chg.class = Person
    legal_fname_chg.noun = 'name'
    legal_fname_chg.verb = "change"
    legal_fname_chg.reason = "legal name change"
    legal_fname_chg.fields = ['first_name', 'last_name']   
    legal_fname_chg.ui_description = "Change person's name due to a legal name change."
    legal_fname_chg.ui_header_do_not_display = []


  end


end




@web_content = Person.CommandPersonChangeNameLegalNameChange
