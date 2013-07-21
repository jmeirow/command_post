

module DataValidation
  

  def verify_data  
    @data_errors = []
    data_ok = true

    schema_fields.each do |field_name, field_info|
      # are any required fields missing?
      if @data[field_name.to_s].nil? && field_info[:required] == true
        data_ok = false
        @data_errors << "required field '#{field_name}' is missing."
      end

      # if a field's been set, is it the correct type?
      if @data[field_name] != nil && (@data[field_name].class !=  field_info[:type])
        data_ok = false 
        @data_errors << "#{field_name}: expected type: #{field_info[:type].name}, but received type #{@data[field_name].class.name}."
      end

      # if a field's been set, is it the correct type?
      if @data[field_name] != nil && (@data[field_name].class !=  Array &&  field_info[:allowed_values] )
        if field_info[:allowed_values].class != Array 
          data_ok = false 
          @data_errors << "#{field_name}: Allowed Values was declared but values must be supplied in an array."
        end
        if @data[field_name] != nil && ( field_info[:allowed_values].include?(@data[field_name]) == false  )
          data_ok = false 
          @data_errors << "#{field_name}: The value supplied was not in the list of acceptable values."
        end
      end


      if (@data[field_name.to_s] != nil) && (@data[field_name].class == Array) && (field_info[:type] == Array) && (field_info[:local] == true)
        if field_info[:of].nil? || field_info[:of] == nil 
          data_ok = false 
          @data_errors << "#{field_name}: is an Array, but the ':of' keyword was not set to declare the class type for objects in the array."
        else 
          # OK, :of was declared, forge ahead and check any objects in the array for the correct type (these are all local, no worries about aggregate pointer)
          if field_info[:location] == :local
            expected_type = field_info[:of]
            @data[field_name.to_s].each do |object_in_array|
              if object_in_array.class != expected_type 
                data_ok = false 
                @data_errors << "#{field_name} is an Array and all objects should be of type #{expected_type} but one object was of type #{object_in_array.class}."
              end
            end
          end
        end
      end    


      if (@data[field_name.to_s] != nil) && (@data[field_name].class == Array) && (field_info[:type] == Array) && (field_info[:local] == false)
        # OK, :of was declared, forge ahead and check any objects in the array for the correct type (these are all local, no worries about aggregate pointer)
        expected_type = field_info[:of]
        @data[field_name.to_s].each do |object_in_array|
          if (object_in_array.class != expected_type) && (object_in_array.class != AggregatePointer) 
            data_ok = false 
            @data_errors << "#{field_name} is an Array and all objects should be of type #{expected_type} but one object was of type #{object_in_array.class} or of AggregatePointer."
          end
        end
      end 
    end
    data_ok
  end


  def data_errors
    verify_data
    @data_errors
  end


  def empty?

    @data.nil? || @data == {}
  end


  def valid?

    verify_data 
  end



end
