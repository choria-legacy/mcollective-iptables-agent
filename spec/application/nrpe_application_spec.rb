#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'application', 'iptables.rb')

module MCollective
  class Application
    describe Iptables do
      before do
        application_file = File.join(File.dirname(__FILE__), '../../', 'application', 'iptables.rb')
        @app = MCollective::Test::ApplicationTest.new('iptables', :application_file => application_file).plugin
      end

      describe "#application_description" do
        it "should have a descrption set" do
          @app.should have_a_description
        end
      end

      describe "#validate_configuration" do
        it "should fail if the command is unknown" do
          @app.configuration[:command] = "rspec"
          expect { @app.validate_configuration(@app.configuration) }.to raise_error(/should be one of/)
        end

        it "should fail unless an ip address is set" do
          @app.configuration[:command] = "block"
          @app.configuration[:ipaddress] = nil

          expect { @app.validate_configuration(@app.configuration) }.to raise_error(/provide an IP address/)
        end
      end

      describe "#main" do
        before do
          @rpcclient = mock
          @app.stubs(:halt)
          @app.expects(:rpcclient).returns(@rpcclient)
        end

        it "should support non verbose isblocked display" do
          @rpcclient.stubs(:verbose).returns(false)
          @rpcclient.stubs(:stats).returns({})

          result = [{:data => {:blocked => "blocked"}, :statuscode => 0, :sender => 'rspec1', :statusmsg => 'ok'},
                    {:data => {:blocked => "unblocked"}, :statuscode => 0, :sender => 'rspec2', :statusmsg => 'ok'}]

          @rpcclient.expects(:send).with("isblocked", {:ipaddr => "::1"}).returns(result)

          @app.configuration[:silent] = false
          @app.configuration[:command] = "isblocked"
          @app.configuration[:ipaddress] = "::1"

          @app.expects(:puts).with(regexp_matches(/rspec1.+blocked/)).never
          @app.expects(:puts).with(regexp_matches(/rspec2.+unblocked/))

          @app.main
        end

        it "should support non verbose block and unblock display" do
          @rpcclient.stubs(:verbose).returns(false)
          @rpcclient.stubs(:stats).returns({})

          result = [{:data => {:output => "blocked"}, :statuscode => 0, :sender => 'rspec1', :statusmsg => 'ok'},
                    {:data => {:output => nil}, :statuscode => 1, :sender => 'rspec2', :statusmsg => 'failed'}]

          @rpcclient.expects(:send).with("block", {:ipaddr => "::1"}).returns(result)

          @app.configuration[:silent] = false
          @app.configuration[:command] = "block"
          @app.configuration[:ipaddress] = "::1"

          @app.expects(:puts).with(regexp_matches(/rspec1/)).never
          @app.expects(:puts).with(regexp_matches(/rspec2:\s+failed/))

          @app.main
        end

        it "should support verbose display" do
          @rpcclient.stubs(:verbose).returns(true)
          @rpcclient.stubs(:stats).returns({})

          result = [{:data => {:output => "blocked"}, :statuscode => 0, :sender => 'rspec1', :statusmsg => 'ok'},
                    {:data => {:output => nil}, :statuscode => 1, :sender => 'rspec2', :statusmsg => 'failed'}]

          @rpcclient.expects(:send).with("block", {:ipaddr => "::1"}).returns(result)

          @app.configuration[:silent] = false
          @app.configuration[:command] = "block"
          @app.configuration[:ipaddress] = "::1"

          @app.expects(:puts).with(regexp_matches(/rspec1:\s+blocked/))
          @app.expects(:puts).with(regexp_matches(/rspec2:\s+failed/))

          @app.main
        end

        it "should support silent mode" do
          @app.configuration[:silent] = true
          @app.configuration[:command] = "block"
          @app.configuration[:ipaddress] = "::1"

          @rpcclient.expects(:send).with("block", {:ipaddr => "::1", :process_results => false}).returns("rspec")
          @app.expects(:puts).with(regexp_matches(/Sent request rspec/))

          @app.main
        end
      end
    end
  end
end
