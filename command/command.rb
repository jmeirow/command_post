

class Command


  def validate_persistent_fields object, errors
    object.schema_fields.each do |field_name, field_info|
      if field_info[:type].superclass == Persistence
        if object.send(field_name.to_sym).valid? == false
          errors += object.send(field_name.to_sym).data_errors
        else
          errors += validate_persistent_fields(object.send(field_name.to_sym), errors)
        end
      end
    end
    errors
  end


  def hashify_persistent_objects_before_save object
    object.schema_fields.each do |field_name, field_info|
      if field_info[:type].superclass == Persistence 
        puts "field_name of persistent object is #{field_name}"
        puts "going off to hashify that object..."
        hashify_persistent_objects_before_save (object.send field_name.to_sym)
        puts "back from validating field #{field_name} of type #{field_info[:type]}"
        puts "the VALUE currently in field_name #{field_name} is type #{object.send(field_name.to_sym).class}"

        hash = object.send(field_name.to_sym).to_h
        pp "hash is class of #{hash.class} #{hash}"
        method_name = "#{field_name}=".to_sym
        object.send(method_name, hash)
        puts "NOW the value currently in field_name #{field_name} is type #{object.send(field_name.to_sym).class}"
      end
    end
  end


end