import Config

config :chord,
  simulation: true,
  network_size: 32

config :logger,
  level: :warn

# config :logger,
#       backends: [{LoggerFileBackend, :file_log}]
#
# config :logger, :file_log,
#       path: 'log/here.log'

# import_config "#{Mix.env()}.exs"
