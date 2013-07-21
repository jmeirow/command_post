
module AutoLoad

  def auto_load_fields
    fields = schema_fields.select {|key, value| value[:auto_load] == true }.keys
    fields
  end
  

  def populate_auto_load_fields 
    auto_load_fields.select {|x| @data.keys.include? x}.each do |field|
      puts "auto_loading field...#{field}"
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
        p "debugging"
        p field 
        pp @data
        @data[field] = Aggregate.get_by_aggregate_id(Object.const_get(@data[field]['aggregate_type']), @data[field]['aggregate_id'])
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

  def convert_persitence_objects_to_hash

  end


end