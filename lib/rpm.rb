require 'process'
require 'pty'

module RPM
  def command(*argv)
    input, output = [nil, nil]
    argv ||= yield if block_given?
    input, output, pid = PTY.spawn(*argv)
    Process::wait(pid)
    [$?, input.read]
  ensure
    input.close if input
    output.close if output
  end

  def rpmbuild (target, config)
    command do
      options = config.map {|name, value| [name.to_s.tr('_', '-'), value]}.to_h
      stage = '-' << case
      when file = options.delete('tar') then 't'
      when file = options.delete('spec') then 'b'
      else raise ArgumentError, 'Missing spec or tar file'
      end
      stage << case target.to_s
      when 'all' then 'a'
      when 'binary' then 'b'
      when 'source' then 's'
      when 'prep' then 'p'
      when 'build' then 'c'
      when 'install' then 'i'
      when 'list', 'check', 'list-check' then 'l'
      else raise ArgumentError, "Unknown building stage: #{target}"
      end
      argv = [options.delete('rpmbuild') || 'rpmbuild', stage]
      argv += options.map do |name, value|
        case name
          when 'debug' then ['-vv']
          when 'verbose' then ['-v']
          when 'clean', 'quiet', 'nobuild', 'short-circuit',
               'rmsource', 'rmspec'
            ["--#{name}"]
          when 'target', 'buildroot', 'root', 'dbpath', 'rcfile'
            ["--#{name}", "#{value}"]
          else raise ArgumentError, "Unknown option #{name}"
        end if value
      end.flatten
      argv += [file].flatten
    end
  end

  def mock (action, config)
    command do
      options = config.map {|name, value| [name.to_s.tr('_', '-'), value]}.to_h
      argv = []
      argv += ['sudo'] + options.delete('sudo').split + ['--'] if options['sudo']
      argv += [options.delete('mock') || 'mock', "--#{action}"]
      argv += case action.to_s
      when 'rebuild'
        [options.delete('srpm')]
      when 'buildsrpm'
        case
        when options['spec'] then ['--spec', options.delete('spec')]
        when options['sources'] then ['--sources', options.delete('sources')]
        when options['scm-enable']
          options.delete('scm-enable') && ['--scm-enable']
        end
      when 'chroot'
        [options.delete('command')]
      when 'install', 'remove'
        [options.delete('package')]
      when 'installdeps'
        case
        when options['srpm'] then [options.delete('srpm')]
        when options['rpm'] then [options.delete('rpm')]
        end
      when 'copyin', 'copyout'
        options.delete('path')
      when 'init', 'clean', 'update', 'orphanskill' then []
      else
        raise ArgumentError, "Unknown action `#{action}'"
      end
      argv += options.map do |name, value|
        case value
        when String then ["--#{name}", value]
        when Array then value.map {|v| ["--#{name}", v]}
        when Hash then value.map {|k, v| ["--#{name}", "#{k}=#{v}"]}
        end
      end.flatten
    end
  end
end
