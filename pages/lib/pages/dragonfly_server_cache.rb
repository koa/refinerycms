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
