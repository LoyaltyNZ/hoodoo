########################################################################
# File::    generator.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Implement the +hoodoo+ command line interface. See also
#           +/bin/hoodoo+.
# ----------------------------------------------------------------------
#           07-Oct-2014 (JDC): Created.
########################################################################

require 'singleton'
require 'fileutils'

module Hoodoo

  # Implement the +hoodoo+ command line interface.
  #
  class Generator
    include Singleton

    # Kernel::exit takes a boolean but defines no constants to describe
    # what it means; very bad form. This constant equates to the 'success'
    # boolean value.
    #
    KERNEL_EXIT_SUCCESS = true

    # Kernel::exit takes a boolean but defines no constants to describe
    # what it means; very bad form. This constant equates to the 'failed'
    # boolean value.
    #
    KERNEL_EXIT_FAILURE = false

    # Regular expression describing allowed names of services (A-Z,
    # a-z, 0-9, underscore or hyphen; between 2 and 30 characters).
    #
    NAME_REGEX = /^[a-zA-Z01-9_-]{2,30}$/

    # Run the +hoodoo+ command implementation.
    #
    # +args+:: Array of command line arguments, excluding the +hoodoo+
    #          command itself (so, just any extra arguments passed in).
    #
    def run!( args )
      return show_usage if args_empty?(args)

      name = args.first

      return usage_and_warning( "SERVICE_NAME must match #{ NAME_REGEX.inspect }" ) if naughty_name?( name )
      return usage_and_warning( "'#{ name }' already exists" ) if File.exist?( "./#{ name }" )

      return create_service( name )
    end

  private

    def create_service(name)
      if create_dir( name )          &&
         clone_service_shell( name ) &&
         remove_dot_git( name )      &&
         replace_strings( name )

        puts "Success! ./#{name} created."
        Kernel::exit( KERNEL_EXIT_SUCCESS )
      else
        Kernel::exit( KERNEL_EXIT_FAILURE )
      end
    end

    def create_dir( name )
      `mkdir #{ name }`
      $?.to_i == 0
    end

    def clone_service_shell( name )
      `git clone git@github.com:LoyaltyNZ/service_shell.git #{ name }`
      $?.to_i == 0
    end

    def remove_dot_git( name )
      git_folder = "./#{ name }/.git"
      git_config = "#{ git_folder }/config"

      if File.read( git_config ).include?( "url = git@github.com:LoyaltyNZ/service_shell.git" ) # Paranoid
        FileUtils.remove_dir( git_folder )
        return true
      else
        raise 'Did not find a .git folder with a service_shell config file in it!'
      end
    end

    def replace_strings( name )
      human_name = name.split( '_' )
      human_name = human_name.drop( 1 ) if ( human_name[ 0 ].downcase == 'service' )
      human_name = human_name.map( &:capitalize ).join( ' ' )

      base_cmd   = "LC_CTYPE=C && LANG=C && find #{ name } -type f -print0 | xargs -0 sed -i \"\" \"s/%s/g\""
      uscore_cmd = base_cmd % "service_shell/#{ Regexp.escape( name ) }"
      human_cmd  = base_cmd % "#{ Regexp.escape( 'Platform Service: Generic' ) }/#{ Regexp.escape( 'Platform Service: ' + human_name ) }"

      puts "Replacing shell names with real service name:"
      puts uscore_cmd
      `#{ uscore_cmd }`
      result = $?.to_i == 0
      return false unless result == true

      puts human_cmd
      `#{ human_cmd }`
      result = $?.to_i == 0
      return result
    end

    def args_empty?( args )
      args.empty? || args.first == ''
    end

    def naughty_name?( name )
      !( name =~ NAME_REGEX )
    end

    def show_usage
      puts "Usage: hoodoo SERVICE_NAME"
      puts "  e.g. hoodoo service_cron"

      Kernel::exit( KERNEL_EXIT_FAILURE )
    end

    def usage_and_warning( warning )
      puts "WARNING: #{warning}"
      puts
      show_usage
    end
  end
end

