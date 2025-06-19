# frozen_string_literal: true

require "digest"
require "yaml"
require "erb"

require_relative "helpers"

def fetch_zone_records(client, account_id, zone_id)
  client.zones.all_zone_records(account_id, zone_id).data
end

class ZonesImporter
  attr_reader :client, :account_id

  ZONE_TEMPLATE = "dnsimple_zone"
  ZONE_RECORD_TEMPLATE = "dnsimple_zone_record"

  def initialize(client, account_id, provider_alias = "")
    @client = client
    @account_id = account_id
    @default_attributes = { provider_alias: provider_alias }
  end

  def import
    zones = fetch_zones(account_id)
    zones.each do |zone|
      zone_resource_id = zone.name.gsub(".", "_")
      Helpers.generate render_zone_block(zone, zone_resource_id)
      Helpers.generate render_zone_import_block(zone, zone_resource_id)

      prepare_zone_records(zone).each do |zone_record|
        zone_record_resource_id = "record_#{zone_record.id}"
        Helpers.generate render_zone_record_block(zone_record, zone_resource_id, zone_record_resource_id)
        Helpers.generate render_zone_record_import_block(zone, zone_record, zone_record_resource_id)
      end
    end
  end

  def prepare_zone_records(zone)
    return [] if zone.secondary

    records = fetch_zone_records(account_id, zone)
    records.each_with_object([]) do |record, acc|
      next if record.system_record

      acc << record
    end
  end

  private

  def fetch_zones(account_id)
    zones = client.zones.all_zones(account_id).data
    zones.sort_by(&:name)
  end

  def fetch_zone_records(account_id, zone)
    client.zones.all_zone_records(account_id, zone.id).data
  end

  def render_zone_block(zone, resource_id)
    Helpers.render_template(ZONE_TEMPLATE, @default_attributes.merge({
      resource_id:,
      zone:
    }))
  end

  def render_zone_record_block(record, zone_resource_id, resource_id)
    Helpers.render_template(ZONE_RECORD_TEMPLATE, @default_attributes.merge({
      resource_id:,
      zone_resource_id:,
      record:
    }))
  end

  def render_zone_import_block(zone, resource_id)
    Helpers.render_import_block("dnsimple_zone.#{resource_id}", %("#{zone.name}"))
  end

  def render_zone_record_import_block(zone, record, resource_id)
    # For some reason, the Provider expects a zone record ID to be "example.com_1234".
    Helpers.render_import_block("dnsimple_zone_record.#{resource_id}", %("#{zone.name}_#{record.id}"))
  end
end
