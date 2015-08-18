# enable local networking in development
default['apt']['packages'] = %w{ avahi-daemon libnss-mdns } if ENV['VAGRANT']

default['nginx']['user'] = 'www-data'
default['nginx']['dir'] = '/etc/nginx'
default['nginx']['log_dir'] = '/var/log/nginx'
default['nginx']['worker_processes'] = 4
default['nginx']['worker_connections'] = 768

default['nginx']['subdomain'] = 'ec2'
