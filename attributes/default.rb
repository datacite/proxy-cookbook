default['openresty']['user'] = 'www-data'
default['openresty']['dir'] = '/etc/nginx'
default['openresty']['log_dir'] = '/var/log/nginx'
default['openresty']['cache_dir'] = '/var/cache/nginx'
default['openresty']['rsyslog_server'] = '127.0.0.1'
default['openresty']['status']['url'] = '/basic_status'

default['ruby']['deploy_user'] = "vagrant"
default['ruby']['deploy_group'] = "vagrant"
default['ruby']['rails_env'] = "development"
default['ruby']['enable_capistrano'] = false

default['ruby']['packages'] = %w{ curl git python-software-properties software-properties-common zlib1g-dev nfs-common }

default["application"] = "proxy"

default['proxy']['resolver'] = '10.0.0.2'
default['proxy']['ext_domain'] = 'datacite.local'
default['proxy']['int_domain'] = 'ec2.datacite.local'
default['proxy']['subdomains'] = []
