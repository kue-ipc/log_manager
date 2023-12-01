require_relative 'platform'
require_relative 'win_kernel32' if LogManager::Utils::Platform.windows?

module LogManager
  module Utils
    class DiskStat
      def initialize(path)
        @path = path
        @absolute_path = File.absolute_path(@path)

        case LogManager::Utils::Platform.platform
        when :windows
          @data = DiskStat.disk_data_windows(@absolute_path)
        when :linux
          @data = DiskStat.disk_data_linux(@absolute_path)
        else
          raise NotImplementedError
        end
      end

      def block
        @data[:block]
      end

      def inode
        @data[:inode]
      end

      def self.disk_data_windows(path)
        path_wstr = path.gsub('/', '\\').encode(Encoding::UTF_16LE)
        vol_size = File.absolute_path(path).size + 1
        vol_wstr = (' ' * vol_size).encode(Encoding::UTF_16LE)

        if WinKernel32.GetVolumePathNameW(path_wstr, vol_wstr, vol_size).zero?
          last_error = WinKernel32.GetLastError()
          raise "Error GetDiskFreeSpaceExW: #{last_error}"
        end

        vol_ustr = vol_wstr.encode(Encoding::UTF_8)
        vol = vol_ustr[0, vol_ustr.index("\0")].gsub('\\', '/')

        # GetDiskSpaceInformation dose not suppport remote drives
        # info = WinKernel32::DiskSpaceInformation.malloc
        # if WinKernel32.FAILED(WinKernel32.GetDiskSpaceInformationW(vol_wstr, info))
        #   last_error = WinKernel32.GetLastError()
        #   raise "Error GetDiskSpaceInformationW: #{last_error}"
        # end

        avail_p = ' ' * 8
        total_p = ' ' * 8
        if WinKernel32.GetDiskFreeSpaceExW(path_wstr, avail_p, total_p,
                                           nil).zero?
          last_error = WinKernel32.GetLastError()
          raise "Error GetDiskFreeSpaceExW: #{last_error}"
        end

        avail = avail_p.unpack1('Q')
        total = total_p.unpack1('Q')

        {
          path: vol,
          block: {
            total: total,
            used: total - avail,
            avail: avail,
          },
          inode: nil,
        }
      end

      def self.disk_data_linux(path)
        data = {}
        result = IO.popen(['df', '-B', '1', path]) do |io|
          io.gets
          io.gets&.split
        end
        raise "failed to df block for: #{path}" if !$?.success? || result.nil?

        data[:path] = result[5]
        data[:block] = {
          total: result[1].to_i,
          used: result[2].to_i,
          avail: result[3].to_i,
        }

        result = IO.popen(['df', '-i', path]) do |io|
          io.gets
          io.gets&.split
        end
        raise "failed to df inode for: #{path}" if !$?.success? || result.nil?

        data[:inode] = {
          total: result[1].to_i,
          used: result[2].to_i,
          avail: result[3].to_i,
        }

        data
      end
    end
  end
end

if $0 == __FILE__
  ARGV.each do |path|
    stat = LogManager::Utils::DiskStat.new(path)
    pp stat
  end
end
