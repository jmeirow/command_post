
module CommandPost

  module AutoLoad

     
    
    def to_pretty_pp
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


  

  end
end