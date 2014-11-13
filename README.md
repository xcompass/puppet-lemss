LEMSS Patch Management Puppet Module
-----------------------------------

This module installs LEMSS.

Install
-------

    puppet module install compass-lemss

Usage
-----

    class { 'lemss':
      server  =>'https://mylemss.server.com',
      license =>'XXXXXXX-XXXXXXX',
      group   =>'CTLT'
    }


Tests
---------

Install the dependencies first:

    bundle install

Run the tests:

    bundle exec rake
