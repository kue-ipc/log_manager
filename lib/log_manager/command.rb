require 'logger'
require 'optparse'

require 'log_manager'
require 'log_manager/config'
require 'log_manager/command/check'
require 'log_manager/command/clean'
require 'log_manager/command/rsync'
require 'log_manager/command/scp'
require 'log_manager/command/show'

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
            check                            check log disk
            clean                            clean add compress log
            rsync                            rsync log from remote
            scp                              scp log from remote
            show                             show config
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

      unknown_cmds = cmds - %w[check clean rsync scp show]

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

      results = []
      cmds.each do |cmd|
        case cmd
        when 'check'
          results << Command::Check.run(config, **opts)
        when 'clean'
          results << Command::Clean.run(config, **opts)
        when 'rsync'
          results << Command::Rsync.run(config, **opts)
        when 'scp'
          results << Command::Scp.run(config, **opts)
        when 'show'
          results << Command::Show.run(config, **opts)
        end
      end
      pp results

      return 0
    end
  end
end
