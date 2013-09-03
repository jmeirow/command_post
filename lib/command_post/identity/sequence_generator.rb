require 'securerandom'
require 'sequel'



module CommandPost


  class SequenceGenerator


    def self.aggregate_id
      @@DB ||= Connection.db_cqrs
      val = 0
      @@DB.fetch("SELECT nextval('aggregate');") do |row|
        val = row[row.keys.first]
      end
      val
    end

    def self.transaction_id
      @@DB ||= Connection.db_cqrs
      val = 0
      @@DB.fetch("SELECT nextval('transaction');") do |row|
        val = row[row.keys.first]
      end
      val
    end

    def self.misc
      @@DB ||= Connection.db_cqrs
      val = 0
      @@DB.fetch("SELECT nextval('misc');") do |row|
        val = row[row.keys.first]
      end
      val
    end
  end


end

 