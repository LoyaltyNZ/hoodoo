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
# Call with "ruby add_toc.rb" and an optional space separated list of
# leafnames on the CLI which are relative to this script. If omitted,
# file "api_specification.md" in the PWD will be processed by default.

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

    # Replace "* <a name="foo"></a> Heading text" with
    # MarkDown reference syntax "* [Heading text](#foo)"

    heading.gsub!(/\*\s*?(\<a name\=\"(.*?)\"\>\<\/a\>)(.*)$/, '* [\3](#\2)')

    heading
  end

  headings = headings.join("\n")

  # Assume the file has an existing table of contents where the
  # first entry will begin with "* [" at the start of the line. Assume
  # the TOC is followed immediately by a heading at any level, found by
  # "^#"; replace all lines in between with the headings (making sure
  # we add a blank line after and put back the "#" we overwrite).

  str.sub!(/^\[\]\(TOCS\)\s*$.*\[\]\(TOCE\)\s*$/m, "[](TOCS)\n" + headings + "\n[](TOCE)\n")

  # Write the updated result

  File.write(path, str)

end

puts "...Finished."
