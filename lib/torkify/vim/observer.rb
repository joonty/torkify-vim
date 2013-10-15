require_relative "quickfix"
require_relative "remote"
require_relative "error_splitter"

module Torkify::Vim
  class Observer
    attr_reader :quickfix, :split_errors, :split_error_threshold, :me

    def initialize(options = {})
      vim = if options[:server]
        Remote.new(options[:server])
      else
        Remote.from_first_server
      end

      @me = "vim-torkify"

      @split_errors = !!options[:split_errors]
      @split_error_threshold = options.fetch(:split_error_threshold, 30).to_i

      @quickfix = Quickfix::API.new(vim)
    end

    def on_absorb(event)
      quickfix.clear
      self
    end

    def on_pass(event)
      on_pass_or_fail(event)
      self
    end

    def on_fail(event)
      on_pass_or_fail(event)
      self
    end

    def on_pass_or_fail(event)
      populator = Quickfix::Populator.new(quickfix)
      populator.exclude File.basename(event.log_file.chomp('.log'))

      errors = errors_from_event(event)
      Torkify.logger.debug { "#{me}: number of errors: #{errors.length}" }

      populator.populate errors
      quickfix.open if populator.errors_populated > 0
      self
    end

    def errors_from_event(event)
      if split_errors && event.errors.length < split_error_threshold
        Torkify.logger.debug { "#{me}: number of errors before splitting: #{event.errors.length}" }
        splitter = ErrorSplitter.new
        event.errors.each_with_object([]) { |error, split|
          split.concat(splitter.call(error))
        }
      else
        event.errors
      end
    end
  end
end
