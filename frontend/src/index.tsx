/* @refresh reload */

import './styles/index.css';
import App from './pages/App.tsx';
// import { AuthProvider } from './pages/auths/AuthProvider.tsx';
// import ProtectedRoute from './pages/auths/RouteGuard.tsx';
// const root = document.getElementById("root");

// render(() => <App />, root!);

import { render } from 'solid-js/web';
import { Router, Route } from '@solidjs/router';
import { lazy } from 'solid-js';

// const Login = lazy(() => import('./pages/Login'));

// Seprate js from these route
const Welcome = lazy(() => import('./pages/Welcome'));

const Library = lazy(() => import('./pages/Library'));
const Albums = lazy(() => import('./pages/Albums'));
const Search = lazy(() => import('./pages/Search'));
const Upload = lazy(() => import('./pages/Upload'));
const Setting = lazy(() => import('./pages/Setting'));

render(
  () => (
    <Router root={App}>
      {/* <AuthProvider> */}
      {/* Public Route */}
      <Route path="/" component={Welcome} />

      {/* Protected Routes */}
      {/* <ProtectedRoute> */}
      <Route path="/library" component={Library} />
      <Route path="/album" component={Albums} />
      <Route path="/search" component={Search} />
      <Route path="/upload" component={Upload} />
      <Route path="/setting" component={Setting} />
      {/* </ProtectedRoute> */}
      {/* </AuthProvider> */}
    </Router>
  ),
  document.getElementById('root')!
);
