# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'version_sorter'
require_relative 'docker_image'

module Shinka
  module Models
    class TokenPreauth < DockerImage
      def initialize(**args)
        super
        @base_url = args[:base_url]
        @token_endpoint = args[:token_endpoint]
        @token_service = args[:token_service]
        @username = args[:username]
        @password = args[:password]
      end

      def find_latest_version
        token = preauthorize
        opts = { 'Authorization' => "Bearer #{token}" }
        response = JSON.parse(URI.open(registry_url, opts).read, symbolize_names: true)
        matching_versions = response[:tags].select { |tag| tag =~ @filter }
        VersionSorter.sort(matching_versions).last
      end

      def preauthorize
        opts = { http_basic_authentication: [@username, @password] }
        response = JSON.parse(URI.open(token_url, opts).read, symbolize_names: true)
        response[:token]
      end

      def token_url
        "#{@base_url}/#{@token_endpoint}?service=#{@token_service}&scope=repository:#{@repository}"
      end

      def registry_url
        "#{@base_url}/v2/#{@repository}/tags/list"
      end
    end
  end
end
