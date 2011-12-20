require 'rubygems'
require 'trollop'

require 'beautify/helpers'
include Beautify::Helpers

module Beautify
  # Does setup, calls appropriate method based on CLI args
  class Application
    SUB_COMMANDS = %w(bootstrap stata)
    class << self
      @@version # Read version once on start

      def start
        v = version
        global_opts = Trollop::options do
          banner <<-EOF
 _                      _   _  __       
| |__   ___  __ _ _   _| |_(_)/ _|_   _ 
| '_ \\ / _ \\/ _` | | | | __| | |_| | | |
| |_) |  __/ (_| | |_| | |_| |  _| |_| |
|_.__/ \\___|\\__,_|\\__,_|\\__|_|_|  \\__, | v#{v}
                                  |___/ 

  Usage:
     beautify stata --data /path/to/stata/output.txt       \\
                    --template /path/to/template.yml       \\
                    --output /path/to/desired/output/folder

   -OR-

     beautify bootstrap [--output /path/to/bootstrap]

  Description:

     The `stata` subcommand is what you run from your .do file.

     The `bootstrap` subcommand is what you run to set up beautify.

To show help:

EOF
          # opt :dry_run, "Don't actually do anything", :short => "-n"
          stop_on SUB_COMMANDS
        end

        cmd = ARGV.shift # get the subcommand
        cmd_opts = case cmd
          when "bootstrap"

            # Define options
            opts = Trollop::options do
              opt :force, "Force deletion"
              opt :output, "Path to save output.", :type => :string
            end

            # Validation
            Trollop::die :output, "is required" unless opts[:output]
            Trollop::die :output, "must be a directory" unless File.directory?(opts[:output])

            # Go!
            require 'beautify/bootstrap'
            Beautify::Bootstrap.run(opts)

          when "stata"

            # Define options
            opts = Trollop::options do
              opt :data, "Path to Stata output file.", :type => :string
              opt :template, "Path to template file.", :type => :string
              opt :output, "Path to save output.", :type => :string
            end

            # Validation
            [:data, :template, :output].each do |option|
              Trollop::die option, "is required" unless opts[option]
            end
            [:data, :template].each do |option|
              Trollop::die option, "must be a path to a file" unless File.exist?(opts[option])
            end
            Trollop::die :output, "must be a directory" unless File.directory?(opts[:output])

            # Go!
            require 'beautify/stata'
            Beautify::Stata.run(opts)
          else
            Trollop::die "unknown subcommand \"#{cmd.inspect}\""
          end

        # puts "Global options: #{global_opts.inspect}"
        # puts "Subcommand: #{cmd.inspect}"
        # puts "Subcommand options: #{cmd_opts.inspect}"
        # puts "Remaining arguments: #{ARGV.inspect}"
      end
      def version
        @@version ||= IO.read(File.join(File.dirname(__FILE__), '../..', 'VERSION'))
      end
    end
  end
end