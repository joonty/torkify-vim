require 'shellwords'

module Torkify::Vim
  class RemoteError < StandardError
  end

  class Remote
    def self.servers
      `vim --serverlist`.split("\n")
    end

    def self.from_first_server
      servers = self.servers
      if servers.any?
        new(self.servers.first)
      else
        raise RemoteError, "No vim servers are available"
      end
    end

    def initialize(servername)
      @servername = servername
      ping
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
      cmd << " #{Shellwords.escape(argument)} 2>&1"
      puts cmd
      parse_output(`#{cmd}`)
    end

    def parse_output(output)
      output = output.strip
      if output =~ /^E\d+:/
        raise RemoteError, output
      else
        output
      end
    end

    def ping
      expr("winnr()")
    end
  end
end
