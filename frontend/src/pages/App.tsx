import { createSignal, createEffect } from 'solid-js';
// import solidLogo from './assets/solid.svg'
// import viteLogo from '/vite.svg'
import Navbar from '../components/Navbar';

function App(props: { children: any }) {
  const [count, setCount] = createSignal(0);
  const [test, settest] = createSignal(0);
  createEffect(() => {
    async function getData() {
      // const res = await fetch("/api/home");
      // const serverData = await res.json();
      // settest(serverData.homepage);
    }
    getData();
  }, []);
  return (
    <>
      <Navbar />
      {props.children}
    </>
  );
}

export default App;
