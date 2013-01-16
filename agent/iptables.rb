module MCollective
  module Agent
    class Iptables<RPC::Agent
      activate_when do
        Util.loadclass("MCollective::Util::IPTables::IPv4")
        Util.loadclass("MCollective::Util::IPTables::IPv6")

        logger_cmd = Config.instance.pluginconf.fetch("iptables.logger", "/usr/bin/logger")
        logger = File.executable?(logger_cmd)

        Log.warn("Cannot find logger command at %s" % logger_cmd) unless logger

        Util::IPTables::IPv4.new.activate? && Util::IPTables::IPv6.new.activate? && logger
      end

      action "block" do
        Log.debug("Blocking IP address '%s'" % request[:ipaddr])

        success, reply[:output], reply[:blocked] = manager_for(request[:ipaddr]).block(request[:ipaddr])
        reply.fail!(reply[:output]) unless success
      end

      action "unblock" do
        Log.debug("Unblocking IP address '%s'" % request[:ipaddr])

          success, reply[:output], reply[:blocked] = manager_for(request[:ipaddr]).unblock(request[:ipaddr])
          reply.fail!(reply[:output]) unless success
      end

      action "listblocked" do
        begin
          reply[:blocked] = []
          reply[:blocked].concat(manager_for("127.0.0.1").listblocked)
          reply[:blocked].concat(manager_for("::1").listblocked)
          reply[:blocked].sort!
        rescue RuntimeError => e
          reply.fail! "Could not list blocked IP address: %s: %s" % [e.class, e.to_s]
        end
      end

      action "isblocked" do
        begin
          reply[:blocked] = manager_for(request[:ipaddr]).blocked?(request[:ipaddr])
        rescue RuntimeError => e
          reply.fail! "Could not check if the address is blocked: %s: %s" % [e.class, e.to_s]
        end
      end

      def self.manager_for(ip)
        require 'ipaddr'

        addr = IPAddr.new(ip)

        return Util::IPTables::IPv4.new if addr.ipv4?
        return Util::IPTables::IPv6.new if addr.ipv6?

        raise "Do not know how to process ip address '%s'" % ip
      end

      def manager_for(ip)
        Iptables.manager_for(ip)
      end
    end
  end
end
