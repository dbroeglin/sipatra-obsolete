module Sipatra
  class New < Thor::Group
    include Thor::Actions
    Thor::Sandbox::Sipatra::New.source_root(File::join(File.dirname(__FILE__), "templates"))
    argument :app_path, :type => :string, :desc => "The name of the new application"
    desc "Creates a new Sipatra application"  

    add_runtime_options!

    def base_dir
      self.destination_root = File.expand_path(app_path, destination_root)
      empty_directory '.'
      FileUtils.cd(destination_root) unless options[:pretend]
    end

    def Rakefile
      template "Rakefile"
    end

    def lib
      empty_directory "lib"

      inside "lib" do
        template "application.rb"
      end
    end
  end
end
