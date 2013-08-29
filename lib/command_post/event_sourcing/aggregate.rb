require 'pp'
require 'securerandom'
require 'json'
require 'sequel'

module CommandPost


  $DB ||= Connection.db_cqrs

  class Aggregate   
   
    @@prep_stmt_insert ||= $DB[:aggregates].prepare(:insert,  :insert_aggregate, :aggregate_id => :$aggregate_id, :aggregate_type => :$aggregate_type, :content => :$content, :aggregate_lookup_value => :$aggregate_lookup_value )

    def update_index object, index_value , field
      index_field = "#{object.class.to_s}.#{field.to_s}"
       $DB["UPDATE aggregate_indexes set #{Persistence.compute_index_column_name(field) } = ?  where aggregate_id = ? and index_field = ?", index_value,  aggregate_id.to_i, index_field ].update
    end

    def self.replace object, aggregate_lookup_value
      content = JSON.generate object
      aggregate_id = object[:aggregate_info][:aggregate_id] 
      aggregate_type = object[:aggregate_info][:aggregate_type] 
      version = object[:aggregate_info][:version].to_i


      if (version) == 1
        @@prep_stmt_insert.call(:aggregate_id => aggregate_id.to_i, :aggregate_type => aggregate_type  , :content => content, :aggregate_lookup_value => aggregate_lookup_value  ) 
        
        object = Aggregate.get_by_aggregate_id Object.const_get(aggregate_type), aggregate_id

        object.index_fields.each do |field|
          index_value = object.send field
          index_field = "#{object.class.to_s}.#{field.to_s}"
          $DB["INSERT INTO aggregate_indexes (aggregate_id , #{Persistence.compute_index_column_name(index_value)}, index_field ) values (?, ?, ?) ", aggregate_id,  index_value,  index_field ].insert
        end
      else
        $DB["UPDATE aggregates set content = ?, aggregate_lookup_value = ? where aggregate_id = ?", content,  aggregate_lookup_value,  aggregate_id ].update
        object = Aggregate.get_by_aggregate_id Object.const_get(aggregate_type), aggregate_id
        @@prep_stmt_insert.call(:aggregate_id => aggregate_id.to_i, :aggregate_type => aggregate_type  , :content => content, :aggregate_lookup_value => aggregate_lookup_value  ) 
        object.index_fields.each do |field|
          index_value = object.send field
          update_index object, index_value, field
        end
      end
    end
    


    def self.get_by_aggregate_id aggregate_type ,aggregate_id 
      hash = Hash.new
      $DB.fetch("SELECT * FROM aggregates WHERE aggregate_id = ?",  aggregate_id ) do |row|
        hash = JSON.parse(row[:content])
      end
      aggregate_type.load_from_hash( aggregate_type, HashUtil.symbolize_keys(hash))
    end



    def self.where(aggregate_type)
      results = Array.new
      $DB.fetch("SELECT * FROM aggregates WHERE aggregate_type = ?", aggregate_type.to_s) do |row|
        hash =  JSON.parse(row[:content])
        results << aggregate_type.load_from_hash( aggregate_type, HashUtil.symbolize_keys(hash))
      end
      results
    end
    

    def self.get_for_indexed_single_value (sql, query_value, aggregate_type)
      results = Array.new
      $DB.fetch(sql, query_value ) do |row|
        hash =  JSON.parse(row[:content])
        results << aggregate_type.load_from_hash( aggregate_type, HashUtil.symbolize_keys(hash))
      end
      results


    end

    def self.get_for_indexed_multiple_values (sql, aggregate_type)
      results = Array.new
      $DB.fetch(sql ) do |row|
        hash =  JSON.parse(row[:content])
        results << aggregate_type.load_from_hash( aggregate_type, HashUtil.symbolize_keys(hash))
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
        aggregate_type.load_from_hash( aggregate_type, HashUtil.symbolize_keys(hash))
      end
    end
  end

end
