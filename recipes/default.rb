include_recipe "apt"

execute "apt-get update" do
  action :nothing
end

# install required libraries
node['ruby']['packages'].each do |pkg|
  package pkg do
    action :install
  end
end

# add PPA for Nginx mainline
apt_repository "nginx" do
  uri          "ppa:nginx/development"
  distribution node['lsb']['codename']
  components   ["main"]
  action       :add
  notifies     :run, "execute[apt-get update]", :immediately
end

# install nginx
%w{ nginx-full }.each do |pkg|
  package pkg do
    options "-y --force-yes"
    action :install
  end
end

if ENV['RSYSLOG_HOST']
  node.override['nginx']['rsyslog_server']  = "#{ENV['RSYSLOG_HOST']}:#{ENV['RSYSLOG_PORT']}"
end

# nginx configuration
template 'nginx.conf' do
  path   "#{node['nginx']['dir']}/nginx.conf"
  source 'nginx.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  cookbook 'proxy'
  variables(
    :rsyslog_server => node['nginx']['rsyslog_server']
  )
  notifies :reload, 'service[nginx]'
end

remote_file "Copy #{node['proxy']['ext_domain']} certificate" do
  path "/etc/ssl/certs/#{node['proxy']['ext_domain']}.crt"
  source "file:///var/www/#{node['application']}/ssl/#{node['proxy']['ext_domain']}.crt"
  owner 'root'
  group 'root'
  mode '0644'
end

remote_file "Copy #{node['proxy']['ext_domain']} key" do
  path "/etc/ssl/private/#{node['proxy']['ext_domain']}.key"
  source "file:///var/www/#{node['application']}/ssl/#{node['proxy']['ext_domain']}.key"
  owner 'root'
  group 'root'
  mode '0644'
end

ssl_certificate node['proxy']['ext_domain'] do
  common_name node['proxy']['ext_domain']
  source 'file'
  key_path "/etc/ssl/private/#{node['proxy']['ext_domain']}.key"
  cert_path "/etc/ssl/certs/#{node['proxy']['ext_domain']}.crt"
end

cert = ssl_certificate node['proxy']['ext_domain']

template 'ssl.conf' do
  path   "#{node['nginx']['dir']}/conf.d/ssl.conf"
  source 'ssl.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  cookbook 'proxy'
  variables(
    ssl_key: cert.key_path,
    ssl_cert: cert.cert_path,
    resolver: node['proxy']['resolver']
  )
  notifies :reload, 'service[nginx]'
end

# delete default configuration
file "#{node['nginx']['dir']}/sites-enabled/default" do
  action :delete
  notifies :reload, 'service[nginx]'
end

# setup endpoint for health checks
template "#{node['nginx']['dir']}/sites-enabled/proxy.conf" do
  source "proxy.conf.erb"
  owner 'root'
  group 'root'
  mode '0644'
  cookbook 'proxy'
  variables(
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

template "#{node['nginx']['dir']}/#{dir}/#{node['proxy']['ext_domain']}.conf" do
  source "server.conf.erb"
  owner 'root'
  group 'root'
  mode '0644'
  cookbook 'proxy'
  variables(
    domain: node['proxy']['ext_domain'],
    regex_domain: node['proxy']['ext_domain'].gsub(/\./, "\."),
    int_domain: node['proxy']['int_domain']
  )
  notifies :reload, 'service[nginx]'
end

# allow more specific configurations for specific subdomains, e.g. enable http
# or use a specific port internally
node['proxy']['subdomains'].each do |subdomain|
  if subdomain['allow_http']
    template "#{node['nginx']['dir']}/#{dir}/#{subdomain}_http.conf" do
      source "server_http.conf.erb"
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'proxy'
      variables(
        subdomain: subdomain['subdomain'],
        domain: node['proxy']['ext_domain'],
        int_domain: node['proxy']['int_domain']
        int_subdomain: subdomain['int_subdomain']
        int_port: subdomain['port'] || 80
      )
      notifies :reload, 'service[nginx]'
    end
  end

  template "#{node['nginx']['dir']}/#{dir}/#{subdomain}.conf" do
    source "server_https.conf.erb"
    owner 'root'
    group 'root'
    mode '0644'
    cookbook 'proxy'
    variables(
      subdomain: subdomain['subdomain'],
      domain: node['proxy']['ext_domain'],
      int_domain: node['proxy']['int_domain']
      int_subdomain: subdomain['int_subdomain']
      int_port: subdomain['port'] || 80
    )
    notifies :reload, 'service[nginx]'
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
