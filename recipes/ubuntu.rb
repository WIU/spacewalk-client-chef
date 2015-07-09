%w(apt-transport-spacewalk_1.0.6-4.1_all.deb
   python-ethtool_0.11-2_amd64.deb
   python-rhn_2.5.55-2_all.deb
   rhn-client-tools_1.8.26-4_amd64.deb
   rhnsd_5.0.4-3_amd64.deb).each do |pkg|
  dpkg_package pkg do
    source "#{node['spacewalk']['pkg_source_path']}/#{pkg}"
    ignore_failure true
  end
end

if node['spacewalk']['enable_osad']
  %w(rhncfg_5.10.14-1ubuntu1~precise2_all.deb
     pyjabber_0.5.0-1.4ubuntu3~precise1_all.deb
     osad_5.11.27-1ubuntu1~precise5_all.deb).each do |pkg|
    dpkg_package pkg do
      source "#{node['spacewalk']['pkg_source_path']}/#{pkg}"
      ignore_failure true
    end
  end
end

execute 'install-spacewalk-deps' do
  command 'apt-get -yf install'
  only_if { File.exists?("/opt/spacewalk/install_deps")
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
    apt-key add #{node['spacewalk']['pkg_source_path']}/#{node['spacewalk']['apt']['key']}
    EOH
    not_if 'apt-key list | grep -i spacewalk'
end

bash 'Use spacewalk for packages' do
    code <<-EOH
    sed -ie '1aModified for spacewalk by Chef' /etc/apt/sources.list
    sed -i 's/^/#/' /etc/apt/sources.list
    EOH
    not_if "grep 'Modified for spacewalk' /etc/apt/sources.list"
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



