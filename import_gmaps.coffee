# Import Google maps from a URL for a specified user.
# "http://maps.google.com/maps/ms?hl=en&gl=us&ie=UTF8&view=map&vps=1&jsv=298d&msa=0&output=georss&msid=116339465326062674750.00049598cedb49f5bd92f" andrew

Parser = require('./googlemapsrss').Parser
models = require('./models')
_ = require('underscore')
argv = require('optimist')
    .demand(['u', 'n'])
    .usage('Usage: -u [Google maps url] -n [username to import into]')
    .argv

url = argv.u # URL
username = argv.n # username
parser = new Parser url

parser.parse (err, result) ->
    if err
        console.log err
        return
    users = []
    # Create any users in the result set that do not already exist.
    users.push e.author for e in result.entries when e.author not in users
    counter = users.length
    for username in users
        models.User.findOne {username: username}, (err, user) ->
            if err
                console.log(err)
                return
            user ?= new models.User {username: username}
            # We probably shouldn't save existing users.
            user.save (err) ->
                counter--
                if counter == 0
                    importLocations()
    # Import Google Maps locations as objects.
    importLocations = ->
        counter = 0
        for entry in result.entries
            # Try to find a user with entry's username.
            models.User.findOne {username: entry.author}, (err, user) ->
                if err
                    console.log err.stack
                if not user
                    console.log "Could not find user: ", entry.author
                if err or not user
                    return
                # Look for a map with the feed's title.
                map = _.select user.maps, (map) ->
                    map.title == result.title
                console.log map
                # If a map doesn't already exist with the title, create one.
                if map.length == 0
                    user.maps.push
                        title: result.title
                        author: user.username
                        permissions:
                            userId: user._id
                            canView: yes
                            canChange: yes
                            canDelete: yes
                    map = user.maps[0]
                else
                    # Use the first one that matched.
                    map = map[0]
                map.memories.push
                    title: entry.title
                    description: entry.description
                    lat: entry.point.lat
                    lon: entry.point.lon
                    date: entry.date
                    author: entry.author
                user.save()
