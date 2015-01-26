########################################################################
# File::    logger.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include the schema based data validation and rendering code.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

# Dependencies

require 'communicators'

# Logger code

require 'logger/logger'
require 'logger/writer_mixin'
require 'logger/flattener_mixin'
require 'logger/fast_writer'
require 'logger/slow_writer'
require 'logger/writers/file_writer'
require 'logger/writers/stream_writer'
require 'logger/writers/log_entries_dot_com_writer'
