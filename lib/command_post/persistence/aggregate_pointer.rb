
module CommandPost


  class AggregatePointer  < Hash
    attr_accessor :aggregate_type, :aggregate_id
    
    def initialize hash
        @aggregate_type =         hash[:aggregate_type]
        @aggregate_id =           hash[:aggregate_id]
        self[:aggregate_type] =  hash[:aggregate_type]
        self[:aggregate_id] =    hash[:aggregate_id]
        self[:class_name] =      'AggregatePointer'
    end 

  end

end