apt_repository "spacewalk_client" do
    uri node['spacewalk']['apt']['repository']
    distribution node['lsb']['codename']
end


%w{ apt-transport-spacewalk rhnsd}.each do |pkg|
    package pkg
end

apt_package 'python-libxml2'

directory '/var/lock/subsys' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end

cookbook_file '/etc/apt/apt.conf.d/40fix_spacewalk_pdiff' do
  source '40fix_spacewalk_pdiff'
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/usr/share/rhn/up2date_client/debUtils.py' do
    source 'debUtils.py'
    owner 'root'
    group 'root'
    mode '0644'
end

cookbook_file '/usr/lib/apt-spacewalk/pre_invoke.py' do
    source 'pre_invoke.py'
    owner 'root'
    group 'root'
    mode '0755'
end

cookbook_file '/usr/lib/apt/methods/spacewalk' do
    source 'spacewalk'
    owner 'root'
    group 'root'
    mode '0755'
end

bash 'add apt-key' do
    code <<-EOH
    apt-key add #{Chef::Config[:file_cache_path]}/#{node['spacewalk']['apt']['key']}
    EOH
    not_if 'apt-key list | grep -i spacewalk'
end

apt_preference 'spacewalk' do
    glob '*'
    pin 'origin spacewalk.wiu.edu'
    pin_priority '700'
end

if node['spacewalk']['enable_osad']
  directory '/usr/share/rhn' do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  remote_file '/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT' do
    owner 'root'
    group 'root'
    mode '0644'
    source "#{node['spacewalk']['reg']['server']}/pub/RHN-ORG-TRUSTED-SSL-CERT"
  end


  execute 'register-with-spacewalk-server' do
    command "rhnreg_ks --activationkey=#{node['spacewalk']['reg']['key']} --serverUrl=#{node['spacewalk']['reg']['server']}/XMLRPC"
    not_if { (File.exist?('/etc/sysconfig/rhn/systemid')) }
    notifies :restart, 'service[osad]'
  end

  service 'osad' do
    supports status: true, restart: true, reload: true, start: true, stop: true
    action [:start, :enable]
  end
else
  execute 'register-with-spacewalk-server' do
    command "rhnreg_ks --activationkey=#{node['spacewalk']['reg']['key']} --serverUrl=#{node['spacewalk']['reg']['server']}/XMLRPC"
    not_if { (File.exist?('/etc/sysconfig/rhn/systemid')) }
  end
end



