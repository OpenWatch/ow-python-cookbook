#
# Cookbook Name:: ow_python
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

ssh_secrets = Chef::EncryptedDataBagItem.load(node['ow_python']['ssh_databag_name'] , node['ow_python']['ssh_databag_item_name'] )
secrets = Chef::EncryptedDataBagItem.load(node['ow_python']['secret_databag_name'] , node['ow_python']['python_databag_item_name'] )
ssh_key = Chef::EncryptedDataBagItem.load("ssh", "git")

# Setup postgresql database
postgresql_database node['ow_python']['db_name'] do
  connection ({
  		:host => "127.0.0.1", 
  		:port => node['ow_python']['db_port'], 
  		:username => node['ow_python']['db_user'], 
  		:password => node['postgresql']['password']['postgres']
  })
  action :create
end

# Deploy Django app with git and virtualenv
# Install pre-req packages
packages = ["libjpeg-dev", "libxml2-dev", "libxslt-dev"]
packages.each do |app|
  package app
end
# Create a virtualenv
virtualenv_path = "/home/" + node['ow_python']['service_user'] + "/.virtualenvs/" + node['ow_python']['virtualenv_name']
python_virtualenv virtualenv_path  do
  owner node['ow_python']['service_user']   
  group node['ow_python']['service_user_group']
  action :create
end

# Establish ssh wrapper for the git user
git_ssh_wrapper "ow-github" do
  owner node['ow_python']['git_user']
  group node['ow_python']['service_user_group']
  ssh_key_data ssh_secrets['id_rsa']
end

# Make git checkout dir
directory node['ow_python']['app_root'] do
  owner node['ow_python']['git_user']
  group node['ow_python']['service_user_group']
  recursive true
  action :create
end

# Git checkout
git node['ow_python']['app_root'] do
   repository node['ow_python']['git_url'] 
   revision node['ow_python']['git_rev']  
   ssh_wrapper "/home/" + node['ow_python']['git_user'] + "/.ssh/wrappers/ow-github_deploy_wrapper.sh"
   action :sync
   user node['ow_python']['git_user']
   group node['ow_python']['service_user_group']
end

# Setup git repository for remote use

=begin
# Copy post-update hook file
# To reset --hard on push
cookbook_file node['ow_python']['app_root'] + '/.git/hooks/post-update'  do
  source "post-update"
  owner node['ow_python']['git_user']
  group node['ow_python']['service_group'] 
  action :create_if_missing # see actions section below
end
=end

# Create /.git/config
template node['ow_python']['app_root'] + "/.git/config" do
    source "config.erb"
    owner node['ow_python']['git_user']   
    group node['ow_python']['service_user_group']   
    variables({     
      :git_url => node['ow_python']['git_url']  
    })
    action :create
end

# Pip install -r requirements.txt
execute "pip install requirements.txt" do
    user "root"
    command virtualenv_path + "/bin/pip install -r " + node['ow_python']['app_root'] + "/requirements.txt"
end

# Make local_settings.py 
template node['ow_python']['app_root'] + "/reopenwatch/reopenwatch/local_settings.py" do
    source "local_settings.py.erb"
    owner node['ow_python']['git_user']   
    group node['ow_python']['service_user_group']   
    mode "770"
    variables({
      :db_name => node['ow_python']['db_name'],
      :db_user => node['ow_python']['db_user'],
      :db_password => node['postgresql']['password']['postgres'],
      :db_host => node['ow_python']['db_host'],
      :db_port => node['ow_python']['db_port'],
      :node_api_user => secrets['django_api_user'],
      :node_api_secret => secrets['django_api_password'],
      :etherpad_url => node['ow_python']['etherpad_url'],
      :etherpad_pad_url => node['ow_python']['etherpad_pad_url'],
      :etherpad_api_key => secrets['etherpad_api_key'],
      :mailgun_api_key => secrets['mailgun_api_key'],
      :stripe_secret => secrets['stripe_secret'],
      :stripe_publishable => node['ow_python']['stripe_publishable'],
      :aws_access_key_id => secrets['aws_access_key_id'],
      :aws_secret_access_key => secrets['aws_secret_access_key'],
      :aws_bucket_name => node['ow_python']['aws_bucket_name'],
      :sentry_dsn => secrets['sentry_dsn'],
      :embedly_api_key => secrets['embedly_api_key'],
      :chef_node_name => Chef::Config[:node_name]
    })
    action :create
end

# Create and set permissions on upload directories
directory node['ow_python']['app_root'] + "/media/recordings" do
  owner node['ow_python']['service_user'] 
  group node['ow_python']['service_user_group']
  mode "770"
  action :create
end

directory node['ow_python']['app_root'] + "/media/uploads" do
  owner node['ow_python']['service_user'] 
  group node['ow_python']['service_user_group']
  mode "770"
  action :create
end

# Make Nginx log dirs
directory node['ow_python']['log_dir'] do
  owner node['nginx']['user']
  group node['nginx']['group']
  recursive true
  action :create
end

# Nginx config file
template node['nginx']['dir'] + "/sites-enabled/ow_python.nginx" do
    source "ow_python.nginx.erb"
    owner node['nginx']['user']
    group node['nginx']['group']
    variables({
    :http_listen_port => node['ow_python']['http_listen_port'],
    :https_listen_port => node['ow_python']['https_listen_port'],
    :client_max_body_size => node['ow_python']['client_max_body_size'],
    :domain => node['ow_python']['domain'],
    :internal_port => node['ow_python']['internal_port'],
    :ssl_cert => node['ow_python']['ssl_dir'] + node['ow_python']['ssl_cert'],
    :ssl_key => node['ow_python']['ssl_dir'] + node['ow_python']['ssl_key'],
    :app_root => node['ow_python']['app_root'],
    :access_log => node['ow_python']['log_dir'] + node['ow_python']['access_log'],
    :error_log => node['ow_python']['log_dir'] + node['ow_python']['error_log'],
    :proxy_pass => node['ow_python']['proxy_pass']
    })
    notifies :restart, "service[nginx]"
    action :create
end

# Upstart service config file
template "/etc/init/" + node['ow_python']['service_name'] + ".conf" do
    source "upstart.conf.erb"
    owner node['ow_python']['service_user'] 
    group node['ow_python']['service_user_gid'] 
    variables({
    :service_user => node['ow_python']['service_user'],
    :virtualenv_path => virtualenv_path,
    :app_root => node['ow_python']['app_root'],
    :app_name => node['ow_python']['app_name'],
    :access_log_path => node['ow_python']['log_dir'] + node['ow_python']['service_log'],
    :error_log_path => node['ow_python']['log_dir'] + node['ow_python']['service_error_log']
    })
end

# Make service log file
file node['ow_python']['log_dir'] + node['ow_python']['service_log']  do
  owner node['ow_python']['service_user']
  group node['ow_python']['service_group'] 
  action :create_if_missing # see actions section below
end

# Make service error log file
file node['ow_python']['log_dir'] + node['ow_python']['service_error_log']  do
  owner node['ow_python']['service_user']
  group node['ow_python']['service_group'] 
  action :create_if_missing # see actions section below
end

# Register capture app as a service
service node['ow_python']['service_name'] do
  provider Chef::Provider::Service::Upstart
  action :enable
end

# Register database backups
# Add to cron
cron "postgres_backups" do
  hour node['ow_python']['backup_hour']
  minute node['ow_python']['backup_minute']
  command virtualenv_path + "/bin/python " + node['ow_python']['app_root'] + "/reopenwatch/manage.py backup_postgres --execute"
end

