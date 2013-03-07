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
  connection ({:host => "127.0.0.1", :port => node['ow_python']['db_port'], :username => node['ow_python']['db_user'], :password => secrets['db_user_password']})
  action :create
end

#  Deploy Django app
application node['ow_python']['service_name'] do
  path node['ow_python']['app_root']
  owner node['ow_python']['git_user']
  group node['ow_python']['service_user_gid']
  repository node['ow_python']['git_url']
  revision node['ow_python']['git_rev']
  deploy_key ssh_key['id_rsa']
  migrate true
  # packages should be handled separately?
  # packages ["git", "git-core", "mercurial"]

  django do
    requirements "requirements.txt"
    settings_template node['ow_python']['local_settings_file']
    debug true
    collectstatic true
    database do
      database node['ow_python']['db_name']
      host node['ow_python']['db_host']
      engine "postgresql_psycopg2"
      username node['ow_python']['db_user']	
      password secrets['postgres_password']
    end
  end
end