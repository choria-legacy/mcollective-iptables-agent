metadata    :name        => "iptables",
            :description => "An agent that manipulates a specific single chain with iptables and ip6tables",
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "ASL 2.0",
            :version     => "3.0.2",
            :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
            :timeout     => 2

requires :mcollective => "2.2.1"

["block", "unblock"].each do |act|
    action act, :description => "#{act.capitalize} an IP" do
        input :ipaddr,
              :prompt      => "IP address",
              :description => "The IP address to #{act}",
              :type        => :string,
              :validation  => :ipaddress,
              :optional    => false,
              :maxlength   => 40

        output :output,
               :description => "Descriptive status of the action",
               :display_as  => "Output",
               :default     => false

        output :blocked,
               :description => "Boolean indication if the IP is blocked or not",
               :display_as  => "Blocked"

        summarize do
            aggregate summary(:blocked)
        end
    end
end

action "listblocked", :description => "Returns list of blocked ips" do
    display :always

    output :blocked,
           :description => "Blocked IPs",
           :display_as  => "Blocked",
           :default     => []
end

action "isblocked", :description => "Check if an IP is blocked" do
    display :always

    input :ipaddr,
          :prompt      => "IP address",
          :description => "The IP address to check",
          :type        => :string,
          :validation  => :ipaddress,
          :optional    => false,
          :maxlength   => 40

    output :blocked,
           :description => "Boolean indication if the IP is blocked or not",
           :display_as  => "Blocked",
           :default     => false

    summarize do
        aggregate summary(:blocked)
    end
end
