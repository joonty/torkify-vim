require 'torkify'
require 'torkify/log/test_error'

module Torkify::Vim
  class ErrorSplitter
    def self.delimiter
      "================"
    end

    def call(error)
      split_text = error.text.split("\n")
      split_text.map { |text|
        Torkify::Log::TestError.new(error.filename,
                                    error.lnum,
                                    text,
                                    error.type)
      } << Torkify::Log::TestError.new(error.filename,
                                       error.lnum,
                                       self.class.delimiter,
                                       error.type)
    end
  end
end
