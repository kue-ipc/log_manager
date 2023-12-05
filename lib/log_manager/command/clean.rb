# frozen_string_literal: true

require 'logger'

require 'log_manager/command/base'

module LogManager
  module Command
    class Clean < Base
      def self.command
        'clean'
      end

      def need_check?(path)
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

      def check_hidden?(path)
        !@config.dig(:clean, :hidden) && file_stat(path).attr.hidden
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
        run_cmd(cmd)
      end

      def compress_and_delete(path = @config[:root_dir], base_time: Time.now)
        check_path(path)
        begin
          unless FileTest.exist?(path)
            log_warn("skip a removed entry: #{path}")
            return
          end

          unless need_check?(path)
            log_info("not covered: #{path}")
            return
          end

          if FileTest.file?(path)
            if need_delete?(path, base_time: base_time)
              log_info("remove an expired file: #{path}")
              remove_file(path)
            elsif need_compress?(path, base_time: base_time)
              compress_file(path)
            else
              log_debug("skip a file: #{path}")
            end
          elsif FileTest.directory?(path)
            entries = Dir.entries(path) - %w[. ..]
            entries.each do |e|
              compress_and_delete(File.join(path, e), base_time: base_time)
            end
            if path != @config[:root_dir] &&
               (Dir.entries(path) - ['.', '..']).empty?
              log_info("remove an empty dir: #{path}")
              remove_dir(path)
            end
          else
            log_info("skip another type: #{path}")
          end
        end
      rescue => e
        log_error("error occured #{e.class}: #{path}")
        log_error("error message: #{e.message}")
        raise
      end

      def run
        base_time = Time.now
        compress_and_delete(base_time: base_time)
        @resulrt = {
          base_time: base_time
        }

        self
      end
    end
  end
end
