import Config

config :chord,
  simulation: true,
  network_size: 32
  # port: 12543,
  # address: localhost,
  # id: "Node1",
  # join_id: "3",
  # join_address: "https://node2.othernetwork.com/47382",

config :logger,
  level: :warn

# config :logger,
#       backends: [{LoggerFileBackend, :file_log}]
#
# config :logger, :file_log,
#       path: 'log/here.log'

# import_config "#{Mix.env()}.exs"
