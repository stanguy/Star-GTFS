Apartment.configure do |config|
  config.persistent_schemas = ['postgis']
  config.default_schema = "public"
  config.excluded_models = ["Agency"]
end
