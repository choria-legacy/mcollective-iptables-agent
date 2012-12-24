#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), "../../..", "util", "iptables", "ipv4.rb")
require File.join(File.dirname(__FILE__), "../../..", "util", "iptables", "ipv6.rb")

module MCollective
  module Util
    module IPTables
      describe IPv6 do
        before do
          Config.any_instance.stubs(:pluginconf).returns({})
          @ipv6 = IPv6.new
        end

        describe "#parse_iptables_list" do
          it "should parse iptables output correctly" do
            output = "Chain junk_filter (2 references)\ntarget     prot opt source               destination\nDROP       all      2a00:1450:4002:802::1001/128  ::/0\nDROP       all      2a00:1450:4002:802::1002/128  ::/0\n"


            @ipv6.parse_iptables_list(output).should == ["2a00:1450:4002:802::1001", "2a00:1450:4002:802::1002"]
          end
        end
      end
    end
  end
end
