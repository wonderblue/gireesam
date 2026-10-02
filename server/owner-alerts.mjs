const endpoint = () => process.env.OWNER_NOTIFICATION_WEBHOOK_URL || ''

export function sendOwnerAlert(event, details = {}) {
  const url = endpoint()
  if (!url) return
  const payload = JSON.stringify({
    source: 'gireesam',
    event,
    occurredAt: new Date().toISOString(),
    ...details,
  })
  void fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: payload,
    signal: AbortSignal.timeout(5000),
  }).catch(() => {})
}
