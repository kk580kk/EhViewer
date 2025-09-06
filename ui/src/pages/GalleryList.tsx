import { useEffect, useState } from 'react'

type GalleryItem = { id: string; title: string; cover: string }

export default function GalleryList() {
  const [items, setItems] = useState<GalleryItem[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)

  useEffect(() => {
    setLoading(true)
    fetch(`http://localhost:8080/api/galleries?page=${page}`)
      .then((r) => r.json())
      .then((res) => {
        setItems(res.data.items)
      })
      .finally(() => setLoading(false))
  }, [page])

  return (
    <div style={{ padding: 24 }}>
      <h2>Galleries</h2>
      {loading ? <p>Loading...</p> : (
        <ul>
          {items.map((it) => (
            <li key={it.id}>{it.title}</li>
          ))}
        </ul>
      )}
      <div style={{ display: 'flex', gap: 8 }}>
        <button disabled={page<=1} onClick={() => setPage((p)=>p-1)}>Prev</button>
        <span>Page {page}</span>
        <button onClick={() => setPage((p)=>p+1)}>Next</button>
      </div>
    </div>
  )
}

