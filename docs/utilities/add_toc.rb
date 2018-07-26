# Add a TOC to a MarkDown file based on named anchors in headings.
# Heading levels from 2 ("## ...") or lower are included.
#
# Your Markdown document MUST include the following markup lines:
#
#     [](TOCS)
#     [](TOCE)
#
# ...each appearing at the start of a line. Everything in between will
# be replaced with the TOC. The markup above is maintained either side
# of the new TOC, so that subsequent runs just replace that TOC with
# an updated copy.
#
# The processor assumes a single top-level heading at level 1 which is
# expected to be the document's overall title and not included in the
# TOC. Only level 2 or below will be read. You need to write unique
# named anchors for headings for things to work; use this syntax:
#
#   ## <a name="heading_name"></a>Heading text
#
# ...for the processor to find the named anchor correctly.
#
# Call with "ruby add_toc.rb" and an optional space separated list of
# leafnames on the CLI which are relative to this script. If omitted,
# a collection of internally hard-coded leafnames will be processed
# by default.

dir   = File.dirname(__FILE__)
paths = []

args = if ARGV.empty?
  [
    '../api_specification/README.md'
  ] # Add other docs to this array if required
else
  ARGV
end

paths = args.map { | leaf | File.join(dir, leaf) }

paths.each do | path |
  puts "Adding table of contents to '#{path}'..."

  str      = File.read(path)
  headings = str.scan(/^\#\#.*$/)

  headings.map! do | heading |

    # Replace Markdown heading levels 2-6 with indented bullets

    heading.gsub!(/^\#\#\#\#\#\#/, '        * ')
    heading.gsub!(/^\#\#\#\#\#/,   '      * ')
    heading.gsub!(/^\#\#\#\#/,     '    * ')
    heading.gsub!(/^\#\#\#/,       '  * ')
    heading.gsub!(/^\#\#/,         '* ')

    # Replace "* <a name="foo"></a> Heading text" with MarkDown reference
    # syntax "* [Heading text](#foo)".
    #
    # Sometimes a document has a link that's not in a canonical form and
    # can be hard to guess when writing documentation. In that case, a new
    # canonical link can be inserted directly in front with the old one
    # kept to avoid breaking any existing links to the old named anchor.
    # The regular expression skips any subsequent patterns.
    #
    # Example:
    #
    #   ### <a name="canonical"></a><a name="old_thing"></a>Heading text
    #
    heading.gsub!(/\*\s*?(\<a name\=\"(.*?)\"\>\<\/a\>)(\<a name\=\"(.*?)\"\>\<\/a\>)*(.*)$/, '* [\5](#\2)')

    heading
  end

  headings = headings.join("\n")

  # Assume the file has an existing table of contents where the
  # first entry will begin with "* [" at the start of the line. Assume
  # the TOC is followed immediately by a heading at any level, found by
  # "^#"; replace all lines in between with the headings (making sure
  # we add a blank line after and put back the "#" we overwrite).

  str.sub!(/^\[\]\(TOCS\)\s*$.*\[\]\(TOCE\)\s*$/m, "[](TOCS)\n\n" + headings + "\n\n[](TOCE)\n")

  # Write the updated result

  File.write(path, str)

end

puts "...Finished."
