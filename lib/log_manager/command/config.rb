# frozen_string_literal: true

require 'logger'
require 'yaml'
require 'json'
require 'fileutils'

require 'log_manager/error'
require 'log_manager/utils'

module LogManager
  module Command
    class Config
      include Utils

      DEFAULT_CONFIG = {
        root_dir: 'var/log',

        logger: {
          file: 'log_manarger/log_manager.log',
          level: Logger::INFO, # 1
          shift: 'weekly',
        },

        clean: {
          period_retention: 60 * 60 * 24 * 366 * 2, # 2 years
          period_nocompress: 60 * 60 * 24 * 2,      # 2 days
          compress: {
            cmd: 'gzip',
            ext: '.gz',
            ext_list: %w[.gz .bz2 .xz .tgz .tbz .txz .zip .7z],
          },
        },

        rsync: {
          cmd: 'rsync',
          save_dir: 'rsync',
          hosts: [],
        },

        scp: {
          ssh_cmd: 'ssh',
          scp_cmd: 'scp',
          save_dir: 'scp',
          hosts: [],
        },
      }

      def self.run(**opts)
        config = Config.new(**opts)
        if config.config_path
          puts "# config_path: #{config.config_path}"
        end
        puts config.config_yaml
      end

      attr_reader :logger, :config_path, :config

      def initialize(**opts)
        @subcommand = opts[:subcommand]
        @config_path = opts[:config_path] || search_config_path

        @config = hash_deep_merge(DEFAULT_CONFIG, load_config(@config_path))

        if @config[:logger][:file] && !FileTest.directory?(File.dirname(@config[:logger][:file]))
          FileUtils.mkpath(File.dirname(@config[:logger][:file]))
        end

        logger_file = File.expand_path(@config[:logger][:file],
                                       @config[:root_dir])
        @logger = Logger.new(logger_file, @config[:logger][:shift])
        @logger.level =
          case @config[:logger][:level]
          when Integer then @config[:logger][:level]
          when /^UNKNOWN$/i then Logger::UNKNOWN
          when /^FATAL$/i then Logger::FATAL
          when /^ERROR$/i then Logger::ERROR
          when /^WARN$/i then Logger::WARN
          when /^INFO$/i then Logger::INFO
          when /^DEBUG$/i then Logger::DEBUG
          else
            raise Error, "unknown logger level - #{@config[:logger][:level]}"
          end

        log_info(opts.to_json)
      end

      def search_config_path
        config_path_list = [
          File.expand_path('../../../etc/log_manager.yml', __dir__),
          '/usr/local/etc/log_manager.yml',
          '/usr/etc/log_manager.yml',
          '/etc/log_manager.yml',
        ]
        config_path_list.find do |path|
          FileTest.file?(path)
        end
      end

      def load_config(config_path = @config_path)
        if config_path && File.file?(config_path)
          YAML.safe_load(IO.read(config_path), symbolize_names: true)
        else
          {}
        end
      end

      def log_fatal(msg)
        @logger.log(Logger::FATAL, msg, @subcommand)
      end

      def log_error(msg)
        @logger.log(Logger::ERROR, msg, @subcommand)
      end

      def log_warn(msg)
        @logger.log(Logger::WARN, msg, @subcommand)
      end

      def log_info(msg)
        @logger.log(Logger::INFO, msg, @subcommand)
      end

      def log_debug(msg)
        @logger.log(Logger::DEBUG, msg, @subcommand)
      end

      def config_yaml
        YAML.dump(hash_stringify_names(@config))
      end
    end
  end
end
