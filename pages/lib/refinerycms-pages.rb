require 'refinerycms-core'
require 'awesome_nested_set'
require 'globalize3'
require 'friendly_id'
require 'seo_meta'

module Refinery
  module Pages

    autoload :InstanceMethods, File.expand_path('../refinery/pages/instance_methods', __FILE__)
    module Admin
      autoload :InstanceMethods, File.expand_path('../refinery/pages/admin/instance_methods', __FILE__)
    end

    class << self
      attr_accessor :root
      def root
        @root ||= Pathname.new(File.expand_path('../../', __FILE__))
      end
    end

    class Engine < ::Rails::Engine
      initializer 'serve static assets' do |app|
        app.middleware.insert_after ::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public"
      end

      config.to_prepare do
        require File.expand_path('../pages/tabs', __FILE__)
      end

      refinery.after_inclusion do
        ::ApplicationController.send :include, ::Refinery::Pages::InstanceMethods
        ::Admin::BaseController.send :include, ::Refinery::Pages::Admin::InstanceMethods
      end

      config.after_initialize do
        ::Refinery::Plugin.register do |plugin|
          plugin.pathname = root
          plugin.name = 'refinery_pages'
          plugin.directory = 'pages'
          plugin.version = %q{1.0.0}
          plugin.menu_match = /(refinery|admin)\/page(_part)?s(_dialogs)?$/
          plugin.activity = {
            :class => Page,
            :url_prefix => 'edit',
            :title => 'title',
            :created_image => 'page_add.png',
            :updated_image => 'page_edit.png'
          }
        end
      end

      initializer 'add marketable routes' do |app|
        app.routes_reloader.paths << File.expand_path('../pages/marketable_routes.rb', __FILE__)
      end

    end
  end
end

::Refinery.engines << 'pages'

module DragonflyServerCache
  def call_with_cache(env)
    result = call_without_cache(env)
    code = result[0]
    if code == 200
      rack_cache_entry = result[2]
        # Only if Entry comes from Rack::Cache
      if rack_cache_entry.respond_to? :to_path
        @@page_cache_directory||=Pathname.new(PagesController.new.page_cache_directory)
        target_file = @@page_cache_directory+"refinery_page_cache/#{env['PATH_INFO']}"
        unless target_file.exist?
          # Copy with temp-File cause of Race-Conditions
          temp_file = @@page_cache_directory+
                  "refinery_page_cache/#{env['PATH_INFO']}.#{rand(1024)}"
          target_file.parent.mkpath
            # Copy Rack-Cache to refinery_page_cache
          File.cp rack_cache_entry.to_path, temp_file
          File.mv temp_file, target_file
        end
      end
    end
    result
  end

  def mkdir(path)
    unless File.exist? path
      mkdir File.dirname(path)
      Dir.mkdir path
    end
  end
end

if RefinerySetting.find_or_set('cache_pages_full', false,
                               {:restricted=>true,
                                :form_value_type =>
                                        'check_box'})
  Rack::Cache::Context.class_eval do
    include DragonflyServerCache
    alias_method_chain :call, :cache
  end
end


