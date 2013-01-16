module MCollective
  module Util
    module IPTables
      class IPv4
        def initialize
          configure
        end

        def configure
          @iptables_cmd = Config.instance.pluginconf.fetch("iptables.iptables", "/sbin/iptables")
          @logger_cmd = Config.instance.pluginconf.fetch("iptables.logger", "/usr/bin/logger")
          @chain = Config.instance.pluginconf.fetch("iptables.chain", "junk_filter")
          @target = Config.instance.pluginconf.fetch("iptables.target", "DROP")
        end

        def activate?
          cmd = File.executable?(@iptables_cmd)
          chain = cmd && (Shell.new("#{@iptables_cmd} -L #{@chain} -n").runcommand.exitstatus == 0)

          Log.warn("Could not find iptables command %s" % @iptables_cmd) unless cmd
          Log.warn("Could not find chain %s" % @chain) unless chain

          cmd && chain
        end

        def listblocked
          iptables_output = ""
          status = Shell.new("#{@iptables_cmd} -L #{@chain} -n 2>&1", :stdout => iptables_output, :chomp => true).runcommand

          unless status.exitstatus == 0
            raise "iptables returned %d" % status.exitstatus
          end

          parse_iptables_list(iptables_output)
        end

        def blocked?(ip)
          listblocked.include?(ip)
        end

        # returns an array with members:
        #
        #  - true or false indicating success
        #  - a human readable string of status
        #  - blocked?(ip)
        def block(ip)
          return([false, "#{ip} is already blocked", true]) if blocked?(ip)

          iptables_output = ""

          Shell.new("#{@iptables_cmd} -A #{@chain} -s #{ip} -j #{@target} 2>&1", :stdout => iptables_output, :chomp => true).runcommand
          Shell.new("#{@logger_cmd} -i -t mcollective 'Attempted to add #{ip} to iptables #{@chain} chain on #{Socket.gethostname}'").runcommand

          blocked = blocked?(ip)

          if blocked
            iptables_output = "#{ip} was blocked" if iptables_output == ""
          else
            return([false, "still unblocked, iptables output: '%s'" % iptables_output, true])
          end

          [true, iptables_output, blocked]
        end

        # returns an array with members:
        #
        #  - true or false indicating success
        #  - a human readable string of status
        #  - blocked?(ip)
        def unblock(ip)
          return([false, "#{ip} is already unblocked", false]) unless blocked?(ip)

          iptables_output = ""

          Shell.new("#{@iptables_cmd} -D #{@chain} -s #{ip} -j #{@target} 2>&1", :stdout => iptables_output, :chomp => true).runcommand
          Shell.new("#{@logger_cmd} -i -t mcollective 'Attempted to remove #{ip} from iptables #{@chain} chain on #{Socket.gethostname}'")

          blocked = blocked?(ip)

          if blocked
            raise "still blocked, iptables output: '%s'" % iptables_output
          else
            iptables_output = "#{ip} was unblocked" if iptables_output == ""
          end

          [true, iptables_output, blocked]
        end

        def parse_iptables_list(output)
          output.split("\n").grep(/^#{@target}/).map{|l| l.split(/\s+/)[3]}
        end
      end
    end
  end
end
