# Models
mongoose = require './lib/mongoose'
db = mongoose.connect 'mongodb://localhost/memento'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

# Permissions
Permission = new Schema
    user: ObjectId
    canView: {type: Boolean, default: no}
    canChange: {type: Boolean, default: no}
    canDelete: {type: Boolean, default: no}
mongoose.model "Permission", Permission

Memory = new Schema
    title: String
    description: String
    place: String
    lat: Number
    lon: Number
    date: Date
    date_added: { type: Date, default: Date.now }
    date_modified: { type: Date, default: Date.now }
    permissions: [Permission]
    author: String # For display
    owner: ObjectId
    map: ObjectId
mongoose.model "Memory", Memory

Map = new Schema
    title: String 
    author: String # Only for display
    owner: ObjectId # User
    permissions: [Permission]
mongoose.model "Map", Map

User = new Schema
    admin: Boolean
    username: {type: String, unique: yes}
    email: {type: String, unique: yes}
    password: String
    date_added: { type: Date, default: Date.now }
    date_modified: { type: Date, default: Date.now }
mongoose.model "User", User

# Make models available to import.
module.exports.User = mongoose.model "User"
module.exports.Map = mongoose.model "Map"
module.exports.Memory = mongoose.model "Memory"
module.exports.Permission = mongoose.model "Permission"
