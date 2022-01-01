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
        current_dokku_image_id = `docker image ls | grep "dokku/#{@name} " | grep latest | awk '{ print $3 }'`.strip
        image_details = JSON.parse(`docker image inspect #{current_dokku_image_id}`, symbolize_names: true).first
        original_tags = JSON.parse(image_details.dig(:Config, :Labels, :"com.dokku.docker-image-labeler/alternate-tags"))
        @deployed_version = original_tags.reject { |tag| tag.start_with? 'dokku/' }
                                         .first&.split(':')&.last
      end

      def find_latest_version
        @latest_version = @image.find_latest_version
        @latest_version_dokku_format = @latest_version[/^v?(?:amd64-)?(?:develop-)?(?:nightly-)?(?:preview-)?(?:version-)?([\\.?\d+]+)/, 1] if @latest_version
      end

      def updates_available
        return false if deployed_version.nil? || latest_version.nil?

        deployed_version != latest_version
      end

      def register_bar(multi_bar)
        text = "Updating #{name}…".ljust(40, ' ')
        @bar = multi_bar.register("#{text} [:bar] :elapsed :percent", total: 22)
        @bar.current = 0
      end

      def update
        @last_update_status = deploy_latest_image
      end

      private

      def deploy_latest_image
        cmd = ['dokku', 'git:from-image', @name.to_s, "#{@image.registry}:#{@latest_version}"]
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
