# frozen_string_literal: true

module Shinka
  module Models
    class DockerImage
      attr_reader :registry
      attr_reader :filter

      def initialize(**args)
        @registry = args[:registry]
        @filter = args[:filter]
      end

      def find_latest_version
        raise NotImplementedError, 'This method should be overridden by subclasses.'
      end

      private

      def registry_bare_name
        @registry.split('/').last(2).join('/')
      end
    end
  end
end
