# Routes
#
# TIP: Remember to use a hash rocket => when using callbacks 
# within a route in order to bind values to @ variables.

models = require './models'

# These modules will be available within routes.
def node_hash: require 'node_hash'
def _ : require 'underscore'
def User: models.User
def Map: models.Map
def Memory: models.Memory

helper login_required: ->
    redirect '/login' unless session.user?

get '/': ->
    login_required()
    Map.find {owner: session.user._id}, (err, maps) =>
        @maps = maps
        render 'dashboard'

get '/maps/map/:mapId': ->
    login_required()
    @years = []
    Map.findById @mapId, (err, map) =>
        if map
            # TODO: memories as embedded documents?
            Memory.find {map: map._id}, (err, memories) =>
                @mapId = map._id
                @years = _.uniq(m.date.getFullYear() for m in memories)
                @memories = memories
                render 'map'

post '/memories/memory/:memoryId': ->
    login_required()
    if @mapId and params._id
        Memory.findById @memoryId, (err, memory) =>
            if err
                console.log err.stack
                return
            for field, value of params
                skip = ['_id', 'mapId', 'permissions'] # TODO: why permissions fail?
                memory[field] = value if field not in skip and value isnt undefined
            memory.save (err) ->
                if err
                    console.log err.stack

get '/login': ->
    if session.user
        req.flash 'success', "Authenticated as #{session.user.name}"
        redirect '/'
    render 'login'

post '/login': ->
    render '/login' unless params.username
    User.findOne {username: params.username}, (err, user) =>
        found = false
        if err
            console.log "Error", err
        if user
            salt = "superblahblah--#{params.username}"
            salted_password = node_hash.sha1 params.password, salt
            if user.password is salted_password
                session.user = user
                redirect '/'
        @message = "Bad username or password."
        render 'login'

get '/logout': ->
    session.destroy ->
        redirect '/'

get '/signup': ->
    if session.user
        request.flash 'success', "Authenticated as #{session.user.name}"
        redirect '/map'
    render 'signup'

post '/signup': ->
    salt = "superblahblah--#{params.username}"
    salted_password = node_hash.sha1 params.password, salt
    salted_confirm_password = node_hash.sha1 params.password_confirm, salt
    signup_user = null
    message = null
    user = new User()
    user.username = params.username
    user.password = salted_password
    user.email = params.email

    if salted_password != salted_confirm_password
        message = "Passwords do not match."
    else
        query = {$or: [{username: params.username}, {email: params.email}]}
        User.count query, (err, count) =>
            if count is 0
                user.save()
                session.user = user
                redirect '/'
            else
                @message = "Username or password already exists."
                @signup_user = user
                render 'signup'
