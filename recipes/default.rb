# load .env configuration file with ENV variables
dotenv node["application"] do
  dotenv          node['dotenv']
  action          :nothing
end.run_action(:load)

# install and configure dependencies
include_recipe "apt"

execute "apt-get update" do
  action :nothing
end

# install packages, including nginx
node['apt']['packages'].each do |pkg|
  package pkg do
    action :install
  end
end

# install nginx
package 'nginx-full' do
  options "-y --force-yes"
  action :install
end

# nginx configuration
template 'nginx.conf' do
  path   "#{node['nginx']['dir']}/nginx.conf"
  source 'nginx.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :reload, 'service[nginx]'
end

# delete default configuration file
file "#{node['nginx']['dir']}/sites-enabled/default" do
  action :delete
  notifies :reload, 'service[nginx]'
end

# enable CORS
directory "#{node['nginx']['dir']}/include.d" do
  owner 'root'
  group 'root'
  mode '0755'
end

template 'cors.conf' do
  path   "#{node['nginx']['dir']}/include.d/cors.conf"
  source 'cors.conf'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :reload, 'service[nginx]'
end

# configure logging
template 'logging.conf' do
  path   "#{node['nginx']['dir']}/conf.d/logging.conf"
  source 'logging.conf'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :reload, 'service[nginx]'
end

# set up reverse proxy for each server
# first server is default server
servers = ENV['SERVERS'].to_s.split(',')
servers.each_with_index do |server, index|
  template "#{node['nginx']['dir']}/sites-enabled/#{server}.conf" do
    source "server.conf.erb"
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      server: server,
      default_server: index == 0,
      subdomain: node['nginx']['subdomain']
    )
    notifies :reload, 'service[nginx]'
  end
end

service 'nginx' do
  supports :status => true, :restart => true, :reload => true
  action   :nothing
end
