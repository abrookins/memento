# Models
mongoose = require 'mongoose'
db = mongoose.connect 'mongodb://localhost/memento'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

# Schemas - required to register a model.
Permission = new Schema
    user: ObjectId
    canView: {type: Boolean, default: no}
    canChange: {type: Boolean, default: no}
    canDelete: {type: Boolean, default: no}

Memory = new Schema
    title: String
    description: String
    place: { type: String, default: ""}
    lat: Number
    lon: Number
    date: Date
    date_added: { type: Date, default: Date.now }
    date_modified: { type: Date, default: Date.now }
    permissions: [Permission]
    author: String # For display
    owner: ObjectId
    map: ObjectId

Map = new Schema
    title: String
    author: String # Only for display
    owner: ObjectId # User
    permissions: [Permission]

User = new Schema
    admin: Boolean
    username: {type: String, unique: yes}
    email: {type: String, unique: yes}
    password: String
    date_added: { type: Date, default: Date.now }
    date_modified: { type: Date, default: Date.now }

# Register models.
mongoose.model "Permission", Permission
mongoose.model "Memory", Memory
mongoose.model "User", User
mongoose.model "Map", Map

# Make models available to import.
module.exports.User = mongoose.model "User"
module.exports.Map = mongoose.model "Map"
module.exports.Memory = mongoose.model "Memory"
module.exports.Permission = mongoose.model "Permission"
