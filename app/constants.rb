DB_CONFIG_PATH = File.join(File.dirname(__FILE__), '..', 'db')
DB_CONFIG = YAML.load_file(
  File.join(DB_CONFIG_PATH, 'config.yml')
)