# Zachery's Rails Template, based off Darcy Laycock's Template
require 'open-uri'
GITHUB_USER = "zacheryph"
do_sudo_gem = false
do_authentication = false
do_authorization = false
do_audit = false
do_jobs = false
do_forms = false

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
  do_sudo_gem = true
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
from_repo "right.js",   "public/javascripts/right.js"
from_repo "rightui.js", "public/javascripts/rightui.js"

commit_state "install RightJS files"

##################################
# Adding the initial set of gems #
#################################

# core auth/model/etc
gem 'searchlogic',            :version => '>= 2.3.6'
gem 'state_machine',          :verison => '>= 0.8.0'
gem 'matthuhiggins-foreigner', :version => '>= 0.3.1', :lib => 'foreigner'

# Layout / View related stuff
gem 'will_paginate',          :version => '>= 2.3.11'

# testing stuff
gem 'shoulda',                :version => '>= 2.10.2'
gem 'rails-footnotes',        :version => '>= 3.6.3'

# optional
if yes?("* Background Tasks?")
  gem 'delayed_job',          :version => '>= 1.8.4'
  do_jobs = true
end

if yes?("* File Uploads?")
  gem 'paperclip',            :version => '>= 2.3.1.1'
end

if yes?("* Inherited Resources?")
  gem 'inherited_resources',  :version => '>= 0.9.2'
end

if yes?("* Formtastic?")
  gem 'formtastic',             :version => '>= 0.9.2'
  gem 'validation_reflection',  :version => '>= 0.3.5'
  do_forms = true
end

if yes?("* Authentication?")
  gem 'warden',               :version => '>= 0.5.2'
  gem 'devise',               :version => '>= 0.4.3'
  do_authentication = true
end

if yes?("* Authorization?")
  gem 'declarative_authorization', :version => '>= 0.4'
  do_authorization = true
end

if yes?("* Auditing?")
  gem 'paper_trail',          :version => '>= 1.2.13'
  do_audit = true
end

commit_state "Add base gems to app"

# lets install all these bad boys now
rake 'gems:install', :sudo => do_sudo_gem

########################################
# lets generate all our special stuff #
########################################
if do_forms
  generate :formtastic

  commit_state 'add formtastic files'
end

if do_authentication || do_authorization
  if do_authentication
    generate :devise_install
    generate :devise, 'User'
    generate :devise_views
  end
  if do_authorization
    from_repo 'authorization_rules.rb.erb', 'config/authorization_rules.rb'
  end

  commit_state "Add authentication/authorization files"
end

if do_audit
  generate :paper_trail

  commit_state "Add paper_trail migration"
end

if do_jobs
  generate :delayed_job

  commit_state "Add delayed_job migration"
end

################################
# Finally, Run rake db migrate #
################################

rake "db:migrate"
commit_state "Migrate Database"

# gc the repo for fun
git :gc => '--aggressive --prune=now'