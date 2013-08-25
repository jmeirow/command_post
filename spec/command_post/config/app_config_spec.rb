require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')


describe AppConfig do 

  it 'should store a value in a property and then retrieve the same value.' do 

    AppConfig.config do 
      parameter  :bounded_context_name
    end


    AppConfig.config do 
      bounded_context_name 'invoicing'
    end
    

    AppConfig.bounded_context_name.must_equal 'invoicing'

  end


end 

