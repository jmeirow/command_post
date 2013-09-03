
Dir.glob(File.expand_path(File.dirname(__FILE__) + '/command_post/*/*.rb')).each {|file| require file; puts file }

module CommandPost

end



