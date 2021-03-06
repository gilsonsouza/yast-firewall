# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2017 SUSE LLC
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

require "yast"

module Y2Firewall
  # Class that stores the proposal settings for firewalld during installation.
  class ProposalSettings
    include Yast::Logger
    include Yast::I18n

    # [Boolean] Whether the firewalld service will be enable
    attr_accessor :enable_firewall
    # [Boolean] Whether the sshd service will be enable
    attr_accessor :enable_sshd
    # [Boolean] Whether the ssh port will be opened
    attr_accessor :open_ssh
    # [Boolean] Whether the vnc port will be opened
    attr_accessor :open_vnc
    # [String] Name of the default zone where perform the changes
    attr_accessor :default_zone

    # Constructor
    def initialize
      Yast.import "PackagesProposal"
      Yast.import "ProductFeatures"
      Yast.import "Linuxrc"

      load_features
      enable_firewall! if @enable_firewall
      enable_sshd! if Yast::Linuxrc.usessh || @enable_sshd
      open_ssh! if Yast::Linuxrc.usessh || @open_ssh
      open_vnc! if Yast::Linuxrc.vnc
      # FIXME: obtain from Y2Firewall::Firewalld, control file or allow to
      # chose a different one in the proposal
      @default_zone = "public"
    end

    # Load the default values defined in the control file
    def load_features
      load_feature(:enable_firewall, :enable_firewall)
      load_feature(:firewall_enable_ssh, :open_ssh)
      load_feature(:enable_sshd, :enable_sshd)
    end

    # Services

    # Add the firewall package to be installed and sets the firewalld service
    # to be enabled
    def enable_firewall!
      Yast::PackagesProposal.AddResolvables("firewall", :package, ["firewalld"])

      log.info "Enabling Firewall"
      self.enable_firewall = true
    end

    # Remove the firewalld package from being installed and sets the firewalld
    # service to be disabled
    def disable_firewall!
      Yast::PackagesProposal.RemoveResolvables("firewall", :package, ["firewalld"])
      log.info "Disabling Firewall"
      self.enable_firewall = false
    end

    # Add the openssh package to be installed and sets the sshd service
    # to be enabled
    def enable_sshd!
      Yast::PackagesProposal.AddResolvables("firewall", :package, ["openssh"])
      log.info "Enabling SSHD"
      self.enable_sshd = true
    end

    # Remove the openssh package from being installed and sets the sshd service
    # to be disabled
    def disable_sshd!
      Yast::PackagesProposal.RemoveResolvables("firewall", :package, ["openssh"])
      log.info "Disabling SSHD"
      self.enable_sshd = false
    end

    # Set the ssh port to be opened
    def open_ssh!
      log.info "Opening SSH port"
      self.open_ssh = true
    end

    # Set the ssh port to be closed
    def close_ssh!
      log.info "Opening SSH port"
      self.open_ssh = false
    end

    # Set the vnc port to be opened
    def open_vnc!
      log.info "Close VNC port"
      self.open_vnc = true
    end

    # Set the vnc port to be closed
    def close_vnc!
      log.info "Close VNC port"
      self.open_vnc = false
    end

  private

    def load_feature(feature, to, source: global_section)
      value = Yast::Ops.get(source, feature.to_s)
      public_send("#{to}=", value) unless value.nil?
    end

    def global_section
      Yast::ProductFeatures.GetSection("globals")
    end

    class << self
      def run
        instance.run
      end

      # Singleton instance
      def instance
        create_instance unless @instance
        @instance
      end

      # Enforce a new clean instance
      def create_instance
        @instance = new
      end

      # Make sure only .instance and .create_instance can be used to
      # create objects
      private :new, :allocate
    end
  end
end
