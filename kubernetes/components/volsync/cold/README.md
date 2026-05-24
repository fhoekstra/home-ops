
This is a volsync component for taking cold backups of a workload: i.e., the workload is shut down, then a snapshot of the volume is backed up.
It uses the [Volsync PVC annotations](https://volsync.readthedocs.io/en/stable/usage/pvccopytriggers.html) for copy triggers with a cronjob per replicationsource (currently: local and remote).

## Assumptions

- The target workload is a statefulset with 1 replica
- The statefulset's name is $APP, or is otherwise provided through $STATEFULSET in Flux postBuild substitute
- VOLSYNC_COPYMETHOD is set to "Snapshot" (default) or "Clone"
- It is strongly recommended to change VOLSYNC_CRON_LOCAL, unless you want to take hourly cold backups, which means shutting down the workload every hour
