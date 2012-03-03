(function(global) {

  var templates = {};
  var $spinner = $("#spinner");

  var app = {
    util: {
      renderContent: function renderContent ( content, nofade ) {
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
      },

      fetchTemplate: function ( name, tplName, callback ) {
        app.util.renderContent($spinner, true);

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
      },

      config: (function configClient () {
        var client = function configClient ( mode, data, success ) {
          var fn = mode === "update" ? $.post : $.get;
          fn("/config/" + mode, data).success(success);
        };
        return {
          update: function updateConfig ( option, value, success ) {
            client("update", {
              option: option,
              value: value
            }, success);
          },

          read: function readConfig ( option, success ) {
            client("read", {
              option: option
            }, function ( data ) {
              var options = [];
              var lines = data.split('\n');
              _.each(lines, function(line) {
                var value = line.split('=').pop();
                var option = line.split('.').pop().split('=')[0];
                var config = {option: option, value: value};
                options.push(config);
              });
              success(options);
            });
          }
        };
      })(),

      redirect: function redirect ( route ) {
        Backbone.history.navigate("!" + route, {trigger: true});
      }
    },

    controller: function () {

      app.WebadminRouter = Backbone.Router.extend({

        routes: {
          "": "login",
          "!baseConfig": "baseConfig"
        },

        login: function () {
          var loginForm = new app.LoginFormView();
          loginForm.render();
        },

        baseConfig: function () {
          var baseConfig = new app.BaseConfigView();
          baseConfig.render();
        }

      });

      new app.WebadminRouter();
      Backbone.history.start({pushState: false});

    }
  };

  global.app = app;

})(window);