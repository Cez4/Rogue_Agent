# Rogue Agent - Project Instructions

## Architectural Philosophy: Modular Action-RPG
This project follows a strict separation of concerns to ensure scalability for MMO/Co-op play.

### 1. Behavior Trees (LimboAI)
- **Role:** High-level strategic decision making.
- **Constraint (Atomic Tasks):** Custom `BTAction` or `BTCondition` scripts must be atomic. No complex timers or motor loops inside GDScript.
- **Composition:** Use native nodes (`BTSequence`, `BTCooldown`, `BTTimeLimit`, `BTWait`) to build logic.
- **Safe Editing:** Structure changes to `.tres` files must be done via Godot Editor Scripts, never raw text replacement.

### 2. State Machines (LimboHSM)
- **Role:** Low-level visual and physical execution (Animations, Hitboxes).
- **Hardening Rule:** Always use `if not is_active(): return` after any `await` or `create_timer` to prevent ghost coroutines from re-enabling components after state exit.

### 3. Actor & Runtimes
- **Bridge Pattern:** Systems must communicate with actors via the `ActorRuntimeBridge` and specific Runtimes (`ActorCombatRuntime`, etc.).
- **Movement:** Always use `stop()` in `PlayerMotor` for a hard physics stop (`velocity = Vector2.ZERO`) to prevent sliding during attacks.

### 4. Telemetry
- **Combat Logs:** All tactical decisions and input intents must emit `CombatTelemetry` events for balancing and debugging.
