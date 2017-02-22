class download_descriptor (
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

include download_descriptor
