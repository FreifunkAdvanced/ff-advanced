$(function () {

  var templates = {};
  var $spinner = $("#spinner");

  var renderContent = function renderContent ( content, nofade ) {
    var $main = $("#main");

    if ( _.isUndefined(nofade) || !nofade ) {
      $main.fadeOut(function () {
        $main.html(content);
        $main.fadeIn();
      });
    }
    else {
      $main.html(content);
    }
  };

  var fetchTemplate = function ( name, tplName, callback ) {
    renderContent($spinner, true);

    var view = arguments.callee;

    if ( _.isFunction(tplName) ) {
      callback = tplName;
      tplName = name;
    }

    if ( _.isUndefined(templates[name]) ) {
      $.get("/templates/" + tplName + ".html")
        .success(function ( tpl ) {
          templates[name] = tpl;
          view.template = templates[name];
          ich.addTemplate(name, view.template);
          callback();
        });
    }
    else {
      callback();
    }
  };

  var configClient = function configClient(mode, data, success) {
    var fn = mode === "update" ? $.post : $.getJSON;
    fn("/config/"+mode, data).success(success);
  };

  var updateConfig = function updateConfig(option, value, success) {
    configClient("update", {
      option: option,
      value: value
    }, success);
  };

  var readConfig = function readConfig(option, success) {
    configClient("update", {
      option: option
    }, success);
  };

  var app = function () {

    var LoginModel = Backbone.Model.extend({
      login: function () {
        //TODO: Login
        $.getJSON("/ws/login", {
          username: this.get("username"),
          password: this.get("password")
        })
          .success(function(data) {
            if(data.valid) {
              console.log("logging in");
              Backbone.history.navigate("!baseConfig", {trigger: true});
            }
            else {
              alert("Falscher Benutzer und/oder Passwort");
            }
          });
      }
    });

    var LoginFormView = Backbone.View.extend({

      id: "login-form",

      events: {
        "click #login": "login"
      },

      render: function () {
        var me = this;
        fetchTemplate("login", function () {
          me.setElement(ich.login());
          renderContent(me.$el);
        });
        return this;
      },

      login: function () {
        var loginModel = new LoginModel({
          user: this.$el.find("#user").val(),
          password: this.$el.find("#password").val()
        });

        loginModel.login();
      }

    });

    var BaseConfigView = Backbone.View.extend({

      tagName: "div",

      id: "base-config",

      events: {
        "click #save": "save"
      },

      render: function () {
        var me = this;
        fetchTemplate("baseConfig", "base_config", function () {
          me.setElement(ich.baseConfig());
          renderContent(me.$el);
        });
        return this;
      },

      save: function () {
        //TODO: save given values
      }

    });

    var WebadminRouter = Backbone.Router.extend({

      routes: {
        "": "login",
        "!baseConfig": "baseConfig",
        "!spinner": "spinner"
      },

      spinner: function () {
        renderContent($spinner, true);
      },

      login: function () {
        var loginForm = new LoginFormView();
        loginForm.render();
      },

      baseConfig: function () {
        var baseConfig = new BaseConfigView();
        baseConfig.render();
      }

    });

    new WebadminRouter();
    Backbone.history.start({pushState: false});

  };

  app();

});