import { useState } from "react";
import { StatusBar } from "expo-status-bar";
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Image,
  ScrollView,
  ActivityIndicator,
  Alert,
} from "react-native";
import * as ImagePicker from "expo-image-picker";

const API_URL = process.env.EXPO_PUBLIC_API_URL || "http://localhost:3000";

export default function App() {
  const [image, setImage] = useState(null);
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);

  // -----------------------------------------------------------------------
  // Pick image from gallery
  // -----------------------------------------------------------------------
  const pickImage = async () => {
    const permission =
      await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      Alert.alert(
        "Permission required",
        "Camera roll access is needed."
      );
      return;
    }

    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ["images"],
      quality: 0.8,
    });

    if (!result.canceled) {
      setImage(result.assets[0]);
      setResults(null);
    }
  };

  // -----------------------------------------------------------------------
  // Take a photo with camera
  // -----------------------------------------------------------------------
  const takePhoto = async () => {
    const permission = await ImagePicker.requestCameraPermissionsAsync();
    if (!permission.granted) {
      Alert.alert("Permission required", "Camera access is needed.");
      return;
    }

    const result = await ImagePicker.launchCameraAsync({
      quality: 0.8,
    });

    if (!result.canceled) {
      setImage(result.assets[0]);
      setResults(null);
    }
  };

  // -----------------------------------------------------------------------
  // Send image to backend → ai-service
  // -----------------------------------------------------------------------
  const detectFood = async () => {
    if (!image) return;

    setLoading(true);
    setResults(null);

    try {
      const formData = new FormData();
      formData.append("file", {
        uri: image.uri,
        name: image.fileName || "photo.jpg",
        type: image.mimeType || "image/jpeg",
      });

      const res = await fetch(`${API_URL}/api/predict`, {
        method: "POST",
        body: formData,
      });

      const data = await res.json();

      if (!res.ok) {
        Alert.alert("Error", data.detail || data.error || "Unknown error");
        return;
      }

      setResults(data);
    } catch (err) {
      Alert.alert("Connection Error", err.message);
    } finally {
      setLoading(false);
    }
  };

  // -----------------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------------
  return (
    <View style={styles.container}>
      <StatusBar style="light" />

      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>LaukAI</Text>
        <Text style={styles.subtitle}>Food Detection Demo</Text>
      </View>

      <ScrollView
        style={styles.body}
        contentContainerStyle={styles.bodyContent}
      >
        {/* Image preview */}
        <View style={styles.imageBox}>
          {image ? (
            <Image
              source={{ uri: image.uri }}
              style={styles.preview}
            />
          ) : (
            <Text style={styles.placeholder}>
              Pick or take a photo to get started
            </Text>
          )}
        </View>

        {/* Action buttons */}
        <View style={styles.actions}>
          <TouchableOpacity
            style={styles.btn}
            onPress={pickImage}
          >
            <Text style={styles.btnText}>Gallery</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.btn}
            onPress={takePhoto}
          >
            <Text style={styles.btnText}>Camera</Text>
          </TouchableOpacity>
        </View>

        {image && (
          <TouchableOpacity
            style={[styles.btn, styles.detectBtn]}
            onPress={detectFood}
            disabled={loading}
          >
            {loading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.btnText}>Detect Food</Text>
            )}
          </TouchableOpacity>
        )}

        {/* Results */}
        {results && (
          <View style={styles.results}>
            <Text style={styles.resultsTitle}>
              Detected Items ({results.count})
            </Text>

            {results.count === 0 && (
              <Text style={styles.noResults}>
                No food items detected. Try another image.
              </Text>
            )}

            {results.detections.map((det, i) => (
              <View key={i} style={styles.detectionCard}>
                <Text style={styles.className}>
                  {det.class}
                </Text>
                <Text style={styles.confidence}>
                  {(det.confidence * 100).toFixed(1)}%
                </Text>
              </View>
            ))}
          </View>
        )}
      </ScrollView>
    </View>
  );
}

// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#0f172a",
  },
  header: {
    paddingTop: 60,
    paddingBottom: 16,
    paddingHorizontal: 24,
    backgroundColor: "#1e293b",
  },
  title: {
    fontSize: 28,
    fontWeight: "800",
    color: "#f8fafc",
  },
  subtitle: {
    fontSize: 14,
    color: "#94a3b8",
    marginTop: 2,
  },
  body: {
    flex: 1,
  },
  bodyContent: {
    padding: 20,
    paddingBottom: 40,
  },
  imageBox: {
    width: "100%",
    aspectRatio: 1,
    backgroundColor: "#1e293b",
    borderRadius: 16,
    overflow: "hidden",
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 16,
  },
  preview: {
    width: "100%",
    height: "100%",
    resizeMode: "cover",
  },
  placeholder: {
    color: "#64748b",
    fontSize: 16,
  },
  actions: {
    flexDirection: "row",
    gap: 12,
    marginBottom: 12,
  },
  btn: {
    flex: 1,
    backgroundColor: "#334155",
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: "center",
  },
  btnText: {
    color: "#f8fafc",
    fontSize: 16,
    fontWeight: "600",
  },
  detectBtn: {
    backgroundColor: "#2563eb",
    marginBottom: 20,
  },
  results: {
    backgroundColor: "#1e293b",
    borderRadius: 16,
    padding: 16,
  },
  resultsTitle: {
    color: "#f8fafc",
    fontSize: 18,
    fontWeight: "700",
    marginBottom: 12,
  },
  noResults: {
    color: "#94a3b8",
    fontSize: 14,
  },
  detectionCard: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    backgroundColor: "#0f172a",
    padding: 14,
    borderRadius: 10,
    marginBottom: 8,
  },
  className: {
    color: "#f8fafc",
    fontSize: 16,
    fontWeight: "600",
  },
  confidence: {
    color: "#22c55e",
    fontSize: 16,
    fontWeight: "700",
  },
});
