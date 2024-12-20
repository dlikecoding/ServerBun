import { createSignal } from 'solid-js';
import '../styles/login.module.css';

const Login = () => {
  const [errMsg, setErrMsg] = createSignal('');
  const [email, setEmail] = createSignal('');
  const [password, setPassword] = createSignal('');
  // Function to handle user clicks and update the ErrMsg
  const handleLogin = (e: Event) => {
    e.preventDefault();
    console.log('Logging in with', { email: email(), password: password() });
  };

  return (
    <div class="ring">
      <i style="--clr: #0051ff"></i>
      <i style="--clr: #fb00ff"></i>
      <i style="--clr: #41de2f"></i>
      <form class="login" action="/login" method="post">
        <h2>Login</h2>
        <p style="color: red"> (errMsg() )</p>
        <div class="inputBx">
          <input type="text" name="username" placeholder="Username" autocomplete="off" required />
        </div>
        <div class="inputBx">
          <input type="password" name="password" placeholder="Password" autocomplete="off" required />
        </div>
        <div class="inputBx">
          <input type="submit" value="Sign in" />
        </div>
        {/* <div class="links">
                    <a href="#">Forget Password</a>
                    <a href="#">Signup</a>
                </div> */}
      </form>
    </div>
  );
};

export default Login;
