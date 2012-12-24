module MCollective
  module Validator
    class IpaddressValidator
      require 'ipaddr'

      def self.validate(validator)
        begin
          ip = IPAddr.new(validator)
          raise ValidatorError, "value should be an IP adddress" unless (ip.ipv4? || ip.ipv6?)
        rescue
          raise ValidatorError, "value should be an IP address"
        end

        true
      end
    end
  end
end
