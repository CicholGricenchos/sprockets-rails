require 'fileutils'

module Sprockets
  module Rails
    class StaticCompiler
      attr_accessor :env, :target, :paths

      def initialize(env, target, paths, options = {})
        @env = env
        @target = target
        @paths = paths
        @digest = options.fetch(:digest, true)
        @manifest = options.fetch(:manifest, true)
        @zip_files = options.delete(:zip_files) || /\.(?:css|html|js|svg|txt|xml)$/
      end

      def compile
        manifest = {}
        env.each_logical_path(paths) do |logical_path|
          if asset = env.find_asset(logical_path)
            digest_path = write_asset(asset)
            manifest[asset.logical_path] = digest_path
            manifest[aliased_path_for(asset.logical_path)] = digest_path
          end
        end
        write_manifest(manifest) if @manifest
      end

      def write_manifest(manifest)
        FileUtils.mkdir_p(@target)
        File.open("#{@target}/manifest.yml", 'wb') do |f|
          YAML.dump(manifest, f)
        end
      end

      def write_asset(asset)
        path_for(asset).tap do |path|
          filename = File.join(target, path)
          FileUtils.mkdir_p File.dirname(filename)
          asset.write_to(filename)
          asset.write_to("#{filename}.gz") if filename.to_s =~ @zip_files
        end
      end

      def path_for(asset)
        @digest ? asset.digest_path : asset.logical_path
      end

      def aliased_path_for(logical_path)
        if File.basename(logical_path).start_with?('index')
          logical_path.sub(/\/index([^\/]+)$/, '\1')
        else
          logical_path.sub(/\.([^\/]+)$/, '/index.\1')
        end
      end
    end
  end
end
