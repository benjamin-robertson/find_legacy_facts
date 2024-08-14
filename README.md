# find_legacy_facts

A module containing a task and plan to scan entire code environments for legacy facts. 

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with find_legacy_facts](#setup)
    * [Beginning with find_legacy_facts](#beginning-with-find_legacy_facts)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

Puppet 8 by default no longer saves legacy facts to PuppetDB. This will case any Puppet manifest code to fail if legacy facts are still in use after upgrading to Puppet 8.

For more information on legacy facts and what they are. See [Legacy Facts][1]

## Setup

### Beginning with find_legacy_facts

Add legacy facts to your Puppetfile and deploy code to your Puppet primary.

Legacy facts task and plan accepts two parameters. 

**Environment:** Required: Name of the environment you wish to scan. This could be production, development etc.
**check_ruby:** Whether to scan ruby files foe legacy facts. Note: local ruby functions/facts can still contain legacy fact as these are still collected on Puppet 8. They are just not submitted to PuppetDB. 

## Usage

From within the Puppet Enterprise console, goto the 

## Limitations

Find_legacy_facts can be used to help prepare to migration to Puppet 8. However it should not depended upon to catch all potential legacy fact issues. Testing of Puppet 8 with your code base within a test environment is vital before performing production upgrades.

## Development

If you find any issues with this module, please log them in the issues register of the GitHub project. [Issues][3]

PR's glady accepted. 

[1]: https://www.puppet.com/docs/puppet/8/core_facts.html#legacy-facts
[2]:
[3]: https://github.com/benjamin-robertson/find_legacy_facts/issues
