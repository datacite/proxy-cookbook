include_recipe 'openresty'

node['proxy']['certificates'].each do |name|
  remote_file "Copy #{name} certificate" do
    path "/etc/ssl/certs/#{name}.crt"
    source "file:///var/www/#{node['application']}/ssl/#{name}.crt"
    owner 'root'
    group 'root'
    mode '0644'
  end

  remote_file "Copy #{name} key" do
    path "/etc/ssl/private/#{name}.key"
    source "file:///var/www/#{node['application']}/ssl/#{name}.key"
    owner 'root'
    group 'root'
    mode '0644'
  end

  ssl_certificate name do
    common_name name
    source 'file'
    key_path "/etc/ssl/private/#{name}.key"
    cert_path "/etc/ssl/certs/#{name}.crt"
  end
end

openssl_dhparam '/etc/ssl/private/dhparam.pem' do
  key_length 2048
end

template 'ssl.conf' do
  path   "#{node['nginx']['dir']}/include.d/ssl.conf"
  source 'ssl.conf'
  owner  'root'
  group  'root'
  mode   '0644'
  cookbook 'proxy'
  notifies :reload, 'service[nginx]'
end

# setup endpoint for health checks
cert = ssl_certificate node['proxy']['ext_domain']

template "#{node['nginx']['dir']}/sites-enabled/proxy.conf" do
  source "proxy.conf.erb"
  owner 'root'
  group 'root'
  mode '0644'
  cookbook 'proxy'
  variables(
    hostname: "#{node['application']}",
    domain: "#{node['proxy']['ext_domain']}",
    ssl_key: cert.key_path,
    ssl_cert: cert.cert_path
  )
  notifies :reload, 'service[nginx]'
end

# set up reverse proxy for each server
node['proxy']['servers'].each do |server|
  hostname = server['hostname']
  domain = server['domain']
  count = server['count'] || 1

  cert = ssl_certificate domain

  template "#{node['nginx']['dir']}/sites-enabled/#{hostname}.conf" do
    source "server.conf.erb"
    owner 'root'
    group 'root'
    mode '0644'
    cookbook 'proxy'
    variables(
      hostname: hostname,
      domain: domain,
      count: count,
      ssl_key: cert.key_path,
      ssl_cert: cert.cert_path
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
