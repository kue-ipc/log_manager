require 'log_manager/command/base'
require 'log_manager/utils'
module LogManager
  module Command
    class Check < Base
      def self.command
        'check'
      end

      def run
        stat = Utils.disk_stat(@config[:root_dir])
        log_info("#{@config[:root_dir]} on #{stat.root_path}")

        block = stat.block.merge({usage: stat.block_usage})
        check_block(block)

        if stat.inode
          inode = stat.inode.merge({usage: stat.inode_usage})
          check_inode(inode)
        else
          inode = nil
          log_info('no inode')
        end

        @result = {
          root_dir: @config[:root_dir],
          disk_path: stat.root_path,
          block: block,
          inode: inode,
        }

        self
      end

      def check_block(block)
        log_info("block: #{block.to_json}")
        if block[:usage] <= @config[:check][:block_threshold]
          true
        else
          err('block size limit over')
          false
        end
      end

      def check_inode(inode)
        log_info("inode: #{inode.to_json}")
        if inode[:usage] <= @config[:check][:inode_threshold]
          true
        else
          err('inode size over limit')
          false
        end
      end
    end
  end
end
