# frozen_string_literal: true

require "public_suffix"
require "erb"

module Helpers
  # Renders the Terraform import statement.
  #
  # @param statement [String] The statement in Terraform language
  # @return [nil]
  def self.generate(statement, separator = "\n")
    puts(statement, separator)
  end

  def self.load_template_content(template_name)
    file_path = File.join(__dir__, "templates", "#{template_name}.erb")
    File.read(file_path)
  end

  def self.render_template(template_name, attributes = {})
    template_content = load_template_content(template_name)
    ERB.new(template_content, trim_mode: "-").result_with_hash(attributes)
  end

  def self.render_import_block(ref, id)
    Helpers.render_template("block_import", {
      ref:,
      id:,
    })
  end
end

# Utility module for resource ID deduplication
module ResourceIdDeduplicator
  @resource_ids = {}

  def self.deduplicate(resource_type, attributes)
    resource_id = resource_type
    attributes.each do |attribute|
      resource_id += to_snake_case("_#{attribute}") if attribute && !attribute.empty?

      next if @resource_ids[resource_id]

      # Resource ID already exists, increment counter and try again

      # Found a unique resource ID, mark it as used
      @resource_ids[resource_id] = 0
      break
    end

    resource_id.delete_prefix("#{resource_type}_")
  end

  def self.ids
    @resource_ids
  end
end

def to_snake_case(str)
  str
    .gsub(/[^0-9A-Za-z_]/, "") # Remove any special characters
    .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2') # Handle acronym + word (e.g. HTMLParser -> HTML_Parser)
    .gsub(/([a-z\d])([A-Z])/, '\1_\2')   # Add underscore between camelCase
    .gsub(/\s+/, "_")                    # Replace spaces with underscores
    .gsub(/_+/, "_")                     # Replace multiple underscores with a single one
    .gsub(/_+$/, "")                     # Remove trailing underscores
    .tr("-", "_")                        # Replace hyphens with underscores
    .downcase
end

# Utility module for TLD extended attribute lookup
module TLDAttributes
  @tld_attributes = {}

  def self.check_extended_attributes(client, domain_name)
    tld = PublicSuffix.parse(domain_name).tld

    # Check if the TLD attributes are already cached
    @tld_attributes[tld] = client.tlds.tld_extended_attributes(tld).data if @tld_attributes[tld].nil?

    @tld_attributes[tld].select(&:required)
  rescue StandardError => e
    # Print the domain name and TLD then print the error alongside the stack trace
    puts "Error fetching TLD attributes for domain: #{domain_name} (TLD: #{tld})"
    puts "Error: #{e.message}"
    puts e.backtrace.join("\n")
    puts "Continuing with the next domain..."

    @tld_attributes[tld] = [] # Cache empty result to avoid repeated errors
    []
  end
end

def deep_transform_keys_to_strings(obj)
  case obj
  when Hash
    obj.each_with_object({}) do |(k, v), result|
      result[k.to_s] = deep_transform_keys_to_strings(v)
    end
  when Array
    obj.map { |e| deep_transform_keys_to_strings(e) }
  else
    obj
  end
end
