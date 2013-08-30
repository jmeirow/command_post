require 'faker'
require 'securerandom'

require 'pry'
require 'pry-debugger'

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')



class TestXXXPerson < CommandPost::Persistence 
  include CommandPost::Identity

  def initialize
    super
  end
  def self.schema 
    fields = Hash.new
    fields[  :first_name        ] = { :required => true,       :type => String,    :location => :local  } 
    fields[  :last_name         ] = { :required => true,       :type => String,    :location => :local  } 
    fields[  :ssn               ] = { :required => true,       :type => String,    :location => :local  } 
    fields[  :state             ] = { :required => true,       :type => String,    :location => :local  }
    fields[  :favorite_number   ] = { :required => true,       :type => Fixnum,    :location => :local  } 
    fields[  :lookup            ] = { :use => :ssn }
    fields 
  end 
  def self.indexes
    [:favorite_number, :state]
  end
end


$DB["delete from aggregates"].delete
$DB["delete from aggregate_events"].delete
$DB["delete from aggregate_indexes"].delete



1000.times do |i|


  params = Hash.new  # like a web request... 

  params['first_name']  = Faker::Name.first_name                                           #hash key is a string to mimic a web post/put
  params['last_name']   = Faker::Name.last_name                                            #hash key is a string to mimic a web post/put
  params['ssn']         = "%09d" %  CommandPost::SequenceGenerator.misc                    #hash key is a string to mimic a web post/put
  params['favorite_number'] = rand(5)
  params['state'] = Faker::Address.state_abbr    

  #----------------------------------------------------------------
  # The code below will eventually be replaced by the 
  # 'handle' method of the CommandXXXXXX class.
  #----------------------------------------------------------------

  object = TestXXXPerson.load_from_hash TestXXXPerson, params
  puts "OBJECT IS NIL #{'=' * 80}" if object.nil?
  event = CommandPost::AggregateEvent.new 
  event.aggregate_id = object.aggregate_id
  event.object = object
  event.aggregate_type =  TestXXXPerson
  event.event_description = 'hired'
  event.user_id = 'test' 
  event.publish


  #----------------------------------------------------------------
  # Retrieve the object by both aggregate_id and aggregate_lookup_value
  # Both ways should retrieve the same object and the fields of both
  # should match the original values used to create the object.
  #----------------------------------------------------------------


  saved_person = CommandPost::Aggregate.get_by_aggregate_id TestXXXPerson, event.aggregate_id 

end



describe CommandPost::Identity do 
  it 'test 1' do 

    sql_cnts_in_array = 0

    $DB.fetch("SELECT * FROM aggregate_indexes WHERE index_field  = 'TestXXXPerson.favorite_number' and index_value_integer in (1,2,3) " ) do |row|
      sql_cnts_in_array += 1
    end

    ids = TestXXXPerson.favorite_number_one_of([1,2,3])

  end

  it 'should pass test 2' do 

    sql_cnts_eq = 0
    $DB.fetch("SELECT * FROM aggregate_indexes WHERE index_field  = 'TestXXXPerson.favorite_number' and index_value_integer = 4 " ) do |row|
      sql_cnts_eq += 1
    end

    ids = TestXXXPerson.favorite_number_is(4)
    ids.length.must_equal sql_cnts_eq
    sql_cnts_eq.wont_equal 0

  end

  it 'should pass test 3' do 

    mi_counts_eq = 0

    $DB.fetch("SELECT * FROM aggregate_indexes WHERE index_field  = 'TestXXXPerson.state' and index_value_text = 'MI' " ) do |row|
      mi_counts_eq += 1
    end

    results = TestXXXPerson.state_eq('MI')
    results.length.must_equal mi_counts_eq
    mi_counts_eq.wont_equal 0


  end

  puts "#{Time.now}"
  TestXXXPerson.state_eq('MI').select{|x| x.favorite_number >= 3 }.each {|x| puts "favorite_number:    #{x.favorite_number} and state #{x.state} "  }
  puts "#{Time.now}"


end




