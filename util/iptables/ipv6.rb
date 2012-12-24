module MCollective
  module Util
    module IPTables
      class IPv6<IPv4
        def configure
          @iptables_cmd = Config.instance.pluginconf.fetch("iptables.ip6tables", "/sbin/ip6tables")
          @logger_cmd = Config.instance.pluginconf.fetch("iptables.logger", "/usr/bin/logger")
          @chain = Config.instance.pluginconf.fetch("iptables.chain", "junk_filter")
          @target = Config.instance.pluginconf.fetch("iptables.target", "DROP")
        end

        def parse_iptables_list(output)
          output.split("\n").grep(/^#{@target}/).map{|l| l.split(/\s+/)[2].gsub(/\/128$/, "")}
        end
      end
    end
  end
end
