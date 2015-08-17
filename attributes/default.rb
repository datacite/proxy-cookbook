default['nginx']['user'] = 'www-data'
default['nginx']['dir'] = '/etc/nginx'
default['nginx']['log_dir'] = '/var/log/nginx'
default['nginx']['worker_processes'] = 4
default['nginx']['worker_connections'] = 768
default['nginx']['default_site_enabled'] = false
default['nginx']['internal_name'] = ['ec2']
default['nginx']['applications'] = ['search']

default['ruby']['deploy_user'] = "vagrant"
default['ruby']['deploy_group'] = "vagrant"
