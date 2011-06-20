WHAT THIS IS

Memento is an attempt to create a simple, easy-to-use and fun to
develop web app sharing location-based memories.

HOW IT WORKS

The server-side is CoffeeScript using the Zappa framework, which
itself wraps around Express (a node.js framework).

The front-end, located in public/js/map.coffee, is also written in
CoffeeScript and uses Backbone.js to organize logic between models,
views, and controllers.

I still need to implement an AJAX create form in the front-end for
adding items to a map. Until then, there is a command-line node.js
script that will import an RSS feed with geographical data and
create map items ("memories"). See: import_georss.coffee and
georss.coffee.

FORMALITIES 

Warning: This app is not packaged for deployment and is at present
untested. I'm just moseying along with it.

Copyright 2011, Andrew Brookins. Released under the GPL v3.  See
LICENSE.txt for the license text.
