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

    className: "login-form well",

    events: {
      "click #login": "login"
    },

    render: function () {
      this.$el
        .append($("<label/>")
          .attr("for", "user")
          .html("User"))
        .append($("<input/>")
          .addClass("span3")
          .attr("type", "text")
          .attr("name", "user")
          .attr("id", "user"))
        .append($("<label/>")
          .attr("for", "user")
          .html("Password"))
        .append($("<input/>")
          .addClass("span3")
          .attr("type", "text")
          .attr("name", "password")
          .attr("id", "password"))
        .append("<label/>")
        .append($("<button/>")
            .attr("type", "button")
            .attr("name", "login")
            .html("Login")
            .attr("id", "login")
            .addClass("btn"))
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