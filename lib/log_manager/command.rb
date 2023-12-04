require 'logger'
require 'optparse'

require 'log_manager'
require 'log_manager/config'
require 'log_manager/command/clean'
require 'log_manager/command/rsync'
require 'log_manager/command/scp'

module LogManager
  module Command
    def self.run(argv, config_path_list = [])
      parser = OptionParser.new

      parser.version = LogManager::VERSION

      parser.on('-c CONFIG', '--config=CONFIG', 'specify config', &:itself)
      parser.on('-h HOST', '--host=HOST', 'speify romote host', &:itself)
      parser.on('-n', '--noop', 'no operation', &:itself)
      parser.on('-m', '--mail', 'send results by mail ', &:itself)

      parser.banner = <<~BANNER
        Usage: #{$0} [options...] commands...
          commands:
            clean                            clean add compress log
            rsync                            rsync log from remote
            scp                              scp log from remote
            check                            check log disk
          options:
      BANNER

      cmds = nil
      opts = {}
      begin
        cmds = parser.parse(ARGV, into: opts)
      rescue OptionParser::ParseError => e
        warn e.message
        warn parser.help
        return 1
      end

      if cmds.empty?
        warn 'no command'
        warn parser.help
        return 2
      end

      unknown_cmds = cmds - %w[clean rsync scp check]

      unless unknown_cmds.empty?
        warn "unknownt command: #{unknown_cmds.join(', ')}"
        return 3
      end

      config_path_list = [opts[:config]] if opts[:config]
      config_path = config_path_list.find { |path| FileTest.exist?(path) }
      if config_path.nil?
        warn 'config file not found'
        return 4
      end

      config = Config.new(config_path)

      pp config
      return 0

      logger_file = File.expand_path(@config[:logger][:file],
        @config[:root_dir])
      unless FileTest.directory?(File.dirname(logger_file))
        FileUtils.mkpath(File.dirname(logger_file))
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

      cmds.each do |cmd|
        case cmd
        when 'config'
          Command::Config.run(**opts)
        when 'clean'
          Command::Clean.run(**opts)
        when 'rsync'
          Command::Rsync.run(**opts)
        when 'scp'
          Command::Scp.run(**opts)
        end
      end

      # parser.order!(argv)
      # if argv.empty?
      #   puts HELP_MESSAGE
      #   exit 1
      # end

      opts[:subcommand] = argv.shift
      subparsers[opts[:subcommand]].parse!(argv)

      case opts[:subcommand]
      when 'config'
        Command::Config.run(**opts)
      when 'clean'
        Command::Clean.run(**opts)
      when 'rsync'
        Command::Rsync.run(**opts)
      when 'scp'
        Command::Scp.run(**opts)
      end
    end
  end
end
