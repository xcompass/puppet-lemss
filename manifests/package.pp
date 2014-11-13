# install lemss agent package
class lemss::package (
  $ensure = 'present',
) inherits ::lemss::params {
  case $::osfamily {
    'redhat': { }
    default: { fail('This module only supports RHEL/CentOS systems') }
  }

  include wget
  include java

  file {$lemss::tgt_dir:
    ensure => directory,
  } ->

  file { 'create temp directory':
    ensure => directory,
    path   => $lemss::tmp_dir,
  } ->

  # install agent
  wget::fetch { 'download agent':
    source      => "${lemss::src_dir}/${lemss::agent_file}-${lemss::version}.tar.bz2",
    destination => "${lemss::tmp_dir}/${lemss::agent_file}",
    verbose     => false,
    require     => Package['wget'],
  } ->

  exec {'untar agent':
    command => "tar -xjf ${lemss::tmp_dir}/${lemss::agent_file}",
    creates => "${lemss::tmp_dir}/install",
    cwd     => $lemss::tmp_dir,
    path    => '/usr/bin:/bin',
  } ->

  # update install script with modified one that enables OpenJDK
  file { "${lemss::tmp_dir}/install":
    ensure => present,
    source => 'puppet:///modules/lemss/install'
  } ->

  exec {'install agent':
    command => "${lemss::tmp_dir}/install ${lemss::install_args} -p ${lemss::server} -sno ${lemss::license} -g '${lemss::group}'",
    creates => "${lemss::tgt_dir}/patchservice",
    cwd     => $::lemss::params::tmp_dir,
    path    => '/sbin:/bin:/usr/sbin:/usr/bin',
    timeout => 1200,
    require => Package['java'],
  } ->

  # update the selinux type
  file { "${lemss::tgt_dir}/mcescan/bin/python":
    seltype => 'rpm_exec_t',
    notify  => Class['Lemss::Service'],
  }
}
