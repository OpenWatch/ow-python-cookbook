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
  symlink_before_migrate ({"local_settings.py" => "reopenwatch/reopenwatch/local_settings.py"})
  symlinks ({"local_settings.py" => "reopenwatch/reopenwatch/local_settings.py"})
  migrate true
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
    collectstatic true
  end
end