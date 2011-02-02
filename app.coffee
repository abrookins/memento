# MEMENTO 

hash = require 'node_hash'
mongoose = require './lib/mongoose'

# Database 
db = mongoose.connect 'mongodb://localhost/memento'

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

mongoose.model "Memory", Memory
mongoose.model "Place", Place
mongoose.model "User", User

# Make an instance of the User model available within routes.
def User: mongoose.model "User"
# Make the hash object available within routes.
def hash: hash

# Routes
get '/': ->
    if session.user
        redirect '/lifemap'
    render 'login'

get '/login': ->
    if session.user
        req.flash 'success', "Authenticated as #{session.user.name}"
        res.redirect '/lifemap'
    render 'login'

post '/login': ->
    path = '/login'
    redirect path unless params.username
    User.findOne {username: params.username}, (err, user) ->
        if err
            console.log "Error", err
        if user
            salt = "superblahblah--#{params.password}"
            salted_password = hash.sha1 params.password, salt

            if user.password is salted_password
                path = '/lifemap'
                session.regenerate ->
                    session.user = user
            else
                message = "Bad username or password."
    redirect path

get '/logout': ->
    session.destroy ->
        redirect '/'

get '/signup': ->
    if session.user
        request.flash 'success', "Authenticated as #{session.user.name}"
        redirect '/lifemap'
    render 'signup'

post '/signup': ->
    salt = "superblahblah--#{params.username}"
    salted_password = hash.sha1 params.password, salt
    salted_confirm_password = hash.sha1 params.password_confirm, salt
    @signup_user = null

    user = new User()
    user.username = params.username
    user.password = salted_password
    user.email = params.email

    if salted_password != salted_confirm_password
        @message = "Passwords do not match."
    else
        User.count {$or: [{username: params.username}, {email: params.email}]}, (err, count) ->
            if count = 0
                user.save()
            else
                @message = "Username or password already exists."
    if user.isNew # unsaved
        @signup_user = user
        render 'signup'
    else
        redirect '/lifemap'

# Views
view index: ->
    h1 'Blah'
    p 'Your mom. Word.'
    @message

view login: ->
    h1 'Login'
    p 'Please login or ', ->
        a href: '/signup', -> 'signup'
    p @message
    form method: 'post', action: 'login', ->
        input id: 'username', name: 'username', type: 'text', placeholder: "Username"
        input id: 'password', name: 'password', type: 'password', placeholder: "Password"
        button "Submit"

view signup: ->
    h1 'Signup'
    p @message
    form method: 'post', action: 'signup', ->
        input id: 'username', name: 'username', type: 'text', placeholder: "Username"
        input id: 'password', name: 'password', type: 'password', placeholder: "Password"
        input id: 'password_confirm', name: 'password_confirm', type: 'password', placeholder: "Confirm password"
        input id: 'email', name: 'email', type: 'text', placeholder: "Email"
        button "Submit"


