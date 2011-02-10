# Import Google maps from a URL for a specified user.
#
# Example URL:
# "http://maps.google.com/maps/ms?hl=en&gl=us&ie=UTF8&view=map&vps=1&jsv=298d&msa=0&output=georss&msid=116339465326062674750.00049598cedb49f5bd92f"

Parser = require('./googlemapsrss').Parser
User = require('./models').User
Map = require('./models').Map
Memory = require('./models').Memory
_ = require('underscore')
argv = require('optimist')
    .demand(['u', 'n'])
    .usage('Usage: -u [Google maps url] -n [username to import into]')
    .argv

url = argv.u # URL
username = argv.n # username
parser = new Parser url

# Parse the JSONified GeoRSS returned by Google Maps.
parser.parse (err, result) ->
    # Unique users in the result set
    users = []

    if err
        console.log err.stack
        return

    # Create a list of unique users.
    users.push e.author for e in result.entries when e.author not in users
    # Use a counter determine when async user creation has finished.
    counter = users.length

    for username in users
        User.findOne {username: username}, (err, user) ->
            if err
                console.log err.stack
                return
            user ?= new User {username: username}
            # We always trigger a save, even if the user existed.
            user.save (err) ->
                counter--
                if counter == 0
                    # TODO: import with real map owner.
                    importMap(user)

    # Create a Map object to hold the imported locations.
    importMap = (user) ->
        # Look for a map with the feed's title, owned by this user.
        Map.findOne {owner: user.username, title: result.title}, (err, map) ->
            fullPermissions =
                userId: user._id
                canView: yes
                canChange: yes
                canDelete: yes
            if err
                console.log err.stack
                return
            # If a map doesn't already exist with the title, create one.
            map ?= new Map
                title: result.title
                owner: user.username
            # TODO: Creates two perms. File bug.
            map.permissions.push fullPermissions
            map.save (err) ->
                importLocations(map, fullPermissions)

    # Import Google Maps locations as memories.
    importLocations = (map, permissions) ->
        for entry in result.entries
            memory =
                title: entry.title
                description: entry.description
                lat: entry.point.lat
                lon: entry.point.lon
                date: entry.date
                author: entry.author
                permissions: [permissions]
            map.memories.push(memory)
        map.save()
        console.log "Done importing."
