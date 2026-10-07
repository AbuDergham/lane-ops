# Housekeeping

## After every merge

Check that the finished lane left nothing behind:

```bash
L=<lane>
docker ps -a --format '{{.Names}} {{.Status}}' | grep "^$L-"   # stopped containers count too
docker volume ls -q | grep "^${L}_"
docker network ls --format '{{.Name}}' | grep "^${L}_"
docker images --format '{{.Repository}}:{{.Tag}}' | grep ":dev-$L$"
git worktree list; git branch --list "*<branch>*"
```

Also check for the lane's secrets and backups folders next to the repo, if your lane setup creates them.

- Remove only resources of **finished lanes**. Keep the default dev stack, the CI runner stack, active lanes, paused lanes, and the owner's other projects.
- Remove stale **watcher processes**: finished agents can leave `until grep ...` loops waiting on a log file that cleanup deleted. One ran for 16 hours.

  ```powershell
  Get-CimInstance Win32_Process -Filter "Name='bash.exe'" | Where-Object { $_.CommandLine -match 'until ' } |
    Select-Object ProcessId, CreationDate, @{n='Cmd';e={$_.CommandLine.Substring(0,120)}}
  ```
  Stop only those that belong to finished lanes, judging by their start time and the file they wait on.
- Delete leftover lane log files in the workspace root once their lane is done.

## Docker limits

- **Network address pools.** Docker's default pools give about 31 networks, and a full stack can use about 4. Around 5 or 6 stacks plus the CI runners, setup fails with "all predefined address pools have been fully subnetted". In order:
  1. bring down stacks that only wait for CI;
  2. remove idle networks (0 containers), but only for other projects with the owner's approval. Compose recreates them on the next `up`.
  3. long term: configure `default-address-pools` with smaller subnets (/24). That needs a Docker restart, so schedule it.
- **Memory.** Each lane takes about 3 to 4 GB. Cap the VM memory sensibly, and check `docker stats` before adding a lane or a local runner.
- **Disk.** Keep the Docker VM disk on an SSD. Moving it is slow; never stop the engine in the middle of a move.

## After a power cut

1. Look for uncommitted work in every worktree, and WIP-commit it before you resume any agent.
2. Restart stacks one by one. A corrupted cache append-only file (AOF) in a lane can be fixed by resetting that lane's cache volume.
3. Re-arm the heartbeat, check the runners, re-run cancelled CI.

## Small Windows tooling traps

- CLI telemetry helpers can flash console windows. Disable telemetry in the CLI (for example `gh config set telemetry disabled`).
- Call `bin\bash.exe` rather than the `git-bash.exe` wrapper from scripts, so no window opens.
- Hidden scheduled tasks aren't the cause of popping windows. Use a process-creation watcher to find the real parent.
