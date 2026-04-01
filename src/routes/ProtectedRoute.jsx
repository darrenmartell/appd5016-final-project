import { Navigate, Outlet, useOutletContext } from 'react-router-dom';
import { useAuthContext } from '../context/AuthContext'; // Import your auth hook

const ProtectedRoute = () => {
    const { isAuthenticated } = useAuthContext(); // Get current user from context
    const context = useOutletContext(); // Get any context passed from parent route

    // If user is authenticated, render child routes via Outlet, otherwise redirect to login
    return isAuthenticated ? <Outlet context={context}/> : <Navigate to="/login" replace />;
};
export default ProtectedRoute;