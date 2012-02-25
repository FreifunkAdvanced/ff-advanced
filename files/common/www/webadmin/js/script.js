$(function () {
  var $spinner = null;

  var render = function render ($view) {
    var $main = $("#main");

    if($spinner === null) {
      $spinner = $main.html();
    }

    $main.html($view);
  };

  var LoginModel = Backbone.Model.extend({
    login: function () {
      //TODO: Login
      console.log("logging in");
    }
  });

  var LoginFormView = Backbone.View.extend({

    tagName: "form",

    className: "login-form",

    events: {
      "click #login": "login"
    },

    render: function () {
      this.$el
        .append($("<input/>")
          .attr("type", "text")
          .attr("name", "user")
          .attr("id", "user"))
        .append($("<input/>")
          .attr("type", "text")
          .attr("name", "password")
          .attr("id", "password"))
        .append($("<input/>")
          .attr("type", "button")
          .attr("name", "login")
          .attr("value", "Login")
          .attr("id", "login"))
      ;

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

  var WebadminRouter = Backbone.Router.extend({

    routes: {
      "": "login"
    },

    before: function () {
      render($spinner);
    },

    login: function () {
      var loginForm = new LoginFormView();
      render(loginForm.render().$el);
    }

  });

  new WebadminRouter();
  Backbone.history.start({pushState: true});

});