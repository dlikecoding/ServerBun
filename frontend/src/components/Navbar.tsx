import { A } from "@solidjs/router";

const Navbar = () => {
  return (
    <nav class="bg-blue-600 text-white p-4">
      <ul class="flex gap-4">HWLLO
        <li><a href="/">Home</a></li>
        <li><a href="/about">About</a></li>
        <li><a href="/login">Login</a></li>
      </ul>
    </nav>
  );
};

export default Navbar;
