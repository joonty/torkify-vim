require 'shellwords'

module Torkify::Vim
  class Remote
    def self.servers
      `vim --serverlist`.split("\n")
    end

    def self.from_first_server
      new(self.servers.first)
    end

    def initialize(servername)
      @servername = servername
    end

    def send(keys)
      exec('send', keys)
    end

    def expr(expression)
      exec('expr', expression)
    end

  protected
    def exec(remote_command, argument)
      cmd = "vim --servername #{@servername}"
      cmd << " --remote-#{remote_command}"
      cmd << " #{Shellwords.escape(argument)}"
      `#{cmd}`.strip
    end
  end
end
