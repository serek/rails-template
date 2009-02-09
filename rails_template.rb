# Darcy's Rails Template, based off Peter Cooper's Template
# and James Cox's fork. Using some code from:
# * http://github.com/lackac/app_lego/tree
# *

GITHUB_USER = "Sutto"

def download(from, to = from.split("/").last)
  run "curl -s -L #{from} > #{to}"
end

def from_repo(from, to = from.split("/").last)
  download("http://github.com/#{GITHUB_USER}/rails-template/raw/master/#{from}", to)
end

def working_tree(comment)
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
working_tree "Added base / rough application"

######################
# View Related Stuff #
######################

# Download JQuery
inside "public/javascripts/" do
  download "http://jqueryjs.googlecode.com/files/jquery-1.3.1.min.js", "jquery/jquery.min.js"
  download "http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js", "jquery/jquery.form.js"
end

working_tree "jQuery Base"

##################################
# Adding the initial set of gems #
#################################

# Layout / View related stuff
gem 'mislav-will_paginate',  :version => '>= 2.2.3', :lib => 'will_paginate',  :source => 'http://gems.github.com'
gem 'haml',                  :version => '>= 2.1'
gem 'chriseppstein-compass', :lib => 'compass', :version => '>= 0.3.4'
gem 'chriseppstein-compass-960-plugin', :lib => 'ninesixty'
# Testing stuff
gem "thoughtbot-shoulda",    :lib => "shoulda", :version => ">= 2.0.5"
gem "redgreen"
gem "quietbacktrace"
gem "rr"
# General
gem "searchlogic"
gem 'rubyist-aasm',          :lib => "aasm"

working_tree "Added gems to the app"

###########################
# Initialize HAML / Rails #
###########################

run "haml --rails ."
run "echo -e 'y\nn\n' | compass --rails -r ninesixty -f 960"

working_tree "Initialize Haml and Compass"

######################################
# Install all of the default plugins #
######################################

plugin "paperclip",  :git => "git://github.com/thoughtbot/paperclip.git"
plugin "machinist",  :git => "git://github.com/notahat/machinist.git"
plugin "forgery",    :git => "git://github.com/sevenwire/forgery.git"
plugin "workling",   :git => "git://github.com/purzelrakete/workling.git"
plugin "spawn",      :git => "git://github.com/tra/spawn.git"
plugin "nh-toolkit", :git => "git://github.com/Sutto/ninjahideout-toolkit.git"
plugin "air_budd_form_builder", :git => "git://github.com/airblade/air_budd_form_builder.git"

working_tree "Added plugins"

##################################
# Initialize the Settings Plugin #
##################################

file "config/site.yml",<<-END
default:
  site_name: Some Site
END

working_tree "Set up default site settings"

###############################
# Setup the default templates #
###############################

run "mkdir -p app/views/shared"

inside "app/views" do
  download "application.html.haml", "layouts/application.html.haml"
  download "header.html.haml",      "shared/_header.html.haml"
  download "footer.html.haml",      "shared/_footer.html.haml"
end

working_tree "added default layout"

########################################
# Generates a user, controller + views #
########################################

if yes?("Would you like authentication?")
  gem "authlogic"
  generate :controller, "Users"
  generate :controller, "UserSessions"
  # Controllers
  inside "app/controllers" do
    from_repo "auth/users_controller.rb"
    from_repo "auth/user_sessions_controller.rb"
  end
  # Views
  inside "app/views" do
    %w(_form edit new).each do |name|
      from_repo "auth/users.#{name}.html.haml", "users/#{name}.html.haml"
    end
    from_repo "login.html.haml", "user_sessions/new.html.haml"
  end
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
  inside "app/models" do
    from_repo "auth/user.rb"
    from_repo "auth/user_session.rb"
  end
  working_tree "Added basic authorization stuff"
end

##################################################
# If the user says to, add a default index site. #
##################################################

if yes?("Would you like to generate a default index?")
  controller = "class SiteController < ApplicationController\n\n  def index\n  page_is 'Welcome'\n  end\n\nend\n"
  # Actually do the work
  generate :controller, "Site"
  route    "map.root :controller => 'site'"
  file     "app/views/site/index.html.haml", "%h2== Welcome to \#{Settings.site_name}\n"
  file     "app/controllers/site_controller.rb", controllers
  working_tree "Added a default site controller"
end

################################
# Finally, Run rake db migrate #
################################

rake "db:migrate"

# if (host = ask?("Enter Passenger Host Name (empty for none)"))
#   
# end