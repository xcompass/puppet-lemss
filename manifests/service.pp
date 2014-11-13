# manage lemss agent service
class lemss::service (
  $service_name   = $::lemss::params::service_name,
  $service_enable = true,
  $service_ensure = 'running',
) {
  # The base class must be included first because parameter defaults depend on it
  if ! defined(Class['lemss::params']) {
    fail('You must include the lemss::params class before using any resources')
  }

  validate_bool($service_enable)

  case $service_ensure {
    true, false, 'running', 'stopped': {
      $_service_ensure = $service_ensure
    }
    default: {
      $_service_ensure = undef
    }
  }

  service { 'patchagent':
    ensure => $_service_ensure,
    enable => $service_enable,
    name   => $service_name,
  }

}
