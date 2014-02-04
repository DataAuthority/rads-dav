rads-dav
====

A WebDav extension to the [Rads Data Repository](https://github.com/DataAuthority/rads "Rads")



License
-------
This is a service to provide Data Provenance, and Collaborative Sharing of Research Data
Copyright (c) 2006-2013, Duke University
All rights reserved.  Mark R. DeLong, Darrin Mann, Darin London, David Daniel

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


Routes
------
Add the following to your config/routes.rb

  mount DAV4Rack::Handler.new( :root => Rails.root.to_s, :root_uri_path => '/webdav/mine',
                               :resource_class => Rads::DavRecordsController
                               ), :at => '/webdav/mine'

  mount DAV4Rack::Handler.new( :root => Rails.root.to_s, :root_uri_path => '/webdav/projects',
                               :resource_class => Rads::DavProjectsController
                               ), :at => '/webdav/projects'

  mount DAV4Rack::Handler.new( :root => Rails.root.to_s, :root_uri_path => '/webdav',
                               :resource_class => DavInterceptorController,
                               ), :at => '/webdav'



Directories Structure
---------------------

Currently, the system serves the following readonly file system, with basic authentication
used to find the Rads user to determine files that are available, and accessible by the user.

  my_files/
           "#{ fileA.id}/#{ fileA.name }"
           "#{ fileB.id }/#{ fileB.name }"
  projects/
          "#{ projectA.name }"/
                               "#{ fileA.id }_#{ fileA.name }"
                               "#{ fileB.id }_#{ fileB.name }"
         "#{ projectB.name }"/

TODO
----
- fix authentication