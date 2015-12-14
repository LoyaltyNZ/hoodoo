########################################################################
# File::    logger.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include the schema based data validation and rendering code.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

# Dependencies

require 'hoodoo/communicators'

# Logger code

require 'hoodoo/logger/logger'
require 'hoodoo/logger/writer_mixin'
require 'hoodoo/logger/flattener_mixin'
require 'hoodoo/logger/fast_writer'
require 'hoodoo/logger/slow_writer'
require 'hoodoo/logger/writers/file_writer'
require 'hoodoo/logger/writers/stream_writer'
require 'hoodoo/logger/writers/log_entries_dot_com_writer'
