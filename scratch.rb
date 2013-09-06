require_relative 'lib/command_post.rb'

require 'securerandom'
require 'json-schema'
require 'pp'
require 'json'
require 'date'
 

class Employer  < CommandPost::Persistence 
  include CommandPost::Identity

  def initialize
    super
  end

  def self.schema 
    {
      title: "Employer",
      required: ["employer_name", "address", "employer_number" ],
      type:  "object",
      properties: 
      {
        employer_number:  { type:  "integer"},
        employer_name:    { type:  "string" },
        address:          { type:  "string" }
      }
    }
  end



  def self.indexes
    [:employer_number]
  end
end


# obj = Employer.load_from_hash({ :employer_number => 3000, :employer_name => 'abc co', :address => '2700 Trumbull'})
# new_obj = Employer.command_create(obj, 'user_id', 'description')

Employer.new
  
objects = Hash.new

objects[:old] = Employer.employer_number_is(3000).first
objects[:new] = Employer.employer_number_is(3000).first

objects[:new].address = "72422 Campground"

pp Employer.changes(objects)








  