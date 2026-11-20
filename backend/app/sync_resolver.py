"""Vector clock causality and conflict resolution engine for offline-first synchronization."""


class VectorClockResolver:
    """Resolves state causality between mobile field nodes and server coordinator."""

    @staticmethod
    def resolve_winner(local_clock: dict, remote_clock: dict) -> str:
        """Returns 'LOCAL_WINS', 'REMOTE_WINS', or 'CONFLICT_MERGE'."""
        local_greater = False
        remote_greater = False

        all_keys = set(local_clock.keys()).union(remote_clock.keys())
        for k in all_keys:
            lv = local_clock.get(k, 0)
            rv = remote_clock.get(k, 0)
            if lv > rv:
                local_greater = True
            elif rv > lv:
                remote_greater = True

        if local_greater and not remote_greater:
            return "LOCAL_WINS"
        if remote_greater and not local_greater:
            return "REMOTE_WINS"
        if not local_greater and not remote_greater:
            return "IDENTICAL"
        return "CONFLICT_MERGE"
