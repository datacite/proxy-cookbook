default['nginx']['user'] = 'www-data'
default['nginx']['dir'] = '/etc/nginx'
default['nginx']['log_dir'] = '/var/log/nginx'
default['nginx']['worker_processes'] = 4
default['nginx']['worker_connections'] = 768

default['ext_domain'] = 'local'
default['int_domain'] = 'local'
default['servers'] = []
