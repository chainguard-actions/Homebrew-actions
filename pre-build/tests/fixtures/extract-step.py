#!/usr/bin/env python3
"""Print the `run:` script of a named step from the shipped action.yml."""
import sys

try:
    import yaml
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "--user", "pyyaml"])
    import site
    sys.path.insert(0, site.getusersitepackages())
    import yaml

action_file, step_name = sys.argv[1], sys.argv[2]
with open(action_file) as f:
    action = yaml.safe_load(f)
for step in action["runs"]["steps"]:
    if step.get("name") == step_name:
        sys.stdout.write(step["run"])
        sys.exit(0)
sys.stderr.write(f"step {step_name!r} not found\n")
sys.exit(1)
