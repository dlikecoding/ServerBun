import { useAuth } from './AuthProvider';
import { Navigate } from '@solidjs/router';

const ProtectedRoute = (props: { children: any }) => {
  const { isAuthenticated } = useAuth();

  return isAuthenticated() ? props.children : <Navigate href="/login" />;
};

export default ProtectedRoute;
