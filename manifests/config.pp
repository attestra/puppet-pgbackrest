# @summary Configures pgBackRest
#
# Configures pgBackRest
#
# @example
#   include pgbackrest::config
#
class pgbackrest::config(
  String $filename   = '/etc/pgbackrest.conf',
  Boolean $show_diff = true,
) {
  # Add each section block configs
  $pgbackrest::config.each |String $section, Hash $settings| {
    $settings.each |String $name, String $value| {
      # Remove values not defined or empty
      $is_present = $value ? {
        undef   => 'absent',
        ''      => 'absent',
        default => 'present',
      }

      # Write the configuration options to pgbackrest::config::filename
      ini_setting { "${section} ${name}":
        ensure    => $is_present,
        path      => $filename,
        section   => $section,
        setting   => $name,
        value     => $value,
        show_diff => $show_diff,
      }
    }
  }
}
