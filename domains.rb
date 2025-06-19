# frozen_string_literal: true

require "erb"
require "yaml"
require "digest"

require_relative "helpers"

class DomainsImporter
  attr_accessor :provider_alias, :import_blocks
  attr_reader :client, :account_id

  DOMAIN_TEMPLATE = "dnsimple_domain"
  DOMAIN_REGISTRATION_TEMPLATE = "dnsimple_registered_domain"
  DOMAIN_DELEGATION_TEMPLATE = "dnsimple_domain_delegation"

  def initialize(client, account_id, provider_alias = "")
    @client = client
    @account_id = account_id
    @default_attributes = { provider_alias: provider_alias }
  end

  def import
    domains = fetch_domains(client, account_id)
    domains.each do |domain|
      domains_resource_id = domain.name.gsub(".", "_")
      Helpers.generate render_domain_block(domain, domains_resource_id)
      Helpers.generate render_domain_import_block(domain, domains_resource_id)

      transfer_lock_status = fetch_transfer_lock_status(client, account_id, domain.name)
      dnssec_status = fetch_dnssec_status(client, account_id, domain.name)
      Helpers.generate render_domain_registration_block({
        resource_id: domains_resource_id,
        domain: domain,
        contact_id: domain.registrant_id,
        auto_renew_enabled: domain.auto_renew,
        transfer_lock_enabled: transfer_lock_status,
        whois_privacy_enabled: domain.private_whois,
        dnssec_enabled: dnssec_status
      })
      Helpers.generate render_domain_registration_import_block(domain, domains_resource_id)

      name_servers = fetch_domain_delegation(client, account_id, domain.name).sort
      Helpers.generate render_domain_delegation_block(domain, name_servers, domains_resource_id)
      Helpers.generate render_domain_delegation_import_block(domain, domains_resource_id)
    end
  end

  private

  def fetch_domains(client, account_id)
    domains = client.domains.all_domains(account_id).data
    domains.select { |domain| domain.state == "registered" }.sort_by(&:name)
  end

  def fetch_transfer_lock_status(client, account_id, domain_id)
    client.registrar.get_domain_transfer_lock(account_id, domain_id).data.enabled
  end

  def fetch_dnssec_status(client, account_id, domain_id)
    client.domains.get_dnssec(account_id, domain_id).data.enabled
  end

  def fetch_domain_prices(client, account_id, domain_id)
    client.registrar.get_domain_prices(account_id, domain_id).data
  end

  def fetch_domain_delegation(client, account_id, domain_id)
    client.registrar.domain_delegation(account_id, domain_id).data
  end

  def render_domain_block(domain, resource_id)
    Helpers.render_template(DOMAIN_TEMPLATE, @default_attributes.merge({
      resource_id:,
      domain:
    }))
  end

  def render_domain_registration_block(attributes)
    Helpers.render_template(DOMAIN_REGISTRATION_TEMPLATE, @default_attributes.merge(attributes))
  end

  def render_domain_delegation_block(domain, name_servers, resource_id)
    Helpers.render_template(DOMAIN_DELEGATION_TEMPLATE, @default_attributes.merge({
      resource_id:,
      domain:,
      name_servers:
    }))
  end

  def render_domain_import_block(domain, resource_id)
    Helpers.render_import_block("dnsimple_domain.#{resource_id}", %("#{domain.name}"))
  end

  def render_domain_registration_import_block(domain, resource_id)
    Helpers.render_import_block("dnsimple_registered_domain.#{resource_id}", %("#{domain.name}"))
  end

  def render_domain_delegation_import_block(domain, resource_id)
    Helpers.render_import_block("dnsimple_domain_delegation.#{resource_id}", %("#{domain.name}"))
  end
end
