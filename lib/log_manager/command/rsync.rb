# TODO
# * multiple sources required by ssh forced-commands-only
# * noop on '-n' mode

require 'resolv'

require 'log_manager/command/base'

module LogManager
  module Command
    class Rsync < Base
      RSYNC_OPTIONS = %w[
        -a
        -u
        -z
        -v
        --no-o
        --no-g
        --chmod=D0755,F0644
        --rsh=ssh
      ].freeze

      def self.command
        'rsync'
      end

      def run
        @result ||= {}
        all_sync

        self
      end

      def save_dir
        @save_dir ||=
          File.expand_path(@config.dig(:rsync, :save_dir), @config[:root_dir])
      end

      def rsync_cmd
        @rsync_cmd ||= @config.dig(:rsync, :cmd)
      end

      def result_sync(host, dir, result)
        @result ||= {}
        @result[:sync] ||= []
        @result[:sync] << {host: host, dir: dir, result: result}
      end

      def all_sync
        log_info('all sync')
        @config.dig(:rsync, :hosts).each do |host|
          next if @host && ![host[:name], host[:host]].include?(@host)

          host_sync(**host)
        rescue => e
          err(e)
        end
      end

      def host_sync(name: nil, host: nil, user: 'root', targets: [])
        raise Error, 'no "host" in hosts' if host.nil? || host.empty?

        name = host_to_name(host) if name.nil?
        raise Error, 'empty name in hosts' if name.empty?

        raise Error, "invalid user: #{user}" if user !~ /\A\w+\z/

        log_info("sync host: #{host} as #{name}")

        host_save_dir = File.join(save_dir, name)

        targets.each do |target|
          target_sync(host, user, host_save_dir, **target)
        rescue => e
          err(e)
        end
      end

      def target_sync(host, user, host_save_dir, name: nil, dir: nil, **opts)
        raise Error, 'no "dir" in targets' if dir.nil? || dir.empty?

        name = File.basename(dir) if name.nil?
        raise Error, 'empty name in hosts' if name.empty?

        log_info("sync target: #{dir} as #{name}")

        target_save_dir = File.join(host_save_dir, name)

        remote =
          if host_type(host) == :fqdn
            "#{user}@[#{host}]"
          else
            "#{user}@#{host}"
          end
        src = "#{remote}:#{dir}/"
        dst = "#{dir}/"

        begin
          stdout = rsync(src, dst, target_save_dir, **opts)
          result_sync(host, dir, stdout)
        rescue => e
          result_sync(host, dir, e.message)
          err(e)
        end
      end

      def rsync(src, dst, includes: nil, excludes: nil)
        check_path(dst)
        make_dir(dst)
        opts = []
        opts << '-n' if @noop
        opts.concat(RSYNC_OPTIONS)
        includes&.each { |pattern| opts << "--include=#{pattern}" }
        excludes&.each { |pattern| opts << "--exclude=#{pattern}" }
        cmd = [
          @rsync_cmd,
          *opts,
          src,
          dst,
        ]
        stdout, _, status = run_cmd(cmd)
        raise Error, "failed to rsnyc: #{src}" unless status.success?

        stdout
      end

      def host_type(host)
        case host
        when Resolv::IPv6::Rege
          :ipv6
        when Resolv::IPv4::Regex
          :ipv4
        when /\A[\w-]+\z/
          :hostname
        when /\A(?:[\w-]+\.)+[\w-]+\z/
          :fqdn
        else
          raise Error, "invalid host: #{host}"
        end
      end

      def host_to_name(host)
        if host_type(host) == :fqdn
          host.split('.').first
        else
          host
        end
      end
    end
  end
end
