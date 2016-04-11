module RPM
  def rpmbuild (target, options)
    command = options[:rpmbuild] || 'rpmbuild'
    stage = '-' << case
      when file = options[:tar] then 't'
      when file = options[:spec] then 'b'
      else raise ArgumentError, 'Missing either spec or tar file option'
    end << case target
      when :all then 'a'
      when :binary then 'b'
      when :source then 's'
      when :prep then 'p'
      when :build then 'c'
      when :install then 'i'
      when :list, :check, :list_check then 'l'
      else raise ArgumentError, "Unknown building stage `#{target}'"
    end
    args = [command, stage] << options.map do |opt, value|
      case opt
        when :debug then '-vv'
        when :verbose then '-v'
        when :clean, :nobuild, :rmsource, :rmspec, :short_circuit, :quiet
          "--#{opt.to_s.tr('_', '-')}"
        when :target, :buildroot, :root, :dbpath, :rcfile
          "--#{opt} #{value}"
        else raise ArgumentError, "Unknown option `#{opt}'"
      end if value
    end
    output = %x(#{args.join(' ')})
    [$?, output]
  end

  def mock (action, options)
    config = options.map {|name, value| [name.to_sym.tr('_', '-'), value]}.to_h
    command = confg[:mock] || 'mock'
    args = [command, "--#{action}"] + case action.to_sym
    when :rebuild
      raise ArgumentError, 'No SRPM specified' unless config[:srpm]
      [config.delete(:srpm)]
    when :buildsrpm
      if config[:spec]
        ['--spec', config.delete(:spec)]
      elsif config[:sources]
        ['--sources', config.delete(:sources)]
      elsif config[:'scm-enable']
        config.delete(:'scm-enable')
        [
          '--scm-enable',
          config.delete(:'scm-option').map {|k, v| "--scm-option #{k}=#{v}"}
        ]
      else
        raise ArgumentError, 'No spec, sources or scm specified'
      end
    when :install, :remove
      raise ArgumentError, 'No package specifies' unless config[:package]
      [config.delete(:package)]
    when :copyin, :copyout
      raise ArgumentError, 'No path specified' unless (config[:path] || []).size < 2
      [config.delete(:path)]
    when :update, :orphanskill then []
    else
      raise ArgumentError, "Unknown action `#{action}'"
    end
    args += [
             :offilne, :'no-clean', :'cleanup-after', :'no-cleanup-after',
             :quiet, :verbose, :unpriv, :trace
    ].select {|name| options[name]}.map {|name| "--#{name}"}
    args += [
             :root, :target, :arch, :resultdir,
             :uniqueext, :configdir, :rpmbuild_timeout, :cwd,
    ].select {|name| options[name]}.map {|name| "--#{name}=#{options[name]}"}
--define="MACRO EXPR"
--with=OPTION
--without=OPTION
--enable-plugin=PLUGIN
--disable-plugin=PLUGIN
  end
end
