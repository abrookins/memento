"""
Import My Places Google maps RSS feed from a URL for a specified user.
"""

Parser = require('./googlemapsrss').Parser
{User, Map, Memory} = require('./models')
_ = require('underscore')

# Import optimist and setup command line arguments.
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
                if err
                    console.log err
                    return
                counter--
                if counter == 0
                    importMap(user)

    # Create a Map object to hold the imported locations.
    importMap = (user) ->
        # Look for a map with the feed's title, owned by this user.
        Map.findOne {owner: user._id, title: result.title}, (err, map) ->
            fullPermissions =
                user: user._id
                canView: yes
                canChange: yes
                canDelete: yes
            if err
                console.log err.stack
                return
            # If a map doesn't already exist with the title, create one.
            map ?= new Map
                title: result.title
                owner: user._id
                author: user.username
            # TODO: Creates two perms? File bug.
            map.permissions.push fullPermissions
            map.save (err) ->
                if err
                    console.log err
                    return
                importLocations(map, user, fullPermissions)

    # Import Google Maps locations as memories.
    importLocations = (map, user, permissions) ->
        for entry in result.entries
            memory = new Memory
                map: map._id
                title: entry.title
                description: entry.description
                lat: entry.point.lat
                lon: entry.point.lon
                date: entry.date
                author: entry.author
                owner: user._id
                permissions: [permissions]
            memory.save (err) ->
                if err
                    console.log "Error: ", err
        console.log "Done importing."
