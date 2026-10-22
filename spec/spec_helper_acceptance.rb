# frozen_string_literal: true

require 'json'
require 'openssl'
require 'voxpupuli/acceptance/spec_helper_acceptance'

# The acceptance tests provision a stand-in for an AEM instance as aem-aws-stack-builder's stack-init.sh does,
# without AWS and AEM: the nodeset is the AMI (see its comments), the package from `make package` is unpacked into
# PROVISIONER_DIR with the stack's hiera data (spec/fixtures/local.yaml), and the facts that stack-init.sh gets
# from the stack and EC2 are external facts.

# The nodeset bakes OpenVox 9 in, as the AMIs do, so configure_beaker doesn't install an agent
ENV['BEAKER_PUPPET_COLLECTION'] ||= 'preinstalled'

PROVISIONER_DIR = '/opt/shinesolutions/aem-aws-stack-provisioner'
# common::tmp_dir, where pre-common.pp downloads the system users' credentials
TMP_DIR = '/tmp/shinesolutions/aem-aws-stack-provisioner'
# packer-aem's tmp_dir, where it bakes the dispatcher from
PACKER_TMP_DIR = '/tmp/shinesolutions/packer-aem'

# The facts set-facts.sh (EC2 tags, stack-facts.txt) and stack-init.sh (FACTER_*) set, and EC2's ec2_metadata.
# component is passed to each puppet apply instead, as the instances only have their own.
# The hosts of the other components (load balancers on a stack) are localhost: AEM Dispatcher doesn't start
# when a backend host doesn't resolve, and nothing has to listen there
STACK_FACTS = {
  'stack_prefix' => 'acceptance',
  'data_bucket_name' => 'acceptance-bucket',
  'aws_region' => 'ap-southeast-2',
  'aws:cloudformation:stack-name' => 'acceptance-stack',
  'aws:autoscaling:groupname' => 'acceptance-chaos-monkey',
  'authorhost' => 'localhost',
  'authorprimaryhost' => 'localhost',
  'publishhost' => 'localhost',
  'publishdispatcherhost' => 'localhost',
  'previewpublishhost' => 'localhost',
  'previewpublishdispatcherhost' => 'localhost',
  'pairinstanceid' => 'i-0123456789abcdef0',
  'snapshotid' => '',
  'cron_env_path' => '/usr/local/bin:/usr/bin:/bin',
  'cron_http_proxy' => '',
  'cron_https_proxy' => '',
  'cron_no_proxy' => '',
  'publish_dispatcher_allowed_client' => '*',
  'preview_publish_dispatcher_allowed_client' => '*',
  'orchestratorasg' => 'acceptance-orchestrator',
  'publisherasg' => 'acceptance-publish',
  'previewpublisherasg' => 'acceptance-preview-publish',
  'publisherdispatcherasg' => 'acceptance-publish-dispatcher',
  'previewpublisherdispatcherasg' => 'acceptance-preview-publish-dispatcher',
  'authordispatcherasg' => 'acceptance-author-dispatcher',
  'asg_probability' => '1.0',
  'asg_max_terminations_per_day' => '1.0',
  'ec2_metadata' => { 'instance-id' => 'i-0123456789abcdef0' }
}.freeze

# The system users the manifests read from the credentials file (pre-common.pp downloads it from the data bucket)
SYSTEM_USERS = %w[admin deployer exporter importer orchestrator replicator].freeze

# The latest AEM Dispatcher built for OpenSSL 3 (Amazon Linux 2023), a public download
DISPATCHER_VERSION = '4.3.8'
# Adobe builds AEM Dispatcher for x86_64 (the AMIs) and aarch64, which Facter's os.architecture reports
# as x86_64/aarch64 on Amazon Linux and amd64/arm64 on Debian based OSes
DISPATCHER_ARCHITECTURES = { 'x86_64' => 'x86_64', 'amd64' => 'x86_64', 'aarch64' => 'aarch64', 'arm64' => 'aarch64' }.freeze
# The adobeinc/dispatcher version aem_curator is tested with (its .fixtures.yml)
DISPATCHER_MODULE_VERSION = '1.0.0'

# The package `make package` built, as stack-init.sh downloads it from the data bucket
def provisioner_package
  Dir.glob('stage/aem-aws-stack-provisioner-*.tar.gz').max_by { |path| File.mtime(path) } ||
    raise('No package in stage/, run make package first')
end

# The aem_resources providers load ruby_aem, whose HTTP client (ethon) loads libcurl through FFI.
# OpenVox 9's bundled Ruby has its own OpenSSL in /opt/puppetlabs/puppet/lib and no libcurl, and the
# system libcurl then binds to that OpenSSL and fails ("undefined symbol: EVP_camellia_256_cbc"), so
# build curl against OpenVox's OpenSSL into /opt/puppetlabs/puppet once per host, as
# the-works-buildenv's provisioners/shell/init.sh does ("Fix missing libcurl for OpenVox Puppet 9
# bundled Ruby"), and install ruby_aem into the agent's Ruby (the AEM AMIs provide both). ruby_aem is
# the version in Gemfile.lock, as in puppet-aem-curator's acceptance tests.
def install_aem_resources_dependencies(host, curl_version: '8.12.1')
  unless host.file_exist?('/opt/puppetlabs/puppet/lib/libcurl.so')
    on(host, 'dnf -y install gcc make perl tar gzip')
    on(host, <<~SHELL)
      set -e
      cd /tmp
      curl -fsSLO https://curl.se/download/curl-#{curl_version}.tar.gz
      tar xzf curl-#{curl_version}.tar.gz
      cd curl-#{curl_version}
      ./configure --prefix=/opt/puppetlabs/puppet --with-openssl=/opt/puppetlabs/puppet \
        --without-gssapi --without-libpsl --disable-ldap --disable-ntlm \
        LDFLAGS="-Wl,-rpath,/opt/puppetlabs/puppet/lib"
      make && make install
      cd /tmp && rm -rf curl-#{curl_version} curl-#{curl_version}.tar.gz
    SHELL
  end
  ruby_aem_version = Gem.loaded_specs.fetch('ruby_aem').version
  on(host, "/opt/puppetlabs/puppet/bin/gem list -i ruby_aem -v #{ruby_aem_version} || " \
           "/opt/puppetlabs/puppet/bin/gem install ruby_aem -v #{ruby_aem_version} --no-document")
end

# EC2 instances have IPv6 on the loopback interface, while Docker disables IPv6 in the container but still maps
# localhost to ::1 in /etc/hosts. httpd then only listens on IPv4, and the tcp_conn_validator checks of
# aem_curator's dispatcher classes, which connect to localhost, fail. Beaker's containers are privileged, so it
# can be enabled
def enable_ipv6_loopback(host)
  on(host, 'echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6 && echo 0 > /proc/sys/net/ipv6/conf/lo/disable_ipv6')
end

# What stack-init.sh does before applying the manifests: unpack the package, add the stack's hiera data
# (data/local.yaml) and facts. The credentials file is created in place of pre-common.pp's download from
# the data bucket, which puppet-archive then skips as the file exists
def install_provisioner(host)
  scp_to(host, provisioner_package, '/tmp/aem-aws-stack-provisioner.tar.gz')
  on(host, "mkdir -p #{PROVISIONER_DIR} && tar -xzf /tmp/aem-aws-stack-provisioner.tar.gz -C #{PROVISIONER_DIR} " \
           "&& chown -R root:root #{PROVISIONER_DIR} && rm /tmp/aem-aws-stack-provisioner.tar.gz")
  scp_to(host, 'spec/fixtures/local.yaml', "#{PROVISIONER_DIR}/data/local.yaml")
  on(host, 'mkdir -p /opt/puppetlabs/facter/facts.d')
  create_remote_file(host, '/opt/puppetlabs/facter/facts.d/acceptance.json', JSON.pretty_generate(STACK_FACTS))
  on(host, "mkdir -p #{TMP_DIR}")
  credentials = SYSTEM_USERS.to_h { |user| [user, "#{user}-password"] }
  create_remote_file(host, "#{TMP_DIR}/system-users-credentials.json", JSON.generate(credentials))
end

# A key and self-signed certificate for the dispatcher, in place of the ones packer-aem's config::certs fetches
# from ACM into <tmp_dir>/certs
def create_dispatcher_certificate(host)
  key = OpenSSL::PKey::RSA.new(2048)
  cert = OpenSSL::X509::Certificate.new
  cert.version = 2
  cert.serial = 1
  cert.subject = cert.issuer = OpenSSL::X509::Name.parse('/CN=localhost')
  cert.public_key = key.public_key
  cert.not_before = Time.now
  cert.not_after = Time.now + (24 * 60 * 60)
  cert.sign(key, OpenSSL::Digest.new('SHA256'))
  on(host, "mkdir -p #{PACKER_TMP_DIR}/certs")
  create_remote_file(host, "#{PACKER_TMP_DIR}/certs/aem.cert", cert.to_pem)
  create_remote_file(host, "#{PACKER_TMP_DIR}/certs/aem.key", key.to_pem)
end

# What packer-aem bakes into the dispatcher AMIs: httpd with the AEM Dispatcher module and the dispatcher's
# certificate (aem_curator::install_dispatcher with packer-aem's hiera data, except the data volume).
# adobeinc/dispatcher reads legacy facts, so it runs with include_legacy_facts as packer-aem has to
def bake_dispatcher(host)
  create_dispatcher_certificate(host)
  # The aarch64 build lets the tests run natively on arm64 machines, where httpd can't run emulated as x86_64
  # (QEMU doesn't support its accept mutex)
  architecture = DISPATCHER_ARCHITECTURES.fetch(fact_on(host, 'os.architecture')) do |unsupported|
    raise "AEM Dispatcher isn't built for #{unsupported}"
  end
  on(host, "puppet module install adobeinc-dispatcher --version #{DISPATCHER_MODULE_VERSION} " \
           "--ignore-dependencies --target-dir #{PACKER_TMP_DIR}/modules")
  create_remote_file(host, "#{PACKER_TMP_DIR}/dispatcher.pp", <<~PUPPET)
    class { 'aem_curator::install_dispatcher':
      apache_module_base_url => 'https://download.macromedia.com/dispatcher/download',
      apache_module_tarball  => 'dispatcher-apache2.4-linux-#{architecture}-ssl3.0-#{DISPATCHER_VERSION}.tar.gz',
      apache_module_filename => 'dispatcher-apache2.4-#{DISPATCHER_VERSION}.so',
      apache_module_temp_dir => '#{PACKER_TMP_DIR}',
      cert_base_url          => 'file://#{PACKER_TMP_DIR}/certs',
      cert_filename          => '/etc/ssl/aem.unified-dispatcher.cert',
      tmp_dir                => '#{PACKER_TMP_DIR}',
      docroot_dir            => '/var/www/html',
      post_stop_sleep_secs   => 300,
    }
  PUPPET
  on(host, "puppet apply --detailed-exitcodes --include_legacy_facts --modulepath #{PACKER_TMP_DIR}/modules:#{PROVISIONER_DIR}/modules " \
           "#{PACKER_TMP_DIR}/dispatcher.pp", acceptable_exit_codes: [0, 2])
end

# Applies a provisioner manifest as stack-init.sh does, for the given component (on the instances the component
# fact comes from the Component tag, set by set-facts.sh). With tags, only the resources of those classes are applied
def apply_provisioner_manifest(manifest, component: nil, tags: nil)
  environment = component ? "FACTER_component=#{component} " : ''
  options = tags ? " --tags #{tags.join(',')}" : ''
  on(default, "cd #{PROVISIONER_DIR} && #{environment}puppet apply --detailed-exitcodes " \
              "--modulepath modules --hiera_config conf/hiera.yaml#{options} manifests/#{manifest}.pp",
     acceptable_exit_codes: [0, 2])
end

# Runs a component's InSpec test as stack-init.sh does, limited to the given controls
def run_component_inspec_test(component, controls:)
  on(default, "cd #{PROVISIONER_DIR}/test/inspec && HOME=/root inspec exec #{component}_spec.rb --no-color " \
              "--controls #{controls.join(' ')}")
end

configure_beaker(modules: nil) do |host|
  enable_ipv6_loopback(host)
  install_aem_resources_dependencies(host)
  install_provisioner(host)
  bake_dispatcher(host)
end
