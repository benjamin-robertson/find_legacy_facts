# lint:ignore:140chars lint:ignore:strict_indent
# @summary Puppet plan which scans entire code environments for legacy facts. Will automatically locate the Puppet primary and run against it. 
#
#
# @param environment Code environment to scan.
# @param check_ruby Whether to check ruby files for legacy facts. **Note:** local ruby functions/facts can still contain legacy facts as these are still collected on Puppet 8, however they are no longer submitted to PuppetDB. 
plan find_legacy_facts::find_legacy_facts (
  Pattern[/^[a-z0-9_]+/]  $environment,
  Boolean                 $check_ruby = false,
) {
  # We need to get the primary server. Check pe_status_check fact. otherwise fall back to built in fact.
  $pe_status_results = puppetdb_query('inventory[certname] { facts.pe_status_check_role = "primary" }')
  if $pe_status_results.length != 1 {
    # check with built-in puppet_enterprise_role fact
    $pe_role_results = puppetdb_query('inventory[certname] { facts.puppet_enterprise_role = "Primary" }')
    if $pe_role_results.length != 1 {
      fail("Could not identify the primary server. Confirm the puppet_enterprise_role fact or pe_status_check_role fact is working correctly. Results: ${pe_role_results}")
    } else {
      $pe_target = $pe_role_results
    }
  } else {
    # We found a single primary server :)
    $pe_target = $pe_status_results
  }

  $pe_target_certname = $pe_target.map | Hash $node | { $node['certname'] }
  out::message("pe_target_certname is ${pe_target_certname}")

  # Update facts
  $pe_target_final = get_target($pe_target_certname)
  without_default_logging() || { run_plan(facts, targets => $pe_target_final) }

  $task_results = run_task('find_legacy_facts::init', $pe_target_final, { 'environment' => $environment, 'check_ruby' => $check_ruby, 'environment_path' => $pe_target_final.facts['puppet_environmentpath'], '_catch_errors' => true })

  $results = $task_results[0].message
  return($results)
}
#lint:endignore
