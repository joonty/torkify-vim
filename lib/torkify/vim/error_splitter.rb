require 'torkify'
require 'torkify/log/test_error'

module Torkify::Vim
  class ErrorSplitter
    def delimiter
      "================"
    end

    def call(error)
      split_text = error.text.split("\n")
      split_text.map { |text|
        Torkify::Log::TestError.new(error.filename,
                                    error.lnum,
                                    text,
                                    error.type)
      } << Torkify::Log::TestError.new("", "", delimiter, "")
    end
  end
end
