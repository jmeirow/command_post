# require 'pp'
# require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')


 

#   class Test100Person < CommandPost::Persistence 
#     include CommandPost::Identity

#     def initialize
#       super
#     end
#     def self.schema 
#       fields = Hash.new
#       fields[  :first_name        ] = { :required => true,       :type => String,    :location => :local  } 
#       fields[  :last_name         ] = { :required => true,       :type => String,    :location => :local  } 
#       fields[  :ssn               ] = { :required => true,       :type => String,    :location => :local  } 
#       fields[  :favorite_number   ] = { :required => true,       :type => Fixnum,    :location => :local  } 
#     fields 
#   end

#   def self.unique_lookup_value 
#     :ssn 
#   end
  
#   def self.indexes
#       [:favorite_number]
#     end
#   end
