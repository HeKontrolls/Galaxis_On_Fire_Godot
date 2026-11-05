# Power and Logic

Electrical systems combine generation, power distribution, and logic signals. A device can need both electrical supply and an enabling signal.

## Generators

| Generator | Nominal capacity | Accepted fuels |
| --- | --- | --- |
| Biomass Generator | 100 W | Raw Biomass, Wood, Leaves |
| Coal Generator | 300 W | Coal Ore |
| Fuel Generator | 600 W | Biofuel, Refined Fuel |

Place a generator, aim at it, and press **F** to open its fuel inventory. Put compatible fuel into the device. Capacity, consumption, and connected demand determine what the network can supply.

## Power wiring

Select **Wire** in the hotbar and right-click compatible gold power terminals to connect devices. Poles and connectors extend the network. Wooden power poles are eight blocks tall, with accessible ground-level connection points for overhead cables.

Cable spans are limited to **16 blocks**. Add a pole or connector when a destination is too far away. Press **Esc** to cancel a pending connection. Connecting an existing pair again can recover that cable.

A simple switched lamp circuit is:

1. Generator **P** to Power Switch **P**.
2. Power Switch **L** to the lamp's **P** terminal.
3. Fuel the generator and press **F** at the switch to toggle the connection.

## Lights and sensors

Electric Lamps, Wall Lights, Ceiling Lights, and Floodlights illuminate the world and can support suitable growing areas. Red Signal Lamps are indicators and do not provide crop-growing light.

Wall Switches toggle connections. Push Buttons produce short pulses. Pressure Plates respond to actors standing on them. Daylight Sensors detect exposed daylight; **F** toggles the sensor's inverted night mode.

## Logic wiring

Use **Logic Wire** for signals. Choose an output such as **Q** or **QB** first, then the destination input. Each input supports one driver. Ordinary power wiring does not substitute for a signal connection.

Logic devices need power. Logic Input can be toggled with **F**. Logic Output accepts **IN** and controls its output and power relay.

## Gates

| A | B | AND | OR | XOR | NAND | NOR |
| --- | --- | --- | --- | --- | --- | --- |
| LOW | LOW | LOW | LOW | LOW | HIGH | HIGH |
| LOW | HIGH | LOW | HIGH | HIGH | HIGH | LOW |
| HIGH | LOW | LOW | HIGH | HIGH | HIGH | LOW |
| HIGH | HIGH | HIGH | HIGH | LOW | LOW | LOW |

**NOT** reverses its A input.

## Memory devices

- **RS NOR Latch:** S/R are active HIGH. Both LOW holds the previous state; both HIGH is invalid.
- **RS NAND Latch:** S/R are active LOW. Both HIGH holds the previous state; both LOW is invalid.
- **T Flip-Flop:** A rising CLK edge toggles the stored state when T is HIGH. Holding CLK HIGH does not repeatedly toggle it.

Inspect device inputs, outputs, fuel, and network supply when a circuit does not behave as expected.

[Home](Home) · [Wiki Index](Wiki-Index) · [Building and Housing](Building-and-Housing) · [Farming and Food](Farming-and-Food)
