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
require 'pathname'
require 'getoptlong'

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

    # Run the +hoodoo+ command implementation. Command line options are
    # taken from the Ruby ARGV constant.
    #
    def run!
      git  = nil
      path = nil

      return show_usage() if ARGV.length < 1
      name = ARGV.shift() if ARGV.first[ 0 ] != '-'

      opts = GetoptLong.new(
        [ '--help',    '-h',       GetoptLong::NO_ARGUMENT       ],
        [ '--version', '-v', '-V', GetoptLong::NO_ARGUMENT       ],
        [ '--path',    '-p',       GetoptLong::REQUIRED_ARGUMENT ],
        [ '--from',    '-f',       GetoptLong::REQUIRED_ARGUMENT ],
        [ '--git',     '-g',       GetoptLong::REQUIRED_ARGUMENT ],
      )

      silence_stream( $stderr ) do
        begin
          opts.each do | opt, arg |
            case opt
              when '--help'
                return show_usage()
              when '--version'
                return show_version()
              when '--path'
                path = arg
              when '--from', '--git'
                git = arg
            end
          end

        rescue GetoptLong::InvalidOption, GetoptLong::MissingArgument => e
          return usage_and_warning( e.message )

        end
      end

      unless path.nil? || git.nil?
        return usage_and_warning( 'Use the --path OR --from arguments, but not both' )
      end

      git ||= 'git@github.com:LoyaltyNZ/service_shell.git'

      name = ARGV.shift() if name.nil?
      return show_usage() if name.nil?

      return usage_and_warning( "Unexpected extra arguments were given" ) if ARGV.count > 0
      return usage_and_warning( "SERVICE_NAME must match #{ NAME_REGEX.inspect }" ) if naughty_name?( name )
      return usage_and_warning( "'#{ name }' already exists" ) if File.exist?( "./#{ name }" )

      return create_service( name, git, path )
    end

  private

    # Name of new service, mandatory GitHub repo path of the shell to start
    # with, or override local filesystem path to copy from (pass "nil" to
    # not do that).
    #
    def create_service( name, git, path )
      ok = create_dir( name )
      ok = clone_service_shell( name, git ) if ok &&   path.nil?
      ok = copy_service_shell( name, path ) if ok && ! path.nil?
      ok = remove_dot_git( name, git )      if ok
      ok = replace_strings( name )          if ok

      if ok
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

    def clone_service_shell( name, git )
      `git clone #{ git } #{ name }`
      $?.to_i == 0
    end

    def copy_service_shell( name, path )
      source_path = Pathname.new( path ).to_s << '/.'
      dest_path   = File.join( '.', name )

      FileUtils.cp_r( source_path, dest_path, verbose: true )
      $?.to_i == 0
    end

    def remove_dot_git( name, git )
      git_folder = "./#{ name }/.git"
      git_config = "#{ git_folder }/config"

      if File.read( git_config ).include?( "url = #{ git }" ) # Paranoid
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
      puts
      puts "Creates a service shell at the PWD, customised with the given service name."
      puts
      puts "  hoodoo <service-name> [--from <git-repository> OR --path <full-pathname>]"
      puts
      puts "For example:"
      puts
      puts "  hoodoo service_cron"
      puts "  hoodoo service_person  --from git@github.com:YOURNAME/service_shell_fork.git"
      puts "  hoodoo service_product --path /path/to/local/service/shell/container"
      puts
      puts "The '--from' option is aliased as '--git'. All options have single letter"
      puts "equivalents. See also:"
      puts
      puts "  hoodoo --help    shows this help"
      puts "  hoodoo --version shows the require-able gem version"
      puts

      Kernel::exit( KERNEL_EXIT_FAILURE )
    end

    def show_version
      require 'hoodoo/version'

      puts
      puts "Accessible Hoodoo gem is #{ Hoodoo::VERSION } (#{ Hoodoo::DATE })"
      puts

      Kernel::exit( KERNEL_EXIT_FAILURE )
    end

    def usage_and_warning( warning )
      puts
      puts "-" * 80
      puts "WARNING: #{warning}"
      puts "-" * 80

      return show_usage()
    end

    def silence_stream( stream, &block )
      begin
        old_stream = stream.dup
        stream.reopen( File::NULL )
        stream.sync = true

        yield

      ensure
        stream.reopen( old_stream )
        old_stream.close

      end
    end
  end
end
