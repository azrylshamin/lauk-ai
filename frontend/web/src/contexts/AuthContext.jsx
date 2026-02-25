import { createContext, useContext, useState, useEffect, useCallback } from "react";
import { API_URL } from "../config";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
    const [user, setUser] = useState(null);
    const [token, setToken] = useState(() => localStorage.getItem("laukai_token"));
    const [loading, setLoading] = useState(true);

    // On mount, if we have a token try to fetch the current user
    useEffect(() => {
        if (!token) {
            setLoading(false);
            return;
        }

        fetch(`${API_URL}/api/auth/me`, {
            headers: { Authorization: `Bearer ${token}` },
        })
            .then((res) => {
                if (!res.ok) throw new Error("Token expired");
                return res.json();
            })
            .then((data) => setUser(data))
            .catch(() => {
                // Token invalid/expired — clear it
                localStorage.removeItem("laukai_token");
                setToken(null);
                setUser(null);
            })
            .finally(() => setLoading(false));
    }, [token]);

    const login = useCallback(async (email, password) => {
        const res = await fetch(`${API_URL}/api/auth/login`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ email, password }),
        });

        const data = await res.json();
        if (!res.ok) throw new Error(data.error || "Login failed");

        localStorage.setItem("laukai_token", data.token);
        setToken(data.token);
        setUser(data.user);
        return data.user;
    }, []);

    const register = useCallback(async (name, email, password, restaurantName) => {
        const res = await fetch(`${API_URL}/api/auth/register`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ name, email, password, restaurantName }),
        });

        const data = await res.json();
        if (!res.ok) throw new Error(data.error || "Registration failed");

        localStorage.setItem("laukai_token", data.token);
        setToken(data.token);
        setUser(data.user);
        return data.user;
    }, []);

    const logout = useCallback(() => {
        localStorage.removeItem("laukai_token");
        setToken(null);
        setUser(null);
    }, []);

    const value = { user, token, loading, login, register, logout };

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error("useAuth must be used within an AuthProvider");
    }
    return context;
}
