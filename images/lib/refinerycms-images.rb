require 'dragonfly'
require 'rack/cache'
require 'refinerycms-core'

module Refinery
  module Images

    class << self
      attr_accessor :root
      def root
        @root ||= Pathname.new(File.expand_path('../../', __FILE__))
      end
    end

    autoload :Dragonfly, File.expand_path('../refinery/images/dragonfly', __FILE__)

    class Engine < ::Rails::Engine
      isolate_namespace ::Refinery

      initializer 'serve static assets' do |app|
        app.middleware.insert_after ::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public"
      end

      initializer 'images-with-dragonfly' do |app|
        ::Refinery::Images::Dragonfly.attach!(app)
      end

      initializer "init plugin", :after => :set_routes_reloader do |app|
        ::Refinery::Plugin.register do |plugin|
          plugin.name = 'refinery_images'
          plugin.directory = 'images'
          plugin.version = %q{1.0.0}
          plugin.menu_match = /(refinery|admin)\/image(_dialog)?s$/
          plugin.activity = {
            :class => Image
          }
          plugin.url = app.routes.url_helpers.refinery_admin_images_path
        end
      end
    end
  end
end

::Refinery.engines << 'dashboard'
