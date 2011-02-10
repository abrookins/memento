
(function() {
    // Use Django-style HTML templating with Underscore.
    _.templateSettings = {
        interpolate : /\{\{(.+?)\}\}/g
    };

    // Models
    var Memory, MemoryList;
    // Views 
    var AppView, MarkerView;
    // Controllers
    var HomeController;

    Memory = Backbone.Model.extend({});

    MemoryList = Backbone.Collection.extend({
        url: "/api/v1/memories/",
        model: Memory,
    });

    MarkerView =  Backbone.View.extend({
        template:  _.template(
            "<div class='marker-content'>"+
            "<span class='title'>{{ title }}</span>"+
            "<div class='marker-description'>{{ description }}</div>"+
            "<span class='date-header'>Date: </span <span class='date'>{{ date }}</span>"+
            "</div>"
        ),

        events: {
          "dblclick div.marker-content" : "edit",
          "click .marker-destroy" : "clear",
          "click .marker-save" : "save",
        },

        initialize: function() {
            this.map = this.options.map;
            this.infoWindow = this.options.infoWindow;

            // Setup events
            _.bindAll(this, "render", "edit", "open", "remove");
            this.delegateEvents(this.events);
            this.model.bind('change', this.render);

            // Set the infoWindow text for the marker.              
            // Set the position of the marker on the map.
            // Set the navigation item.
            var _this = this;
            var now = new Date();
            var date = new Date(Date.parse(this.model.get("date")));
            var position = new google.maps.LatLng(parseFloat(this.model.get("lat")),
                                                  parseFloat(this.model.get("lon")));
            // create a marker on the map
            // var icon = new GIcon();
            this.marker = new google.maps.Marker({
                position: position,
                map: this.map,
                zIndex: this.zIndexByAge
            });

            // Age in days
            this.marker.age = (now.getTime() - date.getTime()) / 86400000;

            // TODO: Use a template to create the content string, E.G:
            //$(this.el).html(this.template(this.model.toJSON()));
            // TODO: Add method to return info window content
            // TODO: Emit event when marker is clicked on 
            // TODO: Appview listens for event and does all of this

            // Show this marker's content when the user clicks its icon.
            // TODO: replace with backbone event that AppView listens for
            google.maps.event.addListener(this.marker, "click", function() {
                _this.open();
            });

            return this;
        },

        open: function() {
            var title = this.model.get("title");
            var description = this.model.get("description");
            var date = new Date(Date.parse(this.model.get("date")));
            var maxWidth = 350; // TODO: belongs elsewhere?

            // This marker's content for the infoWindow.
            var content = this.template({
                title: title,
                description: description,
                date: date.toDateString()
            });
                
            this.map.panTo(this.marker.getPosition());

            if(this.map.getZoom() < 12) {
                this.map.setZoom(12);
            }

            if(/\<img/.test(content)) {
                // Unset maxWidth value, so window will scale to content size.
                maxWidth = null
            }

            // Must close it to set new maxWidth.
            this.infoWindow.close();
            this.infoWindow.setOptions({
                maxWidth: maxWidth
            });
            this.infoWindow.setContent(content);
            this.infoWindow.open(this.map, this.marker);
        },

        edit: function() {
            console.log("called");
        },

        remove: function() {
            // Unregister marker events
            google.maps.event.clearInstanceListeners(this.marker);
            // Set map to null, causing marker to be removed per API spec
            this.marker.setMap(null); 
        },
    });

    NavigationItemView =  Backbone.View.extend({
        template: _.template("<li><a href='#markers/marker/{{ id }}'>{{ title }}</a></li>"),

        initialize: function() {
            _.bindAll(this, 'render');
            this.model.bind('change', this.render);
        },
    
        render: function() {
            // Add item to list of markers in sidebar
            // TODO: This should be a sortable list in a hierarchy, default to sort 
            // by year and month.
            // TODO: Server should return them sorted by date. 
            // TODO: Rendering should either create a new el or modify existing.
            var _this = this;
            var title = this.model.get("title");
            var id = this.model.get("id"); 
            var description = this.model.get("description");
            var date = new Date(Date.parse(this.model.get("date")));
            var position = new google.maps.LatLng(parseFloat(this.model.get("lat")),
                                                  parseFloat(this.model.get("lon")));
            var markerYear = date.getFullYear(); // unused?
            var navigation = $("#navigation-items");
            this.item = this.template({"title": title, "id": id});
            this.item = $(this.item).appendTo(navigation);
        },

        remove: function() {
            $(this.item).remove();
        }        
    });

    NavigationView = Backbone.View.extend({
        initialize: function() {
            this.itemViews= [];
            this.selectId = this.options.selectId || "year";

            _.bindAll(this, 'render', 'addOne', 'addAll', 'remove', 'getSelectedYear');
 
            this.collection.bind('add', this.addOne);
            this.collection.bind('refresh', this.render);

            // Set default options. 
            if(!this.id) {
                this.id = "navigation";
            }
        },

        addOne: function(memory) {
            var view = new NavigationItemView({
                model: memory
            });
            this.itemViews.push(view);
        },

        addAll: function(year) {
            var _this = this;

            this.collection.each(function(memory) {
                var memoryDate = new Date(Date.parse(memory.get("date")));
                if(year == "Any" || memoryDate.getFullYear().toString() == year) {
                    _this.addOne(memory);
                } 
            });
        },

        render: function() {
            var _this = this;
            var timeline = $("#timeline");
            var yearSelect = $("#"+this.selectId);
            var monthSelect = $("#month");
            var option = yearSelect.children("option:selected");
            var year = this.getSelectedYear();

            if(!this.slider) {
                var numberOfNonMonthOptions = 1;
                var numberOfOptions = yearSelect.children("option").size();
                var multiplier = numberOfOptions - numberOfNonMonthOptions;
                                                  ;
                this.slider = $(timeline).slider({
                    min: 1,
                    max: 12 * multiplier + numberOfNonMonthOptions,
                    value: yearSelect[0].selectedIndex + 1,
                    slide: function(event, ui) {
                        selectedYear = null;
                        selectedMonth = null;
                        if(ui.value <= numberOfNonMonthOptions) {
                            // Non-year options
                            selectedYear = ui.value;
                            selectedMonth = ui.value;
                        } else if(ui.value <= 12 + numberOfNonMonthOptions) {
                            // First year, so figure month
                            selectedYear = numberOfNonMonthOptions + 1;
                            selectedMonth = ui.value;
                        } else {
                            // Any year after the first: figure year and month
                            selectedYear = Math.ceil((ui.value - numberOfNonMonthOptions) / 12) + numberOfNonMonthOptions;
                            selectedMonth = ui.value - ((selectedYear - ( numberOfNonMonthOptions + 1)) * 12);
                        }
                        yearSelect[0].selectedIndex = selectedYear - 1;
                        monthSelect[0].selectedIndex = selectedMonth - 1;
                        _this.yearChanged();
                    }
                });

                yearSelect.change(function() {
                    var option = yearSelect.children("option:selected");
                    _this.slider.slider("value", option.index()+1);
                    _this.yearChanged(); // TODO: Why called multiple times?
                });
            }

            // Remove elements if they already exist.  
            this.remove();

            // Add subviews for all visible models.
            this.addAll(year);
        
            // Render all subviews
            $.each(this.itemViews, function() {
                this.render();   
            });
        },

        remove: function() {
            if(this.itemViews) {
                // Rmove all subviews
                $.each(this.itemViews, function() {
                    this.remove();
                }); 
                this.itemViews = [];
            }
        },

        getSelectedYear: function() {
            var option = $("#"+this.selectId).children("option:selected");
            return option.val();
        },

        yearChanged: function() {
            var year = this.getSelectedYear();

            // Notify watchers of the current years and render subviews.
            if(this.year == undefined || this.year != year) {
                this.year = year;
                this.render();
                this.trigger("nav:yearChanged", year);
            }
        }
    });

    AppView = Backbone.View.extend({
        initialize: function() {
            this.map = null;
            this.timeline = null; 
            this.eventSource = null;
            this.bandInfos = null;
            this.resizeTimerID = null;
            this.markerViews = [];
            this.navigationViews = [];

            defaults = {
                mapId: "map",
                list: "list",
                mapFilter: "hidePastFuture",
                infoWindowMaxWidth: 350,
                center: new google.maps.LatLng(45.52, -122.68),
                mapTypeId: google.maps.MapTypeId.TERRAIN,
                defaultZoomLevel: 10 
            };

            this.options = $.extend(defaults, this.options);

            // Bind 'this' to callbacks.
            _.bindAll(this, "addAll", "addOne", "render", "remove");

            // Respond to model changes. 
            //this.collection.bind("refresh", this.addAll);
            //this.collection.bind("add", this.addOne);

            this.map = this.initMap();
            this.infoWindow = this.initInfoWindow();
        },

        openMarker: function(id) {
            var marker = _.select(this.markerViews, function(view) {
                return view.model.get("id") == id;
            })[0];
            if(marker) {
                marker.open();
            }
        },

        initMap: function() {
            var mapOptions = {
                zoom: this.options.defaultZoomLevel,
                center: this.options.center,
                mapTypeId: this.options.mapTypeId
            }

            // TODO: Add map events, if any
            return new google.maps.Map(
                document.getElementById(this.options.mapId),
                mapOptions
            );
        },

        initInfoWindow: function() {
            var infoWindow = new google.maps.InfoWindow({
                maxWidth: this.options.infoWindowMaxWidth
            });

            // TODO: Add infoWindow events, if any
            return infoWindow;
        },

        addOne: function(memory) {
            this.markerViews.push(new MarkerView({
                model: memory,
                map: this.map,
                infoWindow: this.infoWindow
            }));
        },

        addAll: function(year) {
            var _this = this;

            this.collection.each(function(memory) {
                var memoryDate = new Date(Date.parse(memory.get("date")));
                if(year == "Any" || memoryDate.getFullYear().toString() == year) {
                    _this.addOne(memory);
                } 
            });
        },

        remove: function() {
            this.infoWindow.close();
            $.each(this.markerViews, function() {
                this.remove();
            });
        },

        render: function(year) {
            this.remove();
            this.addAll(year);

            // Pan map to the most recent memory on the map 
            var latestMemory = this.markerViews[this.markerViews.length-1];

            if(latestMemory !== undefined) {
                this.map.panTo(latestMemory.marker.getPosition());
            } else {
                // TODO: Handle the case where no markers are visible. 
            }

        }
    });

    HomeController = Backbone.Controller.extend({
        routes: {
            "markers/marker/:id": "openMarker",
        },

        initialize: function(options) {
            _.bindAll(this, "refresh", "openMarker", "filterMarkers");
            this.memories = new MemoryList();

            this.appView = new AppView({
                collection: this.memories
            });

            this.navigationView = new NavigationView({
                collection: this.memories
            });

            this.navigationView.bind("nav:yearChanged", this.filterMarkers);
            this.memories.bind("refresh", this.filterMarkers);
        },

        openMarker: function(id) {
            this.appView.openMarker(id);
        },

        filterMarkers: function(year) {
            this.appView.render(this.navigationView.getSelectedYear());
        },

        refresh: function(newMemories) {
            this.memories.refresh(newMemories);
        }
    });
        
    window.HomeController = HomeController;
})();
