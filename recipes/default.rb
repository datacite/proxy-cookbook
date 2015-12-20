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

  template "#{node['nginx']['dir']}/sites-enabled/#{hostname}.conf" do
    source "server.conf.erb"
    owner 'root'
    group 'root'
    mode '0644'
    cookbook 'proxy'
    variables(
      fqdn: name,
      hostname: hostname,
      domain: domain
    )
    notifies :reload, 'service[nginx]'
  end
end

# create required files and folders, and deploy application
capistrano node["application"] do
  user            ENV['DEPLOY_USER']
  group           ENV['DEPLOY_GROUP']
  rails_env       ENV['RAILS_ENV']
  action          [:config, :consul_install, :rsyslog_config, :restart]
end

service 'nginx' do
  supports :status => true, :restart => true, :reload => true
  action   :nothing
end
