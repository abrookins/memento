# Parse GMaps RSS and create Place data.
request = require 'request'
sys = require 'sys'
xml2js = require 'xml2js-expat'

class Parser 
    constructor: (@url) ->
    
    getJson: (callback) ->
        request {uri: @url}, (err, response, body) ->
            if err? and error?
                callback(err)
            parser = new xml2js.Parser()
            parser.addListener 'end', (result, err) ->
                if err and error?
                    callback(err)
                callback null, result
            parser.parseString body

    parse: (callback) ->
        @getJson (err, result) ->
            if err? and err?
                callback(err)

            #entries = []
            #for entry in result.content.entries
            #    entries.append
            #        author: entry.author

            parsedResult =
                title: result.channel.title
                subtitle: result.channel.title
                entries: result.channel.item
            callback null, parsedResult
    
#Adapter for Google Maps My Places RSS feed.
module.exports.Parser = Parser 
