# Routes

# Make the hash object available within routes.
using 'node_hash'

get '/': ->
    if session.user
        redirect '/map'
    render 'login'

get '/map': ->
    # TODO: Get places/memory JSON
    render 'map'

get '/login': ->
    if session.user
        req.flash 'success', "Authenticated as #{session.user.name}"
        res.redirect '/map'
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
                session.regenerate ->
                    session.user = user
                    redirect '/map'
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
        User.count {$or: [{username: params.username}, {email: params.email}]}, (err, count) =>
            if count is 0
                console.log "saved"
                user.save()
                redirect '/map'
            else
                console.log "not saved"
                @message = "Username or password already exists."
                @signup_user = user
                render 'signup'

