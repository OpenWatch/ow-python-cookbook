#
# Cookbook Name:: ow_python
# Attributes:: default
#
# Copyright 2013, OpenWatch FPC
#
# Licensed under the AGPLv3
#

# Chef repo
default['ow_python']['secret_databag_name'] 			= "secrets"
default['ow_python']['secret_databag_item_name'] 		= "ow_python"

# SSL
default['ow_python']['ssl_databag_name'] 		= "ssl"
default['ow_python']['ssl_databag_item_name'] 	= "ssl"

# System
default['ow_python']['app_root']      		= "/var/www/ReopenWatch"
default['ow_python']['git_user']      		= "git"
default['ow_python']['service_user']      	= "python"
default['ow_python']['service_user_gid']    = 500
default['ow_python']['service_user_group']  = "service_users"
default['ow_python']['service_name']      	= "ow_python"
default['ow_python']['git_url']      		= "git@github.com:OpenWatch/ReopenWatch.git"
default['ow_python']['git_rev']      		= "HEAD"
default['ow_python']['git_branch']      	= "v2" # Can't get this working yet
default['ow_python']['git_ssh_wrapper']   	= "/home/git/.ssh/wrappers/ow-github_deploy_wrapper.sh"
default['ow_python']['log_path']		    = "/var/log/ow_python.log"

#Django
default['ow_python']['local_settings_file'] = "local_settings.py.erb"
default['ow_python']['run_script']	    	= "run.sh"
default['ow_python']['node_api_user']	    = "test"
default['ow_python']['etherpad_url']		= "http://pad.openwatch.net:9001/api"
default['ow_python']['stripe_publishable']	= "pk_test_R5RY0ez5odUzDnzjCbno32jf"
default['ow_python']['aws_bucket_name']		= "openwatch-static"

#Postgres
default['ow_python']['db_host']	    		= "localhost"
default['ow_python']['db_port']	    		= 5432
default['ow_python']['db_name']	    		= "openwatch"
default['ow_python']['db_user']	    		= "postgres"
# Hardcoded in postgresql as 'postgres'

# Nginx
default['ow_python']['http_listen_port']    = 80
default['ow_python']['https_listen_port']   = 443
default['ow_python']['ssl_dir']				= "/srv/ssl/"
default['ow_python']['ssl_cert']     		= "star_openwatch_net.crt"
default['ow_python']['ssl_key']     		= "star_openwatch_net.key"
default['ow_python']['log_dir']     		= "/var/log/ow/"
default['ow_python']['access_log']     		= "nginx_access_python.log"
default['ow_python']['error_log']     		= "nginx_error_python.log"
default['ow_python']['proxy_pass']     		= "http://localhost:8000"


