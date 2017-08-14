require 'rake'
require 'fileutils'

begin
  # not always loaded
  require 'clipboard'
rescue

end

Rake.application.options.trace = false
verbose(false)

# look at veewee (in relation to vagrant)


desc "build a new rails app. r new[appname]. answers are in clipboard."
task :new, [:appname, :url] => 'composer:new'


task default: ['env:setup']

task :test, :printme do |t,args|
  with('~') do |dirname|
    sh "ls #{dirname}"
    puts ""
    puts "you passed: #{args[:printme]}"
  end
end

task :testtest, :printme do |t,args|
  puts "in testtest, about to run test"
  Rake::Task[:test].invoke(args[:printme])
end

task :append_test do
  append_before_end('junk3/config/environments/development.rb',"  asdf")
end


def append(filename, text)
  File.open(filename, 'a') do |out|
    out.puts text
  end
end

def append_before_end(filename, text)
  lines = File.readlines(filename)
  return if lines.size < 3
  end_lines = lines[-2..-1]
  lines[-2] = text
  lines[-1] = end_lines[0]
  lines[lines.size] = end_lines[1]
  File.open(filename, 'w') do |out|
    out.puts lines
  end
end



# task :append, [:filename, :text] do |t, args|
#   filename = args[:filename]
#   File.open(filename, 'a') do |out|
#     out.puts ''
#     out.puts args[:text]
#     out.puts ''
#   end
#   # sh "echo '' >> #{filename}"
#   # sh "echo '' >> #{filename}"
#   # sh "echo '#{args[:text]}' >> #{filename}"
# end


namespace :env do
  task :test do
    sh "echo testing"
  end

  file ".envrc" do
    sh "cp ~/etc/direnv/localhost3000 .envrc" unless (Dir.entries '.').include? ".envrc"
  end

  desc "Setup directory"
  task :setup => ".envrc"
end


namespace :composer do
  task :answers do
    puts "Paste the answers from the clipboard."
#    Clipboard.copy "3 2 2 3 2 2 3 2 2 3 2 1 2 2 1 2 y n n n y n root gobbly7 y y".split(" ").join("\n") + "\n\n\n"
    Clipboard.copy "3 2 2 3 2 2 3 2 2 3 2 1 1 1 1 2 y n n n y n #{ENV['DB_USERNAME'] || 'root'} #{ENV['DB_PASSWORD'] || 'gobbly7'} y y".split(" ").join("\n") + "\n\n\n"
  end


  task :new, [:appname, :composer_url] => [:answers] do |t, args|
    args.with_defaults(:appname => 'junk', :composer_url => "https://raw.github.com/RailsApps/rails-composer/master/composer.rb -T")
    appname = args[:appname]
    gemfilename = "#{appname}/Gemfile"
    url = args[:composer_url]
    raise "*****   #{appname} already exists   ******" if File.exist? appname
    sh "rails new #{appname} -m #{url}"
    # Rake::Task[:append].invoke(gemfilename,"gem 'devise'")
#    sh "cd #{appname} ; r env:setup"   # errors because can't load clipboard from inside rails directory
    append gemfilename, "gem 'devise'"
    sh "cd #{appname} ; getdirenv"
    sh "cd #{appname} ; bundle install ; bundle exec rails g devise:install"
    append_before_end("#{appname}/config/environments/development.rb", "  config.action_mailer.default_url_options = { :host => ENV['RAILS_HOST'] || 'localhost:3000' }")
    sh "cd #{appname} ; bundle exec rake db:migrate"
    append gemfilename, ""
    append gemfilename, "gem 'protected_attributes'"
    append gemfilename, "gem 'activeresource'", require: 'active_resource'
    append gemfilename, "gem 'cancan'", '~> 1.6.10'
    append gemfilename, "gem 'activeadmin', github: 'gregbell/active_admin', branch: 'rails4'"
    sh "cd #{appname} ; bundle install ; bundle exec rails g active_admin:install"
    sh "cd #{appname} ; bundle exec rake db:migrate"
#    sh "cd #{appname} ; bundle exec rails g active_admin:"
  end
end


namespace :edit do
  desc "Edit summit directory"
  task :summit do
    `subl ~/Dropbox/summit`
  end

  desc "Edit blue harvest directory"
  task :blueharvest do
    `subl ~/Documents/git/blue-harvest`
  end

  task :bh => :blueharvest
end




def with(value)
  # synonymn for FileList
  yield(value)
end

class Task 
  def investigation
    result = "------------------------------\n"
    result << "Investigating #{name}\n" 
    result << "class: #{self.class}\n"
    result <<  "task needed: #{needed?}\n"
    result <<  "timestamp: #{timestamp}\n"
    result << "pre-requisites: \n"
    prereqs = @prerequisites.collect {|name| Task[name]}
    prereqs.sort! {|a,b| a.timestamp <=> b.timestamp}
    prereqs.each do |p|
      result << "--#{p.name} (#{p.timestamp})\n"
    end
    latest_prereq = @prerequisites.collect{|n| Task[n].timestamp}.max
    result <<  "latest-prerequisite time: #{latest_prereq}\n"
    result << "................................\n\n"
    return result
  end
end


# might do this to reset the test database:
#    RAILS_ENV=test db:hard_reset

namespace :db do
  desc "Crush and burn the database"
  task :hard_reset => :environment do
    File.delete("db/schema.rb")
    Rake::Task["db:drop"].execute
    Rake::Task["db:create"].execute
    Rake::Task["db:migrate"].execute
    Rake::Task["db:seed"].execute
    if !Rails.env.test?
      Rake::Task["db:data"].execute
    end
  end

  desc "Generate sample data for developing"
  task :data => :environment do
    # Create the sample data in here
  end

  desc "Load mysql_dev_data.sql"
  task :load_mysql_file do
    ` mysql --database=bible_test -u summit -p < mysql_dev_data.sql`
  end
end



# from http://archive.railsforum.com/viewtopic.php?id=29681
def log_task(message)
  if block_given?
    start = Time.now
    print "** [#{start.to_s}] #{message}..."
    yield
    puts " done! (#{"%2.2f" % (Time.now-start)}s)"
  else
    puts "** [#{DateTime.now.to_s}] #{message}."
  end
end
namespace :carla do  
  namespace :chores do
    namespace :periodic do
      desc "Runned hourly"
      task :hourly => ["carla:chores:hourly"] do
        log_task "Ran hourly tasks"
      end
      
      desc "Runned nightly @ 4:30AM"
      task :nightly => ["carla:chores:all"] do        
        log_task "Ran nightly tasks"
      end
      desc "Runned every evening @ 7:30PM"
      task :evening => ["carla:chores:upload_cadremploi_feed"] do
        log_task "Ran evening tasks"
      end
      
      desc "Updates crontab with hourly and nightly tasks"
      task :update_crontab do
        log_task "Updating crontab" do
          require 'erb'
        
          tmp_crontab = File.join(RAILS_ROOT, "/tmp/crontab")
          template = File.read(File.join(RAILS_ROOT, "/lib/tasks/carla.cron.erb"))
        
          # Creates crontab
          File.open(tmp_crontab, 'w') do |f|
            f.write(ERB.new(template).result(binding))
          end
        
          # Creates logfile if it doesn't exist
          system("touch #{File.join(RAILS_ROOT, "/log/chores.log")}")
        
          # Install crontab
          system("crontab #{tmp_crontab}")
        
          # Cleanup
          system("rm -f #{tmp_crontab}")
        end
      end
    end
    
    desc "Purges old sessions"
    task :purge_sessions => :environment do
      log_task "Deleting old sessions" do
        ActiveRecord::Base.connection.execute("DELETE FROM `sessions` WHERE `updated_at`<'#{DateTime.now.advance(:hours => -1).to_s(:db)}';")
      end
    end
    
    desc "Cleans temp folders"
    task :purge_temp_folders do
      log_task "Cleaning temporary folders" do
        folders = ["tmp/attachment_fu", "tmp/conversions"]
        folders.each do |folder|
          system("rm -rf #{File.join(RAILS_ROOT, folder, "*")}")
        end
      end
    end
    desc "Runs backups"
    task :run_backups do
      require 'net/ftp'
      require 'net/http'
      require 'uri'
      require 'yaml'
      servers = []
      servers << {:host => 'host1.domain.fr', :login => 'hostlogin', :password => '*****'}
      servers << {:host => 'host2.domain.fr', :login => 'backups', :password => '*****'}
      log_task "Running SVN backup" do
        backup_filename = "#{DateTime.now.strftime("%Y_%m_%d_%H_%M")}_svn_repositories.tar.bz2"
        backup_file = File.join(RAILS_ROOT, "tmp", backup_filename)
        system("tar -cj /var/svn > #{backup_file}")
        servers.each do |server|
          begin
            Net::FTP.open(server[:host]) do |ftp|
              ftp.login(server[:login], server[:password])
              ftp.put(backup_file)
            end
          rescue Exception => e
            puts("\n** Error while uploading backup to #{server[:host]}\n** Error was : #{e.message}\n")
          end
        end
        system("rm -f #{backup_file}")
      end
    end
  end
end
# SHELL=/bin/bash
# PATH=/usr/local/bin:/usr/local/sbin:/root/sbin:/bin:/usr/bin:/opt/ruby-enterprise-1.8.6/bin
# 00  *  * * *  RAILS_ENV=production rake -f <%= RAILS_ROOT %>/Rakefile carla:chores:periodic:hourly >> <%= RAILS_ROOT %>/log/chores.log 2>&1
# 30  4  * * *  RAILS_ENV=production rake -f <%= RAILS_ROOT %>/Rakefile carla:chores:periodic:nightly >> <%= RAILS_ROOT %>/log/chores.log 2>&1
# 30  19 * * *  RAILS_ENV=production rake -f <%= RAILS_ROOT %>/Rakefile carla:chores:periodic:evening >> <%= RAILS_ROOT %>/log/chores.log 2>&1


