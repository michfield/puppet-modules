class curl::posix {
  require build_essential

  $autotools_environment = $curl::autotools_environment
  $file_cache_dir        = $curl::file_cache_dir
  $install_dir           = $curl::install_dir

  $source_filename  = "curl-7.29.0.tar.gz"
  $source_url = "http://curl.haxx.se/download/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  # Determine if we have an extra environmental variables we need to set
  # based on the operating system.
  if $operatingsystem == 'Darwin' {
    $extra_autotools_environment = {
      "CFLAGS"  => "-arch i386 -arch x86_64",
      "LDFLAGS" => "-arch i386 -arch x86_64",
    }
  } else {
    $extra_autotools_environment = {}
  }

  # Merge our environments.
  $real_autotools_environment = autotools_merge_environments(
    $autotools_environment, $extra_autotools_environment)

  #------------------------------------------------------------------
  # Compile
  #------------------------------------------------------------------
  wget::fetch { "curl":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-curl":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["curl"],
  }

  autotools { "curl":
    configure_flags    => "--prefix=${install_dir} --disable-dependency-tracking",
    configure_sentinel => "${source_dir_path}/src/Makefile",
    cwd                => $source_dir_path,
    environment        => $real_autotools_environment,
    install_sentinel   => "${install_dir}/bin/curl",
    make_sentinel      => "${source_dir_path}/src/.libs/curl",
    require            => Exec["untar-curl"],
  }
}