# default parameters
class lemss::params {
  $src_dir       = 'http://artifactory.ctlt.ubc.ca/artifactory/ctlt-release-local/lemss/'
  $tmp_dir       = '/tmp/patchagent'
  $tgt_dir       = '/usr/local/patchagent'
  $agent_file    = 'UnixPatchAgent'
  $version       = '7.0306'
  $group         = 'Default Group'
  $install_args  = '-silent -d /usr/local'
  $service_name  = 'patchagent'
}
