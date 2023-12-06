require 'log_manager/command/base'
require 'log_manager/utils'

module LogManager
  module Command
    class Check < Base
      def self.command
        'check'
      end

      def run
        log_info("root_dir: #{root_dir}")
        time = Time.now
        stat = Utils.disk_stat(root_dir)
        log_info("root_path: #{stat.root_path}")

        block = stat.block&.merge({usage: stat.block_usage})
        check_block(block)

        inode = stat.inode&.merge({usage: stat.inode_usage})
        check_inode(inode)

        @result = {
          time: time,
          root_dir: root_dir,
          disk_path: stat.root_path,
          block: block,
          inode: inode,
        }

        self
      end

      def check_block(block)
        if block.nil?
          log_info('no block')
          return
        end

        log_info("block: #{block.to_json}")
        if block[:usage] <= @config[:check][:block_threshold]
          true
        else
          err('block size limit over')
          false
        end
      end

      def check_inode(inode)
        if inode.nil?
          log_info('no inode')
          return
        end

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
