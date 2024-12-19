import { createSignal } from 'solid-js';

const Login = () => {
  const [email, setEmail] = createSignal('');
  const [password, setPassword] = createSignal('');

  const handleLogin = (e: Event) => {
    e.preventDefault();
    console.log('Logging in with', { email: email(), password: password() });
  };

  return (
    <div class="p-8">
      <h2 class="text-2xl font-bold mb-4">Login</h2>
      <form onSubmit={handleLogin}>
        <div class="mb-4">
          <label for="email" class="block">
            Email
          </label>
          <input
            id="email"
            type="email"
            value={email()}
            onInput={(e) => setEmail(e.currentTarget.value)}
            class="border px-4 py-2 w-full"
          />
        </div>
        <div class="mb-4">
          <label for="password" class="block">
            Password
          </label>
          <input
            id="password"
            type="password"
            value={password()}
            onInput={(e) => setPassword(e.currentTarget.value)}
            class="border px-4 py-2 w-full"
          />
        </div>
        <button type="submit" class="bg-blue-600 text-white px-4 py-2">
          Login
        </button>
      </form>
    </div>
  );
};

export default Login;
