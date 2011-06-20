"""
Import data from a GeoRSS feed.
    - Get or create a User with the username specified on the command line.
    - Get or create a Map with the title of the feed.
    - Get or create a Memory for each item in the feed and assoc. with the map.
"""

Parser = require('./georss').Parser
{User, Map, Memory} = require('./models')

# Import optimist and setup command line arguments.
argv = require('optimist')
    .demand(['u', 'n'])
    .usage('Usage: -u [GeoRSS feed url] -n [username that will own the map (if new)]')
    .argv

url = argv.u # URL
username = argv.n # user who will own a map if this script needs to one
parser = new Parser url

# Parse the JSONified GeoRSS feed.
parser.parse (err, result) ->
    # Bail early if we couldn't parse the feed.
    if err
        console.log err.stack
    
    # Get or create a user.
    User.findOne {username: username}, (err, user) ->
        if err
            console.log err.stack
        user ?= new User {username: username}
        # Always trigger a save, even if the user existed.
        user.save (err) ->
            if err
                console.log err.stack
            importMap(user)
    
    # Get or create a map owned by the user.
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
            # Get or create a map with the title of the feed.
            # TODO: Not really really safe.
            map ?= new Map
                title: result.title
                owner: user._id
                author: user.username
            # TODO: Creates two perms? Diagnose.
            map.permissions.push fullPermissions
            map.save (err) ->
                if err
                    console.log err
                importItems(map, user, fullPermissions)

    # Import GeoRSS items as Memories.
    importItems = (map, user, permissions) ->
        for entry in result.entries
            memory = new Memory
                map: map._id
                title: entry.title
                description: entry.description
                lat: entry.point.lat
                lon: entry.point.lon
                date: entry.pubDate
                author: user.username
                owner: user._id
                permissions: [permissions]
            memory.save (err) ->
                if err
                    console.log err
        console.log "Done importing."
