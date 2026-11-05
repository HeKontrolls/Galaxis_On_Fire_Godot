# Multiplayer

Multiplayer is shared-world co-op. The host owns the expedition, saves, and planetary travel, while guests have separate character equipment and progress. Sessions support up to **eight captains**, including the host.

## Host an expedition

1. Choose **Multiplayer** from the main menu and open **Host Game**.
2. Enter a server name and game UDP port. The default is **24560**.
3. Choose a new game, the current single-player save, or a compatible Godot save file.
4. Select **Host Expedition** and make the Windows Firewall choice if prompted.
5. For a new game, complete character creation and choose the starting planet. Connected guests wait until a planet is ready.

New co-op games use a separate multiplayer save. Loading an existing file makes that file the host's save destination during the session. Host menus keep the shared world running.

## Join

Open the **Join Game** tab and enter a captain name. LAN servers appear in the browser with their address, player count, build version, and readiness.

Select a server and choose **Join Selected / Direct IP**, or double-click it. For a direct connection, enter the host's IP address or hostname and game port. **Save Address** keeps an address for later use. **Cancel Connection** exits a connection attempt or world-preparation wait.

The host and guest must use matching game builds. The browser discovers local-network games; it is not a public internet matchmaking directory.

## Windows Firewall

The permission dialog offers **Allow (Windows UAC)** or **Decline / Continue**.

- Allow requests administrator approval for inbound UDP rules for the current game executable.
- Rules use the selected game port and the next port for discovery: defaults **24560** and **24561**.
- Private network access is the default. Public network access is optional and initially unchecked.
- Discovery is restricted to the local subnet.
- Decline continues without making firewall changes; connections may be blocked unless access is already permitted.

Use **Windows Firewall...** in the multiplayer menu to revisit the choice. Created rules remain until removed or disabled in Windows Firewall.

## Internet connections

Firewall permission does not configure a router. Internet hosting needs a reachable host and router configuration for the selected **game UDP port**. Guests can then join using a direct address. LAN discovery is not opened to the internet.

## Progress and disconnecting

The host saves guest inventories, hotbars, durability, health, and magic progress. Reconnecting uses the saved player identity, not only the display name. Keep `multiplayer_identity.txt` in the game's user-data folder to retain that identity.

The host chooses planet travel, and guests follow with their equipment. Guests can disconnect from the session menu. Host shutdown returns guests to the browser. The host should save before ending the session.

This is an early co-op implementation for trusted groups. Cross-PC behavior, eight-player performance, and different router/firewall setups still need broader testing. PvP, public matchmaking, and automatic router port forwarding are not current features.

[Home](Home) · [Wiki Index](Wiki-Index) · [Saves and Settings](Saves-and-Settings)
