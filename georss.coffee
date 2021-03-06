request = require 'request'
sys = require 'sys'
xml2js = require 'xml2js-expat'  # It's pretty fast.

# A limited RSS parser that converts the pubDate field to a Date object and
# normalizes geometric data included in feed items as "point" objects in the
# result. The parser is aware of points included using the GeoRSS Simple spec
# (a "georss:point" tag with both lat/lon in a single string) or the "geo:lat"
# and "geo:lon" tags.
class Parser
    constructor: (@url) ->
   
    # Retrieve the georss/XML feed and parse it into JSON.
    getJson: (callback) ->
        request {uri: @url}, (err, response, body) ->
            return callback err if err?
            parser = new xml2js.Parser()
            parser.addListener 'end', (result, err) ->
                return callback err, result
            parser.parseString body

    # Parse a single item in a feed.
    parseItem = (item) ->
        entry = point = {}
        for key, val of item
            switch key
                when "pubDate" then entry[key] = new Date(Date.parse val)
                when "georss:point"
                    # GeoRSS format is a string with lat and long, e.g., "-22.33 44.55"
                    point["lat"] = val.split(' ')[0]
                    point["lon"] = val.split(' ')[1]
                when "geo:lat" then point["lat"] = val # A non-GeoRSS format
                when "geo:long" then point["lon"] = val # A non-GeoRSS format
                # Default to naively storing the value.
                else entry[key] = item[key]
        if point
            entry["point"] = point
        return entry

    # Parse coordinates and dates from the JSONified feed.
    parse: (callback) ->
        @getJson (err, result) ->
            entries = []
            return callback err if err?
            for entry in result.channel.item
                entry = parseItem entry
                entries.push entry if entry?
            parsedResult =
                title: result.channel.title
                subtitle: result.channel.title
                entries: entries
            callback null, parsedResult

    
# Export the parser.
module.exports.Parser = Parser
