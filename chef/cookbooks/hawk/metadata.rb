name "hawk"
maintainer "Thomas Boerger"
maintainer_email "tboerger@suse.de"
license "Apache 2.0"
description "Installs/Configures hawk"
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version "0.0.1"
depends "ruby"
depends "foreman"
recipe "hawk", "Installs/Configures hawk"

supports "suse", ">= 11.3"
