
module SchemaValidation

  def self.validate_schema fields 
    errors = Array.new
    fields.keys.each do |field_name| 
      errors += self.validate_field_name field_name
      errors += self.validate_keywords       field_name, fields[field_name] 
      errors += self.validate_required       field_name, fields[field_name] if fields[field_name].keys.include? :required 
      errors += self.validate_type           field_name, fields[field_name] if fields[field_name].keys.include? :type 
      errors += self.validate_location       field_name, fields[field_name] if fields[field_name].keys.include? :location 
      errors += self.validate_auto_load      field_name, fields[field_name] if fields[field_name].keys.include? :auto_load 
      errors += self.validate_allowed_values field_name, fields[field_name] if fields[field_name].keys.include? :allowed_values 
    end
    errors 
  end
  def self.validate_keywords field_name, field_info 
    errors = Array.new 
    keywords = [:required, :type, :of, :location, :auto_load, :allowed_values]
    field_info.keys.each do |key| 
      if keywords.include?(key)==false 
          errors << "Field Name: #{field_name} :  #{key} is an invalid keyword." 
      end
    end
    errors 
  end
  def self.validate_allowed_values field_name, field_info 
    if field_info[:allowed_values].class != Array
       return ["Field Name  '#{field_name}' :   :allowed_values was specified but the allowed_values must be contained in an Array." ]
    end
    types = Hash.new 

    field_info.each{|x| types[x.type] = 0 }
    if types.keys.count != 1
     return ["Field Name  '#{field_name}' :   :allowed_values the values were not all of the same type - or no values were specified. " ]
    end 
    []
  end
  def self.validate_auto_load field_name, field_info 
    if [true,false].include?(field_info[:auto_load])==false
       return ["Field Name  '#{field_name}' :   :auto_load was specified with an invalid value. Must be 'true' or 'false'." ]
    end 
    if (field_info[:type] == Array) 
      if !field_info[:of].kind_of?(Persistence)  == false  
        return ["Field Name  '#{field_name}' :   When :auto_load is true and :type is Array, then :of must be a kind_of Persistence." ]
      end
    else 
      if field_info[:type].superclass.to_s != 'Persistence'
        return ["Field Name  '#{field_name}' :   When :auto_load is true  then :type must be kind_of Persistence." ]
      end 
    end
    []
  end
  def self.validate_location field_name, field_info 
    if [:local,:remote].include?(field_info[:location]) == false
       return ["Field Name  '#{field_name}' :   :location was specified with an invalid value. Must be ':remote' or ':local'." ]
    end 
    if field_info[:location] == :remote
      if (field_info[:type] == Array) 
        if field_info[:of].included_modules.include?(Identity) == false 
          return ["Field Name  '#{field_name}' :   When :location is :remote and :type is Array, then :of must be a type that includes module Identity." ]
        end
      else 
        if field_info[:type].included_modules.include?(Identity) == false 
          return ["Field Name  '#{field_name}' :   When :location is :remote then :type must be a type that includes module Identity." ]
        end 
      end
    else 
      # location is :local
      if (field_info[:type] == Array)

        if field_info[:of].included_modules.include?(Identity) 
          return ["Field Name  '#{field_name}' :   When :location is :local and :type is Array, then :of cannot be an instance of Identity." ]
        end
      else 
        if field_info[:type].included_modules.include?(Identity)  
          return ["Field Name  '#{field_name}' :   When :location is :local then :type cannot be an instance of Identity." ]
        end
      end
    end
    []
  end
  def self.validate_type field_name, field_info 
    if (field_info[:type] == Array) && (field_info.keys.include?(:of) == false)
       return ["Field Name  '#{field_name}' :   :type is Array, but :of is not present. Use ':of => <type>' to decare the type contained by Array." ]
    end
    []
  end
  def self.validate_required field_name, field_info 
    if [true,false].include?(field_info[:required]) == false
       return ["Field Name  '#{field_name}' :   :required was specified with an invalid value. Must be 'true' or 'false'." ]
    end
    []
  end
  def self.validate_field_name field_name  
    if field_name.class != String
       return ["Field Name  '#{field_name}' :   :field_name must be a String." ]
    end
    []
  end


end
