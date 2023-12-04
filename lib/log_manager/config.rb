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

      check: {
        block_threshold: 0.8,
        inode_threshold: 0.8,
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

    attr_reader :path, :log_file

    def initialize(path)
      @path = path
      @config = hash_deep_merge(DEFAULT_CONFIG, load_config)

      if @config[:root_dir].nil? || @config[:root_dir].empty?
        raise LogManager::Error,  'no root dir.'
      end

      unless FileTest.directory?(@config[:root_dir])
        raise LogManager::Error,  'root dir is not a directory.'
      end

      @log_file = File.expand_path(@config[:log][:file], @config[:root_dir])

      unless FileTest.directory?(File.dirname(@log_file))
        FileUtils.mkpath(File.dirname(@log_file))
      end

      @logger = Logger.new(@log_file, @config[:log][:shift])
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

    def [](key)
      @config[key]
    end

    def dig(*keys)
      @config.dig(*keys)
    end

    def fetch(*args, &block)
      @config.fetch(*args, &block)
    end

    def load_config
      YAML.safe_load(File.read(path), symbolize_names: true)
    end

    def dump_config
      YAML.dump(hash_stringify_names(masked_config))
    end

    def masked_config
      masked_config = @config
      if @config.dig(:mail, :smtp, :password)
        masked_config = hash_deep_merge(masked_config,
          {mali: {smtp: {password: '********'}}})
      end
      masked_config
    end

    def log(*args, &block)
      @logger.log(*args, &block)
    end
  end
end
