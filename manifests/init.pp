# == Class: lemss
#
# this module manages lemss agent
#
# === Parameters
#
# === Variables
#
# === Examples
#
#  class { 'lemss':
#    server  =>'https://mylemss.server.com',
#    license =>'XXXXXXX-XXXXXXX',
#    group   =>'CTLT'
#  }
#
# === Authors
#
# Pan Luo <pan.luo@ubc.ca>
#
# === Copyright
#
# Copyright 2014 Pan Luo, unless otherwise noted.
#
class lemss (
  $server        = undef,
  $license       = undef,
  $group         = $::lemss::params::group,
  $src_dir       = $::lemss::params::src_dir,
  $tgt_dir       = $::lemss::params::tgt_dir,
  $version       = '7.0306',
  $install_args  = $::lemss::params::install_args,
  $service_name  = $::lemss::params::service_name,
) inherits ::lemss::params {
  validate_string($server)
  validate_string($license)

  include '::lemss::package'
  include '::lemss::service'

}
