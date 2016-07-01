# GraphQL.Relay

This library contains helper functions that make it easier to setup a Relay compatible GraphQL schema.

You do not need this library to create a Relay compatible GraphQL schema, it just makes it easier. To illustrate this point here's what a Relay compatible schema looks like [when you don't use this library](https://github.com/graphql-elixir/graphql_relay/blob/master/test/support/star_wars/schema_without_library.exs) and [when you do use it](https://github.com/graphql-elixir/graphql_relay/blob/master/test/support/star_wars/schema.exs).

This library relies on the [GraphQL Elixir](https://github.com/graphql-elixir/graphql) library.

## Installation

Add `graphql_relay` to your list of dependencies in `mix.exs`:

    def deps do
      [{:graphql_relay, "~> 0.5"}]
    end

## Configuration

Relay requires a `schema.json` file which is generated server-side, so we need a way of creating and updating this file.

In `config/config.exs` add the following config:

```elixir
config :graphql_relay,
  schema_module: MyApp.Schema,
  schema_json_path: "#{Path.dirname(__DIR__)}/priv/graphql"
```

* `MyApp.Schema` is a module with a `schema` function that returns your GraphQL schema
* The `schema_json_path` is where the generated JSON schema lives

Generate your schema with:

    mix run -e GraphQL.Relay.generate_schema_json!

## Phoenix Integration

In Phoenix you can generate the schema automatically after each modification to a GraphQL related schema file in the dev environment:

* [Phoenix Dev Setup](https://github.com/graphql-elixir/graphql_relay/wiki/Setup-Phoenix-app-to-reload-schema.json-file-whenever-GraphQL-schema-files-change)

## Babel and Relay

Relay's Babel Plugin ([Relay Docs](https://facebook.github.io/relay/docs/guides-babel-plugin.html), [npm](https://www.npmjs.com/package/babel-relay-plugin)) and `babel-relay-plugin-loader` ([npm](https://www.npmjs.com/package/babel-relay-plugin-loader), [GitHub](https://github.com/BerndWessels/babel-relay-plugin-loader)) rely on a `schema.json` file existing that contains the result of running the full GraphQL introspection query against your GraphQL endpoint. Babel needs this file for transpiling GraphQL queries for use with Relay.

## Usage

See the [Star Wars test schema](https://github.com/graphql-elixir/graphql_relay/blob/master/test/support/star_wars/schema.exs) for a simple example and the [TodoMVC example Phoenix application](https://github.com/graphql-elixir/graphql_relay/blob/master/examples/todo) for a full application example that uses Ecto as well.

* [How to do authentication and authorization in a Phoenix application with GraphQL](https://github.com/graphql-elixir/graphql/wiki/How-to-do-authentication-and-authorization-in-a-Phoenix-application-with-GraphQL)

## Learning GraphQL and Relay

It's important that you understand GraphQL first and then Relay second. Relay is simply a convention for how to organize a GraphQL schema so that Relay clients can query the GraphQL server in a standard way.

* [GraphQL Introduction](https://facebook.github.io/react/blog/2015/05/01/graphql-introduction.html)
* [GraphQL: A data query language](https://code.facebook.com/posts/1691455094417024/graphql-a-data-query-language/)
* [Your First GraphQL Server](https://medium.com/@clayallsopp/your-first-graphql-server-3c766ab4f0a2#.m78ybemas)
* [Learn GraphQL](https://learngraphql.com/)
* [GraphQL Specification](https://facebook.github.io/graphql/)
* [Relay](https://facebook.github.io/relay/)
* [A Cartoon Guide To Facebook's Relay](https://code-cartoons.com/a-cartoon-intro-to-facebook-s-relay-part-1-3ec1a127bca5#.7kaxn4akk)

## Helpful Tools

* [React [and Relay] Developer Tools](https://github.com/facebook/react-devtools) for Chrome and Firefox.
