require 'serverspec'
require 'hiera'

set :backend, :exec

hiera_conf = File.expand_path(File.join(__FILE__, '../../../../conf/hiera.yaml'))
@hiera = Hiera.new(:config => hiera_conf)
