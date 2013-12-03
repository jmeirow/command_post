
module CommandPost

  class Connection

    class << self
      attr_accessor :connection_string
    end

    def self.db_cqrs
      cs = connection_string || "postgres://localhost/cqrs?user=postgres&password=#{ENV['password']}"
      Sequel.connect(cs)
    end

  end

end
