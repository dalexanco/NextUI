# Admin pairing

How a phone finds the console and gets the right to use the
[admin server](server.md): a QR code shown behind the PIN, a one-time token,
a long-lived cookie.

| Section | Content |
|---|---|
| [Decisions](#decisions) | W2–W5, P12 |
| [Flow](#flow) | From the PIN to the home page |
| [Rules](#rules) | Token, cookie, limit, revocation |
| [Open questions](#open-questions) | Not decided yet |

## Decisions

| # | Question | Decision |
|---|---|---|
| W2 | QR content | URL with the IP and a one-time token; security kept as simple as possible |
| W3 | Where the QR shows | Parental.pak admin menu, behind the PIN |
| W4 | IP change | Rescan the QR code; the old pairing is lost |
| W5 | Paired phones | Listed on the console, revocable; at most 5, the oldest dropped |
| P12 | Web PIN | None: pairing replaces it |

## Flow

1. In Parental.pak's admin menu, behind the PIN, the parent opens **Pair a phone**.
2. The console shows a QR code for `http://<ip>[:<port>]/pair?t=<token>`, the
   same URL as text, and: "Connect your phone to the same Wi-Fi network as the
   console."
3. The phone opens the URL. The server swaps the token for a long-lived cookie
   and redirects to the home page.

The pairing screen is in a Tools pak, where the [activation rule](server.md#activation-rule)
keeps the server off. While this screen is displayed, Parental.pak starts the
server itself, answering `/pair` only, and stops it when the screen closes.

A changed IP breaks the bookmark (W4). The phone shows a browser error; the
parent pairs again.

## Rules

| Item | Rule |
|---|---|
| Token | Random, single use, valid while the screen shows plus 5 minutes |
| Cookie | Random, `HttpOnly`, `SameSite=Strict`, no expiry |
| Phone label | Derived from the User-Agent ("Android · Chrome"), editable on the console |
| Limit | 5 phones; a sixth pairing drops the oldest paired |
| Revocation | From the paired phones list in Parental.pak |
| Storage | `parental/phones.toml` ([data](../parental/data.md)) |

## Open questions

| Question | Why it matters |
|---|---|
| Server exception on the pairing screen | A proposal, not a decision; without it, scanning the QR code cannot reach the server |
