#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), "../../..", "util", "iptables", "ipv4.rb")

module MCollective
  module Util
    module IPTables
      describe IPv4 do
        before do
          Config.any_instance.stubs(:pluginconf).returns({})
          Log.stubs(:warn)

          @shell_status = mock
          @shell = mock

          @shell_status.stubs(:exitstatus).returns(0)
          @shell.stubs(:runcommand).returns(@shell_status)

          @ipv4 = IPv4.new
        end

        describe "#activate?" do
          it "should fail if the command is not found" do
            File.expects(:executable?).returns(false)

            Shell.expects(:new).never

            @ipv4.activate?.should == false
          end

          it "should fail if the chain is not found" do
            @shell_status.expects(:exitstatus).returns(1)
            Shell.expects(:new).with("/sbin/iptables -L junk_filter -n", any_parameters).returns(@shell)

            File.expects(:executable?).returns(true)
            @ipv4.activate?.should == false
          end
          it "should pass if both the command is found and the chain exist" do
            Shell.expects(:new).with("/sbin/iptables -L junk_filter -n", any_parameters).returns(@shell)

            File.expects(:executable?).returns(true)
            @ipv4.activate?.should == true
          end
        end

        describe "#listblocked" do
          it "should fail if the command fails to run" do
            @shell_status.expects(:exitstatus).returns(1)
            Shell.expects(:new).with("/sbin/iptables -L junk_filter -n 2>&1", any_parameters).returns(@shell)

            expect { @ipv4.listblocked }.to raise_error(/iptables returned/)
          end

          it "should parse the iptables output" do
            @ipv4.expects(:parse_iptables_list).returns(["175.45.4.66", "115.236.73.190"])
            Shell.expects(:new).with("/sbin/iptables -L junk_filter -n 2>&1", any_parameters).returns(@shell)

            @ipv4.listblocked.should == ["175.45.4.66", "115.236.73.190"]
          end
        end

        describe "#blocked?" do
          it "should correctly report blocked ip addresses" do
            @ipv4.expects(:listblocked).returns(["175.45.4.66", "115.236.73.190"]).twice
            @ipv4.blocked?("115.236.73.190").should == true
            @ipv4.blocked?("127.0.0.1").should == false
          end
        end

        describe "#block" do
          it "should fail if the IP is already blocked" do
            @ipv4.expects(:blocked?).with("127.0.0.1").returns(true)
            @ipv4.block("127.0.0.1").should == [false, "127.0.0.1 is already blocked", true]
          end

          it "should return the correct data on success" do
            Socket.expects(:gethostname).returns("rspec")
            Shell.expects(:new).with("/sbin/iptables -A junk_filter -s 127.0.0.1 -j DROP 2>&1", any_parameters).returns(@shell)
            Shell.expects(:new).with("/usr/bin/logger -i -t mcollective 'Attempted to add 127.0.0.1 to iptables junk_filter chain on rspec'", any_parameters).returns(@shell)

            @ipv4.expects(:blocked?).with("127.0.0.1").twice.returns(false, true)

            @ipv4.block("127.0.0.1").should == [true, "127.0.0.1 was blocked", true]
          end

          it "should raise on failure" do
            Socket.expects(:gethostname).returns("rspec")
            Shell.expects(:new).with("/sbin/iptables -A junk_filter -s 127.0.0.1 -j DROP 2>&1", any_parameters).returns(@shell)
            Shell.expects(:new).with("/usr/bin/logger -i -t mcollective 'Attempted to add 127.0.0.1 to iptables junk_filter chain on rspec'", any_parameters).returns(@shell)

            @ipv4.expects(:blocked?).with("127.0.0.1").twice.returns(false, false)

            @ipv4.block("127.0.0.1").should == [false, "still unblocked, iptables output: ''", true]
          end
        end

        describe "#unblock" do
          it "should fail if the IP is already unblocked" do
            @ipv4.expects(:blocked?).with("127.0.0.1").returns(false)
            @ipv4.unblock("127.0.0.1").should == [false, "127.0.0.1 is already unblocked", false]
          end

          it "should return the correct data on success" do
            Socket.expects(:gethostname).returns("rspec")
            Shell.expects(:new).with("/sbin/iptables -D junk_filter -s 127.0.0.1 -j DROP 2>&1", any_parameters).returns(@shell)
            Shell.expects(:new).with("/usr/bin/logger -i -t mcollective 'Attempted to remove 127.0.0.1 from iptables junk_filter chain on rspec'", any_parameters).returns(@shell)

            @ipv4.expects(:blocked?).with("127.0.0.1").twice.returns(true, false)

            @ipv4.unblock("127.0.0.1").should == [true, "127.0.0.1 was unblocked", false]
          end

          it "should raise on failure" do
            Socket.expects(:gethostname).returns("rspec")
            Shell.expects(:new).with("/sbin/iptables -D junk_filter -s 127.0.0.1 -j DROP 2>&1", any_parameters).returns(@shell)
            Shell.expects(:new).with("/usr/bin/logger -i -t mcollective 'Attempted to remove 127.0.0.1 from iptables junk_filter chain on rspec'", any_parameters).returns(@shell)

            @ipv4.expects(:blocked?).with("127.0.0.1").twice.returns(true, true)

            expect { @ipv4.unblock("127.0.0.1") }.to raise_error(/still blocked/)
          end
        end

        describe "#parse_iptables_list" do
          it "should parse iptables output correctly" do
            output = "Chain junk_filter (2 references)target     prot opt source               destination\nDROP       all  --  115.236.73.190       0.0.0.0/0\nDROP       all  --  175.45.4.66          0.0.0.0/0\n"

            @ipv4.parse_iptables_list(output).should == ["115.236.73.190", "175.45.4.66"]
          end
        end
      end
    end
  end
end
