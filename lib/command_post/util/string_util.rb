

module CommandPost
  class StringUtil

    def self.to_camel_case(field, upcase)
      string = field.to_s
      upcase == true ? string.upcase : string.split('_').collect{|x| x.slice(0,1).capitalize + x.slice(1..-1) }.join()  
    end

    def self.to_label(field, upcase)
      string = field.to_s
       upcase == true ? string.upcase : string.split('_').collect{|x| x.slice(0,1).capitalize + x.slice(1..-1) }.join(' ')  
    end


  end  
end