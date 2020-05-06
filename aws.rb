#!/usr/bin/env ruby
require 'aws-sdk'
require 'aws-sdk-ec2'

module Aws
  module EC2
    class Resource
      def self.ttd_region(region_name = 'us-east-1')
        Aws::EC2::Resource.new(region: region_name)
        # @ttd_regions['region'] ||= Aws::EC2::Resource.new(region: region_name) unless @ttd_regions.key?(region_name)
      end

      def self.ttd_instance(name, region = 'us-east-1')
        region = ttd_region(region) if region.is_a?(String)
        name = "#{name}.use.adsrvr.org" unless name.include?('.')
        # @instances[name] ||= region.instances({filters: [{name: 'tag:Name', values: [name]}]}).first
        region.instances({filters: [{name: 'tag:Name', values: [name]}]}).first
      end

      def self.wait_for_instance_state(instance_name, region_name, state, ids)
        begin
          instance = ttd_instance(instance_name, region_name)
          @client.wait_until(state, instance_ids: [ids]) do |w|
            w.max_attempts = 20
            w.delay = 60
          end
          puts "Success: #{state}."
        rescue Aws::Waiters::Errors::WaiterFailed => error
          puts "Failed: #{error.message}"
          raise error
        end
      end
    end

    class Instance
      def instance_name
        tag_named('Name')
      end

      def tag_named(name)
        tags.select { |t| t[:key] == name }.first.dig(:value)
      end

      def stop_instance
        [:stopping, :stopped].include?(instance_state)
        case state.code
        when 48  # terminated
          warn "instance is terminated, so you cannot stop it"
          state.code
        when 64  # stopping
          warn "instance is stopping, so it will be stopped in a bit"
          0 # consider this a successful stop
        when 80  # stopped
          warn "instance is already stopped"
          0 # consider this a successful stop
        else
          warn "stopping"
          result = stop
          result == 64 ? 0 : result
        end
      end

      def start_instance
        warn state.code
        result = start_instance_raw
        # while result != 0
        #   puts 'not ready to start yet'
        #   puts result
        #   sleep 60
        #   result = start_instance_raw
        # end
        result
      end

      def start_instance_raw
        case state.code
        when 0  # pending
          warn "instance is pending, so it will be running in a bit"
          # state.code
          0 # consider this a successful start
        when 16  # started
          warn "instance is already started"
          0 # consider this a successful start
        when 48  # terminated
          warn "instance is terminated, so you cannot start it"
          state.code
        when 64  # stopping
          warn "instance is stopping, so it will be stopped in a bit"
          state.code
        else
          warn "starting"
          start
        end
      end
      # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-lifecycle.html
      def instance_state
        result = {
          0  => :starting, # pending
          16 => :running,
          32 => :terminating, # shutting_down
          48 => :terminated,
          64 => :stopping,
          80 => :stopped
        }[state.code & 255] # ignore high byte
        result || state.code
      end

      def wait_for_instance_state(state)
        ec2 = ec2.client if ec2.is_a?(Aws::EC2::Resource)
        begin
          ec2.wait_until(state, instance_ids: [id]) do |w|
            w.max_attempts = 20
            w.delay = 60
          end
          puts "Success: #{state}."
        rescue Aws::Waiters::Errors::WaiterFailed => error
          puts "Failed: #{error.message}"
          raise error
        end
      end

      # def wait_for(state_name, max_attempts: 20, delay: 60)
      #   succeeded = false
      #   (0..max_attempts).each do
      #     warn "current state: #{instance_state.inspect} (#{state.code})"
      #     if instance_state == state_name
      #       warn "succeeded reaching state #{state}!!!"
      #       succeeded = true
      #       break
      #     end
      #     print '.'
      #     sleep delay
      #   end
      #   raise "instance #{instance_name} failed to reach state #{state_name} after #{max_attempts*delay} seconds" unless succeeded
      # end
    end
  end
end

class AwsEc2
  def initialize
    @regions = {}
    @instances = {}
  end

  def instance_named(name, region = region_named('us-east-1'))
    name = "#{name}.use.adsrvr.org" unless name.include?('.')
    @instances[name] ||= region.instances({filters: [{name: 'tag:Name', values: [name]}]}).first
  end

  def region_named(region = 'us-east-1')
    @regions['region'] ||= Aws::EC2::Resource.new(region: region) unless @regions.key?(region)
  end

  def credentials
    key = ENV['TTD_ACCESS_KEY']
    secret = ENV['TTD_AWS_SECRET_KEY']
    creds ||= creds = Aws::Credentials.new(key, secret)
  end

  def wait_for_instance_state(ec2, state, ids)
    begin
      ec2.wait_until(state, instance_ids: ids) do |w|
        w.max_attempts = 20
        w.delay = 60
      end
      puts "Success: #{state}."
    rescue Aws::Waiters::Errors::WaiterFailed => error
      puts "Failed: #{error.message}"
      raise error
    end
  end
end
