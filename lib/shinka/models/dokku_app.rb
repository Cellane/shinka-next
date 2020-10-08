# frozen_string_literal: true

require 'json'

Dir[File.join(__dir__, 'docker', '*.rb')].sort.each { |file| require file }

module Shinka
  module Models
    class DokkuApp
      attr_reader :name
      attr_reader :image
      attr_reader :deployed_version
      attr_reader :latest_version

      def initialize(name, record)
        image_type = Models.const_get(record[:image][:type].to_s.split('_').collect(&:capitalize).join)
        @name = name
        @image = image_type.new(record[:image])
      end

      def detect_deployed_version
        current_dokku_image_id = `dokku tags #{@name} | grep dokku | grep latest | awk '{ print $3 }'`.strip
        image_history = `docker image history #{current_dokku_image_id} --format "{{json .}}" --no-trunc`
        current_image_id = image_history.split("\n").map { |line| JSON.parse line, symbolize_names: true }
                                        .reject { |line| line[:CreatedBy].include? 'LABEL com.dokku' }
                                        .first[:ID]

        @deployed_version = JSON.parse(`docker image inspect #{current_image_id}`, symbolize_names: true)
                                .first[:RepoTags].first.split(':').last
      end

      def find_latest_version
        @latest_version = @image.find_latest_version
      end

      def updates_available
        return false if deployed_version.nil? || latest_version.nil?

        deployed_version != latest_version
      end
    end
  end
end
