# frozen_string_literal: true

require 'thor'

module Shinka
  # Handle the application command line parsing
  # and the dispatch to various command objects
  #
  # @api public
  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    desc 'version', 'shinka version'
    def version
      require_relative 'version'
      puts "v#{Shinka::VERSION}"
    end
    map %w(--version -v) => :version

    desc 'update', 'Command description...'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    def update(*)
      if options[:help]
        invoke :help, ['update']
      else
        require_relative 'commands/update'
        Shinka::Commands::Update.new(options).execute
      end
    end
  end
end
