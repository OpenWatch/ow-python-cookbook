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
default['ow_python']['python_databag_item_name'] 		= "ow_python"
default['ow_python']['postgres_databag_item_name'] 		= "postgres"

# SSL
default['ow_python']['ssl_databag_name'] 		= "ssl"
default['ow_python']['ssl_databag_item_name'] 	= "ssl"

# System
default['ow_python']['app_root']      		= "/var/www/ReopenWatch"
default['ow_python']['domain']      		= "chef.openwatch.net"
default['ow_python']['git_user']      		= "git"
default['ow_python']['service_user']      	= "django"
default['ow_python']['service_user_gid']    = 500
default['ow_python']['service_user_group']  = "service_users"
default['ow_python']['service_name']      	= "ow_python"
default['ow_python']['git_url']      		= "git@github.com:OpenWatch/ReopenWatch.git"
default['ow_python']['git_rev']      		= "HEAD"
default['ow_python']['git_branch']      	= "v2" # Can't get this working yet
default['ow_python']['git_ssh_wrapper']   	= "/home/git/.ssh/wrappers/ow-github_deploy_wrapper.sh"
default['ow_python']['log_dir']     		= "/var/log/ow/"
default['ow_python']['service_log']			= "ow_python.log"
default['ow_python']['service_error_log']	= "ow_python_error.log"

#Django
default['ow_python']['app_name']      		= "reopenwatch"
default['ow_python']['local_settings_file'] = "local_settings.py.erb"
default['ow_python']['run_script']	    	= "run.sh"
default['ow_python']['node_api_user']	    = "test"
default['ow_python']['etherpad_url']		= "http://pad.openwatch.net:9001/api"
default['ow_python']['etherpad_pad_url']	= "https://pad.openwatch.net/p/"
default['ow_python']['stripe_publishable']	= "pk_test_R5RY0ez5odUzDnzjCbno32jf"
default['ow_python']['aws_bucket_name']		= "openwatch-static"
default['ow_python']['internal_port']		= 8000

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
default['ow_python']['access_log']     		= "ow_python_nginx_access.log"
default['ow_python']['error_log']     		= "ow_python_nginx_error.log"
default['ow_python']['proxy_pass']     		= "http://localhost:8000"


