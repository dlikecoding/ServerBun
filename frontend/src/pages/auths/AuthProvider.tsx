import { createContext, useContext, createSignal, JSX } from 'solid-js';

const AuthContext = createContext();

export function AuthProvider(props: { children: any }) {
  const [isAuthenticated, setIsAuthenticated] = createSignal(false);

  const login = () => setIsAuthenticated(true);
  const logout = () => setIsAuthenticated(false);

  return <AuthContext.Provider value={{ isAuthenticated, login, logout }}>{props.children}</AuthContext.Provider>;
}

export function useAuth() {
  return useContext(AuthContext);
}
