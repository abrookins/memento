# Import Google maps from a URL for a specified user.
# "http://maps.google.com/maps/ms?hl=en&gl=us&ie=UTF8&view=map&vps=1&jsv=298d&msa=0&output=georss&msid=116339465326062674750.00049598cedb49f5bd92f" andrew

Parser = require('./googlemapsrss').Parser

argv = require('optimist')
    .demand(['u', 'n'])
    .usage('Usage: -u [Google maps url] -n [username to import into]')
    .argv

url = argv.u
username = argv.n
parser = new Parser url

parser.parse (err, result) ->
    console.log result
