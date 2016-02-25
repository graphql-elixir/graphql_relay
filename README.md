# GraphQL.Relay

This library contains helper functions that make it easier to setup a Relay compatible GraphQL schema.

You do not need this library to create a Relay compatible GraphQL schema, it just makes it easier. To illustrate this point here's what a Relay compatible schema looks like <a href="https://github.com/seanabrahams/graphql-relay-elixir/blob/master/test/support/star_wars/schema_without_library.exs">when you don't use this library</a> and <a href="https://github.com/seanabrahams/graphql-relay-elixir/blob/master/test/support/star_wars/schema.exs">when you do use it</a>.

This library relies on the <a href="https://github.com/joshprice/graphql-elixir">graphql-elixir</a> library.

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
          [{:graphql_relay, "~> 0.0.1"}]
        end

  2. Ensure graphql_relay is started before your application:

        def application do
          [applications: [:graphql_relay]]
        end
