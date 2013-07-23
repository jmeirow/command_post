require 'pp'
require 'securerandom'
require 'json'
require 'sequel'

require_relative '../db/connection.rb'
require_relative '../identity/sequence_generator.rb'


$DB ||= Connection.db_cqrs

class Aggregate   
 
  @@prep_stmt_insert ||= $DB[:aggregates].prepare(:insert,  :insert_aggregate, :aggregate_id => :$aggregate_id, :aggregate_type => :$aggregate_type, :content => :$content, :aggregate_lookup_value => :$aggregate_lookup_value )
  @@prep_stmt_update ||= $DB[:aggregates].prepare(:update,  :update_content_aggregate_lookup_value, :aggregate_id => :$aggregate_id, :content => :$content, :aggregate_lookup_value => :$aggregate_lookup_value )

  

  def self.replace object
    content = JSON.generate object
  
    aggregate_id = object['aggregate_info']['aggregate_id'] 
    aggregate_type = object['aggregate_info']['aggregate_type'] 
    version = object['aggregate_info']['version'].to_i
    aggregate_lookup_value =  object['aggregate_lookup_value'] 

    if (version) == 1
      @@prep_stmt_insert.call(:aggregate_id => aggregate_id, :aggregate_type => aggregate_type.to_s , :content => content, :aggregate_lookup_value => aggregate_lookup_value  ) 
    else
      $DB["UPDATE aggregates set content = ?, aggregate_lookup_value = ? where aggregate_id = ?", content,  aggregate_lookup_value,  aggregate_id ].update
    end
  end
  


  def self.get_by_aggregate_id aggregate_type ,aggregate_id 
    hash = Hash.new
    $DB.fetch("SELECT * FROM aggregates WHERE aggregate_id = ?",  aggregate_id ) do |row|
      hash = JSON.parse(row[:content])
    end
    aggregate_type.load_from_hash( aggregate_type, hash)
  end



  def self.where(aggregate_type)
    results = Array.new
    $DB.fetch("SELECT * FROM aggregates WHERE aggregate_type = ?", aggregate_type.to_s) do |row|
      hash =  JSON.parse(row[:content])
      results << aggregate_type.load_from_hash( aggregate_type, hash)
    end
    results
  end
  


  def self.exists? aggregate_type, aggregate_lookup_value  
    $DB.fetch("SELECT count(*) as cnt FROM aggregates WHERE aggregate_type = ? and aggregate_lookup_value = ? ", aggregate_type.to_s, aggregate_lookup_value) do |rec|
      return rec[:cnt].to_i > 0
    end
  end
  


  def self.get_aggregate_by_lookup_value aggregate_type, aggregate_lookup_value 
    hash = Hash.new
    $DB.fetch("SELECT content FROM aggregates WHERE aggregate_type = ? and aggregate_lookup_value = ? ", aggregate_type.to_s, aggregate_lookup_value) do |rec|
      hash = JSON.parse(rec[:content])
    end
    if hash.nil? || hash == {}
      {}
    else
      aggregate_type.load_from_hash( aggregate_type, hash)
    end
  end
end