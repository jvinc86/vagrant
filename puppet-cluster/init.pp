class apache2 {
    exec { 'apt':                       
        command => '/usr/bin/apt update'    # Ejecutar comando 'apt update'
    }

    package { 'apache2':                    # Instalar paquete apache2
        ensure => installed,                # Asegura que este instalado
        require => Exec['apt'],             # Requiere 'exec apt' antes de instalar
    }

    service { 'apache2':                    # Configura servicio apache2
        ensure => running,                  # Asegurar que el servicio apache2 este corriendo
        enable  => true,                    # Habilita el servicio a nivel de OS
        require => Package['apache2'],      # Requiere 'package apache2' antes de proceder
    }

    file { '/var/www/html/info.html':           # Crea archivo info.html
        ensure => file,                         # Asegurar que el archivo info.php existe
        content => '<h1> MI SUPER APP!</h1>',   # Codigo html
        require => Package['apache2'],          # Requiere 'package apache2' antes de proceder
        owner => 'root',
        group => 'root',
        mode => '0644'
    }
}
