# MCollective IPTables Agent

## Deprecation Notice

This repository holds legacy code related to The Marionette Collective project.  That project has been deprecated by Puppet Inc and the code donated to the Choria Project.

Please review the [Choria Project Website](https://choria.io) and specifically the [MCollective Deprecation Notice](https://choria.io/mcollective) for further information and details about the future of the MCollective project.

## Overview

This agent manages a specific chain in iptables or ip6tables, you can use it to
add, remove, query or list entries of the chain.

The basic use case is to maintain a blacklist chain from an IDS, Log monitoring
tool like fail2ban or any other system that needs to manipulate remote IP
chains.

It is limited to managing one configured chain to which has to exist before the
agent will activate.

## Setup

The chain you configure has to exist before MCollective start else this agent
will not activate, you can create the chain using your systems RC scripts which
generally runs before the network come up and so also before MCollective start.

     % iptables -N junk_filter
     % ip6tables -N junk_filter

In other chains you can reference the *junk_filter* chain to do allow/deny based
on its contents.

     % iptables -I INPUT -p tcp --dport 22 -j junk_filter
     % iptables -I INPUT -p tcp --dport 22 --syn -j ACCEPT

This will drop all port 22 traffic for hosts listed in the *junk_filter* chain
while allowing connections to port 22 from everywhere else.

You then configure the agent in your *server.cfg* to use the *junk_filter*
chain:

     plugin.iptables.chain = junk_filter
     plugin.iptables.target = DROP

These lines will instruct the agent to add entries to the *junk_filter* chain
with the *DROP* target.

You can also adjust the paths to some commands if your system does not use
standard locations for these:

    plugin.iptables.iptables = /usr/local/bin/iptables
    plugin.iptables.ip6tables = /usr/local/bin/ip6tables
    plugin.iptables.logger = /usr/local/bin/logger

## Usage
The agent include a utility application that simplifies the command line
interaction, the examples show that but you can of course also use normal RPC
application commands.

All of the *mco iptables* commands below also takes a *-s* argument that will
return quicker and not wait for or show any results.  This is ideal for using
in scripts.

### Blocking a host

    % mco iptables block 192.168.1.1

     * [ ============================================================> ] 3 / 3

    Summary of Blocked:

       true = 3

    Finished processing 3 / 3 hosts in 675.95 ms

The equivelant *rpc* command is *mco rpc iptables block ipaddr=192.168.1.1*

### Checking if a host is blocked

    % mco iptables isblocked 192.168.1.1

     * [ ============================================================> ] 3 / 3

                           host1.example.net:  true
                           host2.example.net:  true
                           host3.example.net:  true

    Summary of Blocked:

       true = 3

    Finished processing 3 / 3 hosts in 337.20 ms

The equivelant *rpc* command is *mco rpc iptables isblocked ipaddr=192.168.1.1*

### Unblocking a host

    % mco iptables unblock 192.168.1.1

     * [ ============================================================> ] 3 / 3

    Summary of Blocked:

       false = 3

    Finished processing 3 / 3 hosts in 670.75 ms

The equivelant *rpc* command is *mco rpc iptables unblock ipaddr=192.168.1.1*

### Listing all the blocked IP addresses

The agent can return a list of all blocked IPs on all hosts, this is mostly not
going to be useful on the command line due to the amount of information it
provides.  You can use the *mco rpc iptables listblocked* command to see that on
the CLI.
