# frozen_string_literal: true

require_relative "helpers"

class ContactImporter
  attr_reader :client, :account_id

  CONTACT_TEMPLATE = "dnsimple_contact"

  def initialize(client, account_id, provider_alias = "")
    @client = client
    @account_id = account_id
    @default_attributes = { provider_alias: provider_alias }
  end

  def import
    contacts = fetch_contacts(account_id)

    contacts.each do |contact|
      resource_id = ResourceIdDeduplicator.deduplicate(
          "dnsimple_contact",
          [
            contact.label,
            contact.first_name,
            contact.last_name,
            contact.country,
            contact.organization_name,
          ]
        )

      Helpers.generate render_contact_block(contact, resource_id)
      Helpers.generate render_contact_import_block(contact, resource_id)
    end
  end

  private

  def fetch_contacts(account_id)
    client.contacts.all_contacts(account_id).data
  end

  def render_contact_block(contact, resource_id)
    Helpers.render_template(CONTACT_TEMPLATE, @default_attributes.merge({
      resource_id:,
      contact:,
    }))
  end

  def render_contact_import_block(contact, resource_id)
    Helpers.render_import_block("dnsimple_contact.#{resource_id}", contact.id)
  end
end
