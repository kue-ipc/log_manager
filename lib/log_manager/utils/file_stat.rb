require_relative 'win_kernel32' if RUBY_PLATFORM =~ /mingw|mswin/

module LogManager
  module Utils
    class FileStat
      attr_reader :path, :absolute_path, :hidden

      def initialize(path)
        @path = path
        @stat = File.stat(@path)
        @absolute_path = File.absolute_path(@path)
        if RUBY_PLATFORM =~ /mingw|mswin/
          @data = WinKernel32::FileAttributeData.malloc
          result = WinKernel32.GetFileAttributesExW(
            path.gsub('/', '\\').encode(Encoding::UTF_16LE),
            WinKernel32::GetFileExInfoStandard,
            @data)
          if result.zero?
            last_error = WinKernel32.GetLastError()
            raise "Error GetFileAttributesExW: #{last_error}"
          end
          @attrs = @data.dwFileAttributes
          @readonly = (@attrs & WinKernel32::FILE_ATTRIBUTE_READONLY).positive?
          @hidden = (@attrs & WinKernel32::FILE_ATTRIBUTE_HIDDEN).positive?
          @system = (@attrs & WinKernel32::FILE_ATTRIBUTE_SYSTEM).positive?
          @arhive = (@attrs & WinKernel32::FILE_ATTRIBUTE_ARCHIVE).positive?
        else
          @hidden =
            if File.basename(path).start_with?('.')
              true
            else
              false
            end
        end
      end
    end
  end
end

if $0 == __FILE__
  ARGV.each do |path|
    stat = LogManager::Utils::FileStat.new(path)
    pp stat
  end
end
