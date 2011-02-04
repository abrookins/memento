# Models

mongoose = require 'mongoose'
db = mongoose.connect 'mongodb://localhost/memento'
Schema = mongoose.Schema

mongoose.model "Memory", new Schema
    title: String
    description: String
    place: String
    lat: Number
    lon: Number
    date: Date
    date_added: { type: Date, default: Date.now }
    date_modified: { type: Date, default: Date.now }
    author: String # Sucks to change, but noSQL?
    userId: Schema.ObjectId # Ref to user owner
Memory = mongoose.model "Memory"

mongoose.model "Map", new Schema
    # TODO: permissions
    title: String # TODO: Unique
    username: String
    userId: Schema.ObjectId
    memories: [Memory]
Map = mongoose.model "Map"

mongoose.model "User", new Schema
    username: String # TODO: Unique
    email: String # TODO: Unique
    password: String
    date_added: { type: Date, default: Date.now }
    date_modified: { type: Date, default: Date.now }
    memories: [Memory] # Data duplication FTW?
    maps: [Map]
User = mongoose.model "User"

# Make models available to import.
module.exports.User = User
module.exports.Map = Map
module.exports.Memory = Memory
