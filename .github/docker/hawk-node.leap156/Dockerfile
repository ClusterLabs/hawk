FROM docker.io/opensuse/leap:15.6

# install deps (hawk2 will pull all the gems, but uglifier)
# libglue-devel is for stonith:external/ssh params hostlist
RUN zypper -n refresh \
 && zypper -n install --no-recommends \
      systemd systemd-sysvinit openssh-server libglue-devel \
      make gcc pam-devel hawk2 ruby2.5-rubygem-uglifier \
 && zypper -n clean -a

# allow root password login (specifically for the tests)
RUN sed -i \
      -e 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' \
      -e 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' \
      /etc/ssh/sshd_config

RUN ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa \
 && cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

# unlock root and set password to "linux"
RUN passwd -u root || true && echo -e "linux\nlinux" | passwd root

# start sshd under systemd (`crm cluster init` will start it later anyway)
RUN systemctl enable sshd

# no need for the hawk itself, it should be copied in the git workflow
RUN rm -rf /usr/share/hawk /etc/sysconfig/hawk

CMD ["/usr/lib/systemd/systemd", "--system"]
