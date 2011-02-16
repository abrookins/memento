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
        if @signup_user
            input id: 'username', name: 'username', type: 'text', value: @signup_user.username
            input id: 'password', name: 'password', type: 'password', placeholder: "Password"
            input id: 'password_confirm', name: 'password_confirm', type: 'password', placeholder: "Confirm password"
            input id: 'email', name: 'email', type: 'text', value: @signup_user.email
        else
            input id: 'username', name: 'username', type: 'text', placeholder: "Username"
            input id: 'password', name: 'password', type: 'password', placeholder: "Password"
            input id: 'password_confirm', name: 'password_confirm', type: 'password', placeholder: "Confirm password"
            input id: 'email', name: 'email', type: 'text', placeholder: "Email"
        button "Submit"

view map: ->
    memoryJson = (memory.toJSON() for memory in @memories)
    # TODO: Generate years with list comprehension in view.
    div id: 'lifemap', ->
        div id: 'navigation-container', ->
            h1 id: 'navigation-header', -> "Moments"
            div id: 'navigation', ->
                div id: 'timeline-container', ->
                    div id: 'timeline', ->
                        form id: 'timeline-select', ->
                            label for: 'year', -> "Year"
                            select id: 'year', name: 'year', ->
                                option 'Any'
                                option year for year in @years
                            label for: 'month', -> 'Month'
                            select id: 'month', name: 'month', ->
                                option 'Any'
                                option 'January'
                                option 'February'
                                option 'March'
                                option 'April'
                                option 'May'
                                option 'June'
                                option 'July'
                                option 'August'
                                option 'September'
                                option 'October'
                                option 'November'
                                option 'December'
                ul id: 'navigation-items'
        div id: 'content', ->
            div id: 'mapcontainer', ->
                div id: 'map'
    script """
        (function($) { 
            $(window).load(function() {
                var memories = new MemoryList();
                memories.url = "/api/v1/map/#{@mapId}";
                var hc = new HomeController({
                    memories: memories
                });
                memories.refresh([#{memoryJson}]);
                Backbone.history.start();
            });
        })(jQuery);
        """
layout ->
    html ->
        head -> 
            title 'Our Life'
            link type: 'text/css', href: 'css/Aristo/jquery-ui-1.8.5.custom.css', rel: 'stylesheet'
            link type: 'text/css', href: 'css/moments.css', rel: 'stylesheet'
            script type: "text/javascript", src: 'http://maps.google.com/maps/api/js?sensor=false'
            script type: "text/javascript", src: 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.3/jquery.min.js'
            script type: "text/javascript", src: 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.5/jquery-ui.min.js'
            script type: "text/javascript", src: 'js/ckeditor/ckeditor.js'
            script type: "text/javascript", src: 'js/underscore.js'
            script type: "text/javascript", src: 'js/json2.js'
            script type: "text/javascript", src: 'js/backbone.js'
            script type: "text/javascript", src: 'js/lifemap.js'
        body ->
            @content

