require 'pp'

require "pry"
require 'pry-debugger'


require 'json'
require 'json-schema'
require 'sequel'

Dir.glob(File.expand_path(File.dirname(__FILE__) + '/../../../lib/command_post/config/*.rb')).each {|file| require file }
Dir.glob(File.expand_path(File.dirname(__FILE__) + '/../../../lib/command_post/db/*.rb')).each {|file| require file }
Dir.glob(File.expand_path(File.dirname(__FILE__) + '/../../../lib/command_post/util/*.rb')).each {|file| require file }


module CommandPost
  $DB ||= Connection.db_cqrs
end



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
      if changes
        save_event changes
      elsif object
        if object.data_errors.length > 0
          raise object.data_errors.join(' ')
        end
        @aggregate_lookup_value = object.aggregate_lookup_value
        save_event object.to_h
      else
        raise 'Event has no state to publish.'
      end
    end
    
    def self.publish event 
      event.publish
    end

    



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

      json = JSON.generate(change)
      @@prepared_statement.call(
                            :aggregate_type => @aggregate_type.to_s, 
                            :aggregate_id => @aggregate_id,
                            :content => json, 
                            :transaction_id => @transaction_id, 
                            :transacted => @transacted, 
                            :event_description => @event_description,
                            :user_id => @user_id
                              )
      Aggregate.replace  get_current_object, @aggregate_lookup_value
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

module CommandPost


  $DB ||= Connection.db_cqrs

  class Aggregate   
   
    @@prep_stmt_insert ||= $DB[:aggregates].prepare(:insert,  :insert_aggregate, :aggregate_id => :$aggregate_id, :aggregate_type => :$aggregate_type, :content => :$content, :aggregate_lookup_value => :$aggregate_lookup_value )

    def update_index object, index_value , field
      index_field = "#{object.class.to_s}.#{field.to_s}"
       $DB["UPDATE aggregate_indexes set #{Persistence.compute_index_column_name(field) } = ?  where aggregate_id = ? and index_field = ?", index_value,  aggregate_id.to_i, index_field ].update
    end

    def self.replace object, aggregate_lookup_value
      content = JSON.generate object
      aggregate_id = object[:aggregate_info][:aggregate_id] 
      aggregate_type = object[:aggregate_info][:aggregate_type] 
      version = object[:aggregate_info][:version].to_i


      if (version) == 1
        @@prep_stmt_insert.call(:aggregate_id => aggregate_id.to_i, :aggregate_type => aggregate_type  , :content => content, :aggregate_lookup_value => aggregate_lookup_value  ) 
        
        object = Aggregate.get_by_aggregate_id Object.const_get(aggregate_type), aggregate_id

        object.index_fields.each do |field|
          index_value = object.send field
          index_field = "#{object.class.to_s}.#{field.to_s}"
          $DB["INSERT INTO aggregate_indexes (aggregate_id , #{Persistence.compute_index_column_name(index_value)}, index_field ) values (?, ?, ?) ", aggregate_id,  index_value,  index_field ].insert
        end
      else
        $DB["UPDATE aggregates set content = ?, aggregate_lookup_value = ? where aggregate_id = ?", content,  aggregate_lookup_value,  aggregate_id ].update
        object = Aggregate.get_by_aggregate_id Object.const_get(aggregate_type), aggregate_id
        @@prep_stmt_insert.call(:aggregate_id => aggregate_id.to_i, :aggregate_type => aggregate_type  , :content => content, :aggregate_lookup_value => aggregate_lookup_value  ) 
        object.index_fields.each do |field|
          index_value = object.send field
          update_index object, index_value, field
        end
      end
    end
    


    def self.get_by_aggregate_id aggregate_type ,aggregate_id 
      hash = Hash.new
      $DB.fetch("SELECT * FROM aggregates WHERE aggregate_id = ?",  aggregate_id ) do |row|
        hash = JSON.parse(row[:content])
      end
      aggregate_type.load_from_hash(HashUtil.symbolize_keys(hash))
    end



    def self.where(aggregate_type)
      results = Array.new
      $DB.fetch("SELECT * FROM aggregates WHERE aggregate_type = ?", aggregate_type.to_s) do |row|
        hash =  JSON.parse(row[:content])
        results << aggregate_type.load_from_hash(HashUtil.symbolize_keys(hash))
      end
      results
    end
    

    def self.get_for_indexed_single_value (sql, query_value, aggregate_type)
      results = Array.new
      $DB.fetch(sql, query_value ) do |row|
        hash =  JSON.parse(row[:content])
        results << aggregate_type.load_from_hash(HashUtil.symbolize_keys(hash))
      end
      results


    end

    def self.get_for_indexed_multiple_values (sql, aggregate_type)
      results = Array.new
      $DB.fetch(sql ) do |row|
        hash =  JSON.parse(row[:content])
        results << aggregate_type.load_from_hash(  HashUtil.symbolize_keys(hash))
      end
      results
    end



    def self.exists? aggregate_type, aggregate_lookup_value  
      $DB.fetch("SELECT count(*) as cnt FROM aggregates WHERE aggregate_type = ? and aggregate_lookup_value = ? ", aggregate_type.to_s, aggregate_lookup_value) do |rec|
        return rec[:cnt].to_i > 0
      end
    end
    


    def self.get_aggregate_by_lookup_value aggregate_type, aggregate_lookup_value 
      hash = Hash.new
      $DB.fetch("SELECT content FROM aggregates WHERE aggregate_type = ? and aggregate_lookup_value = ? ", aggregate_type.to_s, aggregate_lookup_value) do |rec|
        hash = JSON.parse(rec[:content])
      end
      if hash.nil? || hash == {}
        {}
      else
        aggregate_type.load_from_hash(  HashUtil.symbolize_keys(hash))
      end
    end
  end

end



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


    def self.auto_generate persistent_class
      @@commands ||= Hash.new 
      return if @@commands.keys.include? persistent_class 
      @@commands[persistent_class] = []
      self.create_field_correction_commands persistent_class
      self.create_aggregate_creation_commands persistent_class
    end 


    def self.create_aggregate_creation_commands persistent_class 


      modules = persistent_class.to_s.split('::').length - 1
      parts = persistent_class.to_s.split('::')
      if parts.length == 1
        name = "Command#{persistent_class.to_s}Create#{persistent_class.to_s}"
      elsif parts.length == 2
        name = "Command#{parts[1]}Create#{parts[1]}"
      end
      klass = Object::const_set(name.intern, Class::new(Command) do end  )

      if modules == 1
        klass.const_set parts[0], klass
      end


      def_init = Array.new 
      def_init <<  "def self.execute params, user_id " 
      def_init << '  AggregateEvent.publish self.create_event( params, user_id)'
      def_init <<  "end "


      klass.instance_eval (def_init.join("\n"))




      def_init = Array.new 

      def_init << 'def self.build_web_submission_form  '
      def_init << "  "

      def_init << "  hash = Hash.new   "
      def_init << "  hash['page_header'] = 'Create Person'"
      def_init << "  hash['command_class'] = '#{klass.to_s}'"


      def_init << "\n"
      def_init << "  hash['current_state'] =  {} "

      def_init << "  hash['new_state']  =  {   "


      current_state = Array.new 
      persistent_class.schema_fields.each do |form_field, form_field_info|
        current_state <<  " '#{form_field}' =>  {     'label' =>   '#{StringUtil.to_label(form_field, persistent_class.upcase?(form_field))}',   'html' =>   \"<input type='text' id='#{form_field}' name='#{form_field}'/>\" } "
      end 

      def_init << current_state.join(",  \n")

      def_init << '   }'

      def_init << "  hash['command_description'] = 'Submit command to create a new #{persistent_class.to_s}.'"
      def_init << "  hash['command_sub_description'] = ''"

      def_init << '  hash '


      def_init << 'end'


      klass.instance_eval (def_init.join("\n"))


      def_init = Array.new 
      def_init << 'def self.validate params'
      def_init << '  []'
      def_init << 'end '

      klass.instance_eval (def_init.join("\n"))



      fields = persistent_class.schema_fields.keys.collect {|field| ":#{field}" }

      array_of_fields = fields.join(',')

      def_init = Array.new 
      def_init << 'def self.fields'
      def_init << "  [#{array_of_fields}]"   # I LEFT OFF HERE - TRYING TO PUT A STRINGIFIED LIST OF SYMBOLS INTO A HASH
      def_init << 'end '

      klass.instance_eval (def_init.join("\n"))


      def_init = Array.new 
      def_init << 'def self.aggregate_type'
      def_init << "  #{persistent_class.to_s}"
      def_init << 'end '

      klass.instance_eval (def_init.join("\n"))


      def_init = Array.new 
      def_init << 'def self.event_description'
      def_init << " Created Person"
      def_init << 'end '

      klass.instance_eval (def_init.join("\n"))

      @@commands[persistent_class] << klass

    end





    def self.create_field_correction_commands persistent_class



      persistent_class.schema_fields.each do |field_name, field_info|


        modules = persistent_class.to_s.split('::').length - 1
        parts = persistent_class.to_s.split('::')

        names = persistent_class.to_s.split('::')
        if modules == 0
          name = "Command#{persistent_class.to_s}Correct#{CommandPost::StringUtil.to_camel_case(field_name,persistent_class.upcase?(field_name))}"
        elsif modules == 1
          name = "Command#{names[1]}Correct#{CommandPost::StringUtil.to_camel_case(field_name,persistent_class.upcase?(field_name))}"
        end

        klass = Object::const_set(name, Class::new(Command) do end  )

        if modules == 1
          klass.const_set parts[0], klass
        end



        def_init = Array.new 
        def_init <<  "def self.execute params, user_id " 
        def_init << '  AggregateEvent.publish self.create_event( params, user_id)'
        def_init <<  "end "
        

        klass.instance_eval (def_init.join("\n"))


        def_init = Array.new 

        def_init << 'def self.get_web_submission_form aggregate_id'
        def_init << "  object = Aggregate.get_by_aggregate_id(#{persistent_class.to_s}, aggregate_id)"
        def_init << "  "

        def_init << "  hash = Hash.new   "


        def_init << "  hash['command_class'] = '#{klass.to_s}'"
        def_init << "  hash['page_header'] = 'Correct #{StringUtil.to_label(field_name, persistent_class.upcase?(field_name))}'"
        def_init << "  hash['command_description'] = 'Command to correct #{field_name}.'"
        def_init << "  hash['command_sub_description'] = ''"
        def_init << "\n"
        def_init << "  hash['current_state'] =  {"




        current_state = Array.new 
        persistent_class.schema_fields.each do |form_field, form_field_info|
          current_state  << "                              '#{StringUtil.to_label(form_field, persistent_class.upcase?(form_field))}' =>  object.#{form_field}.to_s  "
        end 
        def_init << current_state.join(",  ")
        def_init << "                            }  "
        def_init << "  hash['new_state']  =  { } "



        def_init << "  hash"
        def_init << 'end'



  
        klass.instance_eval (def_init.join("\n"))


        def_init = Array.new 
        def_init << 'def self.validate params'
        def_init << ' []'
        def_init << 'end '

        klass.instance_eval (def_init.join("\n"))





        def_init = Array.new 
        def_init << 'def self.fields'
        def_init << "  [:#{field_name}]"
        def_init << 'end '

        klass.instance_eval (def_init.join("\n"))




        def_init = Array.new 
        def_init << 'def self.aggregate_type'
        def_init << "  #{persistent_class.to_s}"
        def_init << 'end '

        klass.instance_eval (def_init.join("\n"))






        def_init = Array.new 
        def_init << 'def self.event_description'
        def_init << " 'Corrected #{field_name}.'"
        def_init << 'end '

        klass.instance_eval (def_init.join("\n"))





        @@commands[persistent_class] << klass

      end

    end





    def self.publish_event command_class, params, user_id 

      event = AggregateEvent.new 
      event.aggregate_type = command_class.aggregate_type
      event.event_description
      #if command_class.to_s.start_with?("Command#{command_class.aggregate_type.to_s}Create")
      event.aggregate_id = 1000
      #end
      event.transaction_id = SequenceGenerator.transaction_id
      event.user_id = user_id
      event.event_description = 'Person created'
      
      object = command_class.aggregate_type.new



      command_class.fields.each do |field|
        info = command_class.aggregate_type.schema[field.to_s]
        if info[:type] == Date 
          dt = Date._parse(params[field])
          date = Date.new(dt[:year], dt[:mon], dt[:mday])
          object.send("#{field.to_s}=".to_sym, date     )
        else
          object.send("#{field.to_s}=".to_sym, params[field])
        end
      end


      if params[:aggregate_id]
        event.aggregate_id = params[:aggregate_id]
        event.object = object
      else 
        event.object = object 
      end 


      event.publish


    end


    
    def self.commands persistent_class
      
      @@commands[persistent_class]

    end
  end


  class SequenceGenerator


    def self.aggregate_id
      @@DB ||= Connection.db_cqrs
      val = 0
      @@DB.fetch("SELECT nextval('aggregate');") do |row|
        val = row[row.keys.first]
      end
      val
    end

    def self.transaction_id
      @@DB ||= Connection.db_cqrs
      val = 0
      @@DB.fetch("SELECT nextval('transaction');") do |row|
        val = row[row.keys.first]
      end
      val
    end

    def self.misc
      @@DB ||= Connection.db_cqrs
      val = 0
      @@DB.fetch("SELECT nextval('misc');") do |row|
        val = row[row.keys.first]
      end
      val
    end
  end

  module Identity

 
    def aggregate_lookup_value
      field = self.class.unique_lookup_value #(schema_fields[:lookup][:use])
      (self.send field.to_sym).to_s
    end

    def aggregate_id 

      @data[:aggregate_info][:aggregate_id]
    end
    

    def aggregate_pointer

      AggregatePointer.new(aggregate_info)
    end
    

    def self.generate_checksum value 
      sha = Digest::SHA2.new
      sha.update(value)
      sha.to_s 
    end
    

    def checksum  
      data = Array.new
      @data.keys.select {|x| x != :aggregate_info}.each {|x| data <<  @data[x] }
      Identity.generate_checksum(data.join())
    end
    

    def self.select (&block) 
      Aggregate.where(self).select
    end
    

    def aggregate_info
      if @data.keys.include? :aggregate_info
        @data[:aggregate_info]
      else
        raise "A request was made for 'AggregateInfo at a time when it was not present in object state."
      end
    end
    

    def self.find aggregate_id

      Aggregate.get_by_aggregate_id self, aggregate_id
    end
  end


  module AutoLoad

    # def auto_load_fields

    #   schema_fields.select {|key, value| value[:auto_load] == true }.keys
    # end
    

    # def local_peristent_fields

    #   schema_fields.select {|key, value| value[:location] == :local && value[:type].superclass == Persistence }.keys
    # end


    # def populate_auto_load_fields 
    #   auto_load_fields.select {|x| @data.keys.include? x}.each do |field|
    #     if @data[field].class == Array
    #       if schema_fields[field][:location] == :remote
    #         array_of_objects = Array.new 
    #         array_of_pointers = @data[field]
    #         array_of_pointers.each do |pointer|
    #           if pointer.respond_to? :aggregate_pointer
    #             pointer = pointer.aggregate_pointer
    #           end
    #           obj =  Aggregate.get_by_aggregate_id(Object.const_get(pointer[:aggregate_type]), pointer[:aggregate_id])
    #           array_of_objects << obj
    #         end
    #         array_of_pointers.clear
    #         @data[field].clear
    #         @data[field] += array_of_objects
    #       end
    #     else
    #       @data[field] = Aggregate.get_by_aggregate_id( schema_fields[field][:type], @data[field][:aggregate_id])
    #     end
    #   end
    # end

    
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


    # def populate_local_persistent_objects
    #   local_peristent_fields.each do |field|
    #     klass = schema_fields[field][:type]
    #     @data[field] = klass.load_from_hash  HashUtil.symbolize_keys(@data[field])
    #     @data[field].populate_local_persitent_objects
    #   end
    # end  
  end


  class Persistence 
    # include SchemaValidation
    # include DataValidation
    include AutoLoad



    

    def initialize 
      set_class_collections
      set_ivars
      initialize_schema_and_indexes
      create_methods
      Command.auto_generate self.class
    end



    def self.schema_fields 
      @@fields[self]
    end


    def index_fields 
      @@indexes[self.class]
    end



    def set_data data_hash
      @data = data_hash
      if @aggregate_info_set == false 
        @aggregate_info_set = true
      end
    end



    def aggregate_type
      self.class      
    end



    def to_h 
      @data
    end



    def self.all
      Aggregate.where(self)
    end







 




    def self.init_schema fields
      @@fields[self] ||= HashUtil.symbolize_keys(fields)[:properties] 
    end



    def self.init_indexes index_fields
      @@indexes ||= Hash.new
      @@indexes[self] ||= index_fields 
    end



    def self.load_aggregate_info data_hash 
      if  (data_hash.keys.include?(:aggregate_info) == false)  && (self.included_modules.include?(CommandPost::Identity) == true)
        data_hash[:aggregate_info] = Hash.new
        data_hash[:aggregate_info][:aggregate_type] = self.to_s
        data_hash[:aggregate_info][:version] = 1 
        data_hash[:aggregate_info][:aggregate_id] = SequenceGenerator.aggregate_id
      end
    end      


 
    def self.load_from_hash  string_hash
      data_hash = HashUtil.symbolize_keys(string_hash)
      self.load_aggregate_info data_hash
      object =  self.new
      object.set_data  data_hash
      object
    end



    def self.bypass_auto_load
      @@bypass ||= Hash.new
      @@bypass[self] ||= false 
      @@bypass[self]
    end


    
    def self.bypass_auto_load=(value)
      @@bypass ||= Hash.new
      @@bypass[self]=value 
    end



    def schema_fields
      @@fields[self.class]
    end

    def self.schema_fields
      @@fields[self]
    end   


    def set_class_collections
      @@fields ||= Hash.new
      @@indexes ||= Hash.new
      @@methods ||= Hash.new 
    end



    def set_ivars
      @aggregate_info_set = false
      @data = Hash.new
    end



    def initialize_schema_and_indexes
      self.class.init_schema self.class.schema
      self.class.init_indexes self.class.indexes
    end



    def create_methods
      return if @@methods[self.class] && @@methods[self.class] == true
      create_data_access_methods 
      create_index_access_methods
    end



    def create_data_access_methods
      create_getters
      create_setters
    end

    def create_getters
      schema_fields.keys.each do |key|
        if schema_fields[key][:type] == 'object'
          self.class.send(:define_method, key) do
            if @data[key].kind_of?CommandPost::Identity
              @data[key]
            else
              if @data[key][:value]
                puts "GETTING FROM CACHED DATA=============================================================="
                @data[key][:value]
              else 
                puts "RETRIEVING FOR FIRST TIME AND CACHING=============================================================="
                pointer = AggregatePointer.new @data[key]
                klass = Object.const_get(schema_fields[key][:class])
                @data[key][:value] = Aggregate.get_by_aggregate_id(klass,pointer.aggregate_id)
              end
            end
          end
        else
          self.class.send(:define_method, key) do 
            @data[key]
          end
        end
      end
    end


    def get_value key,value
      if value.is_a?(CommandPost::Identity) == true 
        @data[key] = value.aggregate_pointer 
      else
        @data[key] =  value 
      end
    end

    def create_setters
      schema_fields.keys.each do |key|
        self.class.send(:define_method, "#{key.to_s}=".to_sym) do |value| 
          get_value key, value
        end
      end
    end


    def create_index_access_methods
      self.index_fields.each do |field|
        self.class.send(:define_singleton_method, "#{field.to_s}_one_of".to_sym) do |values| 
          self.get_objects_for_in field, values
        end
        self.class.send(:define_singleton_method, "#{field.to_s}_is".to_sym) do |value| 
          self.get_objects_for_is field, value
        end
        self.class.send(:define_singleton_method, "#{field.to_s}_eq".to_sym) do |value| 
          self.get_objects_for_is field, value
        end
        self.class.send(:define_singleton_method, "#{field.to_s}_gt".to_sym) do |value| 
          self.get_objects_for_gt field, value
        end    
        self.class.send(:define_singleton_method, "#{field.to_s}_ge".to_sym) do |value| 
          self.get_objects_for_ge field, value
        end    
        self.class.send(:define_singleton_method, "#{field.to_s}_lt".to_sym) do |value| 
          self.get_objects_for_lt field, value
        end    
        self.class.send(:define_singleton_method, "#{field.to_s}_le".to_sym) do |value| 
          self.get_objects_for_le field, value
        end    
      end
      @@methods[self.class] = true
    end


    def self.stringify_values values
      values.collect{|x| "'#{x}'"}.join(',')
    end



    def self.listify(values)
      return values.collect { |x| "'#{x}'"}.join(',') if values.first.is_a? String
      values.join(',')
    end



    def self.get_sql_for_in  index_field_name, query_values
      list = self.listify query_values
      sql = "
      SELECT            A.* 
      FROM              aggregates A 
      INNER JOIN        aggregate_indexes I on A.aggregate_id = I.aggregate_id 
      WHERE             index_field = '#{self.to_s}.#{index_field_name}' 
      AND               #{self.compute_index_column_name(query_values.first)} in (  #{list}  ) "
      sql
    end



    def self.get_sql_for_is  index_field_name , query_value
      "
      SELECT            A.* 
      FROM              aggregates A 
      INNER JOIN        aggregate_indexes I on A.aggregate_id = I.aggregate_id 
      WHERE             index_field = '#{self.to_s}.#{index_field_name}' 
      AND               #{self.compute_index_column_name(query_value)} = ? "
    end



    def self.get_sql_for_gt  index_field_name , query_value
      "
      SELECT            A.* 
      FROM              aggregates A 
      INNER JOIN        aggregate_indexes I on A.aggregate_id = I.aggregate_id 
      WHERE             index_field = '#{self.to_s}.#{index_field_name}' 
      AND               #{self.compute_index_column_name(query_value)} > ? "
    end



    def self.get_sql_for_ge  index_field_name , query_value
      "
      SELECT            A.* 
      FROM              aggregates A 
      INNER JOIN        aggregate_indexes I on A.aggregate_id = I.aggregate_id 
      WHERE             index_field = '#{self.to_s}.#{index_field_name}' 
      AND               #{self.compute_index_column_name(query_value)} >= ? "
    end



    def self.get_sql_for_lt  index_field_name , query_value
      "
      SELECT            A.* 
      FROM              aggregates A 
      INNER JOIN        aggregate_indexes I on A.aggregate_id = I.aggregate_id 
      WHERE             index_field = '#{self.to_s}.#{index_field_name}' 
      AND               #{self.compute_index_column_name(query_value)} < ? "
    end



    def self.get_sql_for_le  index_field_name , query_value
      "
      SELECT            A.* 
      FROM              aggregates A 
      INNER JOIN        aggregate_indexes I on A.aggregate_id = I.aggregate_id 
      WHERE             index_field = '#{self.to_s}.#{index_field_name}' 
      AND               #{self.compute_index_column_name(query_value)} <= ? "
    end




    def self.compute_index_column_name(field)
      return 'INDEX_VALUE_INTEGER' if field.is_a? Fixnum
      return 'INDEX_VALUE_DECIMAL' if field.is_a? BigDecimal
      'INDEX_VALUE_TEXT'
    end



    def self.get_objects_for_in index_field_name, *args
      Aggregate.get_for_indexed_multiple_values(  self.get_sql_for_in(index_field_name, args.last), self)
    end



    def self.get_objects_for_is index_field_name, query_value
      Aggregate.get_for_indexed_single_value(  self.get_sql_for_is(index_field_name, query_value), query_value, self)
    end



    def self.get_objects_for_gt index_field_name, query_value
      Aggregate.get_for_indexed_single_value(  self.get_sql_for_gt(index_field_name, query_value), query_value, self)
    end



    def self.get_objects_for_ge index_field_name, query_value
      Aggregate.get_for_indexed_single_value( self.get_sql_for_ge(index_field_name, query_value), query_value, self)
    end



    def self.get_objects_for_ll index_field_name, query_value
      Aggregate.get_for_indexed_single_value( self.get_sql_for_lt(index_field_name, query_value), query_value, self)
    end



    def self.get_objects_for_le index_field_name, query_value
      Aggregate.get_for_indexed_single_value( self.get_sql_for_le(index_field_name, query_value) , query_value, self)
    end

  
    # def self.schema_errors

    # end    
   
    def data_errors
      JSON::Validator.fully_validate(self.class.schema, HashUtil.stringify_keys(@data),  :errors_as_objects => true, :validate_schema => true)
    end
  end


end











$DB["delete from aggregates"].delete
$DB["delete from aggregate_events"].delete
$DB["delete from aggregate_indexes"].delete




  class Person  <  CommandPost::Persistence
    include  CommandPost::Identity

    def self.upcase? field_name
      raise ArgumentError ,"field '#{field_name}' not found " if (self.schema_fields.include?(field_name) == false) 
      self.schema_fields[field_name].keys.include?(:upcase) ? self.schema_fields[field_name][:upcase] : false
    end


    def initialize 
      super
    end

    def self.schema
      {
        "type"        => "object",

        "required"    => ["first_name", "last_name", "ssn", "age"],
        
        "properties"  => {
          "first_name"    =>  { "type"          =>  "string"              },
        
          "last_name"     =>  { "type"          =>  "string"              }, 
        
          "ssn"           =>  { "type"          =>  "string",        
                                "upcase"        =>  true                  }, 
        
          "age"           =>  { "type"          =>  "integer"             },
        
          "address"       =>  { "type"          => "object",
                                "class"         =>  "Address",
                                "required"    => ["aggregate_type", "aggregate_id", "class_name"],                  
                                "properties"    => {

                                  "aggregate_type"      =>  { "type"          =>  "string"        },
                                  "aggregate_id"        =>  { "type"          =>  "integer"       },
                                  "class_name"          =>  { "type"          =>  "string"        }
              }
            }
          }
      }
    end

    def self.indexes
      [:last_name]
    end

    def self.unique_lookup_value
      :ssn
    end
  end


  class Address  <  CommandPost::Persistence
    include  CommandPost::Identity

    def self.upcase? field_name
      raise ArgumentError ,"field '#{field_name}' not found " if (self.schema_fields.include?(field_name) == false) 
      self.schema_fields[field_name].keys.include?(:upcase) ? self.schema_fields[field_name][:upcase] : false
    end


    def initialize 
      super
    end

    def self.schema
      {
        "title"           => "Address",
        "required"        => ["address_1", "city", "state","zip"],
        "type"            => "object",
        "properties" => {
                          "address_1"     =>  { "type"          =>  "string"        },
                          "address_2"     =>  { "type"          =>  "string"        },
                          "city"          =>  { "type"          =>  "string"        },
                          "state"         =>  { "type"          =>  "string"        },
                          "zip"           =>  { "type"          =>  "string"        }
                           
                        },
      }
    end

    def self.indexes
      []
    end

    def self.unique_lookup_value
      :address_1
    end
  end


  params = {:address_1 => '72422 Campground', :city => 'Romeo',  :state => 'MI', :zip => "48065"}

  a = Address.load_from_hash params


  event = CommandPost::AggregateEvent.new 
  event.aggregate_id = a.aggregate_id
  event.object = a
  event.aggregate_type =  Address
  event.event_description = 'added new address to system'
  event.user_id = 'test' 
  event.publish



  campground = CommandPost::Aggregate.get_by_aggregate_id Address, a.aggregate_id
  pp campground
  puts campground.city




  params = {:first_name => 'Joseph', :last_name => 'Meirow', :age => 50, :ssn => '123456789'}

  p = Person.load_from_hash params
  p.address = a
   


  event = CommandPost::AggregateEvent.new 
  event.aggregate_id = p.aggregate_id
  event.object = p
  event.aggregate_type =  Person
  event.event_description = 'added new person to system'
  event.user_id = 'test' 
  event.publish


  joe = CommandPost::Aggregate.get_aggregate_by_lookup_value Person, '123456789'
  pp joe
  
  
  puts joe.first_name
  puts joe.address.address_1
  puts joe.address.city
  puts joe.address.state
  puts joe.address.zip
  


  

 




