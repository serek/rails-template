# Darcy's Rails Template, based off Peter Cooper's Template
# and James Cox's fork. Using some code from:
# * http://github.com/lackac/app_lego/tree

require 'open-uri'

GITHUB_USER = "Sutto"

def download(from, to = from.split("/").last)
  #run "curl -s -L #{from} > #{to}"
  file to, open(from).read
end

def from_repo(from, to = from.split("/").last)
  download("http://github.com/#{GITHUB_USER}/rails-template/raw/master/#{from}", to)
end

def commit_state(comment)
  git :add => "."
  git :commit => "-am '#{comment}'"
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

# Move the database config
run "cp config/database.yml config/database.yml.example"

# Git ignore Setup
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run %{find . -type d -empty | grep -v "vendor" | grep -v ".git" | grep -v "tmp" | xargs -I xxx touch xxx/.gitignore}
from_repo "raw_gitignore", ".gitignore"

git :init
commit_state "Added base / rough application"

######################
# View Related Stuff #
######################

# Download JQuery
run "mkdir -p public/javascripts/jquery"
download "http://jqueryjs.googlecode.com/files/jquery-1.3.1.min.js", "public/javascripts/jquery/jquery.min.js"
download "http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js", "public/javascripts/jquery/jquery.form.js"

commit_state "jQuery Base"

##################################
# Adding the initial set of gems #
#################################

# Layout / View related stuff
gem 'mislav-will_paginate',  :version => '>= 2.2.3', :lib => 'will_paginate',  :source => 'http://gems.github.com'
gem 'haml',                  :version => '>= 2.1'
gem 'chriseppstein-compass', :lib => 'compass', :version => '>= 0.3.4'
# Testing stuff
gem "thoughtbot-shoulda",    :lib => "shoulda"
gem "quietbacktrace"
gem "rr"
# General
gem "searchlogic"
gem 'rubyist-aasm',          :lib => "aasm"

commit_state "Added gems to the app"

###########################
# Initialize HAML / Rails #
###########################

run "haml --rails ."
run "echo -e 'y\nn\n' | compass --rails ."
run "mkdir -p public/stylesheets/960"
%w(text reset 960).each do |file|
  from_repo "#{file}.css", "public/stylesheets/960/#{file}.css"
end
file "app/stylesheets/screen.sass", "@import compass/utilities.sass\n@import util.sass\n"
from_repo "util.sass", "app/stylesheets/_util.sass"

commit_state "Initialize Haml and Compass"

######################################
# Install all of the default plugins #
######################################

#plugin "paperclip",  :git => "git://github.com/thoughtbot/paperclip.git"
plugin "machinist",  :git => "git://github.com/notahat/machinist.git"
plugin "forgery",    :git => "git://github.com/sevenwire/forgery.git"
plugin "workling",   :git => "git://github.com/purzelrakete/workling.git"
plugin "spawn",      :git => "git://github.com/tra/spawn.git"
plugin "nh-toolkit", :git => "git://github.com/Sutto/ninjahideout-toolkit.git"
plugin "air_budd_form_builder", :git => "git://github.com/airblade/air_budd_form_builder.git"

commit_state "Added plugins"

##################################
# Initialize the Settings Plugin #
##################################

file "config/site.yml",<<-END
default:
  site_name: Some Site
END

commit_state "Set up default site settings"

###############################
# Setup the default templates #
###############################

run "mkdir -p app/views/shared"

from_repo "application.html.haml", "app/views/layouts/application.html.haml"
from_repo "header.html.haml",      "app/views/shared/_header.html.haml"
from_repo "footer.html.haml",      "app/views/shared/_footer.html.haml"
from_repo "app_controller.rb",     "app/controllers/application_controller.rb"
run "mkdir -p test/blueprints"
from_repo "test_helper.rb",        "test/test_helper.rb"
from_repo "user_blueprint.rb",     "test/blueprints/user_blueprint.rb"
commit_state "added default layout"

########################################
# Generates a user, controller + views #
########################################

if yes?("Would you like authentication?")
  gem "authlogic"
  generate :controller, "Users"
  generate :controller, "UserSessions"
  # Controllers
  from_repo "auth/users_controller.rb",         "app/controllers/users_controller.rb"
  from_repo "auth/user_sessions_controller.rb", "app/controllers/user_sessions_controller.rb"
  # Views
  %w(_form edit new).each do |name|
    from_repo "auth/users.#{name}.html.haml", "app/views/users/#{name}.html.haml"
  end
  from_repo "auth/login.html.haml", "app/views/user_sessions/new.html.haml"
  # Routes
  route "map.resources :users"
  route "map.resource  :user_session"
  # Models
  generate :session, "UserSession"
  fields = [
    "login:string", "crypted_password:string", "password_salt:string",
    "persistence_token:string", "single_access_token:string", "perishable_token:string",
    "login_count:integer", "last_request_at:datetime", "current_login_at:datetime",
    "last_login_at:datetime", "current_login_ip:string", "last_login_ip:string",
    "display_name:string", "created_at:datetime", "updated_at:datetime", "type:string", "slug:string"
  ]
  generate :model,   "User", fields.join(" ")
  from_repo "auth/user.rb",         "app/models/user.rb"
  from_repo "auth/user_session.rb", "app/models/user_session.rb"
  commit_state "Added basic authorization stuff"
end

##################################################
# If the user says to, add a default index site. #
##################################################

if yes?("Would you like to generate a default index?")
  controller = "class SiteController < ApplicationController\n\n  def index\n    page_is 'Welcome'\n  end\n\nend\n"
  # Actually do the work
  generate :controller, "Site"
  route    "map.root :controller => 'site'"
  file     "app/views/site/index.html.haml", "%h2== Welcome to \#{Settings.site_name}\n"
  file     "app/controllers/site_controller.rb", controller
  commit_state "Added a default site controller"
end

################################
# Finally, Run rake db migrate #
################################

rake "db:migrate"

host = ask("Enter Passenger Host Name (empty for none)")
unless host.blank?
  run "sudo board-train . #{host}"
end