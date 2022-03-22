# How to enable systemd in containers with Podman
# Source: https://blog.while-true-do.io/podman-systemd-in-containers/


# Use Fedora 33 as base image
FROM registry.fedoraproject.org/fedora:33

# Install systemd mariadb nginx php-fpm
RUN dnf install -y systemd mariadb-server nginx php-fpm && \
    dnf clean all

# Enable the services
RUN systemctl enable mariadb.service && \
    systemctl enable php-fpm.service && \
    systemctl enable nginx.service

EXPOSE 80

# Use systemd as command
CMD [ "/usr/sbin/init" ]