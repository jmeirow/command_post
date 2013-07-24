require 'date'
require 'rspec'
require_relative '../persistence/persistence.rb'
require_relative '../identity/identity.rb'


describe CommandPost::Persistence do 

  context 'schema validation' do 
  
    it 'should complain if the schema is bad' do

      class SomeClass < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
          fields = Hash.new
          fields[ 'first_name'        ] = { :required => true,       :type => String,    :location => :local  } 
          fields[ 'last_name'         ] = { :required => true,       :type => String,    :location => :local  } 
          self.class.init_schema fields  
        end
      end


      some_class = SomeClass.new 
      some_class.class.should eq(SomeClass)

    end










    it 'should raise an error when a instance of String is not used to identify a field.' do 
 
      class SomeClass < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
          fields = Hash.new
          fields[ String              ] = { :required => true,       :type => String,    :location => :local  } 
          fields[ 'last_name'         ] = { :required => true,       :type => String,    :location => :local  } 
          self.class.init_schema fields 
        end
      end

      expect { some_class = SomeClass.new }.to raise_error 

    end







    it 'should raise an error when a keyword requires a value of true or false but gets neither.'  do 
 
      class SomeClass < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
          fields = Hash.new
          fields[ 'first_name'        ] = { :required => flase,      :type => String,    :location => :local  } 
          fields[ 'last_name'         ] = { :required => true,       :type => String,    :location => :local  }  
          self.class.init_schema fields 
        end
      end

      expect { some_class = SomeClass.new }.to raise_error 

    end







    it 'should raise an error when a :location gets neither :remote or :local for a value.'  do 
 
      class SomeClass < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
          fields = Hash.new
          fields[ 'first_name'        ] = { :required => true,        :type => String,    :location => :x  } 
          fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  }  
          self.class.init_schema fields 
        end
      end

      expect { some_class = SomeClass.new }.to raise_error 

    end







    it 'should raise an error when a :auto_load is true but type is not an CommandPost::Identity class.'  do 
 
      class SomeClass < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
          fields = Hash.new
          fields[ 'first_name'        ] = { :required => true,       :type => String,    :location => :local, :auto_load => true  } 
          fields[ 'last_name'         ] = { :required => true,       :type => String,    :location => :local  } 

          self.class.init_schema fields 
        end
      end

      expect { some_class = SomeClass.new }.to raise_error 

    end







    it 'should raise an error when a :auto_load is true, :type is Array and :of is not supplied.'  do 
 
      class SomeClass < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
          fields = Hash.new
          fields[ 'first_name'        ] = { :required => true,        :type => Array,     :location => :remote,   :auto_load => true  } 
          fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  } 

          self.class.init_schema fields 
        end
      end

      expect { some_class = SomeClass.new }.to raise_error 

    end

 





    it 'should raise an error when a :auto_load is true, :type is Array, :of is supplied but its value is not an CommandPost::Identity class.'  do 
 
      class SomeClass < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
          fields = Hash.new
          fields[ 'first_name'        ] = { :required => false,       :type => Array,   :of => String,  :location => :remote, :auto_load => true  } 
          fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  } 

          self.class.init_schema fields 
        end
      end

      expect { some_class = SomeClass.new }.to raise_error 

    end






    it 'should raise an error when a :auto_load is true, :type is Array, :of is supplied but its value is Persistent, but not an CommandPost::Identity class.'  do 
 

      class Helper < CommandPost::Persistence 
      end 

      class SomeClass < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
          fields = Hash.new
          fields[ 'first_name'        ] = { :required => true,        :type => Array,   :of => Helper,  :location => :remote, :auto_load => true  } 
          fields[ 'last_name'         ] = { :required => true,        :type => String,                  :location => :local  } 

          self.class.init_schema fields 
        end
      end

      expect { some_class = SomeClass.new }.to raise_error 

    end


 



    it 'should raise an error when a :auto_load is true,  its value is Persistent, but not an CommandPost::Identity class.'  do 
 

      class Helper < CommandPost::Persistence 
      end 

      class SomeClass < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
          fields = Hash.new
          fields[ 'first_name'        ] = { :required => true,        :type => Helper,    :location => :remote, :auto_load => true  } 
          fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  } 

          self.class.init_schema fields 
        end
      end

      expect { some_class = SomeClass.new }.to raise_error 

    end




    it 'should raise an error when an CommandPost::Identity class is the :type and location is :local.'  do 
 

      class Helper < CommandPost::Persistence
        include CommandPost::Identity 
      end 

      class SomeClass < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
          fields = Hash.new
          fields[ 'first_name'        ] = { :required => true,        :type => Helper,    :location => :local   } 
          fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  } 
          self.class.init_schema fields 
        end
      end

      expect { some_class = SomeClass.new }.to raise_error 

    end

  end 


end


 
