# Zachery's Rails Template, based off Darcy Laycock's Template
require 'open-uri'
GITHUB_USER = "zacheryph"
SUDO_GEM = false

def download(from, to = from.split("/").last)
  file to, open(from).read
rescue Exception => e
  puts "Frak me - No internets (#{e.message})"
  exit!
end

def from_repo(from, to = from.split("/").last)
  download("http://github.com/#{GITHUB_USER}/rails-template/raw/master/#{from}", to)
end

def commit_state(comment)
  git :add => "."
  git :commit => "-am '#{comment}'"
end

if yes?("Run gem command with sudo?")
  SUDO_GEM = true
end

####################
# Base Application #
####################

# Delete unnecessary files
run "rm README"
run "rm public/index.html"
run "rm public/favicon.ico"
run "rm public/robots.txt"
run "rm public/images/rails.png"
run "rm -f public/javascripts/*"
run "rm -rf vendor"

# Move the database config
run "cp config/database.yml config/database.yml.example"

# Git ignore Setup
run "touch tmp/.gitignore log/.gitignore"
run %{find . -type d -empty | grep -v ".git" | grep -v "tmp" | xargs -I xxx touch xxx/.gitignore}
from_repo "raw_gitignore", ".gitignore"

git :init
commit_state "Base Rails Application"

######################
# View Related Stuff #
######################

# Download RightJS
download "http://rightjs.org/builds/current/right.js", "public/javascripts/right.js"

commit_state "RightJS Base"

##################################
# Adding the initial set of gems #
#################################

# core auth/model/etc
gem 'searchlogic',            :version => '>= 2.3.6'
gem 'state_machine',          :verison => '>= 0.8.0'

# Layout / View related stuff
gem 'will_paginate',          :version => '>= 2.3.11'

# testing stuff
gem 'shoulda',                :version => '>= 2.10.2'
gem 'sanitize_email',         :version => '>= 0.3.6'

# optional
if yes?("* Background Tasks?")
  gem 'delayed_job',          :version => '>= 1.8.4'
end

if yes?("* File Uploads?")
  gem 'paperclip',            :version => '>= 2.3.1.1'
end

if yes?("* Inherited Resources?")
  gem 'inherited_resources',  :version => '>= 0.9.2'
end

commit_state "Add base gems to app"

########################################
# Generates a user, controller + views #
########################################

if yes?("* Authentication?")
  gem 'warden',               :version => '>= 0.5.2'
  gem 'devise',               :version => '>= 0.4.3'

  rake 'gems:install', :sudo => SUDO_GEM

  generate :devise_install
  generate :devise, 'User'
  generate :devise_views

  commit_state "Add basic devise authorization"
else
  rake 'gems:install', :sudo => SUDO_GEM
end

################################
# Finally, Run rake db migrate #
################################

rake "db:migrate"
commit_state "Migrate Database"

# gc the repo for fun
git :gc => '--aggressive --prune=now'