default['ruby']['deploy_user'] = "vagrant"
default['ruby']['deploy_group'] = "vagrant"
default['ruby']['rails_env'] = "development"
default['ruby']['enable_capistrano'] = false

default['ruby']['packages'] = %w{ curl git libmysqlclient-dev python-software-properties software-properties-common zlib1g-dev }
default['ruby']['packages'] += %w{ avahi-daemon libnss-mdns } if node['ruby']['rails_env'] != "production"

default["application"] = "proxy"

default['nodejs']['repo'] = 'https://deb.nodesource.com/node_0.12'

default['proxy']['resolver'] = '10.0.0.2'
default['proxy']['ext_domain'] = 'datacite.local'
default['proxy']['int_domain'] = 'local'
default['proxy']['servers'] = []
