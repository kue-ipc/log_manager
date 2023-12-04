require_relative 'platform'
require_relative 'win_kernel32' if LogManager::Utils::Platform.windows?

module LogManager
  module Utils
    class FileStat
      attr_reader :path, :absolute_path, :stat, :attr

      def initialize(path)
        @path = path
        # @stat = File.stat(@path)
        @absolute_path = File.absolute_path(@path)
        @attr =
          if LogManager::Utils::Platform.windows?
            FileStat.file_attr_windows(path, @stat)
          else
            FileStat.file_attr_posix(path, @stat)
          end
      end

      def self.file_attr_windows(path, _stat = nil)
        path_wstr = path.gsub('/', '\\').encode(Encoding::UTF_16LE)
        WinKernel32::FileAttributeData.malloc(Fiddle::RUBY_FREE) do |data|
          result = WinKernel32.GetFileAttributesExW(path_wstr,
            WinKernel32::GetFileExInfoStandard, data)
          if result.zero?
            raise 'Error GetFileAttributesExW, ' \
                  "Last Error: #{Fiddle.win32_last_error}"
          end
          {
            readonly: WinKernel32::FILE_ATTRIBUTE_READONLY.anybits?(
              data.dwFileAttributes),
            hidden: WinKernel32::FILE_ATTRIBUTE_HIDDEN.anybits?(
              data.dwFileAttributes),
            system: WinKernel32::FILE_ATTRIBUTE_SYSTEM.anybits?(
              data.dwFileAttributes),
            arhive: WinKernel32::FILE_ATTRIBUTE_ARCHIVE.anybits?(
              data.dwFileAttributes),
          }
        end
      end

      def self.file_attr_posix(path, stat = nil)
        stat ||= File.stat(path)
        {
          readonly: stat.mode.nobits?(0o222),
          hidden: File.basename(path).start_with?('.'),
        }
      end
    end
  end
end

if $0 == __FILE__
  ARGV.each do |path|
    pp LogManager::Utils::FileStat.new(path)
  end
end
