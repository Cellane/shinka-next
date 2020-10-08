# frozen_string_literal: true

module Shinka
  module Models
    class DockerImage
      attr_reader :filter

      def initialize(**args)
        @repository = args[:repository]
        @filter = args[:filter]
      end

      def find_latest_version
        raise NotImplementedError, 'This method should be overridden by subclasses.'
      end
    end
  end
end
