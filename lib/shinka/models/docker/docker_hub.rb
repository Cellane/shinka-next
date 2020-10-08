# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'version_sorter'
require_relative 'docker_image'

module Shinka
  module Models
    class DockerHub < DockerImage
      @@registry_base_url = 'https://registry.hub.docker.com/v2/repositories/'

      def initialize(**args)
        super
        @hub_filter = args[:hub_filter]
      end

      def find_latest_version
        response = JSON.parse(URI.open(registry_url).read, symbolize_names: true)
        matching_versions = response[:results].map { |result| result[:name] }.select { |tag| tag =~ @filter }
        VersionSorter.sort(matching_versions).last
      end

      private

      def registry_url
        url = @@registry_base_url
        url += @repository.split('/').count == 1 ? "/library/#{@repository}" : @repository
        url += '/tags?page_size=100'
        url += "&name=#{@hub_filter}" if @hub_filter
        url
      end
    end
  end
end
