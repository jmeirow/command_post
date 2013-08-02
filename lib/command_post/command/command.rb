require 'pp'
require_relative '../lib/string_util.rb'
require_relative '../event_sourcing/aggregate_event.rb'



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
      persistent_class.schema.each do |form_field, form_field_info|
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



      fields = persistent_class.schema.keys.collect {|field| ":#{field}" }

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

      persistent_class.schema.each do |field_name, field_info|


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
        persistent_class.schema.each do |form_field, form_field_info|
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


      object.set_aggregate_lookup_value


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





end





 
























