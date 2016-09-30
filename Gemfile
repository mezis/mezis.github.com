source 'https://rubygems.org'

ruby '2.3.1'

require 'json'
require 'open-uri'
versions = JSON.parse(open('https://pages.github.com/versions.json').read)

gem 'github-pages', versions['github-pages'], group: :jekyll_plugins

# Set us up to reload pages interactively
gem 'guard-jekyll-plus'
gem 'guard-livereload'

gem 'haml'
gem 'compass'
gem 'bootstrap-sass', git: 'https://github.com/thomas-mcdonald/bootstrap-sass.git'

gem 'rake'
gem 'pry'
gem 'listen'
gem 'rb-fsevent'
gem 'html-proofer'
