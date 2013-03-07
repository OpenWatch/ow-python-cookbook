#
# Cookbook Name:: ow_python
# Attributes:: default
#
# Copyright 2013, OpenWatch FPC
#
# Licensed under the AGPLv3
#

# Chef repo
default['ow_python']['secret_databag_name'] 		= "secrets"
default['ow_python']['secret_item_name'] 		= "ow_python"

# SSL
default['ow_python']['ssl_databag_name'] 		= "ssl"
default['ow_python']['ssl_databag_item_name'] 	= "ssl"

# System
default['ow_python']['app_root']      		= "/var/www/ReopenWatch"
default['ow_python']['config_path']       	= "/reopenwatch/reopenwatch/local_settings.py"
default['ow_python']['git_user']      		= "git"
default['ow_python']['service_user']      	= "python"
default['ow_python']['service_user_gid']    = 500
default['ow_python']['service_name']      	= "ow_python"
default['ow_python']['git_url']      		= "git@github.com:OpenWatch/ReopenWatch.git"
default['ow_python']['git_rev']      		= "HEAD"
default['ow_python']['git_branch']      	= "v2" # Can't get this working yet
default['ow_python']['git_ssh_wrapper']   	= "/home/git/.ssh/wrappers/ow-github_deploy_wrapper.sh"
default['ow_python']['log_path']		    = "/var/log/ow_python.log"
default['ow_python']['run_script']	    	= "run.sh"

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


