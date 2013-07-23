

module DataValidation



  def empty?

    @data.nil? || @data == {}
  end

  def valid?
    
    verify_data.length == 0 
  end

  def data_errors

    verify_data
  end
  
  def verify_data  

    errors = Array.new 

    schema_fields.each do |field_name, field_info|
      if missing_required_field(field_name, field_info) 

        errors << "#{self.class}:#{field_name} - is a required field." 
      end
      if data_type_does_not_match_declaration(field_name, field_info) 

        errors << "#{self.class}: #{field_name}: expected type: #{field_info[:type].name}, but received type #{@data[field_name].class.name}."  
      end 
      if allowed_values_declared_but_array_of_values_not_supplied(field_name, field_info) 

        errors << "#{self.class}: #{field_name}: expected type: #{field_info[:type].name}, but received type #{@data[field_name].class.name}."  
      end 
      if value_not_among_the_list_of_allowed_values(field_name, field_info) 

        errors << "#{self.class}: #{field_name}: The value supplied was not in the list of acceptable values."
      end
      if type_is_array_but_keyword___of___not_supplied(field_name, field_info)

        errors << "#{self.class}: #{field_name}: is an Array, but the ':of' keyword was not set to declare the class type for objects in the array."
      end 
      if accepted_values_supplied_but_they_are_not_all_the_same_type(field_name, field_info)
        
        errors << "#{self.class}: #{field_name} is an Array and all objects should be of type #{expected_type} but one object was of type #{object_in_array.class}."
      end
      if field_is_array_of_remote_objects_but_array_has_values_other_than_persistence_or_identity(field_name, field_info)
   
        errors << "#{self.class}: #{field_name} is an Array and all objects should be of type #{expected_type} but one object was of type #{object_in_array.class} or of AggregatePointer." 
      end
    end
    errors 
  end

  def missing_required_field field_name, field_info
    puts "field_name in missing_required_fields check #{field_name}"
    puts "I am in class #{self.class}"
    puts "@data's class is #{@data.class}}"

    @data.keys.include?(field_name)==false && field_info[:required] == true
  end

  def data_type_does_not_match_declaration field_name, field_info

    @data[field_name] != nil  &&  (@data[field_name].class !=  field_info[:type])
  end

  def allowed_values_declared_but_array_of_values_not_supplied field_name, field_info 

    (@data[field_name] != nil)  &&  (@data[field_name].class !=  Array)  &&  (field_info[:allowed_values])  &&  (field_info[:allowed_values].class != Array) 
  end

  def value_not_among_the_list_of_allowed_values field_name, field_info

    (@data[field_name] != nil)  &&  (@data[field_name].class !=  Array)  &&  (field_info[:allowed_values])  &&  (field_info[:allowed_values].include?(@data[field_name]) == false  )
  end

  def type_is_array_but_keyword___of___not_supplied field_name, field_info

    (@data[field_name.to_s] != nil) && (@data[field_name].class == Array) && (field_info[:type] == Array) && (field_info[:local] == true) && ((!field_info.keys.include?(:of)) || field_info[:of].nil?)
  end

  def accepted_values_supplied_but_they_are_not_all_the_same_type(field_name, field_info)
    if (@data[field_name.to_s] != nil) && (@data[field_name].class == Array) && (field_info[:type] == Array) && (field_info[:local] == true)
      if field_info[:location] == :local
        expected_type = field_info[:of]
        @data[field_name.to_s].each do |object_in_array|
          if object_in_array.class != expected_type 
            return true
          end
        end
      end
    end    
  end

  def field_is_array_of_remote_objects_but_array_has_values_other_than_persistence_or_identity(field_name, field_info)
    if (@data[field_name.to_s] != nil) && (@data[field_name].class == Array) && (field_info[:type] == Array) && (field_info[:location] == :remote)
      # OK, :of was declared, forge ahead and check any objects in the array for the correct type (these are all local, no worries about aggregate pointer)
      expected_type = field_info[:of]
      @data[field_name.to_s].each do |object_in_array|
        if (object_in_array.class != expected_type) && (object_in_array.class != AggregatePointer) 
          return ["#{self.class}: #{field_name} is an Array and all objects should be of type #{expected_type} but one object was of type #{object_in_array.class} or of AggregatePointer."]
        end
      end
    end 
  end


end
