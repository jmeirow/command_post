require 'pry'
require 'pry-debugger'


module CommandPost

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
      @object = @changes = nil
    end


    def publish 

      if object.data_errors.length > 0
        raise object.data_errors.join(' ')
      end

      #binding.pry

      $DB.transaction do 
        changes =  get_changes(object)
        #binding.pry
        if changes.keys.include?(:aggregate_info) && changes[:aggregate_info][:version] != object.aggregate_info[:version]
          raise "version has changed, RabbitMQ goes here"
        else
          save_event changes
        end
      end
    end



    def compute_changes objects 
      raise "method 'changes' requires one parameter, which must be a Hash." unless objects.class == Hash
      raise "objects hash execpted key :old, which was not found. " unless objects.keys.include?(:old)
      raise "objects hash execpted key :new, which was not found. " unless objects.keys.include?(:new)
      raise "objects are not of same type."  unless objects[:old].class == objects[:new].class 
      
      old_obj = objects[:old].to_h 
      new_obj = objects[:new].to_h
      chgs = Hash.new 

      new_obj.keys.each do |key|
        chgs[key] = new_obj[key] unless old_obj.keys.include?(key) && old_obj[key] == new_obj[key]
      end
      chgs 
    end



    def get_changes object
      chgs = { old: object.class.find(object.aggregate_id),  new: object }
      compute_changes chgs 
    end


    
    def self.publish event 
      event.publish
    end



    def self.get_history_by_aggregate_id aggregate_id 
      hash = Hash.new
      cnt = 0
      results = Array.new 
      $DB.fetch("SELECT  transaction_id, transacted, aggregate_id,  user_id, event_description  FROM aggregate_events WHERE aggregate_id = ? order by transacted",  aggregate_id ) do |row|
        record = Array.new
        record << "=================================================================================================================================="
        record << "== Version: #{cnt += 1} "
        record << "== Change Made By:    #{row[:user_id]}"
        record << "== Transacted: #{row[:transacted]}  "
        record << "== Event Description: #{row[:event_description]}  "
        record << "=================================================================================================================================="
            $DB.fetch("SELECT content  FROM aggregate_events WHERE transaction_id = ?",   row[:transaction_id] ) do |content_row|
              hash = JSON.parse(content_row[:content])
              record << hash.pretty_inspect
            end
        results << record  

      end
      results.reverse  
    end



private
    def save_event change 

      json = JSON.generate(change)
      #binding.pry
      @@prepared_statement.call(
        :aggregate_type => @aggregate_type.to_s, :aggregate_id => @aggregate_id, :content => json, :transaction_id => @transaction_id, :transacted => @transacted, :event_description => @event_description, :user_id => @user_id )
      Aggregate.replace  get_current_object 
    end



    def get_current_object 
      version = 0
      accumulated_object = Hash.new 
      $DB.fetch("SELECT * FROM aggregate_events WHERE aggregate_id = ? order by transacted", @aggregate_id) do |row|
        accumulated_object.merge!(HashUtil.symbolize_keys(JSON.parse(row[:content])))
        aggregate_details = Hash.new
        aggregate_details[:aggregate_type] = row[:aggregate_type]
        aggregate_details[:aggregate_id] = row[:aggregate_id]
        aggregate_details[:version] = "#{version += 1}"  
        aggregate_details[:most_recent_transaction] = row[:transaction_id]
        accumulated_object[:aggregate_info] =  aggregate_details
      end
      accumulated_object 
    end
  end

end 