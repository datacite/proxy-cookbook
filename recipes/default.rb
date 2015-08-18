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
servers = {
  'search' => ENV['SEARCH']
}
servers.each do |name, ip|
  template "#{node['nginx']['dir']}/sites-enabled/#{name}.conf" do
    source "server.conf.erb"
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      server: name,
      default_server: name == 'search',
      ip: ip
    )
    notifies :reload, 'service[nginx]'
  end
end

service 'nginx' do
  supports :status => true, :restart => true, :reload => true
  action   :nothing
end
