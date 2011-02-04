# Import Google maps from a URL for a specified user.
# "http://maps.google.com/maps/ms?hl=en&gl=us&ie=UTF8&view=map&vps=1&jsv=298d&msa=0&output=georss&msid=116339465326062674750.00049598cedb49f5bd92f" andrew

_ = require('underscore')
Parser = require('./googlemapsrss').Parser
models = require('./models')
argv = require('optimist')
    .demand(['u', 'n'])
    .usage('Usage: -u [Google maps url] -n [username to import into]')
    .argv

url = argv.u
username = argv.n
parser = new Parser url

parser.parse (err, result) ->
    if err
        console.log err
        return
    for entry in result.entries
        # Try to find a user with entry's username.
        models.User.findOne {userame: entry.author}, (err, user) ->
            console.log "there"
            user ?= new models.User {username: entry.author}
            # Look for a map with the feed's title. Feed title is a map title.
            map = _.select user.maps, (map) ->
                map.title == result.title
            map ?= new models.Map {title: result.title, username: user.username}
            map.memories ?= [] # why necessary?
            map.memories.push
                title: entry.title
                description: entry.description
                lat: entry.lat
                lon: entry.lon
                date: entry.date
                author: entry.author
                userId: user.id
            user.maps.push map
            user.save()
            console.log(user)
