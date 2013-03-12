#
# Cookbook Name:: ow_python
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

secrets = Chef::EncryptedDataBagItem.load(node['ow_python']['secret_databag_name'] , node['ow_python']['secret_databag_item_name'] )
ssh_key = Chef::EncryptedDataBagItem.load("ssh", "git")

# Setup postgresql database
postgresql_database node['ow_python']['db_name'] do
  connection ({
  		:host => "127.0.0.1", 
  		:port => node['ow_python']['db_port'], 
  		:username => node['ow_python']['db_user'], 
  		:password => secrets['db_user_password']})
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
  #symlinks ( 'local_settings.py' => 'reopenwatch/reopenwatch/local_settings.py')
  migrate false
  # packages should be handled separately?
  # packages ["git", "git-core", "mercurial"]

  django do
    requirements "requirements.txt"
    settings_template node['ow_python']['local_settings_file']
    local_settings_file 'local_settings.py'
    project_name 'reopenwatch'
    settings({
    	:db_name => node['ow_python']['db_name'],
    	:db_user => node['ow_python']['db_user'],
    	:db_password => secrets['db_user_password'],
    	:db_host => node['ow_python']['db_host'],
    	:db_port => node['ow_python']['db_port'],
    	:node_api_user => node['ow_python']['node_api_user'],
    	:node_api_secret => secrets['node_api_secret'],
    	:etherpad_url => node['ow_python']['etherpad_url'],
    	:etherpad_api_key => secrets['etherpad_api_key'],
    	:mailgun_api_key => secrets['mailgun_api_key'],
    	:stripe_secret => secrets['stripe_secret'],
    	:stripe_publishable => node['ow_python']['stripe_publishable'],
    	:aws_access_key_id => secrets['aws_access_key_id'],
    	:aws_secret_access_key => secrets['aws_secret_access_key'],
    	:aws_bucket_name => node['ow_python']['aws_bucket_name'],
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
    :app_domain => node[:fqdn],
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


## Syncdb
bash "syncdb" do
  user node['ow_python']['git_user']
  cwd node['ow_python']['app_root'] + '/current/reopenwatch'
  code <<-EOH
  /var/www/ReopenWatch/shared/env/bin/python manage.py syncdb --noinput
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
