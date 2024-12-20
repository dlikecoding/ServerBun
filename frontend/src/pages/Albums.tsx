import { createSignal, createResource, For, Show } from 'solid-js';
import '../styles/album.module.css';

const fetchData = async (url: string) => {
  const response = await fetch(url);
  return response.json();
};

const Albums = () => {
  const [trainDataset, setTrainDataset] = createSignal([]);
  const [collections, setCollections] = createSignal([]);
  const [objectsKeys, setObjectsKeys] = createSignal([]);
  const [locations, setLocations] = createSignal([]);
  const [mediaType, setMediaType] = createSignal({});
  const [duplicate, setDuplicate] = createSignal([]);
  const [utilities, setUtilities] = createSignal({});

  // Mock fetching data or replace with actual API calls
  const fetchAllData = () => {
    // Simulated API calls for demo
    setTrainDataset([{ _id: '1', Thumbnail: 'path/to/image1.jpg', title: 'Dataset 1', count: 10 }]);
    setCollections([{ _id: '2', Thumbnail: 'path/to/image2.jpg', title: 'Collection 1', count: 5 }]);
    setObjectsKeys([{ _id: '3', title: 'Object 1' }]);
    setLocations([{ _id: '4', title: 'Location 1' }]);
    setMediaType({ Video: 10, Image: 20 });
    setDuplicate([{ _id: 'Duplicate 1', totals: 5 }]);
    setUtilities({ Utility1: 10, Utility2: 15 });
  };

  fetchAllData();

  return (
    <main class="main-container">
      <h1>Albums</h1>

      <span id="add-to-album">
        <svg class="svg-nav-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          <path fill-rule="evenodd" d="M11 2v9H2v2h9v9h2v-9h9v-2h-9V2Z" />
        </svg>
      </span>

      <Show when={trainDataset().length}>
        <h2>
          Dataset Images{' '}
          <a class="atag-group-views" href="/album/group/albumList">
            See All
          </a>
        </h2>
        <div id="data-container" class="album-section">
          <For each={trainDataset()}>
            {(media) => (
              <div class="data-container album">
                <a href={`/search/find?typeSearch=albumList&keyword=${media._id}`}>
                  <img src={media.Thumbnail} alt="Medias" />
                </a>
                <div class="overlay-text">{media.title}</div>
                <div class="count-text">{media.count}</div>
              </div>
            )}
          </For>
        </div>
      </Show>

      <Show when={collections().length}>
        <h2>
          Collections{' '}
          <a class="atag-group-views" href="/album/group/classifies">
            See All
          </a>
        </h2>
        <div id="data-container" class="album-section">
          <For each={collections()}>
            {(media) => (
              <div class="data-container">
                <a href={`/search/find?typeSearch=classifies&keyword=${media._id}`}>
                  <img src={media.Thumbnail} alt="Medias" />
                </a>
                <div class="overlay-text">{media.title}</div>
                <div class="count-text">{media.count}</div>
              </div>
            )}
          </For>
        </div>
      </Show>

      <Show when={objectsKeys().length}>
        <h2>
          Categories{' '}
          <a class="atag-group-views" href="/album/group/objects">
            See All
          </a>
        </h2>
        <div class="object-section">
          <For each={objectsKeys()}>
            {(media) => (
              <a href={`/search/find?typeSearch=objects&keyword=${media._id}`}>
                <div class="object-text">{media.title}</div>
              </a>
            )}
          </For>
        </div>
      </Show>

      <Show when={locations().length}>
        <h2>
          Locations{' '}
          <a class="atag-group-views" href="/album/group/locations">
            See All
          </a>
        </h2>
        <div class="location-section">
          <For each={locations()}>
            {(media) => (
              <a href={`/search/find?typeSearch=locations&keyword=${media._id}`}>
                <div class="object-text">{media.title}</div>
              </a>
            )}
          </For>
        </div>
      </Show>

      <Show when={Object.keys(mediaType()).length}>
        <h2>Media Types</h2>
        <div class="media-section">
          <For each={Object.entries(mediaType())}>
            {([key, value]) => (
              <Show when={value !== 0}>
                <a href={`/album/${key.toLowerCase()}`}>
                  <span class="label">{key}</span>
                  <span class="info">{value}</span>
                </a>
              </Show>
            )}
          </For>
        </div>
      </Show>

      <h2>Utilities</h2>
      <div class="media-section">
        <Show when={duplicate().length}>
          <a href={`/album/${duplicate()[0]._id.toLowerCase()}`}>
            <span class="label">{duplicate()[0]._id}</span>
            <span class="info">{duplicate()[0].totals}</span>
          </a>
        </Show>
        <For each={Object.entries(utilities())}>
          {([key, value]) => (
            <Show when={value !== 0}>
              <a href={`/album/${key.toLowerCase()}`}>
                <span class="label">{key}</span>
                <span class="info">{value}</span>
              </a>
            </Show>
          )}
        </For>
      </div>
    </main>
  );
};

export default Albums;
