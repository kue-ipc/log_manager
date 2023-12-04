require 'log_manager/command/base'
require 'log_manager/utils'
module LogManager
  module Command
    class Check < Base
      def self.command
        check
      end

      def self.run(config, **opts)
        Check.new(config, **opts).run
      end

      def run
        result = {errors: []}
        stat = Utils.disk_stat(@config[:root_dir])

        log_info("#{@config[:root_dir]} on #{stat.root_path}")
        result[:root_dir] = @config[:root_dir]
        result[:disk_path] = stat.root_path

        result[:block] = stat.block.merge({usage: stat.block_usage})
        log_info("block: #{result[:block].to_json}")
        if result[:block][:usage] > @config[:check][:block_threshold]
          log_warn('block size over limit')
          result[:errors] << 'block size limit over'
        end

        if stat.inode
          result[:inode] = stat.inode.merge({usage: stat.inode_usage})
          log_info("inode: #{result[:inode].to_json}")
          if result[:inode][:usage] > @config[:check][:inode_threshold]
            log_warn('inode size over limit')
            result[:errors] << 'inode size limit over'
          end
        end

        result
      end
    end
  end
end
