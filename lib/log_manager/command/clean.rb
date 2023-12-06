# frozen_string_literal: true

require 'logger'

require 'log_manager/command/base'
require 'log_manager/utils'

module LogManager
  module Command
    class Clean < Base
      def self.command
        'clean'
      end

      def run
        base_time = Time.now
        @result = {
          base_time: base_time,
        }
        compress_and_delete(base_time: base_time)

        self
      end

      def count_up(name)
        @result = {} if @resulst.nil?
        @result[name] ||= 0
        @result[name] += 1
      end

      def need_check?(path)
        return false if check_log_file(path)

        return false if check_hidden?(path)

        name =
          if compressed?(path)
            File.basename(path, File.extname(path))
          else
            File.basename(path)
          end

        return false if check_not_includes?(name)

        return false if check_excludes?(name)

        true
      end

      def check_log_file(path)
        File.expand_path(path) == @config.log_file
      end

      def check_hidden?(path)
        !@config.dig(:clean, :hidden) && Utils.file_stat(path).hidden?
      end

      def check_not_includes?(name)
        @config.dig(:clean, :includes)&.none? { |ptn| File.fnmatch?(ptn, name) }
      end

      def check_excludes?(name)
        @config.dig(:clean, :excludes)&.any? { |ptn| File.fnmatch?(ptn, name) }
      end

      def compressed?(path)
        @config.dig(:clean, :compress, :ext_list).include?(File.extname(path))
      end

      def need_delete?(path, base_time: Time.now)
        base_time - File.stat(path).mtime >
          @config.dig(:clean, :period_retention)
      end

      def need_compress?(path, base_time: Time.now)
        return false if compressed?(path)

        base_time - File.stat(path).mtime >
          @config.dig(:clean, :period_nocompress)
      end

      def compressed_path(path)
        path + @config.dig(:clean, :compress, :ext)
      end

      def compress_cmd
        @compress_cmd ||= @config.dig(:clean, :compress, :cmd).split
      end

      def compress_file(path)
        comperssed = compressed_path(path)
        if FileTest.exist?(comperssed)
          log_info("delete a existed compressed file: #{comperssed}")
          remove_file(comperssed)
        end

        log_info("compress: #{path}")
        cmd = [*compress_cmd, '--', path]
        _, _, status = run_cmd(cmd)
        raise Error, "failed to compress: #{path}" unless status.success?

        nil
      end

      def compress_and_delete(path = @config[:root_dir], base_time: Time.now)
        check_path(path)
        unless FileTest.exist?(path)
          log_warn("skip a removed entry: #{path}")
          count_up(:not_exsit)
          return
        end

        unless need_check?(path)
          log_debug("skip an excluded entry: #{path}")
          count_up(:excluded)
          return
        end

        if FileTest.file?(path)
          if need_delete?(path, base_time: base_time)
            log_debug("remove an expired file: #{path}")
            remove_file(path)
            count_up(:remove_file)
          elsif need_compress?(path, base_time: base_time)
            log_debug("compress an old file: #{path}")
            compress_file(path)
            count_up(:compress_file)
          else
            log_debug("skip a file: #{path}")
            count_up(:skip_file)
          end
        elsif FileTest.directory?(path)
          log_debug("enter a directory: #{path}")
          Dir.each_child(path) do |e|
            compress_and_delete(File.join(path, e), base_time: base_time)
          end

          if path != @config[:root_dir] && Dir.empty?(path)
            log_debug("remove an empty dir: #{path}")
            remove_dir(path)
            count_up(:remove_directory)
          else
            count_up(:check_directory)
          end
        else
          log_info("skip an other type: #{path}")
          count_up(:other)
        end
      rescue => e
        err(e)
        count_up(:error)
      end
    end
  end
end
