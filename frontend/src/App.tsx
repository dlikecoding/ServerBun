import { createSignal, createEffect } from "solid-js";
// import solidLogo from './assets/solid.svg'
// import viteLogo from '/vite.svg'
// import { type  } from "module";
import "./App.css";

function App() {
  const [count, setCount] = createSignal(0);
  const [test, settest] = createSignal(0);
  createEffect(() => {
    async function getData() {
      const res = await fetch("/api/home");
      const serverData = await res.json();
      settest(serverData.homepage);
    }
    getData();
  }, []);
  return (
    <>
      <div class="card">
        <button onClick={() => setCount((count) => count + 1)}>Up</button>
        <button onClick={() => setCount((count) => count - 1)}>Down</button>

        <div>{count()}</div>
        <div>{test()}</div>
      </div>
    </>
  );
}

export default App;
