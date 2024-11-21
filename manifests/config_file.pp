# @summary Write a pgbackrest configuration file snippet
define pgbackrest::config_file(
  Hash[String,Hash] $config,
  String $filename   = "${pgbackrest::config::directory}/${name}.conf",
  Boolean $show_diff = true,
) {
  # TODO: mkdir_p on the dirname($filename)

  # Add each section block configs
  $config.each |String $section, Hash $settings| {
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
