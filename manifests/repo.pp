define reprepro::repo (
  String $architectures,
  String $codename,
  Array $components,
  String $description,
  String $dist,
  String $key_id,
  String $label,
  String $origin,
  String $public_key,
  Boolean $manage_web_server = lookup('reprepro::manage_web_server'),
  String $main_folder        = lookup('reprepro::main-folder'),
  String $www_group          = lookup('reprepro::www_group'),
  String $www_user           = lookup('reprepro::www_user'),
) {
  if $manage_web_server == true {
    file { "/etc/apache2/conf.d/${title}":
      ensure  => directory,
      content => template('reprepro/apache_repo.erb'),
      group   => $www_group,
      owner   => $www_user,
    }
  }
  $folders = [
    "${main_folder}/${title}",
    "${main_folder}/${title}/${dist}",
    "${main_folder}/${title}/${dist}/conf",
    "${main_folder}/${title}/${dist}/incoming",
  ]
  file { $folders:
    ensure  => directory,
    owner   => $www_user,
    group   => $www_group,
  }
  file { "${main_folder}/${title}/${dist}/conf/distributions":
    ensure  => present,
    content => template('reprepro/distributions.erb'),
    group   => $www_group,
    owner   => $www_user,
  }
  file { "${main_folder}/${title}/${dist}/pubkey.gpg":
    ensure  => present,
    content => $public_key,
    group   => $www_group,
    owner   => $www_user,
  }
  file { "${main_folder}/${title}/${dist}/sources.list":
    ensure  => present,
    content => template('reprepro/sources.list.erb'),
    group   => $www_group,
    owner   => $www_user,
  }
  cron { "sign incoming packages for ${title}":
    ensure  => present,
    command => "for file in ${main_folder}/${title}/${dist}/incoming; do reprepro includedeb -b ${main_folder}/${title}/${dist} ${codename} $file; done",
    user    => $www_user,
    minute  => '*/5',
  }
}