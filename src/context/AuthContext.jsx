import { useState, createContext, useContext } from 'react';

const AuthContext = createContext()

export const AuthProvider = ({ children }) => {
    const [token, setToken] = useState(null);
    const [user, setUser] = useState(null);

    return <AuthContext.Provider value={{ token, setToken, user, setUser, isAuthenticated: !!token }}>
        {children}
    </AuthContext.Provider>;
};

export const useAuthContext = () => useContext(AuthContext)
