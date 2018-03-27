#!/bin/sh
sed -i 's$#!/.*$#!/usr/bin/ruby.ruby2.5$' /vagrant/hawk/bin/rails
sed -i 's$#!/.*$#!/usr/bin/ruby.ruby2.5$' /vagrant/hawk/bin/rake
sed -i 's$#!/.*$#!/usr/bin/ruby.ruby2.5$' /vagrant/hawk/bin/bundle
