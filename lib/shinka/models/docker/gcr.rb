# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'version_sorter'
require_relative 'docker_image'

module Shinka
  module Models
    class Gcr < DockerImage
      @@registry_base_url = 'https://gcr.io/v2/'

      def initialize(**args)
        super
        @username = args[:username]
        @password = args[:password]
      end

      def find_latest_version
        opts = {}
        opts[:http_basic_authentication] = [@username, @password] if @username && @password
        registry_url = "#{@@registry_base_url}#{@repository}/tags/list"
        response = URI.open(registry_url, opts).read
        response = JSON.parse(response, symbolize_names: true)
        matching_versions = response[:tags].select { |tag| tag =~ @filter }
        VersionSorter.sort(matching_versions).last
      end
    end
  end
end
