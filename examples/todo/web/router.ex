defmodule Todo.Router do
  use Todo.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Todo do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/graphql" do
    pipe_through :api

    get "/", GraphQL.Plug.Endpoint, schema: {Todo.GraphQL.Schema.Root, :schema}
    post "/", GraphQL.Plug.Endpoint, schema: {Todo.GraphQL.Schema.Root, :schema}
  end

  # Other scopes may use custom stacks.
  # scope "/api", Todo do
  #   pipe_through :api
  # end
end
