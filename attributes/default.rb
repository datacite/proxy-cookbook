default['nginx']['user'] = 'www-data'
default['nginx']['dir'] = '/etc/nginx'
default['nginx']['log_dir'] = '/var/log/nginx'
default['nginx']['worker_processes'] = 1
default['nginx']['worker_connections'] = 1024
default['nginx']['rsyslog_server'] = '127.0.0.1'

default['ruby']['deploy_user'] = "vagrant"
default['ruby']['deploy_group'] = "vagrant"
default['ruby']['rails_env'] = "development"
default['ruby']['enable_capistrano'] = false

default['ruby']['packages'] = %w{ curl git mysql-client-5.6 python-software-properties software-properties-common zlib1g-dev }
default['ruby']['packages'] += %w{ avahi-daemon libnss-mdns } if node['ruby']['rails_env'] != "production"

default["application"] = "proxy"

default['proxy']['resolver'] = '10.0.0.2'
default['proxy']['ext_domain'] = 'datacite.local'
default['proxy']['int_domain'] = 'ec2.datacite.local'
default['proxy']['http_domains'] = []
