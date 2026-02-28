import { API_URL } from "../config";

// ---------------------------------------------------------------------------
// Token helpers
// ---------------------------------------------------------------------------
function getToken() {
    return localStorage.getItem("laukai_token");
}

/**
 * Wrapper around fetch that auto-attaches the JWT Bearer token.
 * On 401 responses, clears the stored token.
 */
async function authFetch(url, options = {}) {
    const token = getToken();
    const headers = { ...options.headers };

    if (token) {
        headers["Authorization"] = `Bearer ${token}`;
    }

    const res = await fetch(url, { ...options, headers });

    // If unauthorized, clear the token
    if (res.status === 401) {
        localStorage.removeItem("laukai_token");
        window.location.href = "/login";
        throw new Error("Session expired. Please log in again.");
    }

    return res;
}

// ---------------------------------------------------------------------------
// API functions
// ---------------------------------------------------------------------------

/**
 * Send an image to AI service for food detection.
 * @param {File} imageFile
 * @returns {Promise<{items: Array, total: number, count: number}>}
 */
export async function predictImage(imageFile) {
    const formData = new FormData();
    formData.append("file", imageFile);

    const res = await authFetch(`${API_URL}/api/predict`, {
        method: "POST",
        body: formData,
    });

    const data = await res.json();

    if (!res.ok) {
        throw new Error(data.detail || data.error || "Unknown error");
    }

    return data;
}

/**
 * Fetch all menu items from the database.
 * @returns {Promise<Array>}
 */
export async function fetchMenuItems() {
    const res = await authFetch(`${API_URL}/api/menu-items`);
    if (!res.ok) throw new Error("Failed to fetch menu items");
    return res.json();
}

/**
 * Create a new menu item (assign an unknown YOLO class).
 * @param {string} yoloClass
 * @param {string} name
 * @param {number} price
 * @returns {Promise<Object>} The created menu item
 */
export async function assignMenuItem(yoloClass, name, price) {
    const res = await authFetch(`${API_URL}/api/menu-items`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            yolo_class: yoloClass,
            name: name.trim(),
            price: parseFloat(price),
        }),
    });

    const data = await res.json();

    if (!res.ok) {
        throw new Error(data.error || "Failed to assign item");
    }

    return data;
}

/**
 * Save a confirmed bill with its line items.
 * @param {Array} items
 * @param {number} total
 * @returns {Promise<Object>} The created bill
 */
export async function saveBill(items, total) {
    const payload = {
        items: items.map((item) => ({
            menu_item_id: item.menu_item_id || null,
            name: item.name,
            price: item.price || 0,
            quantity: item.quantity,
        })),
        total: Math.round(total * 100) / 100,
    };

    const res = await authFetch(`${API_URL}/api/bills`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
    });

    const data = await res.json();

    if (!res.ok) {
        throw new Error(data.error || "Failed to save bill");
    }

    return data;
}

/**
 * Fetch dashboard stats for today.
 * @returns {Promise<{billCount: number, revenue: number, average: number, accuracy: number|null}>}
 */
export async function fetchBillStats() {
    const res = await authFetch(`${API_URL}/api/bills/stats`);
    if (!res.ok) throw new Error("Failed to fetch stats");
    return res.json();
}

/**
 * Fetch recent bills for the authenticated restaurant.
 * @returns {Promise<Array>}
 */
export async function fetchBills() {
    const res = await authFetch(`${API_URL}/api/bills`);
    if (!res.ok) throw new Error("Failed to fetch bills");
    return res.json();
}

/**
 * Fetch a single bill with its line items.
 * @param {number} id
 * @returns {Promise<Object>}
 */
export async function fetchBill(id) {
    const res = await authFetch(`${API_URL}/api/bills/${id}`);
    if (!res.ok) throw new Error("Failed to fetch bill");
    return res.json();
}

// ---------------------------------------------------------------------------
// Menu item management
// ---------------------------------------------------------------------------

/**
 * Update a menu item (name, price, active).
 * @param {number} id
 * @param {Object} fields - { name?, price?, active? }
 * @returns {Promise<Object>}
 */
export async function updateMenuItem(id, fields) {
    const res = await authFetch(`${API_URL}/api/menu-items/${id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(fields),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || "Failed to update menu item");
    return data;
}

/**
 * Delete a menu item.
 * @param {number} id
 * @returns {Promise<Object>}
 */
export async function deleteMenuItem(id) {
    const res = await authFetch(`${API_URL}/api/menu-items/${id}`, {
        method: "DELETE",
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || "Failed to delete menu item");
    return data;
}

// ---------------------------------------------------------------------------
// Restaurant profile
// ---------------------------------------------------------------------------

/**
 * Fetch the authenticated restaurant's profile.
 * @returns {Promise<Object>}
 */
export async function fetchRestaurant() {
    const res = await authFetch(`${API_URL}/api/restaurant`);
    if (!res.ok) throw new Error("Failed to fetch restaurant");
    return res.json();
}

/**
 * Update the restaurant profile.
 * @param {Object} fields - { name?, address?, phone? }
 * @returns {Promise<Object>}
 */
export async function updateRestaurant(fields) {
    const res = await authFetch(`${API_URL}/api/restaurant`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(fields),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || "Failed to update restaurant");
    return data;
}

// ---------------------------------------------------------------------------
// Employee management
// ---------------------------------------------------------------------------

/**
 * Fetch all employees belonging to the authenticated restaurant.
 * @returns {Promise<Array>}
 */
export async function fetchEmployees() {
    const res = await authFetch(`${API_URL}/api/employees`);
    if (!res.ok) throw new Error("Failed to fetch employees");
    return res.json();
}

/**
 * Invite a new staff member to the restaurant.
 * @param {string} name
 * @param {string} email
 * @param {string} password
 * @returns {Promise<Object>}
 */
export async function inviteEmployee(name, email, password) {
    const res = await authFetch(`${API_URL}/api/auth/invite`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, email, password }),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || "Failed to invite employee");
    return data;
}

/**
 * Remove a staff member from the restaurant.
 * @param {number} id
 * @returns {Promise<Object>}
 */
export async function removeEmployee(id) {
    const res = await authFetch(`${API_URL}/api/employees/${id}`, {
        method: "DELETE",
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || "Failed to remove employee");
    return data;
}

// ---------------------------------------------------------------------------
// Customer (public) endpoints
// ---------------------------------------------------------------------------

/**
 * Fetch all restaurants (public, no auth).
 * @returns {Promise<Array>}
 */
export async function fetchPublicRestaurants() {
    const res = await fetch(`${API_URL}/api/customer/restaurants`);
    if (!res.ok) throw new Error("Failed to fetch restaurants");
    return res.json();
}

/**
 * Upload image and get price estimate for a specific restaurant (public, no auth).
 * @param {number} restaurantId
 * @param {File} imageFile
 * @returns {Promise<{items: Array, total: number, count: number}>}
 */
export async function estimateImage(restaurantId, imageFile) {
    const formData = new FormData();
    formData.append("file", imageFile);

    const res = await fetch(`${API_URL}/api/customer/restaurants/${restaurantId}/estimate`, {
        method: "POST",
        body: formData,
    });

    const data = await res.json();

    if (!res.ok) {
        throw new Error(data.detail || data.error || "Unknown error");
    }

    return data;
}

// ---------------------------------------------------------------------------
// Health check
// ---------------------------------------------------------------------------

/**
 * Check backend + AI service health.
 * @returns {Promise<Object>}
 */
export async function checkHealth() {
    const res = await fetch(`${API_URL}/api/health`);
    return res.json();
}
