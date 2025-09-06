import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { createBrowserRouter, RouterProvider } from 'react-router-dom'
import './index.css'
import App from './App.tsx'
import GalleryList from './pages/GalleryList'

const router = createBrowserRouter([
  { path: '/', element: <App /> },
  { path: '/galleries', element: <GalleryList /> },
])

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <RouterProvider router={router} />
  </StrictMode>,
)
