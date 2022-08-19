#!/usr/bin/env ruby
text = File.load(ARGV[1])
json = JSON.parse(text)
File.write(ARGV[2] || 'output.json', json.to_yaml)
