# frozen_string_literal: true

require 'tty-option'
require 'tty-progressbar'
require 'tty-prompt'
require 'tty-table'
require 'yaml'
require_relative '../command'
require_relative '../models/dokku_app'

module Shinka
  module Commands
    class Update < Shinka::Command
      include TTY::Option

      keyword :filename do
        optional
        default 'apps'
      end

      def initialize(options)
        parse
        @options = options
        @prompt = TTY::Prompt.new
      end

      def execute(input: $stdin, output: $stdout)
        elevate_privileges!
        read_apps_config
        initialize_progress_bars
        find_updates
        print_results
        select_updates
        deploy_updates
      end

      private

      def elevate_privileges!
        puts 'Update command needs root privileges to operate. You might be prompted for a password now.'
        `sudo true`
      end

      def initialize_progress_bars
        steps = @apps.count
        @multi_bar = TTY::ProgressBar::Multi.new('Finding updates… [:bar] :elapsed :percent', head: '>')
        @bars = {
          detect_deployed_bar: @multi_bar.register('Detecting currently deployed versions… [:bar] :elapsed :percent', total: steps),
          find_latest_bar: @multi_bar.register('Finding latest versions…               [:bar] :elapsed :percent', total: steps)
        }
      end

      def find_updates
        detect_deployed_thread = Thread.new { detect_deployed_versions }
        find_latest_thread = Thread.new { find_latest_versions }

        [detect_deployed_thread, find_latest_thread].each(&:join)
      end

      def print_results
        header = ['App name', 'Deployed version', 'Latest version']
        rows = @apps.map do |app|
          [app.name, app.deployed_version, app.latest_version].map do |column|
            app.deployed_version == app.latest_version ? column : "\e[1m#{column}\e[22m"
          end
        end

        table = TTY::Table.new header, rows
        puts table.render(:unicode, alignments: %i[left right left], padding: [0, 1])
      end

      def select_updates
        updateable = @apps.select(&:updates_available).map { |app| { app.name => app } }
        options = { cycle: true, filter: true, min: 1 }
        @apps_to_update = @prompt.multi_select('Which apps do you wish to update?', options) do |prompt|
          all_indexes = (1..updateable.count).to_a
          prompt.default *(all_indexes)
          updateable.each { |name, app| prompt.choice name, app }
        end
      end

      def deploy_updates
        multi_bar = TTY::ProgressBar::Multi.new('Deploying updates… [:bar] :elapsed :percent', head: '>')
        @apps_to_update.each { |app| app.register_bar(multi_bar) }
        @apps_to_update.each(&:update)
      end

      def detect_deployed_versions
        @apps.each do |app|
          @bars[:detect_deployed_bar].advance
          app.detect_deployed_version
        end
      end

      def find_latest_versions
        @apps.each do |app|
          @bars[:find_latest_bar].advance
          app.find_latest_version
        end
      end

      def read_apps_config
        file = File.read "#{params[:filename]}.yaml"
        config = YAML.safe_load(file, permitted_classes: [Regexp, Symbol])[:apps]
        @apps = config.map { |name, record| Models::DokkuApp.new(name, record) }
      end
    end
  end
end
