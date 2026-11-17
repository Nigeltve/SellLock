# SellLock

A World of Warcraft **Forever** addon that locks items so they can't be sold by accident.

## How it works

1. Bind a key in **Game Menu → Key Bindings → AddOns → SellLock → Toggle sell lock on hovered item** (unbound by default).
2. Hover over a stack in your bags and press the key. A lock icon appears on it. Press again to unlock.
3. While a merchant is open, clicks on a locked stack are blocked, so right-clicking or dragging it can't sell it. (You also can't move it until you close the merchant or unlock it.)
4. If a locked stack gets sold anyway (a bag addon's auto-sell or a "sell junk" button), SellLock buys it straight back from the buyback tab and locks it again. A buyback costs exactly what the merchant paid, so your gold doesn't change.

Notes:

- A lock belongs to that one stack, not every copy of the item. Split-off stacks start unlocked; merging a locked stack into another can lose the lock.
- Lock icons and click blocking work in the default bags and in BetterBags. In other bag addons the keybind still locks and the auto-buyback still protects, but there's no icon or click blocking.
- Only selling is protected. Deleting, mailing, trading and auction listings are not.
- Locks are saved per character. Disabling the addon stops buybacks and hides the icons; the locks stay saved.

## Requirements

- WoW Forever client (Interface `16001`)

## Installation

1. Download the latest `SellLock-vX.Y.Z.zip` from the [Releases](../../releases) page.
2. Extract it into `World of Warcraft\_forever_\Interface\AddOns\`, so you end up with `AddOns\SellLock\SellLock.toc`.
3. Restart the game or `/reload`.

## Settings

Open **Settings → AddOns → SellLock**, or type `/slock`.

| Setting | Default | Saved |
|---|---|---|
| Enabled | On | Per character |

## Slash commands

`/selllock` works the same as `/slock`.

| Command | What it does |
|---|---|
| `/slock` | Show the addon version and open the options panel |
| `/slock config` | Open the options panel |
| `/slock help` | List the commands |
| `/slock toggle` | Turn the addon on/off for this character |
| `/slock status` | Print the version and whether the addon is enabled |
| `/slock lock` | Toggle the sell lock on the bag item under the mouse (what the keybind does; handy in a macro) |

## Troubleshooting

- **Locked item was sold and not bought back:** SellLock says so in chat. Buy it back from the merchant's buyback tab before you log out.
- **Lua errors:** enable them with `/console scriptErrors 1`, `/reload`, and include the error text in an issue.

## Releasing (maintainers)

Raise `## Version:` in `SellLock.toc` (format `X.Y.Z`) and push to `main`. GitHub Actions then zips the addon and publishes release `vX.Y.Z` with generated notes. Pushes where the version isn't higher than the latest release are skipped. You can also run **Actions → Create Release → Run workflow** to release the current `.toc` version if it hasn't been released yet.

## Author

NuggyNige
