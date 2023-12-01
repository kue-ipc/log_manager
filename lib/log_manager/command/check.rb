require 'log_manager/command/base'

module LogManager
  module Command
    class Check < Base
      def self.run(**opts)
        Check.new(**opts).check
      end

      def initialize(**opts)
        super
      end

      def check
        result = ture
        stat = disk_stat(@config[:root_dir])
        if stat.root_path
          log_info("root_path: #{stat.root_path}")
        else
          result = false
        end

        if stat.block
          block_usage = ((stat.total - stat.avail) * 1000 / stat.total).to_f
          log_info("block: {total: #{stat.total}, used: #{stat.used}, " \
                   "available: #{stat.available}, usage: #{block_usage}")
          if block_usage >= 80
            result = false
          end
        end

        if stat.inode
          inode_usage = ((stat.total - stat.avail) * 1000 / stat.total).to_f
          log_info("inode: {total: #{stat.total}, used: #{stat.used}, " \
                   "available: #{stat.available}, usage: #{inode_usage}")
          if inode_usage >= 80
            result = false
          end
        end

        result
      end
    end
  end
end
