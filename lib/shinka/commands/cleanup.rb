# frozen_string_literal: true

require 'json'
require 'tty-option'
require 'tty-progressbar'
require 'tty-prompt'
require 'yaml'
require_relative '../command'

module Shinka
  module Commands
    class Cleanup < Shinka::Command
      include TTY::Option

      keyword :filename do
        optional
        default 'apps'
      end

      def initialize(options)
        parse
        @options = options
      end

      def execute(input: $stdin, output: $stdout)
        read_config
        setup_multi_bar
        remove_stopped_containers!
        detect_all_image_ids
        determine_used_image_ids
        determine_removal_choices

        if @removal_choices.empty?
          puts 'No orphaned images were found.'
          return
        end

        select_removal_choices
        perform_removal
      end

      private

      def setup_multi_bar
        multi_bar = TTY::ProgressBar::Multi.new('Collecting required information… [:bar] :elapsed', head: '>')
        container_count = parse_json_output(`docker container ls -a --format "{{json .}}" --no-trunc`).count
        @bars = {
          remove_containers: multi_bar.register('Removing stopped containers… [:bar]', total: 2, width: 20),
          determine_used: multi_bar.register('Determining used images… [:bar]', total: container_count)
        }
      end

      def remove_stopped_containers!
        `docker container prune -f`
        @bars[:remove_containers].advance
        `docker image ls | grep "<none>" | awk '{ print $3; }' | xargs -r docker image rm`
        @bars[:remove_containers].advance
      end

      def detect_all_image_ids
        image_ids_output = `docker image ls --format "{{json .}}" --no-trunc`
        @all_image_ids = parse_json_output(image_ids_output).map { |image| image[:ID] }.uniq
      end

      def determine_used_image_ids
        containers = parse_json_output `docker container ls -a --format "{{json .}}" --no-trunc`
        @used_image_ids = containers.map do |container|
          container_details = parse_json_output(`docker container inspect #{container[:ID]} --format "{{json .}}"`)
          @bars[:determine_used].advance
          [container_details[:Image], detect_root_image(container_details[:Image])]
        end.flatten.uniq.sort
      end

      def determine_removal_choices
        unused_image_ids = @all_image_ids - @used_image_ids
        removal_choices = unused_image_ids.map do |image_id|
          image_details = parse_json_output `docker image inspect #{image_id} --format "{{json .}}"`
          image_details[:RepoTags]
        end
        @removal_choices = removal_choices.flatten.reject do |tag|
          tag =~ %r{dokku/.+:latest} || @ignore_list.any? { |regex| tag.match? regex }
        end
        sort_removal_choices
      end

      def sort_removal_choices
        @removal_choices = @removal_choices.sort_by do |element|
          if element.include? '/'
            repo, name_version = element.split '/'
          else
            repo = nil
            name_version = element
          end
          name, version = name_version.split ':'
          [name, version, repo]
        end
      end

      def select_removal_choices
        prompt = TTY::Prompt.new
        options = { cycle: true, filter: true, min: 1, per_page: 16 }
        @removal_choices = prompt.multi_select('Following images might be unused. Select all you want to remove', options) do |prompt|
          all_indexes = (1..@removal_choices.count).to_a
          prompt.default *(all_indexes)
          @removal_choices.each { |tag| prompt.choice tag }
        end
      end

      def perform_removal
        bar = TTY::ProgressBar.new('Removing orphans… [:bar] :percent', head: '>', total: @removal_choices.count)
        @removal_choices.each do |tag|
          `docker image rm #{tag}`
          bar.advance
        end
      end

      def detect_root_image(image_id)
        history = parse_json_output `docker image history #{image_id} --format "{{json .}}" --no-trunc`
        history.reject { |layer| layer[:CreatedBy].include?('com.dokku') }.first[:ID]
      end

      def parse_json_output(output)
        return JSON.parse output, symbolize_names: true if output.lines.count == 1

        output.split("\n").map { |line| JSON.parse line, symbolize_names: true }
      end

      def read_config
        file = File.read "#{params[:filename]}.yaml"
        @ignore_list = YAML.safe_load(file, permitted_classes: [Regexp, Symbol])[:ignored_images]
      end
    end
  end
end
