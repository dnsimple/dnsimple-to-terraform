# DNSimple Account Resource Importer

This script is used to import existing resources from a DNSimple account into Terraform. It uses the DNSimple API to fetch the resources and then generates YAML files and Terraform configuration files for them.

## Prerequisites

- Ruby 3.0 or later

## Getting Started

Install the dependencies:

```bash
bundle install
```

## Usage

The Importer is a collection of scripts that import data from DNSimple via the API and then write it to local Terraform files.

### USAGE

```bash
ruby importer.rb <account_id> <resource_list> <provider_alias>
```

#### ARGUMENTS

- `account_id` – The DNSimple account ID to import data from
- `resource_list` – A comma-separated list of resources to import (default: all)
- `provider_alias` – The provider alias to use in the Terraform configuration

#### EXAMPLE

```bash
ruby importer.rb 12345 contacts,zones playground
```

>[!NOTE]
> The API token must be set in the environment variable `DNSIMPLE_API_TOKEN`.

### Importing Resources

The importer will print to STDOUT the imported resources in YAML format. The Terraform configuration files also be printed.

Currently, there are three Terraform configuration files generated:

- `contacts.tf` – Contains the contacts imported from DNSimple
- `domains.tf` - Contains the resources to be created.
- `import.tf` - Contains the import statements for the resources to be imported.

The `locals` block in the `domains.tf` file is the main entry point for how we manage resources, and it would always be the same for any import run.

### Running the Importer

1. Run the importer command
1. Copy the generated output
1. Review and manually merge the Terraform configuration files (`*.tf`). This step is necessary to preserve any custom changes you've made to the existing configurations.

> [!IMPORTANT]
> Do not directly overwrite existing Terraform files, as this may remove your custom modifications. This is because,
> computing the delta between the DNSimple state vs the Terraform state is not currently supported. Hence, the need to manually merge the Terraform configuration files.

### Importing different DNSimple accounts

The current implementation supports multiple DNSimple accounts, via the aliasing of the DNSimple provider. The `provider_alias` argument is used to specify the alias of the provider to use for the imported resources. And this is also why a default provider is not supported, as we cannot dynamically set the provider alias in Terraform.
