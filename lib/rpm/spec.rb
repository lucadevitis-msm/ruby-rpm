module RPM
  class Spec

    class ParseError < StandardError ; end

    attr_accessor :define
    attr_accessor :tag
    attr_accessor :body

    class << self
      # @example
      #   RPM::Spec.open('file.spec')
      def open(spec)
        new(spec)
      end

      # @example
      #   File.open('file.spec') { |file| RPM::Spec.read(file) }
      alias_method :read, :open
    end

    # @example
    #   RPM::Spec.new 'file.spec'
    #   RPM::Spec.new do |spec|
    #     spec.define = name: 'my-package',
    #                   version: '1.0.0'
    #     spec.tag = Name: '%{name}',
    #                Version: '%{version}'
    #     spec.body = description: 'Some Description'
    #   end
    def initialize(spec = nil)
      @content = ''
      @define = {}
      @tag = {}
      @body = Hash.new('')
      self.load(spec) if spec
      yield self if block_given?
    end

    def load(spec)
      case spec
      when String then File.open(spec) { |file| parse(file) }
      when IO then parse(spec)
      else raise ArgumentError.new("Can't load from #{spec.class}")
      end
    end

    def parse(file)
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
          raise RPM::Spec::ParseError.new(line) if continue.nil?
          continue << line
        end
      end

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

    private :load, :parse
  end
end


