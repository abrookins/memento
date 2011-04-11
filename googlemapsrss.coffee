# Parse GMaps RSS feeds.
request = require 'request'
sys = require 'sys'
xml2js = require 'xml2js-expat'

class Parser
    constructor: (@url) ->
   
    # Retrieve the georss/XML feed from Google, parse it into JSON.
    getJson: (callback) ->
        request {uri: @url}, (err, response, body) ->
            if err?
                callback(err)
            parser = new xml2js.Parser()
            parser.addListener 'end', (result, err) ->
                if err and error?
                    callback(err)
                callback null, result
            parser.parseString body

    # Parse coordinates and dates from the JSONified feed.
    parse: (callback) ->
        @getJson (err, result) ->
            entries = []
            if err?
                callback(err)
            for entry in result.channel.item
                entries.push
                    author: entry.author
                    date: new Date(Date.parse entry.pubDate)
                    title: entry.title
                    description: entry.description
                    point:
                        lat: entry['georss:point'].split(' ')[0]
                        lon: entry['georss:point'].split(' ')[1]
            parsedResult =
                title: result.channel.title
                subtitle: result.channel.title
                entries: entries
            callback null, parsedResult
    
# Adapter for Google Maps My Places RSS feed.
module.exports.Parser = Parser
