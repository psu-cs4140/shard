import Config

# ── Database (Dev) ───────────────────────────────────────────────────────────────
config :shard, Shard.Repo,
  username: "shard",
  password: "change-me",
  hostname: "127.0.0.1",
  database: "shard_dev",
  port: 5432,
  pool_size: 10,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

# ── Endpoint (Dev) ───────────────────────────────────────────────────────────────
config :shard, ShardWeb.Endpoint,
  # Bind to all interfaces so you can hit it from host/VM
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4001")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "2xcfnW1XNY5SwK7bJFPev5TBiRgHshaGeEJVXnc57i6h/e77rBfMzpniCtL0rFXw",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:shard, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:shard, ~w(--watch)]}
  ]

# Live reload in dev
config :shard, ShardWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/shard_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
    ]
  ]

# Dev flags
config :shard, dev_routes: true
config :logger, :default_formatter, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true,
  enable_expensive_runtime_checks: true

# Email (dev)
config :swoosh, :api_client, false
