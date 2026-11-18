# PulseSync State Synchronization Protocol

## Overview
Offline-first conflict-free replicated data types (CRDT) engine for emergency response coordination.

## Replication Rules
- Vector clock timestamping on edge updates.
- Deterministic Last-Write-Wins (LWW) resolver with audit trails.
