module RPM
  class Spec

    class ParseError < StandardError ; end

    class << self
      # @example
      #   RPM::Spec.open('file.spec') do
      #     ...
      #   end
      alias open new

      # @example
      #   File.open('file.spec') { |file| spec = RPM::Spec.read(file) }
      alias read open
    end

    # @example
    #   RPM::Spec.new 'file.spec'
    #   RPM::Spec.new do |spec|
    #     spec.define name: 'my-package',
    #                 version: '1.0.0'
    #     spec.tag Name: '%{name}',
    #              Version: '%{version}'
    #     spec.body description: 'Some Description'
    #   end
    def initialize(spec = nil, &block)
      @define = {}
      @tag = {}
      @body = Hash.new('')
      load(spec) if spec
      yield self if block_given?
    end

    [ :define, :tag, :body ].each do |name|
      define_method(name) do |value = nil|
        instance_variable_set "@:#{name}", value if value
        instance_variable_get "@:#{name}"
      end
    end

    def load(spec)
      case spec
        when String
          File.open(spec) { |file| parse(file) }
        when IO
          parse(spec)
        when Hash
          [ :define, :tag, :body ].each { |k| send k, spec[k] if spec[k] }
        else
          raise ArgumentError.new("Can't load from #{spec.class}")
      end
    end

    def parse(file)
      @content = []
      continue = nil
      file.each_line do |line|
        @content << line
        case line.strip
        when /(^#)|(^$)/
          continue = nil
          next
        when /^%define (\w+)[[:space:]]+(.*)/
          name, macro = $1.to_sym, $2.strip
          continue = macro[-1] == '\\' ? macro : nil
          define[name] = macro
        when /^%(description|prep|build|install|check|clean|files|changelog)/
          continue = body[$1.to_sym]
        when /^(Source|Patch)([[:digit:]]*)[[:space:]]*:(.*)/
          continue = nil
          name, index, value = $1.to_sym, $2.to_i, $3.strip
          tag[name] ||= []
          tag[name][index] = value
        when /^([[:upper:]][[:alpha:]]+)[[:space:]]*:(.*)/
          continue = nil
          name, value = $1.to_sym, $2.strip
          tag[name] = value
        else
          raise RPM::Spec::ParseError.new(@content.size + 1, line) if continue.nil?
          continue << line
        end
      end
      [:name, :version, :release].each {|n| define[n] ||= tag[n.capitalize]}
      @content = @content.join ''
    end

    def dump(spec)
      case spec
      when String then File.new(spec, 'w') { |file| format(file) }
      when IO then format(spec)
      end
    end

    def format(file)
      file.write(to_s)
    end

    def to_s
      if @content.nil?
        @contetn = (
          define.map {|name, macro| "%define #{name} #{macro}"} +
          tag.map {|name, value| "#{name}: #{value}"} +
          [body]
        ).join("\n")
      end
      @content
    end

    def to_h
      { define: define, tag: tag, body: body }
    end

    private :load, :parse
  end
end


