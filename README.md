# prufy

Prove you own a domain, from the terminal.

```bash
prufy verify example.com
```

It prints the one DNS record to add, in the words your DNS provider uses for its own fields. Then it waits and checks. When something isn't right it says what it saw, why, and the one thing to change.

```
  example.com is managed by Cloudflare.

  Add this record:
    Type     TXT
    Name     _prufy-challenge
    Content  prufy-domain-verification=3f9a21bdk2m4q6s8u0w2y4a6c8
    TTL      300, or the lowest your provider offers

  ✓ example.com is verified
    Keep the record in place. We re-check it daily so ownership stays current.
```

There's no account and no password. Your first `prufy verify` starts a session for this terminal, the same way the website does for a browser.

## Install

```bash
curl -fsSL https://prufy.dev/install.sh | bash
```

That address redirects to [`install.sh`](install.sh) in this repository. It downloads one standalone binary for your machine (macOS or Linux, arm64 or x64), checks it against the release's SHA-256, and puts it in `~/.local/bin`. It needs no Node, never uses `sudo`, and never asks for a password. Read the script first if you'd like to: it's about a hundred lines.

| To | Set |
| --- | --- |
| Install somewhere else | `PRUFY_INSTALL=/usr/local/bin` |
| Install a particular version | `PRUFY_VERSION=0.1.0` |

To do it by hand, download the file for your machine from [Releases](https://github.com/agnelnieves/prufy-cli/releases/latest), check it against `checksums.txt`, unpack it with `gunzip`, and make it executable. On Windows, download `prufy-windows-x64.exe`. It hasn't been tried on a real Windows machine yet.

To update, run the installer again. To remove it, delete `~/.local/bin/prufy` and `~/.config/prufy`.

This repository holds the releases, the installer and the issue tracker. The source isn't published.

## Commands

Everything the website does, the CLI does.

| On the website | In the terminal |
| --- | --- |
| Enter a domain, get the record | `prufy verify <domain>` |
| Your domains | `prufy list` |
| A claim's page | `prufy status <domain>` |
| Check now | `prufy check <domain>` |
| Copy the name or the value | `prufy record <domain> --host`, `--value` |
| The zone-file line | `prufy record <domain> --zone-file` |
| Get a new code | `prufy rotate <domain>` |
| Send a link to whoever manages the domain | `prufy share <domain> --email dana@example.com` |
| Open a setup link someone sent you | `prufy setup <link>` |
| One-click setup at the provider | `prufy connect <domain>` |
| Email alerts, and a test alert | `prufy alerts email you@example.com`, `prufy alerts test` |
| The activity strip | `prufy history <domain>` |
| Stop verifying this domain | `prufy stop <domain>` |

Two things the terminal adds:

- `prufy dns <domain>` asks each of the domain's nameservers and two public resolvers what they hold right now, from your machine.
- `prufy whoami` and `prufy logout` show and forget this terminal's session.

One thing it can't do: turn on push notifications. Those need a browser to subscribe, so `prufy alerts` shows them and the website turns them on.

`prufy <command> --help` explains each one.

## For scripts and agents

Add `--json` to any command. stdout then carries one JSON document and nothing else, in the same shapes the API returns. Errors are JSON too: `{ "error": { "kind", "message", "hint" } }`.

With `--json`, `verify` returns the record straight away instead of waiting:

```bash
prufy verify example.com --json
```

```bash
prufy check example.com --json
```

| Exit code | Meaning |
| --- | --- |
| `0` | Done. After a check, it means verified |
| `1` | Something went wrong |
| `2` | The command wasn't understood |
| `3` | Checked, and not verified yet |

An agent that was handed a setup link needs nothing else. The link can read one record and ask for a check, and that's all:

```bash
prufy setup https://prufy.dev/setup/… --json
```

```bash
prufy setup https://prufy.dev/setup/… --check --wait
```

## The session

| | |
| --- | --- |
| Where it's kept | `~/.config/prufy/session.json`, readable only by you. `PRUFY_CONFIG_DIR` or `XDG_CONFIG_HOME` move it |
| In CI | Set `PRUFY_TOKEN` to the token from that file. It's never printed by any command |
| Another Prufy | `--api-url http://localhost:5200`, or `PRUFY_API_URL`. Each address has its own session |
| Colour | Off when piped, with `--no-color`, or when `NO_COLOR` is set. Status is always a word, never colour alone |

A terminal and a browser don't share domains yet. Each is its own session. To move a domain between them, claim it again from the other one: the record in DNS decides who owns it.
