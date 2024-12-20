import '../styles/upload.module.css';

const Upload = () => {
  // Assuming `message` is a reactive signal
  let message = 'Your message here'; // Replace with reactive data or props

  return (
    <main class="main-container">
      <h1>Upload</h1>
      <form id="uploadForm" class="form-container" enctype="multipart/form-data" action="/upload" method="post">
        <fieldset>
          <legend>Upload to MetaX:</legend>
          <ul>
            <li>
              <p style={{ color: 'crimson' }}>{message}</p>
              <label for="filesInput">
                <b>Select</b> <u>Photos</u> or <u>Videos</u> to Upload to your gallery
                <p>
                  + With a <b>SIZE</b> of less than <b>TWO GB</b>
                </p>
                <p>
                  + Total <b>SIZE</b> must not exceed <b>10 GB</b> per session
                </p>
                <p>
                  + Select <b>Most Compatible</b> option before <b>UPLOAD:</b>
                </p>
                <ul>
                  Photo Library → Options → <u>Most Compatible</u>
                </ul>
              </label>

              <input type="file" name="uploadFiles" id="filesInput" accept="image/*, video/*" multiple required />
            </li>
            <li>
              <input type="checkbox" id="enabledAI" name="enabledAI" value="enabledAI" />
              <label for="enabledAI">Enable AI Detection</label>
            </li>
          </ul>
        </fieldset>

        <button id="uploadButton" type="submit" class="buttons">
          Upload
        </button>
      </form>
    </main>
  );
};

export default Upload;
