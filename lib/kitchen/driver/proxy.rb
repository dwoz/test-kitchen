# -*- encoding: utf-8 -*-
#
# Author:: Seth Chisamore <schisamo@opscode.com>
#
# Copyright:: Copyright (c) 2013 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "kitchen/driver/ssh_base"
require "kitchen/version"

module Kitchen
  module Driver
    # Simple driver that proxies commands through to a test instance whose
    # lifecycle is not managed by Test Kitchen. This driver is useful for long-
    # lived non-ephemeral test instances that are simply "reset" between test
    # runs. Think executing against devices like network switches--this is why
    # the driver was created.
    #
    # @author Seth Chisamore <schisamo@opscode.com>
    class Proxy < Kitchen::Driver::Base
      plugin_version Kitchen::VERSION

      required_config :host
      default_config :reset_command, nil

      no_parallel_for :create, :destroy

      # (see Base#create)
      def create(state)
        # TODO: Once this isn't using SSHBase, it should call `super` to support pre_create_command.
        state[:hostname] = config[:host]
        state[:username] = config[:username] unless config[:username].nil?
        state[:password] = config[:password] unless config[:password].nil?
        wait_until_ready(state)
        reset_instance(state) if config[:reset_command]
      end

      # (see Base#destroy)
      def destroy(state)
        return if state[:hostname].nil?
        reset_instance(state) if config[:reset_command]
        state.delete(:hostname)
      end

      private

      # Resets the non-Kitchen managed instance using by issuing a command
      # over the transport.
      #
      # @param state [Hash] the state hash
      # @api private
      def reset_instance(state)
        cmd = config[:reset_command]
        info("Resetting instance state with command: #{cmd}")
        instance.transport.connection(state).execute(cmd)
      end

      def wait_until_ready(state)
        instance.transport.connection(state).wait_until_ready
      end

    end
  end
end
