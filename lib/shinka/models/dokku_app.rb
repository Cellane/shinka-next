# frozen_string_literal: true

require 'json'
require 'open3'

Dir[File.join(__dir__, 'docker', '*.rb')].sort.each { |file| require file }

module Shinka
  module Models
    class DokkuApp
      attr_reader :name
      attr_reader :deployed_version
      attr_reader :latest_version
      attr_reader :last_update_status

      IGNORED_LAYERS = ['LABEL com.dokku', 'LABEL dokku', 'LABEL org.label-schema.schema-version', 'LABEL org.label-schema.vendor=dokku']

      def initialize(name, record)
        image_type = Models.const_get(record[:image][:type].to_s.split('_').collect(&:capitalize).join)
        @name = name
        @image = image_type.new(record[:image])
      end

      def detect_deployed_version
        current_dokku_image_id = `dokku tags #{@name} | grep dokku | grep latest | awk '{ print $3 }'`.strip
        image_history = `docker image history #{current_dokku_image_id} --format "{{json .}}" --no-trunc`
        current_image_id = image_history.split("\n").map { |line| JSON.parse line, symbolize_names: true }
                                        .reject { |line| IGNORED_LAYERS.any? { |ignored| line[:CreatedBy].include? ignored } }
                                        .first[:ID]

        @deployed_version = JSON.parse(`docker image inspect #{current_image_id}`, symbolize_names: true)
                                .first[:RepoTags].reject { |tag| tag.start_with? 'dokku/' }
                                .first.split(':').last
      end

      def find_latest_version
        @latest_version = @image.find_latest_version
        @latest_version_dokku_format = @latest_version[/^v?([\\.?\d+]+)/, 1] if @latest_version
      end

      def updates_available
        return false if deployed_version.nil? || latest_version.nil?

        deployed_version != latest_version
      end

      def register_bar(multi_bar)
        text = "Updating #{name}…".ljust(40, ' ')
        @bar = multi_bar.register("#{text} [:bar] :elapsed :percent", total: 14, width: 20)
        @bar.current = 0
      end

      def update
        @last_update_status = pull_latest_image && deploy_latest_image
      end

      private

      def pull_latest_image
        system("docker image pull #{@image.registry}:#{@latest_version}", out: File::NULL, err: File::NULL) &&
          @bar.advance &&
          system("docker image tag #{@image.registry}:#{@latest_version} dokku/#{@name}:#{@latest_version_dokku_format}") &&
          @bar.advance
      end

      def deploy_latest_image
        cmd = ['dokku', 'tags:deploy', @name.to_s, @latest_version_dokku_format]
        return_value = nil

        Open3.popen3(*cmd) do |_stdin, stdout, _stderr, thread|
          while (line = stdout.gets)
            @bar.advance if line[/^[-=]{2,}/]
          end
          return_value = thread.value
        end

        @bar.finish
        return_value.success?
      end
    end
  end
end
