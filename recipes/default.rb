#
# Cookbook Name:: ow_python
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

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

#  Deploy Django app
application node['ow_python']['service_name'] do
  path node['ow_python']['app_root']
  owner node['ow_python']['git_user']
  group node['ow_python']['service_user_group']
  repository node['ow_python']['git_url']
  revision node['ow_python']['git_rev']
  deploy_key ssh_key['id_rsa']
  before_deploy do

  end
  #symlinks ( 'local_settings.py' => 'reopenwatch/reopenwatch/local_settings.py')
  migrate false
  packages ["libjpeg-dev", "libxml2-dev", "libxslt-dev"]

  django do
    requirements "requirements.txt"
    settings_template node['ow_python']['local_settings_file']
    local_settings_file 'local_settings.py'
    settings({
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
      :embedly_api_key => secrets['embedly_api_key']
    })
    debug true
    collectstatic false
  end
end

#  Symlink local_settings.py to reopenwatch/reopenwatch/local_settings.py
#  TODO: Get Django resource to do this properly
link node['ow_python']['app_root'] + "/current/reopenwatch/reopenwatch/local_settings.py" do
  owner node['ow_python']['git_user']
  group node['ow_python']['service_user_group']
  to node['ow_python']['app_root'] + "/current/local_settings.py"
end

# Create and set permissions on upload directories
directory node['ow_python']['app_root'] + "/current/media/recordings" do
  owner node['ow_python']['git_user'] 
  group node['ow_python']['service_user_group']
  mode "770"
  action :create
end

directory node['ow_python']['app_root'] + "/current/media/uploads" do
  owner node['ow_python']['git_user'] 
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


## Check permissions
bash "check_permissions" do
  user node['ow_python']['git_user']
  cwd node['ow_python']['app_root'] + '/current/reopenwatch'
  code <<-EOH
  /var/www/ReopenWatch/shared/env/bin/python manage.py check_permissions
  EOH
end

# Upstart service config file
template "/etc/init/" + node['ow_python']['service_name'] + ".conf" do
    source "upstart.conf.erb"
    owner node['ow_python']['service_user'] 
    group node['ow_python']['service_user_gid'] 
    variables({
    :service_user => node['ow_python']['service_user'],
    :virtualenv_path => node['ow_python']['app_root'] + '/shared/env',
    :app_root => node['ow_python']['app_root'] + '/current',
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
  action :start
end
