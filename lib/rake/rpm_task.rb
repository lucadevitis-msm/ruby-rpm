module Rake
  class RpmTask

    attr_accessor :_topdir

    def initialize(spec_path = nil, topdir_path = nil)
      init(spec_path, topdir_path)
      yield self if block_given?
      define if block_given?
    end

    def spec=(path)
      @spec = RPM::Spec.new path
    end

    def spec
      if @spec.nil?
        @spec = RPM::Spec.new
      end
      @spec
    end

    def init(spec_path, topdir_path)
      spec = spec_path
      _topdir = topdir_path || spec.define[:_topdir] || './rpmbuild'
    end

    def define
      _topdirs = [
        _specdir = File.join(_topdir, 'SPECS'),
        _sourcedir = File.join(_topdir, 'SOURCES'),
        _builddir = File.join(_topdir, 'BUILD'),
        _buildroot = File.join(_topdir, 'BUILDROOT'),
        _rpmdir = File.join(_topdir, 'RPMS'),
        _srcrpmdir = File.join(_topdir, 'SRPMS')]

      _topdirs.each do |make|
        directory make
      end

      namespace :rpmbuild do
        task :clean do
          rmtree topdirs
        end
        task download: [_topdirs] do
          cd _sourcedir do
            (spec.tag[:Source] + spec.tag[:Patch]).each do |url|
              resource = URI(url)
            end
          end
        end
        task build: [_topdirs]
        task install: [_topdirs]
        task verify: [_topdirs]
        task rpm: [_topdirs]
        task rpms: [_topdirs]
        task all: [_topdirs]
      end

    end
  end
end
