########################################################################
# File::    newrelic_rpm.rb
# (C)::     Loyalty New Zealand 2016
#
# Purpose:: Override NewRelic 'require "newrelic_rpm"'. The test suite
#           cannot allow "real" NewRelic to be loaded as this would hook
#           into all kinds of things and interfere with test results,
#           especially for tests covering variant behaviour for when
#           NewRelic is present or absent.
# ----------------------------------------------------------------------
#           13-Apr-2016 (ADH): Created.
########################################################################

# Yes, this is empty, just comments. The whole point is to allow code to
# be able to require what it thinks is NewRelic without a LoadError
# exception being raised, but not actually define any NewRelic components
# until the test suite is good and ready to do so (with mock data).
