require File.expand_path(File.dirname(__FILE__) + '/../../command_post/require')
require 'pp'


 

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




  # Test100Person.init_indexes Test100Person.indexes


  ids = Test100Person.favorite_number_in([10,11,12])

  puts "count = #{ids.count}"

 

 







