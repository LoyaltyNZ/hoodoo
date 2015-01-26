require 'singleton'
require 'fileutils'

module Hoodoo
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
      return ERROR_EXIT_CODE unless replace_strings(name)

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

    def replace_strings(name)
      human_name = name.split('_')
      human_name = human_name.drop(1) if (human_name[0].downcase == 'service')
      human_name = human_name.map(&:capitalize).join(' ')

      base_cmd   = "find #{name} -type f -print0 | xargs -0 sed -i '' 's/%s/g'"
      uscore_cmd = base_cmd % "service_shell/#{Regexp.escape(name)}"
      human_cmd  = base_cmd % "#{Regexp.escape('Platform Service: Generic')}/#{Regexp.escape('Platform Service: ' + human_name)}"

      puts "Replacing shell names with real service name:"
      puts uscore_cmd
      `#{uscore_cmd}`
      result = $?.to_i == 0
      return false unless result == true

      puts human_cmd
      `#{human_cmd}`
      result = $?.to_i == 0
      return result
    end

    def args_empty?(args)
      args.empty? || args.first == ''
    end

    def naughty_name?(name)
      !(name =~ NAME_REGEX)
    end

    def show_usage
      puts "Usage: hoodoo SERVICE_NAME"
      return ERROR_EXIT_CODE
    end

    def usage_and_warning(warning)
      puts "WARNING: #{warning}"
      puts
      show_usage
    end
  end
end

