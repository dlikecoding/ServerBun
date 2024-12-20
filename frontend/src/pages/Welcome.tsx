import { A } from '@solidjs/router';
import '../styles/partials/welcome.module.css';

const Welcome = () => {
  return (
    <>
      <div id="stars"></div>
      <div id="stars2"></div>
      <div id="stars3"></div>

      <div id="parallax">
        <div class="layer" data-depth="0.6">
          <div class="some-space">
            <h1>Your Journey</h1>
          </div>
        </div>
        <div class="layer" data-depth="0.4">
          <div id="particles-js"></div>
        </div>

        <div class="layer" data-depth="0.3">
          <div class="some-more-space1">
            <A href="/library">Explore</A>
          </div>
        </div>
      </div>
    </>
  );
};

export default Welcome;
