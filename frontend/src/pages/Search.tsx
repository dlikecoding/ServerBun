import { createSignal, createEffect, For } from 'solid-js';
import '../styles/search.module.css';

const Search = () => {
  // State for search results
  const [searchResults, setSearchResults] = createSignal({
    classifies: [],
    objects: [],
    locations: [],
    devices: [],
    years: [],
  });

  // Fetching search results (replace with your API endpoint)
  const fetchSearchResults = async () => {
    // try {
    //   const response = await fetch('/api/search'); // Replace with actual API URL
    //   const data = await response.json();
    //   setSearchResults(data);
    // } catch (error) {
    //   console.error('Failed to fetch search results', error);
    // }
  };

  // Fetch results when the component mounts
  createEffect(() => {
    fetchSearchResults();
  });

  return (
    <main class="main-container">
      <h1>Search</h1>
      <form class="group-search">
        <input id="searchInput" type="text" placeholder="🔍 Places, Objects, Devices, Years ..." />
      </form>

      <ul id="searchResult" class="search-result">
        {/* Classifies */}
        <For each={searchResults().classifies}>
          {(obj) => (
            <a href={`/search/find?typeSearch=classifies&keyword=${obj._id}`} class="inactive">
              <span>{obj._id.replace('_', ' ').replace(/^./, (char) => char.toUpperCase())}</span>
              <span>{obj.count}</span>
            </a>
          )}
        </For>

        {/* Objects */}
        <For each={searchResults().objects}>
          {(obj) => (
            <a href={`/search/find?typeSearch=objects&keyword=${obj._id}`} class="inactive">
              <span>{obj._id.replace('_', ' ').replace(/^./, (char) => char.toUpperCase())}</span>
              <span>{obj.count}</span>
            </a>
          )}
        </For>

        {/* Locations */}
        <For each={searchResults().locations}>
          {(obj) => (
            <a href={`/search/find?typeSearch=locations&keyword=${obj._id}`} class="inactive">
              <span>{obj._id.replace(/^./, (char) => char.toUpperCase())}</span>
              <span>{obj.count}</span>
            </a>
          )}
        </For>

        {/* Devices */}
        <For each={searchResults().devices}>
          {(obj) => (
            <a href={`/search/find?typeSearch=devices&keyword=${obj._id}`} class="inactive">
              <span>{obj._id.replace(/^./, (char) => char.toUpperCase())}</span>
              <span>{obj.count}</span>
            </a>
          )}
        </For>

        {/* Years */}
        <For each={searchResults().years}>
          {(obj) => (
            <a href={`/search/find?typeSearch=years&keyword=${obj._id}`} class="inactive">
              <span>{obj._id}</span>
              <span>{obj.count}</span>
            </a>
          )}
        </For>
      </ul>
    </main>
  );
};

export default Search;
