require_relative "quickfix"
require_relative "remote"
require_relative "error_splitter"

module Torkify::Vim
  class Observer
    def initialize(server = nil)
      vim = if server
        Remote.new(server)
      else
        Remote.from_first_server
      end

      @quickfix = Quickfix::API.new(vim)
    end

    def on_pass(event)
      on_pass_or_fail(event)
    end

    def on_fail(event)
      on_pass_or_fail(event)
    end

    def on_pass_or_fail(event)
      populator = Quickfix::Populator.new @quickfix
      populator.exclude File.basename(event.log_file.chomp('.log'))

      puts "Num errors before split: #{event.errors.length}"
      splitter = ErrorSplitter.new
      errors = []
      event.errors.each { |error|
        errors += splitter.call(error)
      }
      puts "Num errors: #{errors.length}"
      populator.populate errors
      @quickfix.open if populator.errors_populated > 0
    end
  end
end
