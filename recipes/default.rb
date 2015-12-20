# install nginx and create configuration file and application root
passenger_nginx node["application"] do
  user            ENV['DEPLOY_USER']
  group           ENV['DEPLOY_GROUP']
  action          :config
end

# setup endpoint for health checks
template "#{node['nginx']['dir']}/sites-enabled/proxy.conf" do
  source "proxy.conf.erb"
  owner 'root'
  group 'root'
  mode '0644'
  cookbook 'proxy'
  variables(
    fqdn: "#{node['application']}.#{node['proxy']['ext_domain']}",
    domain: node['proxy']['ext_domain'].split(".").slice(0..-2).join(".")
  )
  notifies :reload, 'service[nginx]'
end

# configure SSL
directory "#{node['nginx']['dir']}/ssl" do
  owner 'root'
  group 'root'
  mode '0755'
end

remote_file "Copy intermediate certificate" do
  path "/etc/ssl/certs/#{node['proxy']['intermediate_certificate']}"
  source "file:///var/www/#{node['application']}/ssl/#{node['proxy']['intermediate_certificate']}"
  owner 'root'
  group 'root'
  mode '0644'
end

node['proxy']['certificates'].each do |name|
  remote_file "Copy #{name} certificate" do
    path "#{node['nginx']['dir']}/ssl/#{name}.crt"
    source "file:///var/www/#{node['application']}/ssl/#{name}.crt"
    owner 'root'
    group 'root'
    mode '0644'
  end

  remote_file "Copy #{name} key" do
    path "#{node['nginx']['dir']}/ssl/#{name}.key"
    source "file:///var/www/#{node['application']}/ssl/#{name}.key"
    owner 'root'
    group 'root'
    mode '0644'
  end

  ssl_certificate name do
    common_name name
    source 'file'
    chain_source 'file'
    chain_name node['proxy']['intermediate_certificate']
    key_path "#{node['nginx']['dir']}/ssl/#{name}.key"
    cert_path "#{node['nginx']['dir']}/ssl/#{name}.crt"
  end
end

openssl_dhparam '/etc/nginx/ssl/dhparam.pem' do
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

# set up reverse proxy for each server
node['proxy']['servers'].each do |name|
  hostname = name.split(".").first
  domain = name.split(".").slice(1..-1).join(".")
  cert = ssl_certificate domain

  template "#{node['nginx']['dir']}/sites-enabled/#{hostname}.conf" do
    source "server.conf.erb"
    owner 'root'
    group 'root'
    mode '0644'
    cookbook 'proxy'
    variables(
      fqdn: name,
      hostname: hostname,
      ssl_key: cert.key_path,
      ssl_cert: cert.chain_combined_path
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
