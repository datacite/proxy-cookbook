include_recipe "apt"
include_recipe "openresty"

execute "apt-get update" do
  action :run
end

# # add repo for librato-collectd
apt_repository "librato-collectd" do
  uri          "https://packagecloud.io/librato/librato-collectd/ubuntu/"
  distribution node['lsb']['codename']
  components   ["main"]
  key          "https://packagecloud.io/gpg.key"
  action       :add
  notifies     :run, "execute[apt-get update]"
end

# install required libraries
node['ruby']['packages'].each do |pkg|
  package pkg do
    action :install
  end
end

# install collectd
%w{ collectd }.each do |pkg|
  package pkg do
    options "-y --force-yes"
    action :install
  end
end

if ENV['RSYSLOG_HOST']
  node.override['openresty']['rsyslog_server']  = "#{ENV['RSYSLOG_HOST']}:#{ENV['RSYSLOG_PORT']}"
end

# nginx configuration
template 'nginx.conf' do
  path   "#{node['openresty']['dir']}/nginx.conf"
  source 'nginx.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  cookbook 'proxy'
  variables(
    rsyslog_server: node['openresty']['rsyslog_server']
  )
  notifies :reload, 'service[nginx]'
end

# librato collectd configuration
directory '/opt/collectd/etc/collectd.conf.d' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

template 'librato.conf' do
  path   "/opt/collectd/etc/collectd.conf.d/librato.conf"
  source 'librato.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  cookbook 'proxy'
end

# configure proxy cache
template 'proxy_cache.conf' do
  path   "#{node['openresty']['dir']}/conf.d/proxy_cache.conf"
  source 'proxy_cache.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  cookbook 'proxy'
  notifies :reload, 'service[nginx]'
end

# delete default configuration
file "#{node['openresty']['dir']}/sites-enabled/default" do
  action :delete
  notifies :reload, 'service[nginx]'
end

# setup endpoint for health checks
template "#{node['openresty']['dir']}/sites-enabled/proxy.conf" do
  source "proxy.conf.erb"
  owner 'root'
  group 'root'
  mode '0644'
  cookbook 'proxy'
  variables(
    resolver: node['proxy']['resolver'],
    hostname: node['application'],
    domain: node['proxy']['ext_domain']
  )
  notifies :reload, 'service[nginx]'
end

# set up reverse proxy
if node['ruby']['rails_env'] == "development"
  dir = "sites-available"
else
  dir = "sites-enabled"
end

# write file for common cors settings
cookbook_file "#{node['openresty']['dir']}/cors"do
  source 'cors'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

# write file for common proxy settings
cookbook_file "#{node['openresty']['dir']}/proxy"do
  source 'proxy'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

# write file for test banner
cookbook_file "#{node['openresty']['dir']}/test-banner"do
  source 'test-banner'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

# load test banner for test subdomain
if node['proxy']['ext_domain'] == "test.datacite.org"
  test_string =  "include /etc/nginx/test-banner;"
else
  test_string = ""
end

template "#{node['openresty']['dir']}/#{dir}/#{node['proxy']['ext_domain']}.conf" do
  source "server.conf.erb"
  owner 'root'
  group 'root'
  mode '0644'
  cookbook 'proxy'
  variables(
    resolver: node['proxy']['resolver'],
    domain: node['proxy']['ext_domain'],
    regex_domain: node['proxy']['ext_domain'].gsub(/\./, "\."),
    int_domain: node['proxy']['int_domain'],
    test_string: test_string
  )
  notifies :reload, 'service[nginx]'
end

# allow more specific configurations for specific subdomains, e.g. enable http
# or use a specific port internally
node['proxy']['subdomains'].each do |subdomain|
  if subdomain['subdomain'] == "search"
    template "#{node['openresty']['dir']}/#{dir}/search.conf" do
      source "search.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        resolver: node['proxy']['resolver'],
        subdomain: subdomain['subdomain'],
        domain: node['proxy']['ext_domain'],
        backend: subdomain['backend'],
        search_backend: subdomain['search_backend'],
        test_string: test_string
      )
      notifies :reload, 'service[nginx]'
    end
  elsif subdomain['subdomain'] == "profiles"
    template "#{node['openresty']['dir']}/#{dir}/profiles.conf" do
      source "profiles.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        resolver: node['proxy']['resolver'],
        subdomain: subdomain['subdomain'],
        domain: node['proxy']['ext_domain'],
        backend: subdomain['backend'],
        test_string: test_string
      )
      notifies :reload, 'service[nginx]'
    end
  elsif ["api", "data", "oai"].include? subdomain['subdomain']
    template "#{node['openresty']['dir']}/#{dir}/#{subdomain['subdomain']}.conf" do
      source "frontend.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        resolver: node['proxy']['resolver'],
        subdomain: subdomain['subdomain'],
        domain: node['proxy']['ext_domain'],
        frontend: subdomain['backend'],
        backend: subdomain['search_backend'],
        test_string: test_string
      )
      notifies :reload, 'service[nginx]'
    end
  elsif subdomain['subdomain'] == "eventdata"
    template "#{node['openresty']['dir']}/#{dir}/#{subdomain['subdomain']}.conf" do
      source "eventdata.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        resolver: node['proxy']['resolver'],
        subdomain: subdomain['subdomain'],
        domain: node['proxy']['ext_domain'],
        frontend: subdomain['backend'],
        backend: subdomain['search_backend'],
        test_string: test_string
      )
      notifies :reload, 'service[nginx]'
    end
  elsif ["doi", "friedman"].include? subdomain['subdomain']
    template "#{node['openresty']['dir']}/#{dir}/#{subdomain['subdomain']}.conf" do
      source "ember.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        resolver: node['proxy']['resolver'],
        subdomain: subdomain['subdomain'],
        domain: node['proxy']['ext_domain'],
        frontend: subdomain['backend'],
        test_string: test_string
      )
      notifies :reload, 'service[nginx]'
    end
  elsif subdomain['subdomain'] == "test"
    template "#{node['openresty']['dir']}/#{dir}/test.conf" do
      source "test.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        resolver: node['proxy']['resolver'],
        subdomain: subdomain['subdomain'],
        domain: node['proxy']['ext_domain'],
        backend: subdomain['backend']
      )
      notifies :reload, 'service[nginx]'
    end
  elsif subdomain['subdomain'] == "handle" && node['proxy']['ext_domain'] == "datacite.org"
    template "#{node['openresty']['dir']}/#{dir}/handle.conf" do
      source "handle.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        resolver: node['proxy']['resolver'],
        subdomain: subdomain['subdomain'],
        domain: node['proxy']['ext_domain'],
        backend: subdomain['backend']
      )
      notifies :reload, 'service[nginx]'
    end
  elsif subdomain['subdomain'] == "www"
    template "#{node['openresty']['dir']}/#{dir}/www.conf" do
      source "www.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        resolver: node['proxy']['resolver'],
        subdomain: subdomain['subdomain'],
        domain: node['proxy']['ext_domain'],
        backend: subdomain['backend'],
        test_string: test_string
      )
      notifies :reload, 'service[nginx]'
    end
  elsif ["pidapalooza"].include? subdomain['subdomain']
    template "#{node['openresty']['dir']}/#{dir}/#{subdomain['subdomain']}.conf" do
      source "#{subdomain['subdomain']}.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        resolver: node['proxy']['resolver'],
        domain: "#{subdomain['subdomain']}.org",
        backend: subdomain['backend'],
        test_string: test_string
      )
      notifies :reload, 'service[nginx]'
    end
  elsif subdomain['subdomain'].match('citation')
    template "#{node['openresty']['dir']}/#{dir}/citation.conf" do
      source "citation.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        resolver: node['proxy']['resolver'],
        backend: subdomain['backend'],
        test_string: test_string
      )
      notifies :reload, 'service[nginx]'
    end
  elsif subdomain['allow_http']
    template "#{node['openresty']['dir']}/#{dir}/#{subdomain['subdomain']}.conf" do
      source "server_http.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        resolver: node['proxy']['resolver'],
        subdomain: subdomain['subdomain'],
        domain: node['proxy']['ext_domain'],
        backend: subdomain['backend'],
        test_string: test_string
      )
      notifies :reload, 'service[nginx]'
    end
  else
    template "#{node['openresty']['dir']}/#{dir}/#{subdomain['subdomain']}.conf" do
      source "server_https.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        resolver: node['proxy']['resolver'],
        subdomain: subdomain['subdomain'],
        domain: node['proxy']['ext_domain'],
        backend: subdomain['backend'],
        test_string: test_string
      )
      notifies :reload, 'service[nginx]'
    end
  end
end

# create required files and folders, and deploy application
capistrano node["application"] do
  user            ENV['DEPLOY_USER']
  group           ENV['DEPLOY_GROUP']
  rails_env       ENV['RAILS_ENV']
  action          [:consul_install, :rsyslog_config, :restart]
end

service 'nginx' do
  supports :status => true, :restart => true, :reload => true
  action   :nothing
end
