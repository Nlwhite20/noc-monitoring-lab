# Grafana alerting exports

Exported from the running Grafana with the provisioning API on 2026-10-05
(`/api/v1/provisioning/alert-rules/<uid>/export?format=yaml` and
`/api/v1/provisioning/policies/export?format=yaml`).

| File | Contents |
| --- | --- |
| `target-down-rule.yaml` | `TargetDown` rule: `up` below 1, evaluated every 30 s, pending 1 min, no data and errors alert. Uses the notification policy (no `notification_settings`) |
| `notification-policy.yaml` | Default policy: receiver `discord-noc`, grouped by `grafana_folder`, `alertname`, `job`; 30 s / 5 min / 4 h |

Not exported: the `discord-noc` contact point, because it contains the
Discord webhook URL, which is a secret. Both files were scanned for
`discord.com/api/webhooks` before commit.

Known quirk: the rule export shows `folder: ""`. To provision these files
into another Grafana, set `folder: NOC` first and create a contact point
named `discord-noc`.
