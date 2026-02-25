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
 * Check backend + AI service health.
 * @returns {Promise<Object>}
 */
export async function checkHealth() {
    const res = await fetch(`${API_URL}/api/health`);
    return res.json();
}
