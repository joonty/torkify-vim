require 'torkify'
require 'torkify/log/test_error'

module Torkify::Vim
  class ErrorSplitter
    def call(error)
      split_text = error.text.split("\n")
      split_text.map { |text|
        Torkify::Log::TestError.new(error.filename,
                                    error.lnum,
                                    text,
                                    error.type)
      }
    end
  end
end
