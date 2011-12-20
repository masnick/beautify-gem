module Beautify
  class Bootstrap
    class << self
      def run(options)
        name = 'beautify.do'
        path = File.join(options[:output], name)
        if File.exist?(path) && !(options[:force] == true)
          puts "#{path} already exists. Run command with --force to replace."
          return
        end
        if File.open(path, 'w') do |f|
          f.write("// v" << Beautify::Application.version << "\n" << IO.read(File.join(File.dirname(__FILE__), '..', 'bootstrap', name)))
        end
          puts "#{path} created."
        else
          puts "Could not create #{path}."
        end
      end
    end
  end
end