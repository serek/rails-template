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
  download "http://jqueryjs.googlecode.com/files/jquery-1.3.1.min.js", "jquery.js"
  download "http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js"
end

working_tree "jQuery Base"

##################################
# Adding the initial set of gems #
#################################

# Layout / View related stuff
gem 'mislav-will_paginate',  :version => '>= 2.2.3', :lib => 'will_paginate',  :source => 'http://gems.github.com'
gem 'haml',                  :version => '>= 2.1'
gem 'chriseppstein-compass', :lib => 'compass', :version => '>= 0.3.4'
# Testing stuff
gem "thoughtbot-shoulda",    :lib => "shoulda", :version => ">= 2.0.5"
gem "redgreen"
gem "quietbacktrace"
gem "rr"
# *logic gems
gem "authlogic"
gem "searchlogic"
# General
gem 'rubyist-aasm',          :lib => "aasm"

working_tree "Added gems to the app"

###########################
# Initialize HAML / Rails #
###########################

run "haml --rails ."
run "echo -e 'y\nn\n' | compass --rails -f blueprint"

working_tree "Initialize Rails"

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
  name: Some Site
END

working_tree "added blank config"

