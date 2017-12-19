require 'facter'
require 'hiera'

def init_conf
  hiera_conf = File.expand_path(File.join(__FILE__, '../../../conf/hiera.yaml'))
  @hiera = Hiera.new(:config => hiera_conf)
end
