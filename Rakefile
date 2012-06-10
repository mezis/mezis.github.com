require 'rake/clean'
require 'pry'
require 'haml'
require 'listen'

CLOBBER.include('_site')

HAML = FileList['{_layouts/,_includes/,}*.haml']
SASS = FileList['assets/stylesheets/[^_]*.sass']

HTML = HAML.ext('.html')
CSS  = SASS.ext('.css')

CLEAN.include(*HTML)
CLEAN.include(*CSS)


rule '.html' => '.haml' do |t|
  puts %Q(haml "#{t.source}" -> "#{t.name}")
  File.open(t.name,'w') do |out|
    data = File.open(t.source).read
    out.write Haml::Engine.new(data).render
  end
end


rule '.css' => '.sass' do |t|
  sh %Q{compass compile -q -r bootstrap-sass -s nested --images-dir assets/images --sass-dir assets/stylesheets --css-dir assets/stylesheets}
end


desc "Auto-compile Haml"
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


desc "Auto-compile Sass"
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
task :haml => HTML


desc "Compile Sass files"
task :sass => CSS


desc "Launch preview environment"
task :preview => (HTML + [:watch_haml, :watch_sass]) do
  system "jekyll --auto --server"
end


desc "Build site"
task :build => (HTML+CSS) do |task, args|
  system "jekyll --no-auto"
end


task :default => :preview

