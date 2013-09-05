require 'json-schema' 
require_relative './schema_validation'
require_relative './data_validation'
require_relative './auto_load'


module CommandPost

  class Persistence 

    def initialize 
      set_class_collections
      set_ivars
      initialize_schema_and_indexes
      create_methods
      Command.auto_generate self.class
    end



    def self.schema_fields 
      @@fields[self]
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



    def set_ivars
      @aggregate_info_set = false
      @data = Hash.new
      @old_data = Hash.new
    end



    def aggregate_type
      self.class      
    end

    def changes
      chgs = Hash.new
      @old_data.keys.each do |key|
          chgs[key] = {  :old_value =>@old_data[key] , :new_value => @data[key] }
        end
      end
      chgs
    end 




    def to_h 
      @data
    end



    def self.all
      Aggregate.where(self)
    end




    def self.upcase? field 
      info = schema_fields[field]
      info[:upcase] && info[:upcase] == true 
    end


 
    def stringify_keys
      @data = HashUtil.stringify_keys(@data)
    end


    def symbolize_keys
      @data = HashUtil.symbolize_keys(@data)
    end



    def self.init_schema fields
      @@fields[self] ||= fields
    end



    def self.init_indexes index_fields
      @@indexes ||= Hash.new
      @@indexes[self] ||= index_fields 
    end

 

    def self.load_aggregate_info data_hash 
      if  (data_hash.keys.include?(:aggregate_info) == false)  && (self.included_modules.include?(CommandPost::Identity) == true)
        data_hash[:aggregate_info] = Hash.new
        data_hash[:aggregate_info][:aggregate_type] = self.to_s
        data_hash[:aggregate_info][:version] = 1 
        data_hash[:aggregate_info][:aggregate_id] = SequenceGenerator.aggregate_id
      end
    end      


 
    def self.load_from_hash  string_hash
      data_hash = HashUtil.symbolize_keys(string_hash)
      self.load_aggregate_info data_hash
      object =  self.new
      object.set_data  data_hash
      object
    end



    def schema_fields
      @@fields[self.class]
    end



    def self.schema_fields
      @@fields[self]
    end   



    def set_class_collections
      @@fields ||= Hash.new
      @@indexes ||= Hash.new
      @@methods ||= Hash.new 
    end






    def initialize_schema_and_indexes
      self.class.init_schema HashUtil.symbolize_keys(self.class.schema)[:properties]
      self.class.init_indexes self.class.indexes
    end



    def create_methods
      return if @@methods[self.class] && @@methods[self.class] == true
      create_data_access_methods 
      create_index_access_methods
    end



    def create_data_access_methods
      create_getters
      create_setters
    end



    def create_getters
      schema_fields.keys.each do |key|
        if ((schema_fields[key][:type] == 'string' ) && (schema_fields[key][:class] == 'Identity'))
          create_identity_getter key
        else
          self.class.send(:define_method, key) do 
            @data[key]
          end
        end
      end
    end



    def create_identity_getter key 
      self.class.send(:define_method, key) do
        if @data[key][:value]
          @data[key][:value]
        else
          pointer = AggregatePointer.new @data[key]
          klass = Object.const_get(schema_fields[key][:class])
          @data[key][:value] = Aggregate.get_by_aggregate_id(klass,pointer.aggregate_id)
        end
      end
    end


    def get_value key,value
      if value.is_a?(CommandPost::Identity) == true 
        value.aggregate_pointer
      else
        value 
      end
    end


    def changes
      chgs = Hash.new 
      @data.keys.each do |key|
        if @data[key][:original_value]

          chgs[key] = {:old => @data[key][:original_value], :new => @data[:key]}
        end
      end
      chgs 
    end

    def set_values key, value
      old_value = @data[key]
      new_value = get_value key, value
      @old_data[key] = old_value if (old_value != new_value)
      @data[key] = get_value key, value 
    end

    def create_setters
      schema_fields.keys.each do |key|
        self.class.send(:define_method, "#{key.to_s}=".to_sym) do |value| 
          set_values key, value
        end
      end
    end


    def create_index_access_methods
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



    def self.find(aggregate_id)
      Aggregate.get_by_aggregate_id(self,aggregate_id)
    end


    def self.listify(values)
      return values.collect { |x| "'#{x}'"}.join(',') if values.first.is_a? String
      values.join(',')
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



    def self.get_objects_for_lt index_field_name, query_value
      Aggregate.get_for_indexed_single_value( self.get_sql_for_lt(index_field_name, query_value), query_value, self)
    end



    def self.get_objects_for_le index_field_name, query_value
      Aggregate.get_for_indexed_single_value( self.get_sql_for_le(index_field_name, query_value) , query_value, self)
    end



    def data_errors
      JSON::Validator.fully_validate(JSON.generate(self.class.schema), JSON.generate(@data),  :errors_as_objects => true, :validate_schema => true)
    end



    def self.command_create obj, user_id, description
      raise "Type mismatch error! 'obj' was expected to be class #{self}, but was #{obj.class}." if self != obj.class
      event = AggregateEvent.new 
      event.aggregate_id = obj.aggregate_id
      event.object = obj
      event.aggregate_type =  obj.class
      event.event_description = description
      event.user_id = user_id 
      event.publish
      Aggregate.get_by_aggregate_id(self,obj.aggregate_id)
    end
  end
end