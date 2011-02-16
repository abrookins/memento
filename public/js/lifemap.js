
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

    Memory = Backbone.Model.extend({
        escapedJson: function() {
            return {
                title: this.escape("title"),
                author: this.escape("author"),
                date: this.get("date"),
                place: this.escape("place"),
                description: this.escape("description"),
                _id: this.get("_id")
            };
        }
    });

    MemoryList = Backbone.Collection.extend({
        model: Memory,
    });

    MarkerView =  Backbone.View.extend({
        template:  _.template(
            "<div class='marker-content'>" +
                "<div class='marker-header'>" + 
                    "<span class='title'>{{ title }}</span>" +
                    "<span class='meta'>Added by {{ author }} on {{ date }}</span>" +
                "</div>" +
                "<div class='marker-place'><emphasis>{{ place }}</emphasis></div>" +
                "<div class='marker-description'>{{ description }}</div>" +
                "<a class='edit-marker' name='edit-marker' href='#markers/marker/edit/{{ _id }}'>Edit</a>" +
            "</div>"
        ),

        editTemplate: _.template(
            "<div class='marker-edit-form'>" +
                "<form id='marker-edit'>" +
                "<input id='title' name='title' type='text' value='{{ title }}' placeholder='Title'>" + 
                "<input id='place' name='place' type='text' value='{{ place }}' placeholder='Place'>" + 
                "<textarea id='description-{{ _id }}' name='description' rows=25 cols=45 placeholder='Description'>{{ description }}</textarea>" +
                "<a class='save-button' name='save-button' href='#markers/marker/save/{{ _id }}'>Save</a>" +
                "<a class='cancel-button' name='cancel-button' href='#markers/marker/cancel/{{ _id }}'>Cancel</a>" +
            "</div>"
        ),

        // Actions that URLs are allowed to trigger.
        validActions: ['open', 'close', 'save', 'edit', 'cancel', 'toggle'],

        initialize: function() {
            var _this = this;
            this.map = this.options.map;
            this.infoWindow = this.options.infoWindow;
            this.maxWidth = 350;
            this.zoomLevel = 12;
            this.editButton = null;
            this.editing = null;
            this.ckeditor = null;

            // Bind 'this' to the view in all methods.
            // TODO: Isn't this only necessary if the method will be used
            // in an event callback?
            _.bindAll(this, "render", "edit", "open", "close", "save", "toggle",
                      "remove", "openInfoWindow", "readOnlyHtml", "editFormHtml",
                      "handleAction");

            this.model.bind('change', this.render);

            var now = new Date();
            var date = new Date(Date.parse(this.model.get("date")));
            var position = new google.maps.LatLng(parseFloat(this.model.get("lat")),
                                                  parseFloat(this.model.get("lon")));
            
            // Create a new Google Maps marker for this memory.
            this.marker = new google.maps.Marker({
                position: position,
                map: this.map,
                zIndex: this.zIndexByAge
            });

            // Age in days. TODO: Used?
            this.marker.age = (now.getTime() - date.getTime()) / 86400000;

            // Show this marker's content when the user clicks its icon.
            // TODO: Appview listens for event and does this?
            google.maps.event.addListener(this.marker, "click", function() {
                _this.open();
            });

            return this;
        },

        openInfoWindow: function(content) {
            var _this = this;
            var maxWidth = this.maxWidth;
            var height = null;
            if(/\<img/.test(content) || this.editing) {
                maxWidth = null;
            } 
            // Google's API requires .close() to set new max-width.
            this.infoWindow.close();
            this.infoWindow.setOptions({
                maxWidth: maxWidth,
            });
            this.infoWindow.setContent(content);
            this.infoWindow.open(this.map, this.marker);

            // When editing a form, add a CKeditor widget; otherwise destroy widget.
            clear = function() {
                _this.clearEditor();
                _this.clearInfoWindowEvents();
            }
            if(this.editing === null) {
                // Clear any lingering events. TODO: should happen when window closes.
                clear();
            } else if(this.editing) {
                google.maps.event.addListener(this.infoWindow, 'domready', function() {
                    _this.addEditor();
                });
            }
            google.maps.event.addListener(this.infoWindow, 'closeclick', function() {
                clear();
            });
            google.maps.event.addListener(this.infoWindow, 'content_changed', function() {
                clear();
            });
        },

        addEditor: function() {
            if(!this.ckeditor) {
                this.ckeditor = CKEDITOR.replace('description-' + this.model.get("_id"), {
                    toolbar: [['Source', '-', 'Bold', 'Italic', 'Image', 'Link', 'Unlink']]
                });
            }
        },

        clearEditor: function() {
            if(this.ckeditor) {
                CKEDITOR.remove(this.ckeditor);
                this.ckeditor = null;
            }
        },

        clearInfoWindowEvents: function() {
            google.maps.event.clearListeners(this.infoWindow, 'domready');
            google.maps.event.clearListeners(this.infoWindow, 'content_changed');
            google.maps.event.clearListeners(this.infoWindow, 'closeclick');
        },

        // Replace the marker's infoWindow with read-only HTML.
        readOnlyHtml: function() {
            return this.template(this.model.toJSON());
        },

        // Replace the marker's infoWindow with an edit form.
        editFormHtml: function() {
            return this.editTemplate(this.model.escapedJson())
        },

        // Handle an action routed from the controller if the action is valid.
        handleAction: function(action) {
            if(typeof(this[action]) == 'function' && _.indexOf(this.validActions, action) !== -1) {
                this[action]();
            }
        },

        // ACTIONS
       
        open: function() {
            var _this = this;
    
            // Pan to the marker
            this.map.panTo(this.marker.getPosition());

            if(this.map.getZoom() < this.zoomLevel) {
                this.map.setZoom(this.zoomLevel);
            }
            
            this.editing = false;
            this.openInfoWindow(this.readOnlyHtml());
        },

        edit: function() {
            this.toggle();
        },

        cancel: function() {
            this.toggle();
        },

        close: function() {
            console.log("Closed");
        },

        toggle: function() {
            var content;

            // If the marker has never been opened, redirect and open.
            if(this.editing == null) {
                window.location = "#markers/marker/open/" + this.model.get("_id");
                return;
            }
            if(this.editing) {
                content = this.readOnlyHtml();
                this.editing = false;
            } else {
                content = this.editFormHtml();
                this.editing = true;
            }

            $(this.el).html(content);
            this.openInfoWindow(content);
        },

        save: function() {
            // This won't work if we aren't on an edit form.
            if(!this.editing) {
                return;
            }
            title = $("#title").val();
            place = $("#place").val();
            description = this.ckeditor.getData();
            console.log(description);
            this.model.set({
                title: title,
                place: place,
                description: description
            });
            this.model.save();
            this.toggle();
        },

        remove: function() {
            // Unregister marker events
            google.maps.event.clearInstanceListeners(this.marker);
            // Set map to null, causing marker to be removed per API spec
            this.marker.setMap(null); 
        },
    });

    NavigationItemView =  Backbone.View.extend({
        template: _.template("<li><a href='#markers/marker/open/{{ id }}'>{{ title }}</a></li>"),

        initialize: function() {
            _.bindAll(this, 'render');
            this.model.bind('change', this.render);
        },
    
        render: function() {
            // Add item to list of markers in sidebar
            var _this = this;
            // First remove it if it already exists
            if(this.item) {
                this.remove();
            }
            var date = new Date(Date.parse(this.model.get("date"))); // unused
            var markerYear = date.getFullYear(); // unused
            var navigation = $("#navigation-items");
            this.item = this.template({"title": this.model.get("title"),
                                      "id": this.model.get("_id")});
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

            if(!this.slider) {
                this.renderSlider();
            }

            // Remove elements if they already exist.  
            this.remove();

            // Add subviews for all visible models.
            this.addAll(this.getSelectedYear());
        
            // Render all subviews
            $.each(this.itemViews, function() {
                this.render();   
            });
        },

        renderSlider: function() {
            var _this = this;
            var timeline = $("#timeline");
            var yearSelect = $("#"+this.selectId);
            var monthSelect = $("#month");
            var option = yearSelect.children("option:selected");
            var numberOfNonMonthOptions = 1;
            var numberOfOptions = yearSelect.children("option").size();
            var multiplier = numberOfOptions - numberOfNonMonthOptions;

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

        sendActionToMarker: function(action, id) {
            var marker = _.select(this.markerViews, function(view) {
                return view.model.get("_id") == id;
            })[0];
            if(marker) {
                marker.handleAction(action);
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
            "markers/marker/:action/:id": "sendActionToMarker",
        },

        initialize: function(options) {
            _.bindAll(this, "refresh", "sendActionToMarker", "filterMarkers");
            this.memories = options.memories;

            this.appView = new AppView({
                collection: this.memories
            });

            this.navigationView = new NavigationView({
                collection: this.memories
            });

            this.navigationView.bind("nav:yearChanged", this.filterMarkers);
            this.memories.bind("refresh", this.filterMarkers);
        },

        sendActionToMarker: function(action, id) {
            this.appView.sendActionToMarker(action, id);
        },

        filterMarkers: function(year) {
            this.appView.render(this.navigationView.getSelectedYear());
        },

        refresh: function(newMemories) {
            this.memories.refresh(newMemories);
        }
    });
        
    window.HomeController = HomeController;
    window.MemoryList = MemoryList;
})();
