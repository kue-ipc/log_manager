require 'logger'
require 'yaml'
require 'json'
require 'fileutils'

require 'log_manager/error'
require 'log_manager/utils'

module LogManager
  class Config
    include Utils

    DEFAULT_CONFIG = {
      log: {
        file: 'log_manager/log_manager.log',
        level: 'info',
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

    attr_reader :path, :config, :log

    def initialize(path)
      @path = path
      @config = hash_deep_merge(DEFAULT_CONFIG, load_config)

      if config[:root_dir].nil? || config[:root_dir].empty?
        raise LogManager::Error,  'root dir is empty.'
      end

      unless FileTest.directory?(config[:root_dir])
        raise LogManager::Error,  'root dir is not a directory.'
      end

      @log_file = File.expand_path(@config[:log][:file], @config[:root_dir])

      unless FileTest.directory?(File.dirname(@log_file))
        FileUtils.mkpath(File.dirname(log_file))
      end

      @logger = Logger.new(log_file, @config[:log][:shift])
      @logger.level =
        case @config[:log][:level]
        when Integer then @config[:log][:level]
        when /^UNKNOWN$/i then Logger::UNKNOWN
        when /^FATAL$/i then Logger::FATAL
        when /^ERROR$/i then Logger::ERROR
        when /^WARN$/i then Logger::WARN
        when /^INFO$/i then Logger::INFO
        when /^DEBUG$/i then Logger::DEBUG
        else
          raise LogManager::Error,
            "unknown logger level - #{@config[:log][:level]}"
        end
    end

    def load_config
      YAML.safe_load(File.read(path), symbolize_names: true)
    end

    def dump_config
      YAML.dump(hash_stringify_names(config))
    end
  end
end
