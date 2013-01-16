#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), "../../", "agent", "iptables.rb")

describe "iptables agent" do
  before do
    agent_file = File.join([File.dirname(__FILE__), "../../agent/iptables.rb"])
    @agent = MCollective::Test::LocalAgentTest.new("iptables", :agent_file => agent_file).plugin

    @manager = stub
    @agent.stubs(:manager_for).returns(@manager)
  end

  describe "#block" do
    it "should block the request using the manager" do
      @manager.expects(:block).with("192.168.1.1").returns([true, "blocked", true])

      result = @agent.call(:block, :ipaddr => "192.168.1.1")

      result.should be_successful
      result.should have_data_items(:output => "blocked", :blocked => true)
    end

    it "should fail on any error" do
      @manager.expects(:block).with("192.168.1.1").returns([false, "rspec", true])

      result = @agent.call(:block, :ipaddr => "192.168.1.1")

      result.should be_aborted_error
      result[:statusmsg].should == "rspec"
    end
  end

  describe "#unblock" do
    it "should unblock the request using the manager" do
      @manager.expects(:unblock).with("192.168.1.1").returns([true, "unblocked", false])

      result = @agent.call(:unblock, :ipaddr => "192.168.1.1")

      result.should be_successful
      result.should have_data_items(:output => "unblocked", :blocked => false)
    end

    it "should fail on any error" do
      @manager.expects(:unblock).with("192.168.1.1").returns([false, "rspec", false])

      result = @agent.call(:unblock, :ipaddr => "192.168.1.1")

      result.should be_aborted_error
      result[:statusmsg].should == "rspec"
    end
  end

  describe "#listblocked" do
    it "should return the lists of both IPv4 and IPv6" do
      @agent.expects(:manager_for).with("127.0.0.1").returns(@manager)
      @agent.expects(:manager_for).with("::1").returns(@manager)
      @manager.expects(:listblocked).returns(["127.0.0.1"])
      @manager.expects(:listblocked).returns(["::1"])

      result = @agent.call(:listblocked)

      result.should be_successful
      result.should have_data_items(:blocked => ["127.0.0.1", "::1"])
    end

    it "should fail on runtime error" do
      @agent.expects(:manager_for).with("127.0.0.1").returns(@manager)
      @agent.expects(:manager_for).with("::1").raises("rspec")

      @manager.expects(:listblocked).returns(["127.0.0.1"])

      result = @agent.call(:listblocked)

      result.should be_aborted_error
      result[:statusmsg].should =~ /Could not list blocked/
    end
  end

  describe "#isblocked" do
    it "should check if it's blocked using the manager" do
      @manager.expects(:blocked?).with("127.0.0.1").returns(true)

      result = @agent.call(:isblocked, :ipaddr => "127.0.0.1")

      result.should be_successful
      result.should have_data_items(:blocked => true)
    end

    it "should fail on runtime error" do
      @manager.expects(:blocked?).with("127.0.0.1").raises("rspec")

      result = @agent.call(:isblocked, :ipaddr => "127.0.0.1")

      result.should be_aborted_error
      result[:statusmsg].should =~ /Could not check if/
    end
  end
end
