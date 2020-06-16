FROM elixir:latest

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix do deps.get, deps.compile

COPY . .
RUN mix compile
