app.LoginFormView = Backbone.View.extend({

  id: "login-form",
  tagName: "div",

  events: {
    "click #login": "login"
  },

  render: function () {
    var me = this;
    app.util.fetchTemplate("login", function () {
      me.$el.html(ich.login());
      app.util.renderContent(me.el);
    });
    return this;
  },

  login: function () {
    var loginModel = new app.LoginModel({
      user: this.$el.find("#user").val(),
      password: this.$el.find("#password").val()
    });

    loginModel.login();
  }

});

app.BaseConfigView = Backbone.View.extend({

  tagName: "div",

  id: "base-config",

  events: {
    "click #save": "save"
  },

  render: function () {
    var me = this;
    app.util.fetchTemplate("baseConfig", "base_config", function () {
      me.$el.html(ich.baseConfig());
      app.util.renderContent(me.el);
    });
    return this;
  },

  save: function () {
    //TODO: save given values
  }

});