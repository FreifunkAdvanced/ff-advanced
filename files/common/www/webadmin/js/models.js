app.LoginModel = Backbone.Model.extend({
  login: function () {
    //TODO: Login
    $.getJSON("/ws/login", {
      username: this.get("username"),
      password: this.get("password")
    })
      .success(function ( data ) {
        if ( data.valid ) {
          console.log("logging in");
          app.util.redirect("baseConfig");
        }
        else {
          alert("Falscher Benutzer und/oder Passwort");
        }
      });
  }
});