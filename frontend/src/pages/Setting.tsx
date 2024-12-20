import { createSignal, Show } from 'solid-js';
import '../styles/setting.module.css';

const Setting = () => {
  // Mock of locals.storageChart and locals.barChart for demonstration purposes
  const [storageChart] = createSignal({
    /* your chart data */
  });
  const [barChart] = createSignal([
    /* your bar chart data */
  ]);

  return (
    <main class="main-container">
      <Show when={storageChart()}>
        <h1>Captures/Year</h1>
        <div class="barChart">
          <canvas id="barChart" data-chartjs={JSON.stringify(barChart()[0])}></canvas>
        </div>

        <div class="storage-bar" id="storageChart" data-chartjs={JSON.stringify(storageChart())}>
          <div id="round">
            <div>
              <span>Storage</span>
              <span id="storage-detail">6.5 GB of 10 GB used</span>
            </div>
            <div class="spaces">
              <span class="storage photos"></span>
              <span class="storage lives"></span>
              <span class="storage videos"></span>
              <span class="storage others"></span>
              <span class="storage free-storages" id="free-storages">
                20.5 GB
              </span>
            </div>

            <div class="legend-storage">
              <div class="coloricon photos"></div> Photos
              <div class="coloricon lives"></div> Lives
              <div class="coloricon videos"></div> Videos
              <div class="coloricon others"></div> Others
              <div class="coloricon free-storages"></div> Free storage
            </div>
          </div>
        </div>
        <div>
          <a href="/admin">.</a>
        </div>
      </Show>

      <h1>ReIndex</h1>
      <form id="reindexForm" class="form-container" action="/setting" method="post">
        <fieldset>
          <legend>Select preferred index for medias:</legend>
          <ul>
            <li>
              <label for="importPath">Folder's name:</label>
              <input id="importPath" type="text" name="importPath" autocomplete="off" placeholder="~/Sonomas/2020-20 ..." />
            </li>
            <li>
              <input type="checkbox" id="importMedias" name="importMedias" value="importMedias" />
              <label for="importMedias">Import All Data to Photo TSX</label>
            </li>
            <li>
              <input type="checkbox" id="importClient" name="importClient" value="importClient" />
              <label for="importClient">Import data for client DB</label>
              <ul>
                <li>
                  <input type="checkbox" id="hashKey" name="hashKey" value="hashKey" />
                  <label for="hashKey">Hash 256 Generate</label>
                </li>
              </ul>
            </li>
            <li>
              <input type="checkbox" id="detectModel" name="detectModel" value="detectModel" />
              <label for="detectModel">AI Detection Mode</label>
            </li>
          </ul>
        </fieldset>
        <button class="buttons" type="submit">
          Progress
        </button>
      </form>
    </main>
  );
};

export default Setting;
