require 'log_manager/command/base'

module LogManager
  module Command
    class Show < Base
      def self.command
        'show'
      end

      def self.run(config, **opts)
        Show.new(config, **opts).run
      end

      def run
        log_info('show config')
        puts "# config_path: #{@config.path}"
        puts @config.dump_config
        {
          path: @config.path,
          config: @config.masked_config,
          log_file: @config.log_file,
        }
      end
    end
  end
end
