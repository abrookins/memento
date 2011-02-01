# MEMENTO 

hash = require 'node_hash'
mongoose = require './lib/mongoose'

# Database 
mongoose.connect('mongodb://localhost/memento');

# Models
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

mongoose.model("Memory", Memory)
mongoose.model("Place", Place)
mongoose.model("User", User)

# Routes
get '/': ->
    if request.session.user
        request.flash 'success', "Authenticated as #{req.session.user.name}"
        redirect '/dashboard'
    @message = "Please log in."
    render 'index'

get '/login': ->
   if req.session.user
        req.flash 'success', "Authenticated as #{req.session.user.name}"
        res.redirect '/dashboard'
        @message = "Logged in."
    render 'index'

post '/login': ->
    params = req.body
    User = mongoose.model("User")
    if params.commit.login
        user = User.find({username: params.user.name}) 
        if user
            salt = "superblahblah--#{params.user.password}"
            salted_password = hash.sha1 params.user.password, salt

            if doc.password is salted_password
                request.session.regenerate(() ->
                    request.session.user = params.user
                    resuest.redirect '/dashboard'
                )
            else
                res.redirect '404'
        else
            request.flash 'error', 'User does not exist!'
            res.redirect '/login'


# Views
view index: ->
    h1 'Blah'
    p 'Your mom. Word.'
    p @message


