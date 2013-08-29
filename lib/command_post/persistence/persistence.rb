require_relative './schema_validation'
require_relative './data_validation'
require_relative './auto_load'

require 'pry'
require 'pry-debugger'


module CommandPost

  class Persistence 
    include SchemaValidation
    include DataValidation
    include AutoLoad

    def initialize 
      @@fields ||= Hash.new
      @@indexes ||= Hash.new
      @@methods ||= Hash.new 
      @aggregate_info_set = false
      @data = Hash.new
      self.class.init_schema self.class.schema
      self.class.init_indexes self.class.indexes
      create_methods
      Command.auto_generate self.class
    end

    def create_methods
      return if @@methods[self.class] && @@methods[self.class] == true
      self.schema_fields.keys.each do |key|
        self.class.send(:define_method, key) do 
          @data[key] 
        end
        self.class.send(:define_method, "#{key.to_s}=".to_sym) do |value| 
          @data[key] = value 
        end
      end

      self.index_fields.each do |field|
        self.class.send(:define_singleton_method, "#{field.to_s}_one_of".to_sym) do |values| 
          self.get_objects_for_in field, values
        end
        self.class.send(:define_singleton_method, "#{field.to_s}_is".to_sym) do |value| 
          self.get_objects_for_is field, value
        end
        self.class.send(:define_singleton_method, "#{field.to_s}_eq".to_sym) do |value| 
          self.get_objects_for_is field, value
        end
        self.class.send(:define_singleton_method, "#{field.to_s}_gt".to_sym) do |value| 
          self.get_objects_for_gt field, value
        end    
        self.class.send(:define_singleton_method, "#{field.to_s}_ge".to_sym) do |value| 
          self.get_objects_for_ge field, value
        end    
        self.class.send(:define_singleton_method, "#{field.to_s}_lt".to_sym) do |value| 
          self.get_objects_for_lt field, value
        end    
        self.class.send(:define_singleton_method, "#{field.to_s}_le".to_sym) do |value| 
          self.get_objects_for_le field, value
        end    
      end
      @@methods[self.class] = true
    end


    def schema_fields 
      
      @@fields[self.class]
    end

    def index_fields 
      @@indexes[self.class]
    end



    def set_data data_hash
      @data = data_hash
      if @aggregate_info_set == false 
        @aggregate_info_set = true
      end
    end


    def get_data name 
      if schema_fields[name][:location] == :local
        if schema_fields[name][:type] == DateTime
          return DateHelper.parse_date_time(@data[name]) 
        elsif schema_fields[name][:type] == Time
          DateHelper.parse_time(@data[name]) 
        else
          return @data[name]
        end
      else 
        if @data[name].class == Hash && @data[name].keys == [:aggregate_type,:aggregate_id]  
          Aggregate.get_by_aggregate_id(schema_fields[name][:type], @data[name][:aggregate_id])
        else 
          @data[name]
        end
      end
    end


    def self.stringify_values values

      values.collect{|x| "'#{x}'"}.join(',')

    end

    def self.listify(values)
      return values.collect { |x| "'#{x}'"}.join(',') if values.first.is_a? String
      x = values.join(',')
      x
    end



    def self.get_sql_for_in  index_field_name, query_values
      list = self.listify query_values
      sql = "
      SELECT            A.* 
      FROM              aggregates A 
      INNER JOIN        aggregate_indexes I on A.aggregate_id = I.aggregate_id 
      WHERE             index_field = '#{self.to_s}.#{index_field_name}' 
      AND               #{self.compute_index_column_name(query_values.first)} in (  #{list}  ) "
      sql
    end


    def self.get_sql_for_is  index_field_name , query_value
      "
      SELECT            A.* 
      FROM              aggregates A 
      INNER JOIN        aggregate_indexes I on A.aggregate_id = I.aggregate_id 
      WHERE             index_field = '#{self.to_s}.#{index_field_name}' 
      AND               #{self.compute_index_column_name(query_value)} = ? "
    end


    def self.get_sql_for_gt  index_field_name , query_value
      "
      SELECT            A.* 
      FROM              aggregates A 
      INNER JOIN        aggregate_indexes I on A.aggregate_id = I.aggregate_id 
      WHERE             index_field = '#{self.to_s}.#{index_field_name}' 
      AND               #{self.compute_index_column_name(query_value)} > ? "
    end
    def self.get_sql_for_ge  index_field_name , query_value

      "
      SELECT            A.* 
      FROM              aggregates A 
      INNER JOIN        aggregate_indexes I on A.aggregate_id = I.aggregate_id 
      WHERE             index_field = '#{self.to_s}.#{index_field_name}' 
      AND               #{self.compute_index_column_name(query_value)} >= ? "
    end
    def self.get_sql_for_lt  index_field_name , query_value

      "
      SELECT            A.* 
      FROM              aggregates A 
      INNER JOIN        aggregate_indexes I on A.aggregate_id = I.aggregate_id 
      WHERE             index_field = '#{self.to_s}.#{index_field_name}' 
      AND               #{self.compute_index_column_name(query_value)} < ? "
    end

    def self.get_sql_for_le  index_field_name , query_value
      "
      SELECT            A.* 
      FROM              aggregates A 
      INNER JOIN        aggregate_indexes I on A.aggregate_id = I.aggregate_id 
      WHERE             index_field = '#{self.to_s}.#{index_field_name}' 
      AND               #{self.compute_index_column_name(query_value)} <= ? "
    end




    def self.compute_index_column_name(field)
      return 'INDEX_VALUE_INTEGER' if field.is_a? Fixnum
      return 'INDEX_VALUE_DECIMAL' if field.is_a? BigDecimal
      'INDEX_VALUE_TEXT'
    end


    def self.get_objects_for_in index_field_name, *args
      Aggregate.get_for_indexed_multiple_values(  self.get_sql_for_in(index_field_name, args.last), self)
    end

    def self.get_objects_for_is index_field_name, query_value
      Aggregate.get_for_indexed_single_value(  self.get_sql_for_is(index_field_name, query_value), query_value, self)
    end

    def self.get_objects_for_gt index_field_name, query_value
      Aggregate.get_for_indexed_single_value(  self.get_sql_for_gt(index_field_name, query_value), query_value, self)
    end

    def self.get_objects_for_ge index_field_name, query_value
      Aggregate.get_for_indexed_single_value( self.get_sql_for_ge(index_field_name, query_value), query_value, self)
    end

    def self.get_objects_for_ll index_field_name, query_value
      Aggregate.get_for_indexed_single_value( self.get_sql_for_lt(index_field_name, query_value), query_value, self)
    end

    def self.get_objects_for_le index_field_name, query_value
      Aggregate.get_for_indexed_single_value( self.get_sql_for_le(index_field_name, query_value) , query_value, self)
    end


    def aggregate_type
      self.class      
    end


    def to_h 
      @data
    end


    def self.all
      Aggregate.where(self)
    end


    def self.init_schema fields
      schema_error_messages =  SchemaValidation.validate_schema(fields)
      if schema_error_messages.length > 0
        raise ArgumentError, "The schema for #{self} had the following error(s): #{pp schema_error_messages}"
      end
      @@fields[self] ||= fields 
    end

    def self.init_indexes index_fields
      @@indexes ||= Hash.new
      # index_error_messages =  IndexValidation.validate_indexes(index_fields)
      # if index_error_messages.length > 0
      #   raise ArgumentError, "The declared indexes for #{self} had the following error(s): #{pp index_error_messages}"
      # end
      @@indexes[self] ||= index_fields 
    end


 
    def self.load_from_hash the_class, string_hash

      data_hash = HashUtil.symbolize_keys(string_hash)


      if  (data_hash.keys.include?(:aggregate_info) == false)  && (the_class.included_modules.include?(CommandPost::Identity) == true)
        data_hash[:aggregate_info] = Hash.new
        data_hash[:aggregate_info][:aggregate_type] = the_class.to_s
        data_hash[:aggregate_info][:version] = 1 
        data_hash[:aggregate_info][:aggregate_id] = SequenceGenerator.aggregate_id
      end


      object =  the_class.new
      object.set_data  data_hash
      object.populate_auto_load_fields #unless self.bypass_auto_load == true
      object.populate_local_persistent_objects
      # if (the_class.included_modules.include?(CommandPost::Identity) == true)
      #   object.set_aggregate_lookup_value
      # end
      object
    end


    def self.bypass_auto_load
      @@bypass ||= Hash.new
      @@bypass[self] ||= false 
      @@bypass[self]
    end

    
    def self.bypass_auto_load=(value)
      @@bypass ||= Hash.new
      @@bypass[self]=value 
    end


    def self.upcase? field_name
      raise ArgumentError ,"field not found " if (schema.keys.include?(field_name) == false) 
      field_info = schema[field_name]
      field_info.keys.include?(:upcase) ? field_info[:upcase] : false
    end

  end
end