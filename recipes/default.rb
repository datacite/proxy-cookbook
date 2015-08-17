include_recipe 'apt'

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

# set up reverse proxy for each application server
# first application server is default server
node['nginx']['applications'].each_with_index do |application, index|
  template "#{node['nginx']['dir']}/sites-enabled/#{application}.conf" do
    source "app.conf.erb"
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      application: application,
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
