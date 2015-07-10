default['spacewalk']['version'] = '2.3'
default['spacewalk']['release'] = '2'
default['spacewalk']['rhel']['base_url'] = "http://yum.spacewalkproject.org/#{node['spacewalk']['version']}-client/RHEL"
default['spacewalk']['enable_osad'] = false
default['spacewalk']['reg']['key'] = 'my-reg-key'
default['spacewalk']['reg']['server'] = 'http://spacewalk.example.com'
default['spacewalk']['apt']['key'] = 'example.gpg.pub'

default['spacewalk']['apt']['repository'] = 'ppa:aaronr/spacewalk'
