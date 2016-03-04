# GraphQL.Relay

This library contains helper functions that make it easier to setup a Relay compatible GraphQL schema.

You do not need this library to create a Relay compatible GraphQL schema, it just makes it easier. To illustrate this point here's what a Relay compatible schema looks like <a href="https://github.com/seanabrahams/graphql-relay-elixir/blob/master/test/support/star_wars/schema_without_library.exs">when you don't use this library</a> and <a href="https://github.com/seanabrahams/graphql-relay-elixir/blob/master/test/support/star_wars/schema.exs">when you do use it</a>.

This library relies on the <a href="https://github.com/graphql-elixir/graphql-elixir">graphql-elixir</a> library.

## Learning GraphQL and Relay

It's important that you understand GraphQL first and then Relay second. Relay is simply a convention for how to organize a GraphQL schema so that Relay clients can query the GraphQL server in a standard way.

* <a href="https://facebook.github.io/react/blog/2015/05/01/graphql-introduction.html">GraphQL Introduction</a>
* <a href="https://code.facebook.com/posts/1691455094417024/graphql-a-data-query-language/">GraphQL: A data query language</a>
* <a href="https://medium.com/@clayallsopp/your-first-graphql-server-3c766ab4f0a2#.m78ybemas">Your First GraphQL Server</a>
* <a href="https://learngraphql.com/">Learn GraphQL</a>
* <a href="https://facebook.github.io/graphql/">GraphQL Specification</a>
* <a href="https://facebook.github.io/relay/">Relay</a>
* <a href="https://code-cartoons.com/a-cartoon-intro-to-facebook-s-relay-part-1-3ec1a127bca5#.7kaxn4akk">A Cartoon Guide To Facebook's Relay</a>

## Installation

  1. Add graphql_relay to your list of dependencies in `mix.exs`:

        def deps do
          [
            {:graphql_relay, "~> 0.0.9"},
            {:plug_graphql, git: "https://github.com/seanabrahams/plug_graphql.git", branch: "relay"} # This requirement will be removed in the near future but we need it right now
          ]
        end

## Configuration

Relay's Babel Plugin (<a href="https://facebook.github.io/relay/docs/guides-babel-plugin.html">Relay Docs</a>, <a href="https://www.npmjs.com/package/babel-relay-plugin">npm</a>) and babel-relay-plugin-loader (<a href="https://www.npmjs.com/package/babel-relay-plugin-loader">npm</a>, <a href="https://github.com/BerndWessels/babel-relay-plugin-loader">GitHub</a>) rely on a `schema.json` file existing that contains the result of running the full GraphQL introspection query against your GraphQL endpoint. Babel needs this file for transpiling GraphQL queries for use with Relay.

In other words, Relay requires a `schema.json` file which is generated server-side, so we need a way of creating and updating this file.

We need to set two configuration values which you can do in the `config/config.exs` for the project you're using this library in.

```elixir
config :graphql_relay,
  schema_module: GraphQL.Schema.Root, # Module that includes a `schema` function that returns your GraphQL schema
  schema_json_path: "#{Path.dirname(__DIR__)}/priv/repo/graphql" # Will create a `schema.json` file in this directory
```

With this configuration set you can now run the `GraphQL.Relay.generate_schema_json!` function from your project's root directory: `mix run -e GraphQL.Relay.generate_schema_json!`

If you're using this library in a Phoenix project you can <a href="https://github.com/graphql-elixir/graphql-relay-elixir/wiki/Setup-Phoenix-app-to-reload-schema.json-file-whenever-GraphQL-schema-files-change">set up your Phoenix dev environment to run this automatically after each modification to a GraphQL related schema file</a>.

## Quickstart

* Install elixir deps
* Install js deps
* Configure brunch
* Configure graphql_relay
* Write JS
* Setup graphql schema

## Not-So-Quickstart

Let's walk through setting up a new Phoenix project that uses `graphql-relay-elixir` by creating an implementation of <a href="http://todomvc.com">TodoMVC</a>. You will find this example application in the `examples/` directory of this very repository.

```bash
mix phoenix.new todo
cd todo
mix ecto.create
```

Add `graphql_relay` as a dependency in `mix.exs`:

```elixir
defp deps do
  [{:phoenix, "~> 1.0.3"},
   {:phoenix_ecto, "~> 1.1"},
   {:postgrex, ">= 0.0.0"},
   {:phoenix_html, "~> 2.1"},
   {:phoenix_live_reload, "~> 1.0", only: :dev},
   {:cowboy, "~> 1.0"},
   {:graphql_relay, "~> 0.0.8"},
   {:plug_graphql, git: "https://github.com/seanabrahams/plug_graphql.git", branch: "relay"}]
end
```

Run `mix deps.get`.

### Create TodoMVC models

```bash
mix phoenix.gen.model User users name:string email:string encrypted_password:string
mix phoenix.gen.model Todo todos body:string completed:boolean
```

### Create home page that will contain app

Update the default app layout, `web/templates/layout/app.html.eex`, to the following:

```eex
<!DOCTYPE html>
<html lang="en" data-framework="relay">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>graphql-relay-elixir • TodoMVC</title>
    <link rel="stylesheet" href="<%= static_path(@conn, "/css/app.css") %>">
  </head>

  <body>
    <div id="root"></div>
    <%= @inner %>
    <script src="<%= static_path(@conn, "/js/app.js") %>"></script>
  </body>
</html>
```

With this complete we can now start on our app. What do we need to do? Well we need to render something to the user so let's start there. For this to happen we need `app.js` to render something and for `app.js` to render something we're going to need some javascript libraries so let's update our `package.json`:

```javascript
{
  "repository": {
  },
  "dependencies": {
    "brunch": "^2.1.1",
    "babel-brunch": "^6.0.0",
    "babel-preset-react": "^6.3.13",
    "babel-preset-stage-0": "^6.5.0",
    "babel-relay-plugin": "^0.7",
    "classnames": "2.2.3",
    "clean-css-brunch": ">= 1.0 < 1.8",
    "css-brunch": ">= 1.0 < 1.8",
    "graphql": "^0.4.13",
    "graphql-relay": "^0.3.3",
    "history": "1.17.0",
    "javascript-brunch": ">= 1.0 < 1.8",
    "react": "^0.14.0",
    "react-dom": "^0.14.0",
    "react-relay": "^0.7.0",
    "react-router": "1.0.3",
    "react-router-relay": "0.8.0",
    "todomvc-app-css": "2.0.4",
    "todomvc-common": "1.0.2",
    "uglify-js-brunch": ">= 1.0 < 1.8"
  }
}
```

It turns out we need quite a few javascript libraries.

`npm install`

Now we need to update `brunch-config.js` so that it compiles everything properly. Ensure the `plugins` property looks like the following:

```json
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      presets: ["es2015", "react", "stage-0"],
      // plugins: ["babel-relay-plugin-loader"],
      ignore: [/web\/static\/vendor/],
      pattern: /\.(js|es6|jsx)$/
    }
  },
```

And since we're basing this on the TodoMVC code and using its `todomvc-common` npm package we need to create a `/learn.json` file accessible from the root of our web server. Thus we need to create a `learn.json` file in `web/staic/assets` which can contain the following:

```json
{
  "relay": {
    "name": "Relay",
    "description": "A JavaScript framework for building data-driven React applications",
    "homepage": "facebook.github.io/relay/",
    "examples": [{
      "name": "Relay + graphql-elixir/graphql_relay Example",
      "url": "",
      "source_url": "https://github.com/graphql-elixir/graphql_relay/tree/master/examples/todo",
      "type": "backend"
    }],
    "link_groups": [{
      "heading": "Official Resources",
      "links": [{
        "name": "Documentation",
        "url": "https://facebook.github.io/relay/docs/getting-started.html"
      }, {
        "name": "API Reference",
        "url": "https://facebook.github.io/relay/docs/api-reference-relay.html"
      }, {
        "name": "Relay on GitHub",
        "url": "https://github.com/facebook/relay"
      }]
    }, {
      "heading": "Community",
      "links": [{
        "name": "Relay on StackOverflow",
        "url": "https://stackoverflow.com/questions/tagged/relayjs"
      }]
    }]
  },
  "templates": {
    "todomvc": "<header> <h3><%= name %></h3> <span class=\"source-links\"> <% if (typeof examples !== 'undefined') { %> <% examples.forEach(function (example) { %> <h5><%= example.name %></h5> <% if (!location.href.match(example.url + '/')) { %> <a class=\"demo-link\" data-type=\"<%= example.type === 'backend' ? 'external' : 'local' %>\" href=\"<%= example.url %>\">Demo</a>, <% } if (example.type === 'backend') { %><a href=\"<%= example.source_url %>\"><% } else { %><a href=\"https://github.com/tastejs/todomvc/tree/gh-pages/<%= example.source_url ? example.source_url : example.url %>\"><% } %>Source</a> <% }); %> <% } %> </span> </header> <hr> <blockquote class=\"quote speech-bubble\"> <p><%= description %></p> <footer> <a href=\"http://<%= homepage %>\"><%= name %></a> </footer> </blockquote> <% if (typeof link_groups !== 'undefined') { %> <hr> <% link_groups.forEach(function (link_group) { %> <h4><%= link_group.heading %></h4> <ul> <% link_group.links.forEach(function (link) { %> <li> <a href=\"<%= link.url %>\"><%= link.name %></a> </li> <% }); %> </ul> <% }); %> <% } %> <footer> <hr> <em>If you have other helpful links to share, or find any of the links above no longer work, please <a href=\"https://github.com/tastejs/todomvc/issues\">let us know</a>.</em> </footer>"
  }
}
```

Then we need to update our `lib/todo/endpoint.ex` to serve the `learn.json` file when requested:

```elixir
plug Plug.Static,
  at: "/", from: :todo, gzip: false,
  only: ~w(css fonts images js favicon.ico learn.json robots.txt)
```

If you start the Phoenix server now and load the page you should see some info displayed:

`$ mix phoenix.server`

Manually update babel-relay-plugin per: https://github.com/facebook/relay/issues/887

Add route to `router.ex`

Run seeds: `mix run priv/repo/seeds.exs`

Symlink CSS files from npm packages

Empty `app.css`

### Jump all hurdles in our path
