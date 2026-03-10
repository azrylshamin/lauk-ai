const { v2: cloudinary } = require("cloudinary");
const { CloudinaryStorage } = require("multer-storage-cloudinary");
const multer = require("multer");

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Creates a multer upload middleware that stores images in Cloudinary.
 * @param {string} subfolder - e.g. "restaurants" or "menu-items"
 */
function createUpload(subfolder) {
    const storage = new CloudinaryStorage({
        cloudinary,
        params: async (req, _file) => ({
            folder: `laukai/${req.restaurantId}/${subfolder}`,
            allowed_formats: ["jpg", "jpeg", "png", "webp"],
            transformation: [{ width: 800, height: 800, crop: "limit", quality: "auto" }],
        }),
    });

    return multer({
        storage,
        limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
        fileFilter: (_req, file, cb) => {
            if (file.mimetype.startsWith("image/")) {
                cb(null, true);
            } else {
                cb(new Error("Only image files are allowed"));
            }
        },
    });
}

/**
 * Extracts the Cloudinary public_id from a full URL and destroys the image.
 * Safe to call with null/undefined — just returns silently.
 */
async function destroyImage(imageUrl) {
    if (!imageUrl) return;
    try {
        const parts = imageUrl.split("/upload/");
        if (parts.length < 2) return;
        const afterUpload = parts[1].replace(/^v\d+\//, "");
        const publicId = afterUpload.replace(/\.[^.]+$/, "");
        await cloudinary.uploader.destroy(publicId);
    } catch (err) {
        console.error("Cloudinary destroy error:", err.message);
    }
}

module.exports = { cloudinary, createUpload, destroyImage };
