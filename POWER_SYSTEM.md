# Power generation and logic circuits

The Godot power system now includes three fueled generators, power distribution, powered lighting, combinational gates and memory circuits. There are 26 placeable devices plus power wire, signal wire and three fuel materials. All 31 native sprites were created in Aseprite with editable layers, animation tags and exported sheets.

## Start a network

1. Craft a **Biomass Generator**, **Wood Power Pole**, **Electric Lamp** and **Wire** at a placed workbench (press F to use its own ingredient slots).
2. Place the generator on three adjacent solid floor blocks. Place a pole and lamp nearby. Electrical devices are passable and reserve their whole footprint; lamps/connectors can attach to solid surfaces or built background walls.
3. Put **Wire** in your hotbar. Right-click the generator's gold **P** terminal, then a pole's P, then connect the pole's P to the lamp's P. Each cable costs one Wire and spans at most 16 blocks. You can walk between its two ends after selecting the first terminal. Esc cancels a pending cable.
4. Aim at the generator and press **F**. Its movable, closable window has four persistent fuel slots. Click a fuel stack in the backpack to deposit it, right-click to deposit one, or drag it onto a fuel slot. Click a stored stack to withdraw it; right-click withdraws one. The window shows fuel reserve and grid capacity, demand and supplied watts.
5. Feed the biomass generator **Raw Biomass**, **Wood** or **Leaves**. The connected lamp turns on when enough power is available.

For testing, **F3 > Power > Grant Power Test Kit** supplies all devices, wires and fuels. New games still begin with empty inventory. Developer give commands also recognize every power item.

## Generators and fuel

| Generator | Capacity | Fuel / full-load reserve per item |
|---|---|---|
| Biomass Generator | 100 W | Raw Biomass: 35s; Wood: 18s; Leaves: 8s |
| Coal Generator | 300 W | Coal Ore: 120s |
| Fuel Generator | 600 W | Biofuel: 240s; Refined Fuel: 480s |

Four Leaves make four Raw Biomass in Basic crafting or a workbench. A furnace processes four Raw Biomass, two Corn and one Wood into two Biofuel (16s after warm-up). Two Biofuel and two Coal Ore make two Refined Fuel (24s after warm-up). Coal belongs in the furnace fuel slot for that recipe. The usual five-second furnace warm-up applies.

Fuel consumption follows actual supplied load. One 10W lamp uses one tenth of a biomass generator's full-load rate. Multiple fueled generators share load according to available capacity. An idle network consumes no fuel, and stored fuel is only loaded when there is demand. Under overload, 1W logic devices receive priority over 10W lamps; remaining loads are served in a stable order, with no partial lamp allocation. The inspector reports unmet demand.

Water above 96/255 fill in a device's footprint, or any lava, shuts it down. Draining it permits operation again. Reserved fuel is not burned during shutdown. Generators can also be disabled in their fuel window or controlled by an **EN** signal. A generator controlled by circuitry needs a separately powered control source to start from a LOW enable signal.

## Distribution and connections

- **Wire:** electricity between gold P/L ports, undirected.
- **Wood Power Pole / Power Connector:** extend an electrical bus. Poles are eight blocks tall; their low service socket connects the same P bus as the overhead terminal. Right-click the low socket from the ground while holding Wire; cables run from the crossarm at the top. A connector attaches to nearby solid terrain or a built wall.
- **Power Switch:** F toggles its internal P-to-L connection. Feed P from the source, and connect loads to L to isolate that branch.
- **Electric Lamp:** 10W cave lighting. Without a signal cable its EN input defaults HIGH. A connected EN signal controls the lamp. Powered lamps also illuminate covered crops, including farms on visited planets while you explore elsewhere.
- **Logic Wire:** directional signals. Right-click an output **Q/QB first**, then a purple input. It costs one Logic Wire per connection and also spans 16 blocks. Each input accepts one driver; outputs can fan out to multiple inputs. Power terminals and signal pins cannot be cross-connected.
- Selecting an already-connected pair again removes that cable and returns its item. A Hammer or Mattock can cut a cable under the cursor. Inspectors also have **Disconnect cables**. Dismantling a device refunds attached cables and unburnt fuel stored in its slots; its current loaded fuel charge is lost.

All logic devices require electricity at P and consume 1W each. Labels appear while holding either wire type, in developer mode, or when inspecting that device. Gold marks electrical terminals, green marks signal outputs, and purple marks inputs. Live signal cables glow teal; power cables use gold. The simulation supports 256 devices and 512 cables per planet.

## Powered fixtures and automatic lighting

Craft these items at a Workbench, or use **F3 > Power > Grant Power Test Kit**. Each light needs a physical Wire connection at P. With no signal cable, EN defaults HIGH; adding Logic Wire to EN controls it.

| Item | Load | Placement / operation |
|---|---|---|
| Wall Light | 6W | Built background wall or adjacent solid side; compact room light |
| Ceiling Light | 8W | Two solid ceiling blocks immediately above its two-block width |
| Floodlight | 25W | Two-block floor support; stronger light and an eight-block crop-light range |
| Red Signal Lamp | 2W | Wall or solid side; red indicator sprite with a small neutral light halo, no crop growth |
| Wall Switch | 0W | Wall or solid side; F opens/closes the P-to-L connection |
| Push Button | 1W | Wall or solid side; F emits a half-second Q pulse |
| Pressure Plate | 1W | Two floor blocks; Q HIGH while player, robot or living creature stands on it |
| Daylight Sensor | 1W | Floor support; Q HIGH in open daylight; F inverts to night mode |

Fixtures are passable, can be recovered by mining, and drop once if support is removed. Their connections, fuel usage and water/lava shutdown follow the existing network rules. Lamps lose both illumination and their lit sprite when switched off or starved of power. The indicator has a deliberately smaller halo; ordinary room lights also support indoor farming. The floodlight spreads brighter light around its head rather than a directional beam.

**Switched room:** Generator P -> Wall Switch P; Wall Switch L -> each light P. Press F at the switch. Keep the branch free of other source connections; an alternate path would bypass the switch.

**Automatic night light:** Wire the generator to the sensor and lamp P terminals. Press F on the sensor for NIGHT mode, then run Logic Wire from sensor Q to lamp EN. The sensor reads the planet's day/night cycle and solid roofs block daylight. Separate dawn thresholds prevent flickering. Day mode is HIGH only with sky exposure and daylight; night mode is its inverse, so covering it also activates night mode.

**Walk-triggered light:** Power the plate and lamp at P, then connect plate Q to lamp EN. A player standing or walking across the plate lights the lamp; leaving releases it. Jumping clear of the plate does not trigger it. On a visited planet away from the player, plates release instead of retaining stale actor positions.

**Toggle button:** Power a Push Button and T Flip-Flop, connect button Q to CLK, and flip-flop Q to a powered light's EN. Each separate F press toggles the light once. T defaults HIGH. A pulse lasts 0.5 seconds of active simulation and is saved if interrupted; logic signals propagate at the normal 10Hz rate. Pressing an already-active button restarts its pulse rather than emitting a second rising edge.

## Gates, inputs and outputs

**Logic Input** is a manual signal source: F toggles LOW/HIGH. **Logic Output** is a buffer and controlled power relay: IN passes to Q, and a HIGH Q connects P to L. Feed its control circuitry through P and attach the switched load to L. Every logic output becomes LOW when its device loses power.

| A | B | AND | OR | XOR | NAND | NOR |
|---|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 | 1 | 1 |
| 0 | 1 | 0 | 1 | 1 | 1 | 0 |
| 1 | 0 | 0 | 1 | 1 | 1 | 0 |
| 1 | 1 | 1 | 1 | 0 | 0 | 0 |

**NOT** inverts A. Press F at a gate for its input values, output and truth table. An unwired input can be toggled with its inspector's test button; a connected input is driven by its cable. Ordinary unwired inputs default LOW, EN defaults HIGH, and T defaults HIGH.

Example: connect two powered Logic Inputs to an AND gate's A and B, then connect Q to a powered lamp's EN. The lamp lights only when both sources are HIGH. Replace AND with OR or XOR to change that condition.

## Memory circuits

- **RS NOR Latch:** active HIGH. S/R=10 sets Q, 01 resets, and 00 holds. 11 is invalid and displays Q=QB=LOW with a fault indicator.
- **RS NAND Latch:** active LOW. S/R=01 sets Q, 10 resets, and 11 holds. 00 is invalid and displays Q=QB=HIGH. Unwired S and R default HIGH to hold the state.
- **T Flip-Flop:** a rising CLK edge toggles Q when T is HIGH. A held clock does not repeatedly toggle. T LOW inhibits toggling. Q and QB expose complementary valid outputs.

Real SR latches have an indeterminate release from their forbidden input combination. This game deliberately keeps the last valid remembered state and restores it when inputs return to hold, making recovery predictable. Memories survive power loss and saving, while unpowered outputs remain LOW. The previous clock level is saved to prevent an extra toggle on loading a held clock.

Logic updates synchronously at 10Hz: signals advance one gate per tick. Relays add a following power-distribution tick. Feedback circuits remain bounded to that rate instead of causing unbounded solver loops.

## Persistence, artwork and checks

Placed devices, fuel slots and reserves, cables, manual input defaults, switch positions, latch memory and clock history are stored per planet. Visited networks update during active planetary play and open inventory/station screens; pause, developer controls and map/menu screens stop simulation. There is no real-world offline catch-up. Pending cable selection clears on travel, hotbar changes and load.

Sources: `assets/sprites/source/power/*.aseprite`; runtime PNG/JSON files: `assets/sprites/power/`. The regular Aseprite export and verification workflow includes all 31 assets / 109 frames.

`tests/power_system_check.gd` covers truth tables, both latch types, T edge behavior, forbidden inputs, feedback, relay control, overload, energy conservation, fuel types, real placement/wiring/F interaction, storage, light-dependent crops, flooding, topology removal, crafting, furnace refinement and save/load. `tests/power_fixtures_check.gd` adds real mounting, switch shutdown, light loads and sprites, timed buttons, player/robot/mob pressure detection, day/night automation, crop-light and fixture save checks. Station, farming and housing checks provide regression coverage. Review images: [art](tests/power_art_review.png), [network](tests/power_gameplay.png), [generator storage](tests/power_generator_window.png), [logic inspector](tests/power_logic_window.png), [powered shelter](tests/power_fixtures_gameplay.png), [daylight sensor](tests/power_sensor_window.png).

The requested [DualShockers article](https://www.dualshockers.com/minecraft-redstone-logic-gates-explained/) returned HTTP 502 during implementation. Gate and latch behavior was checked against the original instructional [logic-gate tables](https://www.learnabout-electronics.org/Digital/dig21.php), [SR latch operation](https://www.learnabout-electronics.org/Digital/dig52.php), and [clocked flip-flop discussion](https://www.learnabout-electronics.org/Digital/dig54.php). The deterministic invalid-state recovery above is an intentional game rule.
