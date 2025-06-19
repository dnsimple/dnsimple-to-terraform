# frozen_string_literal: true

# The Importer is a collection of scripts that import data from DNSimple via the API
# and then write it to local Terraform files.
#
# USAGE:
# ruby importer.rb <account_id> <resource_list> [provider_alias]
#
# ARGUMENTS:
# account_id - The DNSimple account ID to import data from
# resource_list - Is a comma-separated list of resources to import, default: all
# provider_alias - The provider alias to use in the Terraform configuration, default: ''
#
# EXAMPLE:
# ruby importer.rb 12345 contacts,zones playground
#
# NOTE: The API token must be set in the environment variable DNSIMPLE_API_TOKEN

require "yaml"
require "dnsimple"

require_relative "contacts"
require_relative "domains"
require_relative "zones"

AVAILABLE_RESOURCES = %w[
  contacts
  domains
  zones
].freeze

account_id = ARGV[0]
unless account_id
  puts "Please provide an account ID as the first argument."
  exit 1
end

resource_list = ARGV[1] || "all"
resource_list = resource_list.split(",").map(&:strip)
if resource_list.include?("all")
  resource_list = AVAILABLE_RESOURCES
else
  resource_list.each do |resource|
    unless AVAILABLE_RESOURCES.include?(resource)
      puts "Invalid resource: #{resource}. Available resources are: #{AVAILABLE_RESOURCES.join(", ")}"
      exit 1
    end
  end
end

provider_alias = ARGV[2]

api_token = ENV.fetch("DNSIMPLE_API_TOKEN", nil)
unless api_token
  puts "Please set the DNSIMPLE_API_TOKEN environment variable."
  exit 1
end

### To Use Sandbox, Replace: ###
client = Dnsimple::Client.new(access_token: api_token)
### With: ###
# client = Dnsimple::Client.new(base_url: "https://api.sandbox.dnsimple.com", access_token: api_token)

zone_importer = ZonesImporter.new(client, account_id, provider_alias)
domain_importer = DomainsImporter.new(client, account_id, provider_alias)
contact_importer = ContactImporter.new(client, account_id, provider_alias)

domain_importer.import if resource_list.include?("domains")
zone_importer.import if resource_list.include?("zones")
contact_importer.import if resource_list.include?("contacts")
