require_relative './schema_validation'
require_relative './data_validation'
require_relative './auto_load'


module CommandPost

  class Persistence 
    include SchemaValidation
    include DataValidation
    include AutoLoad

    def initialize 

      @@fields ||= Hash.new
      @@indexes ||= Hash.new
      @aggregate_info_set = false
      @data = Hash.new
      self.class.init_schema self.class.schema
      self.class.init_indexes self.class.indexes
      Command.auto_generate self.class
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

    def self.get_index_sql  name, values
        
      "SELECT  aggregate_id FROM    aggregate_indexes WHERE   index_field = '#{name}' AND     index_value in (#{self.stringify_values(values)}) "
    end


    def self.get_ids_for_index index_name, *args

      values = args[0][0]
      name = "#{self.to_s}.#{index_name.to_s.sub(/_in$/,'')}"
      sql = get_index_sql name, values
      results = Array.new 
      $DB.fetch(sql) do |row|
        results << row[:aggregate_id]
      end

      results

    end


    def self.method_missing nm, *args , &block
      name = nm.to_s
      search_index = name.gsub(/_in/,'').to_sym
      if (name.end_with?('_in') && self.indexes.include?(search_index))
        ids =  self.get_ids_for_index nm, args
        return ids
      else 
        begin
          super
        rescue Exception => e
          puts "DEBUG:   PRINTING BACKTRACE  #{'=' * 80}"
           puts e.backtrace
        end
      end
    end


    def method_missing(nm, *args)

      name = nm.to_s
      error_msg = "SCHEMA ERROR:  #{name} is not a defined attribute of or index on '#{self.class.to_s}'"
      
      if name.end_with?('=') == false
        if @data.keys.include? nm
            get_data nm
        else 
          if schema_fields.keys.include? nm 
            return nil
          else
            begin
              super
            rescue Exception => e
              raise error_msg
            end
          end
        end
      else
        nm = name.gsub(/\=/,'').to_sym
        raise  error_msg unless schema_fields.keys.include?(nm)  
        @data[nm] = args.first
      end
    end


    def aggregate_type
      self.class      
      #@data[:aggregate_info][:aggregate_type]
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