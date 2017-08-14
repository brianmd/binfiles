#!/usr/bin/env ruby
require 'net/http'
require 'nokogiri'
require 'json'

fullfilename = ARGV[0]
fullpath = File.dirname fullfilename
# Strip off extension. This is for protection of file in case we re-run after erb file has already been moved.
filename = File.basename fullfilename, ".html.erb"
infilename = "#{filename}.html.erb"
outfilename = "#{fullpath}/#{filename}.html.haml"
tokens = fullfilename.split "/"
path = tokens[3]

cmd = "mv #{fullpath}/#{infilename} /tmp/"
puts cmd
`#{cmd}`

puts "translating #{filename} in html path #{path}"

# url = "http://localhost:3000/#{path}/#{filename}"
# puts "url: #{url}"
# uri = URI(url)
# source = Net::HTTP.get(uri)

url = "/tmp/#{infilename}"
puts url
source = File.open(url, 'r') {|f| f.read}

n = Nokogiri::HTML source
puts
puts
forms = n.css 'form'
names = forms.collect {|f| f['id']}
formname = names.select {|f| f!=nil && f!=''}.first
puts names.to_json
puts formname

cmd = "html2haml -e /tmp/#{infilename} tempfile"
puts cmd
`#{cmd}`



# modify haml file

appendtext = """
:coffee
  $ ->
    window.v = Summit.validate '\##{formname}'


"""

sed_patterns = ['s/:\([^ ]*\) => /\1: /g', 's/\/$//', 's/clearfloat/clear/', 's/formlabel/label/', 's/\.formfield//', 's/formbtn/btn/']

tags = ['size', 'valign', 'align', 'width', 'height', 'cellpadding', 'cellspacing', 'colspan', 'cols', 'rowspan', 'rows', 'style']

tags.each { |attr| sed_patterns << "s/#{attr}: \"[^\"]*\", //" }
tags.each { |attr| sed_patterns << "s/#{attr}: \"[^\"]*\"}/}/" }

sed_patterns << 's/, }/}/'
sed_patterns << 's/{}//'

cmd = "cat tempfile | " + (sed_patterns.collect {|p| "sed '#{p}'"}).join(" | ") + " > #{outfilename}"
puts cmd
puts
puts
puts `#{cmd}`

open(outfilename, 'a') { |f| f.puts appendtext }
`rm tempfile`
