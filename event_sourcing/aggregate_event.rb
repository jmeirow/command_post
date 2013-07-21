require_relative './aggregate.rb'


class AggregateEvent  

  attr_accessor :aggregate_type, :aggregate_id, :content, :transaction_id, :transacted, :event_description , :object, :changes, :user_id, :call_stack

  @@prepared_statement ||= $DB[:aggregate_events].prepare(:insert,  :insert_aggregate_event, 
                                          :aggregate_type => :$aggregate_type, 
                                          :aggregate_id => :$aggregate_id, 
                                          :content => :$content, 
                                          :transaction_id => :$transaction_id, 
                                          :transacted => :$transacted, 
                                          :event_description => :$event_description,
                                          :user_id => :$user_id   )
  @@required_by_txn = [ "aggregate_type", "aggregate_id", "event_description", "content", "transaction_id", "transacted" ]

  def initialize
    @transaction_id = SequenceGenerator.transaction_id
    @transacted = Time.now 
    @object = nil
    @changes = nil
  end

  def publish 
    if changes
      save_event_changes
    elsif object
      save_event object.to_h
    else
      raise 'Event has no state to publish.'
    end
  end


  # def mutate
  #   @call_stack = caller if $debug
  #   if changes.class != Hash 
  #     raise "changes must be a Hash."
  #   end
  #   klass = Object.const_get(aggregate_type)
  #   if changes.keys.length != (klass.schema_fields.keys & changes.keys).length
  #     raise "Invalid fields in assignment"
  #   else 
  #     changes.each do |k,v|
  #      raise ("Invalid type assigned to #{k}") if v.class != klass.schema_fields[k]['type']
  #     end
  #   end
  #   save_event changes   
  # end


  # def create 
  #   @call_stack = caller if $debug
  #   if object.kind_of?(Persistence) == false
  #     raise "object must be of type Persistence."
  #   end
  #   # if object.valid? == false 
  #   #   raise "object #{object.class} is invalid. #{object.data_errors}" 
  #   # end
  #   save_event object.to_h
  # end




  def self.get_history_by_aggregate_id aggregate_id 
    hash = Hash.new
    cnt = 0
    results = Array.new 
    $DB.fetch("SELECT * FROM aggregate_events WHERE aggregate_id = ? order by transacted",  aggregate_id ) do |row|
      hash = JSON.parse(row[:content])
      results << "==================================================================================="
      results << "Version: #{cnt += 1} "
      results << "Event Description: #{row[:event_description]}  "
      results << "Change Made By:    #{row[:user_id]}"
      results << "------   change data ------------"
      results << hash.pretty_inspect
    end
    results
  end



  private
  def save_event change 
    content = change
    json = JSON.generate(content)
    @@prepared_statement.call(
                          :aggregate_type => @aggregate_type, 
                          :aggregate_id => @aggregate_id,
                          :content => json, 
                          :transaction_id => @transaction_id, 
                          :transacted => @transacted, 
                          :event_description => @event_description,
                          :user_id => @user_id
                            )
    Aggregate.replace  get_current_object
  end



  def get_current_object 

    version = 0
    accumulated_object = Hash.new 
    $DB.fetch("SELECT * FROM aggregate_events WHERE aggregate_id = ? order by transacted", @aggregate_id) do |row|
      accumulated_object.merge!(JSON.parse(row[:content]))
      aggregate_details = Hash.new
      aggregate_details["aggregate_type"] = row[:aggregate_type]
      aggregate_details["aggregate_id"] = row[:aggregate_id]
      aggregate_details["version"] = "#{version += 1}"  
      aggregate_details["most_recent_transaction"] = row[:transaction_id]
      accumulated_object["aggregate_info"] =  aggregate_details
    end
    accumulated_object 
  end
end