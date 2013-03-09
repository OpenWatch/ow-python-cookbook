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
  # THIS SYMLINKS INTO THE APP ROOT. WHYYYYYYY!
  symlink_before_migrate ({"local_settings.py" => "reopenwatch/reopenwatch/local_settings.py"})
  migrate false
  # packages should be handled separately?
  # packages ["git", "git-core", "mercurial"]

  django do
    requirements "requirements.txt"
    settings_template node['ow_python']['local_settings_file']
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

# collectstatic + syncdb
# TODO: get django resource to do this
bash "collectstatic and syncdb" do
  user node['ow_python']['git_user']
  cwd node['ow_python']['app_root'] + '/current/reopenwatch'
  code <<-EOH
  /var/www/ReopenWatch/shared/env/bin/python manage.py collectstatic --noinput
  /var/www/ReopenWatch/shared/env/bin/python manage.py syncdb --noinput
  EOH
end

## TODO: Put in separate ow_server cookbook
# Make directory for ssl credentials
directory node['ow_python']['ssl_dir'] do
  owner node['nginx']['user']
  group node['nginx']['group']
  recursive true
  action :create
end

# SSL certificate and key
cookbook_file node['ow_python']['ssl_dir'] + node['ow_python']['ssl_cert']  do
  source "star_openwatch_net.crt"
  owner node['nginx']['user']
  group node['nginx']['group']
  mode 0600
  action :create
end

ssl_key = Chef::EncryptedDataBagItem.load(node['ow_python']['ssl_databag_name'] , node['ow_python']['ssl_databag_item_name'] )

file node['ow_python']['ssl_dir'] + node['ow_python']['ssl_key'] do
  owner node['nginx']['user']
  group node['nginx']['group']
  content ssl_key['*.openwatch.net']
  mode 0600
  action :create
end

# Make Nginx log dirs
directory node['ow_python']['log_dir'] do
  owner node['nginx']['user']
  group node['nginx']['group']
  recursive true
  action :create
end

## END TODO: separate cookbook

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


## XXX: Temp server run
bash "collectstatic and syncdb" do
  user node['ow_python']['git_user']
  cwd node['ow_python']['app_root'] + '/current/reopenwatch'
  code <<-EOH
  /var/www/ReopenWatch/shared/env/bin/python manage.py runserver 0.0.0.0:8000
  EOH
end
