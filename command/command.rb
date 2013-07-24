


module CommandPost

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
          hashify_persistent_objects_before_save (object.send field_name.to_sym)
          hash = object.send(field_name.to_sym).to_h
          method_name = "#{field_name}=".to_sym
          object.send(method_name, hash)
        end
      end
    end

  end

end