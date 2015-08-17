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

node['nginx']['applications'].each do |application|
  template "#{application}.conf" do
    source "app.conf.erb"
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      application: application,
    )
    notifies :reload, 'service[nginx]'
  end
end

service 'nginx' do
  supports :status => true, :restart => true, :reload => true
  action   :nothing
end
