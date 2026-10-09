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

- Remove only resources of **finished lanes**. Keep the default dev stack, the CI runner stack, active lanes, paused lanes, the session scratchpad, the prompts folder, and the owner's other projects.
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

## Power cuts

**On battery, before the power goes:**
1. Stop the implementer agents.
2. WIP-commit and push each worktree.
3. Bring each lane stack down, keeping the volumes.
4. Stop the local CI runners and the heartbeat.
5. If the owner asks, stop all containers gracefully (so databases flush), then quit the container engine and its VM.
6. Write a resume note in the handoff file (`templates/session-handoff.md`): the pause time, the containers that ran, and what was done for each agent.

**Resume:**
1. Start the engine and restore exactly the containers that ran before, one stack at a time. A corrupted cache append-only file (AOF) in a lane can be fixed by resetting that lane's cache volume.
2. If the cut came without warning, look for uncommitted work in every worktree, and WIP-commit it before you resume any agent.
3. Resume each agent with a message that says what was done for it (WIP commit, push, stack down).
4. Re-arm one heartbeat, read the channel from the pause start, check the runners, and re-run cancelled CI.

## The repository README

Write it by inventory, not from memory, and only when the owner asks (it is a fan-out):
1. Readers fan out over the module groups and the platform.
2. One writer builds the README from what is merged.
3. A verifier spot-checks 25 or more claims against the code, marks the items that need owner input, and strips hostnames, handles and secrets. In the first pass, it found about 16 overstatements.

## Small Windows tooling traps

- CLI telemetry helpers can flash console windows. Disable telemetry in the CLI (for example `gh config set telemetry disabled`).
- Call `bin\bash.exe` rather than the `git-bash.exe` wrapper from scripts, so no window opens.
- Hidden scheduled tasks aren't the cause of popping windows. Use a process-creation watcher to find the real parent.
