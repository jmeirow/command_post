require_relative '../event_sourcing/aggregate.rb'
require_relative '../event_sourcing/aggregate_event.rb'
require_relative '../persistence/persistence.rb'
require_relative './schema_validation.rb'
require_relative './data_validation.rb'
require_relative './auto_load.rb'

class Persistence 
  include SchemaValidation
  include DataValidation
  include AutoLoad

  def initialize 
    @@fields ||= Hash.new

    @data = Hash.new
    @aggregate_info_set = false
  end

  def schema_fields 
    
    @@fields[self.class]
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
      if @data[name].class == Hash && @data[name].keys == ['aggregate_type','aggregate_id']  
        Aggregate.get_by_aggregate_id(schema_fields[name][:type], @data[name]['aggregate_id'])
      else 
        @data[name]
      end
    end
  end

  def method_missing(nm, *args)
    # puts "\n\n\n================ START DATA DUMP from #{self.class} ==================="
    # puts "method_missing:  #{nm}, #{args}"
    # puts "class of @data is #{@data.class}"
    # pp @data 

    name = nm.to_s
    if name.end_with?('=') == false
      if @data.keys.include? name
        klass =  schema_fields[name][:type]
        if klass.superclass == Persistence 
          klass.load_from_hash klass, get_data(name)
        else 
          get_data name 
        end
      else 
        if schema_fields.keys.include? name 
          return nil
        else
          begin
            super
          rescue 
            puts "#{nm} is not a defined field in #{self}"
          end
        end
      end
    else
      field_name = name.gsub(/\=/,'')
      if args.first.kind_of?Persistence 
        @data[field_name] = args.first 
      else
        @data[field_name] = args.first
      end
    end
  end

  def aggregate_type
    
    @data['aggregate_info']['aggregate_type']
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
      raise "The schema for #{self} had the following error(s): #{pp schema_error_messages}"
    end
    @@fields[self] ||= fields 
  end

  def self.schema_fields 

    @@fields[self]
  end

  def self.load_from_hash the_class, data_hash
    puts "LOAD FROM HASH INFO"
    puts "MY class is #{self}"
    puts "I am LOADING class #{the_class}"
    puts "the hash = #{data_hash}"
    object =  the_class.new
    object.set_data  data_hash
    object.populate_auto_load_fields #unless self.bypass_auto_load == true
    object.populate_local_persistent_objects
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


end