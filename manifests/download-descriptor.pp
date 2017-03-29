class download_descriptor (
  $tmp_dir,
  $descriptor_file = $::descriptor_file
) {

  file { "${tmp_dir}/${descriptor_file}":
    ensure => absent,
  } -> archive { "${tmp_dir}/${descriptor_file}":
    ensure => present,
    source => "s3://${::data_bucket}/${::stackprefix}/${descriptor_file}",
  }

}

include download_descriptor
