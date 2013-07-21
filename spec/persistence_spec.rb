require 'date'
require_relative './spike.rb'

 
  
  results = Hash.new 
  cnt = 0
  




  # ==> 1
    class SomeClass < Persistence 
    include Identity

    def initialize
      @data = Hash.new
      @aggregate_info_set = false
      init_schema
    end

    def init_schema

      fields = Hash.new
      fields[ 'first_name'        ] = { :required => true,       :type => String,    :location => :local  } 
      fields[ 'last_name'         ] = { :required => true,       :type => String,    :location => :local  } 
      self.class.init_schema fields 
    end
  end
  begin 
    puts test =  "\n\n=====================  TEST  #{cnt+=1}   ========================"

    c = SomeClass.new 
  rescue 

    results[cnt] = test
  end






  # ==> 2
  class SomeClass < Persistence 
    include Identity

    def initialize
      @data = Hash.new
      @aggregate_info_set = false
      init_schema
    end

    def init_schema

      fields = Hash.new
      fields[ String              ] = { :required => true,       :type => String,    :location => :local  } 
      fields[ 'last_name'         ] = { :required => true,       :type => String,    :location => :local  } 
      self.class.init_schema fields 
    end
  end
  begin 
    puts test =  "\n\n=====================  TEST  #{cnt+=1}   ========================"
    c = SomeClass.new 
    results[test] = 'failed'  
  rescue 
  end






  # ==> 3
  class SomeClass < Persistence 
    include Identity

    def initialize
      @data = Hash.new
      @aggregate_info_set = false
      init_schema
    end

    def init_schema

      fields = Hash.new
      fields[ 'first_name'        ] = { :required => :flase,       :type => String,    :location => :local  } 
      fields[ 'last_name'         ] = { :required => true,       :type => String,    :location => :local  } 
      self.class.init_schema fields 
    end
  end
  begin 
    puts test =  "\n\n=====================  TEST  #{cnt+=1}   ========================"
    c = SomeClass.new 
    results[cnt] = test
  rescue 
  end




  # ==> 4
  class SomeClass < Persistence 
    include Identity

    def initialize
      @data = Hash.new
      @aggregate_info_set = false
      init_schema
    end

    def init_schema

      fields = Hash.new
      fields[ 'first_name'        ] = { :reeequired => false,       :type => String,    :location => :local  } 
      fields[ 'last_name'         ] = { :required => true,           :type => String,    :location => :local  } 
      self.class.init_schema fields 
    end
  end
  begin 
    puts test =  "\n\n=====================  TEST  #{cnt+=1}   ========================"
    c = SomeClass.new 
    results[cnt] = test
  rescue 
  end

  # ==> 5
  class SomeClass < Persistence 
    include Identity

    def initialize
      @data = Hash.new
      @aggregate_info_set = false
      init_schema
    end

    def init_schema

      fields = Hash.new
      fields[ 'first_name'        ] = { :required => false,       :type => String,    :location => :x  } 
      fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  } 
      self.class.init_schema fields 
    end
  end
  begin 
    puts test =  "\n\n=====================  TEST  #{cnt+=1}   ========================"
    c = SomeClass.new 
    results[cnt] = test
  rescue 
  end



  # ==> 6
  class SomeClass < Persistence 
    include Identity

    def initialize
      @data = Hash.new
      @aggregate_info_set = false
      init_schema
    end

    def init_schema
      fields = Hash.new
      fields[ 'first_name'        ] = { :required => false,       :type => String,    :location => :local, :auto_load => true  } 
      fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  } 
      self.class.init_schema fields 
    end
  end
  begin 
    c = SomeClass.new 
    puts test =  "\n\n=====================  TEST  #{cnt+=1}   ========================"
    results[cnt] = test
  rescue 
  end


  # ==> 7
  class SomeClass < Persistence 
    include Identity

    def initialize
      @data = Hash.new
      @aggregate_info_set = false
      init_schema
    end

    def init_schema

      fields = Hash.new
      fields[ 'first_name'        ] = { :required => false,       :type => String,    :location => :remote, :auto_load => true  } 
      fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  } 
      self.class.init_schema fields 
    end
  end
  begin 
    puts test =  "\n\n=====================  TEST  #{cnt+=1}   ========================"
    c = SomeClass.new 
    results[cnt] = test
  rescue 
  end

  # ==> 8
  class SomeClass < Persistence 
    include Identity

    def initialize
      @data = Hash.new
      @aggregate_info_set = false
      init_schema
    end

    def init_schema

      fields = Hash.new
      fields[ 'first_name'        ] = { :required => false,       :type => Array,     :location => :remote, :auto_load => true  } 
      fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  } 
      self.class.init_schema fields 
    end
  end
  begin 
    puts test =  "\n\n=====================  TEST  #{cnt+=1}   ========================"
    c = SomeClass.new 
    results[cnt] = test
  rescue 
  end


    
  # ==> 9
  class SomeClass < Persistence 
    include Identity

    def initialize
      @data = Hash.new
      @aggregate_info_set = false
      init_schema
    end

    def init_schema

      fields = Hash.new
      fields[ 'first_name'        ] = { :required => false,       :type => Array,   :of => String,  :location => :remote, :auto_load => true  } 
      fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  } 
      self.class.init_schema fields 
    end
  end
  begin 
    puts test =  "\n\n=====================  TEST  #{cnt+=1}   ========================"
    c = SomeClass.new 
    results[cnt] = test
  rescue 
  end



  # ==> 9
  class Helper < Persistence 
  end 
  class SomeClass < Persistence 
    include Identity

    def initialize
      @data = Hash.new
      @aggregate_info_set = false
      init_schema
    end

    def init_schema

      fields = Hash.new
      fields[ 'first_name'        ] = { :required => false,       :type => Array,   :of => Helper,  :location => :remote, :auto_load => true  } 
      fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  } 
      self.class.init_schema fields 
    end
  end
  begin 
    puts test =  "\n\n=====================  TEST  #{cnt+=1}   ========================"
    c = SomeClass.new 
    results[cnt] = test
  rescue 
  end






  # ==> 10
  class Helper < Persistence 
  end 
  class SomeClass < Persistence 
    include Identity

    def initialize
      @data = Hash.new
      @aggregate_info_set = false
      init_schema
    end

    def init_schema

      fields = Hash.new
      fields[ 'first_name'        ] = { :required => false,       :type => Helper,    :location => :remote, :auto_load => true  } 
      fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  } 
      self.class.init_schema fields 
    end
  end
  begin 
    puts test =  "\n\n=====================  TEST  #{cnt+=1}   ========================"
    c = SomeClass.new 
    results[cnt] = test
  rescue 
  end






  # ==> 11
  class Helper2 < Persistence 
    include Identity
  end 
  class SomeClass < Persistence 
    include Identity

    def initialize
      @data = Hash.new
      @aggregate_info_set = false
      init_schema
    end

    def init_schema

      fields = Hash.new
      fields[ 'first_name'        ] = { :required => true,        :type => Helper2,    :location => :local   } 
      fields[ 'last_name'         ] = { :required => true,        :type => String,    :location => :local  } 
      self.class.init_schema fields 
    end
  end
  begin 
    puts test =  "\n\n=====================  TEST  #{cnt+=1}   ========================"
    c = SomeClass.new 
    results[cnt] = test
  rescue 
  end


  module A
  end

  class B
    include A
  end

  x = B.new 
  puts "is x an A?  #{x.is_a? A}"
  puts "is B an A?  #{B.is_a? A}"

