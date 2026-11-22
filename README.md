# Foist

Foist is a clone of the card game "No Thanks!". It is my side project for learning Phoenix LiveView.

Foist is available to play at https://foist.brettbeatty.com.

## Running Locally

Use Erlang/OTP 25 and Elixir 1.14.5 from `.tool-versions`. Run `mise install` to install them. If mise is inactive in your shell, run Mix commands through `mise exec --`, for example `mise exec -- mix compile`.

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deploying to Fly.io

The `foist` app lives in the Brett Beatty personal Fly organization and has a production secret staged. Run this from the repo root to deploy it.

```sh
fly deploy --ha=false
```

To set up a separate Fly app, choose a unique name, update `app` and `PHX_HOST` in `fly.toml`, and stage a production secret before deploying.

```sh
fly apps create your-app-name --org personal
fly secrets set --stage SECRET_KEY_BASE="$(openssl rand -base64 48)"
fly deploy --ha=false
```

Foist needs exactly one running Machine. Games live in memory on the Machine where they were created, and restarting it ends all active games. To verify a deploy, open the app's `fly.dev` URL in two independent browser sessions, create a game, and join it from the second session using the invite link.

For a local image build, use `docker build --platform linux/amd64 -t foist .`. The locked `node-sass` version ships a Linux binary for x86-64.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
