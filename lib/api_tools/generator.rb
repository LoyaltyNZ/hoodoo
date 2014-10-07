require 'singleton'
require 'fileutils'

module ApiTools
  class Generator
    include Singleton

    SUCCESS_EXIT_CODE = 0
    ERROR_EXIT_CODE = 1
    NAME_REGEX = /^[a-zA-Z01-9_-]{2,30}$/

    def run!(args)
      return show_usage if args_empty?(args)

      name = args.first
      return usage_and_warning("SERVICE_NAME must match #{NAME_REGEX.inspect}") if naughty_name?(name)

      return usage_and_warning("'#{name}' already exists") if File.exist?("./#{name}")

      return create_service(name)
    end

private

    def create_service(name)
      return ERROR_EXIT_CODE unless create_dir(name)
      return ERROR_EXIT_CODE unless clone_service_shell(name)
      return ERROR_EXIT_CODE unless remove_dot_git(name)
      puts "Success! ./#{name} created."
      return SUCCESS_EXIT_CODE
    end

    def create_dir(name)
      `mkdir #{name}`
      $?.to_i == 0
    end

    def clone_service_shell(name)
      `git clone git@github.com:LoyaltyNZ/service_shell.git #{name}`
      $?.to_i == 0
    end

    def remove_dot_git(name)
      git_folder = "./#{name}/.git"
      git_config = "#{git_folder}/config"
      if File.read(git_config).include?("url = git@github.com:LoyaltyNZ/service_shell.git") #paranoid
        FileUtils.remove_dir(git_folder)
      else
        raise "Expecting to find the .git folder with a config file in it"
      end
    end

    def args_empty?(args)
      args.empty? || args.first == ''
    end

    def naughty_name?(name)
      !(name =~ NAME_REGEX)
    end

    def show_usage
      puts "Usage: api_tools SERVICE_NAME"
      return ERROR_EXIT_CODE
    end

    def usage_and_warning(warning)
      puts "WARNING: #{warning}"
      puts
      show_usage
    end
  end
end

