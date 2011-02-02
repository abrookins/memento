# Models

mongoose = require 'mongoose'  # Mongo driver/ORM
db = mongoose.connect 'mongodb://localhost/memento'
Schema = mongoose.Schema

Memory = new Schema
    title: String
    description: String
    date: Date
    date_added: { type: Date, default: Date.now }
    date_modified: { type: Date, default: Date.now }

Place = new Schema
    name: String
    lon: Number
    lat: Number
    date_added: { type: Date, default: Date.now }
    date_modified: { type: Date, default: Date.now }
    memories: [Memory]

User = new Schema
    username: String
    email: String
    password: String
    date_added: { type: Date, default: Date.now }
    date_modified: { type: Date, default: Date.now }
    memories: [Memory]

mongoose.model "Memory", Memory
mongoose.model "Place", Place
mongoose.model "User", User

# Make an instance of the User model available within routes.
def User: mongoose.model "User"

