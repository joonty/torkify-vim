require "json"

module Torkify::Vim::Quickfix
  class API
    def initialize(vim)
      @stringifier = Stringifier.new
      @vim = vim
    end

    def get
      existing = "[" + @vim.expr('getqflist()').gsub(/(?<=})\n(?={)/, ",") + "]"
      qflist = existing.gsub(/(?<=[^\\])"/, '\"')
                       .gsub("'", '"')
                       .gsub("\n", '\n')
      if qflist.length > 0
        JSON.parse(qflist)
      else
        []
      end
    rescue => e
      Torkify.logger.fatal { "Couldn't retrieve vim quickfix list: {#{e.class.name}} #{e.message}" }
      []
    end

    def buffer_from_file(file)
      @vim.expr("bufnr(\"#{file}\")").to_i
    end

    def set(errors)
      error_strings = errors.map { |e| @stringifier.convert e }
      if error_strings.any?
        error_strings.each_slice(100).each_with_index do |strings, i|
          action = i == 0 ? '' : ', "a"'
          @vim.expr("setqflist([#{strings.join(",")}]#{action})")
        end
      else
        clear
      end
    end

    def clear
      @vim.expr("setqflist([])")
      @vim.send ':cclose<CR>'
      self
    end

    def open
      if @vim.expr("mode()") == "n"
        @vim.send ':cw<CR>'
      end
    end
  end

  class Populator
    attr_reader :errors_populated

    def initialize(api)
      @api = api
      @excluded_buffers = []
      @errors_populated = 0
    end

    def exclude(file)
      if file && file.length > 0
        bufnum = @api.buffer_from_file(file)
        if bufnum > 0 && !@excluded_buffers.include?(bufnum)
          @excluded_buffers << bufnum
        end
      end
      self
    end

    def populate(errors)
      determine_excluded_buffers errors
      existing = api.get

      kept_errors = exclude_errors existing
      all_errors = kept_errors + errors
      @errors_populated = all_errors.length

      if error_list_changed?(existing, all_errors)
        api.set kept_errors + errors
      end
      self
    end

  protected
    attr_reader :api, :excluded_buffers

    def error_list_changed?(existing, new)
        existing_msgs = existing.map { |e| e['text'] }.sort
        new_msgs = new.map { |e| e['text'] }.sort
        existing_msgs != new_msgs
    end

    def determine_excluded_buffers(errors)
      unique_file_errors = errors.uniq { |e| e['filename'] }
      unique_file_errors.each { |e| exclude e['filename'] }
    end

    def exclude_errors(errors)
      if errors && errors.any?
        errors.dup.keep_if { |e|
          e['type'] == 'E' && !excluded_buffers.include?(e['bufnr'].to_i)
        }
      else
        []
      end
    end
  end

  class Stringifier
    def convert(enumerable)
      pairs = []
      enumerable.each_pair do |n, v|
        pairs << quote_pair(n, v)
      end
      "{#{pairs.join(",")}}"
    end

  protected
    def quote_pair(name, value)
      "\"#{name}\":\"#{quote value}\""
    end

    def quote(string)
      string.to_s.gsub(/['"\\\x0]/,'\\\\\0')
    end
  end
end

