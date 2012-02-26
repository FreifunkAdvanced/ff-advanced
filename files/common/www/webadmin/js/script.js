$(function () {

  var templates = {};

  var fetchTemplate = function (name, tplName, callback) {
    var view = arguments.callee;

    if(_.isFunction(tplName)) {
      callback = tplName;
      tplName = name;
    }

    if (_.isUndefined(templates[name])) {
      $.get("/templates/"+tplName+".html")
        .success(function (tpl) {
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

  var app = function () {

    var $spinner = null;

    var renderContent = function renderContent ( content ) {
      var $main = $("#main");

      if ( $spinner === null ) {
        $spinner = $main.html();
      }

      $main.html(content);
    };

    var LoginModel = Backbone.Model.extend({
      login: function () {
        //TODO: Login
        console.log("logging in");
        Backbone.history.navigate("baseConfig", {trigger: true});
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
        "baseConfig": "baseConfig"
      },

      before: function () {
        renderContent($spinner);
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