require 'date'
require 'minitest/autorun'
require 'minitest/spec'
require File.expand_path(File.dirname(__FILE__) + '/../persistence')
require File.expand_path(File.dirname(__FILE__) + '/../../identity/identity')


describe CommandPost::Persistence do 

    it 'should complain if the schema is bad' do

      class SomeClass01 < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end

        def self.schema 
          fields = Hash.new
          fields[ :first_name        ] = { :required => true,       :type => String,    :location => :local  } 
          fields[ :last_name         ] = { :required => true,       :type => String,    :location => :local  } 
          fields 
        end
      end
      some_class = SomeClass01.new 
      some_class.class.must_be_same_as SomeClass01
    end


    it 'should raise an error when a instance of Symbol is not used to identify a field.' do 
 
      class SomeClass02 < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end

        def self.schema 
          fields = Hash.new
          fields[ 'first_name'        ] = { :required => true,       :type => String,    :location => :local  } 
          fields[ 'last_name'         ] = { :required => true,       :type => String,    :location => :local  } 
          fields 
        end 
      end

      assert_raises(ArgumentError) { some_class = SomeClass02.new } 
    end


    it 'should raise an error when a keyword requires a value of true or false but gets neither.'  do 
 
      class SomeClass03 < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end
        def self.schema 
          fields = Hash.new
          fields[ :first_name        ] = { :required => :flase,      :type => String,    :location => :local  } 
          fields[ :last_name         ] = { :required => true,       :type => String,    :location => :local  }  
          fields 
        end
      end

      assert_raises(ArgumentError)  { some_class = SomeClass03.new } 
    end


    it 'should raise an error when a :location gets neither :remote or :local for a value.'  do 
 
      class SomeClass04 < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end

        def self.schema 
          fields = Hash.new
          fields[ :first_name        ] = { :required => true,        :type => String,    :location => :x  } 
          fields[ :last_name         ] = { :required => true,        :type => String,    :location => :local  }  
          fields 
        end


      end

      assert_raises(ArgumentError)  { some_class = SomeClass04.new } 
    end


    it 'should raise an error when a :auto_load is true but type is not an CommandPost::Identity class.'  do 
 
      class SomeClass05 < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end

        def self.schema 
          fields = Hash.new
          fields[ :first_name        ] = { :required => true,       :type => String,    :location => :local, :auto_load => true  } 
          fields[ :last_name         ] = { :required => true,       :type => String,    :location => :local  } 
          fields 
        end


      end

      assert_raises(ArgumentError)  { some_class = SomeClass05.new } 
    end


    it 'should raise an error when a :auto_load is true, :type is Array and :of is not supplied.'  do 
 
      class SomeClass06 < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end

        def self.schema 
          fields = Hash.new
          fields[ :first_name        ] = { :required => true,        :type => Array,     :location => :remote,   :auto_load => true  } 
          fields[ :last_name         ] = { :required => true,        :type => String,    :location => :local  } 
          fields 
        end
      end

      assert_raises(ArgumentError)  { some_class = SomeClass06.new } 
    end

 





    it 'should raise an error when a :auto_load is true, :type is Array, :of is supplied but its value is not an CommandPost::Identity class.'  do 
 
      class SomeClass06 < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end

        def self.schema 
          fields = Hash.new
          fields[ :first_name        ] = { :required => false,       :type => Array,   :of => String,  :location => :remote, :auto_load => true  } 
          fields[ :last_name         ] = { :required => true,        :type => String,    :location => :local  } 
          fields 
        end
      end

      assert_raises(ArgumentError)  { some_class = SomeClass06.new } 

    end






    it 'should raise an error when a :auto_load is true, :type is Array, :of is supplied but it is a CommandPost::IdentityPersistent class, not an CommandPost::Identity class.'  do 
 

      class Helper07 < CommandPost::Persistence 
      end 

      class SomeClass07 < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end

        def self.schema 
          fields = Hash.new
          fields[ :first_name        ] = { :required => true,        :type => Array,   :of => Helper07,  :location => :remote, :auto_load => true  } 
          fields[ :last_name         ] = { :required => true,        :type => String,                  :location => :local  } 
          fields 
        end
      end

      assert_raises(ArgumentError)  { some_class = SomeClass07.new } 

    end


 



    it 'should raise an error when a :auto_load is true,  its value is Persistent, but not an CommandPost::Identity class.'  do 
 

      class Helper08 < CommandPost::Persistence 
      end 

      class SomeClass08 < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end

        def self.schema 
          fields = Hash.new
          fields[ :first_name        ] = { :required => true,        :type => Helper08,    :location => :remote, :auto_load => true  } 
          fields[ :last_name         ] = { :required => true,        :type => String,      :location => :local  } 
          fields 
        end
      end

      assert_raises(ArgumentError)  { some_class = SomeClass08.new } 

    end




    it 'should raise an error when an CommandPost::Identity class is the :type and location is :local.'  do 
 

      class Helper09 < CommandPost::Persistence
        include CommandPost::Identity 
      end 

      class SomeClass09 < CommandPost::Persistence 
        include CommandPost::Identity

        def initialize
          super
        end

        def self.schema 
          fields = Hash.new
          fields[ :first_name        ] = { :required => true,        :type => Helper09,    :location => :local   } 
          fields[ :last_name         ] = { :required => true,        :type => String,      :location => :local  } 
          fields 
        end
      end

      assert_raises(ArgumentError)  { some_class = SomeClass09.new } 

    end



end


 
