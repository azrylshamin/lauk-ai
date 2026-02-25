const pool = require("../db/db");

/**
 * Look up menu items by yolo_class names and enrich detections.
 * Scoped to a specific restaurant.
 * @param {Array<{class: string, confidence: number, bbox: Array}>} detections
 * @param {number} restaurantId
 * @returns {Promise<{items: Array, total: number}>}
 */
async function lookupMenuItems(detections, restaurantId) {
    const { rows: menuItems } = await pool.query(
        "SELECT * FROM menu_items WHERE restaurant_id = $1",
        [restaurantId]
    );
    const menuMap = new Map(menuItems.map((item) => [item.yolo_class, item]));

    let total = 0;
    const items = detections.map((det) => {
        const menuItem = menuMap.get(det.class);
        if (menuItem) {
            total += parseFloat(menuItem.price);
            return {
                name: menuItem.name,
                yolo_class: det.class,
                price: parseFloat(menuItem.price),
                confidence: det.confidence,
                bbox: det.bbox,
                known: true,
                menu_item_id: menuItem.id,
            };
        }
        return {
            name: "Unknown Item",
            yolo_class: det.class,
            price: null,
            confidence: det.confidence,
            bbox: det.bbox,
            known: false,
        };
    });

    return { items, total: Math.round(total * 100) / 100 };
}

module.exports = lookupMenuItems;
