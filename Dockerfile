FROM elixir:1.11.3 AS builder

ENV MIX_ENV=prod
WORKDIR /app

COPY mix.exs mix.lock ./
COPY config/config.exs config/prod.exs config/
RUN mix local.hex --force && mix local.rebar --force && mix deps.get --only prod

FROM node:14.21.3-bullseye-slim AS assets

WORKDIR /app/assets
COPY --from=builder /app/deps /app/deps
COPY assets/package.json assets/package-lock.json ./
RUN npm ci
COPY assets/ ./
# Tailwind scans the Phoenix templates here before purging unused utilities.
COPY lib/ /app/lib/
RUN npm run deploy

FROM builder AS release

COPY lib/ lib/
COPY config/runtime.exs config/
COPY --from=assets /app/priv/static priv/static/
RUN mix compile && mix phx.digest && mix release

FROM debian:bullseye-slim

WORKDIR /app
ENV LANG=C.UTF-8
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=release --chown=nobody:nogroup /app/_build/prod/rel/foist/ ./
USER nobody

CMD ["bin/foist", "start"]
