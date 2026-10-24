FROM docker.io/opensuse/leap:16.0

# install deps (hawk2 will pull all the gems, but uglifier)
# libglue-devel is for stonith:external/ssh params hostlist
RUN zypper -n refresh \
 && zypper -n install --no-recommends \
      systemd openssh-server \
      make gcc pam-devel hawk2 nodejs git policycoreutils \
 && zypper -n clean -a

# allow root password login (specifically for the tests)
RUN sed -i \
      -e 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' \
      -e 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' \
      /usr/etc/ssh/sshd_config

RUN ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa \
 && cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

# unlock root and set password to "linux"
RUN passwd -u root || true && echo -e "linux\nlinux" | passwd root

# start sshd under systemd (`crm cluster init` will start it later anyway)
RUN systemctl enable sshd

# backup the Gemfiles
RUN cp /usr/share/hawk/Gemfile* /

# we need a clean /usr/share/hawk, later we will 'make install' in here
RUN rm -rf /usr/share/hawk

# rm -rf /usr/share/hawk also removes some of the hawk-apiserver, so let's recover them
RUN zypper -n install --no-recommends -f hawk-apiserver

COPY *.patch /

# Make packaged gems available during compilation while retaining system gems.
ENV GEM_PATH=/usr/libexec/hawk/vendor

CMD ["/usr/lib/systemd/systemd", "--system"]
