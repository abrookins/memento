WHAT IS THIS?

Memento is an attempt to create a simple, easy-to-use and fun to
develop web app to share location-based memories. In effect, I wanted
more features from Google's "My Places" app.

For now, the meat of the project is the front-end script:

  public/js/map.coffee

...which uses the Backbone and underscore libraries. On the server side,
the app uses node.js, Zappa (wrapping Express) and Mongo for
persistence.

Memento is not packaged for deployment and is at present untested
- I'm just moseying along with it.

Copyright 2011, Andrew Brookins. Released under the GPL v3.  See
LICENSE.txt for the license text.
