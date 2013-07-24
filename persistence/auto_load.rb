

module CommandPost

  module AutoLoad

    def auto_load_fields

      schema_fields.select {|key, value| value[:auto_load] == true }.keys
    end
    

    def local_peristent_fields

      schema_fields.select {|key, value| value[:location] == :local && value[:type].superclass == Persistence }.keys
    end

    def populate_auto_load_fields 
      auto_load_fields.select {|x| @data.keys.include? x}.each do |field|
        if @data[field].class == Array
          if schema_fields[field][:location] == :remote
            array_of_objects = Array.new 
            array_of_pointers = @data[field]
            array_of_pointers.each do |pointer|
              if pointer.respond_to? :aggregate_pointer
                pointer = pointer.aggregate_pointer
              end
              obj =  Aggregate.get_by_aggregate_id(Object.const_get(pointer['aggregate_type']), pointer['aggregate_id'])
              array_of_objects << obj
            end
            array_of_pointers.clear
            @data[field].clear
            @data[field] += array_of_objects
          end
        else
          @data[field] = Aggregate.get_by_aggregate_id( schema_fields[field][:type], @data[field]['aggregate_id'])
        end
      end
    end
    
    def to_pretty_pp
      #raise Error "Stop right there! Before you go any further..."
      len = 0
      result  = ''
      @data.keys.map{|key| len = key.length if (key.length > len) }

      @data.keys.reject{|key| /aggregate/.match key}.each do |key|
        label = "%#{len}s :" % key
        if auto_load_fields.include? key 
          result += "\n#{label} (remote object)"
          result += (@data[key]).to_s
        else
          result +=  "#{label} #{@data[key]}"
        end
      end
      result
    end

    def populate_local_persistent_objects
      local_peristent_fields.each do |field|
        klass = schema_fields[field][:type]
        @data[field] = klass.load_from_hash klass, @data[field]
        @data[field].populate_local_persitent_objects
      end
    end  

  end
end