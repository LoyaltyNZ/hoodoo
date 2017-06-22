########################################################################
# File::    ddtrace.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Override DataDog 'require "ddtrace"'. The test suite
#           cannot allow "real" DataDog to be loaded as this would hook
#           into all kinds of things and interfere with test results,
#           especially for tests covering variant behaviour for when
#           DataDog is present or absent.
# ----------------------------------------------------------------------
#           22-June-2017 (JRW): Created.
########################################################################

# Yes, this is empty, just comments. The whole point is to allow code to
# be able to require what it thinks is DataDog without a LoadError
# exception being raised, but not actually define any DataDog components
# until the test suite is good and ready to do so (with mock data).