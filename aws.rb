#!/usr/bin/env ruby
require 'aws-sdk'
require 'aws-sdk-ec2'

module Aws
  module EC2
    class Instance
      def instance_name
        tag_named('Name')
      end

      def tag_named(name)
        tags.select { |t| t[:key] == name }.first.dig(:value)
      end

      def stop_instance
        case state.code
        when 48  # terminated
          warn "instance is terminated, so you cannot stop it"
          state.code
        when 64  # stopping
          warn "instance is stopping, so it will be stopped in a bit"
          state.code
        when 80  # stopped
          warn "instance is already stopped"
          state.code
        else
          warn "stopping"
          stop
        end
      end

      def start_instance
        case state.code
        when 0  # pending
          warn "instance is pending, so it will be running in a bit"
          state.code
        when 16  # started
          warn "instance is already started"
          # consider this a successful start
          0
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
end
