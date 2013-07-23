class CommandToDoSomething



  def initialize  auth_record ,  patient_birth_date , user_id

    raise  ArgumentError.new("Expected AuthRecord") if (auth_record.class != AuthRecord)
    raise  ArgumentError.new("Expected Hash") if (patient_birth_date.class != Hash)
    @auth_record = auth_record
    @patient_birth_date = patient_birth_date
    @user_id = user_id
  end

  def execute 
    event = AggregateEvent.new  
    event.aggregate_id = @auth_record.aggregate_id
    event.aggregate_type = 'AuthRecord'
    event.event_description = "change patient birthdate to elimniate Facets NOF error" 
    event.user_id = @user_id

    current_record_hash = @auth_record.record_hash 


    month = "%02d" % @patient_birth_date[:mon]
    day = "%02d" % @patient_birth_date[:mday]
    year =  @patient_birth_date[:year].to_s.slice(2,2)

    new_date = "#{month}#{day}#{year}"
    puts "NEW DATE IS : #{new_date}"

    current_record_hash['patient_birth_date'] = new_date

    event.changes = {  'record_hash' =>    current_record_hash     }
    event.mutate

    Aggregate.get_by_aggregate_id(AuthRecord,event.aggregate_id)
  end 


  def self.build aggregate_id
      auth_record = AuthRecord.find aggregate_id
      hash = Hash.new 
      hash['aggregate_id'] = aggregate_id
      hash['command_class'] = self.to_s
      hash['page_header'] = 'Claim Authorization Command Processor'
      hash['command_description'] = {'Command Description'  => 'Change the Patient Birth Date on this record in an attempt to get the UMI batch process to match it to Facets.'}
      hash['current_state'] = { 'Root Contract' => auth_record.record_hash['root_contract'], 'Patient First Name' => auth_record.record_hash['patient_first_name'], 'Patient Birth Date' => auth_record.record_hash['patient_birth_date'] }
      hash['new_state'] = {
                            'patient_birth_date' => { 'label' => 'Change Patient Birth Date To',                        'html' => "<input type=text maxlength='10' size='10' id='patient_birth_date' name='patient_birth_date' value='__patient_birth_date__' "},
                            'comments' =>        { 'label' => 'Comments about why this record is being modified', 'html' => "<textarea name='comments' cols='30' rows='4' >__comments__</textarea>" }
                          }

      hash
  end



  def self.execute_instance params , user_id
    auth_record = AuthRecord.find(params[:aggregate_id])
    new_birth_date = Date._strptime(params[:patient_birth_date], "%m/%d/%Y") 
    cmd = self.new auth_record,   new_birth_date , user_id
    cmd.execute 
  end 


  def self.validate params 
    errors = Hash.new 
    if params[:patient_birth_date].strip.length == 0
      errors[:patient_birth_date] = 'Patient Birth Date is required.'
    end
    if Date._strptime(params[:patient_birth_date], "%m/%d/%Y").nil?
      errors[:patient_birth_date] = 'Patient Birth Date must be a valid date.'
    end


    return errors 
  end



end