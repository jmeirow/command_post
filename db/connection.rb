
module CommandPost

  class Connection

    def self.db_cqrs
      Sequel.connect("postgres://localhost/cqrs?user=postgres&password=#{ENV['password']}")
    end

  end

end