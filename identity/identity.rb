
module CommandPost


  module Identity

    def aggregate_lookup_value
    
      @data['aggregate_lookup_value']
    end


    def aggregate_id 
      
      @data['aggregate_info']['aggregate_id']
    end
    

    def aggregate_pointer

      AggregatePointer.new(aggregate_info)
    end
    

    def self.generate_checksum value 
      sha = Digest::SHA2.new
      sha.update(value)
      sha.to_s 
    end
    

    def get_checksum  
      data = Array.new
      @data.keys.select {|x| x != 'aggregate_info'}.each {|x| data <<  @data[x] }
      Persistence.generate_checksum(data.join())
    end
    

    def self.select (&block) 
      Aggregate.where(self).select
    end
    

    def aggregate_info
      if @data.keys.include? 'aggregate_info'
        @data['aggregate_info']
      else
        raise "A request was made for 'AggregateInfo at a time when it was not present in object state."
      end
    end
    

    def self.find aggregate_id

      Aggregate.get_by_aggregate_id self, aggregate_id
    end
    

    def set_aggregate_lookup_value_to value

      @data['aggregate_lookup_value'] = value
    end


  end

end
