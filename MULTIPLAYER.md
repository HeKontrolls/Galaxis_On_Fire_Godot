# Multiplayer expeditions

Choose **Multiplayer** from the main menu, then select its **Host Game** or **Join Game** tab. A session supports up to eight captains, including the host. This is shared-world co-op: the host chooses planets, owns the world simulation, and saves the expedition. Guests have separate names, appearances, inventories, hotbars, tool wear, health, and magic progress. PvP and a public internet matchmaking service are not included.

## Host

1. Enter a server name and game UDP port (default **24560**).
2. Choose **Start a new game**, **Load the current single-player save**, or **Load a saved game file**. Browse accepts the Godot version's JSON saves.
3. Choose **Host Expedition** and make the firewall choice described below.
4. For a new expedition, use the existing character creator, seed field, and galaxy/planet selection. Guests can connect while you prepare; they land when a planet is ready. Loaded saves resume their saved scene.

New co-op expeditions save to `user://galaxis_multiplayer_save.json`, separate from the default single-player save. Loading an existing file makes that file the host's save destination for the session. Opening a file does not overwrite it. F5 and the host's session menu save the world and connected guests' progress. **Save & Main Menu** saves and disconnects everyone. The previous local save destination is restored when hosting ends.

Host menus do not pause the shared world. The host may open menus while guests keep playing. Loading another save or changing settings from the session menu is disabled until the session ends. Normal host galaxy/planet travel brings the group to the next landing site and retains guest inventories. Developer mode remains host-only.

## Join and browse

The browser searches the local network every two seconds and removes expired advertisements. It shows name, address, occupancy, game version, and whether the host is still preparing a planet. Select a row and choose **Join Selected / Direct IP**, or double-click the row. You can instead enter an IP address or hostname and port directly. **Save Address** retains an address for later selection and probing; this also supports LAN hosts using a custom port. Saved internet addresses can be joined even if their discovery query is unanswered.

The game checks protocol and exact build version before admitting a guest. Guests wait while the host chooses or loads a planet. Use **Cancel Connection** to leave that wait. Escape opens the in-game session menu; guests can disconnect there. If the host closes, guests return to the browser with a connection message.

The host save retains disconnected guests' progress. Reconnecting uses the opaque player identity in `user://multiplayer_identity.txt`, not the display name, so changing the name does not duplicate a character. Keep that file to keep your identity. It is not a password or an account service; co-op currently assumes a trusted group. Different game installations/user-data folders can use different identities.

## Windows Firewall and internet hosting

Before networking, the game explains the executable and selected ports and offers **Allow (Windows UAC)** or **Decline / Continue**. Allow launches a hidden helper, with a Windows administrator approval prompt, to create/update inbound UDP rules for the current executable:

- Game port: the selected port, default **24560**.
- Discovery port: game port + 1, default **24561**, restricted to the local subnet.
- Network profiles: **Private** by default. **Public** is optional and unchecked initially.

Decline launches no helper and makes no firewall changes. Connections may still work if Windows already permits them. Cancelling UAC reports the failure and continues without assuming access was granted. **Windows Firewall...** lets you revisit the choice, including after moving/exporting the game executable or changing ports. Rules remain after the session and appear under **Galaxis on Fire Multiplayer** in Windows Defender Firewall with Advanced Security; remove or disable them there to revoke access.

Firewall rules do not configure the router. For internet hosting, forward the **game UDP port** to the host PC and give guests your public address plus that port. The LAN browser is not a global server directory, and discovery is not opened to the internet. Some ISP/router configurations require a VPN or another reachable connection. Godot's ENet transport uses UDP; see the [Godot ENet documentation](https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html). Firewall rule scoping follows Microsoft's [New-NetFirewallRule documentation](https://learn.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule).

## Implementation and checks

`network_session.gd` owns ENet, discovery, version handshakes, transfer limits, snapshots, and guest lifecycle. Each guest gets an authoritative player context on the host. Clients send bounded input events and movement keys; they cannot submit inventory counts, terrain changes, teleports, or arbitrary function calls. Existing gameplay rules therefore handle mining reach, tiers, placement costs, station inventories, and combat. The shared planet, creatures, weather, fluids, crops, and structures are replicated from the host. Terrain updates transfer changed blocks; world packets are compressed, chunked, acknowledged, and limited in size. Disconnects retain host-side profiles. Remote avatars use the existing Aseprite character/tool assets.

This first implementation favors correctness for small co-op sessions. Guest menus/actions reflect host responses, and rendering uses periodic authoritative updates. High-latency internet play and eight players across a large active world still need real-machine performance testing. No global matchmaking, relay, automatic router configuration, or dedicated headless-server UI is provided.

`python tests/run_multiplayer_checks.py` launches two Godot processes with a loopback host, local discovery, and isolated save files under ignored `.godot/multiplayer-checks/`. It checks joining, full-depth world transfer, separate inventories, mining/placement, pickups, shared workbench crafting, guest damage, saving, reconnection, host travel, and shutdown. It never modifies the Windows Firewall. Set `GODOT` to another Godot console executable if needed. Each run creates an isolated project linked to the game's scripts/assets and imported resources, without editor addons. These test directories contain junctions to game sources; do not recursively delete through their linked directories.

`tests/multiplayer_menu_check.gd` checks menus, explicit firewall decline, input validation, host save loading/new-game flows, and continued world time while the host menu is open. Its optional `preview` argument renders menu screenshots. The Windows helper is embedded in `windows_firewall.gd` so exported games retain the consent workflow without loose PowerShell export files.
