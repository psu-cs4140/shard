# Spawn System (draft)

- Scheduler: GenServer or Oban job runs every N seconds
- For each room: pick monsters by weighted `spawn_rate`
- Cap: max N instances per room; respect cooldown
- Despawn: after timeout or on defeat, with cleanup hooks
- Metrics: counter for spawns/room, saturation, failures
