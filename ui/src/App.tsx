import { useEffect, useState } from 'react'
import './App.css'

function App() {
  const [status, setStatus] = useState<'loading' | 'ok' | 'error'>('loading')
  const [message, setMessage] = useState('')

  useEffect(() => {
    fetch('http://localhost:8080/api/health')
      .then(async (res) => {
        if (!res.ok) throw new Error(await res.text())
        return res.json()
      })
      .then((data) => {
        setStatus('ok')
        setMessage(JSON.stringify(data))
      })
      .catch((err) => {
        setStatus('error')
        setMessage(String(err))
      })
  }, [])

  return (
    <div style={{ padding: 24 }}>
      <h1>EhViewer Desktop</h1>
      <p>Backend health: {status}</p>
      <pre style={{ background: '#111', color: '#0f0', padding: 12 }}>{message}</pre>
    </div>
  )
}

export default App
