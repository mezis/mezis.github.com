require 'rake/clean'
require 'pry'
require 'haml'
require 'listen'

CLOBBER.include('_build')

HAML = FileList['_source/{_layouts/,_includes/,}*.haml']
SASS = FileList['_source/assets/stylesheets/[^_]*.sass']

HTML = HAML.map do |haml_path|
  html_path = haml_path.sub(/^_source\//,'').sub(/\.haml$/,'.html')
  file html_path => haml_path do |t|
    puts %Q(haml "#{t.prerequisites.first}" -> "#{t.name}")
    File.open(t.name,'w') do |out|
      data = File.open(t.prerequisites.first).read
      out.write Haml::Engine.new(data).render
    end
  end
  CLEAN.include(html_path)
  html_path
end


CSS  = SASS.map do |sass_path|
  css_path = sass_path.sub(/^_source\//,'').sub(/\.sass$/,'.css')
  file css_path => sass_path do |t|
    sh %Q{compass compile -q -r bootstrap-sass -s compressed --sass-dir _source/assets/stylesheets --css-dir assets/stylesheets}
  end
  CLEAN.include(css_path)
  css_path
end



desc "Auto-compile Haml to HTML"
task :watch_haml do
  Thread.new do
    Listen.to('.', :filter => /\.haml$/) do |modified, added, removed|
      Rake::Task['haml'].tap do |task|
        task.prerequisite_tasks.each(&:reenable)
        task.reenable
        task.invoke
      end
    end
  end
end


desc "Auto-compile Sass to CSS"
task :watch_sass do
  Thread.new do
    Listen.to('.', :filter => /\.sass$/) do |modified, added, removed|
      begin
        Rake::Task['sass'].tap do |task|
          task.prerequisite_tasks.each(&:reenable)
          task.reenable
          task.invoke
        end
      rescue Exception => e
        puts "error: #{e.message}"
      end
    end
  end
end


desc "Compile Haml files"
task :html => HTML


desc "Compile Sass files"
task :css => CSS


desc "Launch preview environment"
task :preview => (HTML + [:watch_haml, :watch_sass]) do
  system "jekyll --auto --server"
end


desc "Build site"
task :build => [:html,:css] do
  system "jekyll --no-auto"
end


task :default => :preview

