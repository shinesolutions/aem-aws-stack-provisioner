class deploy_artifacts_prepare (
  $descriptor_file = $::descriptor_file,
  $path            = '/tmp/shinesolutions/aem-aws-stack-provisioner/',
) {

  file { "${path}/${descriptor_file}":
    ensure => absent,
  } ->
  archive { "${path}/${descriptor_file}":
    ensure => present,
    source => "s3://${::data_bucket}/${::stackprefix}/${descriptor_file}",
  }

}

include deploy_artifacts_prepare
