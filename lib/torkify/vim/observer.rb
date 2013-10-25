require_relative "quickfix"
require_relative "remote"
require_relative "error_splitter"

module Torkify::Vim
  class Observer
    attr_reader :quickfix, :split_errors, :split_error_threshold, :me

    def initialize(options = {})
      @vimserver = options[:server]
      @me = "vim-torkify"

      @split_errors = !!options[:split_errors]
      @split_error_threshold = options.fetch(:split_error_threshold, 30).to_i

      detect_server! true
    end

    def detect_server!(first_time = false)
      @quickfix ||= begin
        vim = if @vimserver
          Remote.new(@vimserver)
        else
          Remote.from_first_server
        end
        puts "Found vim server, #{vim}"
        Quickfix::API.new(vim)
      rescue RemoteError => e
        Torkify.logger.error { "#{me}: #{e}" } if first_time
        nil
      end
    end

    def on_idle(event)
      detect_server!
      self
    end

    def on_absorb(event)
      quickfix.clear if quickfix
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
      return unless quickfix
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
