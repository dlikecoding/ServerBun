import { createSignal } from 'solid-js'
// import solidLogo from './assets/solid.svg'
// import viteLogo from '/vite.svg'
import './App.css'

function App() {
  const [count, setCount] = createSignal(0)

  return (
    <>
      <div class="card">
        <button onClick={() => setCount((count) => count + 1)}>Up</button>
        <button onClick={() => setCount((count) => count - 1)}>Down</button>

        <div>{count()}</div>
      </div>
    </>
  )
}

export default App
