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


get '/': ->
    return redirect '/login' unless session.user?
    Map.find {owner: session.user._id}, (err, maps) =>
        @maps = maps
        render 'dashboard'

get '/maps/map/:mapId': ->
    return redirect '/login' unless session.user?
    @years = []
    Map.findById @mapId, (err, map) =>
        return console.log err.stack if err?
        if map
            # TODO: memories as embedded documents?
            Memory.find {map: map._id}, (err, memories) =>
                return console.log err.stack if err?
                @mapId = map._id
                @title = map.title
                @years = _.uniq(m.date.getFullYear() for m in memories)
                @memoryJson = JSON.stringify(memories)
                render 'map'

post '/memories/memory/:memoryId': ->
    return redirect '/login' unless session.user?
    if @mapId and params._id
        Memory.findById @memoryId, (err, memory) =>
            return console.log err.stack if err?
            for field, value of params
                skip = ['_id', 'mapId', 'permissions'] # TODO: why permissions fail?
                memory[field] = value if field not in skip and value isnt undefined
            memory.save (err) ->
                return console.log err.stack if err?

get '/login': ->
    if session.user
        req.flash 'success', "Authenticated as #{session.user.name}"
        return redirect '/'
    render 'login'

post '/login': ->
    return render '/login' unless params.username?
    User.findOne {username: params.username}, (err, user) =>
        found = false
        return console.log err.stack if err?
        if user
            salt = "superblahblah--#{params.username}"
            salted_password = node_hash.sha1 params.password, salt
            if user.password is salted_password
                session.user = user
                return redirect '/'
        @message = "Bad username or password."
        render 'login'

get '/logout': ->
    session.destroy ->
        return redirect '/'

get '/signup': ->
    if session.user
        request.flash 'success', "Authenticated as #{session.user.name}"
        return redirect '/'
    render 'signup'

post '/signup': ->
    salt = "^&%E^YRHFTH#$Tgeth5--#{params.username}"
    salted_password = node_hash.sha1 params.password, salt
    salted_confirm_password = node_hash.sha1 params.password_confirm, salt
    signup_user = null
    message = null
    user = new User()
    user.username = params.username
    user.password = salted_password
    user.email = params.email

    # Create a new User, a new session, and redirect to dashboard.
    create_user = (user) ->
        user.save (err) ->
            if err
                console.log err.stack
                flash "Sorry, an error occurred! Try again later."
                return
            session.regenerate () ->
                session.user = user
                return redirect '/'

    if salted_password != salted_confirm_password
        message = "Passwords do not match."
    else
        query = {$or: [{username: params.username}, {email: params.email}]}
        User.count query, (err, count) =>
            if count is 0
                # Create a new user and then redirect.
                new_user(user)
            @message = "Username or password already exists."
            @signup_user = user
            render 'signup'
